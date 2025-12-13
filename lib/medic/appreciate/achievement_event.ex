defmodule Medic.Appreciate.AchievementEvent do
  use Ash.Resource,
    domain: Medic.Appreciate,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "achievement_events"
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
        :action,
        :actor_type,
        :actor_id,
        :metadata,
        :occurred_at
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :action, :string do
      allow_nil? false
      constraints max_length: 32
    end

    attribute :occurred_at, :utc_datetime do
      allow_nil? false
      default &DateTime.utc_now/0
    end

    attribute :actor_type, :string do
      allow_nil? false
      default "system"
    end

    attribute :actor_id, :uuid

    attribute :metadata, :map do
      allow_nil? false
      default %{}
    end
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor

    belongs_to :achievement_definition, Medic.Appreciate.AchievementDefinition do
      source_attribute :achievement_definition_id
      destination_attribute :id
    end
  end

  postgres do
    custom_indexes do
      index [:doctor_id, :occurred_at], name: "achievement_events_doctor_idx"
    end
  end
end
