defmodule Medic.Notifications do
  @moduledoc """
  The Notifications context.
  """

  use Ash.Domain

  resources do
    resource Medic.Notifications.Notification
  end

  import Ecto.Query, warn: false


  alias Medic.Notifications.Notification
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
    result =
      Notification
      |> Ash.Changeset.for_create(:create, attrs)
      |> Ash.create()

    case result do
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
    get_notification!(notification_id)
    |> Ash.Changeset.for_update(:update, %{read_at: DateTime.utc_now()})
    |> Ash.update()
  end

  def mark_all_as_read(user_id) do
    # Ash doesn't have a direct update_all equivalent that runs validations/changesets for each,
    # but for bulk updates we can use Ash.bulk_update or manual iteration.
    # For now, let's use Ash.bulk_update if available (Ash 3.0) or iterate.
    # Since this is a simple update, we can use Ash.bulk_update.
    # However, to be safe and simple:
    
    Notification
    |> Ash.Query.filter(user_id == ^user_id and is_nil(read_at))
    |> Ash.bulk_update(:update, %{read_at: DateTime.utc_now()}, strategy: :atomic)
  end

  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(Medic.PubSub, "user_notifications:#{user_id}")
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
    Ash.destroy(notification)
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
end
