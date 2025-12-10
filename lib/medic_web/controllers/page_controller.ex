defmodule MedicWeb.PageController do
  use MedicWeb, :controller

  def home(conn, _params) do
    conn
    |> assign(:page_title, dgettext("default", "Home"))
    |> assign_prop(:page_title, dgettext("default", "Home"))
    |> render_inertia("Public/Home")
  end
end
