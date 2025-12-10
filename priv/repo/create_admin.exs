# priv/repo/create_admin.exs
alias Medic.Accounts.User
alias Medic.Accounts

require Ash.Query

email = "beniam@medic.com"
password = "Silverpaw1_"
role = :admin

IO.puts("Creating admin user: #{email}")

hashed_password = Bcrypt.hash_pwd_salt(password)

attrs = %{
  email: email,
  hashed_password: hashed_password,
  role: role,
  confirmed_at: DateTime.utc_now()
}

# Check if user exists
query = 
  User
  |> Ash.Query.filter(email == ^email)

case Accounts.read_one(query) do
  {:ok, nil} ->
    User
    |> Ash.Changeset.for_create(:create, attrs)
    |> Accounts.create!()
    
    IO.puts("User created successfully.")

  {:ok, _user} ->
    IO.puts("User already exists.")
    
  {:error, error} ->
    IO.inspect(error, label: "Error checking user")
end
