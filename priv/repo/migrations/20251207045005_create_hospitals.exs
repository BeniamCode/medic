defmodule Medic.Repo.Migrations.CreateHospitals do
  use Ecto.Migration

  def change do
    create table(:hospitals) do
      add :name, :string
      add :city, :string
      add :phone, :string
      add :address, :string
      add :location_lat, :float
      add :location_lng, :float

      timestamps(type: :utc_datetime)
    end
  end
end
