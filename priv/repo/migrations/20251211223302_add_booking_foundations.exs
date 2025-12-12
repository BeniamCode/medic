defmodule Medic.Repo.Migrations.AddBookingFoundations do
  use Ecto.Migration

  def change do
    # --- Doctor Locations & Rooms ---
    create table(:doctor_locations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :doctor_id, references(:doctors, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :address, :string
      add :city, :string
      add :country, :string
      add :timezone, :string, null: false, default: "Europe/Athens"
      add :phone, :string
      add :location_lat, :float
      add :location_lng, :float
      add :is_primary, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:doctor_locations, [:doctor_id])

    create unique_index(:doctor_locations, [:doctor_id],
             where: "is_primary",
             name: :doctor_locations_one_primary_per_doctor
           )

    create table(:location_rooms, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :doctor_location_id,
          references(:doctor_locations, type: :binary_id, on_delete: :delete_all),
          null: false

      add :name, :string, null: false
      add :capacity, :integer, null: false, default: 1
      add :is_virtual, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:location_rooms, [:doctor_location_id])
    create unique_index(:location_rooms, [:doctor_location_id, :name])

    # --- Appointment Types ---
    create table(:appointment_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :doctor_id, references(:doctors, type: :binary_id, on_delete: :delete_all), null: false
      add :slug, :string, null: false
      add :name, :string, null: false
      add :description, :text
      add :duration_minutes, :integer, null: false, default: 30
      add :buffer_before_minutes, :integer, null: false, default: 0
      add :buffer_after_minutes, :integer, null: false, default: 0
      add :price_cents, :integer
      add :currency, :string, null: false, default: "EUR"
      add :consultation_mode, :string, null: false, default: "in_person"

      add :default_location_id,
          references(:doctor_locations, type: :binary_id, on_delete: :nilify_all)

      add :default_room_id,
          references(:location_rooms, type: :binary_id, on_delete: :nilify_all)

      add :is_active, :boolean, null: false, default: true
      add :allow_patient_reschedule, :boolean, null: false, default: true
      add :min_notice_minutes, :integer, null: false, default: 0
      add :max_future_days, :integer, null: false, default: 60
      add :max_reschedule_count, :integer, null: false, default: 2
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:appointment_types, [:doctor_id])
    create unique_index(:appointment_types, [:doctor_id, :slug])

    create table(:appointment_type_locations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :appointment_type_id,
          references(:appointment_types, type: :binary_id, on_delete: :delete_all),
          null: false

      add :doctor_location_id,
          references(:doctor_locations, type: :binary_id, on_delete: :delete_all),
          null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:appointment_type_locations, [:appointment_type_id, :doctor_location_id],
             name: :appointment_type_locations_unique_scope
           )

    # --- Schedule Templates ---
    create table(:schedule_templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :doctor_id, references(:doctors, type: :binary_id, on_delete: :delete_all), null: false

      add :doctor_location_id,
          references(:doctor_locations, type: :binary_id, on_delete: :nilify_all)

      add :location_room_id, references(:location_rooms, type: :binary_id, on_delete: :nilify_all)

      add :appointment_type_id,
          references(:appointment_types, type: :binary_id, on_delete: :nilify_all)

      add :day_of_week, :integer, null: false
      add :slot_duration_minutes, :integer, null: false, default: 30
      add :work_start, :time, null: false
      add :work_end, :time, null: false
      add :buffer_before_minutes, :integer, null: false, default: 0
      add :buffer_after_minutes, :integer, null: false, default: 0
      add :max_parallel_sessions, :integer, null: false, default: 1
      add :priority, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:schedule_templates, [:doctor_id, :day_of_week])

    create table(:schedule_template_breaks, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :schedule_template_id,
          references(:schedule_templates, type: :binary_id, on_delete: :delete_all),
          null: false

      add :break_start, :time, null: false
      add :break_end, :time, null: false
      add :label, :string

      timestamps(type: :utc_datetime)
    end

    create index(:schedule_template_breaks, [:schedule_template_id])

    # --- Overrides & Time Off ---
    create table(:availability_exceptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :doctor_id, references(:doctors, type: :binary_id, on_delete: :delete_all), null: false

      add :appointment_type_id,
          references(:appointment_types, type: :binary_id, on_delete: :nilify_all)

      add :doctor_location_id,
          references(:doctor_locations, type: :binary_id, on_delete: :nilify_all)

      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime, null: false
      add :status, :string, null: false, default: "blocked"
      add :reason, :string
      add :source, :string, null: false, default: "manual"

      timestamps(type: :utc_datetime)
    end

    create index(:availability_exceptions, [:doctor_id])
    create index(:availability_exceptions, [:starts_at, :ends_at])

    create table(:time_off_requests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :doctor_id, references(:doctors, type: :binary_id, on_delete: :delete_all), null: false
      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime, null: false
      add :status, :string, null: false, default: "pending"
      add :reason, :string
      add :notes, :text
      add :approved_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:time_off_requests, [:doctor_id])
    create index(:time_off_requests, [:status])

    # --- Appointment Timeline ---
    create table(:appointment_events, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :appointment_id,
          references(:appointments, type: :binary_id, on_delete: :delete_all),
          null: false

      add :occurred_at, :utc_datetime, null: false
      add :actor_type, :string
      add :actor_id, :binary_id
      add :action, :string, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:appointment_events, [:appointment_id])

    # --- Calendar Sync ---
    create table(:calendar_connections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :doctor_id, references(:doctors, type: :binary_id, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :access_token, :text
      add :refresh_token, :text
      add :expires_at, :utc_datetime
      add :scopes, {:array, :string}, null: false, default: []
      add :sync_cursor, :string
      add :last_synced_at, :utc_datetime
      add :status, :string, null: false, default: "active"

      timestamps(type: :utc_datetime)
    end

    create index(:calendar_connections, [:doctor_id])
    create unique_index(:calendar_connections, [:doctor_id, :provider])

    create table(:external_busy_times, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :doctor_id, references(:doctors, type: :binary_id, on_delete: :delete_all), null: false

      add :calendar_connection_id,
          references(:calendar_connections, type: :binary_id, on_delete: :delete_all),
          null: false

      add :external_id, :string, null: false
      add :source, :string, null: false
      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime, null: false
      add :status, :string, null: false, default: "busy"
      add :last_seen_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:external_busy_times, [:doctor_id])
    create index(:external_busy_times, [:calendar_connection_id])
    create unique_index(:external_busy_times, [:calendar_connection_id, :external_id])

    # --- Existing Table Extensions ---
    alter table(:appointments) do
      add :doctor_location_id,
          references(:doctor_locations, type: :binary_id, on_delete: :nilify_all)

      add :location_room_id, references(:location_rooms, type: :binary_id, on_delete: :nilify_all)

      add :appointment_type_id,
          references(:appointment_types, type: :binary_id, on_delete: :nilify_all)

      add :price_cents, :integer
      add :currency, :string, null: false, default: "EUR"
      add :source, :string, null: false, default: "patient_portal"
      add :reschedule_count, :integer, null: false, default: 0
      add :cancelled_by, :string
      add :patient_timezone, :string
      add :doctor_timezone, :string
    end

    create index(:appointments, [:appointment_type_id])
    create index(:appointments, [:doctor_location_id])

    alter table(:patients) do
      add :preferred_language, :string, null: false, default: "en"
      add :preferred_timezone, :string
      add :communication_preferences, :map, null: false, default: %{}
    end

    alter table(:notifications) do
      add :channel, :string, null: false, default: "email"
      add :template, :string
      add :payload, :map, null: false, default: %{}
      add :sent_at, :utc_datetime
      add :provider_message_id, :string
      add :error_reason, :string
    end
  end
end
