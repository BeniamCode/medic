defmodule MedicWeb.Admin.AuthController do
  use MedicWeb, :controller

  alias Medic.Accounts
  alias MedicWeb.UserAuth

  plug :redirect_if_user_is_authenticated when action in [:new]

  def new(conn, _params) do
    conn
    |> assign(:page_title, "Admin Login")
    |> render_inertia("Admin/Login")
  end

  def create(conn, %{"email" => email, "password" => password} = params) do
    case Accounts.get_user_by_email_and_password(email, password) do
      %{role: "admin"} = user ->
        conn
        |> put_flash(:info, "Welcome back, Admin!")
        |> UserAuth.log_in_user(user, params)

      %{role: _other_role} ->
        # User exists but is not admin
        conn
        |> put_flash(:error, "Access denied. Admin privileges required.")
        |> redirect(to: ~p"/medic/login")

      nil ->
        # Invalid credentials
        conn
        |> put_status(422)
        |> render_inertia("Admin/Login", %{
          errors: %{email: "Invalid email or password"}
        })
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  defp redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  defp signed_in_path(%{assigns: %{current_user: %{role: "admin"}}}), do: ~p"/medic/dashboard"
  defp signed_in_path(_conn), do: ~p"/dashboard"
end
