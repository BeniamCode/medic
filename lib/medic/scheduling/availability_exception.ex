defmodule Medic.Scheduling.AvailabilityException do
  @moduledoc """
  Stores manual overrides for availability, such as blocks or extra slots.
  """
  use Ash.Resource,
    domain: Medic.Scheduling,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "availability_exceptions"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :doctor_id,
        :appointment_type_id,
        :doctor_location_id,
        :starts_at,
        :ends_at,
        :status,
        :reason,
        :source
      ]
    end

    update :update do
      accept [
        :appointment_type_id,
        :doctor_location_id,
        :starts_at,
        :ends_at,
        :status,
        :reason,
        :source
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :starts_at, :utc_datetime, allow_nil?: false
    attribute :ends_at, :utc_datetime, allow_nil?: false
    attribute :status, :string, allow_nil?: false, default: "blocked"
    attribute :reason, :string
    attribute :source, :string, allow_nil?: false, default: "manual"

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor
    belongs_to :appointment_type, Medic.Appointments.AppointmentType
    belongs_to :doctor_location, Medic.Doctors.Location
  end

  @statuses ~w(blocked available)

  @doc false
  def changeset(exception, attrs) do
    exception
    |> cast(attrs, [
      :doctor_id,
      :appointment_type_id,
      :doctor_location_id,
      :starts_at,
      :ends_at,
      :status,
      :reason,
      :source
    ])
    |> validate_required([:doctor_id, :starts_at, :ends_at])
    |> validate_inclusion(:status, @statuses)
    |> validate_time_order()
    |> foreign_key_constraint(:doctor_id)
    |> foreign_key_constraint(:appointment_type_id)
    |> foreign_key_constraint(:doctor_location_id)
  end

  defp validate_time_order(changeset) do
    starts_at = get_field(changeset, :starts_at)
    ends_at = get_field(changeset, :ends_at)

    if starts_at && ends_at && DateTime.compare(starts_at, ends_at) != :lt do
      add_error(changeset, :ends_at, "must be after start time")
    else
      changeset
    end
  end
end
