defmodule Medic.Doctors.LocationRoom do
  @moduledoc """
  Represents an exam room or virtual room inside a doctor location.
  """
  use Ash.Resource,
    domain: Medic.Doctors,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "location_rooms"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:doctor_location_id, :name, :capacity, :is_virtual]
    end

    update :update do
      accept [:name, :capacity, :is_virtual]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :capacity, :integer, allow_nil?: false, default: 1
    attribute :is_virtual, :boolean, allow_nil?: false, default: false

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :doctor_location, Medic.Doctors.Location

    has_many :schedule_templates, Medic.Scheduling.ScheduleTemplate do
      destination_attribute :location_room_id
    end

    has_many :appointments, Medic.Appointments.Appointment do
      destination_attribute :location_room_id
    end
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:doctor_location_id, :name, :capacity, :is_virtual])
    |> validate_required([:doctor_location_id, :name])
    |> validate_number(:capacity, greater_than: 0, less_than_or_equal_to: 10)
    |> unique_constraint(:name, name: :location_rooms_doctor_location_id_name_index)
    |> foreign_key_constraint(:doctor_location_id)
  end
end
