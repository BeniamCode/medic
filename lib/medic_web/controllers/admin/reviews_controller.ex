defmodule MedicWeb.Admin.ReviewsController do
  use MedicWeb, :controller

  def index(conn, _params) do
    conn
    |> put_flash(:info, "Reviews page - coming soon")
    |> redirect(to: ~p"/medic/dashboard")
  end
end
