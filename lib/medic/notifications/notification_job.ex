defmodule Medic.Notifications.NotificationJob do
  use Ash.Resource,
    domain: Medic.Notifications,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "notification_jobs"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :user_id,
        :channel,
        :template,
        :payload,
        :scheduled_at,
        :status,
        :attempts,
        :last_error,
        :idempotency_key
      ]
    end

    update :update do
      accept [
        :status,
        :attempts,
        :last_error
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :user_id, :uuid, allow_nil?: false
    attribute :channel, :string, allow_nil?: false, default: "email"
    attribute :template, :string, allow_nil?: false
    attribute :payload, :map, allow_nil?: false, default: %{}
    attribute :scheduled_at, :utc_datetime
    attribute :status, :string, allow_nil?: false, default: "pending"
    attribute :attempts, :integer, allow_nil?: false, default: 0
    attribute :last_error, :string
    attribute :idempotency_key, :string

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :user, Medic.Accounts.User do
      attribute_writable? true
      allow_nil? false
    end

    has_many :deliveries, Medic.Notifications.NotificationDelivery
  end
end
