defmodule Medic.Search do
  @moduledoc """
  Typesense search integration for instant doctor search.

  Provides full-text search with:
  - Typo tolerance
  - Specialty and city filtering
  - Geo-search for nearby doctors
  - Real-time indexing
  """

  alias Medic.Repo
  alias Medic.Doctors
  alias Medic.Doctors.Doctor

  require Logger

  @collection_name "doctors"

  # Collection schema for Typesense
  @collection_schema %{
    "name" => @collection_name,
    "fields" => [
      %{"name" => "id", "type" => "string"},
      %{"name" => "first_name", "type" => "string"},
      %{"name" => "last_name", "type" => "string"},
      %{"name" => "full_name", "type" => "string"},
      %{"name" => "specialty_name_el", "type" => "string", "optional" => true},
      %{"name" => "specialty_name_en", "type" => "string", "optional" => true},
      %{"name" => "specialty_slug", "type" => "string", "optional" => true, "facet" => true},
      %{"name" => "bio_el", "type" => "string", "optional" => true},
      %{"name" => "bio", "type" => "string", "optional" => true},
      %{"name" => "city", "type" => "string", "optional" => true, "facet" => true},
      %{"name" => "address", "type" => "string", "optional" => true},
      %{"name" => "rating", "type" => "float", "optional" => true},
      %{"name" => "review_count", "type" => "int32", "optional" => true},
      %{"name" => "consultation_fee", "type" => "float", "optional" => true},
      %{"name" => "location", "type" => "geopoint", "optional" => true},
      %{"name" => "verified", "type" => "bool"},
      %{"name" => "has_cal_com", "type" => "bool"}
    ],
    "default_sorting_field" => "rating"
  }

  @doc """
  Creates or recreates the doctors collection in Typesense.
  Call this once during initial setup.
  """
  def create_collection do
    with {:ok, _} <- delete_collection(),
         {:ok, result} <- ExTypesense.create_collection(@collection_schema) do
      Logger.info("Typesense collection '#{@collection_name}' created")
      {:ok, result}
    else
      {:error, %{"message" => "Not Found"}} ->
        # Collection didn't exist, that's fine - create it
        ExTypesense.create_collection(@collection_schema)

      error ->
        Logger.error("Failed to create Typesense collection: #{inspect(error)}")
        error
    end
  end

  @doc """
  Deletes the doctors collection.
  """
  def delete_collection do
    ExTypesense.delete_collection(@collection_name)
  end

  @doc """
  Indexes a single doctor document.
  Call this after creating or updating a doctor.
  """
  def index_doctor(%Doctor{} = doctor) do
    doctor = Repo.preload(doctor, :specialty)
    doc = doctor_to_document(doctor)

    case ExTypesense.upsert_document(@collection_name, doc) do
      {:ok, _} ->
        Logger.debug("Indexed doctor: #{doctor.id}")
        :ok

      {:error, reason} ->
        Logger.error("Failed to index doctor #{doctor.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Removes a doctor from the search index.
  """
  def delete_doctor(%Doctor{id: id}) do
    delete_doctor_by_id(id)
  end

  def delete_doctor_by_id(id) when is_binary(id) do
    case ExTypesense.delete_document(@collection_name, id) do
      {:ok, _} ->
        Logger.debug("Deleted doctor from index: #{id}")
        :ok

      {:error, reason} ->
        Logger.warning("Failed to delete doctor #{id} from index: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Syncs all verified doctors to Typesense.
  Use for initial indexing or re-sync.
  """
  def sync_all_doctors do
    doctors =
      Doctors.list_doctors(verified: true, preload: [:specialty])

    Logger.info("Syncing #{length(doctors)} doctors to Typesense...")

    documents = Enum.map(doctors, &doctor_to_document/1)

    case ExTypesense.import_documents(@collection_name, documents, action: "upsert") do
      {:ok, results} ->
        success_count = Enum.count(results, & &1["success"])
        Logger.info("Synced #{success_count}/#{length(doctors)} doctors to Typesense")
        {:ok, success_count}

      {:error, reason} ->
        Logger.error("Failed to sync doctors: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Searches for doctors.

  ## Options
    * `:query` - Search query string (default: "*")
    * `:specialty` - Filter by specialty slug
    * `:city` - Filter by city
    * `:lat` / `:lng` - Geo-search center point
    * `:radius_km` - Search radius in kilometers (default: 10)
    * `:min_rating` - Minimum rating filter
    * `:verified_only` - Only show verified doctors (default: true)
    * `:per_page` - Results per page (default: 20)
    * `:page` - Page number (default: 1)
  """
  def search_doctors(opts \\ []) do
    query = Keyword.get(opts, :query, "*")
    per_page = Keyword.get(opts, :per_page, 20)
    page = Keyword.get(opts, :page, 1)

    search_params = %{
      "q" => query,
      "query_by" => "full_name,specialty_name_el,specialty_name_en,city,bio_el,bio",
      "per_page" => per_page,
      "page" => page,
      "sort_by" => build_sort_by(opts)
    }

    # Add filters
    filters = build_filters(opts)
    search_params = if filters != "", do: Map.put(search_params, "filter_by", filters), else: search_params

    # Add geo-search if coordinates provided
    search_params =
      case {Keyword.get(opts, :lat), Keyword.get(opts, :lng)} do
        {lat, lng} when is_number(lat) and is_number(lng) ->
          radius = Keyword.get(opts, :radius_km, 10) * 1000  # Convert to meters
          Map.merge(search_params, %{
            "filter_by" => add_geo_filter(search_params["filter_by"], lat, lng, radius)
          })

        _ ->
          search_params
      end

    case ExTypesense.search(@collection_name, search_params) do
      {:ok, %{"hits" => hits, "found" => found}} ->
        results =
          Enum.map(hits, fn %{"document" => doc} ->
            %{
              id: doc["id"],
              first_name: doc["first_name"],
              last_name: doc["last_name"],
              full_name: doc["full_name"],
              specialty_name_el: doc["specialty_name_el"],
              specialty_name_en: doc["specialty_name_en"],
              specialty_slug: doc["specialty_slug"],
              city: doc["city"],
              rating: doc["rating"],
              review_count: doc["review_count"],
              consultation_fee: doc["consultation_fee"],
              verified: doc["verified"],
              has_cal_com: doc["has_cal_com"]
            }
          end)

        {:ok, %{results: results, total: found, page: page, per_page: per_page}}

      {:error, reason} ->
        Logger.error("Search failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Convert Doctor struct to Typesense document
  defp doctor_to_document(%Doctor{} = doctor) do
    doc = %{
      "id" => doctor.id,
      "first_name" => doctor.first_name || "",
      "last_name" => doctor.last_name || "",
      "full_name" => "#{doctor.first_name} #{doctor.last_name}",
      "bio_el" => doctor.bio_el,
      "bio" => doctor.bio,
      "city" => doctor.city,
      "address" => doctor.address,
      "rating" => doctor.rating || 0.0,
      "review_count" => doctor.review_count || 0,
      "consultation_fee" => doctor.consultation_fee && Decimal.to_float(doctor.consultation_fee),
      "verified" => doctor.verified_at != nil,
      "has_cal_com" => doctor.cal_com_username != nil
    }

    # Add specialty if loaded
    doc =
      if Ecto.assoc_loaded?(doctor.specialty) && doctor.specialty do
        Map.merge(doc, %{
          "specialty_name_el" => doctor.specialty.name_el,
          "specialty_name_en" => doctor.specialty.name_en,
          "specialty_slug" => doctor.specialty.slug
        })
      else
        doc
      end

    # Add location if available
    if doctor.location_lat && doctor.location_lng do
      Map.put(doc, "location", [doctor.location_lat, doctor.location_lng])
    else
      doc
    end
  end

  defp build_filters(opts) do
    filters = []

    filters =
      if Keyword.get(opts, :verified_only, true) do
        ["verified:=true" | filters]
      else
        filters
      end

    filters =
      case Keyword.get(opts, :specialty) do
        nil -> filters
        slug -> ["specialty_slug:=#{slug}" | filters]
      end

    filters =
      case Keyword.get(opts, :city) do
        nil -> filters
        city -> ["city:=#{city}" | filters]
      end

    filters =
      case Keyword.get(opts, :min_rating) do
        nil -> filters
        rating -> ["rating:>=#{rating}" | filters]
      end

    Enum.join(filters, " && ")
  end

  defp add_geo_filter(existing_filter, lat, lng, radius_meters) do
    geo_filter = "location:(#{lat}, #{lng}, #{radius_meters} m)"

    case existing_filter do
      nil -> geo_filter
      "" -> geo_filter
      filter -> "#{filter} && #{geo_filter}"
    end
  end

  defp build_sort_by(opts) do
    case {Keyword.get(opts, :lat), Keyword.get(opts, :lng)} do
      {lat, lng} when is_number(lat) and is_number(lng) ->
        # Sort by distance when geo-searching
        "location(#{lat}, #{lng}):asc,rating:desc"

      _ ->
        # Default: sort by rating
        "rating:desc"
    end
  end
end
