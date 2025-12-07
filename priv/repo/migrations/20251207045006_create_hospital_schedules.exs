defmodule Medic.Repo.Migrations.CreateHospitalSchedules do
  use Ecto.Migration

  def change do
    create table(:hospital_schedules) do
      add :date, :date
      add :specialties, {:array, :string}
      add :hospital_id, references(:hospitals, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:hospital_schedules, [:hospital_id])
  end
end
