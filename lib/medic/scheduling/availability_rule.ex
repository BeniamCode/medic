defmodule Medic.Scheduling.AvailabilityRule do
  @moduledoc """
  Defines a doctor's weekly availability schedule.
  """
  use Ash.Resource,
    domain: Medic.Scheduling,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "availability_rules"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:day_of_week, :start_time, :end_time, :break_start, :break_end, :slot_duration_minutes, :is_active, :doctor_id]
    end

    update :update do
      accept [:day_of_week, :start_time, :end_time, :break_start, :break_end, :slot_duration_minutes, :is_active]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :day_of_week, :integer
    attribute :start_time, :time
    attribute :end_time, :time
    attribute :break_start, :time
    attribute :break_end, :time
    attribute :slot_duration_minutes, :integer, default: 30
    attribute :is_active, :boolean, default: true

    timestamps()
  end

  relationships do
    belongs_to :doctor, Medic.Doctors.Doctor
  end

  # --- Legacy Logic ---

  @days_of_week 1..7

  @doc false
  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [
      :doctor_id,
      :day_of_week,
      :start_time,
      :end_time,
      :break_start,
      :break_end,
      :slot_duration_minutes,
      :is_active
    ])
    |> validate_required([:doctor_id, :day_of_week, :start_time, :end_time])
    |> validate_inclusion(:day_of_week, @days_of_week, message: "must be 1-7 (Mon-Sun)")
    |> validate_number(:slot_duration_minutes, greater_than: 0, less_than_or_equal_to: 240)
    |> validate_time_order()
    |> validate_break_times()
    |> unique_constraint([:doctor_id, :day_of_week],
      name: :availability_rules_doctor_day_unique,
      message: "availability already set for this day"
    )
    |> foreign_key_constraint(:doctor_id)
  end

  defp validate_time_order(changeset) do
    start_time = get_field(changeset, :start_time)
    end_time = get_field(changeset, :end_time)

    if start_time && end_time && Time.compare(start_time, end_time) != :lt do
      add_error(changeset, :end_time, "must be after start time")
    else
      changeset
    end
  end

  defp validate_break_times(changeset) do
    break_start = get_field(changeset, :break_start)
    break_end = get_field(changeset, :break_end)

    case {break_start, break_end} do
      {nil, nil} ->
        changeset

      {nil, _} ->
        add_error(changeset, :break_start, "required when break_end is set")

      {_, nil} ->
        add_error(changeset, :break_end, "required when break_start is set")

      {start, stop} ->
        if Time.compare(start, stop) != :lt do
          add_error(changeset, :break_end, "must be after break start")
        else
          changeset
        end
    end
  end

  @doc """
  Returns the day name for a day_of_week number.
  """
  def day_name(1), do: "Monday"
  def day_name(2), do: "Tuesday"
  def day_name(3), do: "Wednesday"
  def day_name(4), do: "Thursday"
  def day_name(5), do: "Friday"
  def day_name(6), do: "Saturday"
  def day_name(7), do: "Sunday"

  @doc """
  Returns the Greek day name for a day_of_week number.
  """
  def day_name_el(1), do: "Δευτέρα"
  def day_name_el(2), do: "Τρίτη"
  def day_name_el(3), do: "Τετάρτη"
  def day_name_el(4), do: "Πέμπτη"
  def day_name_el(5), do: "Παρασκευή"
  def day_name_el(6), do: "Σάββατο"
  def day_name_el(7), do: "Κυριακή"
end
