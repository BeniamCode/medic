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
    <div class="max-w-7xl mx-auto py-6 px-4">
      <%!-- Header with Search --%>
      <div class="mb-6">
        <h1 class="text-2xl font-bold mb-4">Find a Doctor</h1>
        <div class="flex flex-col lg:flex-row gap-4">
          <div class="flex-1 relative">
            <.icon name="hero-magnifying-glass" class="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-base-content/50" />
            <input
              type="text"
              id="search-input"
              value={@query}
              placeholder="Search by name, specialty, or body part..."
              phx-keyup="search"
              phx-debounce="200"
              class="input input-bordered w-full pl-12"
              autofocus
            />
          </div>
          <div class="flex gap-2">
            <select class="select select-bordered" phx-change="sort">
              <option value="rating" selected={@sort_by == "rating"}>Highest Rated</option>
              <option value="price_low" selected={@sort_by == "price_low"}>Price: Low to High</option>
              <option value="price_high" selected={@sort_by == "price_high"}>Price: High to Low</option>
              <option value="reviews" selected={@sort_by == "reviews"}>Most Reviews</option>
            </select>
            <button
              class="btn btn-outline lg:hidden"
              phx-click="toggle_filters"
            >
              <.icon name="hero-adjustments-horizontal" class="w-5 h-5" />
              Filters
              <%= if active_filter_count(assigns) > 0 do %>
                <span class="badge badge-primary badge-sm"><%= active_filter_count(assigns) %></span>
              <% end %>
            </button>
          </div>
        </div>
      </div>

      <%!-- Active Filters Chips --%>
      <%= if has_active_filters?(assigns) do %>
        <div class="flex flex-wrap items-center gap-2 mb-4">
          <span class="text-sm text-base-content/70">Active filters:</span>

          <%= if @selected_specialty do %>
            <button phx-click="remove_filter" phx-value-filter="specialty" class="badge badge-primary gap-1">
              <%= get_specialty_name(@specialties, @selected_specialty) %>
              <.icon name="hero-x-mark" class="w-3 h-3" />
            </button>
          <% end %>

          <%= if @selected_city do %>
            <button phx-click="remove_filter" phx-value-filter="city" class="badge badge-primary gap-1">
              <%= @selected_city %>
              <.icon name="hero-x-mark" class="w-3 h-3" />
            </button>
          <% end %>

          <%= if @min_rating do %>
            <button phx-click="remove_filter" phx-value-filter="rating" class="badge badge-primary gap-1">
              <%= @min_rating %>+ ★
              <.icon name="hero-x-mark" class="w-3 h-3" />
            </button>
          <% end %>

          <%= if @max_price do %>
            <button phx-click="remove_filter" phx-value-filter="price" class="badge badge-primary gap-1">
              ≤ €<%= @max_price %>
              <.icon name="hero-x-mark" class="w-3 h-3" />
            </button>
          <% end %>

          <%= if @online_booking_only do %>
            <button phx-click="remove_filter" phx-value-filter="online_booking" class="badge badge-primary gap-1">
              Online Booking
              <.icon name="hero-x-mark" class="w-3 h-3" />
            </button>
          <% end %>

          <button phx-click="clear_filters" class="btn btn-ghost btn-xs">
            Clear all
          </button>
        </div>
      <% end %>

      <%!-- Organ Search Hints --%>
      <%= if @organ_matches != [] do %>
        <div class="mb-4 p-3 bg-info/10 rounded-lg">
          <p class="text-sm text-info font-medium mb-2">
            <.icon name="hero-light-bulb" class="w-4 h-4 inline-block mr-1" />
            Searching for "<%= @query %>"? Try these specialties:
          </p>
          <div class="flex flex-wrap gap-2">
            <%= for specialty <- @organ_matches do %>
              <button
                phx-click="filter_specialty"
                phx-value-value={specialty.id}
                class="badge badge-outline cursor-pointer hover:badge-primary"
              >
                <%= specialty.name %>
              </button>
            <% end %>
          </div>
        </div>
      <% end %>

      <%!-- Main Content: Sidebar + Results --%>
      <div class="flex gap-6">
        <%!-- Filter Sidebar --%>
        <aside class={"w-64 shrink-0 space-y-6 #{if @show_filters, do: "block", else: "hidden lg:block"}"}>
          
          <%!-- On Duty Accordion --%>
          <%= if @on_duty_hospitals != [] do %>
            <div class="collapse collapse-arrow bg-secondary/10 border border-secondary/20">
              <input type="checkbox" /> 
              <div class="collapse-title text-sm font-semibold text-secondary-content flex items-center gap-2">
                <.icon name="hero-building-office-2" class="w-4 h-4" />
                On Duty Today
              </div>
              <div class="collapse-content text-xs"> 
                <ul class="space-y-3 pt-2">
                  <%= for hospital <- @on_duty_hospitals do %>
                    <li class="border-b border-secondary/10 last:border-0 pb-2 last:pb-0">
                      <div class="font-bold text-base-content"><%= hospital.name %></div>
                      <div class="text-base-content/60 mt-1 flex flex-wrap gap-1">
                        <%= for schedule <- hospital.hospital_schedules do %>
                          <%= for specialty <- schedule.specialties do %>
                            <span class="badge badge-xs badge-ghost"><%= specialty %></span>
                          <% end %>
                        <% end %>
                      </div>
                    </li>
                  <% end %>
                </ul>
              </div>
            </div>
          <% end %>

          <div class="card bg-base-100 shadow-sm">
            <div class="card-body p-4 space-y-5">

              <%!-- Specialty Filter --%>
              <div>
                <h3 class="font-semibold text-sm mb-2">Specialty</h3>
                <select
                  class="select select-bordered select-sm w-full"
                  phx-change="filter_specialty"
                >
                  <option value="">All Specialties</option>
                  <%= for specialty <- @specialties do %>
                    <option value={specialty.slug} selected={@selected_specialty == specialty.slug}>
                      <%= specialty.name_en %>
                    </option>
                  <% end %>
                </select>
              </div>

              <%!-- City Filter --%>
              <div>
                <h3 class="font-semibold text-sm mb-2">City</h3>
                <select
                  class="select select-bordered select-sm w-full"
                  phx-change="filter_city"
                >
                  <option value="">All Cities</option>
                  <%= for city <- @cities do %>
                    <option value={city} selected={@selected_city == city}>
                      <%= city %>
                    </option>
                  <% end %>
                </select>
              </div>

              <div class="divider my-2"></div>

              <%!-- Rating Filter --%>
              <div>
                <h3 class="font-semibold text-sm mb-2">
                  <.icon name="hero-star" class="w-4 h-4 inline text-warning" />
                  Rating
                </h3>
                <div class="space-y-1">
                  <label class="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      name="rating"
                      class="radio radio-sm radio-primary"
                      checked={@min_rating == nil}
                      phx-click="filter_rating"
                      phx-value-value=""
                    />
                    <span class="text-sm">Any rating</span>
                  </label>
                  <label class="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      name="rating"
                      class="radio radio-sm radio-primary"
                      checked={@min_rating == 4.0}
                      phx-click="filter_rating"
                      phx-value-value="4.0"
                    />
                    <span class="text-sm">4.0+ ★</span>
                  </label>
                  <label class="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      name="rating"
                      class="radio radio-sm radio-primary"
                      checked={@min_rating == 4.5}
                      phx-click="filter_rating"
                      phx-value-value="4.5"
                    />
                    <span class="text-sm">4.5+ ★</span>
                  </label>
                </div>
              </div>

              <%!-- Price Filter --%>
              <div>
                <h3 class="font-semibold text-sm mb-2">
                  <.icon name="hero-currency-euro" class="w-4 h-4 inline text-success" />
                  Max Price
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
                <div class="flex justify-between text-xs text-base-content/60 mt-1">
                  <span>€30</span>
                  <span class="font-medium text-primary">
                    <%= if @max_price, do: "≤ €#{@max_price}", else: "Any" %>
                  </span>
                  <span>€200</span>
                </div>
              </div>

              <div class="divider my-2"></div>

              <%!-- Toggle Filters --%>
              <div class="space-y-3">
                <label class="flex items-center justify-between cursor-pointer">
                  <span class="text-sm">
                    <.icon name="hero-calendar" class="w-4 h-4 inline text-info mr-1" />
                    Online Booking
                  </span>
                  <input
                    type="checkbox"
                    class="toggle toggle-sm toggle-primary"
                    checked={@online_booking_only}
                    phx-click="toggle_online_booking"
                  />
                </label>

                <label class="flex items-center justify-between cursor-pointer">
                  <span class="text-sm">
                    <.icon name="hero-check-badge" class="w-4 h-4 inline text-success mr-1" />
                    Verified Only
                  </span>
                  <input
                    type="checkbox"
                    class="toggle toggle-sm toggle-primary"
                    checked={@verified_only}
                    phx-click="toggle_verified"
                  />
                </label>
              </div>

              <div class="divider my-2"></div>

              <button phx-click="clear_filters" class="btn btn-outline btn-sm w-full">
                <.icon name="hero-x-mark" class="w-4 h-4" />
                Clear All Filters
              </button>
            </div>
          </div>
        </aside>

        <%!-- Results --%>
        <div class="flex-1">
          <%!-- Results Count --%>
          <div class="text-sm text-base-content/70 mb-4">
            <%= if @total > 0 do %>
              Found <span class="font-semibold"><%= @total %></span> doctors
            <% else %>
              <%= if @searching do %>
                <span class="loading loading-spinner loading-xs"></span> Searching...
              <% else %>
                No results found
              <% end %>
            <% end %>
          </div>

          <%!-- Results Grid --%>
          <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            <%= for doctor <- @doctors do %>
              <.link navigate={~p"/doctors/#{doctor.id}"} class="card bg-base-100 shadow-md hover:shadow-lg transition-all duration-200 hover:-translate-y-0.5">
                <div class="card-body p-4">
                  <div class="flex items-start gap-3">
                    <div class="avatar placeholder">
                      <div class="w-14 h-14 rounded-full bg-primary/10 text-primary">
                        <.icon name="hero-user" class="w-7 h-7" />
                      </div>
                    </div>
                    <div class="flex-1 min-w-0">
                      <h3 class="font-semibold truncate">Dr. <%= doctor.first_name %> <%= doctor.last_name %></h3>
                      <p class="text-sm text-base-content/70 truncate">
                        <%= doctor.specialty_name || "General Practice" %>
                      </p>
                      <div class="flex items-center gap-2 mt-1">
                        <%= if doctor.verified do %>
                          <span class="badge badge-success badge-xs gap-0.5">
                            <.icon name="hero-check-badge" class="w-2.5 h-2.5" />
                            Verified
                          </span>
                        <% end %>
                        <%= if doctor.has_cal_com do %>
                          <span class="badge badge-info badge-xs gap-0.5">
                            <.icon name="hero-calendar" class="w-2.5 h-2.5" />
                            Book Online
                          </span>
                        <% end %>
                      </div>
                    </div>
                  </div>

                  <div class="flex items-center justify-between mt-3 pt-3 border-t border-base-200">
                    <div class="flex items-center gap-1">
                      <.icon name="hero-star" class="w-4 h-4 text-warning" />
                      <span class="font-medium"><%= Float.round(doctor.rating || 0.0, 1) %></span>
                      <span class="text-xs text-base-content/60">(<%= doctor.review_count || 0 %>)</span>
                    </div>

                    <%= if doctor.city do %>
                      <div class="flex items-center gap-1 text-xs text-base-content/60">
                        <.icon name="hero-map-pin" class="w-3 h-3" />
                        <%= doctor.city %>
                      </div>
                    <% end %>

                    <%= if doctor.consultation_fee do %>
                      <span class="badge badge-primary badge-sm">€<%= trunc(doctor.consultation_fee) %></span>
                    <% end %>
                  </div>
                </div>
              </.link>
            <% end %>
          </div>

          <%!-- Empty State --%>
          <%= if @doctors == [] && !@searching do %>
            <div class="text-center py-16">
              <.icon name="hero-magnifying-glass" class="w-16 h-16 mx-auto text-base-content/20 mb-4" />
              <h3 class="text-lg font-semibold mb-2">No doctors found</h3>
              <p class="text-base-content/70 mb-4">
                Try adjusting your filters or search terms
              </p>
              <button phx-click="clear_filters" class="btn btn-primary btn-sm">
                Clear all filters
              </button>
            </div>
          <% end %>

          <%!-- Load More --%>
          <%= if @has_more do %>
            <div class="text-center mt-8">
              <button phx-click="load_more" class="btn btn-outline btn-primary">
                <.icon name="hero-arrow-down" class="w-4 h-4" />
                Load more results
              </button>
            </div>
          <% end %>
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
    {:ok, socket}
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
    organ_matches = if String.length(query) >= 3 do
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
      |> assign(online_booking_only: !socket.assigns.online_booking_only, page: 1, searching: true)
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

    opts = if assigns.selected_city, do: Keyword.put(opts, :city, assigns.selected_city), else: opts

    doctors =
      Doctors.list_doctors(opts)
      |> Enum.map(fn d ->
        %{
          id: d.id,
          first_name: d.first_name,
          last_name: d.last_name,
          specialty_name: d.specialty && d.specialty.name_en,
          city: d.city,
          rating: d.rating || 0.0,
          review_count: d.review_count || 0,
          consultation_fee: d.consultation_fee && Decimal.to_float(d.consultation_fee),
          verified: d.verified_at != nil,
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
  defp maybe_filter_price(doctors, max), do: Enum.filter(doctors, &(&1.consultation_fee && &1.consultation_fee <= max))

  defp maybe_filter_online(doctors, false), do: doctors
  defp maybe_filter_online(doctors, true), do: Enum.filter(doctors, &(&1.has_cal_com))

  defp sort_doctors(doctors, "rating"), do: Enum.sort_by(doctors, &(&1.rating || 0), :desc)
  defp sort_doctors(doctors, "reviews"), do: Enum.sort_by(doctors, &(&1.review_count || 0), :desc)
  defp sort_doctors(doctors, "price_low"), do: Enum.sort_by(doctors, &(&1.consultation_fee || 999))
  defp sort_doctors(doctors, "price_high"), do: Enum.sort_by(doctors, &(&1.consultation_fee || 0), :desc)
  defp sort_doctors(doctors, _), do: doctors

  defp push_url_params(socket) do
    params = %{}
    assigns = socket.assigns

    params = if assigns.query != "", do: Map.put(params, "q", assigns.query), else: params
    params = if assigns.selected_specialty, do: Map.put(params, "specialty", assigns.selected_specialty), else: params
    params = if assigns.selected_city, do: Map.put(params, "city", assigns.selected_city), else: params
    params = if assigns.min_rating, do: Map.put(params, "rating", assigns.min_rating), else: params
    params = if assigns.max_price, do: Map.put(params, "max_price", assigns.max_price), else: params
    params = if assigns.online_booking_only, do: Map.put(params, "online", "true"), else: params
    params = if assigns.sort_by != "rating", do: Map.put(params, "sort", assigns.sort_by), else: params

    push_patch(socket, to: ~p"/search?#{params}", replace: true)
  end

  defp get_cities do
    ["Athens", "Thessaloniki", "Patras", "Heraklion", "Larissa", "Volos", "Ioannina", "Chania", "Rhodes", "Alexandroupoli", "Kalamata", "Kavala", "Serres", "Corfu"]
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
    |> Enum.count(&(&1))
  end

  defp get_specialty_name(specialties, slug) do
    case Enum.find(specialties, &(&1.slug == slug)) do
      nil -> slug
      s -> s.name_en
    end
  end
end
