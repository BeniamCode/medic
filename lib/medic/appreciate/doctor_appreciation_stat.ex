defmodule Medic.Appreciate.DoctorAppreciationStat do
  use Ash.Resource,
    domain: Medic.Appreciate,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "doctor_appreciation_stats"
    repo Medic.Repo

    references do
      reference :doctor, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :doctor_id,
        :appreciated_total_distinct_patients,
        :appreciated_last_30d_distinct_patients,
        :last_appreciated_at,
        :updated_at
      ]
    end

    update :update do
      primary? true

      accept [
        :appreciated_total_distinct_patients,
        :appreciated_last_30d_distinct_patients,
        :last_appreciated_at,
        :updated_at
      ]
    end
  end

  attributes do
    attribute :doctor_id, :uuid, primary_key?: true, allow_nil?: false

    attribute :appreciated_total_distinct_patients, :integer do
      allow_nil? false
      default 0
    end

    attribute :appreciated_last_30d_distinct_patients, :integer do
      allow_nil? false
      default 0
    end

    attribute :last_appreciated_at, :utc_datetime

    attribute :updated_at, :utc_datetime do
      allow_nil? false
      default &DateTime.utc_now/0
    end
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor do
      source_attribute :doctor_id
      destination_attribute :id
    end
  end
end
