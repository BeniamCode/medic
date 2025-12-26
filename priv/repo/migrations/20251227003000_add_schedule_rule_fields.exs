defmodule Medic.Repo.Migrations.AddScheduleRuleFields do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS scope_consultation_mode text"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS effective_from date"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS effective_to date"
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true NOT NULL"
  end

  def down do
    alter table(:schedule_rules) do
      remove :is_active
      remove :effective_to
      remove :effective_from
      remove :scope_consultation_mode
    end
  end
end
