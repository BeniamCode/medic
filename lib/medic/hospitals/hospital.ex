defmodule Medic.Hospitals.Hospital do
  use Ecto.Schema
  import Ecto.Changeset

  schema "hospitals" do
    field :name, :string
    field :address, :string
    field :city, :string
    field :phone, :string
    field :location_lat, :float
    field :location_lng, :float

    has_many :hospital_schedules, Medic.Hospitals.HospitalSchedule

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hospital, attrs) do
    hospital
    |> cast(attrs, [:name, :city, :phone, :address, :location_lat, :location_lng])
    |> validate_required([:name, :city])
  end
end
