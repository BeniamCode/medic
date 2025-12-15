defmodule MedicWeb.SearchController do
  use MedicWeb, :controller

  alias Medic.Doctors
  alias Medic.Search
  alias Medic.Appreciate.DoctorAppreciationStat

  import Ecto.Query
  alias Medic.Repo

  def index(conn, params) do
    query = params["q"] |> to_string() |> String.trim()
    specialty_slug = params["specialty"] |> normalize_blank()
    city = params["city"] |> normalize_blank()
    max_price = parse_int(params["max_price"])
    telemedicine_only = params["telemedicine"] == "true" or params["online"] == "true"
    insurance = params["insurance"] |> normalize_blank()

    {doctors, meta} =
      fetch_doctors(query, specialty_slug, city, max_price, telemedicine_only, insurance)

    page_title = dgettext("default", "Find a doctor")

    conn
    |> assign(:page_title, page_title)
    |> assign_prop(:page_title, page_title)
    |> assign_prop(:filters, %{
      query: query,
      specialty: specialty_slug,
      city: city,
      max_price: max_price,
      telemedicine: telemedicine_only,
      insurance: insurance
    })
    |> assign_prop(:specialties, format_specialties())
    |> assign_prop(:cities, cities())
    |> assign_prop(:insurances, insurances())
    |> assign_prop(:doctors, doctors)
    |> assign_prop(:meta, meta)
    |> render_inertia("Public/Search")
  end

  defp normalize_blank(value) when value in [nil, ""], do: nil
  defp normalize_blank(value), do: value

  defp fetch_doctors("", specialty_slug, city, max_price, telemedicine_only, insurance),
    do: fetch_doctors("*", specialty_slug, city, max_price, telemedicine_only, insurance)

  defp fetch_doctors(nil, specialty_slug, city, max_price, telemedicine_only, insurance),
    do: fetch_doctors("*", specialty_slug, city, max_price, telemedicine_only, insurance)

  defp fetch_doctors(query, specialty_slug, city, max_price, telemedicine_only, insurance) do
    opts =
      [
        query: query,
        specialty: specialty_slug,
        city: city,
        max_price: max_price,
        telemedicine_only: telemedicine_only,
        insurance: insurance,
        verified_only: true,
        per_page: 24
      ]

    case Search.search_doctors(opts) do
      {:ok, %{results: results, total: total}} ->
        appreciation_counts = appreciation_counts_by_doctor_id(results)

        {Enum.map(results, &search_result_to_props(&1, appreciation_counts)),
         %{total: total, source: "search"}}

      {:error, _reason} ->
        {[], %{total: 0, source: "search"}}
    end
  end

  defp appreciation_counts_by_doctor_id(results) do
    doctor_ids = Enum.map(results, & &1.id)

    Repo.all(
      from s in DoctorAppreciationStat,
        where: s.doctor_id in ^doctor_ids,
        select: {s.doctor_id, s.appreciated_total_distinct_patients}
    )
    |> Map.new()
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

  defp search_result_to_props(result, appreciation_counts) do
    %{
      id: result.id,
      first_name: result.first_name,
      last_name: result.last_name,
      specialty_name: result.specialty_name,
      city: result.city,
      rating: result.rating,
      review_count: result.review_count,
      appreciation_count: Map.get(appreciation_counts, result.id, result.appreciation_count),
      consultation_fee: result.consultation_fee,
      verified: result.verified,
      profile_image_url: result.profile_image_url,
      location_lat: result.location_lat,
      location_lng: result.location_lng,
      address: result.address
    }
  end

  defp cities do
    [
      "Athens",
      "Thessaloniki",
      "Patras",
      "Heraklion",
      "Larissa",
      "Volos",
      "Ioannina",
      "Chania",
      "Rhodes",
      "Alexandroupoli",
      "Kalamata",
      "Kavala",
      "Serres",
      "Corfu"
    ]
  end

  defp insurances do
    [
      "ΕΟΠΥΥ",
      "Interamerican",
      "Eurolife",
      "Ethniki",
      "Generali",
      "Other"
    ]
  end

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {i, _} -> i
      :error -> nil
    end
  end

  defp parse_int(val) when is_integer(val), do: val
end
