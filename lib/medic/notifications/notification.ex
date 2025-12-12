defmodule Medic.Notifications.Notification do
  use Ash.Resource,
    domain: Medic.Notifications,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "notifications"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :type,
        :title,
        :message,
        :read_at,
        :resource_id,
        :resource_type,
        :user_id,
        :channel,
        :template,
        :payload,
        :sent_at,
        :provider_message_id,
        :error_reason
      ]
    end

    update :update do
      accept [
        :type,
        :title,
        :message,
        :read_at,
        :resource_id,
        :resource_type,
        :user_id,
        :channel,
        :template,
        :payload,
        :sent_at,
        :provider_message_id,
        :error_reason
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :message, :string, allow_nil?: false
    attribute :type, :string, allow_nil?: false
    attribute :title, :string, allow_nil?: false
    attribute :read_at, :utc_datetime
    attribute :resource_id, :string
    attribute :resource_type, :string
    attribute :channel, :string, default: "email"
    attribute :template, :string
    attribute :payload, :map, default: %{}
    attribute :sent_at, :utc_datetime
    attribute :provider_message_id, :string
    attribute :error_reason, :string

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :user, Medic.Accounts.User do
      attribute_writable? true
      allow_nil? false
    end
  end

  # --- Legacy Logic ---
  import Ecto.Changeset
  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [
      :type,
      :title,
      :message,
      :read_at,
      :resource_id,
      :resource_type,
      :user_id,
      :channel,
      :template,
      :payload,
      :sent_at,
      :provider_message_id,
      :error_reason
    ])
    |> validate_required([:type, :title, :message, :user_id])
    |> validate_inclusion(:channel, ~w(email sms push))
  end
end
