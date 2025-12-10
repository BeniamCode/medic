defmodule MedicWeb.NotificationController do
  use MedicWeb, :controller

  alias Medic.Notifications

  def index(conn, _params) do
    user = conn.assigns.current_user
    notifications = Notifications.list_user_notifications(user.id, 50)

    conn
    |> assign_prop(:notifications, Enum.map(notifications, &notification_props/1))
    |> assign_prop(:unread_count, Notifications.list_unread_count(user.id))
    |> render_inertia("Notifications/Index")
  end

  def mark_all(conn, _params) do
    user = conn.assigns.current_user
    Notifications.mark_all_as_read(user.id)

    conn
    |> put_flash(:success, dgettext("default", "Notifications cleared"))
    |> redirect(to: ~p"/notifications")
  end

  defp notification_props(notification) do
    %{
      id: notification.id,
      title: notification.title,
      message: notification.message,
      read_at: notification.read_at,
      inserted_at: DateTime.to_iso8601(notification.inserted_at)
    }
  end
end
