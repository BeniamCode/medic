defmodule MedicWeb.HomeLive do
  use MedicWeb, :live_view

  alias Medic.Doctors
  alias Medic.MedicalTaxonomy
  alias Medic.Hospitals

  def render(assigns) do
    ~H"""
    <div class="min-h-screen">
      <%!-- Hero Section --%>
      <section class="relative py-20 px-4 overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-secondary/5"></div>
        <div class="max-w-6xl mx-auto relative">
          <div class="text-center space-y-6">
            <h1 class="text-4xl md:text-6xl font-bold leading-tight">
              Find the right
              <span class="text-primary">doctor</span>
              <br />
              for you
            </h1>
            <p class="text-xl text-base-content/70 max-w-2xl mx-auto">
              Search among hundreds of specialized doctors
              and book your appointment instantly.
            </p>

            <%!-- Search Bar --%>
            <div class="max-w-2xl mx-auto mt-8">
              <.form for={%{}} action={~p"/search"} method="get" class="flex gap-2">
                <div class="flex-1 relative">
                  <.icon name="hero-magnifying-glass" class="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-base-content/50" />
                  <input
                    type="text"
                    name="q"
                    placeholder="Search by doctor, specialty, or body part..."
                    class="input input-lg w-full pl-12 bg-base-100 border-base-300 focus:border-primary"
                  />
                </div>
                <button type="submit" class="btn btn-primary btn-lg">
                  Search
                </button>
              </.form>
            </div>
          </div>
        </div>
      </section>

      <%!-- On Duty Hospitals Section --%>
      <%= if @on_duty_hospitals != [] do %>
        <section class="py-12 px-4 bg-secondary/5">
          <div class="max-w-6xl mx-auto">
            <div class="flex items-center gap-3 mb-8">
              <div class="p-2 rounded-lg bg-secondary/10 text-secondary">
                <.icon name="hero-building-office-2" class="w-6 h-6" />
              </div>
              <div>
                <h2 class="text-2xl font-bold text-base-content">Hospitals On Duty Today</h2>
                <p class="text-sm text-base-content/60"><%= Calendar.strftime(Date.utc_today(), "%A, %d %B %Y") %></p>
              </div>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <%= for hospital <- @on_duty_hospitals do %>
                <div class="card bg-base-100 shadow-sm hover:shadow-md transition-shadow border border-base-200">
                  <div class="card-body p-5">
                    <div class="flex items-start justify-between gap-4">
                      <div>
                        <h3 class="font-semibold text-lg leading-snug mb-1"><%= hospital.name %></h3>
                        <div class="flex items-center gap-1 text-xs text-base-content/60">
                          <.icon name="hero-map-pin" class="w-3 h-3" />
                          <%= hospital.city %>
                        </div>
                      </div>
                      <div class="badge badge-sm badge-outline text-xs">On Call</div>
                    </div>
                    
                    <div class="mt-4">
                      <div class="text-xs font-medium text-base-content/50 mb-2 uppercase tracking-wider">Departments</div>
                      <div class="flex flex-wrap gap-1.5">
                        <%= for schedule <- hospital.hospital_schedules do %>
                          <%= for specialty <- schedule.specialties do %>
                            <span class="badge badge-primary badge-soft badge-sm text-xs font-normal">
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
      <section class="py-16 px-4 bg-base-200/30">
        <div class="max-w-6xl mx-auto">
          <h2 class="text-2xl font-bold text-center mb-8">Popular Specialties</h2>
          <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            <%= for specialty <- @specialties do %>
              <.link
                navigate={~p"/search?specialty=#{specialty.id}"}
                class="card bg-base-100 hover:shadow-lg transition-all duration-300 hover:-translate-y-1 group"
              >
                <div class="card-body items-center text-center p-4">
                  <div class="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center group-hover:bg-primary/20 transition-colors">
                    <.icon name={specialty.icon || "hero-heart"} class="w-6 h-6 text-primary" />
                  </div>
                  <h3 class="font-medium text-sm mt-2"><%= specialty.name %></h3>
                </div>
              </.link>
            <% end %>
          </div>
        </div>
      </section>

      <%!-- Stats Section --%>
      <section class="py-16 px-4">
        <div class="max-w-4xl mx-auto">
          <div class="stats stats-vertical md:stats-horizontal shadow w-full">
            <div class="stat place-items-center">
              <div class="stat-figure text-primary">
                <.icon name="hero-users" class="w-8 h-8" />
              </div>
              <div class="stat-title">Doctors</div>
              <div class="stat-value text-primary">600+</div>
              <div class="stat-desc">Verified professionals</div>
            </div>
            <div class="stat place-items-center">
              <div class="stat-figure text-secondary">
                <.icon name="hero-calendar-days" class="w-8 h-8" />
              </div>
              <div class="stat-title">Appointments</div>
              <div class="stat-value text-secondary">10K+</div>
              <div class="stat-desc">Booked via Medic</div>
            </div>
            <div class="stat place-items-center">
              <div class="stat-figure text-accent">
                <.icon name="hero-star" class="w-8 h-8" />
              </div>
              <div class="stat-title">Rating</div>
              <div class="stat-value">4.8</div>
              <div class="stat-desc">From our users</div>
            </div>
          </div>
        </div>
      </section>

      <%!-- How It Works --%>
      <section class="py-16 px-4 bg-base-200/30">
        <div class="max-w-4xl mx-auto">
          <h2 class="text-2xl font-bold text-center mb-12">How It Works</h2>
          <div class="grid md:grid-cols-3 gap-8">
            <div class="text-center space-y-4">
              <div class="w-16 h-16 mx-auto rounded-full bg-primary text-primary-content flex items-center justify-center text-2xl font-bold">
                1
              </div>
              <h3 class="font-semibold text-lg">Search</h3>
              <p class="text-base-content/70">
                Find the doctor you need by specialty, body part, or location
              </p>
            </div>
            <div class="text-center space-y-4">
              <div class="w-16 h-16 mx-auto rounded-full bg-secondary text-secondary-content flex items-center justify-center text-2xl font-bold">
                2
              </div>
              <h3 class="font-semibold text-lg">Choose Time</h3>
              <p class="text-base-content/70">
                See real-time availability and pick a convenient time slot
              </p>
            </div>
            <div class="text-center space-y-4">
              <div class="w-16 h-16 mx-auto rounded-full bg-accent text-accent-content flex items-center justify-center text-2xl font-bold">
                3
              </div>
              <h3 class="font-semibold text-lg">Confirm</h3>
              <p class="text-base-content/70">
                Get confirmation and reminders for your appointment
              </p>
            </div>
          </div>
        </div>
      </section>

      <%!-- CTA Section --%>
      <section class="py-20 px-4">
        <div class="max-w-4xl mx-auto text-center">
          <h2 class="text-3xl font-bold mb-4">Are You a Doctor?</h2>
          <p class="text-xl text-base-content/70 mb-8">
            Join the Medic network and increase your visibility
          </p>
          <.link navigate={~p"/register/doctor"} class="btn btn-primary btn-lg">
            <.icon name="hero-identification" class="w-5 h-5 mr-2" />
            Doctor Registration
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
    
    {:ok, assign(socket, 
      specialties: specialties, 
      on_duty_hospitals: on_duty_hospitals,
      page_title: "Find a Doctor"
    )}
  end
end
