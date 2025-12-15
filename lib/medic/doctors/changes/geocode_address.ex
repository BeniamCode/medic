defmodule Medic.Doctors.Changes.GeocodeAddress do
  use Ash.Resource.Change

  alias Medic.Geocoding
  require Logger

  @impl true
  def change(changeset, _opts, _context) do
    # Get current values (from changeset or data)
    address = Ash.Changeset.get_attribute(changeset, :address) || 
             (changeset.data && Map.get(changeset.data, :address))
    
    city = Ash.Changeset.get_attribute(changeset, :city) || 
           (changeset.data && Map.get(changeset.data, :city)) || ""
    
    # Check if we should geocode
    should_geocode? = 
      (Ash.Changeset.changing_attribute?(changeset, :address) or 
       Ash.Changeset.changing_attribute?(changeset, :city)) or
       (address && address != "" && is_nil(changeset.data.location_lat))

    if should_geocode? and address && address != "" do
      case Geocoding.geocode_address(address, city) do
        {:ok, {lat, lng}} ->
          Logger.info("Geocoded #{address}, #{city} to #{lat}, #{lng}")
          changeset
          |> Ash.Changeset.force_change_attribute(:location_lat, lat)
          |> Ash.Changeset.force_change_attribute(:location_lng, lng)

        {:error, _} ->
          Logger.warning("Failed to geocode address: #{address}, #{city}")
          changeset
      end
    else
      changeset
    end
  end
end
