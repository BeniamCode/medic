defmodule MedicWeb.Plugs.InertiaContext do
  @moduledoc """
  Shares common props (auth, locale, flash, etc.) with every Inertia response.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2]
  import Inertia.Controller, only: [assign_prop: 3, inertia_always: 1]

  alias Medic.Accounts.User
  alias Medic.Notifications
  alias MedicWeb.I18n
  alias MedicWeb.Gettext, as: WebGettext

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = resolve_locale(conn)

    conn
    |> assign_prop(:app, inertia_always(app_payload(conn, locale)))
    |> assign_prop(:auth, inertia_always(auth_payload(conn)))
    |> assign_prop(:flash, inertia_always(flash_payload(conn)))
    |> assign_prop(:i18n, inertia_always(i18n_payload(locale)))
  end

  defp resolve_locale(%{assigns: %{locale: locale}}) when is_binary(locale), do: locale

  defp resolve_locale(_conn) do
    Gettext.get_locale(WebGettext) || I18n.default_locale()
  end

  defp app_payload(conn, locale) do
    %{
      csrf_token: get_csrf_token(),
      current_scope: scope_for(conn),
      locale: locale,
      available_locales: I18n.available_locales(),
      path: conn.request_path,
      method: conn.method,
      unread_count: unread_count(conn)
    }
  end

  defp unread_count(%{assigns: %{current_user: %{id: user_id}}}) do
    Notifications.list_unread_count(user_id)
  end

  defp unread_count(_), do: 0

  defp auth_payload(%{assigns: %{current_user: %User{} = user}}) do
    %{
      authenticated: true,
      user: %{
        id: user.id,
        email: user.email,
        role: user.role,
        confirmed_at: user.confirmed_at
      },
      permissions: permissions_for(user)
    }
  end

  defp auth_payload(_conn) do
    %{authenticated: false, user: nil, permissions: %{}}
  end

  defp permissions_for(%User{role: role}) do
    %{
      can_access_admin: role == "admin",
      can_access_doctor: role in ["doctor", "admin"],
      can_manage_profile: role in ["doctor", "admin"],
      can_book: role in ["patient", "doctor", "admin"]
    }
  end

  defp flash_payload(conn) do
    [:info, :success, :error, :warning]
    |> Enum.reduce(%{}, fn type, acc ->
      case get_flash(conn, type) do
        nil -> acc
        "" -> acc
        message -> Map.put(acc, type, message)
      end
    end)
  end

  defp i18n_payload(locale) do
    %{
      locale: locale,
      default_locale: I18n.default_locale(),
      translations: I18n.export(locale)
    }
  end

  defp scope_for(%{assigns: %{current_scope: scope}}) when is_binary(scope), do: scope

  defp scope_for(%{path_info: ["medic" | _]}), do: "admin"

  defp scope_for(%{assigns: %{current_user: %User{role: "doctor"}}}), do: "doctor"

  defp scope_for(%{assigns: %{current_user: %User{role: "admin"}}}), do: "admin"

  defp scope_for(_conn), do: "public"
end
