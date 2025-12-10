defmodule MedicWeb.SettingsController do
  use MedicWeb, :controller

  def show(conn, _params) do
    user = conn.assigns.current_user

    conn
    |> assign(:page_title, dgettext("default", "Settings"))
    |> assign_prop(:profile, %{
      email: user.email,
      role: user.role,
      confirmed_at: user.confirmed_at
    })
    |> render_inertia("Patient/Settings")
  end
end
