defmodule Medic.Appreciate.DoctorAppreciationNote do
  use Ash.Resource,
    domain: Medic.Appreciate,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "doctor_appreciation_notes"
    repo Medic.Repo

    references do
      reference :appreciation, on_delete: :delete
      reference :moderated_by, on_delete: :nilify
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:appreciation_id, :note_text, :visibility]

      change fn changeset, _ ->
        note_text = Ash.Changeset.get_attribute(changeset, :note_text)

        if is_binary(note_text) and String.length(note_text) > 80 do
          Ash.Changeset.add_error(changeset,
            field: :note_text,
            message: "Note must be 80 characters or less"
          )
        else
          changeset
        end
      end

      change set_attribute(:moderation_status, :pending)
    end

    update :moderate do
      accept [:visibility, :moderation_status, :moderated_by_id]

      change set_attribute(:moderated_at, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :note_text, :string do
      allow_nil? false
    end

    attribute :visibility, :string do
      allow_nil? false
      default "private"
      constraints max_length: 16
    end

    attribute :moderation_status, :string do
      allow_nil? false
      default "pending"
      constraints max_length: 16
    end

    attribute :moderated_at, :utc_datetime

    create_timestamp :created_at
  end

  relationships do
    belongs_to :appreciation, Medic.Appreciate.DoctorAppreciation
    belongs_to :moderated_by, Medic.Accounts.User
  end

  identities do
    identity :unique_appreciation, [:appreciation_id]
  end
end
