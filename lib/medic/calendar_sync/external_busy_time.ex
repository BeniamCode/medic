defmodule Medic.CalendarSync.ExternalBusyTime do
  @moduledoc """
  Represents busy blocks synced from external calendars.
  """
  use Ash.Resource,
    domain: Medic.CalendarSync,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "external_busy_times"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :doctor_id,
        :calendar_connection_id,
        :external_id,
        :source,
        :starts_at,
        :ends_at,
        :status,
        :last_seen_at
      ]
    end

    update :update do
      accept [:starts_at, :ends_at, :status, :last_seen_at]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :external_id, :string, allow_nil?: false
    attribute :source, :string, allow_nil?: false
    attribute :starts_at, :utc_datetime, allow_nil?: false
    attribute :ends_at, :utc_datetime, allow_nil?: false
    attribute :status, :string, allow_nil?: false, default: "busy"
    attribute :last_seen_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor
    belongs_to :calendar_connection, Medic.CalendarSync.CalendarConnection
  end

  @doc false
  def changeset(busy_time, attrs) do
    busy_time
    |> cast(attrs, [
      :doctor_id,
      :calendar_connection_id,
      :external_id,
      :source,
      :starts_at,
      :ends_at,
      :status,
      :last_seen_at
    ])
    |> validate_required([
      :doctor_id,
      :calendar_connection_id,
      :external_id,
      :source,
      :starts_at,
      :ends_at
    ])
    |> validate_time_order()
    |> unique_constraint([:calendar_connection_id, :external_id])
    |> foreign_key_constraint(:doctor_id)
    |> foreign_key_constraint(:calendar_connection_id)
  end

  defp validate_time_order(changeset) do
    starts_at = get_field(changeset, :starts_at)
    ends_at = get_field(changeset, :ends_at)

    if starts_at && ends_at && DateTime.compare(starts_at, ends_at) != :lt do
      add_error(changeset, :ends_at, "must be after start time")
    else
      changeset
    end
  end
end
