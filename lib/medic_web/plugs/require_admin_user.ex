defmodule MedicWeb.Plugs.RequireAdminUser do
  @moduledoc """
  Plug to require admin user authentication.
  Redirects to /medic/login if not authenticated or not admin.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias MedicWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      %{role: "admin"} ->
        conn

      %{role: _other} ->
        conn
        |> put_flash(:error, "Access denied. Admin privileges required.")
        |> redirect(to: "/medic/login")
        |> halt()

      nil ->
        conn
        |> put_flash(:error, "Please log in to access the admin panel.")
        |> redirect(to: "/medic/login")
        |> halt()
    end
  end
end
