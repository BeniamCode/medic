defmodule MedicWeb.API.AppointmentController do
  @moduledoc """
  Appointment API controller for mobile app.
  Handles listing, viewing, booking, and managing appointments.
  """
  use MedicWeb, :controller

  alias Medic.Appointments
  alias Medic.Scheduling
  alias Medic.Repo

  action_fallback MedicWeb.API.FallbackController

  @doc """
  GET /api/appointments
  Lists appointments for the current user.
  """
  def index(conn, params) do
    user = conn.assigns.current_user
    status = params["status"]
    
    opts = case user.role do
      "doctor" ->
        doctor = get_doctor_for_user(user.id)
        [doctor_id: doctor && doctor.id, status: status, preload: [:patient, :doctor]]
      
      "patient" ->
        patient = get_patient_for_user(user.id)
        [patient_id: patient && patient.id, status: status, preload: [:patient, :doctor]]
      
      _ ->
        []
    end

    appointments = Appointments.list_appointments(opts)
    
    conn
    |> put_status(:ok)
    |> json(%{data: Enum.map(appointments, &appointment_to_json/1)})
  end

  @doc """
  GET /api/appointments/:id
  Gets a single appointment with details.
  """
  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    
    try do
      appointment = Appointments.get_appointment_with_details!(id)
      
      # Verify user has access to this appointment
      if authorized_for_appointment?(user, appointment) do
        conn
        |> put_status(:ok)
        |> json(%{data: appointment_to_json(appointment)})
      else
        {:error, :unauthorized}
      end
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
    end
  end

  @doc """
  POST /api/appointments
  Books a new appointment.
  """
  def create(conn, params) do
    user = conn.assigns.current_user
    patient = get_patient_for_user(user.id)
    
    unless patient do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Only patients can book appointments"})
    else
      doctor_id = params["doctor_id"]
      starts_at = parse_datetime(params["starts_at"])
      ends_at = parse_datetime(params["ends_at"])
      appointment_type_slug = params["appointment_type"] || "in-person"
      notes = params["notes"]

      # Lookup appointment type
      appointment_type_id = 
        case Medic.Appointments.get_appointment_type_by_slug(appointment_type_slug, doctor_id) do
          {:ok, type} -> type.id
          _ -> nil
        end

      if is_nil(appointment_type_id) do
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid appointment type"})
      else
        attrs = %{
          doctor_id: doctor_id,
          patient_id: patient.id,
          starts_at: starts_at,
          ends_at: ends_at,
          appointment_type_id: appointment_type_id,
          notes: notes,
          status: "pending"
        }

        case Appointments.hold_slot(attrs) do
          {:ok, appointment} ->
            # Submit as pending request
            case Appointments.submit_request(appointment) do
              {:ok, submitted} ->
                conn
                |> put_status(:created)
                |> json(%{data: appointment_to_json(submitted)})
              
              {:error, reason} ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{error: "Failed to submit: #{inspect(reason)}"})
            end

          {:error, reason} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "Failed to book: #{inspect(reason)}"})
        end
      end
    end
  end

  @doc """
  POST /api/appointments/:id/cancel
  Cancels an appointment.
  """
  def cancel(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user
    reason = params["reason"]
    
    try do
      appointment = Appointments.get_appointment!(id)
      
      if authorized_for_appointment?(user, appointment) do
        case Appointments.cancel_appointment(appointment, reason) do
          {:ok, cancelled} ->
            conn
            |> put_status(:ok)
            |> json(%{data: appointment_to_json(cancelled)})
          
          {:error, reason} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "Failed to cancel: #{inspect(reason)}"})
        end
      else
        {:error, :unauthorized}
      end
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
    end
  end

  @doc """
  POST /api/appointments/:id/approve
  Doctor approves a pending appointment.
  """
  def approve(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    
    if user.role != "doctor" do
      {:error, :unauthorized}
    else
      try do
        appointment = Appointments.get_appointment!(id)
        doctor = get_doctor_for_user(user.id)
        
        if doctor && appointment.doctor_id == doctor.id do
          case Appointments.approve_request(appointment) do
            {:ok, approved} ->
              conn
              |> put_status(:ok)
              |> json(%{data: appointment_to_json(approved)})
            
            {:error, reason} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "Failed to approve: #{inspect(reason)}"})
          end
        else
          {:error, :unauthorized}
        end
      rescue
        Ecto.NoResultsError -> {:error, :not_found}
      end
    end
  end

  @doc """
  POST /api/appointments/:id/reject
  Doctor rejects a pending appointment.
  """
  def reject(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user
    reason = params["reason"]
    
    if user.role != "doctor" do
      {:error, :unauthorized}
    else
      try do
        appointment = Appointments.get_appointment!(id)
        doctor = get_doctor_for_user(user.id)
        
        if doctor && appointment.doctor_id == doctor.id do
          case Appointments.reject_request(appointment, reason) do
            {:ok, rejected} ->
              conn
              |> put_status(:ok)
              |> json(%{data: appointment_to_json(rejected)})
            
            {:error, reason} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "Failed to reject: #{inspect(reason)}"})
          end
        else
          {:error, :unauthorized}
        end
      rescue
        Ecto.NoResultsError -> {:error, :not_found}
      end
    end
  end

  @doc """
  POST /api/appointments/:id/appreciate
  Patient appreciates doctor after an appointment.
  """
  def appreciate(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user
    patient = get_patient_for_user(user.id)
    
    unless patient do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Only patients can appreciate"})
    else
      try do
        appointment = Appointments.get_appointment!(id)
        
        if appointment.patient_id != patient.id do
          {:error, :unauthorized}
        else
          case Medic.Appreciate.Service.appreciate_appointment(%{
            appointment_id: id,
            patient_id: patient.id,
            note_text: params["note_text"]
          }) do
            {:ok, appreciation} ->
              conn
              |> put_status(:created)
              |> json(%{data: %{id: appreciation.id, message: "Appreciation submitted"}})
            
            {:error, error} ->
              error_text = inspect(error)
              status = if String.contains?(error_text, "unique_appointment") or String.contains?(error_text, "already"), do: :conflict, else: :unprocessable_entity
              conn
              |> put_status(status)
              |> json(%{error: if(status == :conflict, do: "Already appreciated", else: "Failed to appreciate")})
          end
        end
      rescue
        Ecto.NoResultsError -> {:error, :not_found}
      end
    end
  end

  @doc """
  POST /api/appointments/:id/experience
  Patient submits experience rating after an appointment.
  """
  def experience(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user
    patient = get_patient_for_user(user.id)
    
    unless patient do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Only patients can submit experience"})
    else
      try do
        appointment = Appointments.get_appointment!(id)
        
        if appointment.patient_id != patient.id do
          {:error, :unauthorized}
        else
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
            {:ok, submission} ->
              conn
              |> put_status(:created)
              |> json(%{data: %{id: submission.id, message: "Experience submitted"}})
            
            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "Failed to submit experience"})
          end
        end
      rescue
        Ecto.NoResultsError -> {:error, :not_found}
      end
    end
  end

  @doc """
  POST /api/appointments/:id/reschedule
  Request to reschedule an appointment.
  """
  def reschedule(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user
    
    try do
      appointment = Appointments.get_appointment!(id)
      new_starts_at = parse_datetime(params["new_starts_at"])
      
      unless new_starts_at do
        conn
        |> put_status(:bad_request)
        |> json(%{error: "new_starts_at is required"})
      else
        if authorized_for_appointment?(user, appointment) do
          case Appointments.reschedule_request(appointment, new_starts_at) do
            {:ok, updated} ->
              conn
              |> put_status(:ok)
              |> json(%{data: appointment_to_json(updated)})
            
            {:error, reason} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "Failed to reschedule: #{inspect(reason)}"})
          end
        else
          {:error, :unauthorized}
        end
      end
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
    end
  end

  @doc """
  POST /api/appointments/:id/approve_reschedule
  Patient approves a reschedule proposed by doctor.
  """
  def approve_reschedule(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    patient = get_patient_for_user(user.id)
    
    unless patient do
      {:error, :unauthorized}
    else
      try do
        appointment = Appointments.get_appointment!(id)
        
        if appointment.patient_id == patient.id do
          case Appointments.approve_request(appointment) do
            {:ok, updated} ->
              conn
              |> put_status(:ok)
              |> json(%{data: appointment_to_json(updated)})
            
            {:error, reason} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "Failed to approve: #{inspect(reason)}"})
          end
        else
          {:error, :unauthorized}
        end
      rescue
        Ecto.NoResultsError -> {:error, :not_found}
      end
    end
  end

  @doc """
  POST /api/appointments/:id/reject_reschedule
  Patient rejects a reschedule proposed by doctor.
  """
  def reject_reschedule(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user
    patient = get_patient_for_user(user.id)
    reason = params["reason"]
    
    unless patient do
      {:error, :unauthorized}
    else
      try do
        appointment = Appointments.get_appointment!(id)
        
        if appointment.patient_id == patient.id do
          case Appointments.reject_request(appointment, reason) do
            {:ok, updated} ->
              conn
              |> put_status(:ok)
              |> json(%{data: appointment_to_json(updated)})
            
            {:error, reason} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "Failed to reject: #{inspect(reason)}"})
          end
        else
          {:error, :unauthorized}
        end
      rescue
        Ecto.NoResultsError -> {:error, :not_found}
      end
    end
  end

  # --- Private Helpers ---

  defp get_doctor_for_user(user_id) do
    Medic.Doctors.get_doctor_by_user_id(user_id)
  end

  defp get_patient_for_user(user_id) do
    Medic.Patients.get_patient_by_user_id(user_id)
  end

  defp authorized_for_appointment?(user, appointment) do
    cond do
      user.role == "doctor" ->
        doctor = get_doctor_for_user(user.id)
        doctor && appointment.doctor_id == doctor.id
      
      user.role == "patient" ->
        patient = get_patient_for_user(user.id)
        patient && appointment.patient_id == patient.id
      
      user.role == "admin" ->
        true
      
      true ->
        false
    end
  end

  defp parse_datetime(nil), do: nil
  defp parse_datetime(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
  defp parse_datetime(%DateTime{} = dt), do: dt

  defp appointment_to_json(appointment) do
    # Ensure association is loaded
    appointment = Ash.load!(appointment, [:doctor, :patient, :appointment_type_record])

    %{
      id: appointment.id,
      status: appointment.status,
      starts_at: appointment.starts_at && DateTime.to_iso8601(appointment.starts_at),
      ends_at: appointment.ends_at && DateTime.to_iso8601(appointment.ends_at),
      appointment_type: if(appointment.appointment_type_record, do: appointment.appointment_type_record.slug, else: "unknown"),
      notes: appointment.notes,
      doctor: if(Ecto.assoc_loaded?(appointment.doctor) && appointment.doctor, do: %{
        id: appointment.doctor.id,
        first_name: appointment.doctor.first_name,
        last_name: appointment.doctor.last_name,
        profile_image_url: appointment.doctor.profile_image_url
      }),
      patient: if(Ecto.assoc_loaded?(appointment.patient) && appointment.patient, do: %{
        id: appointment.patient.id,
        first_name: appointment.patient.first_name,
        last_name: appointment.patient.last_name
      }),
      inserted_at: appointment.inserted_at && DateTime.to_iso8601(appointment.inserted_at)
    }
  end
end
