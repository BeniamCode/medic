defmodule Medic.Hospitals.HospitalSchedule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "hospital_schedules" do
    field :date, :date
    field :specialties, {:array, :string}
    field :hospital_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hospital_schedule, attrs) do
    hospital_schedule
    |> cast(attrs, [:date, :specialties])
    |> validate_required([:date, :specialties])
  end
end
