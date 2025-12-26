defmodule Medic.Repo.Migrations.AddIsActiveToScheduleRules do
  use Ecto.Migration

  def change do
    alter table(:schedule_rules) do
      add :is_active, :boolean, default: true, null: false
    end
  end
end
