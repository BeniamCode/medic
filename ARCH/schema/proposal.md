Below is a Postgres + Ash-ready “world-class booking” blueprint you can implement now. It’s designed for:

Concurrency safety (DB prevents overlaps)

Parallel sessions / capacity (without hacks)

Split shifts, breaks, overrides

Fast “next available” UX

Clean evolution (payments, reminders, waitlists, multi-participant later)

I’m going to give you:

Schema (tables + columns)

Constraints + indexes (the important part)

Ecto/Ash migration snippets (practical)

Slot-generation + booking algorithm (race-safe)

What to change from your current schema

0) Postgres prerequisites (must do)

You’ll use range types + exclusion constraints to prevent overlaps. Postgres explicitly recommends exclusion constraints for “non-overlapping” range rules. 
PostgreSQL

You’ll also want btree_gist so you can include equality comparisons (e.g. resource_id WITH =) inside GiST-backed exclusion constraints. 
PostgreSQL
+1

CREATE EXTENSION IF NOT EXISTS btree_gist;

1) Canonical schema (recommended)
1.1 Appointment types (services)

appointment_types

doctor-defined services patients book.

Key design choice: keep service rules here; store snapshots in appointments if you need historical accuracy.

CREATE TABLE appointment_types (
  id uuid PRIMARY KEY,
  doctor_id uuid NOT NULL REFERENCES doctors(id),
  slug text NOT NULL,
  name text NOT NULL,
  description text,
  duration_minutes int NOT NULL DEFAULT 30 CHECK (duration_minutes BETWEEN 5 AND 360),
  buffer_before_minutes int NOT NULL DEFAULT 0 CHECK (buffer_before_minutes BETWEEN 0 AND 240),
  buffer_after_minutes  int NOT NULL DEFAULT 0 CHECK (buffer_after_minutes BETWEEN 0 AND 240),
  consultation_mode text NOT NULL CHECK (consultation_mode IN ('in_person','video','phone')),
  price_cents int,
  currency text NOT NULL DEFAULT 'EUR',
  allow_patient_reschedule boolean NOT NULL DEFAULT true,
  min_notice_minutes int NOT NULL DEFAULT 0 CHECK (min_notice_minutes BETWEEN 0 AND 43200),
  max_future_days int NOT NULL DEFAULT 60 CHECK (max_future_days BETWEEN 1 AND 365),
  max_reschedule_count int NOT NULL DEFAULT 2 CHECK (max_reschedule_count BETWEEN 0 AND 20),
  is_active boolean NOT NULL DEFAULT true,
  default_location_id uuid REFERENCES doctor_locations(id),
  default_room_id uuid REFERENCES location_rooms(id),
  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (doctor_id, slug)
);
CREATE INDEX appointment_types_doctor_active_idx ON appointment_types(doctor_id, is_active);


appointment_type_locations (your join table stays, good)

1.2 Capacity model (this is what makes it “world class”)

Instead of trying to enforce max_parallel_sessions with counts, you model bookable resources and let Postgres enforce non-overlap per resource.

bookable_resources

Examples:

in-person: each room is a resource

telehealth: create N “virtual rooms” (capacity N)

equipment/staff if needed later

