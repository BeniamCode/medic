defmodule Medic.Scheduling.ScheduleRule do
  @moduledoc """
  Canonical weekly rule describing when a doctor is available for booking.
  Rules can be scoped by appointment type, location, or room and run in the
  doctor’s timezone so split shifts and buffers are easy to manage.
  """
  use Ash.Resource,
    domain: Medic.Scheduling,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "schedule_rules"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :doctor_id,
        :timezone,
        :scope_appointment_type_id,
        :scope_doctor_location_id,
        :scope_location_room_id,
        :day_of_week,
        :work_start_local,
        :work_end_local,
        :slot_interval_minutes,
        :buffer_before_minutes,
        :buffer_after_minutes,
        :label,
        :priority
      ]
    end

    update :update do
      accept [
        :timezone,
        :scope_appointment_type_id,
        :scope_doctor_location_id,
        :scope_location_room_id,
        :day_of_week,
        :work_start_local,
        :work_end_local,
        :slot_interval_minutes,
        :buffer_before_minutes,
        :buffer_after_minutes,
        :label,
        :priority
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :timezone, :string, allow_nil?: false, default: "Europe/Athens"
    attribute :day_of_week, :integer, allow_nil?: false
    attribute :work_start_local, :time, allow_nil?: false
    attribute :work_end_local, :time, allow_nil?: false
    attribute :slot_interval_minutes, :integer, allow_nil?: false, default: 30
    attribute :buffer_before_minutes, :integer, allow_nil?: false, default: 0
    attribute :buffer_after_minutes, :integer, allow_nil?: false, default: 0
    attribute :label, :string
    attribute :priority, :integer, allow_nil?: false, default: 0

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor
    belongs_to :scope_appointment_type, Medic.Appointments.AppointmentType
    belongs_to :scope_doctor_location, Medic.Doctors.Location
    belongs_to :scope_location_room, Medic.Doctors.LocationRoom

    has_many :breaks, Medic.Scheduling.ScheduleRuleBreak
    has_many :exceptions, Medic.Scheduling.ScheduleException
  end

  @days 1..7

  @doc false
  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [
      :doctor_id,
      :timezone,
      :scope_appointment_type_id,
      :scope_doctor_location_id,
      :scope_location_room_id,
      :day_of_week,
      :work_start_local,
      :work_end_local,
      :slot_interval_minutes,
      :buffer_before_minutes,
      :buffer_after_minutes,
      :label,
      :priority
    ])
    |> validate_required([:doctor_id, :day_of_week, :work_start_local, :work_end_local])
    |> validate_number(:day_of_week, greater_than_or_equal_to: 1, less_than_or_equal_to: 7)
    |> validate_inclusion(:day_of_week, @days)
    |> validate_number(:slot_interval_minutes, greater_than: 0, less_than_or_equal_to: 480)
    |> validate_number(:buffer_before_minutes,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 240
    )
    |> validate_number(:buffer_after_minutes,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 240
    )
    |> validate_number(:priority, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_interval(:work_start_local, :work_end_local)
    |> foreign_key_constraint(:doctor_id)
    |> foreign_key_constraint(:scope_appointment_type_id)
    |> foreign_key_constraint(:scope_doctor_location_id)
    |> foreign_key_constraint(:scope_location_room_id)
  end

  defp validate_interval(changeset, start_field, end_field) do
    start_time = get_field(changeset, start_field)
    end_time = get_field(changeset, end_field)

    if start_time && end_time && Time.compare(start_time, end_time) != :lt do
      add_error(changeset, end_field, "must be after #{start_field}")
    else
      changeset
    end
  end
end
