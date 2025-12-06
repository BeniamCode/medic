defmodule MedicWeb.DoctorLive.Schedule do
  @moduledoc """
  Doctor schedule management - stub for now.
  """
  use MedicWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8 px-4">
      <.link navigate={~p"/dashboard/doctor"} class="btn btn-ghost btn-sm mb-4">
        <.icon name="hero-arrow-left" class="w-4 h-4" />
        Πίσω στο Dashboard
      </.link>

      <h1 class="text-2xl font-bold mb-4">Διαχείριση Προγράμματος</h1>

      <div class="alert alert-info">
        <.icon name="hero-information-circle" class="w-6 h-6" />
        <div>
          <h3 class="font-bold">Σύντομα διαθέσιμο</h3>
          <p>Η διαχείριση του προγράμματος γίνεται μέσω του Cal.com. Συνδέστε τον λογαριασμό σας στις ρυθμίσεις προφίλ.</p>
        </div>
        <a href="https://app.cal.com/availability" target="_blank" class="btn btn-primary">
          Άνοιγμα Cal.com
          <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4" />
        </a>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Πρόγραμμα")}
  end
end