CREATE TABLE bookable_resources (
  id uuid PRIMARY KEY,
  doctor_id uuid NOT NULL REFERENCES doctors(id),
  doctor_location_id uuid REFERENCES doctor_locations(id),
  location_room_id uuid REFERENCES location_rooms(id),
  type text NOT NULL CHECK (type IN ('room','telehealth_slot','equipment','staff')),
  label text,
  is_active boolean NOT NULL DEFAULT true,
  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX bookable_resources_scope_idx
  ON bookable_resources(doctor_id, doctor_location_id, type, is_active);


How to represent “max_parallel_sessions = 3” for video?
Insert 3 rows with type='telehealth_slot' for that doctor (optionally scoped to a location), and you’re done.

1.3 Scheduling (ONE canonical engine)

This replaces both availability_rules and schedule_templates.

schedule_rules

Recurring windows in the doctor’s IANA timezone (e.g. Europe/Athens)

Support split shifts by allowing multiple rules per weekday

Optional scoping to appointment_type/location/room

CREATE TABLE schedule_rules (
  id uuid PRIMARY KEY,
  doctor_id uuid NOT NULL REFERENCES doctors(id),
  timezone text NOT NULL,  -- IANA tzid
  scope_appointment_type_id uuid REFERENCES appointment_types(id),
  scope_doctor_location_id uuid REFERENCES doctor_locations(id),
  scope_location_room_id uuid REFERENCES location_rooms(id),

  day_of_week int NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
  work_start_local time NOT NULL,
  work_end_local time NOT NULL,
  slot_interval_minutes int NOT NULL DEFAULT 10 CHECK (slot_interval_minutes BETWEEN 5 AND 60),
  priority int NOT NULL DEFAULT 0,

  effective_from date,
  effective_to date,
  is_active boolean NOT NULL DEFAULT true,

  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CHECK (work_end_local > work_start_local),
  CHECK (effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from)
);

CREATE INDEX schedule_rules_lookup_idx ON schedule_rules
  (doctor_id, day_of_week, is_active, priority);


schedule_rule_breaks

CREATE TABLE schedule_rule_breaks (
  id uuid PRIMARY KEY,
  schedule_rule_id uuid NOT NULL REFERENCES schedule_rules(id) ON DELETE CASCADE,
  break_start_local time NOT NULL,
  break_end_local time NOT NULL,
  label text,
  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (break_end_local > break_start_local)
);
CREATE INDEX schedule_rule_breaks_rule_idx ON schedule_rule_breaks(schedule_rule_id);

1.4 Exceptions / overrides (one-off blocks or openings)

Store exceptions in UTC as ranges, then apply them during slot generation.

CREATE TABLE availability_exceptions (
  id uuid PRIMARY KEY,
  doctor_id uuid NOT NULL REFERENCES doctors(id),
  scope_appointment_type_id uuid REFERENCES appointment_types(id),
  scope_doctor_location_id uuid REFERENCES doctor_locations(id),
  scope_location_room_id uuid REFERENCES location_rooms(id),

  starts_at_utc timestamptz NOT NULL,
  ends_at_utc timestamptz NOT NULL,
  period tstzrange GENERATED ALWAYS AS (tstzrange(starts_at_utc, ends_at_utc, '[)')) STORED,

  kind text NOT NULL DEFAULT 'blocked' CHECK (kind IN ('blocked','available')),
  reason text,
  source text NOT NULL DEFAULT 'manual',

  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CHECK (ends_at_utc > starts_at_utc)
);

CREATE INDEX availability_exceptions_lookup_idx
  ON availability_exceptions(doctor_id, starts_at_utc);
CREATE INDEX availability_exceptions_period_gist
  ON availability_exceptions USING gist(period);

1.5 Appointments (truth) + resource claims (the lock)

appointments

Make period a generated range and enforce sanity checks.

Keep “held” appointments (temporary holds) in the same table.

CREATE TABLE appointments (
  id uuid PRIMARY KEY,
  doctor_id uuid NOT NULL REFERENCES doctors(id),
  patient_id uuid NOT NULL REFERENCES patients(id),
  appointment_type_id uuid NOT NULL REFERENCES appointment_types(id),

  doctor_location_id uuid REFERENCES doctor_locations(id),
  location_room_id uuid REFERENCES location_rooms(id),

  starts_at_utc timestamptz NOT NULL,
  ends_at_utc   timestamptz NOT NULL,
  period tstzrange GENERATED ALWAYS AS (tstzrange(starts_at_utc, ends_at_utc, '[)')) STORED,

  status text NOT NULL DEFAULT 'held'
    CHECK (status IN ('held','pending','confirmed','completed','cancelled','no_show')),

  hold_expires_at timestamptz, -- only for held
  patient_timezone text,
  doctor_timezone text,

  -- optional snapshots (recommended)
  duration_minutes_snapshot int,
  price_cents_snapshot int,
  currency_snapshot text,
  consultation_mode_snapshot text,

  notes text,
  cancellation_reason text,
  cancelled_at timestamptz,
  cancelled_by_actor_type text,
  cancelled_by_actor_id uuid,
  reschedule_count int NOT NULL DEFAULT 0,

  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CHECK (ends_at_utc > starts_at_utc)
);

CREATE INDEX appointments_doctor_starts_idx ON appointments(doctor_id, starts_at_utc);
CREATE INDEX appointments_patient_starts_idx ON appointments(patient_id, starts_at_utc);
CREATE INDEX appointments_type_starts_idx ON appointments(appointment_type_id, starts_at_utc);
CREATE INDEX appointments_period_gist ON appointments USING gist(period);


appointment_resource_claims

This is what actually enforces capacity + overlap rules.

CREATE TABLE appointment_resource_claims (
  id uuid PRIMARY KEY,
  appointment_id uuid NOT NULL UNIQUE REFERENCES appointments(id) ON DELETE CASCADE,
  resource_id uuid NOT NULL REFERENCES bookable_resources(id),
  period tstzrange NOT NULL,
  inserted_at timestamptz NOT NULL DEFAULT now()
);

-- Non-overlap per resource:
ALTER TABLE appointment_resource_claims
  ADD CONSTRAINT resource_no_overlap
  EXCLUDE USING gist (
    resource_id WITH =,
    period WITH &&
  );


The && operator is the Postgres “overlaps” operator for ranges. 
PostgreSQL
+2
PostgreSQL
+2

Important detail: use '[)' bounds for ranges so that an appointment ending at 10:00 and another starting at 10:00 are not considered overlapping (adjacency is allowed). 
peterullrich.com

1.6 Audit log (append-only)
CREATE TABLE appointment_events (
  id uuid PRIMARY KEY,
  appointment_id uuid NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
  occurred_at timestamptz NOT NULL,
  actor_type text NOT NULL,
  actor_id uuid,
  action text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX appointment_events_appt_idx
  ON appointment_events(appointment_id, occurred_at DESC);

2) Ecto / Ash migration notes (practical)

Ecto supports defining constraints (including exclusion constraints) in migrations; you’ll typically use execute/1 for the EXCLUDE clause and keep it explicit. 
Hexdocs
+1

You’ll handle overlaps by catching Postgres :exclusion_violation errors (Ash can surface them cleanly as invalid changes when configured).

3) Slot generation algorithm (rules + breaks + exceptions + capacity)

