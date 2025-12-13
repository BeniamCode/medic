defmodule MedicWeb.DoctorAppointmentsController do
  use MedicWeb, :controller

  alias Medic.Appointments
  alias Medic.Doctors

  def index(conn, _params) do
    user = conn.assigns.current_user

    with {:ok, doctor} <- fetch_doctor(user) do
      appointments =
        Appointments.list_appointments(
          doctor_id: doctor.id,
          preload: [:patient, :doctor, :appointment_type_record]
        )

      conn
      |> assign(:page_title, dgettext("default", "Appointments"))
      |> assign_prop(:appointments, Enum.map(appointments, &appointment_props/1))
      |> assign_prop(:counts, counts(appointments))
      |> render_inertia("Doctor/Appointments")
    else
      _ -> redirect(conn, to: ~p"/dashboard/doctor/profile")
    end
  end

  def approve(conn, %{"id" => id}) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user),
         {:ok, appointment} <- fetch_doctor_appointment(id, doctor.id),
         {:ok, _updated} <-
           do_approve(appointment, doctor) do
      conn
      |> put_flash(:success, dgettext("default", "Appointment approved"))
      |> redirect(to: ~p"/dashboard/doctor/appointments")
    else
      {:error, :not_found} -> not_found(conn)
      {:error, reason} -> handle_error(conn, reason)
    end
  end

  def reject(conn, %{"id" => id, "reason" => reason}) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user),
         {:ok, appointment} <- fetch_doctor_appointment(id, doctor.id),
         {:ok, _updated} <-
           do_reject(appointment, reason, doctor) do
      conn
      |> put_flash(:success, dgettext("default", "Appointment rejected"))
      |> redirect(to: ~p"/dashboard/doctor/appointments")
    else
      {:error, :not_found} -> not_found(conn)
      {:error, reason} -> handle_error(conn, reason)
    end
  end

  def reschedule(conn, %{"id" => id, "starts_at" => starts_at, "reason" => reason}) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user),
         {:ok, appointment} <- fetch_doctor_appointment(id, doctor.id),
         {:ok, starts_at_dt} <- parse_datetime(starts_at),
         {:ok, _updated} <-
           do_reschedule(appointment, starts_at_dt, doctor, reason) do
      conn
      |> put_flash(:success, dgettext("default", "Reschedule proposed to patient"))
      |> redirect(to: ~p"/dashboard/doctor/appointments")
    else
      {:error, :not_found} -> not_found(conn)
      {:error, reason} -> handle_error(conn, reason)
    end
  end

  def cancel(conn, %{"id" => id, "reason" => reason}) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user),
         {:ok, appointment} <- fetch_doctor_appointment(id, doctor.id),
         {:ok, _updated} <-
           Appointments.cancel_appointment(appointment, reason,
             cancelled_by: :doctor,
             cancelled_by_actor_type: :doctor,
             cancelled_by_actor_id: doctor.id
           ) do
      conn
      |> put_flash(:success, dgettext("default", "Appointment cancelled"))
      |> redirect(to: ~p"/dashboard/doctor/appointments")
    else
      {:error, :not_found} -> not_found(conn)
      {:error, reason} -> handle_error(conn, reason)
    end
  end

  defp fetch_doctor(user) do
    case Doctors.get_doctor_by_user_id(user.id) do
      nil -> {:error, :not_found}
      doctor -> {:ok, doctor}
    end
  end

  defp do_approve(appointment, doctor) do
    {:ok, Appointments.approve_request(appointment, %{actor_type: :doctor, actor_id: doctor.id})}
  rescue
    e -> {:error, e}
  end

  defp do_reject(appointment, reason, doctor) do
    Appointments.cancel_appointment(appointment, reason,
      cancelled_by: :doctor,
      cancelled_by_actor_type: :doctor,
      cancelled_by_actor_id: doctor.id
    )
  rescue
    e -> {:error, e}
  end

  defp do_reschedule(appointment, starts_at_dt, doctor, reason) do
    actor = %{actor_type: :doctor, actor_id: doctor.id}

    with {:ok, updated} <- Appointments.reschedule_request(appointment, starts_at_dt, actor) do
      if reason && reason != "" do
        _ = Appointments.log_event(updated.id, "reschedule_reason", %{reason: reason}, actor)
      end

      {:ok, updated}
    end
  end

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> {:ok, dt}
      _ -> {:error, :invalid_datetime}
    end
  end

  defp parse_datetime(%DateTime{} = dt), do: {:ok, dt}

  defp fetch_doctor_appointment(id, doctor_id) do
    appointment = Appointments.get_appointment_with_details!(id)

    if appointment.doctor_id == doctor_id do
      {:ok, appointment}
    else
      {:error, :not_found}
    end
  rescue
    _ -> {:error, :not_found}
  end

  defp appointment_props(appointment) do
    appointment_type_name =
      appointment.service_name_snapshot ||
        (appointment.appointment_type_record && appointment.appointment_type_record.name)

    patient = appointment.patient

    %{
      id: appointment.id,
      starts_at: DateTime.to_iso8601(appointment.starts_at),
      status: appointment.status,
      consultation_mode: appointment.consultation_mode_snapshot,
      pending_expires_at:
        appointment.pending_expires_at && DateTime.to_iso8601(appointment.pending_expires_at),
      appointment_type_name: appointment_type_name,
      notes: appointment.notes,
      patient:
        patient &&
          %{
            id: patient.id,
            first_name: patient.first_name,
            last_name: patient.last_name,
            phone: patient.phone,
            avatar_url: Map.get(patient, :profile_image_url)
          }
    }
  end

  defp counts(appointments) do
    %{
      total: length(appointments),
      pending: Enum.count(appointments, &(&1.status == "pending")),
      upcoming: Enum.count(appointments, &(&1.status in ["pending", "confirmed"])),
      completed: Enum.count(appointments, &(&1.status == "completed"))
    }
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_flash(:error, dgettext("default", "Appointment not found"))
    |> redirect(to: ~p"/dashboard/doctor/appointments")
  end

  defp handle_error(conn, _reason) do
    conn
    |> put_flash(:error, dgettext("default", "Unable to process appointment"))
    |> redirect(to: ~p"/dashboard/doctor/appointments")
  end
end
