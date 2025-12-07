defmodule MedicWeb.NotificationLive do
  use MedicWeb, :live_view

  alias Medic.Notifications

  def mount(_params, session, socket) do
    if user_id = session["user_id"] do
      if connected?(socket) do
        Notifications.subscribe(user_id)
      end
      
      unread_count = Notifications.list_unread_count(user_id)
      
      {:ok, assign(socket, 
        current_user: %{id: user_id}, 
        unread_count: unread_count, 
        notifications: [],
        show_dropdown: false
      )}
    else
      {:ok, assign(socket, current_user: nil, unread_count: 0, show_dropdown: false)}
    end
  end

  def render(assigns) do
    ~H"""
    <div id="notifications-bell" class="relative" phx-hook="Notifications">
      <%= if @current_user do %>
        <button class="btn btn-ghost btn-circle" phx-click="toggle_notifications">
          <div class="indicator">
            <.icon name="hero-bell" class="w-5 h-5" />
            <%= if @unread_count > 0 do %>
              <span class="badge badge-xs badge-primary indicator-item"></span>
            <% end %>
          </div>
        </button>

        <%= if @show_dropdown do %>
          <div class="absolute right-0 mt-3 w-80 bg-base-100 rounded-box shadow-xl z-[100] border border-base-200 overflow-hidden">
            <div class="p-3 border-b border-base-200 flex justify-between items-center bg-base-200/50">
              <h3 class="font-bold text-sm">Notifications</h3>
              <%= if @unread_count > 0 do %>
                <button class="text-xs text-primary hover:underline" phx-click="mark_all_read">Mark all read</button>
              <% end %>
            </div>
            
            <div class="max-h-96 overflow-y-auto">
              <%= if @notifications == [] do %>
                <div class="p-4 text-center text-base-content/60 text-sm">
                  No new notifications
                </div>
              <% else %>
                <ul class="divide-y divide-base-200">
                  <%= for notification <- @notifications do %>
                    <li class={"p-3 hover:bg-base-200/50 transition-colors #{unless notification.read_at, do: "bg-primary/5"}"}>
                      <div class="flex gap-3">
                        <div class={"mt-1 w-2 h-2 rounded-full shrink-0 #{if notification.read_at, do: "bg-base-300", else: "bg-primary"}"}></div>
                        <div>
                          <p class="font-medium text-sm"><%= notification.title %></p>
                          <p class="text-xs text-base-content/70 mt-0.5"><%= notification.message %></p>
                          <p class="text-[10px] text-base-content/50 mt-1">
                            <%= Calendar.strftime(notification.inserted_at, "%b %d, %H:%M") %>
                          </p>
                        </div>
                      </div>
                    </li>
                  <% end %>
                </ul>
              <% end %>
            </div>
          </div>
          
          <%!-- Backdrop to close --%>
          <div class="fixed inset-0 z-[90]" phx-click="toggle_notifications"></div>
        <% end %>
      <% end %>
    </div>
    """
  end

  def handle_event("toggle_notifications", _, socket) do
    if !socket.assigns.show_dropdown do
      # Load notifications when opening
      notifications = Notifications.list_user_notifications(socket.assigns.current_user.id)
      {:noreply, assign(socket, show_dropdown: true, notifications: notifications)}
    else
      {:noreply, assign(socket, show_dropdown: false)}
    end
  end

  def handle_event("mark_all_read", _, socket) do
    Notifications.mark_all_as_read(socket.assigns.current_user.id)
    {:noreply, assign(socket, unread_count: 0, notifications: Notifications.list_user_notifications(socket.assigns.current_user.id))}
  end

  def handle_info({:new_notification, notification}, socket) do
    # Show toast
    
    # Update count
    new_count = socket.assigns.unread_count + 1
    
    # If dropdown is open, prepend notification
    notifications = if socket.assigns.show_dropdown do
      [notification | socket.assigns.notifications]
    else
      socket.assigns.notifications
    end

    socket = socket
             |> assign(unread_count: new_count, notifications: notifications)
             |> push_event("show_toast", %{title: notification.title, message: notification.message, type: "info"})

    {:noreply, socket}
  end
end
