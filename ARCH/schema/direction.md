Overall: this is a strong, scalable direction for Phoenix + Ash + Postgres, and it’s already thinking about the right “hard parts” (audit log, exceptions, double-booking constraints, service catalog, templates). The main risks are (1) schedule model duplication, (2) parallel sessions vs exclusion constraints, and (3) a couple naming/normalization issues that will bite later.

## Execution plan (how we’ll roll this out)

**Phase 0 – Audit & plan (✅ today):** document gaps vs. the proposal, align on the canonical data model, and freeze any new work on `availability_rules` so we can replace it cleanly.

**Phase 1 – New primitives (this PR):**
- Create the shared tables: `bookable_resources`, `appointment_resource_claims`, `schedule_rules`, `schedule_rule_breaks`, `schedule_exceptions`.
- Add snapshot + actor columns to `appointments` and rename the legacy `appointment_type` column to `consultation_mode_snapshot`.
- Expose Ash resources for the new tables so services can start persisting data without touching legacy flows yet.

**Phase 2 – Feature adoption:**
- Teach the scheduling context to read from `schedule_rules` (while still backfilling from availability rules for existing doctors) and emit resource claims when booking.
- Update booking flows (doctor portal + patient booking) to capture consultation mode snapshots and resource assignments.

**Phase 3 – Cutover & cleanup:**
- Remove/alias `availability_rules`/`schedule_templates` once all traffic is on `schedule_rules`.
- Drop the legacy `appointment_type` string usages in FE/back-end, delete compatibility code, and enforce `bookable_resources` claims everywhere.

We can iterate on Phase 2/3 in smaller PRs (e.g., “slots now read from schedule_rules for telemedicine” or “create resource claims when confirming appointments”).

Stack fit (Phoenix + Ash + Inertia + TanStack Query + Postgres)

Phoenix + Ash + Postgres is a great combo for this domain: validations, policies, atomic actions, and PG constraints do the real safety work.

Inertia + TanStack Query is fine for booking UX (search slots → book → confirm → update). Just make sure you have a clean invalidation strategy:

On booking/cancel/reschedule, invalidate queries keyed by (doctor_id, location_id, date_range, appointment_type_id).

If you want “live” slot updates, use Phoenix PubSub + a small Inertia client hook to explain “availability changed, refresh”.

What’s excellent in your schema

appointment_events append-only audit log is exactly right.

appointment_types is good: duration, buffers, rules, modality, default location/room.

availability_exceptions exists (you will 100% need it).

Template + breaks gives you the power you’ll want later.

The 3 big issues to fix early
1) You currently have two schedule systems (availability_rules and schedule_templates)

That’s fine as a product progression, but it’s dangerous as a data model unless you declare a single source of truth.

What I’d do:

Pick one canonical engine for slot generation.

Either: keep availability_rules only for MVP and add templates later as a migration.

Or: make schedule_templates the canonical source and treat availability_rules as a simplified UI that writes into templates.

Otherwise you’ll end up debugging “why did Monday show slots from rules but also from templates”.

2) max_parallel_sessions cannot be enforced with a simple “no double booking” constraint

An exclusion constraint on (doctor_id, tstzrange(starts_at, ends_at)) works only when capacity is 1.

If you truly want parallel sessions, you need a capacity model. Two common approaches:

Option A (clean + scalable): “resource units”

Create a table like bookable_resources (or schedule_resources) representing capacity units (e.g., “Room 2”, “Telemedicine Slot A”, etc.).

Each appointment claims exactly one resource_id.

Enforce exclusion on (resource_id, tstzrange) — now capacity > 1 is just “more resources”.

Option B (lighter): “slot key + counter”

Keep starts_at/ends_at and allow overlaps, but enforce count(*) <= max_parallel_sessions at transaction time with locking.

This is harder to make bulletproof under concurrency than Option A.

If you’re serious about parallel sessions, do Option A now. It will save you pain.

