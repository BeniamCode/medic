defmodule Medic.Notifications do
  @moduledoc """
  The Notifications context.
  """

  use Ash.Domain

  resources do
    resource Medic.Notifications.Notification
    resource Medic.Notifications.NotificationJob
    resource Medic.Notifications.NotificationDelivery
  end

  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [change: 2, add_error: 3]

  alias Medic.Notifications.{Notification, NotificationJob}
  alias Medic.Workers.NotificationDispatch
  alias Oban
  require Logger
  require Ash.Query

  @doc """
  Returns the list of notifications.

  ## Examples

      iex> list_notifications()
      [%Notification{}, ...]

  """
  def list_notifications do
    Ash.read!(Notification)
  end

  @doc """
  Gets a single notification.

  Raises `Ecto.NoResultsError` if the Notification does not exist.

  ## Examples

      iex> get_notification!(123)
      %Notification{}

      iex> get_notification!(456)
      ** (Ecto.NoResultsError)

  """
  def get_notification!(id), do: Ash.get!(Notification, id)

  @doc """
  Creates a notification and broadcasts it.
  """
  def create_notification(attrs \\ %{}) do
    Notification
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
    |> normalize_result()
    |> case do
      {:ok, notification} ->
        broadcast_notification(notification)
        {:ok, notification}

      error ->
        error
    end
  end

  def list_user_notifications(user_id, limit \\ 20) do
    Notification
    |> Ash.Query.filter(user_id == ^user_id)
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.Query.limit(limit)
    |> Ash.read!()
  end

  def list_unread_count(user_id) do
    Notification
    |> Ash.Query.filter(user_id == ^user_id and is_nil(read_at))
    |> Ash.count!()
  end

  def mark_as_read(notification_id) do
    notification = get_notification!(notification_id)

    notification
    |> Ash.Changeset.for_update(:update, %{read_at: DateTime.utc_now()})
    |> Ash.update()
    |> normalize_result()
    |> case do
      {:ok, updated} ->
        broadcast_unread_count(updated.user_id)
        {:ok, updated}

      other ->
        other
    end
  end

  def mark_as_read_for_user(user_id, notification_id) do
    Notification
    |> Ash.Query.filter(id == ^notification_id and user_id == ^user_id)
    |> Ash.read_one()
    |> case do
      {:ok, nil} ->
        {:error, :not_found}

      {:ok, notification} ->
        notification
        |> Ash.Changeset.for_update(:update, %{read_at: DateTime.utc_now()})
        |> Ash.update()
        |> normalize_result()
        |> case do
          {:ok, updated} ->
            broadcast_unread_count(updated.user_id)
            {:ok, updated}

          other ->
            other
        end

      other ->
        other
    end
  end

  def mark_all_as_read(user_id) do
    # Ash doesn't have a direct update_all equivalent that runs validations/changesets for each,
    # but for bulk updates we can use Ash.bulk_update or manual iteration.
    # For now, let's use Ash.bulk_update if available (Ash 3.0) or iterate.
    # Since this is a simple update, we can use Ash.bulk_update.
    # However, to be safe and simple:

    result =
      Notification
      |> Ash.Query.filter(user_id == ^user_id and is_nil(read_at))
      |> Ash.bulk_update(:update, %{read_at: DateTime.utc_now()}, strategy: :atomic)

    case result do
      {:ok, %Ash.BulkResult{} = bulk} ->
        broadcast_unread_count(user_id)
        {:ok, bulk}

      %Ash.BulkResult{} = bulk ->
        broadcast_unread_count(user_id)
        {:ok, bulk}

      {:error, _} = error ->
        error

      other ->
        other
    end
  end

  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(Medic.PubSub, "user_notifications:#{user_id}")
  end

  def broadcast_unread_count(user_id) do
    count = list_unread_count(user_id)

    Phoenix.PubSub.broadcast(
      Medic.PubSub,
      "user_notifications:#{user_id}",
      {:unread_count, count}
    )

    :ok
  end

  defp broadcast_notification(notification) do
    Logger.info("Broadcasting notification to user_notifications:#{notification.user_id}")

    Phoenix.PubSub.broadcast(
      Medic.PubSub,
      "user_notifications:#{notification.user_id}",
      {:new_notification, notification}
    )
  end

  @doc """
  Updates a notification.
  """
  def update_notification(%Notification{} = notification, attrs) do
    notification
    |> Ash.Changeset.for_update(:update, attrs)
    |> Ash.update()
    |> normalize_result()
  end

  # --- Outbox (notification_jobs) ---

  @doc """
  Enqueue a notification job; schedules an Oban worker at scheduled_at (or now).
  attrs: user_id (required), channel, template, payload (map), scheduled_at.
  """
  def enqueue_notification_job(attrs) do
    attrs = Map.new(attrs)

    NotificationJob
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
    |> normalize_result()
    |> case do
      {:ok, job} ->
        schedule_dispatch(job)
        {:ok, job}

      error ->
        error
    end
  end

  defp schedule_dispatch(%NotificationJob{} = job) do
    schedule_at = job.scheduled_at || DateTime.utc_now()

    %{"notification_job_id" => job.id}
    |> NotificationDispatch.new(scheduled_at: schedule_at)
    |> Oban.insert()
    |> case do
      {:ok, _oban_job} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Deletes a notification.

  ## Examples

      iex> delete_notification(notification)
      {:ok, %Notification{}}

      iex> delete_notification(notification)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notification(%Notification{} = notification) do
    case Ash.destroy(notification) do
      :ok -> {:ok, notification}
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notification changes.

  ## Examples

      iex> change_notification(notification)
      %Ecto.Changeset{data: %Notification{}}

  """
  def change_notification(%Notification{} = notification, attrs \\ %{}) do
    Notification.changeset(notification, attrs)
  end

  defp normalize_result({:ok, result}), do: {:ok, result}

  defp normalize_result({:error, %Ash.Error.Invalid{errors: errors}}) do
    base_changeset = change({%{}, %{}}, %{})

    ecto_changeset =
      Enum.reduce(errors, base_changeset, fn error, changeset ->
        message = Map.get(error, :message) || "is invalid"
        field = Map.get(error, :field, :base)
        add_error(changeset, field, message)
      end)

    {:error, ecto_changeset}
  end

  defp normalize_result(other), do: other
end
