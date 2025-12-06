defmodule MedicWeb.AppointmentLive.Show do
  @moduledoc """
  Appointment details view - stub for now.
  """
  use MedicWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto py-8 px-4">
      <.link navigate={~p"/dashboard"} class="btn btn-ghost btn-sm mb-4">
        <.icon name="hero-arrow-left" class="w-4 h-4" />
        Πίσω στο Dashboard
      </.link>

      <h1 class="text-2xl font-bold mb-4">Λεπτομέρειες Ραντεβού</h1>

      <div class="alert alert-info">
        <.icon name="hero-information-circle" class="w-6 h-6" />
        <span>Σύντομα διαθέσιμο</span>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Ραντεβού")}
  end
end
