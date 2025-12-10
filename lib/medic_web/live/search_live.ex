defmodule MedicWeb.SearchLive do
  @moduledoc """
  Doctor search LiveView with industry-standard filters.
  """
  use MedicWeb, :live_view

  alias Medic.Doctors
  alias Medic.Search
  alias Medic.MedicalTaxonomy
  alias Medic.Hospitals

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
      <%!-- Map Container (Full Width) --%>
      <div class="w-full h-[500px] mb-8 rounded-2xl overflow-hidden shadow-xl border border-base-200 relative z-0">
        <div
          id="map-container"
          phx-hook="MapboxMap"
          phx-update="ignore"
          data-doctors={
            Jason.encode!(
              Enum.map(@doctors, fn d ->
                %{
                  id: d.id,
                  first_name: d.first_name,
                  last_name: d.last_name,
                  location_lat: Map.get(d, :location_lat),
                  location_lng: Map.get(d, :location_lng),
                  consultation_fee: Map.get(d, :consultation_fee),
                  specialty_name:
                    Map.get(d, :specialty_name) ||
                      (Map.get(d, :specialty) && Map.get(d.specialty, :name_en)) || "Doctor"
                }
              end)
            )
          }
          class="w-full h-full"
        >
        </div>
      </div>

      <%!-- Header with Search --%>
      <div class="mb-8 space-y-4">
        <h1 class="text-3xl font-bold text-base-content"><%= gettext("Find a Doctor") %></h1>
        <.form for={%{}} action={~p"/search"} method="get" class="w-full">
          <div class="flex flex-col sm:flex-row gap-3 items-center">
            <label class="input input-lg w-full bg-base-100 shadow-sm border border-base-200 flex items-center gap-3 focus-within:outline-none focus-within:ring-0 focus-within:border-base-300 transition-colors">
              <.icon name="hero-magnifying-glass" class="w-5 h-5 text-base-content/50" />
              <input
                type="text"
                id="search-input"
                value={@query}
                placeholder={gettext("Search by name, specialty, or body part...")}
                phx-keyup="search"
                phx-debounce="200"
                class="grow"
                autofocus
              />
            </label>
            <button type="submit" class="btn btn-primary btn-lg w-full sm:w-auto gap-2 shadow-lg">
              <.icon name="hero-arrow-path-rounded-square" class="w-5 h-5" /> <%= gettext("Search") %>
            </button>
          </div>
        </.form>

        <div class="flex gap-2 lg:hidden">
          <button class="btn btn-outline w-full justify-center" phx-click="toggle_filters">
            <.icon name="hero-adjustments-horizontal" class="w-5 h-5" /> <%= gettext("Filters") %>
            <%= if active_filter_count(assigns) > 0 do %>
              <div class="badge badge-primary badge-sm"><%= active_filter_count(assigns) %></div>
            <% end %>
          </button>
        </div>
      </div>

      <%!-- Active Filters Chips --%>
      <%= if has_active_filters?(assigns) do %>
        <div class="flex flex-wrap items-center gap-2 mb-6">
          <span class="text-sm text-base-content/70"><%= gettext("Active filters:") %></span>

          <%= if @selected_specialty do %>
            <button
              phx-click="remove_filter"
              phx-value-filter="specialty"
              class="badge badge-primary gap-1 p-3"
            >
              <%= get_specialty_name(@specialties, @selected_specialty) %>
              <.icon name="hero-x-mark" class="w-3 h-3" />
            </button>
          <% end %>

          <%= if @selected_city do %>
            <button
              phx-click="remove_filter"
              phx-value-filter="city"
              class="badge badge-primary gap-1 p-3"
            >
              <%= @selected_city %>
              <.icon name="hero-x-mark" class="w-3 h-3" />
            </button>
          <% end %>

          <%= if @min_rating do %>
            <button
              phx-click="remove_filter"
              phx-value-filter="rating"
              class="badge badge-primary gap-1 p-3"
            >
              <%= @min_rating %>+ ★ <.icon name="hero-x-mark" class="w-3 h-3" />
            </button>
          <% end %>

          <%= if @max_price do %>
            <button
              phx-click="remove_filter"
              phx-value-filter="price"
              class="badge badge-primary gap-1 p-3"
            >
              ≤ €<%= @max_price %>
              <.icon name="hero-x-mark" class="w-3 h-3" />
            </button>
          <% end %>

          <%= if @online_booking_only do %>
            <button
              phx-click="remove_filter"
              phx-value-filter="online_booking"
              class="badge badge-primary gap-1 p-3"
            >
              <%= gettext("Online Booking") %> <.icon name="hero-x-mark" class="w-3 h-3" />
            </button>
          <% end %>

          <button phx-click="clear_filters" class="btn btn-ghost btn-xs">
            <%= gettext("Clear all") %>
          </button>
        </div>
      <% end %>

      <%!-- Organ Search Hints --%>
      <%= if @organ_matches != [] do %>
        <div role="alert" class="alert alert-info mb-6 shadow-sm">
          <.icon name="hero-light-bulb" class="w-5 h-5" />
          <div>
            <h3 class="font-bold text-sm">Searching for "<%= @query %>"?</h3>
            <div class="text-xs">Try these specialties:</div>
          </div>
          <div class="flex flex-wrap gap-2 ml-auto">
            <%= for specialty <- @organ_matches do %>
              <button
                phx-click="filter_specialty"
                phx-value-value={specialty.id}
                class="btn btn-xs btn-outline btn-info"
              >
                <%= specialty.name %>
              </button>
            <% end %>
          </div>
        </div>
      <% end %>

      <%!-- Main Content --%>

      <div class="flex flex-col lg:flex-row gap-8">
        <%!-- Filter Sidebar --%>
        <aside class={"w-full lg:w-72 shrink-0 space-y-6 #{if @show_filters, do: "block", else: "hidden lg:block"}"}>
          <%!-- On Duty Accordion --%>
          <%= if @on_duty_hospitals != [] do %>
            <div class={"collapse collapse-arrow bg-base-100 border border-secondary/20 shadow-sm #{if @show_on_duty, do: "collapse-open"}"}>
              <div
                class="collapse-title text-sm font-bold text-secondary flex items-center gap-2 cursor-pointer hover:bg-base-200/50 transition-colors"
                phx-click="toggle_on_duty"
              >
                <.icon name="hero-building-office-2" class="w-5 h-5" /> <%= gettext(
                  "On Duty Hospitals Today"
                ) %>
              </div>
              <div class="collapse-content text-xs">
                <ul class="space-y-4 pt-2">
                  <%= for hospital <- @on_duty_hospitals do %>
                    <li class="border-b border-base-content/10 last:border-0 pb-3 last:pb-0">
                      <div class="font-bold text-sm text-base-content"><%= hospital.name %></div>
                      <%= if hospital.address do %>
                        <div class="flex items-start gap-1.5 mt-1 text-base-content/70">
                          <.icon name="hero-map-pin" class="w-3.5 h-3.5 mt-0.5 shrink-0" />
                          <span><%= hospital.address %>, <%= hospital.city %></span>
                        </div>
                      <% end %>
                      <%= if hospital.phone do %>
                        <div class="flex items-center gap-1.5 mt-1 text-base-content/70">
                          <.icon name="hero-phone" class="w-3.5 h-3.5 shrink-0" />
                          <a
                            href={"tel:#{hospital.phone}"}
                            class="hover:text-primary transition-colors"
                          >
                            <%= hospital.phone %>
                          </a>
                        </div>
                      <% end %>

                      <div class="text-base-content/60 mt-2 flex flex-wrap gap-1">
                        <%= for schedule <- hospital.hospital_schedules do %>
                          <%= for specialty <- schedule.specialties do %>
                            <div class="badge badge-xs badge-secondary badge-outline">
                              <%= specialty %>
                            </div>
                          <% end %>
                        <% end %>
                      </div>
                    </li>
                  <% end %>
                </ul>
              </div>
            </div>
          <% end %>

          <div class="card card-bordered bg-base-100 shadow-xl">
            <div class="card-body p-5 space-y-6">
              <h2 class="card-title text-lg">Filters</h2>

              <%!-- Specialty Filter --%>
              <div class="form-control w-full">
                <label class="label">
                  <span class="label-text font-medium"><%= gettext("Specialty") %></span>
                </label>
                <div class="dropdown w-full">
                  <div
                    tabindex="0"
                    role="button"
                    class="btn btn-outline w-full justify-between font-normal"
                  >
                    <%= if @selected_specialty,
                      do: get_specialty_name(@specialties, @selected_specialty),
                      else: gettext("All Specialties") %>
                    <.icon name="hero-chevron-down" class="w-4 h-4" />
                  </div>
                  <ul
                    tabindex="0"
                    class="dropdown-content menu bg-base-100 rounded-box z-[1] w-full p-2 shadow-sm max-h-60 overflow-y-auto block"
                  >
                    <li>
                      <a
                        phx-click="filter_specialty"
                        phx-value-value=""
                        class={if !@selected_specialty, do: "active"}
                      >
                        <%= gettext("All Specialties") %>
                      </a>
                    </li>
                    <%= for specialty <- @specialties do %>
                      <li>
                        <a
                          phx-click="filter_specialty"
                          phx-value-value={specialty.slug}
                          class={if @selected_specialty == specialty.slug, do: "active"}
                        >
                          <%= specialty.name_en %>
                        </a>
                      </li>
                    <% end %>
                  </ul>
                </div>
              </div>

              <%!-- City Filter --%>
              <div class="form-control w-full">
                <label class="label">
                  <span class="label-text font-medium"><%= gettext("City") %></span>
                </label>
                <div class="dropdown w-full">
                  <div
                    tabindex="0"
                    role="button"
                    class="btn btn-outline w-full justify-between font-normal"
                  >
                    <%= if @selected_city, do: @selected_city, else: gettext("All Cities") %>
                    <.icon name="hero-chevron-down" class="w-4 h-4" />
                  </div>
                  <ul
                    tabindex="0"
                    class="dropdown-content menu bg-base-100 rounded-box z-[1] w-full p-2 shadow-sm max-h-60 overflow-y-auto block"
                  >
                    <li>
                      <a
                        phx-click="filter_city"
                        phx-value-value=""
                        class={if !@selected_city, do: "active"}
                      >
                        <%= gettext("All Cities") %>
                      </a>
                    </li>
                    <%= for city <- @cities do %>
                      <li>
                        <a
                          phx-click="filter_city"
                          phx-value-value={city}
                          class={if @selected_city == city, do: "active"}
                        >
                          <%= city %>
                        </a>
                      </li>
                    <% end %>
                  </ul>
                </div>
              </div>

              <div class="divider my-0"></div>

              <%!-- Rating Filter --%>
              <div>
                <h3 class="font-medium text-sm mb-3 flex items-center gap-2">
                  <.icon name="hero-star" class="w-4 h-4 text-warning" /> <%= gettext("Rating") %>
                </h3>
                <div class="space-y-2">
                  <label class="label cursor-pointer justify-start gap-3 p-0">
                    <input
                      type="radio"
                      name="rating"
                      class="radio radio-sm radio-primary"
                      checked={@min_rating == nil}
                      phx-click="filter_rating"
                      phx-value-value=""
                    />
                    <span class="label-text"><%= gettext("Any rating") %></span>
                  </label>
                  <label class="label cursor-pointer justify-start gap-3 p-0">
                    <input
                      type="radio"
                      name="rating"
                      class="radio radio-sm radio-primary"
                      checked={@min_rating == 4.0}
                      phx-click="filter_rating"
                      phx-value-value="4.0"
                    />
                    <span class="label-text">4.0+ ★</span>
                  </label>
                  <label class="label cursor-pointer justify-start gap-3 p-0">
                    <input
                      type="radio"
                      name="rating"
                      class="radio radio-sm radio-primary"
                      checked={@min_rating == 4.5}
                      phx-click="filter_rating"
                      phx-value-value="4.5"
                    />
                    <span class="label-text">4.5+ ★</span>
                  </label>
                </div>
              </div>

              <%!-- Price Filter --%>
              <div>
                <h3 class="font-medium text-sm mb-3 flex items-center gap-2">
                  <.icon name="hero-currency-euro" class="w-4 h-4 text-success" /> <%= gettext(
                    "Max Price"
                  ) %>
                </h3>
                <input
                  type="range"
                  min="30"
                  max="200"
                  step="10"
                  value={@max_price || 200}
                  class="range range-sm range-primary"
                  phx-change="filter_price"
                />
                <div class="flex justify-between text-xs text-base-content/60 mt-2 font-medium">
                  <span>€30</span>
                  <span class="text-primary">
                    <%= if @max_price, do: "≤ €#{@max_price}", else: gettext("Any") %>
                  </span>
                  <span>€200</span>
                </div>
              </div>

              <div class="divider my-0"></div>

              <%!-- Toggles --%>
              <div class="space-y-4">
                <div class="form-control">
                  <label class="label cursor-pointer">
                    <span class="label-text flex items-center gap-2">
                      <.icon name="hero-calendar" class="w-4 h-4 text-info" /> <%= gettext(
                        "Online Booking"
                      ) %>
                    </span>
                    <input
                      type="checkbox"
                      class="toggle toggle-sm toggle-primary"
                      checked={@online_booking_only}
                      phx-click="toggle_online_booking"
                    />
                  </label>
                </div>

                <div class="form-control">
                  <label class="label cursor-pointer">
                    <span class="label-text flex items-center gap-2">
                      <.icon name="hero-check-badge" class="w-4 h-4 text-success" /> <%= gettext(
                        "Verified Only"
                      ) %>
                    </span>
                    <input
                      type="checkbox"
                      class="toggle toggle-sm toggle-primary"
                      checked={@verified_only}
                      phx-click="toggle_verified"
                    />
                  </label>
                </div>
              </div>

              <div class="divider my-0"></div>

              <button phx-click="clear_filters" class="btn btn-outline btn-sm w-full">
                <%= gettext("Clear All Filters") %>
              </button>
            </div>
          </div>
        </aside>

        <%!-- Results --%>
        <div class="flex-1 min-w-0">
          <div class="flex flex-col gap-6 relative items-start">
            <%!-- Results List --%>
            <div class="w-full space-y-6">
              <div class="flex flex-wrap items-center justify-between gap-4 bg-base-100 p-4 rounded-xl shadow-sm border border-base-200">
                <h2 class="font-bold text-lg flex items-center gap-2">
                  <.icon name="hero-list-bullet" class="w-5 h-5 text-primary" /> <%= gettext(
                    "Waitlist"
                  ) %>
                </h2>
                <div class="text-sm text-base-content/60">
                  <%= if @total > 0,
                    do: "#{@total} #{gettext("results")}",
                    else: gettext("No results") %>
                </div>
              </div>

              <%!-- Results and Pagination --%>
              <div id="doctor-results" class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                <%= for doctor <- @doctors do %>
                  <.link
                    navigate={~p"/doctors/#{doctor.id}"}
                    class="card bg-base-100 shadow-sm hover:shadow-xl transition-all duration-300 border border-base-200 group flex flex-col items-stretch overflow-hidden h-full"
                  >
                    <%!-- Card Image --%>
                    <div class="w-full h-48 bg-base-200 shrink-0 relative">
                      <%= if Map.get(doctor, :profile_image_url) do %>
                        <img
                          src={Map.get(doctor, :profile_image_url)}
                          alt={doctor.first_name}
                          class="absolute inset-0 w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
                        />
                      <% else %>
                        <div class="absolute inset-0 flex items-center justify-center bg-primary/5 text-primary">
                          <.icon name="hero-user" class="w-16 h-16 opacity-50" />
                        </div>
                      <% end %>

                      <div class="absolute top-2 right-2 flex flex-col gap-1 items-end">
                        <div class="flex items-center gap-1 bg-base-100/90 backdrop-blur-sm text-yellow-600 px-2 py-1 rounded-md text-xs font-bold shadow-sm">
                          <.icon name="hero-star-solid" class="w-3.5 h-3.5" />
                          <%= doctor.rating || "5.0" %>
                          <span class="font-normal opacity-70">
                            (<%= doctor.review_count || 12 %>)
                          </span>
                        </div>
                      </div>
                    </div>

                    <div class="card-body p-4 sm:p-5 grow flex flex-col">
                      <div class="flex-1">
                        <h3 class="card-title text-lg font-bold group-hover:text-primary transition-colors line-clamp-1">
                          Dr. <%= doctor.first_name %> <%= doctor.last_name %>
                        </h3>
                        <p class="text-sm font-medium text-base-content/70 mb-3">
                          <%= Map.get(doctor, :specialty_name) ||
                            (Map.get(doctor, :specialty) && Map.get(doctor.specialty, :name_en)) ||
                            "General Practice" %>
                        </p>

                        <div class="flex flex-wrap gap-2 mb-3">
                          <%= if doctor.verified do %>
                            <div class="badge badge-success gap-1 text-success-content badge-sm badge-outline bg-success/5">
                              <.icon name="hero-check-badge" class="size-[1em]" /> <%= gettext(
                                "Verified"
                              ) %>
                            </div>
                          <% end %>
                        </div>

                        <div class="space-y-2 text-sm text-base-content/80">
                          <div class="flex items-start gap-2">
                            <.icon
                              name="hero-map-pin"
                              class="size-[1.2em] mt-0.5 shrink-0 opacity-70"
                            />
                            <span class="line-clamp-2 leading-tight">
                              <%= Map.get(doctor, :address) || "Athens, Greece" %>
                            </span>
                          </div>
                          <%= if doctor.consultation_fee do %>
                            <div class="flex items-center gap-2">
                              <.icon
                                name="hero-currency-euro"
                                class="size-[1.2em] shrink-0 opacity-70"
                              />
                              <span>
                                <span class="font-semibold text-base-content">
                                  €<%= trunc(doctor.consultation_fee) %>
                                </span>
                                <span class="text-xs text-base-content/60 ml-0.5">
                                  <%= gettext("initial visit") %>
                                </span>
                              </span>
                            </div>
                          <% end %>
                          <div class="flex items-center gap-2 text-primary font-medium pt-1">
                            <.icon name="hero-calendar" class="size-[1.2em] shrink-0" />
                            <span>
                              <%= if doctor.next_available_slot do %>
                                <%= gettext("Next:") %> <%= Calendar.strftime(
                                  doctor.next_available_slot,
                                  "%b %d"
                                ) %>
                              <% else %>
                                <%= gettext("Tomorrow") %>
                              <% end %>
                            </span>
                          </div>
                        </div>
                      </div>

                      <div class="card-actions mt-4 pt-4 border-t border-base-content/10">
                        <button class="btn btn-primary btn-sm w-full btn-outline hover:!text-white group-hover:btn-active">
                          <%= gettext("View Profile") %>
                        </button>
                      </div>
                    </div>
                  </.link>
                <% end %>
              </div>

              <%!-- Empty State --%>
              <%= if @total == 0 do %>
                <div class="card bg-base-100 shadow-xl border border-dashed border-base-300">
                  <div class="card-body items-center text-center py-16">
                    <div class="w-24 h-24 bg-base-200 rounded-full flex items-center justify-center mb-4">
                      <.icon name="hero-magnifying-glass" class="w-12 h-12 text-base-content/30" />
                    </div>
                    <h3 class="text-xl font-bold mb-2"><%= gettext("No doctors found") %></h3>
                    <p class="text-base-content/70 max-w-md mx-auto mb-6">
                      <%= gettext(
                        "We couldn't find any doctors matching your current filters. Try adjusting your search terms or removing some filters."
                      ) %>
                    </p>
                    <button phx-click="clear_filters" class="btn btn-primary">
                      <%= gettext("Clear all filters") %>
                    </button>
                  </div>
                </div>
              <% end %>

              <%!-- Load More --%>
              <%= if @has_more do %>
                <div class="text-center mt-12">
                  <button phx-click="load_more" class="btn btn-outline btn-primary btn-wide">
                    <%= gettext("Load more results") %>
                    <.icon name="hero-arrow-down" class="w-4 h-4" />
                  </button>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    specialties = Doctors.list_specialties()
    cities = get_cities()
    on_duty_hospitals = Hospitals.list_on_duty_hospitals(Date.utc_today())

    socket =
      socket
      |> assign(
        page_title: "Find a Doctor",
        specialties: specialties,
        cities: cities,
        on_duty_hospitals: on_duty_hospitals,
        # Search
        query: params["q"] || "",
        # Filters
        selected_specialty: params["specialty"],
        selected_city: params["city"],
        min_rating: parse_float(params["rating"]),
        max_price: parse_int(params["max_price"]),
        online_booking_only: params["online"] == "true",
        verified_only: true,
        # Sort
        sort_by: params["sort"] || "rating",
        # UI State
        show_filters: false,
        organ_matches: [],
        # Results
        doctors: [],
        total: 0,
        page: 1,
        has_more: false,
        searching: false,
        use_typesense: typesense_available?()
      )

    socket = if connected?(socket), do: perform_search(socket), else: socket
    {:ok, assign(socket, show_on_duty: false)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign(
        query: params["q"] || socket.assigns.query,
        selected_specialty: params["specialty"] || socket.assigns.selected_specialty,
        selected_city: params["city"] || socket.assigns.selected_city,
        min_rating: parse_float(params["rating"]) || socket.assigns.min_rating,
        max_price: parse_int(params["max_price"]) || socket.assigns.max_price,
        online_booking_only: params["online"] == "true" || socket.assigns.online_booking_only,
        sort_by: params["sort"] || socket.assigns.sort_by
      )
      |> perform_search()

    {:noreply, socket}
  end

  # Event Handlers

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    organ_matches =
      if String.length(query) >= 3 do
        MedicalTaxonomy.search_specialties_by_organ(query) |> Enum.take(5)
      else
        []
      end

    socket =
      socket
      |> assign(query: query, page: 1, searching: true, organ_matches: organ_matches)
      |> perform_search()
      |> push_url_params()

    {:noreply, socket}
  end

  def handle_event("filter_specialty", %{"value" => value}, socket) do
    specialty = if value == "", do: nil, else: value

    socket =
      socket
      |> assign(selected_specialty: specialty, page: 1, searching: true, organ_matches: [])
      |> perform_search()
      |> push_url_params()

    {:noreply, socket}
  end

  def handle_event("filter_city", %{"value" => value}, socket) do
    city = if value == "", do: nil, else: value

    socket =
      socket
      |> assign(selected_city: city, page: 1, searching: true)
      |> perform_search()
      |> push_url_params()

    {:noreply, socket}
  end

  def handle_event("filter_rating", %{"value" => value}, socket) do
    rating = parse_float(value)

    socket =
      socket
      |> assign(min_rating: rating, page: 1, searching: true)
      |> perform_search()
      |> push_url_params()

    {:noreply, socket}
  end

  def handle_event("filter_price", %{"value" => value}, socket) do
    price = parse_int(value)
    # Only set filter if less than max
    max_price = if price && price < 200, do: price, else: nil

    socket =
      socket
      |> assign(max_price: max_price, page: 1, searching: true)
      |> perform_search()
      |> push_url_params()

    {:noreply, socket}
  end

  def handle_event("toggle_online_booking", _, socket) do
    socket =
      socket
      |> assign(
        online_booking_only: !socket.assigns.online_booking_only,
        page: 1,
        searching: true
      )
      |> perform_search()
      |> push_url_params()

    {:noreply, socket}
  end

  def handle_event("toggle_verified", _, socket) do
    socket =
      socket
      |> assign(verified_only: !socket.assigns.verified_only, page: 1, searching: true)
      |> perform_search()
      |> push_url_params()

    {:noreply, socket}
  end

  def handle_event("toggle_on_duty", _, socket) do
    {:noreply, assign(socket, show_on_duty: !socket.assigns.show_on_duty)}
  end

  def handle_event("toggle_filters", _, socket) do
    {:noreply, assign(socket, show_filters: !socket.assigns.show_filters)}
  end

  def handle_event("sort", %{"value" => sort_by}, socket) do
    socket =
      socket
      |> assign(sort_by: sort_by, page: 1, searching: true)
      |> perform_search()
      |> push_url_params()

    {:noreply, socket}
  end

  def handle_event("remove_filter", %{"filter" => filter}, socket) do
    socket =
      case filter do
        "specialty" -> assign(socket, selected_specialty: nil)
        "city" -> assign(socket, selected_city: nil)
        "rating" -> assign(socket, min_rating: nil)
        "price" -> assign(socket, max_price: nil)
        "online_booking" -> assign(socket, online_booking_only: false)
        _ -> socket
      end
      |> assign(page: 1, searching: true)
      |> perform_search()
      |> push_url_params()

    {:noreply, socket}
  end

  def handle_event("clear_filters", _, socket) do
    socket =
      socket
      |> assign(
        query: "",
        selected_specialty: nil,
        selected_city: nil,
        min_rating: nil,
        max_price: nil,
        online_booking_only: false,
        verified_only: true,
        sort_by: "rating",
        page: 1,
        organ_matches: []
      )
      |> perform_search()
      |> push_url_params()

    {:noreply, socket}
  end

  def handle_event("load_more", _, socket) do
    socket =
      socket
      |> assign(page: socket.assigns.page + 1)
      |> perform_search(append: true)

    {:noreply, socket}
  end

  # Private Functions

  defp perform_search(socket, opts \\ []) do
    append = Keyword.get(opts, :append, false)

    if socket.assigns.use_typesense do
      search_with_typesense(socket, append)
    else
      search_with_ecto(socket, append)
    end
  end

  defp search_with_typesense(socket, append) do
    assigns = socket.assigns

    search_opts = [
      query: if(assigns.query == "", do: "*", else: assigns.query),
      specialty: assigns.selected_specialty,
      city: assigns.selected_city,
      min_rating: assigns.min_rating,
      max_price: assigns.max_price,
      has_cal_com: if(assigns.online_booking_only, do: true, else: nil),
      verified_only: assigns.verified_only,
      page: assigns.page,
      per_page: 12,
      sort_by: assigns.sort_by
    ]

    case Search.search_doctors(search_opts) do
      {:ok, %{results: results, total: total}} ->
        doctors = if append, do: assigns.doctors ++ results, else: results
        has_more = length(doctors) < total

        assign(socket, doctors: doctors, total: total, has_more: has_more, searching: false)

      {:error, _reason} ->
        search_with_ecto(socket, append)
    end
  end

  defp search_with_ecto(socket, append) do
    assigns = socket.assigns
    opts = [preload: [:specialty]]

    opts = if assigns.verified_only, do: Keyword.put(opts, :verified, true), else: opts

    opts =
      if assigns.selected_specialty do
        specialty = Doctors.get_specialty_by_slug(assigns.selected_specialty)
        if specialty, do: Keyword.put(opts, :specialty_id, specialty.id), else: opts
      else
        opts
      end

    opts =
      if assigns.selected_city, do: Keyword.put(opts, :city, assigns.selected_city), else: opts

    doctors =
      Doctors.list_doctors(opts)
      |> Enum.map(fn d ->
        %{
          id: d.id,
          first_name: d.first_name,
          last_name: d.last_name,
          title: d.title || "Dr.",
          pronouns: d.pronouns,
          specialty_name: d.specialty && d.specialty.name_en,
          city: d.city,
          rating: d.rating || 0.0,
          review_count: d.review_count || 0,
          consultation_fee: d.consultation_fee && Decimal.to_float(d.consultation_fee),
          verified: d.verified_at != nil,
          next_available_slot: d.next_available_slot,
          has_cal_com: false
        }
      end)
      |> maybe_filter_rating(assigns.min_rating)
      |> maybe_filter_price(assigns.max_price)
      |> maybe_filter_online(assigns.online_booking_only)
      |> sort_doctors(assigns.sort_by)

    all_doctors = if append, do: assigns.doctors ++ doctors, else: doctors

    assign(socket,
      doctors: all_doctors,
      total: length(all_doctors),
      has_more: false,
      searching: false
    )
  end

  defp maybe_filter_rating(doctors, nil), do: doctors
  defp maybe_filter_rating(doctors, min), do: Enum.filter(doctors, &(&1.rating >= min))

  defp maybe_filter_price(doctors, nil), do: doctors

  defp maybe_filter_price(doctors, max),
    do: Enum.filter(doctors, &(&1.consultation_fee && &1.consultation_fee <= max))

  defp maybe_filter_online(doctors, false), do: doctors
  defp maybe_filter_online(doctors, true), do: Enum.filter(doctors, & &1.has_cal_com)

  defp sort_doctors(doctors, "rating"), do: Enum.sort_by(doctors, &(&1.rating || 0), :desc)
  defp sort_doctors(doctors, "reviews"), do: Enum.sort_by(doctors, &(&1.review_count || 0), :desc)

  defp sort_doctors(doctors, "price_low"),
    do: Enum.sort_by(doctors, &(&1.consultation_fee || 999))

  defp sort_doctors(doctors, "price_high"),
    do: Enum.sort_by(doctors, &(&1.consultation_fee || 0), :desc)

  defp sort_doctors(doctors, _), do: doctors

  defp push_url_params(socket) do
    params = %{}
    assigns = socket.assigns

    params = if assigns.query != "", do: Map.put(params, "q", assigns.query), else: params

    params =
      if assigns.selected_specialty,
        do: Map.put(params, "specialty", assigns.selected_specialty),
        else: params

    params =
      if assigns.selected_city, do: Map.put(params, "city", assigns.selected_city), else: params

    params =
      if assigns.min_rating, do: Map.put(params, "rating", assigns.min_rating), else: params

    params =
      if assigns.max_price, do: Map.put(params, "max_price", assigns.max_price), else: params

    params = if assigns.online_booking_only, do: Map.put(params, "online", "true"), else: params

    params =
      if assigns.sort_by != "rating", do: Map.put(params, "sort", assigns.sort_by), else: params

    push_patch(socket, to: ~p"/search?#{params}", replace: true)
  end

  defp get_cities do
    [
      "Athens",
      "Thessaloniki",
      "Patras",
      "Heraklion",
      "Larissa",
      "Volos",
      "Ioannina",
      "Chania",
      "Rhodes",
      "Alexandroupoli",
      "Kalamata",
      "Kavala",
      "Serres",
      "Corfu"
    ]
  end

  defp typesense_available? do
    case Search.search_doctors(query: "*", per_page: 1) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  rescue
    _ -> false
  end

  defp parse_float(nil), do: nil
  defp parse_float(""), do: nil

  defp parse_float(val) when is_binary(val) do
    case Float.parse(val) do
      {f, _} -> f
      :error -> nil
    end
  end

  defp parse_float(val) when is_number(val), do: val

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {i, _} -> i
      :error -> nil
    end
  end

  defp parse_int(val) when is_integer(val), do: val

  defp has_active_filters?(assigns) do
    assigns.selected_specialty || assigns.selected_city || assigns.min_rating ||
      assigns.max_price || assigns.online_booking_only
  end

  defp active_filter_count(assigns) do
    [
      assigns.selected_specialty,
      assigns.selected_city,
      assigns.min_rating,
      assigns.max_price,
      assigns.online_booking_only && true
    ]
    |> Enum.count(& &1)
  end

  defp get_specialty_name(specialties, slug) do
    case Enum.find(specialties, &(&1.slug == slug)) do
      nil -> slug
      s -> s.name_en
    end
  end
end