Inputs: doctor_id, appointment_type_id, optional location_id, date range (e.g. next 14 days)

Step A — build candidate windows (local time → UTC)

Load schedule_rules matching doctor + (scopes nullable OR match request).

For each day in range:

Convert local work_start_local/work_end_local in rule.timezone into UTC interval(s)

Subtract recurring breaks for that rule (convert those local break times to UTC for that date)

Step B — apply exceptions (UTC)

Load exceptions overlapping the date range:

kind='blocked' → subtract from availability

kind='available' → add availability (useful for special openings)

Step C — slice into start times

For each availability interval:

Let service_total_minutes = duration + buffers

Step through by slot_interval_minutes and emit candidate start times where start+total fits fully inside interval.

Step D — apply capacity (fast availability check)

For each candidate slot you show, you only need: “is there at least one resource free?”

Query free resource exists:

pick from bookable_resources filtered by doctor/location/type

exclude those whose claims overlap candidate period

This is where a cache (optional) later helps “next available”.

4) Booking algorithm (race-safe and fast)
Hold (recommended UX)

When user clicks a slot:

In one DB transaction:

Insert appointments(status='held', hold_expires_at=now()+5min, starts_at/ends_at, …snapshots…)

Choose a free resource with FOR UPDATE SKIP LOCKED-style pattern (or retry loop):

Try resource A → insert claim

If exclusion violation, try next resource

Insert appointment_events(action='held')

If you can’t claim any resource, return “slot just got taken”.

Confirm

Update appointment to confirmed

Insert event confirmed

Optional: payment capture before confirm

Expire holds

Background job deletes/auto-cancels held appointments past hold_expires_at

Event hold_expired

5) What to change from your current schema

Unify scheduling

Replace availability_rules + schedule_templates with schedule_rules + schedule_rule_breaks

You get split shifts + clean scoping without duplicate engines.

Replace max_parallel_sessions with resources

Keep max_parallel_sessions only as a UI helper that creates N telehealth resources.

Enforcement lives in appointment_resource_claims exclusion constraint.

Fix naming collision

Remove appointments.appointment_type (legacy modality)

Use appointment_type_id + optional consultation_mode_snapshot

Make events append-only

Drop updated_at from appointment_events (or never update rows)

6) Optional “add now if you want world-class”

These are cheap now, expensive later:

waitlist_entries (doctor/type/location + date prefs)

notification_jobs + notification_deliveries (reminders, cancellations, reschedules)

payments (even if many appointments are free)

appointment_participants (guardian/child/group sessions)

External calendar sync fields (external_provider, external_event_id)

If you want external calendar recurrence compatibility later, store recurrence as RRULE/RDATE/EXDATE (RFC 5545). 
IETF Datatracker
+1