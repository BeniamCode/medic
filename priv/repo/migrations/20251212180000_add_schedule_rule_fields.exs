defmodule Medic.Repo.Migrations.AddScheduleRuleFields do
  use Ecto.Migration

  def up do
    alter table(:schedule_rules) do
      add :scope_consultation_mode, :text
      add :effective_from, :date
      add :effective_to, :date
      add :is_active, :boolean, null: false, default: true
    end
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
