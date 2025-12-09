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
      accept [:starts_at, :ends_at, :duration_minutes, :appointment_type, :status, :notes, :doctor_id, :patient_id]
    end

    update :update do
      accept [:starts_at, :ends_at, :duration_minutes, :appointment_type, :status, :notes]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :starts_at, :utc_datetime
    attribute :ends_at, :utc_datetime
    attribute :duration_minutes, :integer, default: 30
    attribute :status, :string, default: "pending"
    attribute :meeting_url, :string
    attribute :appointment_type, :string, default: "in_person"
    attribute :notes, :string
    attribute :cancellation_reason, :string
    attribute :cancelled_at, :utc_datetime

    timestamps()
  end

  relationships do
    belongs_to :patient, Medic.Patients.Patient
    belongs_to :doctor, Medic.Doctors.Doctor
  end

  # --- Legacy Logic ---

  @statuses ~w(pending confirmed completed cancelled no_show)
  @appointment_types ~w(in_person telemedicine)

  @doc false
  def changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [
      :starts_at,
      :ends_at,
      :duration_minutes,
      :appointment_type,
      :status,
      :notes,
      :doctor_id,
      :patient_id
    ])
    |> validate_required([:starts_at, :ends_at, :doctor_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:appointment_type, @appointment_types)
    |> validate_number(:duration_minutes, greater_than: 0, less_than_or_equal_to: 240)
    |> validate_time_order()
    |> validate_future_date()
    |> foreign_key_constraint(:patient_id)
    |> foreign_key_constraint(:doctor_id)
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
      :appointment_type,
      :notes,
      :doctor_id,
      :patient_id
    ])
    |> validate_required([:starts_at, :ends_at, :doctor_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:appointment_type, @appointment_types)
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
  def telemedicine?(%{appointment_type: "telemedicine"}), do: true
  def telemedicine?(_), do: false
end
