defmodule MedicWeb.API.AuthController do
  @moduledoc """
  Authentication API controller for mobile app.
  Handles login, registration, token refresh, and current user info.
  """
  use MedicWeb, :controller

  alias Medic.Accounts
  alias Medic.Token
  alias Medic.Repo

  action_fallback MedicWeb.API.FallbackController

  @doc """
  POST /api/auth/login
  Authenticates user and returns JWT token.
  """
  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.get_user_by_email_and_password(email, password) do
      %Medic.Accounts.User{} = user ->
        user = Ash.load!(user, [:doctor, :patient])
        {:ok, token, _claims} = Token.generate_and_sign_for_user(user)
        
        conn
        |> put_status(:ok)
        |> json(%{
          data: %{
            token: token,
            user: user_to_json(user)
          }
        })

      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})
    end
  end

  @doc """
  POST /api/auth/register
  Registers a new user and returns JWT token.
  """
  def register(conn, %{"email" => email, "password" => password} = params) do
    role = Map.get(params, "role", "patient")
    
    attrs = %{
      email: email,
      password: password,
      role: role
    }

    case Accounts.register_user(attrs) do
      {:ok, user} ->
        user = Ash.load!(user, [:doctor, :patient])
        {:ok, token, _claims} = Token.generate_and_sign_for_user(user)
        
        conn
        |> put_status(:created)
        |> json(%{
          data: %{
            token: token,
            user: user_to_json(user)
          }
        })

      {:error, changeset} ->
        errors = format_changeset_errors(changeset)
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors})
    end
  end

  @doc """
  GET /api/auth/me
  Returns current authenticated user info.
  """
  def me(conn, _params) do
    user = conn.assigns.current_user
    
    # Load full user from DB with associations
    full_user = 
      Medic.Accounts.User
      |> Repo.get!(user.id)
      |> Ash.load!([:doctor, :patient])
    
    conn
    |> put_status(:ok)
    |> json(%{data: user_to_json(full_user)})
  end

  @doc """
  POST /api/auth/refresh
  Refreshes the JWT token.
  """
  def refresh(conn, _params) do
    user = conn.assigns.current_user
    
    full_user = 
      Medic.Accounts.User
      |> Repo.get!(user.id)
      |> Ash.load!([:doctor, :patient])
    
    {:ok, token, _claims} = Token.generate_and_sign_for_user(full_user)
    
    conn
    |> put_status(:ok)
    |> json(%{data: %{token: token}})
  end

  @doc """
  POST /api/auth/forgot_password
  Sends password reset email.
  """
  def forgot_password(conn, %{"email" => email}) do
    # Always return success to prevent email enumeration
    case Accounts.get_user_by_email(email) do
      %Medic.Accounts.User{} = user ->
        # Generate reset token and send email
        Accounts.deliver_user_reset_password_instructions(user, fn token ->
          "#{MedicWeb.Endpoint.url()}/reset-password/#{token}"
        end)
      _ ->
        :ok
    end
    
    conn
    |> put_status(:ok)
    |> json(%{message: "If an account exists, a reset email has been sent"})
  end

  @doc """
  POST /api/auth/reset_password
  Resets password using token.
  """
  def reset_password(conn, %{"token" => token, "password" => password}) do
    case Accounts.get_user_by_reset_password_token(token) do
      %Medic.Accounts.User{} = user ->
        case Accounts.reset_user_password(user, %{password: password, password_confirmation: password}) do
          {:ok, _user} ->
            conn
            |> put_status(:ok)
            |> json(%{message: "Password reset successfully"})
          
          {:error, _} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "Failed to reset password"})
        end
      
      nil ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Invalid or expired token"})
    end
  end

  @doc """
  POST /api/auth/change_password (authenticated)
  Changes password for logged-in user.
  """
  def change_password(conn, %{"current_password" => current, "new_password" => new_password}) do
    user_claims = conn.assigns.current_user
    user = Repo.get!(Medic.Accounts.User, user_claims.id)
    
    case Accounts.update_user_password(user, current, %{password: new_password}) do
      {:ok, _updated} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Password changed successfully"})
      
      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Current password is incorrect"})
    end
  end

  # --- Private Helpers ---

  defp user_to_json(user) do
    first_name = cond do
      user.doctor && is_struct(user.doctor) -> user.doctor.first_name
      user.patient && is_struct(user.patient) -> user.patient.first_name
      true -> "User"
    end
    
    last_name = cond do
      user.doctor && is_struct(user.doctor) -> user.doctor.last_name
      user.patient && is_struct(user.patient) -> user.patient.last_name
      true -> ""
    end

    profile_id = cond do
      user.doctor && is_struct(user.doctor) -> user.doctor.id
      user.patient && is_struct(user.patient) -> user.patient.id
      true -> nil
    end

    %{
      id: user.id,
      email: user.email,
      role: user.role,
      first_name: first_name,
      last_name: last_name,
      profile_id: profile_id
    }
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
