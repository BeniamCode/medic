defmodule Medic.Appointments.AppointmentTypeLocation do
  @moduledoc """
  Join table linking appointment types to the locations they can be booked in.
  """
  use Ash.Resource,
    domain: Medic.Appointments,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "appointment_type_locations"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:appointment_type_id, :doctor_location_id]
    end

    update :update do
      accept [:appointment_type_id, :doctor_location_id]
    end
  end

  attributes do
    uuid_primary_key :id

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :appointment_type, Medic.Appointments.AppointmentType
    belongs_to :doctor_location, Medic.Doctors.Location
  end

  @doc false
  def changeset(record, attrs) do
    record
    |> cast(attrs, [:appointment_type_id, :doctor_location_id])
    |> validate_required([:appointment_type_id, :doctor_location_id])
    |> unique_constraint([:appointment_type_id, :doctor_location_id],
      name: :appointment_type_locations_unique_scope
    )
    |> foreign_key_constraint(:appointment_type_id)
    |> foreign_key_constraint(:doctor_location_id)
  end
end
