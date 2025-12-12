defmodule Medic.Appointments.AppointmentResourceClaim do
  @moduledoc """
  Represents the resource assignment for an appointment. Enforced via an
  exclusion constraint so that a given resource cannot be double-booked.
  """
  use Ash.Resource,
    domain: Medic.Appointments,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "appointment_resource_claims"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:appointment_id, :bookable_resource_id, :starts_at, :ends_at, :status]
    end

    update :update do
      accept [:status]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :appointment_id, :uuid, allow_nil?: false
    attribute :bookable_resource_id, :uuid, allow_nil?: false
    attribute :starts_at, :utc_datetime, allow_nil?: false
    attribute :ends_at, :utc_datetime, allow_nil?: false
    attribute :status, :string, allow_nil?: false, default: "active"

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :appointment, Medic.Appointments.Appointment

    belongs_to :bookable_resource, Medic.Scheduling.BookableResource
  end

  @statuses ~w(active released cancelled)

  @doc false
  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:appointment_id, :bookable_resource_id, :starts_at, :ends_at, :status])
    |> validate_required([:appointment_id, :bookable_resource_id, :starts_at, :ends_at])
    |> validate_inclusion(:status, @statuses)
    |> validate_time_order()
    |> foreign_key_constraint(:appointment_id)
    |> foreign_key_constraint(:bookable_resource_id)
  end

  defp validate_time_order(changeset) do
    starts_at = get_field(changeset, :starts_at)
    ends_at = get_field(changeset, :ends_at)

    if starts_at && ends_at && DateTime.compare(starts_at, ends_at) != :lt do
      add_error(changeset, :ends_at, "must be after starts_at")
    else
      changeset
    end
  end
end