3) Naming/normalization: appointments.appointment_type conflicts with appointment_type_id

You have:

appointments.appointment_type (legacy modality in_person/telemedicine)

appointments.appointment_type_id FK to appointment_types

appointment_types.consultation_mode

That’s a confusion magnet.

Fix:

Rename appointments.appointment_type → consultation_mode_snapshot (or remove it).

Keep appointment_type_id as the service.

If you want a snapshot (in case the service changes later), store snapshots explicitly:

appointment_type_name_snapshot, duration_snapshot, price_snapshot, mode_snapshot.

Table-by-table tightening
appointments

Add/adjust:

Use Postgres timestamptz (utc_datetime in Ecto is fine) and ensure check: ends_at > starts_at.

Consider a computed range column (tsrange/tstzrange) for constraints + indexing.

Add explicit fields for lifecycle:

created_by_actor_type, created_by_actor_id

cancelled_by_actor_type, cancelled_by_actor_id (instead of freeform cancelled_by)

Add external_ref if you ever integrate with third-party calendars/telehealth/payment.

Indexes you’ll want on day 1:

(doctor_id, starts_at)

(patient_id, starts_at)

(doctor_location_id, starts_at)

(appointment_type_id, starts_at)

Payment (if you’ll charge): you’ll eventually want payment_status + payment_provider + payment_intent_id.

appointment_events

If it’s truly immutable:

Drop updated_at (or enforce insert-only at the DB level). Having updated_at suggests mutability.

Index (appointment_id, occurred_at desc).

appointment_types

Good. Add:

Unique constraint should be (doctor_id, slug) (not global).

Consider visibility (public/private) if doctors create internal-only services.

availability_rules

Your unique (doctor_id, day_of_week) means you can’t represent:

split shifts (e.g., 09:00–12:00 and 17:00–20:00)

multiple breaks

If you keep this table, make it represent windows, not “weekday settings”:

Replace uniqueness with: many rows per weekday, each row is a window.

Breaks should be a separate table (or move straight to templates).

schedule_templates / schedule_template_breaks

Good direction. Add constraints:

Ensure work_end > work_start

Ensure breaks don’t overlap each other and are within work window (enforce in code; optionally with exclusion constraints per template)

If location_room_id is optional, define booking rules (room required for in-person?).

availability_exceptions

Clarify semantics:

status: blocked/available is okay, but I’d rename to kind or exception_type to avoid “status” collisions with appointment status.

Add check ends_at > starts_at.

Index by (doctor_id, starts_at) and ideally range index if you query overlaps.

time_off_requests

Good. Add:

approved_at, denied_at

Consider event log too (or reuse appointment_events-style pattern).

One missing “core” concept: what is being booked

Right now it’s mostly “doctor time”, with optional room/location. Real systems end up needing a first-class concept like:

booking_subject / bookable_resource

doctor time

room

equipment

telehealth capacity

clinic-wide shared resources

Even if you don’t expose it in UI now, modeling it internally makes constraints and scaling sane (especially for parallel sessions).

My blunt recommendation

If you change only a few things now, do these:

Pick one schedule engine (templates or rules) and make the other feed into it (or remove it).

If you want max_parallel_sessions > 1, implement resource-unit booking now.

Clean up the appointment_type naming collision and store explicit snapshots if needed.

Add the key DB constraints + indexes (range overlap, ends > starts, slug uniqueness per doctor).

If you want, paste your current “no_double_bookings” constraint definition and how you generate slots, and I’ll tell you whether it’s concurrency-safe and how to adapt it to parallel sessions without race conditions.

We want to make a world class booking systems, give us complete direction on how to model this and what schema to use and what to improve. Think best practice and industry standard but also consider practical UX and what is needed even ideally so we can add it now.
Thought for 34s

