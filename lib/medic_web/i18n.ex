defmodule MedicWeb.I18n do
  @moduledoc """
  Utilities for exposing Gettext translations and locale metadata to the
  JavaScript application.
  """

  alias Expo.PO
  alias Expo.Message.{Plural, Singular}

  @gettext_backend MedicWeb.Gettext

  @doc """
  Returns the available locales configured for the application.
  """
  @spec available_locales() :: [String.t()]
  def available_locales do
    @gettext_backend.__gettext__(:known_locales)
  end

  @doc """
  Returns the default locale configured for Gettext.
  """
  @spec default_locale() :: String.t()
  def default_locale do
    locale = @gettext_backend.__gettext__(:default_locale)

    case locale do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end

  @doc """
  Materializes the translations for the given locale grouped by domain.
  The map is safe to serialize and send to the client.
  """
  @spec export(String.t() | nil) :: map()
  def export(locale \\ nil)

  def export(locale) when is_binary(locale) do
    locale = normalize_locale(locale)

    locale
    |> domain_files()
    |> Enum.reduce(%{}, fn {domain, path}, acc ->
      Map.put(acc, domain, entries_for(path))
    end)
  end

  def export(_), do: export(current_locale())

  defp normalize_locale(locale) do
    locale
    |> case do
      <<>> -> current_locale()
      value -> value
    end
  end

  defp current_locale do
    Gettext.get_locale(@gettext_backend) || default_locale()
  end

  defp gettext_dir do
    otp_app = @gettext_backend.__gettext__(:otp_app)
    priv = @gettext_backend.__gettext__(:priv)
    Application.app_dir(otp_app, priv)
  end

  defp domain_files(locale) do
    pattern = Path.join([gettext_dir(), locale, "LC_MESSAGES", "*.po"])

    pattern
    |> Path.wildcard()
    |> Enum.map(fn path ->
      domain =
        path
        |> Path.basename(".po")

      {domain, path}
    end)
  end

  defp entries_for(path) do
    path
    |> PO.parse_file!(strip_meta: true)
    |> Map.fetch!(:messages)
    |> Enum.reduce(%{}, fn
      %Singular{msgid: [""], obsolete: _}, acc -> acc
      %Plural{msgid: [""], obsolete: _}, acc -> acc
      %{obsolete: true}, acc -> acc
      message, acc -> Map.put(acc, message_key(message), message_value(message))
    end)
  end

  defp message_key(%{msgid: msgid, msgctxt: context}) do
    base = IO.iodata_to_binary(msgid)

    case context do
      nil ->
        base

      [] ->
        base

      ctxt ->
        ctx = IO.iodata_to_binary(ctxt)

        if ctx == "" do
          base
        else
          ctx <> "::" <> base
        end
    end
  end

  defp message_value(%Singular{msgstr: msgstr}) do
    msgstr
    |> IO.iodata_to_binary()
  end

  defp message_value(%Plural{msgstr: msgstr}) do
    msgstr
    |> Enum.map(fn {idx, value} ->
      {Integer.to_string(idx), IO.iodata_to_binary(value)}
    end)
    |> Enum.into(%{})
  end
end
