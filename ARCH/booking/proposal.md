To build Add Slot professionally with your stack, you’ll use each piece for a specific job and add a few “glue” parts for correctness (timezones, validation, concurrency).

Frontend (Inertia + TanStack Query + React Hook Form + AntD)

AntD: Modal/Drawer UI, day toggle pills, TimePicker/RangePicker, Selects (service/location/mode), and a slot “preview” list.

React Hook Form: Owns the form state + dynamic arrays (multiple windows per day, breaks). Use useFieldArray for adding/removing windows/breaks, and a schema resolver for strong validation.

TanStack Query: Fetch initial schedule + reference data (appointment types, locations, rooms), and handle mutations (create/update schedule rules). After save: invalidate keys like ['schedule_rules', doctorId] and ['availability_preview', doctorId, weekRange] so the UI refreshes instantly.

Inertia: Page shell and routing; the form can live as a React component on the schedule page, and TanStack Query handles the data layer.

Backend (Phoenix + Ash + Postgres)

Ash Resources + Actions: ScheduleRule, ScheduleRuleBreak, AvailabilityException resources; custom actions like upsert_schedule_rules (bulk) and preview_slots (calculated view). Put the business rules here: split shifts allowed, breaks within windows, scoping to service/location, etc.

Postgres constraints: CHECK constraints (end > start) and (if you ever store generated slot rows or holds) exclusion constraints to prevent overlapping bookings. Even for just schedule rules, add unique/index constraints and validate overlaps at the Ash layer.

Timezone/DST correctness: store schedule windows as local times + tzid (e.g. Europe/Athens) and expand to UTC when generating previews/availability. This is the difference between “seems fine” and “works year-round”.

Supporting pieces you’ll want for “professional” quality

Bulk save + transactional integrity: when a doctor saves multiple days/windows, do it in one transaction (Ash can orchestrate this) so partial updates never happen.

Optimistic UI + conflict handling: show success immediately, but if the backend rejects overlaps/conflicts, return field-level errors back into React Hook Form.

Background job (optional): if you later add “holds” and expiry or send reminders, add a job runner (Oban is the common choice in Phoenix land).

here’s a concrete, implementable spec your devs can pick up and build without guesswork: API surface (Ash actions), TanStack Query keys, RHF form shape, payloads, and error mapping.

1) React Hook Form shape (single source of truth)

Use one form model that can both preview and save.

// AddSlotFormValues
type AddSlotFormValues = {
  scope: {
    appointmentTypeId?: string | null;   // null = all services
    doctorLocationId?: string | null;    // null = all locations
    locationRoomId?: string | null;      // null = any room
    consultationMode?: "in_person" | "video" | "phone" | null; // optional
    timezone: string;                    // required, e.g. "Europe/Athens"
  };

  days: Array<{
    dayOfWeek: 1 | 2 | 3 | 4 | 5 | 6 | 7; // ISO
    enabled: boolean;
    windows: Array<{
      workStartLocal: string;            // "09:00"
      workEndLocal: string;              // "17:00"
      slotIntervalMinutes: 5 | 10 | 15 | 20 | 30 | 60;
      breaks: Array<{
        breakStartLocal: string;         // "13:00"
        breakEndLocal: string;           // "14:00"
        label?: string;
      }>;
      priority?: number;                 // default 0
      effectiveFrom?: string | null;     // "YYYY-MM-DD" optional
      effectiveTo?: string | null;
    }>;
  }>;

  // Saving behavior
  replaceMode: "replace_selected_days" | "append"; // recommended default: replace_selected_days
};


RHF implementation notes

useFieldArray for days[x].windows and days[x].windows[y].breaks

Grey-out a day’s section when enabled=false, but keep values in state.

Inline preview calls (debounced) run against the same shape (minus replaceMode).

2) TanStack Query keys + hooks
Query keys
const scheduleRulesKey = (doctorId: string, scope: any) =>
  ["schedule_rules", doctorId, scope];

const schedulePreviewKey = (doctorId: string, payloadHash: string) =>
  ["schedule_preview", doctorId, payloadHash];

const referenceDataKey = (doctorId: string) =>
  ["schedule_refdata", doctorId]; // appointment types, locations, rooms

Hooks overview

useQuery(referenceDataKey) → loads Select options

