defmodule Medic.Hospitals.HospitalSchedule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "hospital_schedules" do
    field :date, :date
    field :specialties, {:array, :string}
    belongs_to :hospital, Medic.Hospitals.Hospital

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hospital_schedule, attrs) do
    hospital_schedule
    |> cast(attrs, [:date, :specialties, :hospital_id])
    |> validate_required([:date, :specialties, :hospital_id])
  end
end
