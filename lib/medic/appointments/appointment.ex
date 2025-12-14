defmodule Medic.Appointments.Appointment do
  @moduledoc """
  Appointment schema with PostgreSQL exclusion constraint for double-booking prevention.
  """
  use Ash.Resource,
    domain: Medic.Appointments,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "appointments"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :starts_at,
        :ends_at,
        :duration_minutes,
        :consultation_mode_snapshot,
        :status,
        :notes,
        :doctor_id,
        :patient_id,
        :doctor_location_id,
        :location_room_id,
        :appointment_type_id,
        :price_cents,
        :currency,
        :source,
        :reschedule_count,
        :cancelled_by,
        :patient_timezone,
        :doctor_timezone,
        :service_name_snapshot,
        :service_duration_snapshot,
        :service_price_cents_snapshot,
        :service_currency_snapshot,
        :external_reference,
        :hold_expires_at,
        :pending_expires_at,
        :created_by_actor_type,
        :created_by_actor_id,
        :cancelled_by_actor_type,
        :cancelled_by_actor_id,
        :rescheduled_from_appointment_id,
        :approval_required_snapshot
      ]
    end

    update :update do
      accept [
        :starts_at,
        :ends_at,
        :duration_minutes,
        :consultation_mode_snapshot,
        :status,
        :notes,
        :doctor_location_id,
        :location_room_id,
        :appointment_type_id,
        :price_cents,
        :currency,
        :source,
        :reschedule_count,
        :cancelled_by,
        :patient_timezone,
        :doctor_timezone,
        :service_name_snapshot,
        :service_duration_snapshot,
        :service_price_cents_snapshot,
        :service_currency_snapshot,
        :external_reference,
        :hold_expires_at,
        :pending_expires_at,
        :cancelled_by_actor_type,
        :cancelled_by_actor_id,
        :rescheduled_from_appointment_id,
        :approval_required_snapshot
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :starts_at, :utc_datetime
    attribute :ends_at, :utc_datetime
    attribute :duration_minutes, :integer, default: 30
    attribute :status, :string, default: "pending"
    attribute :meeting_url, :string
    attribute :consultation_mode_snapshot, :string, default: "in_person"
    attribute :notes, :string
    attribute :cancellation_reason, :string
    attribute :cancelled_at, :utc_datetime
    attribute :price_cents, :integer
    attribute :currency, :string, default: "EUR"
    attribute :source, :string, default: "patient_portal"
    attribute :reschedule_count, :integer, default: 0
    attribute :cancelled_by, :string
    attribute :patient_timezone, :string
    attribute :doctor_timezone, :string
    attribute :service_name_snapshot, :string
    attribute :service_duration_snapshot, :integer
    attribute :service_price_cents_snapshot, :integer
    attribute :service_currency_snapshot, :string
    attribute :external_reference, :string
    attribute :hold_expires_at, :utc_datetime
    attribute :pending_expires_at, :utc_datetime
    attribute :created_by_actor_type, :string
    attribute :created_by_actor_id, :uuid
    attribute :cancelled_by_actor_type, :string
    attribute :cancelled_by_actor_id, :uuid
    attribute :rescheduled_from_appointment_id, :uuid
    attribute :approval_required_snapshot, :boolean, default: false

    timestamps()
  end

  relationships do
    belongs_to :patient, Medic.Patients.Patient
    belongs_to :doctor, Medic.Doctors.Doctor
    belongs_to :doctor_location, Medic.Doctors.Location
    belongs_to :location_room, Medic.Doctors.LocationRoom

    belongs_to :appointment_type_record, Medic.Appointments.AppointmentType,
      source_attribute: :appointment_type_id,
      destination_attribute: :id

    belongs_to :rescheduled_from, __MODULE__,
      source_attribute: :rescheduled_from_appointment_id,
      destination_attribute: :id

    has_many :events, Medic.Appointments.AppointmentEvent
    has_many :resource_claims, Medic.Appointments.AppointmentResourceClaim

    has_one :appreciation, Medic.Appreciate.DoctorAppreciation do
      destination_attribute :appointment_id
    end
  end

  # --- Legacy Logic ---

  @statuses ~w(pending confirmed completed cancelled no_show held)
  @consultation_modes ~w(in_person telemedicine)

  @doc false
  def changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [
      :starts_at,
      :ends_at,
      :duration_minutes,
      :consultation_mode_snapshot,
      :status,
      :notes,
      :doctor_id,
      :patient_id,
      :doctor_location_id,
      :location_room_id,
      :appointment_type_id,
      :price_cents,
      :currency,
      :source,
      :reschedule_count,
      :cancelled_by,
      :patient_timezone,
      :doctor_timezone,
      :service_name_snapshot,
      :service_duration_snapshot,
      :service_price_cents_snapshot,
      :service_currency_snapshot,
      :external_reference,
      :hold_expires_at,
      :created_by_actor_type,
      :created_by_actor_id,
      :cancelled_by_actor_type,
      :cancelled_by_actor_id
    ])
    |> validate_required([:starts_at, :ends_at, :doctor_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:consultation_mode_snapshot, @consultation_modes)
    |> validate_number(:duration_minutes, greater_than: 0, less_than_or_equal_to: 240)
    |> validate_number(:reschedule_count, greater_than_or_equal_to: 0)
    |> validate_number(:service_duration_snapshot, greater_than: 0)
    |> validate_time_order()
    |> validate_future_date()
    |> foreign_key_constraint(:patient_id)
    |> foreign_key_constraint(:doctor_id)
    |> foreign_key_constraint(:doctor_location_id)
    |> foreign_key_constraint(:location_room_id)
    |> foreign_key_constraint(:appointment_type_id)
    |> exclusion_constraint(:no_double_bookings,
      message: "This time slot is already booked"
    )
  end

  @doc """
  Changeset for confirming an appointment.
  """
  def confirm_changeset(appointment) do
    change(appointment, status: "confirmed")
  end

  @doc """
  Changeset for completing an appointment.
  """
  def complete_changeset(appointment) do
    change(appointment, status: "completed")
  end

  @doc """
  Changeset for cancelling an appointment.
  """
  def cancel_changeset(appointment, reason \\ nil) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    appointment
    |> change(status: "cancelled", cancelled_at: now)
    |> put_change(:cancellation_reason, reason)
  end

  @doc """
  Changeset for marking as no-show.
  """
  def no_show_changeset(appointment) do
    change(appointment, status: "no_show")
  end

  @doc """
  Changeset for seeding (bypasses future date validation).
  """
  def seed_changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [
      :starts_at,
      :ends_at,
      :duration_minutes,
      :status,
      :consultation_mode_snapshot,
      :notes,
      :doctor_id,
      :patient_id
    ])
    |> validate_required([:starts_at, :ends_at, :doctor_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:consultation_mode_snapshot, @consultation_modes)
    |> validate_number(:duration_minutes, greater_than: 0, less_than_or_equal_to: 240)
    |> validate_time_order()
    |> foreign_key_constraint(:patient_id)
    |> foreign_key_constraint(:doctor_id)
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

  defp validate_future_date(changeset) do
    case get_change(changeset, :starts_at) do
      nil ->
        changeset

      starts_at ->
        if DateTime.compare(starts_at, DateTime.utc_now()) == :gt do
          changeset
        else
          add_error(changeset, :starts_at, "must be in the future")
        end
    end
  end

  @doc """
  Returns the duration in minutes.
  """
  def duration(%{starts_at: starts_at, ends_at: ends_at})
      when not is_nil(starts_at) and not is_nil(ends_at) do
    DateTime.diff(ends_at, starts_at, :minute)
  end

  def duration(_), do: nil

  @doc """
  Checks if the appointment is upcoming.
  """
  def upcoming?(%{starts_at: starts_at, status: status})
      when status in ["pending", "confirmed"] do
    DateTime.compare(starts_at, DateTime.utc_now()) == :gt
  end

  def upcoming?(_), do: false

  @doc """
  Checks if the appointment is a telemedicine appointment.
  """
  def telemedicine?(%{consultation_mode_snapshot: "telemedicine"}), do: true
  def telemedicine?(_), do: false
end
