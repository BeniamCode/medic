defmodule MedicWeb.SearchLive do
  @moduledoc """
  Doctor search LiveView with instant search.
  """
  use MedicWeb, :live_view

  alias Medic.Doctors
  alias Medic.Search
  alias Medic.MedicalTaxonomy

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto py-8 px-4">
      <div class="mb-8">
        <h1 class="text-2xl font-bold mb-4">Find a Doctor</h1>

        <%!-- Search Form --%>
        <div class="flex flex-col md:flex-row gap-4 mb-6">
          <div class="flex-1 relative">
            <.icon name="hero-magnifying-glass" class="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-base-content/50" />
            <input
              type="text"
              id="search-input"
              value={@query}
              placeholder="Search by doctor name, specialty, or body part..."
              phx-keyup="search"
              phx-debounce="200"
              class="input input-bordered w-full pl-12"
              autofocus
            />
          </div>
          <select
            class="select select-bordered w-full md:w-64"
            phx-change="filter_specialty"
          >
            <option value="">All Specialties</option>
            <%= for specialty <- @specialties do %>
              <option value={specialty.slug} selected={@selected_specialty == specialty.slug}>
                <%= specialty.name_en %>
              </option>
            <% end %>
          </select>
          <select
            class="select select-bordered w-full md:w-48"
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
                  class="badge badge-primary badge-outline cursor-pointer hover:badge-primary"
                >
                  <%= specialty.name %>
                </button>
              <% end %>
            </div>
          </div>
        <% end %>

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
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <%= for doctor <- @doctors do %>
            <.link navigate={~p"/doctors/#{doctor.id}"} class="card bg-base-100 shadow-lg hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
              <div class="card-body">
                <div class="flex items-center gap-4">
                  <div class="avatar placeholder">
                    <div class="w-16 h-16 rounded-full bg-primary/10 text-primary">
                      <span class="text-xl"><.icon name="hero-user" class="w-8 h-8" /></span>
                    </div>
                  </div>
                  <div class="flex-1">
                    <h3 class="font-bold">Dr. <%= doctor.first_name %> <%= doctor.last_name %></h3>
                    <p class="text-sm text-base-content/70">
                      <%= doctor.specialty_name || "General Practice" %>
                    </p>
                    <%= if doctor.verified do %>
                      <div class="badge badge-success badge-sm gap-1 mt-1">
                        <.icon name="hero-check-badge" class="w-3 h-3" />
                        Verified
                      </div>
                    <% end %>
                  </div>
                </div>

                <div class="flex items-center justify-between mt-4">
                  <div class="flex items-center gap-1">
                    <.icon name="hero-star" class="w-4 h-4 text-warning" />
                    <span class="font-medium"><%= Float.round(doctor.rating || 0.0, 1) %></span>
                    <span class="text-xs text-base-content/70">(<%= doctor.review_count || 0 %>)</span>
                  </div>

                  <%= if doctor.city do %>
                    <div class="flex items-center gap-1 text-sm text-base-content/70">
                      <.icon name="hero-map-pin" class="w-4 h-4" />
                      <%= doctor.city %>
                    </div>
                  <% end %>
                </div>

                <%= if doctor.consultation_fee do %>
                  <div class="mt-2">
                    <span class="badge badge-primary">€<%= doctor.consultation_fee %></span>
                    <%= if doctor.has_cal_com do %>
                      <span class="badge badge-ghost badge-sm ml-2">
                        <.icon name="hero-calendar" class="w-3 h-3 mr-1" />
                        Online booking
                      </span>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </.link>
          <% end %>
        </div>

        <%!-- Empty State --%>
        <%= if @doctors == [] && !@searching do %>
          <div class="text-center py-16">
            <.icon name="hero-magnifying-glass" class="w-20 h-20 mx-auto text-base-content/20 mb-4" />
            <h3 class="text-lg font-semibold mb-2">No doctors found</h3>
            <p class="text-base-content/70 mb-4">
              Try changing your search criteria
            </p>
            <button phx-click="clear_filters" class="btn btn-outline">
              Clear filters
            </button>
          </div>
        <% end %>

        <%!-- Load More --%>
        <%= if @has_more do %>
          <div class="text-center mt-8">
            <button phx-click="load_more" class="btn btn-outline btn-primary">
              Load more results
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    specialties = Doctors.list_specialties()
    cities = get_cities()
    selected_specialty = params["specialty"]
    query = params["q"] || ""

    socket =
      socket
      |> assign(
        page_title: "Find a Doctor",
        specialties: specialties,
        cities: cities,
        selected_specialty: selected_specialty,
        selected_city: nil,
        query: query,
        doctors: [],
        total: 0,
        page: 1,
        has_more: false,
        searching: false,
        organ_matches: [],
        use_typesense: typesense_available?()
      )

    # Perform initial search
    socket = if connected?(socket), do: perform_search(socket), else: socket

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    # Check for organ matches
    organ_matches = if String.length(query) >= 3 do
      MedicalTaxonomy.search_specialties_by_organ(query)
      |> Enum.take(5)
    else
      []
    end

    socket =
      socket
      |> assign(query: query, page: 1, searching: true, organ_matches: organ_matches)
      |> perform_search()

    {:noreply, socket}
  end

  def handle_event("filter_specialty", %{"value" => specialty}, socket) do
    specialty = if specialty == "", do: nil, else: specialty

    socket =
      socket
      |> assign(selected_specialty: specialty, page: 1, searching: true, organ_matches: [])
      |> perform_search()

    {:noreply, socket}
  end

  def handle_event("filter_city", %{"value" => city}, socket) do
    city = if city == "", do: nil, else: city

    socket =
      socket
      |> assign(selected_city: city, page: 1, searching: true)
      |> perform_search()

    {:noreply, socket}
  end

  def handle_event("clear_filters", _, socket) do
    socket =
      socket
      |> assign(query: "", selected_specialty: nil, selected_city: nil, page: 1, organ_matches: [])
      |> perform_search()

    {:noreply, socket}
  end

  def handle_event("load_more", _, socket) do
    socket =
      socket
      |> assign(page: socket.assigns.page + 1)
      |> perform_search(append: true)

    {:noreply, socket}
  end

  defp perform_search(socket, opts \\ []) do
    append = Keyword.get(opts, :append, false)

    if socket.assigns.use_typesense do
      search_with_typesense(socket, append)
    else
      search_with_ecto(socket, append)
    end
  end

  defp search_with_typesense(socket, append) do
    %{query: query, selected_specialty: specialty, selected_city: city, page: page} = socket.assigns

    search_opts = [
      query: if(query == "", do: "*", else: query),
      specialty: specialty,
      city: city,
      page: page,
      per_page: 12,
      verified_only: true
    ]

    case Search.search_doctors(search_opts) do
      {:ok, %{results: results, total: total}} ->
        doctors = if append, do: socket.assigns.doctors ++ results, else: results
        has_more = length(doctors) < total

        assign(socket,
          doctors: doctors,
          total: total,
          has_more: has_more,
          searching: false
        )

      {:error, _reason} ->
        # Fallback to Ecto search on error
        search_with_ecto(socket, append)
    end
  end

  defp search_with_ecto(socket, append) do
    %{selected_specialty: specialty_slug, selected_city: city} = socket.assigns

    opts = [preload: [:specialty], verified: true]

    opts =
      if specialty_slug do
        specialty = Doctors.get_specialty_by_slug(specialty_slug)
        if specialty, do: Keyword.put(opts, :specialty_id, specialty.id), else: opts
      else
        opts
      end

    opts = if city, do: Keyword.put(opts, :city, city), else: opts

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
          has_cal_com: d.cal_com_username != nil
        }
      end)

    all_doctors = if append, do: socket.assigns.doctors ++ doctors, else: doctors

    assign(socket,
      doctors: all_doctors,
      total: length(all_doctors),
      has_more: false,
      searching: false
    )
  end

  defp get_cities do
    # Cities matching seed data (English names)
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
end
