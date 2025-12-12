defmodule Medic.Appointments.AppointmentEvent do
  @moduledoc """
  Append-only log capturing state changes and actions taken on appointments.
  """
  use Ash.Resource,
    domain: Medic.Appointments,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "appointment_events"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:appointment_id, :occurred_at, :actor_type, :actor_id, :action, :metadata]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :occurred_at, :utc_datetime, allow_nil?: false
    attribute :actor_type, :string
    attribute :actor_id, :uuid
    attribute :action, :string, allow_nil?: false
    attribute :metadata, :map, allow_nil?: false, default: %{}

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :appointment, Medic.Appointments.Appointment
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:appointment_id, :occurred_at, :actor_type, :actor_id, :action, :metadata])
    |> validate_required([:appointment_id, :occurred_at, :action])
    |> foreign_key_constraint(:appointment_id)
  end
end
