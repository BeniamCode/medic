defmodule MedicWeb.DashboardController do
  use MedicWeb, :controller

  alias Medic.Appointments
  alias Medic.Patients

  def show(conn, _params) do
    current_user = conn.assigns.current_user

    with {:ok, patient} <- fetch_patient(current_user) do
      upcoming =
        Appointments.list_appointments(
          patient_id: patient.id,
          upcoming: true,
          preload: [doctor: [:specialty]]
        )

      past =
        Appointments.list_appointments(
          patient_id: patient.id,
          status: ["completed", "cancelled", "no_show"],
          preload: [doctor: [:specialty]]
        )

      stats = patient_stats(patient)

      conn
      |> assign(:page_title, dgettext("default", "Dashboard"))
      |> assign_prop(:patient, %{id: patient.id, first_name: patient.first_name, last_name: patient.last_name})
      |> assign_prop(:upcoming_appointments, Enum.map(upcoming, &appointment_props/1))
      |> assign_prop(:past_appointments, Enum.map(past, &appointment_props/1))
      |> assign_prop(:stats, stats)
      |> render_inertia("Patient/Dashboard")
    else
      _ -> redirect(conn, to: ~p"/onboarding/doctor")
    end
  end

  defp fetch_patient(%{id: user_id}) do
    case Patients.get_patient_by_user_id(user_id) do
      nil -> {:error, :not_found}
      patient -> {:ok, patient}
    end
  end

  defp appointment_props(appointment) do
    doctor = appointment.doctor

    %{
      id: appointment.id,
      starts_at: DateTime.to_iso8601(appointment.starts_at),
      status: appointment.status,
      doctor: %{
        id: doctor.id,
        first_name: doctor.first_name,
        last_name: doctor.last_name,
        specialty: doctor.specialty && doctor.specialty.name_en
      }
    }
  end

  defp patient_stats(patient) do
    completed =
      Appointments.list_appointments(patient_id: patient.id, status: "completed")
      |> length()

    cancelled =
      Appointments.list_appointments(patient_id: patient.id, status: "cancelled")
      |> length()

    %{
      upcoming: length(Appointments.list_appointments(patient_id: patient.id, upcoming: true)),
      completed: completed,
      cancelled: cancelled
    }
  end
end
