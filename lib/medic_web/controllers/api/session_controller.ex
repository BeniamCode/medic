defmodule MedicWeb.API.SessionController do
  use MedicWeb, :controller

  alias Medic.Accounts
  alias Medic.Token
  alias Medic.Repo

  action_fallback MedicWeb.API.FallbackController

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.get_user_by_email_and_password(email, password) do
      %Medic.Accounts.User{} = user ->
        user = Ash.load!(user, [:doctor, :patient])
        {:ok, token, _claims} = Token.generate_and_sign_for_user(user)
        
        first_name = cond do
          user.doctor && is_map(user.doctor) -> user.doctor.first_name
          user.patient && is_map(user.patient) -> user.patient.first_name
          true -> "User"
        end
        
        last_name = cond do
          user.doctor && is_map(user.doctor) -> user.doctor.last_name
          user.patient && is_map(user.patient) -> user.patient.last_name
          true -> ""
        end

        conn
        |> put_status(:ok)
        |> json(%{
          data: %{
            token: token,
            user: %{
              id: user.id,
              email: user.email,
              role: user.role,
              first_name: first_name,
              last_name: last_name
            }
          }
        })

      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})
    end
  end
end