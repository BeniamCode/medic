defmodule MedicWeb.Plugs.VerifyApiToken do
  import Plug.Conn
  alias Medic.Token

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- Token.verify_token(token) do
      assign(conn, :current_user, %{id: claims["user_id"], role: claims["role"]})
    else
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Unauthorized"}))
        |> halt()
    end
  end
end