useQuery(scheduleRulesKey) → loads existing rules to display in “Weekly Hours”

useQuery(schedulePreviewKey, { enabled: !!payloadHash }) → preview “Will create N slots”

useMutation(saveRules) → saves + invalidates scheduleRulesKey

On success:

queryClient.invalidateQueries({ queryKey: ["schedule_rules", doctorId] })

queryClient.invalidateQueries({ queryKey: ["schedule_preview", doctorId] })

3) Backend API surface (Ash actions)

You want two main server capabilities:

preview generated slots (no writes)

bulk upsert recurring rules + breaks (atomic write)

Resource: ScheduleRule

Attributes (matches the earlier blueprint):

doctor_id, timezone

optional scope: appointment_type_id, doctor_location_id, location_room_id, consultation_mode

day_of_week, work_start_local, work_end_local, slot_interval_minutes, priority

effective_from, effective_to, is_active
Relationships:

has_many :breaks, ScheduleRuleBreak

Action: preview_slots

Type: read action (or custom calculation endpoint)
Input: AddSlotFormValues (scope + days/windows/breaks + date range for preview)

Example request:

POST /doctor/schedule/preview
{
  "scope": { "timezone": "Europe/Athens", "appointmentTypeId": null, "doctorLocationId": "…", "consultationMode": "in_person" },
  "days": [ ... ],
  "dateRange": { "start": "2025-12-15", "end": "2025-12-21" }
}


Example response:

{
  "summary": { "totalSlots": 32, "daysEnabled": 4 },
  "days": [
    {
      "dayOfWeek": 1,
      "windows": [
        {
          "workStartLocal": "09:00",
          "workEndLocal": "17:00",
          "slotIntervalMinutes": 30,
          "slots": [
            { "startLocal": "09:00", "endLocal": "09:30" },
            { "startLocal": "09:30", "endLocal": "10:00" }
          ]
        }
      ]
    }
  ],
  "warnings": [
    { "code": "BREAK_OUTSIDE_WINDOW", "path": "days.0.windows.0.breaks.1", "message": "Break must be inside the work window." }
  ]
}

Action: bulk_upsert_schedule_rules

Type: create/update/destroy in one transaction
Semantics (recommended): “replace selected days for this scope”

For the given doctor_id + scope, delete existing rules for the selected dayOfWeeks, then insert the new rules + breaks.

Request:

POST /doctor/schedule/rules/bulk_upsert
{
  "scope": { "timezone": "Europe/Athens", "appointmentTypeId": null, "doctorLocationId": "…", "locationRoomId": null, "consultationMode": "in_person" },
  "replaceMode": "replace_selected_days",
  "days": [ ...same as form... ]
}


Response:

{ "ok": true, "insertedRules": 6, "deletedRules": 2 }


Important validations in Ash (server-side)

work_end_local > work_start_local

breaks:

break_end_local > break_start_local

break must be within window

breaks must not overlap each other

split shifts allowed (multiple windows per day)

optional: prevent overlapping rules within same scope/day if you want (or allow and use priority)

4) Error mapping back into React Hook Form

Return errors with a path that matches RHF fields. Example:

{
  "ok": false,
  "errors": [
    { "path": "days.0.windows.1.workEndLocal", "code": "END_BEFORE_START", "message": "End time must be after start time." },
    { "path": "days.2.enabled", "code": "NO_WINDOWS", "message": "Enabled days must have at least one window." }
  ]
}


Then in the client:

setError("days.0.windows.1.workEndLocal", { type: "server", message })

5) Minimal routing (Phoenix + Inertia)

GET /doctor/schedule → Inertia page props: doctorId, timezoneDefault

GET /api/doctor/schedule/refdata → types/locations/rooms

GET /api/doctor/schedule/rules → existing rules (for the grid)

POST /api/doctor/schedule/preview → preview slots

POST /api/doctor/schedule/rules/bulk_upsert → save

(You can keep these as Phoenix JSON controllers that call Ash actions internally.)

6) UI behavior checklist (so devs match product intent)

Day chips: select one for viewing, but saving supports multi-day edits.

Per-day toggle: if off → disable inputs + show “Not available”

Windows: add/remove (split shifts)

Pattern: slot interval minutes + preview “Creates N slots”

Breaks: add/remove within a window

