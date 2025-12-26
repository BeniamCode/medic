defmodule Medic.Workers.SendEmail do
  @moduledoc """
  Oban worker for delivering email notifications.

  Accepts an email type and appointment ID, loads the necessary data,
  composes the email using Medic.Emails, and delivers via Medic.Mailer.
  """

  use Oban.Worker, queue: :mailers, max_attempts: 5

  alias Medic.Appointments
  alias Medic.Emails
  alias Medic.AppointmentsMailer, as: Mailer


  require Logger

  @email_types ~w(
    appointment_confirmation
    appointment_cancelled_patient
    appointment_cancelled_doctor
    appointment_reminder
    new_booking_for_doctor
    new_appointment_request
    appointment_declined
    reschedule_proposed
  )

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    email_type = Map.get(args, "email_type")
    appointment_id = Map.get(args, "appointment_id")
    hours_before = Map.get(args, "hours_before")

    if email_type not in @email_types do
      Logger.warning("SendEmail: Unknown email type #{email_type}")
      :discard
    else
      send_email(email_type, appointment_id, hours_before)
    end
  end

  defp send_email(email_type, appointment_id, hours_before) do
    Logger.info("SendEmail: Starting #{email_type} for appointment #{appointment_id}")
    appointment = load_appointment(appointment_id)

    if is_nil(appointment) do
      Logger.warning("SendEmail: Appointment #{appointment_id} not found")
      :discard
    else
      Logger.info("SendEmail: Appointment loaded, building email...")
      
      try do
        email = build_email(email_type, appointment, hours_before)

        if is_nil(email) do
          Logger.warning("SendEmail: Could not build email for #{email_type}")
          :discard
        else
          Logger.info("SendEmail: Email built, delivering...")
          deliver_email(email, email_type, appointment_id)
        end
      rescue
        e ->
          Logger.error("SendEmail: CRASH in build_email: #{inspect(e)}")
          Logger.error(Exception.format(:error, e, __STACKTRACE__))
          :discard
      end
    end
  end

  defp load_appointment(appointment_id) do
    appointment = Appointments.get_appointment!(appointment_id)

    Ash.load!(appointment, [
      patient: [:user],
      doctor: [:user, :specialty]
    ])
  rescue
    _ -> nil
  end

  defp build_email("appointment_confirmation", appointment, _) do
    Emails.appointment_confirmation(appointment)
  end

  defp build_email("new_booking_for_doctor", appointment, _) do
    Emails.new_booking_for_doctor(appointment)
  end

  defp build_email("appointment_cancelled_patient", appointment, _) do
    Emails.appointment_cancelled_patient(appointment)
  end

  defp build_email("appointment_cancelled_doctor", appointment, _) do
    Emails.appointment_cancelled_doctor(appointment)
  end

  defp build_email("appointment_reminder", appointment, hours_before) do
    Emails.appointment_reminder(appointment, hours_before || 24)
  end

  defp build_email("new_appointment_request", appointment, _) do
    Emails.new_appointment_request(appointment)
  end

  defp build_email("appointment_declined", appointment, reason) do
    Emails.appointment_declined(appointment, reason)
  end

  defp build_email("reschedule_proposed", appointment, extra) do
    previous_starts_at = Map.get(extra || %{}, "previous_starts_at")
    new_starts_at = Map.get(extra || %{}, "new_starts_at")
    
    # Parse ISO8601 strings back to DateTime if needed
    prev = parse_datetime(previous_starts_at)
    new_dt = parse_datetime(new_starts_at)
    
    Emails.reschedule_proposed(appointment, prev, new_dt)
  end

  defp build_email(_, _, _), do: nil

  defp parse_datetime(%DateTime{} = dt), do: dt
  defp parse_datetime(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
  defp parse_datetime(_), do: nil

  defp deliver_email(email, email_type, appointment_id) do
    template_name = Map.get(email.private, :template_name, email_type)
    to_address = List.first(email.to) |> elem(1)
    
    result = Mailer.deliver(email)
    
    log_attrs = %{
      to: to_address,
      subject: email.subject,
      template_name: template_name,
      triggered_by: "worker",
      html_body: email.html_body
    }

    case result do
      {:ok, _result} ->
        Logger.info("SendEmail: Delivered #{email_type} for appointment #{appointment_id}")
        Medic.Notifications.create_email_log(Map.merge(log_attrs, %{status: :sent}))
        :ok

      {:error, reason} ->
        Logger.error(
          "SendEmail: Failed to deliver #{email_type} for appointment #{appointment_id}: #{inspect(reason)}"
        )
        Medic.Notifications.create_email_log(Map.merge(log_attrs, %{status: :failed, error: inspect(reason)}))

        {:error, reason}
    end
  end

  # --- Public API for enqueueing emails ---

  @doc """
  Enqueues an appointment confirmation email for the patient.
  """
  def enqueue_confirmation(appointment_id) do
    %{email_type: "appointment_confirmation", appointment_id: appointment_id}
    |> new()
    |> Oban.insert()
  end

  @doc """
  Enqueues a new booking alert email for the doctor.
  """
  def enqueue_doctor_alert(appointment_id) do
    %{email_type: "new_booking_for_doctor", appointment_id: appointment_id}
    |> new()
    |> Oban.insert()
  end

  @doc """
  Enqueues a cancellation email for the patient.
  """
  def enqueue_cancelled_patient(appointment_id) do
    %{email_type: "appointment_cancelled_patient", appointment_id: appointment_id}
    |> new()
    |> Oban.insert()
  end

  @doc """
  Enqueues a cancellation email for the doctor.
  """
  def enqueue_cancelled_doctor(appointment_id) do
    %{email_type: "appointment_cancelled_doctor", appointment_id: appointment_id}
    |> new()
    |> Oban.insert()
  end

  @doc """
  Enqueues a reminder email for a specific time before the appointment.
  """
  def enqueue_reminder(appointment_id, hours_before, scheduled_at \\ nil) do
    job_args = %{
      email_type: "appointment_reminder",
      appointment_id: appointment_id,
      hours_before: hours_before
    }

    opts = if scheduled_at, do: [scheduled_at: scheduled_at], else: []

    job_args
    |> new(opts)
    |> Oban.insert()
  end

  @doc """
  Enqueues an email to the doctor for a new appointment request (action required).
  """
  def enqueue_new_request_doctor(appointment_id) do
    %{email_type: "new_appointment_request", appointment_id: appointment_id}
    |> new()
    |> Oban.insert()
  end

  @doc """
  Enqueues a declined email to the patient.
  """
  def enqueue_declined_patient(appointment_id, reason \\ nil) do
    %{email_type: "appointment_declined", appointment_id: appointment_id, hours_before: reason}
    |> new()
    |> Oban.insert()
  end

  @doc """
  Enqueues a reschedule proposed email to the patient.
  """
  def enqueue_reschedule_proposed(appointment_id, previous_starts_at, new_starts_at) do
    %{
      email_type: "reschedule_proposed",
      appointment_id: appointment_id,
      hours_before: %{
        previous_starts_at: DateTime.to_iso8601(previous_starts_at),
        new_starts_at: DateTime.to_iso8601(new_starts_at)
      }
    }
    |> new()
    |> Oban.insert()
  end
end
