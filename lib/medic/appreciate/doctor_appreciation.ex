defmodule Medic.Appreciate.DoctorAppreciation do
  use Ash.Resource,
    domain: Medic.Appreciate,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "doctor_appreciations"
    repo Medic.Repo

    references do
      reference :doctor, on_delete: :delete
      reference :patient, on_delete: :delete
      reference :appointment, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :appreciate_appointment do
      primary? true

      accept [:appointment_id, :kind]

      argument :actor_patient_id, :uuid, allow_nil?: false
      argument :note_text, :string, allow_nil?: true

      change set_attribute(:patient_id, arg(:actor_patient_id))

      change fn changeset, _context ->
        appointment_id = Ash.Changeset.get_attribute(changeset, :appointment_id)
        patient_id = Ash.Changeset.get_attribute(changeset, :patient_id)

        if is_nil(appointment_id) or is_nil(patient_id) do
          changeset
        else
          changeset
          |> Ash.Changeset.before_action(fn cs ->
            appointment = Medic.Appointments.get_appointment_with_details!(appointment_id)

            cond do
              appointment.patient_id != patient_id ->
                Ash.Changeset.add_error(cs,
                  field: :appointment_id,
                  message: "You can only appreciate your own appointment"
                )

              appointment.status not in ["completed", "confirmed"] ->
                Ash.Changeset.add_error(cs,
                  field: :appointment_id,
                  message: "Appointment is not eligible for appreciation"
                )

              true ->
                cs
                |> Ash.Changeset.force_change_attribute(:doctor_id, appointment.doctor_id)
            end
          end)
        end
      end

      after_action(fn _changeset, appreciation, context ->
        note_text = context.arguments[:note_text]
        normalized_text = Medic.Appreciate.Helpers.normalize_note_text(note_text)

        if is_binary(normalized_text) and normalized_text != "" and
             not Medic.Appreciate.Helpers.maybe_block_note?(normalized_text) do
          _ =
            Medic.Appreciate.DoctorAppreciationNote
            |> Ash.Changeset.for_create(:create, %{
              appreciation_id: appreciation.id,
              note_text: normalized_text,
              visibility: "private"
            })
            |> Ash.create()
        end

        Medic.Appreciate.Service.refresh_doctor_appreciation_stats(appreciation.doctor_id)
        {:ok, appreciation}
      end)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :kind, :string do
      allow_nil? false
      default "appreciated"
      constraints max_length: 32
    end

    create_timestamp :created_at
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor
    belongs_to :patient, Medic.Patients.Patient
    belongs_to :appointment, Medic.Appointments.Appointment

    has_one :note, Medic.Appreciate.DoctorAppreciationNote do
      destination_attribute :appreciation_id
    end
  end

  identities do
    identity :unique_appointment, [:appointment_id]
  end

  postgres do
    custom_indexes do
      index [:doctor_id, :created_at], name: "doctor_appreciations_doctor_created_idx"
      index [:patient_id, :created_at], name: "doctor_appreciations_patient_created_idx"
    end
  end
end
