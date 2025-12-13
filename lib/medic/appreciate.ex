defmodule Medic.Appreciate do
  @moduledoc """
  Positive-only Appreciation system.

  This domain stores patient-to-doctor appreciation events tied to appointments,
  plus a small achievements/badges layer.
  """

  use Ash.Domain

  resources do
    resource Medic.Appreciate.DoctorAppreciation
    resource Medic.Appreciate.DoctorAppreciationNote
    resource Medic.Appreciate.DoctorAppreciationStat
    resource Medic.Appreciate.AchievementDefinition
    resource Medic.Appreciate.DoctorAchievement
    resource Medic.Appreciate.AchievementEvent
  end
end
