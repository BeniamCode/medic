defmodule Medic.Repo.Migrations.MakeUserIdNullable do
  use Ecto.Migration

  def up do
    alter table(:patients) do
      modify :user_id, :uuid, null: true
    end
  end

  def down do
    alter table(:patients) do
      modify :user_id, :uuid, null: false
    end
  end
end
