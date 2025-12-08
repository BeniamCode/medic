defmodule MedicWeb.AppointmentLive.Show do
  @moduledoc """
  Appointment details view with cancel and delete functionality.
  """
  use MedicWeb, :live_view

  alias Medic.Appointments

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4 md:p-8 space-y-8">
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 class="text-3xl font-bold">Appointment Details</h2>
          <p class="text-base-content/70 mt-1">
            Booked on <%= Calendar.strftime(@appointment.inserted_at, "%B %d, %Y") %>
          </p>
        </div>
        <div>
          <.link navigate={~p"/dashboard"} class="btn btn-ghost">
            <.icon name="hero-arrow-left" class="size-4 mr-2" />
            Back to Dashboard
          </.link>
        </div>
      </div>

      <div class="grid gap-6 md:grid-cols-2">
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <div class="flex items-center justify-between mb-4">
              <h3 class="card-title">Status</h3>
              <div class={"badge " <> status_badge_class(@appointment.status)}>
                <%= status_text(@appointment.status) %>
              </div>
            </div>
            
            <div class="flex items-center gap-4">
              <div class="avatar placeholder">
                <div class="bg-primary/10 text-primary rounded-full w-16">
                  <.icon name="hero-user" class="size-8" />
                </div>
              </div>
              <div>
                <h4 class="text-lg font-bold">
                  Dr. <%= @appointment.doctor.first_name %> <%= @appointment.doctor.last_name %>
                </h4>
                <%= if @appointment.doctor.specialty do %>
                  <p class="text-sm text-base-content/70"><%= @appointment.doctor.specialty.name_en %></p>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h3 class="card-title mb-4">Time & Date</h3>
            <div class="grid gap-4">
              <div class="flex items-center gap-4 rounded-box border border-base-200 p-4">
                <.icon name="hero-calendar" class="size-5 text-base-content/70" />
                <div class="flex-1">
                  <p class="text-sm font-bold">Date</p>
                  <p class="text-sm text-base-content/70">
                    <%= Calendar.strftime(@appointment.starts_at, "%A, %B %d, %Y") %>
                  </p>
                </div>
              </div>
              <div class="flex items-center gap-4 rounded-box border border-base-200 p-4">
                <.icon name="hero-clock" class="size-5 text-base-content/70" />
                <div class="flex-1">
                  <p class="text-sm font-bold">Time</p>
                  <p class="text-sm text-base-content/70">
                    <%= format_time(@appointment.starts_at) %> - <%= format_time(@appointment.ends_at) %>
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%= if @appointment.notes && @appointment.notes != "" do %>
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h3 class="card-title">Notes</h3>
            <div class="rounded-box bg-base-200 p-4 text-sm">
              <%= @appointment.notes %>
            </div>
          </div>
        </div>
      <% end %>

      <%= if @appointment.status == "cancelled" do %>
        <div class="alert alert-error">
          <.icon name="hero-x-circle" class="size-5" />
          <div>
            <h3 class="font-bold">Appointment Cancelled</h3>
            <div class="text-sm">
              <%= if @appointment.cancellation_reason do %>
                <p>Reason: <%= @appointment.cancellation_reason %></p>
              <% end %>
              <%= if @appointment.cancelled_at do %>
                <p>Cancelled on <%= Calendar.strftime(@appointment.cancelled_at, "%B %d, %Y at %H:%M") %></p>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <div class="flex items-center justify-end gap-2">
        <%= if @appointment.status in ["pending", "confirmed"] do %>
          <button
            phx-click="show_cancel_modal"
            class="btn btn-warning btn-outline"
          >
            <.icon name="hero-x-mark" class="size-4 mr-2" />
            Cancel Appointment
          </button>
        <% end %>
        <button
          phx-click="show_delete_modal"
          class="btn btn-error"
        >
          <.icon name="hero-trash" class="size-4 mr-2" />
          Delete
        </button>
      </div>

      <%!-- Cancel Modal --%>
      <.modal :if={@show_cancel_modal} id="cancel-modal" show on_cancel={JS.push("hide_modal")}>
        <div class="mb-4">
          <h3 class="text-lg font-bold">Cancel Appointment?</h3>
          <p class="py-4">
            Are you sure you want to cancel your appointment with
            <strong>Dr. <%= @appointment.doctor.last_name %></strong>
            on <strong><%= Calendar.strftime(@appointment.starts_at, "%B %d at %H:%M") %></strong>?
          </p>
        </div>

        <.form for={%{}} phx-submit="cancel_appointment" class="space-y-4">
          <div class="form-control">
            <label class="label">
              <span class="label-text">Reason for cancellation (optional)</span>
            </label>
            <textarea
              name="reason"
              class="textarea textarea-bordered h-24"
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
      </.modal>

      <%!-- Delete Modal --%>
      <.modal :if={@show_delete_modal} id="delete-modal" show on_cancel={JS.push("hide_modal")}>
        <div class="mb-4">
          <h3 class="text-lg font-bold text-error">Delete Appointment?</h3>
          <p class="py-4">
            Are you sure you want to permanently delete this appointment record?
            This action cannot be undone.
          </p>
        </div>

        <div class="modal-action">
          <button type="button" phx-click="hide_modal" class="btn">
            Cancel
          </button>
          <button phx-click="delete_appointment" class="btn btn-error">
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

  defp status_badge_class("pending"), do: "badge-warning"
  defp status_badge_class("confirmed"), do: "badge-success"
  defp status_badge_class("completed"), do: "badge-info"
  defp status_badge_class("cancelled"), do: "badge-error"
  defp status_badge_class(_), do: "badge-ghost"

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
