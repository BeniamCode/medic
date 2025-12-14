defmodule MedicWeb.NotificationStreamController do
  use MedicWeb, :controller

  alias Medic.Notifications
  require Logger

  @keepalive_ms 25_000

  def stream(conn, _params) do
    user = conn.assigns.current_user

    Notifications.subscribe(user.id)

    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> send_chunked(200)

    unread_count = Notifications.list_unread_count(user.id)

    with {:ok, conn} <- send_sse(conn, "ready", %{unread_count: unread_count}) do
      loop(conn, user.id)
    end
  end

  defp loop(conn, user_id) do
    receive do
      {:new_notification, notification} ->
        unread_count = Notifications.list_unread_count(user_id)

        payload = %{
          notification: notification_props(notification),
          unread_count: unread_count
        }

        case send_sse(conn, "new_notification", payload) do
          {:ok, conn} -> loop(conn, user_id)
          {:error, _} -> conn
        end

      {:unread_count, count} when is_integer(count) ->
        case send_sse(conn, "unread_count", %{unread_count: count}) do
          {:ok, conn} -> loop(conn, user_id)
          {:error, _} -> conn
        end
    after
      @keepalive_ms ->
        case Plug.Conn.chunk(conn, ": keep-alive\n\n") do
          {:ok, conn} -> loop(conn, user_id)
          {:error, _} -> conn
        end
    end
  end

  defp send_sse(conn, event, payload) do
    data = Jason.encode!(payload)
    Plug.Conn.chunk(conn, "event: #{event}\ndata: #{data}\n\n")
  end

  defp notification_props(notification) do
    %{
      id: notification.id,
      title: notification.title,
      message: notification.message,
      type: notification.type,
      read_at: notification.read_at,
      resource_id: notification.resource_id,
      resource_type: notification.resource_type,
      inserted_at: DateTime.to_iso8601(notification.inserted_at)
    }
  end
end
