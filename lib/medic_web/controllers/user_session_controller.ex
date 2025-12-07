defmodule MedicWeb.UserSessionController do
  @moduledoc """
  Handles user session creation and deletion.
  """
  use MedicWeb, :controller

  alias Medic.Accounts
  alias MedicWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    # After registration, redirect based on role (determined after login in create/3)
    create(conn, params, "Account created successfully!", :registered)
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/dashboard")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/login")
    end
  end

  # Handle registration - redirect based on user role
  defp create(conn, %{"user" => user_params}, info, :registered) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      # Redirect doctors to onboarding, patients to dashboard
      redirect_to = if user.role == "doctor", do: ~p"/onboarding/doctor", else: ~p"/dashboard"

      conn
      |> put_session(:user_return_to, redirect_to)
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
