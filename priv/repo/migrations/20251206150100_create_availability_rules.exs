defmodule Medic.Repo.Migrations.CreateAvailabilityRules do
  use Ecto.Migration

  def change do
    create table(:availability_rules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :doctor_id, references(:doctors, type: :binary_id, on_delete: :delete_all), null: false
      add :day_of_week, :integer, null: false  # 1=Monday, 7=Sunday (ISO week)
      add :start_time, :time, null: false
      add :end_time, :time, null: false
      add :break_start, :time
      add :break_end, :time
      add :slot_duration_minutes, :integer, default: 30
      add :is_active, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:availability_rules, [:doctor_id])
    create index(:availability_rules, [:doctor_id, :day_of_week])

    # Ensure only one rule per doctor per day
    create unique_index(:availability_rules, [:doctor_id, :day_of_week],
      name: :availability_rules_doctor_day_unique
    )
  end
end