Here notes for a world-class booking model: you want a design that is (a) concurrency-safe, (b) timezone/DST correct, (c) flexible for future features (multi-location, rooms, group capacity, telehealth, payments, reminders, rescheduling rules), and (d) fast for “next available” UX.

The biggest principle: availability is layered, and the database—not the app—prevents double-booking.

1) Core concepts (industry-standard mental model)
Availability layers (in precedence order)

Schedule rules (recurring “I work Mon 09:00–17:00” optionally scoped to service/location)

Break rules (recurring lunch/rounds inside working windows)

Exceptions (one-off overrides: block day, ad-hoc opening, holiday)

Capacity/resources (room, equipment, telehealth capacity, max parallel sessions)

Bookings (appointments + holds)

Hard requirement: represent time as a range

Postgres range types + exclusion constraints are the canonical way to enforce “no overlapping bookings” at the DB level. 
PostgreSQL
+1

2) What to improve in your current schema (high impact)
A) Merge availability_rules and schedule_templates

Pick ONE canonical “recurring schedule rule” table and build the simple UI on top of it.

Your current (doctor_id, day_of_week) uniqueness in availability_rules blocks split shifts (e.g., 09–12 + 17–20).

Move breaks out of the rule row (you already have schedule_template_breaks; make that the pattern everywhere).

B) Fix parallel sessions properly

max_parallel_sessions cannot be enforced by a simple “doctor can’t overlap” exclusion constraint.
Best practice: model capacity as resources, then enforce “no overlap per resource”.

Example: “Telehealth capacity = 3” → create 3 virtual resources in a pool.

Each appointment claims exactly one resource.

Exclusion constraint becomes: no overlaps for the chosen resource.

This is the cleanest way to scale from “1 at a time” → “N in parallel” without race conditions.

C) Remove the appointment_type naming collision

Right now you have appointments.appointment_type (legacy modality) and appointments.appointment_type_id.
Rename/remove the legacy column and store modality as:

derived from appointment_type at booking time, or

a snapshot field (consultation_mode_snapshot) if you need immutability.

D) Make audit log truly immutable

appointment_events should be insert-only. Consider dropping updated_at, or at least treat updates as a bug.

3) Recommended schema (world-class baseline)
3.1 Booking truth tables
appointments

Minimal “truth” of a booking.

id (uuid)

doctor_id, patient_id

appointment_type_id

location_id (doctor_location), room_id (optional)

starts_at_utc timestamptz, ends_at_utc timestamptz

period tstzrange (generated from starts/ends) (or store and validate)

status (held, pending, confirmed, completed, cancelled, no_show)

created_by_actor_type, created_by_actor_id

cancelled_by_actor_type, cancelled_by_actor_id, cancelled_at

patient_timezone, doctor_timezone (snapshots)

optional snapshots: price_cents_snapshot, currency_snapshot, duration_snapshot, mode_snapshot

Critical constraint (capacity=1 case):

EXCLUDE USING gist (doctor_id WITH =, period WITH &&) 
PostgreSQL
+1

If you implement resources (recommended), that constraint moves to (resource_id, period).

appointment_events

Append-only lifecycle/event log:

appointment_id, occurred_at, actor_type/id, action, metadata jsonb

Optional but extremely useful: appointment_participants

If you ever need multiple participants (guardian + child, group sessions, interpreter):

appointment_id, participant_type, participant_id, role

3.2 Capacity: resources (this is what makes it “world class”)
bookable_resources

A thing that cannot be double-booked.

id

doctor_id

location_id nullable

type (room, equipment, telehealth_slot, staff, etc.)

label

is_active

appointment_resource_claims

appointment_id

resource_id

Unique (appointment_id, resource_id)

Exclusion constraint: no overlap per resource:

EXCLUDE USING gist (resource_id WITH =, period WITH &&) 
PostgreSQL
+1

How to represent max_parallel_sessions

Create a “pool” by just having N resources of type telehealth_slot for that doctor/service/location.

