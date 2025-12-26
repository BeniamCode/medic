defmodule Medic.Workers.AppointmentReminder do
  @moduledoc """
  Cron job that finds upcoming appointments and enqueues reminder emails.

  Runs every 15 minutes and sends reminders:
  - 24 hours before the appointment
  - 2 hours before the appointment

  Uses the appointment's notification tracking to avoid duplicate reminders.
  """

  use Oban.Worker, queue: :mailers, max_attempts: 3

  import Ecto.Query

  alias Medic.Appointments.Appointment
  alias Medic.Repo
  alias Medic.Workers.SendEmail

  require Logger

  # Reminder windows in hours
  @reminder_windows [24, 2]

  @impl Oban.Worker
  def perform(_job) do
    now = DateTime.utc_now()

    for hours <- @reminder_windows do
      send_reminders_for_window(now, hours)
    end

    :ok
  end

  defp send_reminders_for_window(now, hours_before) do
    # Find appointments starting in approximately `hours_before` hours
    # with a 15-minute window to account for cron timing
    window_start = DateTime.add(now, hours_before * 60 * 60 - 8 * 60, :second)
    window_end = DateTime.add(now, hours_before * 60 * 60 + 8 * 60, :second)

    appointments =
      Appointment
      |> where([a], a.status == "confirmed")
      |> where([a], a.starts_at >= ^window_start and a.starts_at <= ^window_end)
      |> Repo.all()

    Logger.info(
      "AppointmentReminder: Found #{length(appointments)} appointments for #{hours_before}h reminder window"
    )

    for appointment <- appointments do
      # Check if reminder already sent (using Oban's unique job feature)
      case SendEmail.enqueue_reminder(appointment.id, hours_before) do
        {:ok, _job} ->
          Logger.info(
            "AppointmentReminder: Enqueued #{hours_before}h reminder for appointment #{appointment.id}"
          )

        {:error, %Ecto.Changeset{errors: [_ | _]}} ->
          # Likely a duplicate; Oban unique constraint prevented insertion
          :ok

        {:error, reason} ->
          Logger.warning(
            "AppointmentReminder: Failed to enqueue reminder for #{appointment.id}: #{inspect(reason)}"
          )
      end
    end
  end
end
