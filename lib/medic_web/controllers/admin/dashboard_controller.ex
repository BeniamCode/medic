defmodule MedicWeb.Admin.DashboardController do
  use MedicWeb, :controller

  alias Medic.Appointments.Appointment
  alias Medic.Doctors.Doctor
  alias Medic.Repo

  import Ecto.Query

  def index(conn, _params) do
    stats = calculate_stats()

    conn
    |> assign(:page_title, "Admin Dashboard")
    |> render_inertia("Admin/Dashboard", stats)
  end

  defp calculate_stats do
    now = DateTime.utc_now()
    today_start = DateTime.truncate(now, :second)
    today_end = DateTime.add(today_start, 24 * 3600, :second)

    # Pending doctors (not verified)
    pending_doctors =
      Doctor
      |> where([d], is_nil(d.verified_at))
      |> Repo.aggregate(:count, :id)

    # Today's appointments
    todays_appointments =
      Appointment
      |> where([a], a.starts_at >= ^today_start and a.starts_at < ^today_end)
      |> where([a], a.status in ["pending", "confirmed"])
      |> Repo.aggregate(:count, :id)

    # Estimated revenue (sum of price_cents for today)
    todays_revenue_cents =
      Appointment
      |> where([a], a.starts_at >= ^today_start and a.starts_at < ^today_end)
      |> where([a], a.status in ["confirmed", "completed"])
      |> select([a], sum(a.price_cents))
      |> Repo.one()
      |> Kernel.||(0)

    todays_revenue = (todays_revenue_cents / 100) |> Float.round(2)

    %{
      pending_doctors: pending_doctors,
      todays_appointments: todays_appointments,
      todays_revenue: todays_revenue
    }
  end
end
