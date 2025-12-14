defmodule Medic.Repo.Migrations.DropDoctorPronouns do
  use Ecto.Migration

  def change do
    alter table(:doctors) do
      remove :pronouns
    end
  end
end
