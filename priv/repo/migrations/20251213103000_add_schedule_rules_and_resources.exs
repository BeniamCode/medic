defmodule Medic.Repo.Migrations.AddScheduleRulesAndResources do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS btree_gist"

    create table(:bookable_resources, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :doctor_id, references(:doctors, type: :binary_id, on_delete: :delete_all), null: false

      add :doctor_location_id,
          references(:doctor_locations, type: :binary_id, on_delete: :nilify_all)

      add :location_room_id,
          references(:location_rooms, type: :binary_id, on_delete: :nilify_all)

      add :resource_type, :string, null: false
      add :label, :string
      add :capacity, :integer, null: false, default: 1
      add :is_active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create index(
             :bookable_resources,
             [:doctor_id, :doctor_location_id, :resource_type, :is_active],
             name: :bookable_resources_scope_index
           )

    create table(:schedule_rules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :doctor_id, references(:doctors, type: :binary_id, on_delete: :delete_all), null: false
      add :timezone, :string, null: false, default: "Europe/Athens"

      add :scope_appointment_type_id,
          references(:appointment_types, type: :binary_id, on_delete: :nilify_all)

      add :scope_doctor_location_id,
          references(:doctor_locations, type: :binary_id, on_delete: :nilify_all)

      add :scope_location_room_id,
          references(:location_rooms, type: :binary_id, on_delete: :nilify_all)

      add :day_of_week, :integer, null: false
      add :work_start_local, :time, null: false
      add :work_end_local, :time, null: false
      add :slot_interval_minutes, :integer, null: false, default: 30
      add :buffer_before_minutes, :integer, null: false, default: 0
      add :buffer_after_minutes, :integer, null: false, default: 0
      add :label, :string
      add :priority, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:schedule_rules, [:doctor_id, :day_of_week])

    create table(:schedule_rule_breaks, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :schedule_rule_id,
          references(:schedule_rules, type: :binary_id, on_delete: :delete_all),
          null: false

      add :break_start_local, :time, null: false
      add :break_end_local, :time, null: false
      add :label, :string

      timestamps(type: :utc_datetime)
    end

    create index(:schedule_rule_breaks, [:schedule_rule_id])

    create table(:schedule_exceptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :doctor_id, references(:doctors, type: :binary_id, on_delete: :delete_all), null: false

      add :schedule_rule_id,
          references(:schedule_rules, type: :binary_id, on_delete: :delete_all)

      add :appointment_type_id,
          references(:appointment_types, type: :binary_id, on_delete: :nilify_all)

      add :doctor_location_id,
          references(:doctor_locations, type: :binary_id, on_delete: :nilify_all)

      add :location_room_id,
          references(:location_rooms, type: :binary_id, on_delete: :nilify_all)

      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime, null: false
      add :exception_type, :string, null: false, default: "blocked"
      add :reason, :string
      add :source, :string, null: false, default: "manual"

      timestamps(type: :utc_datetime)
    end

    create index(:schedule_exceptions, [:doctor_id, :starts_at])

    create table(:appointment_resource_claims, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :appointment_id,
          references(:appointments, type: :binary_id, on_delete: :delete_all),
          null: false

      add :bookable_resource_id,
          references(:bookable_resources, type: :binary_id, on_delete: :delete_all),
          null: false

      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime, null: false
      add :status, :string, null: false, default: "active"

      timestamps(type: :utc_datetime)
    end

    create index(:appointment_resource_claims, [:appointment_id])

    create index(:appointment_resource_claims, [:bookable_resource_id],
             name: :appointment_resource_claims_resource_idx
           )

    execute """
    ALTER TABLE appointment_resource_claims
    ADD CONSTRAINT appointment_resource_claims_no_overlap
    EXCLUDE USING gist (
      bookable_resource_id WITH =,
      tsrange(starts_at, ends_at) WITH &&
    )
    WHERE (status = 'active')
    """

    rename table(:appointments), :appointment_type, to: :consultation_mode_snapshot

    alter table(:appointments) do
      add :service_name_snapshot, :string
      add :service_duration_snapshot, :integer
      add :service_price_cents_snapshot, :integer
      add :service_currency_snapshot, :string
      add :external_reference, :string
      add :hold_expires_at, :utc_datetime
      add :created_by_actor_type, :string
      add :created_by_actor_id, :binary_id
      add :cancelled_by_actor_type, :string
      add :cancelled_by_actor_id, :binary_id
    end

    create index(:appointments, [:doctor_id, :starts_at], name: :appointments_doctor_start_idx)
    create index(:appointments, [:patient_id, :starts_at], name: :appointments_patient_start_idx)

    create index(:appointments, [:appointment_type_id, :starts_at],
             name: :appointments_type_start_idx
           )
  end

  def down do
    drop index(:appointments, [:doctor_id, :starts_at], name: :appointments_doctor_start_idx)
    drop index(:appointments, [:patient_id, :starts_at], name: :appointments_patient_start_idx)

    drop index(:appointments, [:appointment_type_id, :starts_at],
           name: :appointments_type_start_idx
         )

    alter table(:appointments) do
      remove :service_name_snapshot
      remove :service_duration_snapshot
      remove :service_price_cents_snapshot
      remove :service_currency_snapshot
      remove :external_reference
      remove :hold_expires_at
      remove :created_by_actor_type
      remove :created_by_actor_id
      remove :cancelled_by_actor_type
      remove :cancelled_by_actor_id
    end

    rename table(:appointments), :consultation_mode_snapshot, to: :appointment_type

    execute "ALTER TABLE appointment_resource_claims DROP CONSTRAINT IF EXISTS appointment_resource_claims_no_overlap"

    drop table(:appointment_resource_claims)
    drop table(:schedule_exceptions)
    drop table(:schedule_rule_breaks)
    drop table(:schedule_rules)
    drop table(:bookable_resources)
  end
end
