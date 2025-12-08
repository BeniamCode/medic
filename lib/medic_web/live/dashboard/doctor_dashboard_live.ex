defmodule MedicWeb.DoctorDashboardLive do
  @moduledoc """
  Doctor dashboard showing today's appointments and quick stats.
  """
  use MedicWeb, :live_view

  alias Medic.Doctors
  alias Medic.Appointments

  def render(assigns) do
    ~H"""
    <div class="p-4 md:p-8 space-y-8">
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 class="text-3xl font-bold">Dashboard</h2>
          <p class="text-base-content/70 mt-1">
            Good morning, Dr. <%= @doctor && @doctor.last_name || "Doctor" %>. Here's what's happening today.
          </p>
        </div>
        <div>
          <.link navigate={~p"/dashboard/doctor/profile"} class="btn btn-primary">
            <.icon name="hero-user-circle" class="size-5" />
            Profile
          </.link>
        </div>
      </div>

      <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <div class="stats shadow bg-base-100">
          <div class="stat">
            <div class="stat-figure text-primary">
              <.icon name="hero-calendar" class="size-8" />
            </div>
            <div class="stat-title">Today's Appointments</div>
            <div class="stat-value text-primary"><%= length(@today_appointments) %></div>
            <div class="stat-desc">↗︎ 20.1% from last month</div>
          </div>
        </div>
        
        <div class="stats shadow bg-base-100">
          <div class="stat">
            <div class="stat-figure text-secondary">
              <.icon name="hero-clock" class="size-8" />
            </div>
            <div class="stat-title">Pending Requests</div>
            <div class="stat-value text-secondary"><%= @pending_count %></div>
            <div class="stat-desc">Action required</div>
          </div>
        </div>

        <div class="stats shadow bg-base-100">
          <div class="stat">
            <div class="stat-figure text-accent">
              <.icon name="hero-check-circle" class="size-8" />
            </div>
            <div class="stat-title">Confirmed (Week)</div>
            <div class="stat-value text-accent"><%= @upcoming_count %></div>
            <div class="stat-desc">↗︎ 19% from last week</div>
          </div>
        </div>

        <div class="stats shadow bg-base-100">
          <div class="stat">
            <div class="stat-figure text-warning">
              <.icon name="hero-star" class="size-8" />
            </div>
            <div class="stat-title">Rating</div>
            <div class="stat-value text-warning"><%= @doctor && Float.round(@doctor.rating || 0.0, 1) || "N/A" %></div>
            <div class="stat-desc">Based on <%= @doctor && @doctor.review_count || 0 %> reviews</div>
          </div>
        </div>
      </div>

      <div class="grid gap-8 lg:grid-cols-3">
        <div class="lg:col-span-2 card bg-base-100 shadow-xl">
          <div class="card-body">
            <h3 class="card-title">Today's Schedule</h3>
            <p class="text-base-content/70">
              You have <%= length(@today_appointments) %> appointments today.
            </p>
            
            <div class="divider my-0"></div>

            <%= if @today_appointments == [] do %>
              <div class="flex flex-col items-center justify-center py-12 text-center opacity-50">
                <.icon name="hero-calendar" class="size-16 mb-4" />
                <p>No appointments scheduled for today.</p>
              </div>
            <% else %>
              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <tbody>
                    <%= for appointment <- @today_appointments do %>
                      <tr>
                        <td>
                          <div class="font-bold">
                            <%= appointment.patient && "#{appointment.patient.first_name} #{appointment.patient.last_name}" || "Patient" %>
                          </div>
                          <div class="text-sm opacity-50">
                            <%= if appointment.appointment_type == "telemedicine", do: "Telemedicine", else: "In-person" %>
                          </div>
                        </td>
                        <td>
                          <div class="font-medium">
                            <%= format_time(appointment.starts_at) %>
                          </div>
                          <div class="text-xs opacity-50">
                            <%= appointment.duration_minutes %> min
                          </div>
                        </td>
                        <td class="text-right">
                          <div class={"badge " <> status_badge_class(appointment.status)}>
                            <%= status_text(appointment.status) %>
                          </div>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% end %>
          </div>
        </div>

        <div class="card bg-base-100 shadow-xl h-fit">
          <div class="card-body">
            <h3 class="card-title">Quick Actions</h3>
            <p class="text-base-content/70 mb-4">Manage your practice</p>
            
            <div class="flex flex-col gap-2">
              <.link navigate={~p"/doctor/schedule"} class="btn btn-outline justify-start">
                <.icon name="hero-calendar" class="size-5" />
                Manage Availability
              </.link>
              <.link navigate={~p"/dashboard/doctor/profile"} class="btn btn-outline justify-start">
                <.icon name="hero-user-circle" class="size-5" />
                Edit Profile
              </.link>
              <button class="btn btn-outline btn-disabled justify-start">
                <.icon name="hero-chart-bar" class="size-5" />
                Analytics (Coming Soon)
              </button>
            </div>
            
            <%= if @doctor && is_nil(@doctor.verified_at) do %>
              <div class="alert alert-warning mt-4">
                <.icon name="hero-exclamation-triangle" class="size-5" />
                <div>
                  <h3 class="font-bold">Verification Pending</h3>
                  <div class="text-xs">Complete your profile to appear in search results.</div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    doctor = Doctors.get_doctor_by_user_id(user.id)

    {today_appointments, pending_count, upcoming_count} =
      if doctor do
        today = Appointments.list_doctor_appointments_today(doctor.id)
        pending = Appointments.count_upcoming_doctor_appointments(doctor.id)
        upcoming = Appointments.list_appointments(doctor_id: doctor.id, status: "confirmed") |> length()
        {today, pending, upcoming}
      else
        {[], 0, 0}
      end

    {:ok,
     assign(socket,
       page_title: "Doctor Dashboard",
       doctor: doctor,
       today_appointments: today_appointments,
       pending_count: pending_count,
       upcoming_count: upcoming_count
     )}
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
