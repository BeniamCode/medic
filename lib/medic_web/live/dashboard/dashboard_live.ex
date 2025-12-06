defmodule MedicWeb.DashboardLive do
  @moduledoc """
  Patient dashboard showing upcoming appointments.
  """
  use MedicWeb, :live_view

  alias Medic.Patients
  alias Medic.Appointments

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8 px-4">
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-2xl font-bold">Welcome</h1>
          <p class="text-base-content/70"><%= @current_user.email %></p>
        </div>
        <.link navigate={~p"/search"} class="btn btn-primary">
          <.icon name="hero-magnifying-glass" class="w-5 h-5 mr-2" />
          Find Doctor
        </.link>
      </div>

      <%!-- Quick Stats --%>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-primary">
            <.icon name="hero-calendar" class="w-8 h-8" />
          </div>
          <div class="stat-title">Upcoming Appointments</div>
          <div class="stat-value text-primary"><%= length(@upcoming_appointments) %></div>
        </div>
        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-secondary">
            <.icon name="hero-check-circle" class="w-8 h-8" />
          </div>
          <div class="stat-title">Completed</div>
          <div class="stat-value text-secondary"><%= @completed_count %></div>
        </div>
        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-accent">
            <.icon name="hero-heart" class="w-8 h-8" />
          </div>
          <div class="stat-title">Favorite Doctors</div>
          <div class="stat-value">3</div>
        </div>
      </div>

      <%!-- Upcoming Appointments --%>
      <div class="card bg-base-100 shadow-lg">
        <div class="card-body">
          <h2 class="card-title">
            <.icon name="hero-calendar-days" class="w-6 h-6 text-primary" />
            Upcoming Appointments
          </h2>

          <%= if @upcoming_appointments == [] do %>
            <div class="py-12 text-center">
              <.icon name="hero-calendar" class="w-16 h-16 mx-auto text-base-content/30 mb-4" />
              <p class="text-base-content/70 mb-4">No scheduled appointments</p>
              <.link navigate={~p"/search"} class="btn btn-primary">
                Book your first appointment
              </.link>
            </div>
          <% else %>
            <div class="space-y-4">
              <%= for appointment <- @upcoming_appointments do %>
                <div class="flex items-center gap-4 p-4 bg-base-200/50 rounded-lg">
                  <div class="avatar placeholder">
                    <div class="w-12 h-12 rounded-full bg-primary/10 text-primary">
                      <span><.icon name="hero-user" class="w-6 h-6" /></span>
                    </div>
                  </div>
                  <div class="flex-1">
                    <h3 class="font-medium">
                      Dr. <%= appointment.doctor.first_name %> <%= appointment.doctor.last_name %>
                    </h3>
                    <p class="text-sm text-base-content/70">
                      <%= Calendar.strftime(appointment.starts_at, "%m/%d/%Y at %H:%M") %>
                    </p>
                  </div>
                  <div class={"badge badge-#{status_color(appointment.status)}"}>
                    <%= status_text(appointment.status) %>
                  </div>
                  <.link navigate={~p"/appointments/#{appointment.id}"} class="btn btn-ghost btn-sm">
                    Details
                  </.link>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    patient = Patients.get_patient_by_user_id(user.id)

    upcoming_appointments =
      if patient do
        Appointments.list_appointments(
          patient_id: patient.id,
          upcoming: true,
          preload: [:doctor]
        )
      else
        []
      end

    completed_count =
      if patient do
        Appointments.list_appointments(
          patient_id: patient.id,
          status: "completed"
        )
        |> length()
      else
        0
      end

    {:ok,
     assign(socket,
       page_title: "Dashboard",
       upcoming_appointments: upcoming_appointments,
       completed_count: completed_count
     )}
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
end
