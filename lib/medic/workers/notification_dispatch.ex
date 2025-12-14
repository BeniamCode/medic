defmodule Medic.Workers.NotificationDispatch do
  @moduledoc """
  Delivers notification_jobs by creating in-app notifications.
  Acts as an outbox to decouple booking flows from delivery.
  """

  use Oban.Worker, queue: :mailers, max_attempts: 10

  alias Ash
  alias Ash.Changeset
  alias Medic.Notifications
  alias Medic.Notifications.{NotificationDelivery, NotificationJob}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"notification_job_id" => job_id}}) do
    job = Ash.get!(NotificationJob, job_id)

    cond do
      job.status != "pending" ->
        :ok

      scheduled_in_future?(job) ->
        {:snooze, seconds_until(job.scheduled_at)}

      true ->
        attempt_delivery(job)
    end
  rescue
    Ash.Error.Invalid -> :discard
  end

  defp attempt_delivery(job) do
    payload = job.payload || %{}
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    title = Map.get(payload, "title") || job.template || "Notification"
    message = Map.get(payload, "message") || "You have an update."
    type = Map.get(payload, "type") || "system"
    resource_id = Map.get(payload, "resource_id")
    resource_type = Map.get(payload, "resource_type")

    delivery_changeset = %{
      notification_job_id: job.id,
      channel: job.channel,
      attempted_at: now,
      status: "pending",
      response: %{}
    }

    case Notifications.create_notification(%{
           user_id: job.user_id,
           type: type,
           title: title,
           message: message,
           resource_id: resource_id,
           resource_type: resource_type,
           channel: job.channel,
           template: job.template,
           payload: payload
         }) do
      {:ok, _notif} ->
        NotificationDelivery
        |> Changeset.for_create(:create, Map.put(delivery_changeset, :status, "sent"))
        |> Ash.create()

        job
        |> Changeset.for_update(:update, %{
          status: "sent",
          attempts: job.attempts + 1,
          last_error: nil
        })
        |> Ash.update()

        :ok

      {:error, reason} ->
        NotificationDelivery
        |> Changeset.for_create(:create, Map.put(delivery_changeset, :status, "failed"))
        |> Ash.create()

        job
        |> Changeset.for_update(:update, %{
          status: "pending",
          attempts: job.attempts + 1,
          last_error: inspect(reason)
        })
        |> Ash.update()

        {:error, reason}
    end
  end

  defp scheduled_in_future?(%NotificationJob{scheduled_at: nil}), do: false

  defp scheduled_in_future?(%NotificationJob{scheduled_at: scheduled_at}) do
    DateTime.compare(scheduled_at, DateTime.utc_now()) == :gt
  end

  defp seconds_until(nil), do: 0

  defp seconds_until(dt) do
    max(1, DateTime.diff(dt, DateTime.utc_now(), :second))
  end
end
