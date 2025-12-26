defmodule MedicWeb.Admin.DoctorsController do
  use MedicWeb, :controller

  alias Medic.Doctors.Doctor
  alias Medic.Repo

  import Ecto.Query

  def index(conn, params) do
    page = String.to_integer(params["page"] || "1")
    per_page = 20
    search = params["search"]
    verified_filter = params["verified"]

    query = build_doctors_query(search, verified_filter)

    total = Repo.aggregate(query, :count, :id)

    doctors =
      query
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> order_by([d], desc: d.inserted_at)
      |> Repo.all()

    # Load Ash relationships
    doctors = Ash.load!(doctors, [:user, :specialty])

    doctors_data =
      Enum.map(doctors, fn doctor ->
        %{
          id: doctor.id,
          first_name: doctor.first_name,
          last_name: doctor.last_name,
          email: doctor.user.email,
          specialty: doctor.specialty && doctor.specialty.name_en,
          verified: !is_nil(doctor.verified_at),
          verified_at: doctor.verified_at,
          inserted_at: doctor.inserted_at
        }
      end)

    conn
    |> assign(:page_title, "Doctor Management")
    |> render_inertia("Admin/Doctors", %{
      doctors: doctors_data,
      pagination: %{
        current_page: page,
        per_page: per_page,
        total: total
      },
      search: search,
      verified_filter: verified_filter
    })
  end

  defp build_doctors_query(nil, nil) do
    from d in Doctor
  end

  defp build_doctors_query(search, nil) when is_binary(search) do
    search_term = "%#{search}%"

    from d in Doctor,
      left_join: u in assoc(d, :user),
      left_join: s in assoc(d, :specialty),
      where:
        ilike(d.first_name, ^search_term) or
          ilike(d.last_name, ^search_term) or
          ilike(u.email, ^search_term) or
          ilike(s.name, ^search_term)
  end

  defp build_doctors_query(nil, "verified") do
    from d in Doctor,
      where: not is_nil(d.verified_at)
  end

  defp build_doctors_query(nil, "pending") do
    from d in Doctor,
      where: is_nil(d.verified_at)
  end

  defp build_doctors_query(search, verified_filter) when is_binary(search) do
    search_term = "%#{search}%"

    base_query =
      from d in Doctor,
        left_join: u in assoc(d, :user),
        left_join: s in assoc(d, :specialty),
        where:
          ilike(d.first_name, ^search_term) or
            ilike(d.last_name, ^search_term) or
            ilike(u.email, ^search_term) or
            ilike(s.name, ^search_term)

    case verified_filter do
      "verified" -> from d in base_query, where: not is_nil(d.verified_at)
      "pending" -> from d in base_query, where: is_nil(d.verified_at)
      _ -> base_query
    end
  end

  defp build_doctors_query(_, _), do: from(d in Doctor)
end

