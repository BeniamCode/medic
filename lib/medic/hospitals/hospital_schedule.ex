defmodule Medic.Hospitals.HospitalSchedule do
  use Ash.Resource,
    domain: Medic.Hospitals,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "hospital_schedules"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:date, :specialties, :hospital_id]
    end

    update :update do
      accept [:date, :specialties, :hospital_id]
    end
  end

  attributes do
    integer_primary_key :id

    attribute :date, :date
    attribute :specialties, {:array, :string}

    timestamps()
  end

  relationships do
    belongs_to :hospital, Medic.Hospitals.Hospital do
      attribute_type :integer
    end
  end

  # --- Legacy Logic ---
  @doc false
  def changeset(hospital_schedule, attrs) do
    hospital_schedule
    |> cast(attrs, [:date, :specialties, :hospital_id])
    |> validate_required([:date, :specialties, :hospital_id])
  end
end
