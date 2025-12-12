defmodule MedicWeb.PageControllerTest do
  use MedicWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "id=\"app\""
  end
end
