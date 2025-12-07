defmodule MedicWeb.AppointmentLive.Show do
  @moduledoc """
  Appointment details view with cancel and delete functionality.
  """
  use MedicWeb, :live_view

  alias Medic.Appointments

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto py-8 px-4">
      <.link navigate={~p"/dashboard"} class="btn btn-ghost btn-sm mb-6">
        <.icon name="hero-arrow-left" class="w-4 h-4" />
        Back to Dashboard
      </.link>

      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <%!-- Header with Status --%>
          <div class="flex items-start justify-between">
            <div>
              <h1 class="text-2xl font-bold">Appointment Details</h1>
              <p class="text-base-content/70">
                Booked on <%= Calendar.strftime(@appointment.inserted_at, "%B %d, %Y") %>
              </p>
            </div>
            <div class={"badge badge-lg badge-#{status_color(@appointment.status)}"}>
              <%= status_text(@appointment.status) %>
            </div>
          </div>

          <div class="divider"></div>

          <%!-- Doctor Info --%>
          <div class="flex items-center gap-4 mb-6">
            <div class="avatar placeholder">
              <div class="w-16 h-16 rounded-full bg-primary/10 text-primary">
                <span><.icon name="hero-user" class="w-8 h-8" /></span>
              </div>
            </div>
            <div>
              <h2 class="text-xl font-semibold">
                Dr. <%= @appointment.doctor.first_name %> <%= @appointment.doctor.last_name %>
              </h2>
              <%= if @appointment.doctor.specialty do %>
                <p class="text-primary"><%= @appointment.doctor.specialty.name_en %></p>
              <% end %>
            </div>
          </div>

          <%!-- Appointment Details --%>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div class="bg-base-200/50 rounded-lg p-4">
              <div class="flex items-center gap-2 text-base-content/70 mb-1">
                <.icon name="hero-calendar" class="w-4 h-4" />
                <span class="text-sm">Date</span>
              </div>
              <p class="font-semibold">
                <%= Calendar.strftime(@appointment.starts_at, "%A, %B %d, %Y") %>
              </p>
            </div>
            <div class="bg-base-200/50 rounded-lg p-4">
              <div class="flex items-center gap-2 text-base-content/70 mb-1">
                <.icon name="hero-clock" class="w-4 h-4" />
                <span class="text-sm">Time</span>
              </div>
              <p class="font-semibold">
                <%= format_time(@appointment.starts_at) %> - <%= format_time(@appointment.ends_at) %>
              </p>
            </div>
          </div>

          <%!-- Notes --%>
          <%= if @appointment.notes && @appointment.notes != "" do %>
            <div class="bg-base-200/50 rounded-lg p-4 mb-6">
              <div class="flex items-center gap-2 text-base-content/70 mb-2">
                <.icon name="hero-document-text" class="w-4 h-4" />
                <span class="text-sm">Notes</span>
              </div>
              <p><%= @appointment.notes %></p>
            </div>
          <% end %>

          <%!-- Cancellation Info --%>
          <%= if @appointment.status == "cancelled" do %>
            <div class="alert alert-error mb-6">
              <.icon name="hero-x-circle" class="w-5 h-5" />
              <div>
                <p class="font-semibold">This appointment was cancelled</p>
                <%= if @appointment.cancellation_reason do %>
                  <p class="text-sm">Reason: <%= @appointment.cancellation_reason %></p>
                <% end %>
                <%= if @appointment.cancelled_at do %>
                  <p class="text-sm">Cancelled on <%= Calendar.strftime(@appointment.cancelled_at, "%B %d, %Y at %H:%M") %></p>
                <% end %>
              </div>
            </div>
          <% end %>

          <div class="divider"></div>

          <%!-- Action Buttons --%>
          <div class="flex flex-wrap gap-3 justify-end">
            <%= if @appointment.status in ["pending", "confirmed"] do %>
              <button
                phx-click="show_cancel_modal"
                class="btn btn-warning btn-outline"
              >
                <.icon name="hero-x-mark" class="w-4 h-4" />
                Cancel Appointment
              </button>
            <% end %>
            <button
              phx-click="show_delete_modal"
              class="btn btn-error btn-outline"
            >
              <.icon name="hero-trash" class="w-4 h-4" />
              Delete
            </button>
          </div>
        </div>
      </div>

      <%!-- Cancel Modal --%>
      <%= if @show_cancel_modal do %>
        <div class="modal modal-open">
          <div class="modal-box">
            <h3 class="text-lg font-bold">Cancel Appointment?</h3>
            <p class="py-4">
              Are you sure you want to cancel your appointment with
              <strong>Dr. <%= @appointment.doctor.last_name %></strong>
              on <strong><%= Calendar.strftime(@appointment.starts_at, "%B %d at %H:%M") %></strong>?
            </p>
            <p class="text-sm text-base-content/70 mb-4">
              The appointment will be marked as cancelled but will remain in your history.
            </p>

            <.form for={%{}} phx-submit="cancel_appointment" class="space-y-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Reason for cancellation (optional)</span>
                </label>
                <textarea
                  name="reason"
                  class="textarea textarea-bordered"
                  placeholder="e.g., Schedule conflict, feeling better..."
                ></textarea>
              </div>

              <div class="modal-action">
                <button type="button" phx-click="hide_modal" class="btn">
                  Keep Appointment
                </button>
                <button type="submit" class="btn btn-warning">
                  Yes, Cancel
                </button>
              </div>
            </.form>
          </div>
          <div class="modal-backdrop bg-base-300/80" phx-click="hide_modal"></div>
        </div>
      <% end %>

      <%!-- Delete Modal --%>
      <%= if @show_delete_modal do %>
        <div class="modal modal-open">
          <div class="modal-box">
            <h3 class="text-lg font-bold text-error">Delete Appointment?</h3>
            <p class="py-4">
              Are you sure you want to permanently delete this appointment record?
            </p>
            <div class="alert alert-warning mb-4">
              <.icon name="hero-exclamation-triangle" class="w-5 h-5" />
              <span>This action cannot be undone.</span>
            </div>

            <div class="modal-action">
              <button type="button" phx-click="hide_modal" class="btn">
                Cancel
              </button>
              <button phx-click="delete_appointment" class="btn btn-error">
                <.icon name="hero-trash" class="w-4 h-4" />
                Delete Permanently
              </button>
            </div>
          </div>
          <div class="modal-backdrop bg-base-300/80" phx-click="hide_modal"></div>
        </div>
      <% end %>
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

  defp status_color("pending"), do: "warning"
  defp status_color("confirmed"), do: "success"
  defp status_color("completed"), do: "info"
  defp status_color("cancelled"), do: "error"
  defp status_color(_), do: "ghost"

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
