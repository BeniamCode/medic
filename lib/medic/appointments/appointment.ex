defmodule Medic.Appointments.Appointment do
  @moduledoc """
  Appointment schema with Cal.com integration and telemedicine support.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(pending confirmed completed cancelled no_show)
  @appointment_types ~w(in_person telemedicine)

  schema "appointments" do
    belongs_to :patient, Medic.Patients.Patient
    belongs_to :doctor, Medic.Doctors.Doctor

    field :scheduled_at, :utc_datetime
    field :duration_minutes, :integer, default: 30
    field :status, :string, default: "pending"

    # Cal.com integration
    field :cal_com_booking_id, :string
    field :cal_com_uid, :string

    # Telemedicine support
    field :meeting_url, :string
    field :appointment_type, :string, default: "in_person"

    field :notes, :string
    field :cancellation_reason, :string
    field :cancelled_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [
      :scheduled_at, :duration_minutes, :appointment_type,
      :notes, :doctor_id, :patient_id
    ])
    |> validate_required([:scheduled_at, :duration_minutes, :doctor_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:appointment_type, @appointment_types)
    |> validate_number(:duration_minutes, greater_than: 0, less_than_or_equal_to: 240)
    |> validate_future_date()
    |> foreign_key_constraint(:patient_id)
    |> foreign_key_constraint(:doctor_id)
  end

  @doc """
  Changeset for Cal.com integration (sets booking IDs after sync).
  """
  def cal_com_changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [:cal_com_booking_id, :cal_com_uid, :meeting_url])
    |> unique_constraint(:cal_com_uid)
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
  Use only in seeds for creating historical test data.
  """
  def seed_changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [
      :scheduled_at, :duration_minutes, :status, :appointment_type,
      :notes, :doctor_id, :patient_id
    ])
    |> validate_required([:scheduled_at, :duration_minutes, :doctor_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:appointment_type, @appointment_types)
    |> validate_number(:duration_minutes, greater_than: 0, less_than_or_equal_to: 240)
    |> foreign_key_constraint(:patient_id)
    |> foreign_key_constraint(:doctor_id)
  end

  defp validate_future_date(changeset) do
    case get_change(changeset, :scheduled_at) do
      nil ->
        changeset

      scheduled_at ->
        if DateTime.compare(scheduled_at, DateTime.utc_now()) == :gt do
          changeset
        else
          add_error(changeset, :scheduled_at, "must be in the future")
        end
    end
  end

  @doc """
  Returns the end time of the appointment.
  """
  def ends_at(%__MODULE__{scheduled_at: start, duration_minutes: duration}) when not is_nil(start) do
    DateTime.add(start, duration * 60, :second)
  end

  def ends_at(_), do: nil

  @doc """
  Checks if the appointment is upcoming.
  """
  def upcoming?(%__MODULE__{scheduled_at: scheduled_at, status: status})
      when status in ["pending", "confirmed"] do
    DateTime.compare(scheduled_at, DateTime.utc_now()) == :gt
  end

  def upcoming?(_), do: false

  @doc """
  Checks if the appointment is a telemedicine appointment.
  """
  def telemedicine?(%__MODULE__{appointment_type: "telemedicine"}), do: true
  def telemedicine?(_), do: false
end
