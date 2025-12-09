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
      accept [:type, :title, :message, :read_at, :resource_id, :resource_type, :user_id]
    end

    update :update do
      accept [:type, :title, :message, :read_at, :resource_id, :resource_type, :user_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :message, :string
    attribute :type, :string
    attribute :title, :string
    attribute :read_at, :utc_datetime
    attribute :resource_id, :string
    attribute :resource_type, :string

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :user, Medic.Accounts.User
  end

  # --- Legacy Logic ---
  import Ecto.Changeset
  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:type, :title, :message, :read_at, :resource_id, :resource_type, :user_id])
    |> validate_required([:type, :title, :message, :user_id])
  end
end
