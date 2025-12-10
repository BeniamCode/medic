defmodule MedicWeb.HomeLive do
  use MedicWeb, :live_view

  alias Medic.MedicalTaxonomy
  alias Medic.Hospitals

  def render(assigns) do
    ~H"""
    <div class="min-h-screen">
      <%!-- Hero Section --%>
      <section class="hero min-h-[70vh] bg-base-200 relative overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-secondary/5">
        </div>
        <div class="hero-content text-center relative z-10">
          <div class="max-w-3xl">
            <h1 class="text-5xl md:text-7xl font-bold leading-tight">
              <%= gettext("Find the right") %> <span class="text-primary"><%= gettext("doctor") %></span>
              <br /> <%= gettext("for you") %>
            </h1>
            <p class="py-6 text-xl text-base-content/70 max-w-2xl mx-auto">
              <%= gettext("Search among hundreds of specialized doctors and book your appointment instantly.") %>
            </p>

            <%!-- Search Bar --%>
            <div class="max-w-2xl mx-auto mt-8">
              <.form for={%{}} action={~p"/search"} method="get" class="join w-full shadow-lg">
                <div class="relative flex-1 join-item">
                  <.icon
                    name="hero-magnifying-glass"
                    class="absolute left-4 top-1/2 -translate-y-1/2 size-5 text-base-content/50"
                  />
                  <input
                    type="text"
                    name="q"
                    placeholder={gettext("Search by doctor, specialty, or body part...")}
                    class="input input-lg w-full pl-12 bg-base-100 border-base-300 focus:border-primary join-item"
                  />
                </div>
                <button type="submit" class="btn btn-primary btn-lg join-item">
                  <%= gettext("Search") %>
                </button>
              </.form>
            </div>
          </div>
        </div>
      </section>

      <%!-- On Duty Hospitals Section --%>
      <%= if @on_duty_hospitals != [] do %>
        <section class="py-16 px-4 bg-base-100">
          <div class="max-w-6xl mx-auto">
            <div class="flex items-center gap-3 mb-8">
              <div class="p-2 rounded-lg bg-secondary/10 text-secondary">
                <.icon name="hero-building-office-2" class="size-6" />
              </div>
              <div>
                <h2 class="text-2xl font-bold"><%= gettext("Hospitals On Duty Today") %></h2>
                <p class="text-sm text-base-content/60">
                  <%= Calendar.strftime(Date.utc_today(), "%A, %d %B %Y") %>
                </p>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <%= for hospital <- @on_duty_hospitals do %>
                <div class="card bg-base-100 shadow-xl border border-base-200 hover:border-primary transition-colors">
                  <div class="card-body p-5">
                    <div class="flex items-start justify-between gap-4">
                      <div>
                        <h3 class="card-title text-lg leading-snug mb-1"><%= hospital.name %></h3>
                        <div class="flex items-center gap-1 text-xs text-base-content/60">
                          <.icon name="hero-map-pin" class="size-3" />
                          <%= hospital.city %>
                        </div>
                      </div>
                      <div class="badge badge-secondary badge-outline text-xs"><%= gettext("On Call") %></div>
                    </div>

                    <div class="mt-4">
                      <div class="text-xs font-bold text-base-content/50 mb-2 uppercase tracking-wider">
                        <%= gettext("Departments") %>
                      </div>
                      <div class="flex flex-wrap gap-1.5">
                        <%= for schedule <- hospital.hospital_schedules do %>
                          <%= for specialty <- schedule.specialties do %>
                            <span class="badge badge-primary badge-outline badge-sm text-xs">
                              <%= specialty %>
                            </span>
                          <% end %>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </section>
      <% end %>

      <%!-- Specialties Grid --%>
      <section class="py-16 px-4 bg-base-200">
        <div class="max-w-6xl mx-auto">
          <h2 class="text-3xl font-bold text-center mb-12"><%= gettext("Popular Specialties") %></h2>
          <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            <%= for specialty <- @specialties do %>
              <.link
                navigate={~p"/search?specialty=#{specialty.id}"}
                class="card bg-base-100 shadow-sm hover:shadow-xl transition-all duration-300 hover:-translate-y-1 group"
              >
                <div class="card-body items-center text-center p-4">
                  <div class="avatar placeholder mb-2">
                    <div class="bg-primary/10 text-primary rounded-full w-12 group-hover:bg-primary group-hover:text-primary-content transition-colors">
                      <.icon name={specialty.icon || "hero-heart"} class="size-6" />
                    </div>
                  </div>
                  <h3 class="font-bold text-sm"><%= specialty.name %></h3>
                </div>
              </.link>
            <% end %>
          </div>
        </div>
      </section>

      <%!-- Stats Section --%>
      <section class="py-16 px-4 bg-base-100">
        <div class="max-w-4xl mx-auto">
          <div class="stats stats-vertical md:stats-horizontal shadow-xl w-full bg-base-100">
            <div class="stat place-items-center">
              <div class="stat-figure text-primary">
                <.icon name="hero-users" class="size-8" />
              </div>
              <div class="stat-title"><%= gettext("Doctors") %></div>
              <div class="stat-value text-primary">600+</div>
              <div class="stat-desc"><%= gettext("Verified professionals") %></div>
            </div>
            <div class="stat place-items-center">
              <div class="stat-figure text-secondary">
                <.icon name="hero-calendar-days" class="size-8" />
              </div>
              <div class="stat-title"><%= gettext("Appointments") %></div>
              <div class="stat-value text-secondary">10K+</div>
              <div class="stat-desc"><%= gettext("Booked via Medic") %></div>
            </div>
            <div class="stat place-items-center">
              <div class="stat-figure text-accent">
                <.icon name="hero-star" class="size-8" />
              </div>
              <div class="stat-title"><%= gettext("Rating") %></div>
              <div class="stat-value text-accent">4.8</div>
              <div class="stat-desc"><%= gettext("From our users") %></div>
            </div>
          </div>
        </div>
      </section>

      <%!-- How It Works --%>
      <section class="py-16 px-4 bg-base-200">
        <div class="max-w-4xl mx-auto">
          <h2 class="text-3xl font-bold text-center mb-12"><%= gettext("How It Works") %></h2>
          <div class="grid md:grid-cols-3 gap-8">
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body items-center text-center">
                <div class="w-16 h-16 rounded-full bg-primary text-primary-content flex items-center justify-center text-2xl font-bold mb-4">
                  1
                </div>
                <h3 class="card-title"><%= gettext("Search") %></h3>
                <p class="text-base-content/70">
                  <%= gettext("Find the doctor you need by specialty, body part, or location") %>
                </p>
              </div>
            </div>
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body items-center text-center">
                <div class="w-16 h-16 rounded-full bg-secondary text-secondary-content flex items-center justify-center text-2xl font-bold mb-4">
                  2
                </div>
                <h3 class="card-title"><%= gettext("Choose Time") %></h3>
                <p class="text-base-content/70">
                  <%= gettext("See real-time availability and pick a convenient time slot") %>
                </p>
              </div>
            </div>
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body items-center text-center">
                <div class="w-16 h-16 rounded-full bg-accent text-accent-content flex items-center justify-center text-2xl font-bold mb-4">
                  3
                </div>
                <h3 class="card-title"><%= gettext("Confirm") %></h3>
                <p class="text-base-content/70">
                  <%= gettext("Get confirmation and reminders for your appointment") %>
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <%!-- CTA Section --%>
      <section class="py-20 px-4 bg-base-100">
        <div class="max-w-4xl mx-auto text-center">
          <h2 class="text-4xl font-bold mb-4"><%= gettext("Are You a Doctor?") %></h2>
          <p class="text-xl text-base-content/70 mb-8">
            <%= gettext("Join the Medic network and increase your visibility") %>
          </p>
          <.link navigate={~p"/register/doctor"} class="btn btn-primary btn-lg">
            <.icon name="hero-identification" class="size-5 mr-2" /> <%= gettext("Doctor Registration") %>
          </.link>
        </div>
      </section>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    # Use popular specialties from taxonomy
    specialties = MedicalTaxonomy.popular_specialties()
    on_duty_hospitals = Hospitals.list_on_duty_hospitals(Date.utc_today())

    {:ok,
     assign(socket,
       specialties: specialties,
       on_duty_hospitals: on_duty_hospitals,
       page_title: "Find a Doctor"
     )}
  end
end
