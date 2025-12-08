defmodule Medic.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query, warn: false
  alias Medic.Repo

  alias Medic.Notifications.Notification
  require Logger

  @doc """
  Returns the list of notifications.

  ## Examples

      iex> list_notifications()
      [%Notification{}, ...]

  """
  def list_notifications do
    Repo.all(Notification)
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
  def get_notification!(id), do: Repo.get!(Notification, id)

  @doc """
  Creates a notification and broadcasts it.
  """
  def create_notification(attrs \\ %{}) do
    result =
      %Notification{}
      |> Notification.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, notification} ->
        broadcast_notification(notification)
        {:ok, notification}
      error -> error
    end
  end

  def list_user_notifications(user_id, limit \\ 20) do
    from(n in Notification,
      where: n.user_id == ^user_id,
      order_by: [desc: n.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def list_unread_count(user_id) do
    Repo.one(from n in Notification, where: n.user_id == ^user_id and is_nil(n.read_at), select: count())
  end

  def mark_as_read(notification_id) do
    get_notification!(notification_id)
    |> Notification.changeset(%{read_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def mark_all_as_read(user_id) do
    from(n in Notification, where: n.user_id == ^user_id and is_nil(n.read_at))
    |> Repo.update_all(set: [read_at: DateTime.utc_now()])
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
    |> Notification.changeset(attrs)
    |> Repo.update()
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
    Repo.delete(notification)
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
