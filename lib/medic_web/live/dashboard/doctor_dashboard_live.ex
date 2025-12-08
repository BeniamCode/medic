defmodule MedicWeb.DoctorDashboardLive do
  @moduledoc """
  Doctor dashboard showing today's appointments and quick stats.
  """
  use MedicWeb, :live_view

  alias Medic.Doctors
  alias Medic.Appointments

  def render(assigns) do
    ~H"""
    <div class="flex-1 space-y-4 p-8 pt-6">
      <div class="flex items-center justify-between space-y-2">
        <div>
          <h2 class="text-3xl font-bold tracking-tight">Dashboard</h2>
          <p class="text-muted-foreground">
            Good morning, Dr. <%= @doctor && @doctor.last_name || "Doctor" %>. Here's what's happening today.
          </p>
        </div>
        <div class="flex items-center space-x-2">
          <.link navigate={~p"/dashboard/doctor/profile"} class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2">
            <.icon name="hero-user-circle" class="mr-2 h-4 w-4" />
            Profile
          </.link>
        </div>
      </div>

      <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <div class="rounded-xl border bg-card text-card-foreground shadow-sm">
          <div class="p-6 flex flex-row items-center justify-between space-y-0 pb-2">
            <h3 class="tracking-tight text-sm font-medium">Today's Appointments</h3>
            <.icon name="hero-calendar" class="h-4 w-4 text-muted-foreground" />
          </div>
          <div class="p-6 pt-0">
            <div class="text-2xl font-bold"><%= length(@today_appointments) %></div>
            <p class="text-xs text-muted-foreground">
              +20.1% from last month
            </p>
          </div>
        </div>
        <div class="rounded-xl border bg-card text-card-foreground shadow-sm">
          <div class="p-6 flex flex-row items-center justify-between space-y-0 pb-2">
            <h3 class="tracking-tight text-sm font-medium">Pending Requests</h3>
            <.icon name="hero-clock" class="h-4 w-4 text-muted-foreground" />
          </div>
          <div class="p-6 pt-0">
            <div class="text-2xl font-bold"><%= @pending_count %></div>
            <p class="text-xs text-muted-foreground">
              Action required
            </p>
          </div>
        </div>
        <div class="rounded-xl border bg-card text-card-foreground shadow-sm">
          <div class="p-6 flex flex-row items-center justify-between space-y-0 pb-2">
            <h3 class="tracking-tight text-sm font-medium">Confirmed (Week)</h3>
            <.icon name="hero-check-circle" class="h-4 w-4 text-muted-foreground" />
          </div>
          <div class="p-6 pt-0">
            <div class="text-2xl font-bold"><%= @upcoming_count %></div>
            <p class="text-xs text-muted-foreground">
              +19% from last week
            </p>
          </div>
        </div>
        <div class="rounded-xl border bg-card text-card-foreground shadow-sm">
          <div class="p-6 flex flex-row items-center justify-between space-y-0 pb-2">
            <h3 class="tracking-tight text-sm font-medium">Rating</h3>
            <.icon name="hero-star" class="h-4 w-4 text-muted-foreground" />
          </div>
          <div class="p-6 pt-0">
            <div class="text-2xl font-bold"><%= @doctor && Float.round(@doctor.rating || 0.0, 1) || "N/A" %></div>
            <p class="text-xs text-muted-foreground">
              Based on <%= @doctor && @doctor.review_count || 0 %> reviews
            </p>
          </div>
        </div>
      </div>

      <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        <div class="col-span-4 rounded-xl border bg-card text-card-foreground shadow-sm">
          <div class="flex flex-col space-y-1.5 p-6">
            <h3 class="font-semibold leading-none tracking-tight">Today's Schedule</h3>
            <p class="text-sm text-muted-foreground">
              You have <%= length(@today_appointments) %> appointments today.
            </p>
          </div>
          <div class="p-6 pt-0">
            <%= if @today_appointments == [] do %>
              <div class="flex flex-col items-center justify-center py-8 text-center">
                <.icon name="hero-calendar" class="h-12 w-12 text-muted-foreground/50 mb-4" />
                <p class="text-muted-foreground">No appointments scheduled for today.</p>
              </div>
            <% else %>
              <div class="space-y-8">
                <%= for appointment <- @today_appointments do %>
                  <div class="flex items-center">
                    <div class="space-y-1">
                      <p class="text-sm font-medium leading-none">
                        <%= appointment.patient && "#{appointment.patient.first_name} #{appointment.patient.last_name}" || "Patient" %>
                      </p>
                      <p class="text-sm text-muted-foreground">
                        <%= format_time(appointment.starts_at) %> - <%= appointment.duration_minutes %> min
                        <span class="ml-2 inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80">
                          <%= if appointment.appointment_type == "telemedicine", do: "Telemedicine", else: "In-person" %>
                        </span>
                      </p>
                    </div>
                    <div class={"ml-auto font-medium " <> status_color_class(appointment.status)}>
                      <%= status_text(appointment.status) %>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <div class="col-span-3 rounded-xl border bg-card text-card-foreground shadow-sm">
          <div class="flex flex-col space-y-1.5 p-6">
            <h3 class="font-semibold leading-none tracking-tight">Quick Actions</h3>
            <p class="text-sm text-muted-foreground">
              Manage your practice
            </p>
          </div>
          <div class="p-6 pt-0 space-y-2">
            <.link navigate={~p"/doctor/schedule"} class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2 w-full justify-start">
              <.icon name="hero-calendar" class="mr-2 h-4 w-4" />
              Manage Availability
            </.link>
            <.link navigate={~p"/dashboard/doctor/profile"} class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2 w-full justify-start">
              <.icon name="hero-user-circle" class="mr-2 h-4 w-4" />
              Edit Profile
            </.link>
            <button class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2 w-full justify-start opacity-50 cursor-not-allowed">
              <.icon name="hero-chart-bar" class="mr-2 h-4 w-4" />
              Analytics (Coming Soon)
            </button>
          </div>
          
          <%= if @doctor && is_nil(@doctor.verified_at) do %>
            <div class="p-6 pt-0 mt-4">
              <div class="rounded-lg border border-warning/50 bg-warning/10 p-4 text-warning-foreground">
                <div class="flex items-center gap-2">
                  <.icon name="hero-exclamation-triangle" class="h-4 w-4" />
                  <h5 class="font-medium leading-none tracking-tight">Verification Pending</h5>
                </div>
                <div class="mt-2 text-sm opacity-90">
                  Complete your profile to appear in search results.
                </div>
              </div>
            </div>
          <% end %>
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

  defp status_color_class("pending"), do: "text-yellow-600"
  defp status_color_class("confirmed"), do: "text-green-600"
  defp status_color_class("completed"), do: "text-blue-600"
  defp status_color_class("cancelled"), do: "text-red-600"
  defp status_color_class(_), do: "text-muted-foreground"

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
