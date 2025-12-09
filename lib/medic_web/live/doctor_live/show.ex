defmodule MedicWeb.DoctorLive.Show do
  @moduledoc """
  Doctor profile view with industry-standard booking layout.
  Inspired by Zocdoc/Doctolib - stacked design with booking prominent.
  """
  use MedicWeb, :live_view

  alias Medic.Doctors
  alias MedicWeb.DoctorLive.BookingComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-b from-base-200 to-base-100">
      <%!-- Hero Section with Doctor Info --%>
      <div class="bg-base-100 border-b border-base-200 shadow-sm">
        <div class="max-w-4xl mx-auto py-8 px-4">
          <.link navigate={~p"/search"} class="btn btn-ghost btn-sm gap-1 mb-6">
            <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to search
          </.link>

          <div class="flex flex-col md:flex-row items-start gap-6">
            <%!-- Doctor Avatar --%>
            <div class="avatar placeholder">
              <div class="w-28 h-28 rounded-2xl bg-gradient-to-br from-primary/20 to-primary/5 text-primary ring-2 ring-primary/20">
                <span class="text-4xl"><.icon name="hero-user" class="w-14 h-14" /></span>
              </div>
            </div>

            <%!-- Doctor Info --%>
            <div class="flex-1">
              <div class="flex items-start justify-between gap-4 flex-wrap">
                <div>
                  <h1 class="text-3xl font-bold tracking-tight">
                    Dr. <%= @doctor.first_name %> <%= @doctor.last_name %>
                  </h1>
                  <p class="text-lg text-primary font-medium mt-1">
                    <%= (@doctor.specialty && @doctor.specialty.name_en) || "General Practice" %>
                  </p>
                </div>

                <%= if @doctor.consultation_fee do %>
                  <div class="text-right bg-primary/5 rounded-xl px-4 py-3">
                    <p class="text-xs text-base-content/60 uppercase tracking-wide">Consultation</p>
                    <p class="text-2xl font-bold text-primary">€<%= @doctor.consultation_fee %></p>
                  </div>
                <% end %>
              </div>

              <%!-- Stats Row --%>
              <div class="flex flex-wrap items-center gap-4 mt-4">
                <div class="flex items-center gap-1.5 bg-warning/10 rounded-full px-3 py-1.5">
                  <.icon name="hero-star-solid" class="w-5 h-5 text-warning" />
                  <span class="font-semibold"><%= Float.round(@doctor.rating || 0.0, 1) %></span>
                  <span class="text-base-content/60">(<%= @doctor.review_count || 0 %> reviews)</span>
                </div>

                <%= if @doctor.verified_at do %>
                  <div class="badge badge-success gap-1 py-3">
                    <.icon name="hero-check-badge" class="w-4 h-4" /> Verified Professional
                  </div>
                <% end %>

                <%= if @doctor.city do %>
                  <div class="flex items-center gap-1.5 text-base-content/70">
                    <.icon name="hero-map-pin" class="w-4 h-4" />
                    <span><%= @doctor.city %></span>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- Main Content --%>
      <div class="max-w-4xl mx-auto py-8 px-4">
        <%!-- Booking Section - Prominent & Centered --%>
        <div class="card bg-base-100 shadow-xl border border-base-200 mb-8">
          <div class="card-body">
            <div class="flex items-center gap-3 mb-6">
              <div class="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                <.icon name="hero-calendar-days" class="w-5 h-5 text-primary" />
              </div>
              <div>
                <h2 class="text-xl font-bold">Book an Appointment</h2>
                <p class="text-sm text-base-content/60">Select a date and time that works for you</p>
              </div>
            </div>

            <.live_component
              module={BookingComponent}
              id="booking"
              doctor={@doctor}
              current_user={@current_user}
            />
          </div>
        </div>

        <%!-- About Section --%>
        <%= if @doctor.bio do %>
          <div class="card bg-base-100 shadow-lg border border-base-200 mb-8">
            <div class="card-body">
              <div class="flex items-center gap-3 mb-4">
                <div class="w-10 h-10 rounded-full bg-secondary/10 flex items-center justify-center">
                  <.icon name="hero-user-circle" class="w-5 h-5 text-secondary" />
                </div>
                <h2 class="text-xl font-bold">About the Doctor</h2>
              </div>
              <p class="text-base-content/80 leading-relaxed whitespace-pre-line">
                <%= @doctor.bio %>
              </p>
            </div>
          </div>
        <% end %>

        <%!-- Location Section --%>
        <%= if @doctor.address || @doctor.city do %>
          <div class="card bg-base-100 shadow-lg border border-base-200">
            <div class="card-body">
              <div class="flex items-center gap-3 mb-4">
                <div class="w-10 h-10 rounded-full bg-accent/10 flex items-center justify-center">
                  <.icon name="hero-map-pin" class="w-5 h-5 text-accent" />
                </div>
                <h2 class="text-xl font-bold">Location</h2>
              </div>
              <div class="flex items-start gap-3">
                <div class="bg-base-200 rounded-xl p-4 flex-1">
                  <p class="font-medium"><%= @doctor.address %></p>
                  <%= if @doctor.city do %>
                    <p class="text-base-content/70"><%= @doctor.city %>, Greece</p>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        <% end %>
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
