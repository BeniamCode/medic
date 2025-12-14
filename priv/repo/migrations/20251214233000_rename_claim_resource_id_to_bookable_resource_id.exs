defmodule Medic.Repo.Migrations.RenameClaimResourceIdToBookableResourceId do
  use Ecto.Migration

  def up do
    execute """
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'appointment_resource_claims'
          AND column_name = 'resource_id'
      ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'appointment_resource_claims'
          AND column_name = 'bookable_resource_id'
      ) THEN
        ALTER TABLE appointment_resource_claims
        RENAME COLUMN resource_id TO bookable_resource_id;
      END IF;
    END $$;
    """
  end

  def down do
    execute """
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'appointment_resource_claims'
          AND column_name = 'bookable_resource_id'
      ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'appointment_resource_claims'
          AND column_name = 'resource_id'
      ) THEN
        ALTER TABLE appointment_resource_claims
        RENAME COLUMN bookable_resource_id TO resource_id;
      END IF;
    END $$;
    """
  end
end
