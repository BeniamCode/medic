defmodule Medic.Repo.Migrations.CreateAppreciateSystem do
  use Ecto.Migration

  def change do
    create table(:doctor_appreciations, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :doctor_id, references(:doctors, type: :uuid, on_delete: :delete_all), null: false
      add :patient_id, references(:patients, type: :uuid, on_delete: :delete_all), null: false

      add :appointment_id,
          references(:appointments, type: :uuid, on_delete: :delete_all),
          null: false

      add :kind, :text, null: false, default: "appreciated"
      add :created_at, :timestamptz, null: false, default: fragment("now()")
    end

    create unique_index(:doctor_appreciations, [:appointment_id])
    create unique_index(:doctor_appreciations, [:doctor_id, :patient_id, :appointment_id])

    create index(:doctor_appreciations, [:doctor_id, :created_at],
             name: "doctor_appreciations_doctor_created_idx"
           )

    create index(:doctor_appreciations, [:patient_id, :created_at],
             name: "doctor_appreciations_patient_created_idx"
           )

    create table(:doctor_appreciation_notes, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :appreciation_id,
          references(:doctor_appreciations, type: :uuid, on_delete: :delete_all),
          null: false

      add :note_text, :text, null: false
      add :visibility, :text, null: false, default: "private"
      add :moderation_status, :text, null: false, default: "pending"

      add :moderated_by_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :moderated_at, :timestamptz

      add :created_at, :timestamptz, null: false, default: fragment("now()")
    end

    create unique_index(:doctor_appreciation_notes, [:appreciation_id])

    create constraint(:doctor_appreciation_notes, :note_text_max_length,
             check: "char_length(note_text) <= 80"
           )

    create table(:doctor_appreciation_stats, primary_key: false) do
      add :doctor_id, references(:doctors, type: :uuid, on_delete: :delete_all),
        primary_key: true,
        null: false

      add :appreciated_total_distinct_patients, :integer, null: false, default: 0
      add :appreciated_last_30d_distinct_patients, :integer, null: false, default: 0
      add :last_appreciated_at, :timestamptz
      add :updated_at, :timestamptz, null: false, default: fragment("now()")
    end

    create index(:doctor_appreciation_stats, [:updated_at],
             name: "doctor_appreciation_stats_updated_idx"
           )

    create table(:achievement_definitions, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :key, :text, null: false
      add :name, :text, null: false
      add :description, :text
      add :category, :text, null: false
      add :icon, :text
      add :is_public, :boolean, null: false, default: true
      add :is_active, :boolean, null: false, default: true
      add :is_tiered, :boolean, null: false, default: false

      timestamps(type: :timestamptz)
    end

    create unique_index(:achievement_definitions, [:key])

    create index(:achievement_definitions, [:is_active, :category],
             name: "achievement_definitions_active_idx"
           )

    create table(:doctor_achievements, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :doctor_id, references(:doctors, type: :uuid, on_delete: :delete_all), null: false

      add :achievement_definition_id,
          references(:achievement_definitions, type: :uuid, on_delete: :delete_all),
          null: false

      add :status, :text, null: false, default: "earned"
      add :tier, :integer
      add :earned_at, :timestamptz, null: false, default: fragment("now()")
      add :source, :text, null: false, default: "system"
      add :metadata, :map, null: false, default: %{}
    end

    create unique_index(:doctor_achievements, [:doctor_id, :achievement_definition_id, :tier])

    create index(:doctor_achievements, [:doctor_id, :earned_at],
             name: "doctor_achievements_doctor_idx"
           )

    create table(:achievement_events, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :doctor_id, references(:doctors, type: :uuid, on_delete: :delete_all), null: false

      add :achievement_definition_id,
          references(:achievement_definitions, type: :uuid, on_delete: :delete_all),
          null: false

      add :action, :text, null: false
      add :occurred_at, :timestamptz, null: false, default: fragment("now()")

      add :actor_type, :text, null: false, default: "system"
      add :actor_id, :uuid

      add :metadata, :map, null: false, default: %{}
    end

    create index(:achievement_events, [:doctor_id, :occurred_at],
             name: "achievement_events_doctor_idx"
           )
  end
end
