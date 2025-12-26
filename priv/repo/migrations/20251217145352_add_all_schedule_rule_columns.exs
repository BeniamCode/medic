defmodule Medic.Repo.Migrations.AddAllScheduleRuleColumns do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS work_start_local time"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS work_end_local time"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS slot_interval_minutes integer DEFAULT 30"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS buffer_before_minutes integer DEFAULT 0"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS buffer_after_minutes integer DEFAULT 0"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS label varchar(255)"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS priority integer DEFAULT 0"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS scope_consultation_mode varchar(255)"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS scope_appointment_type_id uuid"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS scope_doctor_location_id uuid"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS scope_location_room_id uuid"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS effective_from date"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS effective_to date"
  end
end
