defmodule Medic.Repo.Migrations.AddDoctorInitiatedToPatients do
  use Ecto.Migration

  def change do
    alter table(:patients) do
      add :doctor_initiated, :boolean, default: false, null: false
    end
  end
end