Scope selects (service/location/mode) at the top of modal

Save does atomic replace for selected days + scope

Time Off remains separate (exceptions override rules later)

Below is a working “shape” for this in Ash + Phoenix JSON endpoints, including:

ScheduleRule + ScheduleRuleBreak resources

a transactional bulk upsert (replace_selected_days or append)

a DST-safe-ish preview_slots implementation using core Elixir time APIs

controller examples

I’m assuming Ash with Ecto data layer + a Medic.Repo. If your Ash version differs slightly, you may need tiny syntax tweaks (mainly around validations/transactions), but the architecture is solid.

1) Ash Resources
lib/medic/scheduling/schedule_rule.ex
defmodule Medic.Scheduling.ScheduleRule do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "schedule_rules"
    repo Medic.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :doctor_id, :uuid, allow_nil?: false
    attribute :timezone, :string, allow_nil?: false

    # Optional scope (null = applies broadly)
    attribute :scope_appointment_type_id, :uuid
    attribute :scope_doctor_location_id, :uuid
    attribute :scope_location_room_id, :uuid
    attribute :scope_consultation_mode, :atom do
      constraints one_of: [:in_person, :video, :phone]
      allow_nil? true
    end

    attribute :day_of_week, :integer, allow_nil?: false
    attribute :work_start_local, :time, allow_nil?: false
    attribute :work_end_local, :time, allow_nil?: false
    attribute :slot_interval_minutes, :integer, allow_nil?: false, default: 10
    attribute :priority, :integer, allow_nil?: false, default: 0

    attribute :effective_from, :date
    attribute :effective_to, :date
    attribute :is_active, :boolean, allow_nil?: false, default: true

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :breaks, Medic.Scheduling.ScheduleRuleBreak do
      destination_attribute :schedule_rule_id
    end
  end

  validations do
    validate compare(:day_of_week, greater_than_or_equal_to: 1)
    validate compare(:day_of_week, less_than_or_equal_to: 7)

    validate compare(:work_end_local, greater_than: :work_start_local)

    validate compare(:slot_interval_minutes, greater_than_or_equal_to: 5)
    validate compare(:slot_interval_minutes, less_than_or_equal_to: 60)

    # effective_to >= effective_from (if both present)
    validate {Medic.Scheduling.Validations.EffectiveRange, []}
  end

  actions do
    defaults [:read, :create, :update, :destroy]

    create :create_with_breaks do
      accept [
        :doctor_id, :timezone,
        :scope_appointment_type_id, :scope_doctor_location_id, :scope_location_room_id, :scope_consultation_mode,
        :day_of_week, :work_start_local, :work_end_local, :slot_interval_minutes, :priority,
        :effective_from, :effective_to, :is_active
      ]

      argument :breaks, {:array, :map}, allow_nil?: true, default: []

      change manage_relationship(:breaks,
        type: :create,
        on_no_match: :ignore,
        on_match: :ignore,
        value_is_key: :breaks
      )
    end
  end

  identities do
    # Not unique on day_of_week because split shifts are allowed.
    # If you want to prevent exact duplicates, define a composite identity.
  end
end

lib/medic/scheduling/schedule_rule_break.ex
defmodule Medic.Scheduling.ScheduleRuleBreak do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "schedule_rule_breaks"
    repo Medic.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :schedule_rule_id, :uuid, allow_nil?: false
    attribute :break_start_local, :time, allow_nil?: false
    attribute :break_end_local, :time, allow_nil?: false
    attribute :label, :string

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :schedule_rule, Medic.Scheduling.ScheduleRule do
      source_attribute :schedule_rule_id
      allow_nil? false
    end
  end

  validations do
    validate compare(:break_end_local, greater_than: :break_start_local)
  end

  actions do
    defaults [:read, :create, :update, :destroy]
  end
end

lib/medic/scheduling/validations/effective_range.ex
defmodule Medic.Scheduling.Validations.EffectiveRange do
  use Ash.Resource.Validation

  @impl true
  def validate(changeset, _opts) do
    from = Ash.Changeset.get_attribute(changeset, :effective_from)
    to   = Ash.Changeset.get_attribute(changeset, :effective_to)

    cond do
      is_nil(from) or is_nil(to) -> :ok
      Date.compare(to, from) in [:eq, :gt] -> :ok
      true -> {:error, field: :effective_to, message: "effective_to must be on/after effective_from"}
    end
  end
