defmodule MedicWeb.SettingsLive do
  @moduledoc """
  User settings - stub for now.
  """
  use MedicWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto py-8 px-4">
      <h1 class="text-2xl font-bold mb-4">Ρυθμίσεις</h1>

      <div class="alert alert-info">
        <.icon name="hero-information-circle" class="w-6 h-6" />
        <span>Σύντομα διαθέσιμο</span>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Ρυθμίσεις")}
  end
end
