defmodule MedicWeb.LiveHooks.Locale do
  import Phoenix.Component

  def on_mount(:default, _params, session, socket) do
    locale = session["locale"] || "en"
    Gettext.put_locale(MedicWeb.Gettext, locale)
    {:cont, assign(socket, locale: locale)}
  end
end
