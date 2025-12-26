defmodule MedicWeb.ExperienceSubmissionController do
  use MedicWeb, :controller



  def create(conn, %{"id" => appointment_id} = params) do
    # Ensure patient owns the appointment or check permissions via policies?
    # For now, we trust the appointment_id in the URL and the user session.
    # Ideally, we should fetch the appointment and verify it belongs to the current user.

    # But since we're using Ash, we can just use the create action.
    # However, we need to pass doctor_id and patient_id.
    # The frontend should probably pass the form data, but doctor_id and patient_id might be implicit or explicit.

    # Let's see what params we get.
    # We need to look up the appointment to get doctor_id and patient_id.
    
    appointment = Medic.Appointments.get_appointment!(appointment_id)
    
    # Verify ownership (simplistic check, ideally handled by Ash Policies)
    current_user = conn.assigns.current_user
    patient = Medic.Patients.get_patient_by_user_id(current_user.id)
    
    if appointment.patient_id != patient.id do
      send_resp(conn, 403, "Forbidden")
    else
      # Check if already submitted?
      # The UI should hide it, but good to check.
      
      attrs = 
        params
        |> Map.take([
          "communication_style",
          "explanation_style",
          "personality_tone",
          "pace",
          "appointment_timing",
          "consultation_style"
        ])
        |> Map.merge(%{
          "doctor_id" => appointment.doctor_id,
          "patient_id" => patient.id,
          "appointment_id" => appointment.id
        })
      
      
      result =
        Medic.Doctors.ExperienceSubmission
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create()

      case result do
        {:ok, _submission} ->
          conn
          |> put_status(:created)
          |> json(%{success: true})
        
        {:error, %Ash.Error.Invalid{errors: errors}} ->
           conn
           |> put_status(:unprocessable_entity)
           |> json(%{errors: errors})
           
        {:error, error} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: inspect(error)})
      end
    end
  end
end
