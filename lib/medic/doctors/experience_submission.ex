defmodule Medic.Doctors.ExperienceSubmission do
  use Ash.Resource,
    domain: Medic.Doctors,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "experience_submissions"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [
        :communication_style,
        :explanation_style,
        :personality_tone,
        :pace,
        :appointment_timing,
        :consultation_style,
        :doctor_id,
        :patient_id,
        :appointment_id
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :communication_style, :integer do
      allow_nil? false
      constraints min: 0, max: 100
    end
    
    attribute :explanation_style, :integer do
       allow_nil? false
       constraints min: 0, max: 100
    end

    attribute :personality_tone, :integer do
       allow_nil? false
       constraints min: 0, max: 100
    end

    attribute :pace, :integer do
       allow_nil? false
       constraints min: 0, max: 100
    end

    attribute :appointment_timing, :integer do
       allow_nil? false
       constraints min: 0, max: 100
    end

    attribute :consultation_style, :integer do
       allow_nil? false
       constraints min: 0, max: 100
    end
    
    timestamps()
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor
    belongs_to :patient, Medic.Patients.Patient
    belongs_to :appointment, Medic.Appointments.Appointment
  end
end
