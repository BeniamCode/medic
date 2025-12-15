defmodule Medic.Repo.Migrations.AddNeighborhoodToDoctors do
  use Ecto.Migration

  def change do
    alter table(:doctors) do
      add :neighborhood, :string
    end
  end
end
