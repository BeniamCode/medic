defmodule MedicWeb.API.PatientPortalController do
  @moduledoc """
  Patient Portal API controller for mobile app.
  Handles patient-specific dashboard and doctor history.
  """
  use MedicWeb, :controller

  alias Medic.Patients
  alias Medic.Appointments

  action_fallback MedicWeb.API.FallbackController

  @doc """
  GET /api/patient/dashboard
  Returns dashboard stats for the logged-in patient.
  """
  def dashboard(conn, _params) do
    user = conn.assigns.current_user
    
    case get_patient(user.id) do
      nil ->
        {:error, :not_found}
      
      patient ->
        # Get upcoming appointments
        upcoming = Appointments.list_appointments(
          patient_id: patient.id,
          upcoming: true,
          preload: [:doctor]
        )
        
        # Get past appointments count
        past_count = Appointments.list_appointments(
          patient_id: patient.id,
          status: "completed"
        ) |> length()
        
        conn
        |> put_status(:ok)
        |> json(%{
          data: %{
            patient_id: patient.id,
            upcoming_appointments: Enum.map(Enum.take(upcoming, 5), &appointment_summary/1),
            upcoming_count: length(upcoming),
            completed_count: past_count
          }
        })
    end
  end

  @doc """
  GET /api/patient/doctors
  Lists doctors the patient has visited.
  """
  def doctors(conn, _params) do
    user = conn.assigns.current_user
    
    case get_patient(user.id) do
      nil ->
        {:error, :not_found}
      
      patient ->
        doctors = Patients.list_my_doctors(patient.id)
        
        conn
        |> put_status(:ok)
        |> json(%{data: Enum.map(doctors, &doctor_summary/1)})
    end
  end

  # --- Private Helpers ---

  defp get_patient(user_id) do
    Patients.get_patient_by_user_id(user_id)
  end

  defp appointment_summary(appt) do
    %{
      id: appt.id,
      starts_at: appt.starts_at && DateTime.to_iso8601(appt.starts_at),
      status: appt.status,
      doctor_name: if(appt.doctor, do: "Dr. #{appt.doctor.first_name} #{appt.doctor.last_name}"),
      doctor_id: appt.doctor_id
    }
  end

  defp doctor_summary(doc) do
    %{
      doctor_id: doc.doctor_id,
      first_name: doc.first_name,
      last_name: doc.last_name,
      specialty: doc.specialty,
      profile_image_url: doc.profile_image_url,
      rating: doc.rating,
      visit_count: doc.visit_count,
      last_visit: doc.last_visit && DateTime.to_iso8601(doc.last_visit)
    }
  end
end
