defmodule Medic.Scheduling do
  @moduledoc """
  The Scheduling context - manages doctor availability and appointment slots.

  Uses Timex for timezone-safe date/time operations with Greek DST support.
  """

  use Ash.Domain

  resources do
    resource Medic.Scheduling.AvailabilityRule
    resource Medic.Scheduling.ScheduleTemplate
    resource Medic.Scheduling.ScheduleTemplateBreak
    resource Medic.Scheduling.AvailabilityException
    resource Medic.Scheduling.TimeOffRequest
    resource Medic.Scheduling.BookableResource
    resource Medic.Scheduling.ScheduleRule
    resource Medic.Scheduling.ScheduleRuleBreak
    resource Medic.Scheduling.ScheduleException
  end

  import Ecto.Query
  alias Medic.Repo

  alias Medic.Scheduling.{
    AvailabilityRule,
    AvailabilityException,
    ScheduleException,
    ScheduleRule,
    ScheduleRuleBreak,
    ScheduleTemplate,
    ScheduleTemplateBreak,
    TimeOffRequest
  }

  alias Medic.Appointments.Appointment
  alias Medic.Doctors.Doctor
  alias Medic.Notifications
  require Ash.Query

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

  defp schedule_rule_for_day_map(doctor_id, day_of_week) do
    case find_schedule_rule_for_day(doctor_id, day_of_week) do
      nil -> nil
      rule -> schedule_rule_to_virtual_rule(rule)
    end
  end

  defp schedule_rule_to_virtual_rule(%ScheduleRule{} = rule) do
    rule = Ash.load!(rule, :breaks)
    break = List.first(rule.breaks || [])

    %{
      day_of_week: rule.day_of_week,
      start_time: rule.work_start_local,
      end_time: rule.work_end_local,
      break_start: break && break.break_start_local,
      break_end: break && break.break_end_local,
      slot_duration_minutes: rule.slot_interval_minutes,
      timezone: rule.timezone
    }
  end

  defp availability_rule_map(doctor_id, day_of_week) do
    AvailabilityRule
    |> where([r], r.doctor_id == ^doctor_id)
    |> where([r], r.day_of_week == ^day_of_week)
    |> where([r], r.is_active == true)
    |> Repo.one()
    |> case do
      nil ->
        nil

      rule ->
        %{
          day_of_week: rule.day_of_week,
          start_time: rule.start_time,
          end_time: rule.end_time,
          break_start: rule.break_start,
          break_end: rule.break_end,
          slot_duration_minutes: rule.slot_duration_minutes,
          timezone: @timezone
        }
    end
  end

  # --- Schedule Rules (canonical engine) ---

  @doc """
  Returns schedule rules formatted for the legacy UI. Falls back to
  availability rules if no schedule rules exist yet.
  """
  def list_schedule_rules_for_ui(doctor_id) do
    schedule_rules =
      ScheduleRule
      |> Ash.Query.filter(doctor_id == ^doctor_id)
      |> Ash.Query.load(:breaks)
      |> Ash.Query.sort(:day_of_week)
      |> Ash.read!()

    if Enum.empty?(schedule_rules) do
      list_availability_rules(doctor_id, include_inactive: true)
      |> Enum.map(&legacy_rule_to_ui/1)
    else
      Enum.map(schedule_rules, &schedule_rule_to_ui/1)
    end
  end

  @doc """
  Creates or updates a schedule rule based on the UI payload.
  Passing `is_active: false` removes the rule for that weekday.
  """
  def upsert_schedule_rule(doctor_id, attrs) when is_map(attrs) do
    attrs = Map.new(attrs)

    if truthy?(Map.get(attrs, :is_active, true)) do
      with {:ok, rule} <- persist_schedule_rule(doctor_id, attrs),
           {:ok, _} <- sync_rule_breaks(rule, attrs[:break_start], attrs[:break_end]) do
        {:ok, rule}
      end
    else
      delete_schedule_rule(doctor_id, attrs)
    end
  end

  @doc """
  Deletes a schedule rule by id (or attributes containing id/day_of_week).
  """
  def delete_schedule_rule(doctor_id, %{id: id}) when not is_nil(id),
    do: delete_schedule_rule(doctor_id, id)

  def delete_schedule_rule(doctor_id, %{day_of_week: day}) when not is_nil(day) do
    case find_schedule_rule_for_day(doctor_id, day) do
      nil -> {:ok, :noop}
      %ScheduleRule{} = rule -> destroy_schedule_rule(rule)
    end
  end

  def delete_schedule_rule(doctor_id, id) when is_binary(id) do
    with {:ok, %ScheduleRule{} = rule} <- get_schedule_rule(doctor_id, id) do
      destroy_schedule_rule(rule)
    end
  end

  def delete_schedule_rule(_doctor_id, _attrs), do: {:ok, :noop}

  @doc """
  Creates a schedule exception (new override engine).
  """
  def create_schedule_exception(attrs) do
    ScheduleException
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  defp schedule_rule_to_ui(%ScheduleRule{} = rule) do
    rule = Ash.load!(rule, :breaks)
    break = List.first(rule.breaks || [])

    %{
      id: rule.id,
      day_of_week: rule.day_of_week,
      start_time: rule.work_start_local,
      end_time: rule.work_end_local,
      break_start: break && break.break_start_local,
      break_end: break && break.break_end_local,
      breaks: rule.breaks || [],
      slot_duration_minutes: rule.slot_interval_minutes,
      is_active: true,
      timezone: rule.timezone
    }
  end

  defp legacy_rule_to_ui(%AvailabilityRule{} = rule) do
    %{
      id: rule.id,
      day_of_week: rule.day_of_week,
      start_time: rule.start_time,
      end_time: rule.end_time,
      break_start: rule.break_start,
      break_end: rule.break_end,
      slot_duration_minutes: rule.slot_duration_minutes,
      is_active: rule.is_active,
      timezone: @timezone
    }
  end

  defp persist_schedule_rule(doctor_id, attrs) do
    data = %{
      timezone: Map.get(attrs, :timezone, @timezone),
      day_of_week: attrs[:day_of_week],
      work_start_local: attrs[:start_time],
      work_end_local: attrs[:end_time],
      slot_interval_minutes: attrs[:slot_duration_minutes] || 30,
      buffer_before_minutes: 0,
      buffer_after_minutes: 0,
      priority: 0
    }

    case find_schedule_rule_for_upsert(doctor_id, attrs) do
      nil ->
        ScheduleRule
        |> Ash.Changeset.for_create(:create, Map.put(data, :doctor_id, doctor_id))
        |> Ash.create()

      %ScheduleRule{} = rule ->
        rule
        |> Ash.Changeset.for_update(:update, Map.drop(data, [:day_of_week]))
        |> Ash.update()
    end
  end

  defp sync_rule_breaks(rule, nil, nil) do
    rule
    |> Ash.load!(:breaks)
    |> Map.get(:breaks, [])
    |> Enum.each(&Ash.destroy/1)

    {:ok, rule}
  end

  defp sync_rule_breaks(rule, break_start, break_end) do
    rule = Ash.load!(rule, :breaks)
    payload = %{break_start_local: break_start, break_end_local: break_end}

    case rule.breaks do
      [existing | _] ->
        existing
        |> Ash.Changeset.for_update(:update, payload)
        |> Ash.update()

      _ ->
        ScheduleRuleBreak
        |> Ash.Changeset.for_create(:create, Map.put(payload, :schedule_rule_id, rule.id))
        |> Ash.create()
    end
  end

  defp find_schedule_rule_for_upsert(doctor_id, attrs) do
    cond do
      attrs[:id] ->
        case get_schedule_rule(doctor_id, attrs[:id]) do
          {:ok, rule} -> rule
          _ -> nil
        end

      attrs[:day_of_week] ->
        find_schedule_rule_for_day(doctor_id, attrs[:day_of_week])

      true ->
        nil
    end
  end

  defp get_schedule_rule(doctor_id, id) do
    case Ash.get(ScheduleRule, id) do
      {:ok, %ScheduleRule{doctor_id: ^doctor_id} = rule} -> {:ok, rule}
      {:ok, _} -> {:error, :forbidden}
      {:error, reason} -> {:error, reason}
    end
  rescue
    _ -> {:error, :not_found}
  end

  defp find_schedule_rule_for_day(doctor_id, day_of_week) do
    ScheduleRule
    |> Ash.Query.filter(doctor_id == ^doctor_id and day_of_week == ^day_of_week)
    |> Ash.Query.sort(:priority)
    |> Ash.Query.limit(1)
    |> Ash.Query.load(:breaks)
    |> Ash.read!()
    |> List.first()
  end

  defp destroy_schedule_rule(rule) do
    rule
    |> Ash.load!(:breaks)
    |> Map.get(:breaks, [])
    |> Enum.each(&Ash.destroy/1)

    Ash.destroy(rule)
  end

  defp truthy?(value), do: value not in [false, "false", 0, "0", nil]

  @doc """
  Returns an availability rule changeset.
  """
  def change_availability_rule(%AvailabilityRule{} = rule, attrs \\ %{}) do
    AvailabilityRule.changeset(rule, attrs)
  end

  # --- Schedule Templates ---

  def list_schedule_templates(doctor_id) do
    ScheduleTemplate
    |> Ash.Query.filter(doctor_id == ^doctor_id)
    |> Ash.Query.load(:breaks)
    |> Ash.read!()
  end

  def create_schedule_template(attrs) do
    ScheduleTemplate
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def update_schedule_template(%ScheduleTemplate{} = template, attrs) do
    template
    |> Ash.Changeset.for_update(:update, attrs)
    |> Ash.update()
  end

  def delete_schedule_template(%ScheduleTemplate{} = template), do: Ash.destroy(template)

  def add_template_break(attrs) do
    ScheduleTemplateBreak
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def delete_template_break(%ScheduleTemplateBreak{} = break_struct),
    do: Ash.destroy(break_struct)

  # --- Exceptions & Time Off ---

  def list_availability_exceptions(doctor_id, opts \\ []) do
    query = Ash.Query.filter(AvailabilityException, doctor_id == ^doctor_id)

    query =
      case Keyword.get(opts, :upcoming_only, false) do
        true ->
          now = DateTime.utc_now()
          Ash.Query.filter(query, ends_at >= ^now)

        _ ->
          query
      end

    Ash.read!(query)
  end

  def get_availability_exception(id), do: Ash.get(AvailabilityException, id)

  def create_availability_exception(attrs) do
    AvailabilityException
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def update_availability_exception(%AvailabilityException{} = exception, attrs) do
    exception
    |> Ash.Changeset.for_update(:update, attrs)
    |> Ash.update()
  end

  def delete_availability_exception(%AvailabilityException{} = exception),
    do: Ash.destroy(exception)

  def list_time_off_requests(doctor_id) do
    TimeOffRequest
    |> Ash.Query.filter(doctor_id == ^doctor_id)
    |> Ash.read!()
  end

  def request_time_off(attrs) do
    TimeOffRequest
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def update_time_off_request(%TimeOffRequest{} = request, attrs) do
    request
    |> Ash.Changeset.for_update(:update, attrs)
    |> Ash.update()
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
        rule_timezone = Map.get(rule, :timezone, timezone)

        # Generate slots from the rule
        potential_slots = generate_slots_from_rule(rule, date, rule_timezone)

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
    consultation_mode =
      Keyword.get(opts, :consultation_mode) ||
        Keyword.get(opts, :appointment_type) ||
        "in_person"

    notes = Keyword.get(opts, :notes)

    Appointment
    |> Ash.Changeset.for_create(:create, %{
      doctor_id: doctor_id,
      patient_id: patient_id,
      starts_at: starts_at,
      ends_at: ends_at,
      status: "confirmed",
      consultation_mode_snapshot: consultation_mode,
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
    schedule_rule_for_day_map(doctor_id, day_of_week) ||
      availability_rule_map(doctor_id, day_of_week)
  end

  defp generate_slots_from_rule(rule, date, timezone) do
    slot_duration = Map.get(rule, :slot_duration_minutes, 30)
    start_time = Map.get(rule, :start_time)
    end_time = Map.get(rule, :end_time)

    if is_nil(start_time) or is_nil(end_time) do
      []
    else
      # Convert rule times to datetime in the target timezone
      day_start = combine_date_time(date, start_time, timezone)
      day_end = combine_date_time(date, end_time, timezone)

      # Generate slot boundaries
      slot_times = generate_slot_times(day_start, day_end, slot_duration)

      # Remove slots that fall within break time
      slot_times
      |> Enum.reject(fn {starts_at, _ends_at} ->
        in_break?(starts_at, rule, date, timezone)
      end)
      |> Enum.map(fn {starts_at, ends_at} ->
        %{
          starts_at: Timex.to_datetime(starts_at, "Etc/UTC"),
          ends_at: Timex.to_datetime(ends_at, "Etc/UTC"),
          status: :free
        }
      end)
    end
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

  defp in_break?(starts_at, rule, date, timezone) do
    case {Map.get(rule, :break_start), Map.get(rule, :break_end)} do
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

    appointments =
      Appointment
      |> where([a], a.doctor_id == ^doctor_id)
      |> where([a], a.starts_at >= ^day_start and a.starts_at <= ^day_end)
      |> where([a], a.status in ["pending", "confirmed"])
      |> select([a], {a.starts_at, a.ends_at})
      |> Repo.all()

    exceptions =
      AvailabilityException
      |> where([e], e.doctor_id == ^doctor_id)
      |> where([e], e.starts_at <= ^day_end and e.ends_at >= ^day_start)
      |> select([e], {e.starts_at, e.ends_at})
      |> Repo.all()

    appointments ++ exceptions
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
  # ---------- BULK UPSERT ----------

  def bulk_upsert_schedule_rules!(doctor_id, payload) do
    Repo.transaction(fn ->
      scope = normalize_scope!(payload["scope"] || %{})
      replace_mode = parse_replace_mode(payload["replaceMode"] || "replace_selected_days")

      days =
        payload["days"]
        |> List.wrap()
        |> Enum.filter(&(&1["enabled"] == true))

      selected_dows = Enum.map(days, & &1["dayOfWeek"])

      cond do
        replace_mode == :reset_all ->
          # Delete ALL rules for the doctor regardless of days or scope
          delete_all_rules_for_doctor!(doctor_id)

        replace_mode == :replace_selected_days ->
          delete_rules_for_scope_and_days!(doctor_id, scope, selected_dows)
        
        true -> 
          :ok
      end

      # Insert new rules + breaks (only if any provided)
      inserted =
        for day <- days,
            window <- List.wrap(day["windows"]),
            do: create_rule_with_breaks!(doctor_id, scope, day["dayOfWeek"], window)

      %{inserted_rules: length(inserted), deleted_days: selected_dows}
    end)
    |> case do
      {:ok, result} -> result
      {:error, reason} -> raise reason
    end
  end

  defp delete_all_rules_for_doctor!(doctor_id) do
    ScheduleRule
    |> Ash.Query.filter(doctor_id == ^doctor_id)
    |> Ash.read!()
    |> Enum.each(&destroy_schedule_rule/1) 
  end

  defp delete_rules_for_scope_and_days!(doctor_id, scope, dows) do
    # Fetch matching rules then destroy via Ash (so breaks cascade properly).
    query =
      ScheduleRule
      |> Ash.Query.filter(doctor_id == ^doctor_id and day_of_week in ^dows)
      |> apply_scope_filter(scope)

    rules = Ash.read!(query)

    Enum.each(rules, &destroy_schedule_rule/1)
  end

  defp create_rule_with_breaks!(doctor_id, scope, dow, window) do
    breaks =
      window["breaks"]
      |> List.wrap()
      |> Enum.map(fn b ->
        %{
          break_start_local: parse_time!(b["breakStartLocal"]),
          break_end_local: parse_time!(b["breakEndLocal"]),
          label: b["label"]
        }
      end)

    attrs = %{
      doctor_id: doctor_id,
      timezone: scope.timezone,

      scope_appointment_type_id: scope.appointment_type_id,
      scope_doctor_location_id: scope.doctor_location_id,
      scope_location_room_id: scope.location_room_id,
      scope_consultation_mode: scope.consultation_mode,

      day_of_week: dow,
      work_start_local: parse_time!(window["workStartLocal"]),
      work_end_local: parse_time!(window["workEndLocal"]),
      slot_interval_minutes: window["slotIntervalMinutes"] || 10,
      priority: window["priority"] || 0,
      effective_from: parse_date_maybe(window["effectiveFrom"]),
      effective_to: parse_date_maybe(window["effectiveTo"]),
      is_active: true,
      breaks: breaks
    }

    Ash.create!(ScheduleRule, attrs, action: :create_with_breaks)
  end

  # ---------- PREVIEW ----------

  def preview_slots(_doctor_id, payload) do
    scope = normalize_scope!(payload["scope"] || %{})

    days =
      payload["days"]
      |> List.wrap()
      |> Enum.filter(&(&1["enabled"] == true))

    %{"start" => start_s, "end" => end_s} = payload["dateRange"] || %{}
    start_date = Date.from_iso8601!(start_s)
    end_date   = Date.from_iso8601!(end_s)

    date_list = Date.range(start_date, end_date) |> Enum.to_list()

    preview =
      for date <- date_list,
          dow = iso_dow(date),
          day <- days,
          day["dayOfWeek"] == dow,
          window <- List.wrap(day["windows"]) do
        build_preview_for_window(scope.timezone, date, window)
      end
      |> List.flatten()

    total = length(preview)

    %{
      summary: %{totalSlots: total, daysEnabled: length(days)},
      slots: preview
    }
  end

  defp build_preview_for_window(tz, date, window) do
    work_start = parse_time!(window["workStartLocal"])
    work_end   = parse_time!(window["workEndLocal"])
    interval   = window["slotIntervalMinutes"] || 10

    {:ok, ws_utc} = local_to_utc(date, work_start, tz)
    {:ok, we_utc} = local_to_utc(date, work_end, tz)

    # subtract breaks
    breaks =
      window["breaks"]
      |> List.wrap()
      |> Enum.map(fn b ->
        bs = parse_time!(b["breakStartLocal"])
        be = parse_time!(b["breakEndLocal"])
        {:ok, bs_utc} = local_to_utc(date, bs, tz)
        {:ok, be_utc} = local_to_utc(date, be, tz)
        {bs_utc, be_utc}
      end)

    intervals =
      [{ws_utc, we_utc}]
      |> subtract_breaks(breaks)

    # slice into slot starts (preview only)
    for {a, b} <- intervals,
        slot <- slice_interval(a, b, interval),
        do: slot
  end

  defp slice_interval(a_utc, b_utc, interval_minutes) do
    step = interval_minutes * 60

    Stream.unfold(a_utc, fn current ->
      next = DateTime.add(current, step, :second)
      if DateTime.compare(next, b_utc) in [:lt, :eq] do
        slot = %{startUtc: current, endUtc: next}
        {slot, next}
      else
        nil
      end
    end)
    |> Enum.to_list()
  end

  defp subtract_breaks(intervals, breaks) do
    Enum.reduce(breaks, intervals, fn {bs, be}, acc ->
      Enum.flat_map(acc, fn {a, b} ->
        cond do
          DateTime.compare(be, a) != :gt -> [{a, b}]   # break ends before interval starts
          DateTime.compare(bs, b) != :lt -> [{a, b}]   # break starts after interval ends
          DateTime.compare(bs, a) == :gt and DateTime.compare(be, b) == :lt ->
            [{a, bs}, {be, b}]
          DateTime.compare(bs, a) != :gt and DateTime.compare(be, b) == :lt ->
            [{be, b}]
          DateTime.compare(bs, a) == :gt and DateTime.compare(be, b) != :lt ->
            [{a, bs}]
          true ->
            [] # break covers whole interval
        end
      end)
    end)
    |> Enum.filter(fn {a, b} -> DateTime.compare(b, a) == :gt end)
  end

  # ---------- Helpers ----------

  defp normalize_scope!(%{} = s) do
    %{
      timezone: s["timezone"] || "Europe/Athens",
      appointment_type_id: blank_to_nil(s["appointmentTypeId"]),
      doctor_location_id: blank_to_nil(s["doctorLocationId"]),
      location_room_id: blank_to_nil(s["locationRoomId"]),
      consultation_mode: parse_mode(blank_to_nil(s["consultationMode"]))
    }
  end

  defp apply_scope_filter(query, scope) do
    query
    |> Ash.Query.filter(timezone == ^scope.timezone)
    |> Ash.Query.filter(scope_appointment_type_id == ^scope.appointment_type_id)
    |> Ash.Query.filter(scope_doctor_location_id == ^scope.doctor_location_id)
    |> Ash.Query.filter(scope_location_room_id == ^scope.location_room_id)
    |> Ash.Query.filter(scope_consultation_mode == ^scope.consultation_mode)
  end

  defp parse_replace_mode("replace_selected_days"), do: :replace_selected_days
  defp parse_replace_mode("reset_all"), do: :reset_all
  defp parse_replace_mode(_), do: :replace_selected_days

  defp parse_mode(nil), do: nil
  defp parse_mode("in_person"), do: :in_person
  defp parse_mode("video"), do: :video
  defp parse_mode("phone"), do: :phone
  defp parse_mode(_), do: nil

  defp parse_time!(t) when is_binary(t) do
    # expects "HH:MM"
    [h, m] = String.split(t, ":")
    {:ok, time} = Time.new(String.to_integer(h), String.to_integer(m), 0)
    time
  end

  defp parse_date_maybe(nil), do: nil
  defp parse_date_maybe(""), do: nil
  defp parse_date_maybe(s), do: Date.from_iso8601!(s)

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(v), do: v

  defp iso_dow(date), do: Date.day_of_week(date, :monday)

  # DST-safe-ish conversion:
  # - if ambiguous: pick the earlier
  # - if gap: shift forward by the gap (fallback to later valid time)
  defp local_to_utc(date, time, tz) do
    naive = NaiveDateTime.new!(date, time)

    case DateTime.from_naive(naive, tz) do
      {:ok, dt} ->
        {:ok, DateTime.shift_zone!(dt, "Etc/UTC")}

      {:ambiguous, dt1, _dt2} ->
        {:ok, DateTime.shift_zone!(dt1, "Etc/UTC")}

      {:gap, _dt_before, dt_after} ->
        {:ok, DateTime.shift_zone!(dt_after, "Etc/UTC")}

      other ->
        other
    end
  end
end
