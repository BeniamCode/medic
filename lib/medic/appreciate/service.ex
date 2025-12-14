defmodule Medic.Appreciate.Service do
  @moduledoc """
  Service functions for the appreciation system.

  Keeps write-side logic in one place so controllers and jobs stay small.
  """

  import Ecto.Query
  alias Medic.Repo

  alias Medic.Doctors
  alias Medic.Doctors.Doctor

  alias Medic.Appreciate.{
    DoctorAppreciation,
    DoctorAppreciationStat
  }

  def appreciate_appointment(%{appointment_id: appointment_id, patient_id: patient_id} = attrs) do
    DoctorAppreciation
    |> Ash.Changeset.for_create(
      :appreciate_appointment,
      %{
        appointment_id: appointment_id,
        kind: Map.get(attrs, :kind, "appreciated"),
        actor_patient_id: patient_id,
        note_text: Map.get(attrs, :note_text)
      }
    )
    |> Ash.create()
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

    result =
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

    _ =
      case result do
        {:ok, _} -> Doctors.enqueue_index_job(%Doctor{id: doctor_id})
        _ -> :ok
      end

    result
  end
end
