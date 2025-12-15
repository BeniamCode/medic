defmodule Medic.Repo.Migrations.AddZipCodeColumn do
  use Ecto.Migration

  def change do
    alter table(:doctors) do
      add :zip_code, :string
    end
  end
end
