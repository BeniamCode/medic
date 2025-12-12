defmodule Medic.Appointments.AppointmentType do
  @moduledoc """
  Defines patient-facing appointment offerings for each doctor.
  """
  use Ash.Resource,
    domain: Medic.Appointments,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "appointment_types"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :doctor_id,
        :slug,
        :name,
        :description,
        :duration_minutes,
        :buffer_before_minutes,
        :buffer_after_minutes,
        :price_cents,
        :currency,
        :consultation_mode,
        :default_location_id,
        :default_room_id,
        :is_active,
        :allow_patient_reschedule,
        :min_notice_minutes,
        :max_future_days,
        :max_reschedule_count,
        :notes
      ]
    end

    update :update do
      accept [
        :slug,
        :name,
        :description,
        :duration_minutes,
        :buffer_before_minutes,
        :buffer_after_minutes,
        :price_cents,
        :currency,
        :consultation_mode,
        :default_location_id,
        :default_room_id,
        :is_active,
        :allow_patient_reschedule,
        :min_notice_minutes,
        :max_future_days,
        :max_reschedule_count,
        :notes
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :slug, :string, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    attribute :description, :string
    attribute :duration_minutes, :integer, default: 30, allow_nil?: false
    attribute :buffer_before_minutes, :integer, default: 0, allow_nil?: false
    attribute :buffer_after_minutes, :integer, default: 0, allow_nil?: false
    attribute :price_cents, :integer
    attribute :currency, :string, default: "EUR", allow_nil?: false
    attribute :consultation_mode, :string, default: "in_person", allow_nil?: false
    attribute :is_active, :boolean, default: true, allow_nil?: false
    attribute :allow_patient_reschedule, :boolean, default: true, allow_nil?: false
    attribute :min_notice_minutes, :integer, default: 0, allow_nil?: false
    attribute :max_future_days, :integer, default: 60, allow_nil?: false
    attribute :max_reschedule_count, :integer, default: 2, allow_nil?: false
    attribute :notes, :string

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor
    belongs_to :default_location, Medic.Doctors.Location
    belongs_to :default_room, Medic.Doctors.LocationRoom
    has_many :appointment_type_locations, Medic.Appointments.AppointmentTypeLocation
    has_many :appointments, Medic.Appointments.Appointment
    has_many :schedule_templates, Medic.Scheduling.ScheduleTemplate
  end

  @consultation_modes ~w(in_person video phone)

  @doc false
  def changeset(type, attrs) do
    type
    |> cast(attrs, [
      :doctor_id,
      :slug,
      :name,
      :description,
      :duration_minutes,
      :buffer_before_minutes,
      :buffer_after_minutes,
      :price_cents,
      :currency,
      :consultation_mode,
      :default_location_id,
      :default_room_id,
      :is_active,
      :allow_patient_reschedule,
      :min_notice_minutes,
      :max_future_days,
      :max_reschedule_count,
      :notes
    ])
    |> validate_required([:doctor_id, :slug, :name])
    |> validate_format(:slug, ~r/^[a-z0-9\-]+$/)
    |> validate_length(:slug, max: 50)
    |> validate_number(:duration_minutes, greater_than: 0, less_than_or_equal_to: 360)
    |> validate_number(:buffer_before_minutes,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 120
    )
    |> validate_number(:buffer_after_minutes,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 120
    )
    |> validate_number(:min_notice_minutes, greater_than_or_equal_to: 0)
    |> validate_number(:max_future_days, greater_than: 0, less_than_or_equal_to: 365)
    |> validate_inclusion(:consultation_mode, @consultation_modes)
    |> unique_constraint([:doctor_id, :slug])
    |> foreign_key_constraint(:doctor_id)
    |> foreign_key_constraint(:default_location_id)
    |> foreign_key_constraint(:default_room_id)
  end
end
