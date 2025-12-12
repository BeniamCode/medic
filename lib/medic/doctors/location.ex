defmodule Medic.Doctors.Location do
  @moduledoc """
  Clinic or office location for a doctor.
  """
  use Ash.Resource,
    domain: Medic.Doctors,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "doctor_locations"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :doctor_id,
        :name,
        :address,
        :city,
        :country,
        :timezone,
        :phone,
        :location_lat,
        :location_lng,
        :is_primary
      ]
    end

    update :update do
      accept [
        :name,
        :address,
        :city,
        :country,
        :timezone,
        :phone,
        :location_lat,
        :location_lng,
        :is_primary
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :address, :string
    attribute :city, :string
    attribute :country, :string
    attribute :timezone, :string, allow_nil?: false, default: "Europe/Athens"
    attribute :phone, :string
    attribute :location_lat, :float
    attribute :location_lng, :float
    attribute :is_primary, :boolean, allow_nil?: false, default: false

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor

    has_many :rooms, Medic.Doctors.LocationRoom do
      destination_attribute :doctor_location_id
    end

    has_many :appointment_types, Medic.Appointments.AppointmentType do
      destination_attribute :default_location_id
    end
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [
      :doctor_id,
      :name,
      :address,
      :city,
      :country,
      :timezone,
      :phone,
      :location_lat,
      :location_lng,
      :is_primary
    ])
    |> validate_required([:doctor_id, :name, :timezone])
    |> validate_inclusion(:timezone, Tzdata.zone_list())
    |> unique_constraint(:doctor_id,
      name: :doctor_locations_one_primary_per_doctor,
      where: "is_primary",
      message: "primary location already set"
    )
    |> foreign_key_constraint(:doctor_id)
  end
end
