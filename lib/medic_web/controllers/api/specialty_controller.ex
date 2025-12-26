defmodule MedicWeb.API.SpecialtyController do
  @moduledoc """
  Specialty API controller for mobile app.
  Provides list of medical specialties.
  """
  use MedicWeb, :controller

  alias Medic.Doctors

  action_fallback MedicWeb.API.FallbackController

  @doc """
  GET /api/specialties
  Lists all medical specialties.
  """
  def index(conn, _params) do
    specialties = Doctors.list_specialties()
    
    conn
    |> put_status(:ok)
    |> json(%{
      data: Enum.map(specialties, &specialty_to_json/1)
    })
  end

  # --- Private Helpers ---

  defp specialty_to_json(specialty) do
    %{
      id: specialty.id,
      name: specialty.name_en,
      name_el: specialty.name_el,
      slug: specialty.slug,
      icon: specialty.icon
    }
  end
end
