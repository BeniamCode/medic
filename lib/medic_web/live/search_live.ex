defmodule MedicWeb.SearchLive do
  @moduledoc """
  Doctor search LiveView with instant search.
  Stub for now - will be fully implemented in Phase 3.
  """
  use MedicWeb, :live_view

  alias Medic.Doctors

  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto py-8 px-4">
      <div class="mb-8">
        <h1 class="text-2xl font-bold mb-4">Αναζήτηση Γιατρών</h1>

        <%!-- Search Form --%>
        <div class="flex gap-4 mb-6">
          <div class="flex-1 relative">
            <.icon name="hero-magnifying-glass" class="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-base-content/50" />
            <input
              type="text"
              name="q"
              value={@query}
              placeholder="Αναζήτηση γιατρού ή ειδικότητας..."
              phx-keyup="search"
              phx-debounce="300"
              class="input input-bordered w-full pl-12"
            />
          </div>
          <select class="select select-bordered" phx-change="filter_specialty">
            <option value="">Όλες οι ειδικότητες</option>
            <%= for specialty <- @specialties do %>
              <option value={specialty.slug} selected={@selected_specialty == specialty.slug}>
                {specialty.name_el}
              </option>
            <% end %>
          </select>
        </div>

        <%!-- Results --%>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <%= for doctor <- @doctors do %>
            <.link navigate={~p"/doctors/#{doctor.id}"} class="card bg-base-100 shadow-lg hover:shadow-xl transition-shadow">
              <div class="card-body">
                <div class="flex items-center gap-4">
                  <div class="avatar placeholder">
                    <div class="w-16 h-16 rounded-full bg-primary/10 text-primary">
                      <span class="text-xl"><.icon name="hero-user" class="w-8 h-8" /></span>
                    </div>
                  </div>
                  <div>
                    <h3 class="font-bold">Dr. {doctor.first_name} {doctor.last_name}</h3>
                    <p class="text-sm text-base-content/70">
                      {doctor.specialty && doctor.specialty.name_el || "Γενική Ιατρική"}
                    </p>
                  </div>
                </div>

                <div class="flex items-center gap-2 mt-4">
                  <div class="rating rating-sm">
                    <%= for _i <- 1..5 do %>
                      <input type="radio" class="mask mask-star-2 bg-warning" disabled />
                    <% end %>
                  </div>
                  <span class="text-sm text-base-content/70">({doctor.review_count} κριτικές)</span>
                </div>

                <%= if doctor.city do %>
                  <div class="flex items-center gap-2 text-sm text-base-content/70">
                    <.icon name="hero-map-pin" class="w-4 h-4" />
                    {doctor.city}
                  </div>
                <% end %>

                <%= if doctor.consultation_fee do %>
                  <div class="mt-2">
                    <span class="badge badge-primary badge-lg">€{doctor.consultation_fee}</span>
                  </div>
                <% end %>
              </div>
            </.link>
          <% end %>
        </div>

        <%= if @doctors == [] do %>
          <div class="text-center py-12">
            <.icon name="hero-magnifying-glass" class="w-16 h-16 mx-auto text-base-content/30 mb-4" />
            <p class="text-base-content/70">Δεν βρέθηκαν αποτελέσματα</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    specialties = Doctors.list_specialties()
    selected_specialty = params["specialty"]
    query = params["q"] || ""

    doctors = load_doctors(query, selected_specialty)

    {:ok,
     assign(socket,
       page_title: "Αναζήτηση Γιατρών",
       specialties: specialties,
       selected_specialty: selected_specialty,
       query: query,
       doctors: doctors
     )}
  end

  def handle_event("search", %{"value" => query}, socket) do
    doctors = load_doctors(query, socket.assigns.selected_specialty)
    {:noreply, assign(socket, query: query, doctors: doctors)}
  end

  def handle_event("filter_specialty", %{"value" => specialty}, socket) do
    specialty = if specialty == "", do: nil, else: specialty
    doctors = load_doctors(socket.assigns.query, specialty)
    {:noreply, assign(socket, selected_specialty: specialty, doctors: doctors)}
  end

  defp load_doctors(_query, specialty_slug) do
    # For now, just filter by specialty using Ecto
    # In Phase 3, this will use Typesense for full-text search
    opts = [preload: [:specialty], verified: true]

    opts =
      if specialty_slug do
        specialty = Doctors.get_specialty_by_slug(specialty_slug)
        if specialty, do: Keyword.put(opts, :specialty_id, specialty.id), else: opts
      else
        opts
      end

    Doctors.list_doctors(opts)
  end
end
