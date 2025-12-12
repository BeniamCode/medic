defmodule Medic.Scheduling.ScheduleTemplate do
  @moduledoc """
  Weekly recurring availability template for a doctor.
  """
  use Ash.Resource,
    domain: Medic.Scheduling,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "schedule_templates"
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
        :appointment_type_id,
        :day_of_week,
        :slot_duration_minutes,
        :work_start,
        :work_end,
        :buffer_before_minutes,
        :buffer_after_minutes,
        :max_parallel_sessions,
        :priority
      ]
    end

    update :update do
      accept [
        :doctor_location_id,
        :location_room_id,
        :appointment_type_id,
        :day_of_week,
        :slot_duration_minutes,
        :work_start,
        :work_end,
        :buffer_before_minutes,
        :buffer_after_minutes,
        :max_parallel_sessions,
        :priority
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :day_of_week, :integer, allow_nil?: false
    attribute :slot_duration_minutes, :integer, default: 30, allow_nil?: false
    attribute :work_start, :time, allow_nil?: false
    attribute :work_end, :time, allow_nil?: false
    attribute :buffer_before_minutes, :integer, default: 0, allow_nil?: false
    attribute :buffer_after_minutes, :integer, default: 0, allow_nil?: false
    attribute :max_parallel_sessions, :integer, default: 1, allow_nil?: false
    attribute :priority, :integer, default: 0, allow_nil?: false

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor
    belongs_to :doctor_location, Medic.Doctors.Location
    belongs_to :location_room, Medic.Doctors.LocationRoom
    belongs_to :appointment_type, Medic.Appointments.AppointmentType
    has_many :breaks, Medic.Scheduling.ScheduleTemplateBreak
  end

  @doc false
  def changeset(template, attrs) do
    template
    |> cast(attrs, [
      :doctor_id,
      :doctor_location_id,
      :location_room_id,
      :appointment_type_id,
      :day_of_week,
      :slot_duration_minutes,
      :work_start,
      :work_end,
      :buffer_before_minutes,
      :buffer_after_minutes,
      :max_parallel_sessions,
      :priority
    ])
    |> validate_required([:doctor_id, :day_of_week, :work_start, :work_end])
    |> validate_number(:day_of_week, greater_than_or_equal_to: 1, less_than_or_equal_to: 7)
    |> validate_number(:slot_duration_minutes, greater_than: 0, less_than_or_equal_to: 480)
    |> validate_number(:max_parallel_sessions, greater_than: 0, less_than_or_equal_to: 10)
    |> validate_time_order(:work_start, :work_end)
    |> foreign_key_constraint(:doctor_id)
    |> foreign_key_constraint(:doctor_location_id)
    |> foreign_key_constraint(:location_room_id)
    |> foreign_key_constraint(:appointment_type_id)
  end

  defp validate_time_order(changeset, start_field, end_field) do
    start_time = get_field(changeset, start_field)
    end_time = get_field(changeset, end_field)

    if start_time && end_time && Time.compare(start_time, end_time) != :lt do
      add_error(changeset, end_field, "must be after start time")
    else
      changeset
    end
  end
end
