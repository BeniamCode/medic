defmodule Medic.Appreciate.Service do
  @moduledoc """
  Service functions for the appreciation system.

  Keeps write-side logic in one place so controllers and jobs stay small.
  """

  import Ecto.Query
  alias Medic.Repo

  alias Medic.Appreciate.{
    DoctorAppreciation,
    DoctorAppreciationNote,
    DoctorAppreciationStat,
    Helpers
  }

  def appreciate_appointment(%{appointment_id: appointment_id, patient_id: patient_id} = attrs) do
    Repo.transaction(fn ->
      with {:ok, appreciation} <-
             DoctorAppreciation
             |> Ash.Changeset.for_create(
               :appreciate_appointment,
               %{
                 appointment_id: appointment_id,
                 kind: Map.get(attrs, :kind, "appreciated"),
                 actor_patient_id: patient_id
               }
             )
             |> Ash.create(),
           {:ok, _maybe_note} <- maybe_create_note(appreciation, Map.get(attrs, :note_text)) do
        {:ok, appreciation}
      else
        {:error, error} -> Repo.rollback(error)
      end
    end)
  end

  defp maybe_create_note(_appreciation, nil), do: {:ok, nil}

  defp maybe_create_note(appreciation, note_text) when is_binary(note_text) do
    note_text = Helpers.normalize_note_text(note_text)

    cond do
      is_nil(note_text) or note_text == "" ->
        {:ok, nil}

      Helpers.maybe_block_note?(note_text) ->
        {:ok, nil}

      true ->
        DoctorAppreciationNote
        |> Ash.Changeset.for_create(:create, %{
          appreciation_id: appreciation.id,
          note_text: note_text,
          visibility: "private"
        })
        |> Ash.create()
    end
  end

  def refresh_doctor_appreciation_stats(doctor_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    since = DateTime.add(now, -30, :day)

    total_distinct_patients =
      Repo.one!(
        from a in DoctorAppreciation,
          where: a.doctor_id == ^doctor_id,
          select: count(fragment("distinct ?", a.patient_id))
      )

    last_30d_distinct_patients =
      Repo.one!(
        from a in DoctorAppreciation,
          where: a.doctor_id == ^doctor_id and a.created_at >= ^since,
          select: count(fragment("distinct ?", a.patient_id))
      )

    last_appreciated_at =
      Repo.one(
        from a in DoctorAppreciation,
          where: a.doctor_id == ^doctor_id,
          order_by: [desc: a.created_at],
          limit: 1,
          select: a.created_at
      )

    stat = Repo.get(DoctorAppreciationStat, doctor_id)

    attrs = %{
      appreciated_total_distinct_patients: total_distinct_patients,
      appreciated_last_30d_distinct_patients: last_30d_distinct_patients,
      last_appreciated_at: last_appreciated_at,
      updated_at: now
    }

    case stat do
      nil ->
        DoctorAppreciationStat
        |> Ash.Changeset.for_create(:create, Map.put(attrs, :doctor_id, doctor_id))
        |> Ash.create()

      %DoctorAppreciationStat{} = stat ->
        stat
        |> Ash.Changeset.for_update(:update, attrs)
        |> Ash.update()
    end
  end
end
