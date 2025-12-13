defmodule Medic.Workers.AppreciationMaintenance do
  @moduledoc """
  Nightly maintenance for the appreciation system.

  - Recomputes doctor appreciation stats (total and last 30d)
  - Updates tiered achievements (Highly Appreciated)
  """

  use Oban.Worker, queue: :maintenance, max_attempts: 3

  import Ecto.Query
  require Ash.Query

  alias Medic.Repo

  alias Medic.Appreciate.{
    AchievementDefinition,
    DoctorAchievement,
    AchievementEvent,
    Service,
    DoctorAppreciation
  }

  @impl true
  def perform(_job) do
    doctor_ids = Repo.all(from a in DoctorAppreciation, select: a.doctor_id, distinct: true)

    Enum.each(doctor_ids, fn doctor_id ->
      _ = Service.refresh_doctor_appreciation_stats(doctor_id)
      _ = update_highly_appreciated_tier(doctor_id)
    end)

    :ok
  end

  defp update_highly_appreciated_tier(doctor_id) do
    definition_id =
      Repo.one(
        from d in AchievementDefinition,
          where: d.key == "highly_appreciated" and d.is_active == true,
          select: d.id
      )

    definition =
      if definition_id do
        Ash.get!(AchievementDefinition, definition_id)
      else
        nil
      end

    if is_nil(definition) do
      :ok
    else
      stats = Repo.get(Medic.Appreciate.DoctorAppreciationStat, doctor_id)
      total = (stats && stats.appreciated_total_distinct_patients) || 0

      tier =
        cond do
          total >= 300 -> 3
          total >= 100 -> 2
          total >= 25 -> 1
          true -> nil
        end

      current =
        DoctorAchievement
        |> Ash.read!()
        |> Enum.filter(fn a ->
          a.doctor_id == doctor_id and a.achievement_definition_id == definition.id
        end)

      current_tiers = MapSet.new(Enum.map(current, & &1.tier))

      desired_tiers =
        case tier do
          nil -> MapSet.new()
          1 -> MapSet.new([1])
          2 -> MapSet.new([1, 2])
          3 -> MapSet.new([1, 2, 3])
        end

      revoke = MapSet.difference(current_tiers, desired_tiers)
      earn = MapSet.difference(desired_tiers, current_tiers)

      Enum.each(revoke, fn t ->
        rec = Enum.find(current, &(&1.tier == t))

        if rec do
          {:ok, _} =
            rec
            |> Ash.Changeset.for_update(:update, %{status: "revoked"})
            |> Ash.update()

          _ =
            AchievementEvent
            |> Ash.Changeset.for_create(:create, %{
              doctor_id: doctor_id,
              achievement_definition_id: definition.id,
              action: "revoked",
              actor_type: "system",
              metadata: %{tier: t, reason: "recomputed"}
            })
            |> Ash.create()
        end
      end)

      Enum.each(earn, fn t ->
        {:ok, _} =
          DoctorAchievement
          |> Ash.Changeset.for_create(:create, %{
            doctor_id: doctor_id,
            achievement_definition_id: definition.id,
            tier: t,
            status: "earned",
            source: "system",
            metadata: %{threshold: threshold_for_tier(t)}
          })
          |> Ash.create()

        _ =
          AchievementEvent
          |> Ash.Changeset.for_create(:create, %{
            doctor_id: doctor_id,
            achievement_definition_id: definition.id,
            action: "earned",
            actor_type: "system",
            metadata: %{tier: t, reason: "recomputed"}
          })
          |> Ash.create()
      end)

      :ok
    end
  end

  defp threshold_for_tier(1), do: 25
  defp threshold_for_tier(2), do: 100
  defp threshold_for_tier(3), do: 300
end
