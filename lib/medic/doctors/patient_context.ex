defmodule Medic.Doctors.PatientContext do
  use Ash.Resource,
    domain: Medic.Doctors,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "patient_contexts"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:doctor_id, :patient_id, :tags, :note]
    end

    update :update do
      primary? true
      accept [:tags, :note]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :tags, {:array, :string} do
      allow_nil? true
      default []
    end

    attribute :note, :string do
      allow_nil? true
      constraints [max_length: 300]
    end

    timestamps()
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor do
      allow_nil? false
    end

    belongs_to :patient, Medic.Patients.Patient do
      allow_nil? false
    end
  end

  identities do
    identity :unique_context, [:doctor_id, :patient_id]
  end
end
