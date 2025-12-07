defmodule Medic.Repo.Migrations.RemoveCalComFields do
  use Ecto.Migration

  def change do
    alter table(:doctors) do
      remove :cal_com_user_id
      remove :cal_com_event_type_id
      remove :cal_com_username
    end
  end
end
