# Admin User Seed
# Creates admin@medic.gr if it doesn't exist

alias Medic.{Accounts, Repo}

IO.puts("Creating admin user...")

admin_attrs = %{
  email: "admin@medic.gr",
  password: "Admin123!Medic",
  role: "admin",
  first_name: "Admin",
  last_name: "User"
}

case Accounts.get_user_by_email("admin@medic.gr") do
  nil ->
    case Accounts.register_user(admin_attrs) do
      {:ok, user} ->
        # Auto-confirm admin user
        user
        |> Ecto.Changeset.change(%{confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)})
        |> Repo.update!()
        
        IO.puts("✓ Admin user created: admin@medic.gr / Admin123!Medic")

      {:error, changeset} ->
        IO.puts("✗ Failed to create admin user:")
        IO.inspect(changeset.errors)
    end

  _existing_user ->
    IO.puts("✓ Admin user already exists")
end
