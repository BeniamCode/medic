defmodule MedicWeb.AppointmentLive.Show do
  @moduledoc """
  Appointment details view with cancel and delete functionality.
  """
  use MedicWeb, :live_view

  alias Medic.Appointments

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1 space-y-4 p-8 pt-6">
      <div class="flex items-center justify-between space-y-2">
        <div>
          <h2 class="text-3xl font-bold tracking-tight">Appointment Details</h2>
          <p class="text-muted-foreground">
            Booked on <%= Calendar.strftime(@appointment.inserted_at, "%B %d, %Y") %>
          </p>
        </div>
        <div class="flex items-center space-x-2">
          <.link navigate={~p"/dashboard"} class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2">
            <.icon name="hero-arrow-left" class="mr-2 h-4 w-4" />
            Back to Dashboard
          </.link>
        </div>
      </div>

      <div class="grid gap-6 md:grid-cols-2">
        <div class="rounded-xl border bg-card text-card-foreground shadow-sm">
          <div class="flex flex-col space-y-1.5 p-6">
            <div class="flex items-center justify-between">
              <h3 class="font-semibold leading-none tracking-tight">Status</h3>
              <div class={"inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent " <> status_badge_class(@appointment.status)}>
                <%= status_text(@appointment.status) %>
              </div>
            </div>
          </div>
          <div class="p-6 pt-0">
            <div class="flex items-center gap-4">
              <div class="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
                <.icon name="hero-user" class="h-8 w-8 text-primary" />
              </div>
              <div>
                <h4 class="text-lg font-semibold">
                  Dr. <%= @appointment.doctor.first_name %> <%= @appointment.doctor.last_name %>
                </h4>
                <%= if @appointment.doctor.specialty do %>
                  <p class="text-sm text-muted-foreground"><%= @appointment.doctor.specialty.name_en %></p>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <div class="rounded-xl border bg-card text-card-foreground shadow-sm">
          <div class="flex flex-col space-y-1.5 p-6">
            <h3 class="font-semibold leading-none tracking-tight">Time & Date</h3>
          </div>
          <div class="p-6 pt-0 grid gap-4">
            <div class="flex items-center gap-4 rounded-md border p-4">
              <.icon name="hero-calendar" class="h-5 w-5 text-muted-foreground" />
              <div class="flex-1">
                <p class="text-sm font-medium leading-none">Date</p>
                <p class="text-sm text-muted-foreground">
                  <%= Calendar.strftime(@appointment.starts_at, "%A, %B %d, %Y") %>
                </p>
              </div>
            </div>
            <div class="flex items-center gap-4 rounded-md border p-4">
              <.icon name="hero-clock" class="h-5 w-5 text-muted-foreground" />
              <div class="flex-1">
                <p class="text-sm font-medium leading-none">Time</p>
                <p class="text-sm text-muted-foreground">
                  <%= format_time(@appointment.starts_at) %> - <%= format_time(@appointment.ends_at) %>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%= if @appointment.notes && @appointment.notes != "" do %>
        <div class="rounded-xl border bg-card text-card-foreground shadow-sm">
          <div class="flex flex-col space-y-1.5 p-6">
            <h3 class="font-semibold leading-none tracking-tight">Notes</h3>
          </div>
          <div class="p-6 pt-0">
            <div class="rounded-md bg-muted p-4 text-sm text-muted-foreground">
              <%= @appointment.notes %>
            </div>
          </div>
        </div>
      <% end %>

      <%= if @appointment.status == "cancelled" do %>
        <div class="rounded-lg border border-destructive/50 bg-destructive/10 p-4 text-destructive">
          <div class="flex items-center gap-2">
            <.icon name="hero-x-circle" class="h-5 w-5" />
            <h5 class="font-medium leading-none tracking-tight">Appointment Cancelled</h5>
          </div>
          <div class="mt-2 text-sm opacity-90">
            <%= if @appointment.cancellation_reason do %>
              <p>Reason: <%= @appointment.cancellation_reason %></p>
            <% end %>
            <%= if @appointment.cancelled_at do %>
              <p>Cancelled on <%= Calendar.strftime(@appointment.cancelled_at, "%B %d, %Y at %H:%M") %></p>
            <% end %>
          </div>
        </div>
      <% end %>

      <div class="flex items-center justify-end gap-2">
        <%= if @appointment.status in ["pending", "confirmed"] do %>
          <button
            phx-click="show_cancel_modal"
            class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2 text-yellow-600 hover:text-yellow-700"
          >
            <.icon name="hero-x-mark" class="mr-2 h-4 w-4" />
            Cancel Appointment
          </button>
        <% end %>
        <button
          phx-click="show_delete_modal"
          class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-destructive text-destructive-foreground hover:bg-destructive/90 h-10 px-4 py-2"
        >
          <.icon name="hero-trash" class="mr-2 h-4 w-4" />
          Delete
        </button>
      </div>

      <%!-- Cancel Modal --%>
      <.modal :if={@show_cancel_modal} id="cancel-modal" show on_cancel={JS.push("hide_modal")}>
        <div class="flex flex-col space-y-1.5 text-center sm:text-left mb-4">
          <h3 class="text-lg font-semibold leading-none tracking-tight">Cancel Appointment?</h3>
          <p class="text-sm text-muted-foreground">
            Are you sure you want to cancel your appointment with
            <strong>Dr. <%= @appointment.doctor.last_name %></strong>
            on <strong><%= Calendar.strftime(@appointment.starts_at, "%B %d at %H:%M") %></strong>?
          </p>
        </div>

        <.form for={%{}} phx-submit="cancel_appointment" class="space-y-4">
          <div class="grid w-full gap-1.5">
            <label class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">
              Reason for cancellation (optional)
            </label>
            <textarea
              name="reason"
              class="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
              placeholder="e.g., Schedule conflict, feeling better..."
            ></textarea>
          </div>

          <div class="flex items-center justify-end space-x-2">
            <button type="button" phx-click="hide_modal" class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2">
              Keep Appointment
            </button>
            <button type="submit" class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-destructive text-destructive-foreground hover:bg-destructive/90 h-10 px-4 py-2">
              Yes, Cancel
            </button>
          </div>
        </.form>
      </.modal>

      <%!-- Delete Modal --%>
      <.modal :if={@show_delete_modal} id="delete-modal" show on_cancel={JS.push("hide_modal")}>
        <div class="flex flex-col space-y-1.5 text-center sm:text-left mb-4">
          <h3 class="text-lg font-semibold leading-none tracking-tight text-destructive">Delete Appointment?</h3>
          <p class="text-sm text-muted-foreground">
            Are you sure you want to permanently delete this appointment record?
            This action cannot be undone.
          </p>
        </div>

        <div class="flex items-center justify-end space-x-2 pt-4">
          <button type="button" phx-click="hide_modal" class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2">
            Cancel
          </button>
          <button phx-click="delete_appointment" class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-destructive text-destructive-foreground hover:bg-destructive/90 h-10 px-4 py-2">
            Delete Permanently
          </button>
        </div>
      </.modal>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    appointment = Appointments.get_appointment_with_details!(id)

    {:ok,
     assign(socket,
       page_title: "Appointment Details",
       appointment: appointment,
       show_cancel_modal: false,
       show_delete_modal: false
     )}
  end

  @impl true
  def handle_event("show_cancel_modal", _, socket) do
    {:noreply, assign(socket, show_cancel_modal: true)}
  end

  def handle_event("show_delete_modal", _, socket) do
    {:noreply, assign(socket, show_delete_modal: true)}
  end

  def handle_event("hide_modal", _, socket) do
    {:noreply, assign(socket, show_cancel_modal: false, show_delete_modal: false)}
  end

  def handle_event("cancel_appointment", %{"reason" => reason}, socket) do
    reason = if reason == "", do: nil, else: reason

    case Appointments.cancel_appointment(socket.assigns.appointment, reason) do
      {:ok, appointment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Appointment cancelled successfully")
         |> assign(appointment: appointment, show_cancel_modal: false)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to cancel appointment")
         |> assign(show_cancel_modal: false)}
    end
  end

  def handle_event("delete_appointment", _, socket) do
    case Appointments.delete_appointment(socket.assigns.appointment) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Appointment deleted")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete appointment")
         |> assign(show_delete_modal: false)}
    end
  end

  defp status_badge_class("pending"), do: "bg-yellow-100 text-yellow-800 hover:bg-yellow-100/80"
  defp status_badge_class("confirmed"), do: "bg-green-100 text-green-800 hover:bg-green-100/80"
  defp status_badge_class("completed"), do: "bg-blue-100 text-blue-800 hover:bg-blue-100/80"
  defp status_badge_class("cancelled"), do: "bg-red-100 text-red-800 hover:bg-red-100/80"
  defp status_badge_class(_), do: "bg-gray-100 text-gray-800 hover:bg-gray-100/80"

  defp status_text("pending"), do: "Pending"
  defp status_text("confirmed"), do: "Confirmed"
  defp status_text("completed"), do: "Completed"
  defp status_text("cancelled"), do: "Cancelled"
  defp status_text(_), do: "Unknown"

  defp format_time(datetime) do
    datetime
    |> DateTime.shift_zone!("Europe/Athens")
    |> Calendar.strftime("%H:%M")
  end
end
