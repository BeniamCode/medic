defmodule MedicWeb.DoctorDashboardController do
  use MedicWeb, :controller

  alias Medic.Appointments
  alias Medic.Doctors
  alias Medic.Patients.Patient

  def show(conn, _params) do
    user = conn.assigns.current_user

    with {:ok, doctor} <- fetch_doctor(user) do
      today = Appointments.list_doctor_appointments_today(doctor.id)
      stats = doctor_stats(doctor)
      pending = pending_requests(doctor.id)

      conn
      |> assign(:page_title, dgettext("default", "Doctor Dashboard"))
      |> assign_prop(:doctor, doctor_props(doctor))
      |> assign_prop(:today_appointments, Enum.map(today, &appointment_props/1))
      |> assign_prop(:pending_count, pending)
      |> assign_prop(:upcoming_count, stats.upcoming)
      |> render_inertia("Doctor/Dashboard")
    else
      _ -> redirect(conn, to: ~p"/dashboard/doctor/profile")
    end
  end

  defp fetch_doctor(user) do
    case Doctors.get_doctor_by_user_id(user.id) do
      nil -> {:error, :not_found}
      doctor -> {:ok, Ash.load!(doctor, [:specialty])}
    end
  end

  defp doctor_props(doctor) do
    %{
      id: doctor.id,
      first_name: doctor.first_name,
      last_name: doctor.last_name,
      rating: doctor.rating && Float.round(doctor.rating, 1),
      review_count: doctor.review_count,
      verified: not is_nil(doctor.verified_at)
    }
  end

  defp appointment_props(appt) do
    patient = appt.patient || %Patient{}

    appointment_type_name =
      appt.service_name_snapshot ||
        (appt.appointment_type_record && appt.appointment_type_record.name)

    %{
      id: appt.id,
      starts_at: DateTime.to_iso8601(appt.starts_at),
      duration_minutes: appt.duration_minutes,
      notes: appt.notes,
      status: appt.status,
      appointment_type_id: appt.appointment_type_id,
      appointment_type_name: appointment_type_name,
      consultation_mode: appt.consultation_mode_snapshot,
      patient: %{
        first_name: patient.first_name,
        last_name: patient.last_name
      }
    }
  end

  defp doctor_stats(doctor) do
    upcoming =
      Appointments.list_appointments(doctor_id: doctor.id, status: "confirmed")
      |> length()

    %{upcoming: upcoming}
  end

  defp pending_requests(doctor_id) do
    Appointments.list_appointments(doctor_id: doctor_id, status: "pending")
    |> length()
  end
end
