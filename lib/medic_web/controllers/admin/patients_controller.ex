defmodule MedicWeb.Admin.PatientsController do
  use MedicWeb, :controller

  alias Medic.Patients.Patient
  alias Medic.Repo

  import Ecto.Query

  def index(conn, params) do
    page = String.to_integer(params["page"] || "1")
    per_page = 20
    search = params["search"]

    query = build_patients_query(search)

    total = Repo.aggregate(query, :count, :id)

    patients =
      query
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> order_by([p], desc: p.inserted_at)
      |> Repo.all()

    # Load Ash relationships
    patients = Ash.load!(patients, [:user])

    patients_data =
      Enum.map(patients, fn patient ->
        %{
          id: patient.id,
          first_name: patient.first_name,
          last_name: patient.last_name,
          email: patient.user.email,
          phone: patient.phone,
          date_of_birth: patient.date_of_birth,
          inserted_at: patient.inserted_at
        }
      end)

    conn
    |> assign(:page_title, "Patient Management")
    |> render_inertia("Admin/Patients", %{
      patients: patients_data,
      pagination: %{
        current_page: page,
        per_page: per_page,
        total: total
      },
      search: search
    })
  end

  defp build_patients_query(nil) do
    from p in Patient
  end

  defp build_patients_query(search) do
    search_term = "%#{search}%"

    from p in Patient,
      left_join: u in assoc(p, :user),
      where:
        ilike(p.first_name, ^search_term) or
          ilike(p.last_name, ^search_term) or
          ilike(u.email, ^search_term)
  end
end

