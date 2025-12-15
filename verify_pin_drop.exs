
# Script to verify manual pin drop precedence
alias Medic.Doctors
alias Medic.Repo
import Ecto.Query
require Logger

# Find 'lico' again
name = "lico" 
doctor = 
  Medic.Doctors.Doctor
  |> where([d], ilike(d.first_name, ^"%#{name}%"))
  |> Repo.one()

if doctor do
  Logger.info("found doctor: #{doctor.first_name} #{doctor.last_name}")
  
  # User's target address (Real coords ~40.56, 22.95)
  address = "Isminis 9"
  neighborhood = "Kalamaria"
  city = "Thessaloniki"
  zip_code = "55135"

  # Manual "Pin Drop" coords (Arbitrarily different)
  manual_lat = 40.000000
  manual_lng = 23.000000

  attrs = %{
    "address" => address, 
    "neighborhood" => neighborhood,
    "city" => city,
    "zip_code" => zip_code,
    "location_lat" => manual_lat,
    "location_lng" => manual_lng,
    "bio" => "Pin drop test #{System.os_time()}"
  }

  Logger.info("Updating doctor with Address AND Manual Coords (40.0, 23.0)...")
  
  case Doctors.update_doctor(doctor, attrs) do
    {:ok, updated} ->
      Logger.info("Update SUCCESS")
      Logger.info("Saved Coords: #{inspect(updated.location_lat)}, #{inspect(updated.location_lng)}")
      
      expected_lat = 40.0
      expected_lng = 23.0

      # Check if saved matches manual
      if updated.location_lat == expected_lat and updated.location_lng == expected_lng do
         Logger.info("✅ SUCCESS: Manual coordinates were saved! Geocoding was skipped.")
      else
         Logger.error("❌ FAILURE: Saved coordinates do not match manual input. Geocoding might have overridden them.")
      end

    {:error, changeset} ->
      Logger.error("Update FAILED: #{inspect(changeset)}")
  end
else
  Logger.error("Doctor 'lico' not found for verification.")
end
