defmodule Medic.Notifications.NotificationDelivery do
  use Ash.Resource,
    domain: Medic.Notifications,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "notification_deliveries"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :notification_job_id,
        :channel,
        :provider,
        :provider_message_id,
        :attempted_at,
        :status,
        :response,
        :error
      ]
    end

    update :update do
      accept [
        :provider_message_id,
        :status,
        :response,
        :error
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :channel, :string, allow_nil?: false, default: "email"
    attribute :provider, :string
    attribute :provider_message_id, :string
    attribute :attempted_at, :utc_datetime
    attribute :status, :string, allow_nil?: false, default: "pending"
    attribute :response, :map, allow_nil?: false, default: %{}
    attribute :error, :string

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :notification_job, Medic.Notifications.NotificationJob do
      attribute_writable? true
      allow_nil? false
    end
  end
end
