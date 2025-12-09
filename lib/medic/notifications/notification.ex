defmodule Medic.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notifications" do
    field :message, :string
    field :type, :string
    field :title, :string
    field :read_at, :utc_datetime
    field :resource_id, :string
    field :resource_type, :string

    belongs_to :user, Medic.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:type, :title, :message, :read_at, :resource_id, :resource_type, :user_id])
    |> validate_required([:type, :title, :message, :user_id])
  end
end
