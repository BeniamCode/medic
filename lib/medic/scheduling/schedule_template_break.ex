defmodule Medic.Scheduling.ScheduleTemplateBreak do
  @moduledoc """
  Structured breaks belonging to a schedule template.
  """
  use Ash.Resource,
    domain: Medic.Scheduling,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "schedule_template_breaks"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:schedule_template_id, :break_start, :break_end, :label]
    end

    update :update do
      accept [:break_start, :break_end, :label]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :break_start, :time, allow_nil?: false
    attribute :break_end, :time, allow_nil?: false
    attribute :label, :string

    timestamps(type: :utc_datetime)
  end

  relationships do
    belongs_to :schedule_template, Medic.Scheduling.ScheduleTemplate
  end

  @doc false
  def changeset(break_struct, attrs) do
    break_struct
    |> cast(attrs, [:schedule_template_id, :break_start, :break_end, :label])
    |> validate_required([:schedule_template_id, :break_start, :break_end])
    |> validate_time_order()
    |> foreign_key_constraint(:schedule_template_id)
  end

  defp validate_time_order(changeset) do
    start_time = get_field(changeset, :break_start)
    end_time = get_field(changeset, :break_end)

    if start_time && end_time && Time.compare(start_time, end_time) != :lt do
      add_error(changeset, :break_end, "must be after break start")
    else
      changeset
    end
  end
end
