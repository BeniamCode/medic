defmodule MedicWeb.Admin.UsersController do
  use MedicWeb, :controller

  alias Medic.Accounts
  alias Medic.Repo

  import Ecto.Query

  def index(conn, params) do
    page = String.to_integer(params["page"] || "1")
    per_page = 20

    search = params["search"]

    query = build_users_query(search)

    total = Repo.aggregate(query, :count, :id)

    users =
      query
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> order_by([u], desc: u.inserted_at)
      |> Repo.all()
      |> Repo.preload([:doctor, :patient])

    users_data =
      Enum.map(users, fn user ->
        %{
          id: user.id,
          email: user.email,
          role: user.role,
          confirmed: !is_nil(user.confirmed_at),
          confirmed_at: user.confirmed_at,
          first_name: get_first_name(user),
          last_name: get_last_name(user),
          inserted_at: user.inserted_at
        }
      end)

    conn
    |> assign(:page_title, "User Management")
    |> render_inertia("Admin/Users", %{
      users: users_data,
      pagination: %{
        current_page: page,
        per_page: per_page,
        total: total
      },
      search: search
    })
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    case Repo.delete(user) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "User deleted successfully")
        |> redirect(to: ~p"/medic/users")

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to delete user")
        |> redirect(to: ~p"/medic/users")
    end
  end

  defp build_users_query(nil) do
    from u in Medic.Accounts.User
  end

  defp build_users_query(search) do
    search_term = "%#{search}%"

    from u in Medic.Accounts.User,
      left_join: d in assoc(u, :doctor),
      left_join: p in assoc(u, :patient),
      where:
        ilike(u.email, ^search_term) or
          ilike(d.first_name, ^search_term) or
          ilike(d.last_name, ^search_term) or
          ilike(p.first_name, ^search_term) or
          ilike(p.last_name, ^search_term)
  end

  defp get_first_name(%{doctor: %{first_name: name}}) when not is_nil(name), do: name
  defp get_first_name(%{patient: %{first_name: name}}) when not is_nil(name), do: name
  defp get_first_name(_), do: nil

  defp get_last_name(%{doctor: %{last_name: name}}) when not is_nil(name), do: name
  defp get_last_name(%{patient: %{last_name: name}}) when not is_nil(name), do: name
  defp get_last_name(_), do: nil
end
