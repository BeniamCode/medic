defmodule Medic.Repo.Migrations.CreateDoctors do
  use Ecto.Migration

  def change do
    create table(:doctors, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :specialty_id, references(:specialties, type: :binary_id, on_delete: :nilify_all)

      # Profile info
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :bio, :text
      add :bio_el, :text
      add :profile_image_url, :string

      # Location for geo-search
      add :location_lat, :float
      add :location_lng, :float
      add :address, :string
      add :city, :string

      # Ratings and pricing
      add :rating, :float, default: 0.0
      add :review_count, :integer, default: 0
      add :consultation_fee, :decimal, precision: 10, scale: 2

      # Cal.com integration
      add :cal_com_user_id, :string
      add :cal_com_event_type_id, :string
      add :cal_com_username, :string

      # Cached availability for fast search
      add :next_available_slot, :utc_datetime

      add :verified_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:doctors, [:user_id])
    create index(:doctors, [:specialty_id])
    create index(:doctors, [:city])
    create index(:doctors, [:rating])
    create index(:doctors, [:next_available_slot])
  end
end
