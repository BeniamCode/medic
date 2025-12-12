defmodule Medic.Scheduling.ScheduleException do
  @moduledoc """
  Manual overrides that block or open availability on top of schedule rules
  (e.g., vacations, special clinics, pop-up availability).
  """
  use Ash.Resource,
    domain: Medic.Scheduling,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "schedule_exceptions"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :doctor_id,
        :schedule_rule_id,
        :appointment_type_id,
        :doctor_location_id,
        :location_room_id,
        :starts_at,
        :ends_at,
        :exception_type,
        :reason,
        :source
      ]
    end

    update :update do
      accept [
        :schedule_rule_id,
        :appointment_type_id,
        :doctor_location_id,
        :location_room_id,
        :starts_at,
        :ends_at,
        :exception_type,
        :reason,
        :source
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :starts_at, :utc_datetime, allow_nil?: false
    attribute :ends_at, :utc_datetime, allow_nil?: false
    attribute :exception_type, :string, allow_nil?: false, default: "blocked"
    attribute :reason, :string
    attribute :source, :string, allow_nil?: false, default: "manual"

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor
    belongs_to :schedule_rule, Medic.Scheduling.ScheduleRule
    belongs_to :appointment_type, Medic.Appointments.AppointmentType
    belongs_to :doctor_location, Medic.Doctors.Location
    belongs_to :location_room, Medic.Doctors.LocationRoom
  end

  @exception_types ~w(blocked available)

  @doc false
  def changeset(exception, attrs) do
    exception
    |> cast(attrs, [
      :doctor_id,
      :schedule_rule_id,
      :appointment_type_id,
      :doctor_location_id,
      :location_room_id,
      :starts_at,
      :ends_at,
      :exception_type,
      :reason,
      :source
    ])
    |> validate_required([:doctor_id, :starts_at, :ends_at])
    |> validate_inclusion(:exception_type, @exception_types)
    |> validate_time_order()
    |> foreign_key_constraint(:doctor_id)
    |> foreign_key_constraint(:schedule_rule_id)
    |> foreign_key_constraint(:appointment_type_id)
    |> foreign_key_constraint(:doctor_location_id)
    |> foreign_key_constraint(:location_room_id)
  end

  defp validate_time_order(changeset) do
    starts_at = get_field(changeset, :starts_at)
    ends_at = get_field(changeset, :ends_at)

    if starts_at && ends_at && DateTime.compare(starts_at, ends_at) != :lt do
      add_error(changeset, :ends_at, "must be after starts_at")
    else
      changeset
    end
  end
end
