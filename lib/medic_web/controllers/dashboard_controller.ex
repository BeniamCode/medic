defmodule MedicWeb.DashboardController do
  use MedicWeb, :controller

  alias Medic.Appointments
  alias Medic.Patients

  def show(conn, params) do
    current_user = conn.assigns.current_user
    tab = Map.get(params, "tab", "dashboard")

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
          preload: [doctor: [:specialty], appreciation: [], experience_submission: []]
        )

      stats = patient_stats(patient)
      
      my_doctors = 
        if tab == "doctors" do
          Patients.list_my_doctors(patient.id)
          |> Enum.map(&doctor_props/1)
        else
          []
        end

      conn
      |> assign(:page_title, dgettext("default", "Dashboard"))
      |> assign_prop(:patient, %{
        firstName: patient.first_name,
        lastName: patient.last_name
      })
      |> assign_prop(:upcomingAppointments, Enum.map(upcoming, &appointment_props/1))
      |> assign_prop(:pastAppointments, Enum.map(past, &appointment_props/1))
      |> assign_prop(:stats, stats)
      |> assign_prop(:myDoctors, my_doctors)
      |> assign_prop(:activeTab, tab)
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
      startsAt: DateTime.to_iso8601(appointment.starts_at),
      endsAt: appointment.ends_at && DateTime.to_iso8601(appointment.ends_at),
      status: appointment.status,
      consultationMode: appointment.consultation_mode_snapshot,
      pendingExpiresAt:
        appointment.pending_expires_at && DateTime.to_iso8601(appointment.pending_expires_at),
      rescheduledFromAppointmentId: appointment.rescheduled_from_appointment_id,
      appreciated: not is_nil(appointment.appreciation),
      hasExperienceSubmission: not is_nil(appointment.experience_submission),
      doctor: %{
        id: doctor.id,
        firstName: doctor.first_name,
        lastName: doctor.last_name,
        specialty: doctor.specialty && doctor.specialty.name_en,
        avatarUrl: Map.get(doctor, :avatar_url) || Map.get(doctor, :profile_image_url)
      }
    }
  end

  defp doctor_props(d) do
    %{
      id: d.doctor_id,
      firstName: d.first_name,
      lastName: d.last_name,
      specialty: d.specialty,
      profileImageUrl: d.profile_image_url,
      rating: d.rating,
      visitCount: d.visit_count,
      lastVisit: d.last_visit && DateTime.to_iso8601(d.last_visit),
      firstVisit: d.first_visit && DateTime.to_iso8601(d.first_visit),
      hasContext: not is_nil(d.context),
      tags: (d.context && d.context.tags) || []
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
