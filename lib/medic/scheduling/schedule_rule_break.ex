defmodule Medic.Scheduling.ScheduleRuleBreak do
  @moduledoc """
  Optional recurring breaks that live inside a schedule rule window.
  """
  use Ash.Resource,
    domain: Medic.Scheduling,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "schedule_rule_breaks"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:schedule_rule_id, :break_start_local, :break_end_local, :label]
    end

    update :update do
      accept [:break_start_local, :break_end_local, :label]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :break_start_local, :time, allow_nil?: false
    attribute :break_end_local, :time, allow_nil?: false
    attribute :label, :string

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :schedule_rule, Medic.Scheduling.ScheduleRule
  end

  @doc false
  def changeset(break_struct, attrs) do
    break_struct
    |> cast(attrs, [:schedule_rule_id, :break_start_local, :break_end_local, :label])
    |> validate_required([:schedule_rule_id, :break_start_local, :break_end_local])
    |> validate_interval(:break_start_local, :break_end_local)
    |> foreign_key_constraint(:schedule_rule_id)
  end

  defp validate_interval(changeset, start_field, end_field) do
    start_time = get_field(changeset, start_field)
    end_time = get_field(changeset, end_field)

    if start_time && end_time && Time.compare(start_time, end_time) != :lt do
      add_error(changeset, end_field, "must be after #{start_field}")
    else
      changeset
    end
  end
end
