defmodule Medic.Scheduling.Validations.EffectiveRange do
  use Ash.Resource.Validation

  @impl true
  def validate(changeset, _opts, _context) do
    from = Ash.Changeset.get_attribute(changeset, :effective_from)
    to = Ash.Changeset.get_attribute(changeset, :effective_to)

    cond do
      is_nil(from) or is_nil(to) ->
        :ok

      Date.compare(to, from) in [:eq, :gt] ->
        :ok

      true ->
        {:error, field: :effective_to, message: "effective_to must be on/after effective_from"}
    end
  end
end
