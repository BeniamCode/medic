You can make this “Appreciation + Achievements” system feel premium, ethical, and still technically rigorous if you treat it like:

one positive-only patient signal (Appreciation)

a separate, mostly system-driven badge layer (Achievements)

audited + abuse-resistant + privacy-safe

event-driven / metric-driven (so it scales cleanly in Ash)

Below is a professional design + a concrete Postgres schema you can drop into your Ash app.

1) Product rules (make it ethical + hard to game)
Patient Appreciation rules (simple, fair, and defensible)

Only after a real appointment

Appreciation must be tied to an appointment_id with status IN ('completed','confirmed') (you choose).

One appreciation per appointment

Prevent spam; still allows appreciation across multiple visits.

Display “Patients Appreciated” = distinct patients

You can allow multiple appreciations over time, but the public counter is unique patients.

No downvotes, no public negative scoring

If you want “safety”, handle complaints privately (support workflow), not as public signals.

Achievements rules

Achievements are positive, mostly system-awarded, and auditable.

Some can be dynamic tiers (“Highly Appreciated”), recalculated nightly.

2) Schema blueprint (Postgres)
2.1 Patient Appreciation (truth table)
doctor_appreciations

One row per (appointment appreciation). This is the atomic signal.

CREATE TABLE doctor_appreciations (
  id uuid PRIMARY KEY,
  doctor_id uuid NOT NULL REFERENCES doctors(id),
  patient_id uuid NOT NULL REFERENCES patients(id),
  appointment_id uuid NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,

  -- optional: lets you add future “flavors” without ratings
  kind text NOT NULL DEFAULT 'appreciated'
    CHECK (kind IN ('appreciated')),

  created_at timestamptz NOT NULL DEFAULT now(),

  -- prevents multiple appreciations for the same appointment
  UNIQUE (appointment_id),

  -- optional extra guard (helps if appointment table can be shared in future):
  UNIQUE (doctor_id, patient_id, appointment_id)
);

CREATE INDEX doctor_appreciations_doctor_created_idx
  ON doctor_appreciations(doctor_id, created_at DESC);

CREATE INDEX doctor_appreciations_patient_created_idx
  ON doctor_appreciations(patient_id, created_at DESC);


Ash validations you enforce (important):

appointment belongs to that doctor_id and patient_id

appointment status is eligible (completed/confirmed)

appointment is not cancelled

patient can appreciate only their own appointment

Don’t try to enforce those cross-row checks purely in SQL—do them in Ash actions (transactional) and keep the DB constraints for uniqueness and integrity.

2.2 Optional: public “kind words” (still non-judgmental)

If you want an optional short note that can be shown publicly after moderation:

doctor_appreciation_notes
CREATE TABLE doctor_appreciation_notes (
  id uuid PRIMARY KEY,
  appreciation_id uuid NOT NULL UNIQUE
    REFERENCES doctor_appreciations(id) ON DELETE CASCADE,

  note_text text NOT NULL CHECK (char_length(note_text) <= 800),
  visibility text NOT NULL DEFAULT 'private'
    CHECK (visibility IN ('private','public')),

  moderation_status text NOT NULL DEFAULT 'pending'
    CHECK (moderation_status IN ('pending','approved','rejected')),

  moderated_by_id uuid REFERENCES accounts(id),
  moderated_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now()
);


This lets you keep the public surface calm without turning it into a comment war.

2.3 Counter cache / stats (for fast profile pages)

You can compute counts on the fly, but for a big directory you’ll want a stats table.

