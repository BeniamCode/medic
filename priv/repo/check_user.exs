# priv/repo/check_user.exs
alias Medic.Accounts
require Ash.Query

email = "beniam@medic.com"
user = Medic.Accounts.User |> Ash.Query.filter(email == ^email) |> Ash.read_one!()

IO.inspect(user.role, label: "User Role")
IO.inspect(user.email, label: "User Email")
