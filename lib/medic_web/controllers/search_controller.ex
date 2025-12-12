defmodule MedicWeb.SearchController do
  use MedicWeb, :controller

  alias Medic.Doctors
  alias Medic.Search
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

  defp fetch_doctors("", specialty_slug), do: fetch_doctors("*", specialty_slug)

  defp fetch_doctors(nil, specialty_slug), do: fetch_doctors("*", specialty_slug)

  defp fetch_doctors(query, specialty_slug) do
    opts = [query: query, specialty: specialty_slug, per_page: 24]

    IO.puts("\n=== SEARCH DEBUG START ===")
    IO.inspect(opts, label: "Search Opts")

    case Search.search_doctors(opts) do
      {:ok, %{results: results, total: total}} ->
        IO.inspect(total, label: "Total Found")
        IO.inspect(List.first(results), label: "First Result")
        IO.puts("=== SEARCH DEBUG END ===\n")

        {Enum.map(results, &search_result_to_props/1), %{total: total, source: "search"}}

      {:error, reason} ->
        IO.inspect(reason, label: "Search Error")
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
      profile_image_url: result.profile_image_url,
      location_lat: result.location_lat,
      location_lng: result.location_lng,
      address: result.address
    }
  end
end
