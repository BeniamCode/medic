defmodule MedicWeb.Admin.FinancialsController do
  use MedicWeb, :controller

  def index(conn, _params) do
    conn
    |> put_flash(:info, "Financials page - coming soon")
    |> redirect(to: ~p"/medic/dashboard")
  end
end
