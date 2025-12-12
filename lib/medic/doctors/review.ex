defmodule Medic.Doctors.Review do
  use Ash.Resource,
    domain: Medic.Doctors,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "reviews"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:rating, :comment, :doctor_id, :patient_id, :appointment_id]
    end

    update :update do
      accept [:rating, :comment, :status]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :rating, :integer do
      allow_nil? false
      constraints min: 1, max: 5
    end

    attribute :comment, :string do
      allow_nil? true
    end

    attribute :status, :atom do
      constraints one_of: [:published, :hidden]
      default :published
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor
    belongs_to :patient, Medic.Patients.Patient
    belongs_to :appointment, Medic.Appointments.Appointment
  end
end
