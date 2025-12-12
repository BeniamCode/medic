defmodule MedicWeb.Admin.DashboardLive do
  use MedicWeb, :live_view

  alias Medic.Doctors.Doctor

  require Ash.Query

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h1 class="text-3xl font-bold">Dashboard</h1>
      <!-- Stats Grid -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="stats shadow bg-base-100 border border-base-200">
          <div class="stat">
            <div class="stat-figure text-primary">
              <.icon name="hero-user-group" class="size-8" />
            </div>
            <div class="stat-title">Pending Doctors</div>
            <div class="stat-value text-primary"><%= @pending_doctors_count %></div>
            <div class="stat-desc">Waiting for verification</div>
          </div>
        </div>

        <div class="stat">
          <div class="stat-figure text-secondary">
            <.icon name="hero-calendar" class="size-8" />
          </div>
          <div class="stat-title">Todays Appointments</div>
          <div class="stat-value text-secondary"><%= @todays_appointments_count %></div>
          <div class="stat-desc">Across all doctors</div>
        </div>

        <div class="stat">
          <div class="stat-figure text-accent">
            <.icon name="hero-banknotes" class="size-8" />
          </div>
          <div class="stat-title">Est. Revenue (Today)</div>
          <div class="stat-value text-accent">€<%= @todays_revenue %></div>
          <div class="stat-desc">Based on fees</div>
        </div>
      </div>
      <!-- Quick Actions / Alert -->
      <%= if @pending_doctors_count > 0 do %>
        <div class="alert alert-warning shadow-sm">
          <.icon name="hero-exclamation-triangle" class="size-6" />
          <div>
            <h3 class="font-bold">Attention Needed</h3>
            <div class="text-xs">
              You have <%= @pending_doctors_count %> doctor application(s) pending review.
            </div>
          </div>
          <.link navigate={~p"/medic/doctors"} class="btn btn-sm btn-ghost">Review Now</.link>
        </div>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    # Fetch Counts
    # Ideally these are aggregated queries. For now we will list and count (not performant for huge data but fine for MVP)
    # Using Ash Queries would be better.

    # Pending Doctors: Verified_at is nil
    pending_doctors_query =
      Doctor
      |> Ash.Query.filter(is_nil(verified_at))

    pending_count =
      case Ash.read(pending_doctors_query) do
        {:ok, docs} -> length(docs)
        _ -> 0
      end

    # Todays Appointments
    today_start = DateTime.utc_now() |> DateTime.truncate(:second)
    _today_end = today_start |> DateTime.add(24 * 3600, :second)

    # We need a proper query for appointments logic, usually we'd have a specialized action
    # For now let's just use strict filtering if possible or generic read

    # We'll just define stats as placeholders until we implement the Aggregate Actions in Resources
    # Or raw query. 

    {:ok,
     assign(socket,
       pending_doctors_count: pending_count,
       # Placeholder
       todays_appointments_count: 12,
       # Placeholder
       todays_revenue: 450
     ), layout: {MedicWeb.Layouts, :admin}}
  end
end