doctor_appreciation_stats
CREATE TABLE doctor_appreciation_stats (
  doctor_id uuid PRIMARY KEY REFERENCES doctors(id) ON DELETE CASCADE,

  appreciated_total_distinct_patients int NOT NULL DEFAULT 0,
  appreciated_last_30d_distinct_patients int NOT NULL DEFAULT 0,

  last_appreciated_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX doctor_appreciation_stats_updated_idx
  ON doctor_appreciation_stats(updated_at DESC);


How to maintain it (best practice):

Update stats in the same transaction as inserting doctor_appreciations (or via an async job with eventual consistency).

The “last 30d” value is easiest to recompute nightly (cheap, deterministic).

3) Achievements (badges) system
3.1 Definitions (what badges exist)
achievement_definitions
CREATE TABLE achievement_definitions (
  id uuid PRIMARY KEY,
  key text NOT NULL UNIQUE,            -- e.g. 'profile_completed'
  name text NOT NULL,                  -- e.g. 'Profile Completed'
  description text,
  category text NOT NULL,              -- 'profile' | 'trust' | 'engagement' | 'patient_care'
  icon text,                           -- optional (for UI)
  is_public boolean NOT NULL DEFAULT true,
  is_active boolean NOT NULL DEFAULT true,

  -- optional: tiered achievements (bronze/silver/gold)
  is_tiered boolean NOT NULL DEFAULT false,

  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX achievement_definitions_active_idx
  ON achievement_definitions(is_active, category);

3.2 Awards (what a doctor has earned)
doctor_achievements
CREATE TABLE doctor_achievements (
  id uuid PRIMARY KEY,
  doctor_id uuid NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  achievement_definition_id uuid NOT NULL REFERENCES achievement_definitions(id),

  status text NOT NULL DEFAULT 'earned'
    CHECK (status IN ('earned','revoked')),

  tier int, -- null if not tiered, otherwise 1/2/3
  earned_at timestamptz NOT NULL DEFAULT now(),

  source text NOT NULL DEFAULT 'system'
    CHECK (source IN ('system','manual')),

  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

  UNIQUE (doctor_id, achievement_definition_id, tier)
);

CREATE INDEX doctor_achievements_doctor_idx
  ON doctor_achievements(doctor_id, earned_at DESC);

3.3 Audit log (how/why it was awarded/revoked)
achievement_events
CREATE TABLE achievement_events (
  id uuid PRIMARY KEY,
  doctor_id uuid NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  achievement_definition_id uuid NOT NULL REFERENCES achievement_definitions(id),

  action text NOT NULL CHECK (action IN ('earned','revoked','tier_changed')),
  occurred_at timestamptz NOT NULL DEFAULT now(),

  actor_type text NOT NULL DEFAULT 'system', -- system/admin
  actor_id uuid,

  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX achievement_events_doctor_idx
  ON achievement_events(doctor_id, occurred_at DESC);

4) How to implement the “ethical gamification” cleanly
A) “Patient Appreciation” (public)

Use doctor_appreciation_stats.appreciated_total_distinct_patients

Copy for profile:
“183 Patients Appreciated this Doctor”

Optional: show “Appreciated recently” using last 30 days count (still calm).

B) System achievements (examples + criteria)

You can implement these as either:

event-driven (award immediately when doctor completes action), or

scheduled evaluation (nightly job checks criteria)

Recommended split:

Event-driven (instant gratification):

Profile Completed (when required fields filled)

Uploaded Professional Photo

Added Office Hours (created schedule_rules)

Connected Calendar (if you integrate)

Verified Credentials (admin action)

Scheduled evaluation (metrics):

Active this Month (last login/activity)

Consistent Availability (e.g., schedule maintained over last X days)

Highly Appreciated (tiers based on appreciation stats)

Low No-Show Rate (requires appointment outcomes)

C) “Highly Appreciated” tiers (calm + meaningful)

Instead of showing ranks, show tiers:

Tier 1: 25+ distinct patients

Tier 2: 100+

Tier 3: 300+

These tiers are recomputed, not “permanent glory”. That avoids toxicity and keeps it honest.

Implementation: nightly job reads doctor_appreciation_stats and updates doctor_achievements for the tier definition.

5) Ash modeling notes (how to do it professionally)

DoctorAppreciation as an Ash resource

create action appreciate_appointment(appointment_id)

validations:

appointment belongs to actor patient

appointment doctor matches

status eligible

not already appreciated (DB unique handles race)

on success:

create appointment_event like patient_appreciated

update stats (either immediate or enqueue job)

AchievementDefinition as a read-mostly resource

DoctorAchievement as resource with actions:

award/2 (system/admin only)

revoke/2

AchievementEvent insert-only resource for audit

6) Integrating with your booking schema

Add one optional event in appointment_events:

action = 'patient_appreciated' with metadata = %{appreciation_id: ...}

And add a UI rule:

Appreciation CTA appears only after appointment completion (or after end time + confirmed)

7) What I would change in your existing text/UX

Keep the label “Patient Appreciation” for the section title

Use “Appreciated” as the verb (exactly as you want)

Don’t show “0 appreciated” loudly. If zero, simply omit the counter.