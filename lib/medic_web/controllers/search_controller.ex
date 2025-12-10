defmodule MedicWeb.SearchController do
  use MedicWeb, :controller

  alias Medic.Doctors
  alias Medic.Search
  alias Medic.Doctors.Specialty
  alias Decimal

  def index(conn, params) do
    query = params["q"] |> to_string() |> String.trim()
    specialty_slug = params["specialty"] |> normalize_blank()

    {doctors, meta} = fetch_doctors(query, specialty_slug)

    page_title = dgettext("default", "Find a doctor")

    conn
    |> assign(:page_title, page_title)
    |> assign_prop(:page_title, page_title)
    |> assign_prop(:filters, %{query: query, specialty: specialty_slug})
    |> assign_prop(:specialties, format_specialties())
    |> assign_prop(:doctors, doctors)
    |> assign_prop(:meta, meta)
    |> render_inertia("Public/Search")
  end

  defp normalize_blank(value) when value in [nil, ""], do: nil
  defp normalize_blank(value), do: value

  defp fetch_doctors("", specialty_slug) do
    specialty_id = specialty_slug |> specialty_from_slug() |> maybe_specialty_id()

    Doctors.list_doctors(
      verified: true,
      specialty_id: specialty_id,
      preload: [:specialty]
    )
    |> Enum.take(24)
    |> then(fn docs ->
      {Enum.map(docs, &doctor_to_props/1), %{total: length(docs), source: "catalog"}}
    end)
  end

  defp fetch_doctors(query, specialty_slug) do
    opts = [query: query, specialty: specialty_slug, per_page: 24]

    case Search.search_doctors(opts) do
      {:ok, %{results: results, total: total}} ->
        {Enum.map(results, &search_result_to_props/1), %{total: total, source: "search"}}

      {:error, _reason} ->
        {[], %{total: 0, source: "search"}}
    end
  end

  defp format_specialties do
    Doctors.list_specialties()
    |> Enum.map(fn specialty ->
      %{
        id: specialty.id,
        name: specialty.name_en,
        slug: specialty.slug
      }
    end)
  end

  defp doctor_to_props(doctor) do
    %{
      id: doctor.id,
      first_name: doctor.first_name,
      last_name: doctor.last_name,
      specialty_name: (doctor.specialty && doctor.specialty.name_en) || nil,
      city: doctor.city,
      rating: doctor.rating,
      review_count: doctor.review_count,
      consultation_fee: doctor.consultation_fee && Decimal.to_float(doctor.consultation_fee),
      verified: not is_nil(doctor.verified_at),
      profile_image_url: doctor.profile_image_url
    }
  end

  defp search_result_to_props(result) do
    %{
      id: result.id,
      first_name: result.first_name,
      last_name: result.last_name,
      specialty_name: result.specialty_name,
      city: result.city,
      rating: result.rating,
      review_count: result.review_count,
      consultation_fee: result.consultation_fee,
      verified: result.verified,
      profile_image_url: result.profile_image_url
    }
  end

  defp specialty_from_slug(nil), do: nil
  defp specialty_from_slug(slug), do: Doctors.get_specialty_by_slug(slug)

  defp maybe_specialty_id(%Specialty{id: id}), do: id
  defp maybe_specialty_id(_), do: nil
end
