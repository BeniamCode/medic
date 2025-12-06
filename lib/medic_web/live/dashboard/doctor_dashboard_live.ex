defmodule MedicWeb.DoctorDashboardLive do
  @moduledoc """
  Doctor dashboard showing today's appointments and quick stats.
  """
  use MedicWeb, :live_view

  alias Medic.Doctors
  alias Medic.Appointments

  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto py-8 px-4">
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-2xl font-bold">
            Καλημέρα, Dr. {@doctor && @doctor.last_name || "Γιατρέ"}
          </h1>
          <p class="text-base-content/70">{Date.utc_today() |> Calendar.strftime("%A, %d %B %Y")}</p>
        </div>
        <.link navigate={~p"/dashboard/doctor/profile"} class="btn btn-outline">
          <.icon name="hero-user-circle" class="w-5 h-5 mr-2" />
          Προφίλ
        </.link>
      </div>

      <%!-- Quick Stats --%>
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-primary">
            <.icon name="hero-calendar" class="w-8 h-8" />
          </div>
          <div class="stat-title">Σήμερα</div>
          <div class="stat-value text-primary">{length(@today_appointments)}</div>
          <div class="stat-desc">Ραντεβού</div>
        </div>
        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-warning">
            <.icon name="hero-clock" class="w-8 h-8" />
          </div>
          <div class="stat-title">Εκκρεμή</div>
          <div class="stat-value text-warning">{@pending_count}</div>
          <div class="stat-desc">Προς επιβεβαίωση</div>
        </div>
        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-success">
            <.icon name="hero-check-circle" class="w-8 h-8" />
          </div>
          <div class="stat-title">Αυτή την εβδομάδα</div>
          <div class="stat-value text-success">{@upcoming_count}</div>
          <div class="stat-desc">Επιβεβαιωμένα</div>
        </div>
        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-secondary">
            <.icon name="hero-star" class="w-8 h-8" />
          </div>
          <div class="stat-title">Βαθμολογία</div>
          <div class="stat-value">{@doctor && Float.round(@doctor.rating, 1) || "N/A"}</div>
          <div class="stat-desc">{@doctor && @doctor.review_count || 0} κριτικές</div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <%!-- Today's Schedule --%>
        <div class="lg:col-span-2">
          <div class="card bg-base-100 shadow-lg">
            <div class="card-body">
              <h2 class="card-title">
                <.icon name="hero-calendar-days" class="w-6 h-6 text-primary" />
                Σημερινά Ραντεβού
              </h2>

              <%= if @today_appointments == [] do %>
                <div class="py-12 text-center">
                  <.icon name="hero-calendar" class="w-16 h-16 mx-auto text-base-content/30 mb-4" />
                  <p class="text-base-content/70">Δεν έχετε ραντεβού σήμερα</p>
                </div>
              <% else %>
                <div class="space-y-4">
                  <%= for appointment <- @today_appointments do %>
                    <div class="flex items-center gap-4 p-4 bg-base-200/50 rounded-lg">
                      <div class="text-center min-w-[60px]">
                        <div class="text-lg font-bold text-primary">
                          {Calendar.strftime(appointment.scheduled_at, "%H:%M")}
                        </div>
                        <div class="text-xs text-base-content/70">
                          {appointment.duration_minutes} λεπτά
                        </div>
                      </div>
                      <div class="divider divider-horizontal m-0"></div>
                      <div class="avatar placeholder">
                        <div class="w-10 h-10 rounded-full bg-secondary/10 text-secondary">
                          <span><.icon name="hero-user" class="w-5 h-5" /></span>
                        </div>
                      </div>
                      <div class="flex-1">
                        <h3 class="font-medium">
                          {appointment.patient && "#{appointment.patient.first_name} #{appointment.patient.last_name}" || "Ασθενής"}
                        </h3>
                        <p class="text-sm text-base-content/70">
                          <%= if appointment.appointment_type == "telemedicine" do %>
                            <.icon name="hero-video-camera" class="w-4 h-4 inline" /> Τηλεϊατρική
                          <% else %>
                            <.icon name="hero-building-office" class="w-4 h-4 inline" /> Δια ζώσης
                          <% end %>
                        </p>
                      </div>
                      <div class="badge badge-{status_color(appointment.status)}">
                        {status_text(appointment.status)}
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <%!-- Quick Actions --%>
        <div class="space-y-6">
          <div class="card bg-base-100 shadow-lg">
            <div class="card-body">
              <h2 class="card-title text-lg">Γρήγορες Ενέργειες</h2>
              <div class="space-y-2">
                <.link navigate={~p"/dashboard/doctor/schedule"} class="btn btn-block btn-outline justify-start">
                  <.icon name="hero-calendar" class="w-5 h-5" />
                  Διαχείριση Διαθεσιμότητας
                </.link>
                <.link navigate={~p"/dashboard/doctor/profile"} class="btn btn-block btn-outline justify-start">
                  <.icon name="hero-user-circle" class="w-5 h-5" />
                  Επεξεργασία Προφίλ
                </.link>
                <button class="btn btn-block btn-outline justify-start" disabled>
                  <.icon name="hero-chart-bar" class="w-5 h-5" />
                  Αναλυτικά (Σύντομα)
                </button>
              </div>
            </div>
          </div>

          <%= if @doctor && is_nil(@doctor.verified_at) do %>
            <div class="alert alert-warning">
              <.icon name="hero-exclamation-triangle" class="w-6 h-6" />
              <div>
                <h3 class="font-bold">Προφίλ υπό επαλήθευση</h3>
                <div class="text-sm">Συμπληρώστε το προφίλ σας για να εμφανιστείτε στην αναζήτηση.</div>
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
       page_title: "Dashboard Γιατρού",
       doctor: doctor,
       today_appointments: today_appointments,
       pending_count: pending_count,
       upcoming_count: upcoming_count
     )}
  end

  defp status_color("pending"), do: "warning"
  defp status_color("confirmed"), do: "success"
  defp status_color("completed"), do: "info"
  defp status_color("cancelled"), do: "error"
  defp status_color(_), do: "ghost"

  defp status_text("pending"), do: "Εκκρεμεί"
  defp status_text("confirmed"), do: "Επιβεβαιωμένο"
  defp status_text("completed"), do: "Ολοκληρώθηκε"
  defp status_text("cancelled"), do: "Ακυρώθηκε"
  defp status_text(_), do: "Άγνωστο"
end
