defmodule Medic.Hospitals.Hospital do
  use Ash.Resource,
    domain: Medic.Hospitals,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "hospitals"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:name, :city, :phone, :address, :location_lat, :location_lng]
    end

    update :update do
      accept [:name, :city, :phone, :address, :location_lat, :location_lng]
    end
  end

  attributes do
    integer_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :address, :string
    attribute :city, :string, allow_nil?: false
    attribute :phone, :string
    attribute :location_lat, :float
    attribute :location_lng, :float

    timestamps()
  end

  relationships do
    has_many :hospital_schedules, Medic.Hospitals.HospitalSchedule
  end

  # --- Legacy Logic ---
  @doc false
  def changeset(hospital, attrs) do
    hospital
    |> cast(attrs, [:name, :city, :phone, :address, :location_lat, :location_lng])
    |> validate_required([:name, :city])
  end
end
