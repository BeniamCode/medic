alias Medic.Appreciate.AchievementDefinition

# Idempotent seed of baseline achievements.
base = [
  %{
    key: "highly_appreciated",
    name: "Highly Appreciated",
    description: "Awarded based on patient appreciation over time",
    category: "patient_care",
    icon: "heart",
    is_public: true,
    is_active: true,
    is_tiered: true
  },
  %{
    key: "verified_credentials",
    name: "Verified Credentials",
    description: "Credentials verified by Medic",
    category: "trust",
    icon: "shield-check",
    is_public: true,
    is_active: true,
    is_tiered: false
  }
]

for attrs <- base do
  case Ash.create(
         Ash.Changeset.for_create(AchievementDefinition, :create, attrs)
       ) do
    {:ok, _} -> :ok
    {:error, _} -> :ok
  end
end
