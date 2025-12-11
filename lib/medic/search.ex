defmodule Medic.Search do
  @moduledoc """
  Typesense search integration for instant doctor search.

  Provides full-text search with:
  - Typo tolerance
  - Specialty and city filtering
  - Geo-search for nearby doctors
  - Real-time indexing

  Uses Req HTTP client for Typesense API calls.
  """


  alias Medic.Doctors
  alias Medic.Doctors.Doctor

  require Logger

  @collection_name "doctors"

  # Get Typesense config
  defp typesense_url do
    host = Application.get_env(:ex_typesense, :host, "localhost")
    port = Application.get_env(:ex_typesense, :port, 8108)
    scheme = Application.get_env(:ex_typesense, :scheme, "http")
    "#{scheme}://#{host}:#{port}"
  end

  defp api_key do
    Application.get_env(:ex_typesense, :api_key, "xyz")
  end

  # Collection schema for Typesense
  @collection_schema %{
    "name" => @collection_name,
    "fields" => [
      %{"name" => "id", "type" => "string"},
      %{"name" => "first_name", "type" => "string"},
      %{"name" => "last_name", "type" => "string"},
      %{"name" => "full_name", "type" => "string"},
      %{"name" => "profile_image_url", "type" => "string", "optional" => true},
      %{"name" => "specialty_name", "type" => "string", "optional" => true},
      %{"name" => "specialty_slug", "type" => "string", "optional" => true, "facet" => true},
      %{"name" => "bio", "type" => "string", "optional" => true},
      %{"name" => "city", "type" => "string", "optional" => true, "facet" => true},
      %{"name" => "address", "type" => "string", "optional" => true},
      %{"name" => "rating", "type" => "float"},
      %{"name" => "review_count", "type" => "int32", "optional" => true},
      %{"name" => "consultation_fee", "type" => "float", "optional" => true},
      %{"name" => "location", "type" => "geopoint", "optional" => true},
      %{"name" => "verified", "type" => "bool"},
      %{"name" => "title", "type" => "string", "optional" => true},
      %{"name" => "pronouns", "type" => "string", "optional" => true},
      %{"name" => "next_available_slot", "type" => "int64", "optional" => true},
      %{"name" => "has_cal_com", "type" => "bool"}
    ],
    "default_sorting_field" => "rating"
  }

  @doc """
  Creates or recreates the doctors collection in Typesense.
  """
  def create_collection do
    # Delete if exists
    _ = delete_collection()

    url = "#{typesense_url()}/collections"

    case Req.post(url,
           json: @collection_schema,
           headers: [{"X-TYPESENSE-API-KEY", api_key()}]
         ) do
      {:ok, %{status: 201, body: body}} ->
        Logger.info("Typesense collection '#{@collection_name}' created")
        {:ok, body}

      {:ok, %{status: 409}} ->
        Logger.info("Typesense collection '#{@collection_name}' already exists")
        {:ok, :already_exists}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to create collection: #{status} - #{inspect(body)}")
        {:error, body}

      {:error, reason} ->
        Logger.error("Failed to create collection: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Deletes the doctors collection.
  """
  def delete_collection do
    url = "#{typesense_url()}/collections/#{@collection_name}"

    case Req.delete(url, headers: [{"X-TYPESENSE-API-KEY", api_key()}]) do
      {:ok, %{status: 200}} ->
        Logger.info("Deleted Typesense collection '#{@collection_name}'")
        {:ok, :deleted}

      {:ok, %{status: 404}} ->
        {:ok, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Indexes a single doctor document (upsert).
  """
  def index_doctor(%Doctor{} = doctor) do
    doctor = Ash.load!(doctor, :specialty)
    doc = doctor_to_document(doctor)

    url = "#{typesense_url()}/collections/#{@collection_name}/documents?action=upsert"

    case Req.post(url,
           json: doc,
           headers: [{"X-TYPESENSE-API-KEY", api_key()}]
         ) do
      {:ok, %{status: status}} when status in [200, 201] ->
        Logger.debug("Indexed doctor: #{doctor.id}")
        :ok

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to index doctor #{doctor.id}: #{status} - #{inspect(body)}")
        {:error, body}

      {:error, reason} ->
        Logger.error("Failed to index doctor #{doctor.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Removes a doctor from the search index.
  """
  def delete_doctor(%Doctor{id: id}), do: delete_doctor_by_id(id)

  def delete_doctor_by_id(id) when is_binary(id) do
    url = "#{typesense_url()}/collections/#{@collection_name}/documents/#{id}"

    case Req.delete(url, headers: [{"X-TYPESENSE-API-KEY", api_key()}]) do
      {:ok, %{status: 200}} ->
        Logger.debug("Deleted doctor from index: #{id}")
        :ok

      {:ok, %{status: 404}} ->
        Logger.debug("Doctor #{id} not in index")
        :ok

      {:error, reason} ->
        Logger.warning("Failed to delete doctor #{id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Syncs all verified doctors to Typesense.
  """
  def sync_all_doctors do
    case create_collection() do
      {:ok, _} -> :ok
      {:error, reason} -> Logger.warning("Collection issue: #{inspect(reason)}")
    end

    doctors = Doctors.list_doctors(verified: true, preload: [:specialty])
    Logger.info("Syncing #{length(doctors)} doctors to Typesense...")

    results =
      doctors
      |> Enum.map(&index_doctor/1)
      |> Enum.count(&(&1 == :ok))

    Logger.info("Synced #{results}/#{length(doctors)} doctors to Typesense")
    {:ok, results}
  end

  @doc """
  Searches for doctors.
  """
  def search_doctors(opts \\ []) do
    query = Keyword.get(opts, :query, "*")
    per_page = Keyword.get(opts, :per_page, 20)
    page = Keyword.get(opts, :page, 1)

    filters = build_filters(opts)
    sort_by = build_sort_by(opts)

    params = %{
      "q" => query,
      "query_by" => "first_name,last_name,full_name,specialty_name,city,bio",
      "per_page" => per_page,
      "page" => page,
      "sort_by" => sort_by,
      "filter_by" => filters
    }

    url = "#{typesense_url()}/collections/#{@collection_name}/documents/search"

    case Req.get(url,
           params: params,
           headers: [{"X-TYPESENSE-API-KEY", api_key()}]
         ) do
      {:ok, %{status: 200, body: %{"hits" => hits, "found" => found}}} ->
        results = Enum.map(hits, &doc_to_result/1)
        {:ok, %{results: results, total: found, page: page, per_page: per_page}}

      {:ok, %{status: 404}} ->
        Logger.error("Search failed: Collection not found")
        {:error, "Not found."}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Search failed: #{status} - #{inspect(body)}")
        {:error, body}

      {:error, reason} ->
        Logger.error("Search failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp doc_to_result(%{"document" => doc}) do
    %{
      id: doc["id"],
      first_name: doc["first_name"],
      last_name: doc["last_name"],
      full_name: doc["full_name"],
      specialty_name: doc["specialty_name"],
      specialty_slug: doc["specialty_slug"],
      city: doc["city"],
      address: doc["address"],
      rating: doc["rating"],
      review_count: doc["review_count"],
      consultation_fee: doc["consultation_fee"],
      verified: doc["verified"],
      title: doc["title"],
      pronouns: doc["pronouns"],
      next_available_slot:
        if(doc["next_available_slot"],
          do: DateTime.from_unix!(doc["next_available_slot"]),
          else: nil
        ),
      has_cal_com: doc["has_cal_com"],
      location_lat: if(doc["location"], do: Enum.at(doc["location"], 0), else: nil),
      location_lng: if(doc["location"], do: Enum.at(doc["location"], 1), else: nil),
      profile_image_url: doc["profile_image_url"]
    }
  end

  defp doctor_to_document(%Doctor{} = doctor) do
    doc = %{
      "id" => doctor.id,
      "first_name" => doctor.first_name || "",
      "last_name" => doctor.last_name || "",
      "full_name" => "#{doctor.first_name} #{doctor.last_name}",
      "profile_image_url" => doctor.profile_image_url || "",
      "bio" => doctor.bio || "",
      "city" => doctor.city || "",
      "address" => doctor.address || "",
      "rating" => doctor.rating || 0.0,
      "review_count" => doctor.review_count || 0,
      "consultation_fee" =>
        if(doctor.consultation_fee, do: Decimal.to_float(doctor.consultation_fee), else: 0.0),
      "verified" => doctor.verified_at != nil,
      "title" => doctor.title || "",
      "pronouns" => doctor.pronouns || "",
      "next_available_slot" =>
        if(doctor.next_available_slot, do: DateTime.to_unix(doctor.next_available_slot), else: nil),
      "has_cal_com" => false
    }

    doc =
      if Ecto.assoc_loaded?(doctor.specialty) && doctor.specialty do
        Map.merge(doc, %{
          "specialty_name" => doctor.specialty.name_en || "",
          "specialty_slug" => doctor.specialty.slug || ""
        })
      else
        Map.merge(doc, %{"specialty_name" => "", "specialty_slug" => ""})
      end

    if doctor.location_lat && doctor.location_lng do
      Map.put(doc, "location", [doctor.location_lat, doctor.location_lng])
    else
      doc
    end
  end

  defp build_filters(opts) do
    filters = []

    filters =
      if Keyword.get(opts, :verified_only, true), do: ["verified:=true" | filters], else: filters

    filters =
      case Keyword.get(opts, :specialty),
        do: (
          nil -> filters
          slug -> ["specialty_slug:=#{slug}" | filters]
        )

    filters =
      case Keyword.get(opts, :city),
        do: (
          nil -> filters
          city -> ["city:=#{city}" | filters]
        )

    filters =
      case Keyword.get(opts, :min_rating),
        do: (
          nil -> filters
          rating -> ["rating:>=#{rating}" | filters]
        )

    filters =
      case Keyword.get(opts, :max_price),
        do: (
          nil -> filters
          price -> ["consultation_fee:<=#{price}" | filters]
        )

    filters =
      case Keyword.get(opts, :has_cal_com),
        do: (
          true -> ["has_cal_com:=true" | filters]
          _ -> filters
        )

    Enum.join(filters, " && ")
  end

  defp build_sort_by(opts) do
    case Keyword.get(opts, :sort_by) do
      "price_low" ->
        "consultation_fee:asc"

      "price_high" ->
        "consultation_fee:desc"

      "reviews" ->
        "review_count:desc"

      _ ->
        # Default or "rating" - check for geo sort
        case {Keyword.get(opts, :lat), Keyword.get(opts, :lng)} do
          {lat, lng} when is_number(lat) and is_number(lng) ->
            "location(#{lat}, #{lng}):asc,rating:desc"

          _ ->
            "rating:desc"
        end
    end
  end
end
