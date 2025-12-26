defmodule MedicWeb.API.NotificationController do
  @moduledoc """
  Notification API controller for mobile app.
  Handles listing and managing notifications.
  """
  use MedicWeb, :controller

  alias Medic.Notifications

  action_fallback MedicWeb.API.FallbackController

  @doc """
  GET /api/notifications
  Lists notifications for the current user.
  """
  def index(conn, params) do
    user = conn.assigns.current_user
    limit = parse_int(params["limit"]) || 50
    
    notifications = Notifications.list_user_notifications(user.id, limit)
    unread_count = Notifications.list_unread_count(user.id)
    
    conn
    |> put_status(:ok)
    |> json(%{
      data: Enum.map(notifications, &notification_to_json/1),
      meta: %{
        unread_count: unread_count
      }
    })
  end

  @doc """
  POST /api/notifications/:id/read
  Marks a notification as read.
  """
  def mark_read(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    
    case Notifications.mark_as_read_for_user(user.id, id) do
      {:ok, _} ->
        conn
        |> put_status(:ok)
        |> json(%{success: true})
      
      {:error, :not_found} ->
        {:error, :not_found}
      
      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Could not mark notification as read"})
    end
  end

  @doc """
  POST /api/notifications/mark_all
  Marks all notifications as read.
  """
  def mark_all(conn, _params) do
    user = conn.assigns.current_user
    
    case Notifications.mark_all_as_read(user.id) do
      {:ok, _} ->
        conn
        |> put_status(:ok)
        |> json(%{success: true})
      
      %Ash.BulkResult{status: :success} ->
        conn
        |> put_status(:ok)
        |> json(%{success: true})
      
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Could not mark notifications as read"})
    end
  end

  # --- Private Helpers ---

  defp parse_int(nil), do: nil
  defp parse_int(val) when is_integer(val), do: val
  defp parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {i, _} -> i
      :error -> nil
    end
  end

  defp notification_to_json(notification) do
    %{
      id: notification.id,
      title: notification.title,
      message: notification.message,
      template: notification.template,
      read_at: notification.read_at && DateTime.to_iso8601(notification.read_at),
      inserted_at: DateTime.to_iso8601(notification.inserted_at)
    }
  end
end
