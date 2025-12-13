defmodule MedicWeb.AppointmentsController do
  use MedicWeb, :controller

  alias Medic.Appointments
  alias Medic.Patients

  def show(conn, %{"id" => id}) do
    appointment = Appointments.get_appointment_with_details!(id)

    conn
    |> assign(:page_title, dgettext("default", "Appointment"))
    |> assign_prop(:appointment, appointment_props(appointment))
    |> render_inertia("Patient/AppointmentDetail")
  end

  def approve_reschedule(conn, %{"id" => id}) do
    with {:ok, appointment} <- fetch_patient_appointment(conn.assigns.current_user, id),
         {:ok, _updated} <-
           Appointments.approve_request(appointment, %{
             actor_type: :patient,
             actor_id: appointment.patient_id
           }) do
      respond_ok(conn, dgettext("default", "Appointment approved"))
    else
      {:error, :not_found} -> not_found(conn)
      {:error, _} -> handle_error(conn)
    end
  end

  def reject_reschedule(conn, %{"id" => id, "reason" => reason}) do
    with {:ok, appointment} <- fetch_patient_appointment(conn.assigns.current_user, id),
         {:ok, _updated} <-
           Appointments.cancel_appointment(appointment, reason,
             cancelled_by: :patient,
             cancelled_by_actor_type: :patient,
             cancelled_by_actor_id: appointment.patient_id
           ) do
      respond_ok(conn, dgettext("default", "Appointment rejected"))
    else
      {:error, :not_found} -> not_found(conn)
      {:error, _} -> handle_error(conn)
    end
  end

  def cancel(conn, %{"id" => id} = params) do
    reason = Map.get(params, "reason") || dgettext("default", "Cancelled by patient")

    with {:ok, appointment} <- fetch_patient_appointment(conn.assigns.current_user, id),
         {:ok, _updated} <-
           Appointments.cancel_appointment(appointment, reason,
             cancelled_by: :patient,
             cancelled_by_actor_type: :patient,
             cancelled_by_actor_id: appointment.patient_id
           ) do
      respond_ok(conn, dgettext("default", "Appointment cancelled"))
    else
      {:error, :not_found} -> not_found(conn)
      {:error, _} -> handle_error(conn)
    end
  end

  defp appointment_props(appointment) do
    %{
      id: appointment.id,
      starts_at: DateTime.to_iso8601(appointment.starts_at),
      ends_at: DateTime.to_iso8601(appointment.ends_at),
      status: appointment.status,
      pendingExpiresAt:
        appointment.pending_expires_at && DateTime.to_iso8601(appointment.pending_expires_at),
      rescheduledFromAppointmentId: appointment.rescheduled_from_appointment_id,
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

  defp fetch_patient_appointment(user, id) do
    case Patients.get_patient_by_user_id(user.id) do
      nil ->
        {:error, :not_found}

      patient ->
        appt = Appointments.get_appointment_with_details!(id)
        if appt.patient_id == patient.id, do: {:ok, appt}, else: {:error, :not_found}
    end
  rescue
    _ -> {:error, :not_found}
  end

  defp not_found(conn) do
    if ajax?(conn) do
      send_resp(conn, :not_found, "")
    else
      conn
      |> put_status(:not_found)
      |> put_flash(:error, dgettext("default", "Appointment not found"))
      |> redirect(to: ~p"/dashboard")
    end
  end

  defp handle_error(conn) do
    if ajax?(conn) do
      send_resp(conn, :unprocessable_entity, "")
    else
      conn
      |> put_flash(:error, dgettext("default", "Unable to process appointment"))
      |> redirect(to: ~p"/dashboard")
    end
  end

  defp respond_ok(conn, message) do
    if ajax?(conn) do
      send_resp(conn, :no_content, "")
    else
      conn
      |> put_flash(:success, message)
      |> redirect(to: ~p"/dashboard")
    end
  end

  defp ajax?(conn) do
    Enum.any?(get_req_header(conn, "x-requested-with"), fn h ->
      String.downcase(h) == "xmlhttprequest"
    end)
  end
end
