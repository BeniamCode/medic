defmodule Medic.Appreciate.DoctorAchievement do
  use Ash.Resource,
    domain: Medic.Appreciate,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "doctor_achievements"
    repo Medic.Repo

    references do
      reference :doctor, on_delete: :delete
      reference :achievement_definition, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :doctor_id,
        :achievement_definition_id,
        :status,
        :tier,
        :source,
        :metadata
      ]
    end

    update :update do
      accept [:status, :tier, :source, :metadata]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :status, :string do
      allow_nil? false
      default "earned"
      constraints max_length: 32
    end

    attribute :tier, :integer

    attribute :source, :string do
      allow_nil? false
      default "system"
      constraints max_length: 32
    end

    attribute :metadata, :map do
      allow_nil? false
      default %{}
    end

    create_timestamp :earned_at
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor

    belongs_to :achievement_definition, Medic.Appreciate.AchievementDefinition do
      source_attribute :achievement_definition_id
      destination_attribute :id
    end
  end

  identities do
    identity :unique_doctor_definition_tier, [:doctor_id, :achievement_definition_id, :tier]
  end

  postgres do
    custom_indexes do
      index [:doctor_id, :earned_at], name: "doctor_achievements_doctor_idx"
    end
  end
end
