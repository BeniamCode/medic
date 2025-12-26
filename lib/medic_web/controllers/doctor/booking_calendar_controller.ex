defmodule MedicWeb.Doctor.BookingCalendarController do
  @moduledoc """
  Controller for doctor booking calendar operations.
  """
  use MedicWeb, :controller

  alias Medic.Appointments

  @doc """
  Render the calendar page.
  """
  def index(conn, _params) do
    user = conn.assigns.current_user
    
    # Fetch doctor from user
    doctor = Medic.Repo.get_by(Medic.Doctors.Doctor, user_id: user.id)
    
    unless doctor do
      conn
      |> put_flash(:error, "Doctor profile not found")
      |> redirect(to: "/dashboard/doctor/profile")
      |> halt()
    else
      # Get current month data
      today = Date.utc_today()
      month_start = Date.beginning_of_month(today)
      month_end = Date.end_of_month(today)
      
      counts = Appointments.get_appointment_counts_by_date(doctor.id, month_start, month_end)
      
      # Convert counts to JSON-serializable format
      formatted_counts =
        counts
        |> Enum.map(fn {date, count} ->
          {Date.to_iso8601(date), count}
        end)
        |> Map.new()
      
      conn
      |> assign_prop(:doctor, %{
        id: doctor.id,
        firstName: doctor.first_name,
        lastName: doctor.last_name
      })
      |> assign_prop(:today, Date.to_iso8601(today))
      |> assign_prop(:month_counts, formatted_counts)
      |> render_inertia("Doctor/BookingCalendar")
    end
  end

  @doc """
  Fetch appointment counts for a specific month (AJAX).
  """
  def month_data(conn, %{"year" => year_str, "month" => month_str}) do
    user = conn.assigns.current_user
    doctor = Medic.Repo.get_by(Medic.Doctors.Doctor, user_id: user.id)
    
    year = String.to_integer(year_str)
    month = String.to_integer(month_str)
    
    month_start = Date.new!(year, month, 1)
    month_end = Date.end_of_month(month_start)
    
    counts = Appointments.get_appointment_counts_by_date(doctor.id, month_start, month_end)
    
    # Convert to JSON-serializable format
    formatted_counts =
      counts
      |> Enum.map(fn {date, count} ->
        {Date.to_iso8601(date), count}
      end)
      |> Map.new()
    
    json(conn, %{counts: formatted_counts})
  end

  @doc """
  Fetch available slots for a specific day (AJAX).
  """
  def day_slots(conn, %{"date" => date_str}) do
    user = conn.assigns.current_user
    doctor = Medic.Repo.get_by(Medic.Doctors.Doctor, user_id: user.id)
    
    {:ok, date} = Date.from_iso8601(date_str)
    
    slots = Appointments.get_day_slots(doctor.id, date)
    
    # Format slots for JSON
    formatted_slots = Enum.map(slots, fn slot ->
      %{
        starts_at: DateTime.to_iso8601(slot.starts_at),
        ends_at: DateTime.to_iso8601(slot.ends_at),
        status: slot.status
      }
    end)
    
    json(conn, %{slots: formatted_slots, date: date_str})
  end

  @doc """
  Search for a patient by email/phone (AJAX).
  """
  def search_patient(conn, params) do
    email = Map.get(params, "email", "")
    phone = Map.get(params, "phone", "")
    
    patients = Medic.Patients.search_patients_by_contact(email, phone)
    
    # Format patients for JSON
    formatted_patients = Enum.map(patients, fn patient ->
      %{
        id: patient.id,
        first_name: patient.first_name,
        last_name: patient.last_name,
        email: get_patient_email(patient),
        phone: patient.phone,
        doctor_initiated: patient.doctor_initiated
      }
    end)
    
    json(conn, %{patients: formatted_patients})
  end

  @doc """
  Create a doctor-initiated booking (AJAX).
  """
  def create_booking(conn, params) do
    user = conn.assigns.current_user
    doctor = Medic.Repo.get_by(Medic.Doctors.Doctor, user_id: user.id)
    
    booking_attrs = %{
      starts_at: params["starts_at"],
      ends_at: params["ends_at"],
      duration_minutes: params["duration_minutes"] || 30,
      consultation_mode_snapshot: params["consultation_mode"] || "in_person",
      status: params["status"] || "confirmed",
      notes: params["notes"]
    }
    
    patient_attrs = %{
      first_name: params["patient"]["first_name"],
      last_name: params["patient"]["last_name"],
      email: params["patient"]["email"],
      phone: params["patient"]["phone"]
    }
    
    case Appointments.create_doctor_booking(doctor.id, booking_attrs, patient_attrs) do
      {:ok, appointment} ->
        appointment = Ash.load!(appointment, [:patient])
        
        json(conn, %{
          success: true,
          appointment: %{
            id: appointment.id,
            starts_at: DateTime.to_iso8601(appointment.starts_at),
            patient: %{
              first_name: appointment.patient.first_name,
              last_name: appointment.patient.last_name
            }
          }
        })
        
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: format_error(reason)})
    end
  end

  # Helper to get patient email (from user association if exists)
  defp get_patient_email(patient) do
    patient = Ash.load!(patient, [:user])
    if patient.user, do: patient.user.email, else: Map.get(patient, :email)
  end

  defp format_error(:slot_already_booked), do: "This time slot is already booked"
  defp format_error(:multiple_patients_found), do: "Multiple patients found with this contact information"
  defp format_error(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end
  defp format_error(other), do: inspect(other)
end
