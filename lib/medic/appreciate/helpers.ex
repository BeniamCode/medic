defmodule Medic.Appreciate.Helpers do
  @moduledoc false

  def normalize_note_text(nil), do: nil

  def normalize_note_text(text) when is_binary(text) do
    text
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end

  def maybe_block_note?(nil), do: false

  def maybe_block_note?(text) when is_binary(text) do
    blocked = [
      ~r/\b(terrible|awful|worst|hate|scam|fraud)\b/i,
      ~r/(\bsex\b|\bporn\b|\bracist\b)/i,
      ~r/(\bf\*\*k\b|\bshit\b|\bbitch\b)/i
    ]

    Enum.any?(blocked, &Regex.match?(&1, text))
  end
end
