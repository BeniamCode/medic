defmodule Medic.Repo.Migrations.AddExclusionConstraintToAppointments do
  use Ecto.Migration

  def up do
    # Enable btree_gist extension for exclusion constraints
    execute "CREATE EXTENSION IF NOT EXISTS btree_gist"

    # Rename scheduled_at to starts_at and add ends_at
    rename table(:appointments), :scheduled_at, to: :starts_at

    alter table(:appointments) do
      add :ends_at, :utc_datetime
    end

    # Backfill ends_at from starts_at + duration
    execute """
    UPDATE appointments
    SET ends_at = starts_at + (duration_minutes || ' minutes')::interval
    WHERE ends_at IS NULL
    """

    # Make ends_at NOT NULL after backfill
    alter table(:appointments) do
      modify :ends_at, :utc_datetime, null: false
    end

    # Create the exclusion constraint to prevent double-booking
    # This ensures no two appointments for the same doctor can have overlapping times
    execute """
    ALTER TABLE appointments
    ADD CONSTRAINT no_double_bookings
    EXCLUDE USING gist (
      doctor_id WITH =,
      tsrange(starts_at, ends_at) WITH &&
    )
    WHERE (status NOT IN ('cancelled', 'no_show'))
    """

    # Add index for time-range queries
    create index(:appointments, [:starts_at, :ends_at])
  end

  def down do
    execute "ALTER TABLE appointments DROP CONSTRAINT IF EXISTS no_double_bookings"
    drop_if_exists index(:appointments, [:starts_at, :ends_at])

    alter table(:appointments) do
      remove :ends_at
    end

    rename table(:appointments), :starts_at, to: :scheduled_at
  end
end
