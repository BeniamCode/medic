
# Cleanup script to revert doctor to valid coords
alias Medic.Doctors
alias Medic.Repo
import Ecto.Query
require Logger

name = "lico" 
doctor = 
  Medic.Doctors.Doctor
  |> where([d], ilike(d.first_name, ^"%#{name}%"))
  |> Repo.one()

if doctor do
  Logger.info("Reverting doctor #{doctor.first_name} to auto-geocoded location...")
  
  # Update WITHOUT manual coords to trigger geocode
  attrs = %{
    "address" => "Isminis 9", 
    "neighborhood" => "Kalamaria",
    "city" => "Thessaloniki",
    "zip_code" => "55135",
    "bio" => "Restored after pin drop test"
  }

  case Doctors.update_doctor(doctor, attrs) do
    {:ok, updated} ->
      Logger.info("Restoration SUCCESS. Coords: #{updated.location_lat}, #{updated.location_lng}")
    {:error, changeset} ->
      Logger.error("Restoration FAILED: #{inspect(changeset)}")
  end
end
