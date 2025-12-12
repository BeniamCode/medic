defmodule Medic.Scheduling.TimeOffRequest do
  @moduledoc """
  Tracks doctor-submitted time off that blocks availability once approved.
  """
  use Ash.Resource,
    domain: Medic.Scheduling,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "time_off_requests"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:doctor_id, :starts_at, :ends_at, :status, :reason, :notes, :approved_by_id]
    end

    update :update do
      accept [:starts_at, :ends_at, :status, :reason, :notes, :approved_by_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :starts_at, :utc_datetime, allow_nil?: false
    attribute :ends_at, :utc_datetime, allow_nil?: false
    attribute :status, :string, allow_nil?: false, default: "pending"
    attribute :reason, :string
    attribute :notes, :string

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor
    belongs_to :approved_by, Medic.Accounts.User
  end

  @statuses ~w(pending approved denied)

  @doc false
  def changeset(request, attrs) do
    request
    |> cast(attrs, [:doctor_id, :starts_at, :ends_at, :status, :reason, :notes, :approved_by_id])
    |> validate_required([:doctor_id, :starts_at, :ends_at])
    |> validate_inclusion(:status, @statuses)
    |> validate_time_order()
    |> foreign_key_constraint(:doctor_id)
    |> foreign_key_constraint(:approved_by_id)
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