end

2) Bulk upsert + preview API module
lib/medic/scheduling.ex
defmodule Medic.Scheduling do
  alias Medic.Scheduling.{ScheduleRule, ScheduleRuleBreak}
  alias Medic.Repo

  @type replace_mode :: :replace_selected_days | :append

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

      if replace_mode == :replace_selected_days do
        delete_rules_for_scope_and_days!(doctor_id, scope, selected_dows)
      end

      # Insert new rules + breaks
      inserted =
        for day <- days,
            window <- List.wrap(day["windows"]),
            do: create_rule_with_breaks!(doctor_id, scope, day["dayOfWeek"], window)

      %{inserted_rules: length(inserted), deleted_days: selected_dows}
    end)
    |> case do
      {:ok, result} -> result
      {:error, reason} -> reraise(reason, __STACKTRACE__)
    end
  end

  defp delete_rules_for_scope_and_days!(doctor_id, scope, dows) do
    # Fetch matching rules then destroy via Ash (so breaks cascade properly).
    query =
      ScheduleRule
      |> Ash.Query.filter(doctor_id == ^doctor_id and day_of_week in ^dows)
      |> apply_scope_filter(scope)

    rules = Ash.read!(query)

    Enum.each(rules, fn rule ->
      Ash.destroy!(rule)
    end)
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

  def preview_slots(doctor_id, payload) do
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

  defp parse_replace_mode("append"), do: :append
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

3) Phoenix JSON controllers (thin)
lib/medic_web/controllers/doctor_schedule_controller.ex
defmodule MedicWeb.DoctorScheduleController do
  use MedicWeb, :controller
  alias Medic.Scheduling

  # POST /api/doctor/schedule/preview
  def preview(conn, params) do
    doctor_id = conn.assigns.current_doctor.id
    result = Scheduling.preview_slots(doctor_id, params)
    json(conn, result)
  end

  # POST /api/doctor/schedule/rules/bulk_upsert
  def bulk_upsert(conn, params) do
    doctor_id = conn.assigns.current_doctor.id

    result =
      Scheduling.bulk_upsert_schedule_rules!(doctor_id, params)

    json(conn, %{ok: true, result: result})
  rescue
    e ->
      # In production, map Ash errors into {path, code, message} and return 422
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{ok: false, error: Exception.message(e)})
  end
end


Routes:

scope "/api/doctor/schedule", MedicWeb do
  post "/preview", DoctorScheduleController, :preview
  post "/rules/bulk_upsert", DoctorScheduleController, :bulk_upsert
end

4) What I’d add immediately (so it’s truly “professional”)

Server-side overlap validation for breaks

right now we only subtract breaks in preview; add a validation to ensure breaks don’t overlap each other and are within the work window (as an Ash validation on the rule create action).

Error shaping

return errors as [%{path, code, message}] so the client can setError() directly.

Scope equality

the delete step filters scope fields by equality; that’s correct only if you enforce “null means global” consistently. (You do—just keep it strict.)

Your current schema is a solid “marketplace + basic appointments” baseline, but it’s missing the pieces needed for Add Slot and for a booking system that is concurrency-safe and scalable:

No recurring schedule model (rules/breaks)

No exceptions/time off

No service catalog (appointment types) and scoping

No hard DB-level overlap prevention (especially if you later add capacity/parallel sessions)

appointments only has scheduled_at (single timestamp) — you need start + end (and ideally a range)

Below is a clean, incremental plan that preserves your existing data fields, and introduces the world-class model.

Phase 1: Add Slot (recurring rules + breaks + exceptions)
Ecto migration: schedule rules + breaks + exceptions

Create a migration like priv/repo/migrations/YYYYMMDDHHMMSS_add_scheduling_tables.exs:

