defmodule MedicWeb.UserConfirmationController do
  @moduledoc """
  Handles user account confirmation links.
  """
  use MedicWeb, :controller

  alias Medic.Accounts

  def update(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, _user} ->
        conn
        |> put_flash(:success, dgettext("default", "Account confirmed successfully."))
        |> redirect(to: ~p"/login")

      :error ->
        conn
        |> put_flash(:error, dgettext("default", "Confirmation link is invalid or has expired."))
        |> redirect(to: ~p"/login")
    end
  end
end