When booking, pick any available resource (first-fit).

This avoids fragile “COUNT(*) <= N” logic under concurrency.

3.3 Scheduling (one canonical system)
schedule_rules (canonical replacement for both your rules/templates)

Represents recurring windows, scoped as needed.

id

doctor_id

timezone (IANA tzid, e.g. Europe/Athens) required

scope_appointment_type_id nullable

scope_location_id nullable

scope_room_id nullable

day_of_week (1–7)

work_start_local time, work_end_local time

slot_interval_minutes (e.g. 5/10/15) (separate from service duration)

default_capacity (usually 1; actual capacity comes from resources)

priority (higher wins when overlapping rules exist)

effective_from date nullable, effective_to date nullable

is_active

schedule_rule_breaks

schedule_rule_id

break_start_local time, break_end_local time

label

Why store local times + tzid
Recurring schedules are human/local (“Mondays 9–5”). DST shifts must be handled by expanding occurrences in local time then converting to UTC.

3.4 Exceptions / overrides
availability_exceptions

One-off blocks or extra availability.

doctor_id

starts_at_utc, ends_at_utc (period range)

scope fields nullable (type/location/room)

kind (blocked, available)

reason, source

This table should be applied as a layer over rules when generating availability.

3.5 Performance + UX (optional tables that pay off early)
availability_cache_slots (cache, not truth)

Precomputed slots for fast “next available” and search.

doctor_id, appointment_type_id, location_id

starts_at_utc, ends_at_utc

resource_id nullable (or leave unassigned and assign at booking time)

generated_for_date, generated_at, version

You can regenerate when schedule/exceptions change. It’s okay if it’s eventually consistent as long as booking is enforced by constraints.

4) Booking flow that is concurrency-safe and feels great in UX
The “hold then confirm” pattern

Patient selects a slot → create an appointment with status='held' and a short TTL (hold_expires_at).

DB constraints ensure the hold itself doesn’t overlap.

On confirmation (and payment if needed) → transition to confirmed.

Expired holds are cleaned up by a job.

This prevents two users “seeing the same slot” and both paying. The database is the referee.

Why DB constraints matter

Exclusion constraints are designed for “non-overlapping” time ranges. 
PostgreSQL
+1

5) Recurrence rules (industry standard option)

If remember you may eventually sync with external calendars (Google/Apple/Outlook), store recurrence using RFC 5545 RRULE/RDATE/EXDATE and expand in-app. RFC 5545 defines RRULE for recurring events. 
IETF Datatracker
+1

Google Calendar’s recurrence field is literally RRULE/RDATE/EXDATE strings based on RFC 5545. 
Google for Developers

You don’t have to expose RRULE in UI now, but designing your schedule_rules so they can map to RRULE later is smart.

6) Features worth modeling now (cheap now, expensive later)
Cancellation + reschedule policy

cancellation_policy_minutes per appointment type

reschedule_policy_minutes

store rescheduled_from_appointment_id and/or an event log action

Reminders + notifications (deliverability + audit)

notification_jobs (what should be sent when)

notification_deliveries (what was sent, result, provider ids)

Payments (even if optional)

payments table linked to appointment

provider fields (stripe_payment_intent_id, etc.)

payment_status

Waitlist (very high ROI)

waitlist_entries (doctor/type/location, date range preference, priority)

when a slot opens, notify in order

7) How this maps cleanly into Ash

Each table → Ash resource

“Book appointment” action should be atomic:

select resource (if using capacity pools)

insert appointment (held/confirmed)

insert event

all inside one transaction

Use policies to enforce:

patients only see/book allowed types/locations

doctors can override schedules

system can expire holds

The two decisions you should make right now

Do you want parallel sessions at all?
If yes → implement the resource model now (it’s the difference between clean vs painful later).

One schedule engine only
Unify your availability_rules + schedule_templates into schedule_rules + breaks + exceptions.
