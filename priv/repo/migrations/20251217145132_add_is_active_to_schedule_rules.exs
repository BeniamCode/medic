defmodule Medic.Repo.Migrations.AddIsActiveToScheduleRules do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE schedule_rules ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true NOT NULL"
  end
end