defmodule Medic.Repo.Migrations.AddSchedulingTables do
  use Ecto.Migration

  def up do
    # Needed later if you add exclusion constraints with equality fields
    execute("CREATE EXTENSION IF NOT EXISTS btree_gist;")

    create table(:schedule_rules, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :doctor_id, references(:doctors, type: :uuid, on_delete: :delete_all), null: false

      add :timezone, :text, null: false

      # optional scope
      add :scope_appointment_type_id, :uuid
      add :scope_doctor_location_id, :uuid
      add :scope_location_room_id, :uuid
      add :scope_consultation_mode, :text

      add :day_of_week, :int, null: false
      add :work_start_local, :time, null: false
      add :work_end_local, :time, null: false
      add :slot_interval_minutes, :int, null: false, default: 10
      add :priority, :int, null: false, default: 0

      add :effective_from, :date
      add :effective_to, :date
      add :is_active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime_usec)
    end

    create index(:schedule_rules, [:doctor_id, :day_of_week, :is_active, :priority])

    execute("""
    ALTER TABLE schedule_rules
    ADD CONSTRAINT schedule_rules_day_of_week_chk CHECK (day_of_week BETWEEN 1 AND 7);
    """)

    execute("""
    ALTER TABLE schedule_rules
    ADD CONSTRAINT schedule_rules_work_time_chk CHECK (work_end_local > work_start_local);
    """)

    execute("""
    ALTER TABLE schedule_rules
    ADD CONSTRAINT schedule_rules_effective_range_chk
    CHECK (effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from);
    """)

    create table(:schedule_rule_breaks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :schedule_rule_id, references(:schedule_rules, type: :uuid, on_delete: :delete_all), null: false
      add :break_start_local, :time, null: false
      add :break_end_local, :time, null: false
      add :label, :text
      timestamps(type: :utc_datetime_usec)
    end

    create index(:schedule_rule_breaks, [:schedule_rule_id])

    execute("""
    ALTER TABLE schedule_rule_breaks
    ADD CONSTRAINT schedule_rule_breaks_time_chk CHECK (break_end_local > break_start_local);
    """)

    create table(:availability_exceptions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :doctor_id, references(:doctors, type: :uuid, on_delete: :delete_all), null: false

      # optional scope
      add :scope_appointment_type_id, :uuid
      add :scope_doctor_location_id, :uuid
      add :scope_location_room_id, :uuid

      add :starts_at_utc, :utc_datetime_usec, null: false
      add :ends_at_utc, :utc_datetime_usec, null: false

      add :kind, :text, null: false, default: "blocked" # blocked|available
      add :reason, :text
      add :source, :text, null: false, default: "manual"

      timestamps(type: :utc_datetime_usec)
    end

    create index(:availability_exceptions, [:doctor_id, :starts_at_utc])
    execute("""
    ALTER TABLE availability_exceptions
    ADD CONSTRAINT availability_exceptions_time_chk CHECK (ends_at_utc > starts_at_utc);
    """)
  end

  def down do
    drop table(:availability_exceptions)
    drop table(:schedule_rule_breaks)
    drop table(:schedule_rules)
  end
end


That’s enough to implement Add Slot + “Time Off” (exceptions) right away.

Phase 2: Upgrade appointments to world-class time model (keep Cal.com sync)

Right now appointments.scheduled_at is a single timestamp. For reliable booking, add:

starts_at_utc, ends_at_utc

(optional now, highly recommended later) a period tstzrange + GiST index

keep cal_com_* columns untouched

Migration: alter appointments (backfill safely)
defmodule Medic.Repo.Migrations.UpgradeAppointmentsTimeModel do
  use Ecto.Migration

  def up do
    alter table(:appointments) do
      add :starts_at_utc, :utc_datetime_usec
      add :ends_at_utc, :utc_datetime_usec
      add :patient_timezone, :text
      add :doctor_timezone, :text
      add :hold_expires_at, :utc_datetime_usec
      add :cancelled_by_actor_type, :text
      add :cancelled_by_actor_id, :uuid
    end

    # Backfill from scheduled_at + duration_minutes (assuming scheduled_at was UTC)
    execute("""
    UPDATE appointments
    SET starts_at_utc = scheduled_at::timestamptz,
        ends_at_utc   = (scheduled_at::timestamptz + (duration_minutes || ' minutes')::interval)
    WHERE starts_at_utc IS NULL;
    """)

    execute("""
    ALTER TABLE appointments
    ADD CONSTRAINT appointments_time_chk CHECK (ends_at_utc > starts_at_utc);
    """)

    # Optional but recommended for fast range queries later:
    # Add period as a generated column (Ecto doesn't always support generated columns cleanly)
    execute("""
    ALTER TABLE appointments
    ADD COLUMN period tstzrange GENERATED ALWAYS AS (tstzrange(starts_at_utc, ends_at_utc, '[)')) STORED;
    """)

    execute("CREATE INDEX appointments_period_gist_idx ON appointments USING gist (period);")
    create index(:appointments, [:doctor_id, :starts_at_utc])
    create index(:appointments, [:patient_id, :starts_at_utc])
  end

  def down do
    execute("DROP INDEX IF EXISTS appointments_period_gist_idx;")
    execute("ALTER TABLE appointments DROP COLUMN IF EXISTS period;")

    execute("ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_time_chk;")

    alter table(:appointments) do
      remove :cancelled_by_actor_id
      remove :cancelled_by_actor_type
      remove :hold_expires_at
      remove :doctor_timezone
      remove :patient_timezone
      remove :ends_at_utc
      remove :starts_at_utc
    end
  end
end


You can keep scheduled_at for now (compat) and later deprecate it in code.

Phase 3: Add appointment types + scoping (so Add Slot can target services/locations)

You don’t currently have doctor_locations / location_rooms in the schema snapshot. If you don’t need multi-location yet, you can start with just appointment_types and add locations later.

Minimum:

appointment_types (per doctor)

appointment_type_locations (optional once locations exist)

Then your Add Slot modal can scope rules to “All services” or specific service.

Phase 4: “True booking safety” (capacity/resources + exclusion constraints)

When you move from “show slots” → “book slots”, you should enforce non-overlap at the DB level.

If you want capacity / parallel sessions: add

bookable_resources

appointment_resource_claims with EXCLUDE USING gist (resource_id WITH =, period WITH &&)

That’s what makes it bulletproof under concurrency.

Ash resources/actions you should implement now (for Add Slot)
Resources

Medic.Scheduling.ScheduleRule

Medic.Scheduling.ScheduleRuleBreak

Medic.Scheduling.AvailabilityException

Actions

bulk_upsert_schedule_rules (transactional; default mode: replace selected days for the given scope)

preview_slots (pure read; expands local schedule → UTC slots; subtract breaks; apply exceptions)
Dropping Cal.com means you can simplify the schema and booking flow—but the core scheduling + booking model I proposed doesn’t change. The big difference is you no longer need external identifiers or reconciliation logic, and you can lean harder on DB constraints + “hold → confirm” to make the experience rock-solid.

Here’s what changes (and what doesn’t):

What stays the same (core architecture)

Recurring schedule rules (local times + timezone) + breaks

Exceptions for time off / ad-hoc openings

Appointments stored with starts_at_utc + ends_at_utc (+ period range)

Preview slots (read-only expansion) for UX

Booking safety enforced in Postgres (range overlap prevention)

If you want parallel sessions: resources + claims (best practice)

What you remove / simplify

Remove from appointments:

cal_com_booking_id

cal_com_uid (and its unique index)

Remove any “sync” code paths and background jobs used for reconciliation.

Migration to remove those columns
defmodule Medic.Repo.Migrations.RemoveCalComFields do
  use Ecto.Migration

  def up do
    drop_if_exists index(:appointments, [:cal_com_uid], name: :appointments_cal_com_uid_index)
    alter table(:appointments) do
      remove :cal_com_booking_id
      remove :cal_com_uid
    end
  end

  def down do
    alter table(:appointments) do
      add :cal_com_booking_id, :text
      add :cal_com_uid, :text
    end
    create unique_index(:appointments, [:cal_com_uid])
  end
end

What you should add because you own the whole flow now

If you’re building your own, I strongly recommend adding these now because they’re cheap early:

1) Holds (prevents “two people grabbed the same slot”)

appointments.status includes held

hold_expires_at

A cleanup job expires holds (or you can expire on read + periodic job)

2) Audit log (already in your earlier schema draft)

appointment_events (append-only)

3) Policies + actors

Instead of “cancelled_by text”, store:

cancelled_by_actor_type + cancelled_by_actor_id
Same for created/rescheduled if you want full traceability.

One important note

If you no longer need Cal.com, you can also rename/reshape the existing column scheduled_at:

Prefer starts_at_utc / ends_at_utc

Keep scheduled_at only temporarily for backward compatibility, then remove it.