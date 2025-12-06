defmodule MedicWeb.PageController do
  use MedicWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
