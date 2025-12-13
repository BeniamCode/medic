defmodule Medic.Repo.Migrations.AddBookingLifecycleFields do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      add :pending_expires_at, :utc_datetime
      add :approval_required_snapshot, :boolean, null: false, default: false

      add :rescheduled_from_appointment_id,
          references(:appointments, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:appointments, [:status, :hold_expires_at], name: :appointments_hold_expiry_idx)

    create index(:appointments, [:status, :pending_expires_at],
             name: :appointments_pending_expiry_idx
           )

    create index(:appointments, [:rescheduled_from_appointment_id],
             name: :appointments_rescheduled_from_idx
           )

    alter table(:appointment_resource_claims) do
      add :released_at, :utc_datetime
    end

    create index(:appointment_resource_claims, [:status, :released_at],
             name: :appointment_resource_claims_release_idx
           )

    create index(:appointment_events, [:appointment_id, :occurred_at],
             name: :appointment_events_time_idx
           )

    create table(:notification_jobs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :channel, :string, null: false, default: "email"
      add :template, :string, null: false
      add :payload, :map, null: false, default: %{}
      add :scheduled_at, :utc_datetime
      add :status, :string, null: false, default: "pending"
      add :attempts, :integer, null: false, default: 0
      add :last_error, :string
      add :idempotency_key, :string

      timestamps(type: :utc_datetime)
    end

    create index(:notification_jobs, [:user_id])
    create index(:notification_jobs, [:status, :scheduled_at])

    create unique_index(:notification_jobs, [:idempotency_key],
             where: "idempotency_key IS NOT NULL"
           )

    create table(:notification_deliveries, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :notification_job_id,
          references(:notification_jobs, type: :binary_id, on_delete: :delete_all),
          null: false

      add :channel, :string, null: false, default: "email"
      add :provider, :string
      add :provider_message_id, :string
      add :attempted_at, :utc_datetime
      add :status, :string, null: false, default: "pending"
      add :response, :map, null: false, default: %{}
      add :error, :string

      timestamps(type: :utc_datetime)
    end

    create index(:notification_deliveries, [:notification_job_id])
    create index(:notification_deliveries, [:status])

    create table(:notification_preferences, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :channels, :map, null: false, default: %{}
      add :reminder_settings, :map, null: false, default: %{}
      add :quiet_hours, :map
      add :locale, :string, null: false, default: "en"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:notification_preferences, [:user_id],
             name: :notification_preferences_user_unique
           )
  end
end
