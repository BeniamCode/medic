defmodule Medic.Repo.Migrations.CreateSpecialties do
  use Ecto.Migration

  def change do
    create table(:specialties, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name_en, :string, null: false
      add :name_el, :string, null: false
      add :slug, :string, null: false
      add :icon, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:specialties, [:slug])
  end
end
