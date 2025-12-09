defmodule MedicWeb.Plugs.Locale do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _default) do
    case fetch_locale(conn) do
      nil ->
        conn

      locale ->
        MedicWeb.Gettext
        |> Gettext.put_locale(locale)

        conn
        |> assign(:locale, locale)
        |> put_session(:locale, locale)
    end
  end

  defp fetch_locale(conn) do
    # 1. Check params (e.g., ?locale=el)
    # 2. Check session
    # 3. Fallback to default (nil here means we don't force it unless set)
    case conn.params["locale"] do
      nil -> get_session(conn, :locale)
      locale when locale in ["en", "el"] -> locale
      _ -> get_session(conn, :locale)
    end
  end
end
