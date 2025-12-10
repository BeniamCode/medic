defmodule MedicWeb.AppointmentsController do
  use MedicWeb, :controller

  alias Medic.Appointments

  def show(conn, %{"id" => id}) do
    appointment = Appointments.get_appointment_with_details!(id)

    conn
    |> assign(:page_title, dgettext("default", "Appointment"))
    |> assign_prop(:appointment, appointment_props(appointment))
    |> render_inertia("Patient/AppointmentDetail")
  end

  defp appointment_props(appointment) do
    %{
      id: appointment.id,
      starts_at: DateTime.to_iso8601(appointment.starts_at),
      ends_at: DateTime.to_iso8601(appointment.ends_at),
      status: appointment.status,
      notes: appointment.notes,
      doctor: %{
        id: appointment.doctor.id,
        first_name: appointment.doctor.first_name,
        last_name: appointment.doctor.last_name,
        specialty: appointment.doctor.specialty && appointment.doctor.specialty.name_en
      },
      patient: %{
        id: appointment.patient.id,
        first_name: appointment.patient.first_name,
        last_name: appointment.patient.last_name
      }
    }
  end
end
