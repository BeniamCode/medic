defmodule Medic.Repo.Migrations.CreateAdminUser do
  use Ecto.Migration

  def up do
    # This migration creates an admin user if one doesn't exist
    # Run this once, then it's idempotent
    
    execute """
    DO $$
    BEGIN
      -- Check if admin user exists
      IF NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@medic.gr') THEN
        -- Insert admin user (password will be hashed by the application)
        -- We'll handle this in seeds.exs instead since we need the Accounts context
        NULL;
      END IF;
    END $$;
    """
  end

  def down do
    execute "DELETE FROM users WHERE email = 'admin@medic.gr';"
  end
end
