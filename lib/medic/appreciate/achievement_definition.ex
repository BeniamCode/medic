defmodule Medic.Appreciate.AchievementDefinition do
  use Ash.Resource,
    domain: Medic.Appreciate,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "achievement_definitions"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :key,
        :name,
        :description,
        :category,
        :icon,
        :is_public,
        :is_active,
        :is_tiered
      ]
    end

    update :update do
      accept [
        :name,
        :description,
        :category,
        :icon,
        :is_public,
        :is_active,
        :is_tiered
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :key, :string, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    attribute :description, :string

    attribute :category, :string do
      allow_nil? false
      constraints max_length: 64
    end

    attribute :icon, :string

    attribute :is_public, :boolean do
      allow_nil? false
      default true
    end

    attribute :is_active, :boolean do
      allow_nil? false
      default true
    end

    attribute :is_tiered, :boolean do
      allow_nil? false
      default false
    end

    timestamps()
  end

  identities do
    identity :unique_key, [:key]
  end

  postgres do
    custom_indexes do
      index [:is_active, :category], name: "achievement_definitions_active_idx"
    end
  end
end
