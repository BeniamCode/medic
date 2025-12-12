defmodule Medic.Repo.Migrations.AddUuidDefaultsToTables do
  use Ecto.Migration

  @tables ~w(users users_tokens specialties doctors patients appointments availability_rules notifications)a

  @timestamp_columns %{
    users: [:inserted_at, :updated_at],
    users_tokens: [:inserted_at],
    specialties: [:inserted_at, :updated_at],
    doctors: [:inserted_at, :updated_at],
    patients: [:inserted_at, :updated_at],
    appointments: [:inserted_at, :updated_at],
    availability_rules: [:inserted_at, :updated_at],
    notifications: [:inserted_at, :updated_at]
  }

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")

    Enum.each(@tables, &execute(alter_default_sql(&1, "gen_random_uuid()")))

    create_updated_at_function()

    Enum.each(@timestamp_columns, fn {table, columns} ->
      Enum.each(columns, &execute(alter_column_default_sql(table, &1, "timezone('utc', now())")))

      if :updated_at in columns do
        execute(create_trigger_sql(table))
      end
    end)
  end

  def down do
    Enum.each(@tables, &execute(alter_default_sql(&1, nil)))

    Enum.each(@timestamp_columns, fn {table, columns} ->
      if :updated_at in columns do
        execute(drop_trigger_sql(table))
      end

      Enum.each(columns, &execute(alter_column_default_sql(table, &1, nil)))
    end)

    execute("DROP FUNCTION IF EXISTS set_updated_at_timestamp()")
  end

  defp alter_default_sql(table, nil) do
    "ALTER TABLE \"#{table}\" ALTER COLUMN id DROP DEFAULT"
  end

  defp alter_default_sql(table, expression) do
    "ALTER TABLE \"#{table}\" ALTER COLUMN id SET DEFAULT #{expression}"
  end

  defp alter_column_default_sql(table, column, nil) do
    "ALTER TABLE \"#{table}\" ALTER COLUMN #{column} DROP DEFAULT"
  end

  defp alter_column_default_sql(table, column, expression) do
    "ALTER TABLE \"#{table}\" ALTER COLUMN #{column} SET DEFAULT #{expression}"
  end

  defp create_updated_at_function do
    execute("""
    CREATE OR REPLACE FUNCTION set_updated_at_timestamp()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = timezone('utc', now());
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """)
  end

  defp create_trigger_sql(table) do
    """
    CREATE TRIGGER set_updated_at_#{table}
    BEFORE UPDATE ON \"#{table}\"
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at_timestamp();
    """
  end

  defp drop_trigger_sql(table) do
    "DROP TRIGGER IF EXISTS set_updated_at_#{table} ON \"#{table}\""
  end
end
