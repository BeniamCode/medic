defmodule MedicWeb.API.DoctorPortalController do
  @moduledoc """
  Doctor Portal API controller for mobile app.
  Handles doctor-specific dashboard, patients, and schedule management.
  """
  use MedicWeb, :controller

  alias Medic.Doctors
  alias Medic.Appointments
  alias Medic.Scheduling

  action_fallback MedicWeb.API.FallbackController

  # --- Dashboard ---

  @doc """
  GET /api/doctor/dashboard
  Returns dashboard stats for the logged-in doctor.
  """
  def dashboard(conn, _params) do
    user = conn.assigns.current_user
    
    case get_doctor(user.id) do
      nil ->
        {:error, :not_found}
      
      doctor ->
        # Get stats
        today_appointments = Appointments.list_doctor_appointments_today(doctor.id)
        pending_count = count_by_status(doctor.id, "pending")
        upcoming_count = Appointments.count_upcoming_doctor_appointments(doctor.id)
        
        conn
        |> put_status(:ok)
        |> json(%{
          data: %{
            doctor_id: doctor.id,
            today_appointments: Enum.map(today_appointments, &appointment_summary/1),
            pending_count: pending_count,
            upcoming_count: upcoming_count
          }
        })
    end
  end

  # --- My Patients ---

  @doc """
  GET /api/doctor/patients
  Lists patients the doctor has seen.
  """
  def patients(conn, _params) do
    user = conn.assigns.current_user
    
    case get_doctor(user.id) do
      nil ->
        {:error, :not_found}
      
      doctor ->
        patients = Doctors.list_my_patients(doctor.id)
        
        conn
        |> put_status(:ok)
        |> json(%{data: Enum.map(patients, &patient_summary/1)})
    end
  end

  # --- Schedule Management ---

  @doc """
  GET /api/doctor/schedule
  Returns doctor's schedule rules and exceptions.
  """
  def schedule(conn, _params) do
    user = conn.assigns.current_user
    
    case get_doctor(user.id) do
      nil ->
        {:error, :not_found}
      
      doctor ->
        rules = Scheduling.list_schedule_rules_for_ui(doctor.id)
        exceptions = Scheduling.list_availability_exceptions(doctor.id, upcoming_only: true)
        
        conn
        |> put_status(:ok)
        |> json(%{
          data: %{
            rules: Enum.map(rules, &rule_to_json/1),
            exceptions: Enum.map(exceptions, &exception_to_json/1)
          }
        })
    end
  end

  @doc """
  PUT /api/doctor/schedule
  Updates doctor's schedule rules.
  """
  def update_schedule(conn, params) do
    user = conn.assigns.current_user
    
    case get_doctor(user.id) do
      nil ->
        {:error, :not_found}
      
      doctor ->
        case Scheduling.bulk_upsert_schedule_rules!(doctor.id, params) do
          result when is_map(result) ->
            conn
            |> put_status(:ok)
            |> json(%{success: true})
          
          _ ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "Failed to update schedule"})
        end
    end
  rescue
    e ->
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: Exception.message(e)})
  end

  @doc """
  POST /api/doctor/schedule/exceptions
  Creates a time-off exception.
  """
  def create_exception(conn, params) do
    user = conn.assigns.current_user
    
    case get_doctor(user.id) do
      nil ->
        {:error, :not_found}
      
      doctor ->
        with {:ok, starts_at} <- parse_datetime(params["starts_at"]),
             {:ok, ends_at} <- parse_datetime(params["ends_at"]) do
          attrs = %{
            doctor_id: doctor.id,
            starts_at: starts_at,
            ends_at: ends_at,
            reason: params["reason"] || "day_off",
            status: "blocked",
            source: "manual"
          }

          case Scheduling.create_availability_exception(attrs) do
            {:ok, exception} ->
              conn
              |> put_status(:created)
              |> json(%{data: exception_to_json(exception)})
            
            {:error, _} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "Failed to create exception"})
          end
        else
          _ ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: "Invalid datetime format"})
        end
    end
  end

  @doc """
  DELETE /api/doctor/schedule/exceptions/:id
  Deletes a time-off exception.
  """
  def delete_exception(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    
    case get_doctor(user.id) do
      nil ->
        {:error, :not_found}
      
      doctor ->
        case Scheduling.get_availability_exception(id) do
          {:ok, exception} when exception.doctor_id == doctor.id ->
            case Scheduling.delete_availability_exception(exception) do
              :ok ->
                conn
                |> put_status(:ok)
                |> json(%{success: true})
              
              _ ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{error: "Failed to delete"})
            end
          
          _ ->
            {:error, :not_found}
        end
    end
  end

  # --- Private Helpers ---

  defp get_doctor(user_id) do
    Doctors.get_doctor_by_user_id(user_id)
  end

  defp count_by_status(doctor_id, status) do
    Appointments.list_appointments(doctor_id: doctor_id, status: status)
    |> length()
  end

  defp appointment_summary(appt) do
    %{
      id: appt.id,
      starts_at: appt.starts_at && DateTime.to_iso8601(appt.starts_at),
      status: appt.status,
      patient_name: if(appt.patient, do: "#{appt.patient.first_name} #{appt.patient.last_name}")
    }
  end

  defp patient_summary(patient) do
    %{
      patient_id: patient.patient_id,
      first_name: patient.first_name,
      last_name: patient.last_name,
      date_of_birth: patient.date_of_birth,
      age: patient.age,
      visit_count: patient.visit_count,
      last_visit: patient.last_visit && DateTime.to_iso8601(patient.last_visit)
    }
  end

  defp rule_to_json(rule) do
    %{
      id: rule.id,
      day_of_week: rule.day_of_week,
      start_time: format_time(rule.start_time),
      end_time: format_time(rule.end_time),
      break_start: format_time(rule.break_start),
      break_end: format_time(rule.break_end),
      slot_duration_minutes: rule.slot_duration_minutes || 30,
      is_active: rule.is_active
    }
  end

  defp exception_to_json(ex) do
    %{
      id: ex.id,
      starts_at: DateTime.to_iso8601(ex.starts_at),
      ends_at: DateTime.to_iso8601(ex.ends_at),
      reason: ex.reason
    }
  end

  defp format_time(nil), do: nil
  defp format_time(%Time{} = time), do: Calendar.strftime(time, "%H:%M")
  defp format_time(_), do: nil

  defp parse_datetime(nil), do: {:error, :missing}
  defp parse_datetime(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> {:ok, dt}
      _ -> {:error, :invalid}
    end
  end
end
