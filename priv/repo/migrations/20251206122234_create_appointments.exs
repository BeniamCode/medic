defmodule Medic.Repo.Migrations.CreateAppointments do
  use Ecto.Migration

  def change do
    create table(:appointments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :patient_id, references(:patients, type: :binary_id, on_delete: :nilify_all)
      add :doctor_id, references(:doctors, type: :binary_id, on_delete: :nilify_all), null: false

      add :scheduled_at, :utc_datetime, null: false
      add :duration_minutes, :integer, null: false, default: 30
      add :status, :string, null: false, default: "pending"

      # Cal.com integration
      add :cal_com_booking_id, :string
      add :cal_com_uid, :string

      # Telemedicine support
      add :meeting_url, :string
      add :appointment_type, :string, default: "in_person"

      add :notes, :text
      add :cancellation_reason, :text
      add :cancelled_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:appointments, [:patient_id])
    create index(:appointments, [:doctor_id])
    create index(:appointments, [:scheduled_at])
    create index(:appointments, [:status])
    create unique_index(:appointments, [:cal_com_uid])
  end
end
