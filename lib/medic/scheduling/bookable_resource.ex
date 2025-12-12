defmodule Medic.Scheduling.BookableResource do
  @moduledoc """
  Represents a concrete capacity unit (room, telehealth slot, equipment, etc.)
  that appointments can claim to enforce parallel session limits.
  """
  use Ash.Resource,
    domain: Medic.Scheduling,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "bookable_resources"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :doctor_id,
        :doctor_location_id,
        :location_room_id,
        :resource_type,
        :label,
        :capacity,
        :is_active
      ]
    end

    update :update do
      accept [:doctor_location_id, :location_room_id, :label, :capacity, :is_active]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :resource_type, :string, allow_nil?: false
    attribute :label, :string
    attribute :capacity, :integer, default: 1, allow_nil?: false
    attribute :is_active, :boolean, default: true, allow_nil?: false

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor
    belongs_to :doctor_location, Medic.Doctors.Location
    belongs_to :location_room, Medic.Doctors.LocationRoom
  end

  @resource_types ~w(room telehealth_slot equipment staff)

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [
      :doctor_id,
      :doctor_location_id,
      :location_room_id,
      :resource_type,
      :label,
      :capacity,
      :is_active
    ])
    |> validate_required([:doctor_id, :resource_type])
    |> validate_inclusion(:resource_type, @resource_types)
    |> validate_number(:capacity, greater_than: 0, less_than_or_equal_to: 25)
    |> foreign_key_constraint(:doctor_id)
    |> foreign_key_constraint(:doctor_location_id)
    |> foreign_key_constraint(:location_room_id)
  end
end
