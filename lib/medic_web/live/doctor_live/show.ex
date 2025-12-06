defmodule MedicWeb.DoctorLive.Show do
  @moduledoc """
  Doctor profile view for patients with native booking.
  """
  use MedicWeb, :live_view

  alias Medic.Doctors
  alias MedicWeb.DoctorLive.BookingComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto py-8 px-4">
      <.link navigate={~p"/search"} class="btn btn-ghost btn-sm mb-4">
        <.icon name="hero-arrow-left" class="w-4 h-4" />
        Back to search
      </.link>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <%!-- Doctor Info Card --%>
        <div class="lg:col-span-2">
          <div class="card bg-base-100 shadow-lg">
            <div class="card-body">
              <%!-- Header --%>
              <div class="flex items-start gap-6">
                <div class="avatar placeholder">
                  <div class="w-24 h-24 rounded-full bg-primary/10 text-primary">
                    <span class="text-3xl"><.icon name="hero-user" class="w-12 h-12" /></span>
                  </div>
                </div>
                <div class="flex-1">
                  <h1 class="text-2xl font-bold">Dr. <%= @doctor.first_name %> <%= @doctor.last_name %></h1>
                  <p class="text-lg text-base-content/70">
                    <%= @doctor.specialty && @doctor.specialty.name_en || "General Practice" %>
                  </p>

                  <div class="flex items-center gap-4 mt-4">
                    <div class="flex items-center gap-1">
                      <.icon name="hero-star" class="w-5 h-5 text-warning" />
                      <span class="font-medium"><%= Float.round(@doctor.rating || 0.0, 1) %></span>
                      <span class="text-base-content/70">(<%= @doctor.review_count || 0 %> reviews)</span>
                    </div>
                    <%= if @doctor.verified_at do %>
                      <div class="badge badge-success gap-1">
                        <.icon name="hero-check-badge" class="w-4 h-4" />
                        Verified
                      </div>
                    <% end %>
                  </div>
                </div>

                <%= if @doctor.consultation_fee do %>
                  <div class="text-right">
                    <p class="text-sm text-base-content/70">Consultation fee</p>
                    <p class="text-2xl font-bold text-primary">€<%= @doctor.consultation_fee %></p>
                  </div>
                <% end %>
              </div>

              <div class="divider"></div>

              <%!-- Bio --%>
              <%= if @doctor.bio do %>
                <div class="prose max-w-none">
                  <h3>About</h3>
                  <p><%= @doctor.bio %></p>
                </div>
              <% end %>

              <%!-- Location --%>
              <%= if @doctor.address || @doctor.city do %>
                <div class="mt-6">
                  <h3 class="font-semibold mb-2">
                    <.icon name="hero-map-pin" class="w-5 h-5 inline text-primary" />
                    Location
                  </h3>
                  <p class="text-base-content/70">
                    <%= @doctor.address %>
                    <%= if @doctor.address && @doctor.city do %>, <% end %>
                    <%= @doctor.city %>
                  </p>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <%!-- Booking Card --%>
        <div class="lg:col-span-1">
          <div class="card bg-base-100 shadow-lg sticky top-4">
            <div class="card-body">
              <h3 class="font-semibold mb-4">
                <.icon name="hero-calendar" class="w-5 h-5 inline text-primary" />
                Book Appointment
              </h3>

              <.live_component
                module={BookingComponent}
                id="booking"
                doctor={@doctor}
                current_user={@current_user}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    doctor = Doctors.get_doctor_with_details!(id)

    {:ok,
     assign(socket,
       page_title: "Dr. #{doctor.first_name} #{doctor.last_name}",
       doctor: doctor
     )}
  end
end
