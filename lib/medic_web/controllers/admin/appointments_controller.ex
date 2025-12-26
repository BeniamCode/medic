defmodule MedicWeb.Admin.AppointmentsController do
  use MedicWeb, :controller

  alias Medic.Appointments
  alias Medic.Repo

  import Ecto.Query

  def index(conn, params) do
    page = String.to_integer(params["page"] || "1")
    per_page = 20
    status_filter = params["status"]

    query = build_appointments_query(status_filter)

    total = Repo.aggregate(query, :count, :id)

    appointments =
      query
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> order_by([a], desc: a.starts_at)
      |> Repo.all()
      |> Ash.load!([:patient, :doctor])

    appointments_data =
      Enum.map(appointments, fn appt ->
        %{
          id: appt.id,
          patient_name: get_patient_name(appt.patient),
          doctor_name: get_doctor_name(appt.doctor),
          starts_at: appt.starts_at,
          status: appt.status,
          duration_minutes: appt.duration_minutes,
          consultation_mode: appt.consultation_mode_snapshot,
          price_cents: appt.price_cents
        }
      end)

    conn
    |> assign(:page_title, "Appointment Management")
    |> render_inertia("Admin/Appointments", %{
      appointments: appointments_data,
      pagination: %{
        current_page: page,
        per_page: per_page,
        total: total
      },
      status_filter: status_filter
    })
  end

  def cancel(conn, %{"id" => id}) do
    appointment = Appointments.get_appointment!(id)

    case Appointments.cancel_appointment(appointment, "Cancelled by admin") do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Appointment cancelled successfully")
        |> redirect(to: ~p"/medic/appointments")

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to cancel appointment")
        |> redirect(to: ~p"/medic/appointments")
    end
  end

  defp build_appointments_query(nil) do
    from a in Medic.Appointments.Appointment
  end

  defp build_appointments_query(status) do
    from a in Medic.Appointments.Appointment,
      where: a.status == ^status
  end

  defp get_patient_name(%{user: %{first_name: fname, last_name: lname}}) when not is_nil(fname),
    do: "#{fname} #{lname}"

  defp get_patient_name(%{first_name: fname, last_name: lname}) when not is_nil(fname),
    do: "#{fname} #{lname}"

  defp get_patient_name(_), do: "Unknown"

  defp get_doctor_name(%{first_name: fname, last_name: lname}) when not is_nil(fname),
    do: "Dr. #{fname} #{lname}"

  defp get_doctor_name(_), do: "Unknown"
end
