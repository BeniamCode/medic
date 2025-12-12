defmodule Medic.CalendarSync.CalendarConnection do
  @moduledoc """
  Stores OAuth credentials for syncing with third-party calendars.
  """
  use Ash.Resource,
    domain: Medic.CalendarSync,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "calendar_connections"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :doctor_id,
        :provider,
        :access_token,
        :refresh_token,
        :expires_at,
        :scopes,
        :sync_cursor,
        :last_synced_at,
        :status
      ]
    end

    update :update do
      accept [
        :access_token,
        :refresh_token,
        :expires_at,
        :scopes,
        :sync_cursor,
        :last_synced_at,
        :status
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :provider, :string, allow_nil?: false
    attribute :access_token, :string
    attribute :refresh_token, :string
    attribute :expires_at, :utc_datetime
    attribute :scopes, {:array, :string}, allow_nil?: false, default: []
    attribute :sync_cursor, :string
    attribute :last_synced_at, :utc_datetime
    attribute :status, :string, allow_nil?: false, default: "active"

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor
    has_many :external_busy_times, Medic.CalendarSync.ExternalBusyTime
  end

  @providers ~w(google)

  @doc false
  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [
      :doctor_id,
      :provider,
      :access_token,
      :refresh_token,
      :expires_at,
      :scopes,
      :sync_cursor,
      :last_synced_at,
      :status
    ])
    |> validate_required([:doctor_id, :provider])
    |> validate_inclusion(:provider, @providers)
    |> foreign_key_constraint(:doctor_id)
    |> unique_constraint([:doctor_id, :provider])
  end
end
