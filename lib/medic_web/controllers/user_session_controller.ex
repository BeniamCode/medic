defmodule MedicWeb.UserSessionController do
  @moduledoc """
  Handles user session creation and deletion.
  """
  use MedicWeb, :controller

  alias Medic.Accounts
  alias MedicWeb.UserAuth

  def new(conn, _params) do
    if conn.assigns.current_user do
      redirect(conn, to: ~p"/dashboard")
    else
      conn
      |> assign(:page_title, "Log in")
      |> render_inertia("Auth/Login")
    end
  end

  def create(conn, %{"_action" => "registered"} = params) do
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

  defp create(conn, user_params, info) do
    %{"email" => email, "password" => password} = user_params

    # The UserAuth.log_in_user expects params to maybe have remember_me? No typically it takes separate arg or options.
    # checking UserAuth.log_in_user signature isn't possible directly here but standard phx auth usually just takes user.
    # Wait, the original code passed `user_params` as second arg.

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> put_status(401)
      |> render_inertia("Auth/Login")

      # Re-render on failure is important for Inertia to show errors, but Inertia handles validation errors via session usually?
      # No, for login failure (401), we typically return to the page with errors.
      # Standard Inertia pattern in Phoenix is to put errors in flash or session?
      # Or simpler: redirect back to /login with flash error.
      # Actually the original code redirected to ~p"/login". That works fine for Inertia too, it follows redirects.
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
