defmodule Medic.Geocoding do
  @moduledoc """
  Handles geocoding addresses using the Mapbox Geocoding API.
  """
  require Logger

  @mapbox_api_url "https://api.mapbox.com/search/geocode/v6/forward"
  # Default public token from frontend if not configured - ideally should be secret
  @default_token "pk.eyJ1IjoibWVkaWNnciIsImEiOiJjbWl6bnpubDcwMTk2M2VzaWZlNDlkeDh1In0.DFR6nJ1SOlC2HE5jSKaAHg"

  def geocode_address(address, city, zip_code \\ nil, neighborhood \\ nil) do
    # Format: "Address, Neighborhood, Zip, City, Greece"
    query_parts = [address, neighborhood, zip_code, city, "Greece"] 
                  |> Enum.reject(&is_nil/1) 
                  |> Enum.reject(&(&1 == ""))
    
    query = Enum.join(query_parts, ", ")
    
    token = Application.get_env(:medic, :mapbox_token, @default_token)
    
    # v6 uses 'q' parameter
    params = [q: query, access_token: token, limit: 1]

    case Req.get(@mapbox_api_url, params: params) do
      {:ok, %{status: 200, body: %{"features" => [feature | _]}}} ->
        # v6 GeoJSON: geometry.coordinates is [lng, lat]
        %{"geometry" => %{"coordinates" => [lng, lat]}} = feature
        {:ok, {lat, lng}}

      {:ok, %{status: 200, body: %{"features" => []}}} ->
        Logger.warning("Geocoding failed: No results for #{query}")
        {:error, :not_found}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Geocoding error: #{status} - #{inspect(body)}")
        {:error, :api_error}

      {:error, reason} ->
        Logger.error("Geocoding request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
