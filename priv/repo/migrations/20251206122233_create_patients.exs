defmodule Medic.Repo.Migrations.CreatePatients do
  use Ecto.Migration

  def change do
    create table(:patients, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :date_of_birth, :date
      add :phone, :string
      add :emergency_contact, :string
      add :profile_image_url, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:patients, [:user_id])
  end
end
