defmodule Medic.Scheduling do
  @moduledoc """
  The Scheduling context - manages doctor availability and appointment slots.

  Uses Timex for timezone-safe date/time operations with Greek DST support.
  """

  use Ash.Domain

  resources do
    resource Medic.Scheduling.AvailabilityRule
  end

  import Ecto.Query
  alias Medic.Repo
  alias Medic.Scheduling.AvailabilityRule
  alias Medic.Appointments.Appointment
  alias Medic.Doctors.Doctor
  alias Medic.Notifications

  use Timex

  @timezone "Europe/Athens"

  # --- Availability Rules ---

  @doc """
  Returns all availability rules for a doctor.
  """
  def list_availability_rules(doctor_id, opts \\ []) do
    AvailabilityRule
    |> where([r], r.doctor_id == ^doctor_id)
    |> maybe_filter_active(opts)
    |> order_by([r], r.day_of_week)
    |> Repo.all()
  end

  defp maybe_filter_active(query, opts) do
    if Keyword.get(opts, :include_inactive, false) do
      query
    else
      where(query, [r], r.is_active == true)
    end
  end

  @doc """
  Gets a single availability rule.
  """
  def get_availability_rule!(id), do: Ash.get!(AvailabilityRule, id)

  @doc """
  Creates an availability rule for a doctor.
  """
  def create_availability_rule(attrs \\ %{}) do
    AvailabilityRule
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  @doc """
  Updates an availability rule.
  """
  def update_availability_rule(%AvailabilityRule{} = rule, attrs) do
    rule
    |> Ash.Changeset.for_update(:update, attrs)
    |> Ash.update()
  end

  @doc """
  Deletes an availability rule.
  """
  def delete_availability_rule(%AvailabilityRule{} = rule) do
    Ash.destroy(rule)
  end

  @doc """
  Returns an availability rule changeset.
  """
  def change_availability_rule(%AvailabilityRule{} = rule, attrs \\ %{}) do
    AvailabilityRule.changeset(rule, attrs)
  end

  # --- Slot Generation ---

  @doc """
  Gets available time slots for a doctor on a specific date.

  Returns a list of slot maps:
  [
    %{starts_at: ~U[...], ends_at: ~U[...], status: :free},
    %{starts_at: ~U[...], ends_at: ~U[...], status: :booked},
    ...
  ]

  ## Options
    * `:timezone` - The timezone to use (default: "Europe/Athens")
  """
  def get_slots(%Doctor{id: doctor_id}, date, opts \\ []) do
    timezone = Keyword.get(opts, :timezone, @timezone)
    # 1=Monday, 7=Sunday (ISO)
    day_of_week = Timex.weekday(date)

    # Get the availability rule for this day
    rule = get_rule_for_day(doctor_id, day_of_week)

    case rule do
      nil ->
        # No availability rule = no slots
        []

      rule ->
        # Generate slots from the rule
        potential_slots = generate_slots_from_rule(rule, date, timezone)

        # Get existing appointments for this doctor on this date
        booked_ranges = get_booked_ranges(doctor_id, date, timezone)

        # Mark slots as free or booked
        mark_slot_availability(potential_slots, booked_ranges)
    end
  end

  @doc """
  Gets available slots for multiple days (week view).
  """
  def get_slots_for_range(%Doctor{} = doctor, start_date, end_date, opts \\ []) do
    # Generate date range
    days = Timex.diff(end_date, start_date, :days) + 1

    0..(days - 1)
    |> Enum.map(fn offset ->
      date = Timex.shift(start_date, days: offset)

      %{
        date: date,
        slots: get_slots(doctor, date, opts)
      }
    end)
  end

  @doc """
  Books an appointment slot.

  Returns {:ok, appointment} or {:error, changeset/reason}.
  The PostgreSQL exclusion constraint will reject double-bookings.
  """
  def book_slot(doctor_id, patient_id, starts_at, ends_at, opts \\ []) do
    appointment_type = Keyword.get(opts, :appointment_type, "in_person")
    notes = Keyword.get(opts, :notes)

    Appointment
    |> Ash.Changeset.for_create(:create, %{
      doctor_id: doctor_id,
      patient_id: patient_id,
      starts_at: starts_at,
      ends_at: ends_at,
      status: "confirmed",
      appointment_type: appointment_type,
      notes: notes
    })
    |> Ash.create()
    |> case do
      {:ok, appointment} ->
        notify_doctor_booking(appointment)
        Medic.Appointments.broadcast_doctor_event(appointment.doctor_id, :refresh_dashboard)
        {:ok, appointment}

      {:error, error} ->
        # Check for exclusion constraint violation
        # AshPostgres usually wraps constraint errors.
        # For now, we'll log it and return a generic error or try to detect it.
        # A robust way is to check if the error contains the constraint name.
        
        if is_constraint_error?(error, "no_double_bookings") do
          {:error, :slot_already_booked}
        else
          # Convert Ash error to changeset for UI compatibility if possible,
          # or just return the error and let the UI handle it (though UI expects changeset).
          # For now, let's return the error and see.
          {:error, error}
        end
    end
  end

  # --- Private Functions ---

  defp get_rule_for_day(doctor_id, day_of_week) do
    AvailabilityRule
    |> where([r], r.doctor_id == ^doctor_id)
    |> where([r], r.day_of_week == ^day_of_week)
    |> where([r], r.is_active == true)
    |> Repo.one()
  end

  defp generate_slots_from_rule(rule, date, timezone) do
    slot_duration = rule.slot_duration_minutes

    # Convert rule times to datetime in the target timezone
    day_start = combine_date_time(date, rule.start_time, timezone)
    day_end = combine_date_time(date, rule.end_time, timezone)

    # Generate slot boundaries
    slot_times = generate_slot_times(day_start, day_end, slot_duration)

    # Remove slots that fall within break time
    slot_times
    |> Enum.reject(fn {starts_at, ends_at} ->
      in_break?(starts_at, ends_at, rule, date, timezone)
    end)
    |> Enum.map(fn {starts_at, ends_at} ->
      %{
        starts_at: Timex.to_datetime(starts_at, "Etc/UTC"),
        ends_at: Timex.to_datetime(ends_at, "Etc/UTC"),
        status: :free
      }
    end)
  end

  defp generate_slot_times(start_dt, end_dt, duration_minutes) do
    Stream.unfold(start_dt, fn current ->
      slot_end = Timex.shift(current, minutes: duration_minutes)

      if Timex.compare(slot_end, end_dt) <= 0 do
        {{current, slot_end}, slot_end}
      else
        nil
      end
    end)
    |> Enum.to_list()
  end

  defp combine_date_time(date, time, timezone) do
    date
    |> Timex.to_datetime(timezone)
    |> Timex.set(hour: time.hour, minute: time.minute, second: 0)
  end

  defp in_break?(starts_at, _ends_at, rule, date, timezone) do
    case {rule.break_start, rule.break_end} do
      {nil, _} ->
        false

      {_, nil} ->
        false

      {break_start, break_end} ->
        break_start_dt = combine_date_time(date, break_start, timezone)
        break_end_dt = combine_date_time(date, break_end, timezone)

        # Slot is in break if it starts during the break
        Timex.compare(starts_at, break_start_dt) >= 0 &&
          Timex.compare(starts_at, break_end_dt) < 0
    end
  end

  defp get_booked_ranges(doctor_id, date, timezone) do
    day_start = date |> Timex.to_datetime(timezone) |> Timex.beginning_of_day()
    day_end = date |> Timex.to_datetime(timezone) |> Timex.end_of_day()

    Appointment
    |> where([a], a.doctor_id == ^doctor_id)
    |> where([a], a.starts_at >= ^day_start and a.starts_at <= ^day_end)
    |> where([a], a.status in ["pending", "confirmed"])
    |> select([a], {a.starts_at, a.ends_at})
    |> Repo.all()
  end

  defp mark_slot_availability(slots, booked_ranges) do
    Enum.map(slots, fn slot ->
      if slot_overlaps_booking?(slot, booked_ranges) do
        %{slot | status: :booked}
      else
        slot
      end
    end)
  end

  defp slot_overlaps_booking?(slot, booked_ranges) do
    Enum.any?(booked_ranges, fn {booked_start, booked_end} ->
      # Two ranges overlap if one starts before the other ends
      Timex.compare(slot.starts_at, booked_end) < 0 &&
        Timex.compare(slot.ends_at, booked_start) > 0
    end)
  end

  defp notify_doctor_booking(appointment) do
    # Preload patient and doctor to get names and user_id
    appointment = Ash.load!(appointment, [:patient, :doctor])

    if appointment.doctor do
      Notifications.create_notification(%{
        user_id: appointment.doctor.user_id,
        type: "booking",
        title: "New Appointment Request",
        message:
          "Patient #{appointment.patient.first_name} #{appointment.patient.last_name} has requested an appointment.",
        resource_id: appointment.id,
        resource_type: "appointment"
      })
    end
  end

  defp is_constraint_error?(error, constraint_name) do
    # Simple check for the constraint name in the error string representation
    # This is a bit hacky but works for now until we have proper Ash exception handling
    inspect(error) =~ constraint_name
  end
end
