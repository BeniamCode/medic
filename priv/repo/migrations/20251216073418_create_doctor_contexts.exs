defmodule Medic.Repo.Migrations.CreateDoctorContexts do
  use Ecto.Migration

  def change do
    create table(:doctor_contexts, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :patient_id, references(:patients, type: :uuid, on_delete: :delete_all), null: false
      add :doctor_id, references(:doctors, type: :uuid, on_delete: :delete_all), null: false
      add :tags, {:array, :string}, default: []
      add :note, :string

      timestamps()
    end

    create unique_index(:doctor_contexts, [:patient_id, :doctor_id])
    create index(:doctor_contexts, [:patient_id])
    create index(:doctor_contexts, [:doctor_id])
  end
end
