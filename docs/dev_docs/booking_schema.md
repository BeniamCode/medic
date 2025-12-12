# Booking Schema Reference

> Central reference for all database tables that power availability, slot generation, and appointment booking.

- **appointments** – actual patient bookings plus pricing + snapshots + lifecycle metadata.
- **appointment_events** – append-only event log for appointment lifecycle updates.
- **appointment_resource_claims** – GiST-enforced link between an appointment and the specific capacity unit it consumes.
- **appointment_types** – doctor-defined services (duration, price, modality) exposed to patients.
- **appointment_type_locations** – join table that scopes a service to one or more practice locations.
- **bookable_resources** – canonical capacity units (rooms, telehealth slots, equipment) that can be claimed.
- **schedule_rules**, **schedule_rule_breaks**, **schedule_exceptions** – the new canonical scheduling engine (timezone-aware split shifts + overrides); `availability_rules`/`schedule_templates` remain for legacy UI data entry.
- **availability_rules** – legacy weekday-based window (still powering the current UI until we migrate fully to schedule rules).
- **schedule_templates** & **schedule_template_breaks** – existing rich template engine (to be replaced by schedule rules).
- **availability_exceptions** – historical manual overrides (new work should use `schedule_exceptions`).
- **time_off_requests** – HR-style PTO approvals that eventually generate exceptions.

---

## Table: `appointments`
- **Module**: `Medic.Appointments.Appointment`
- **Purpose**: Stores every booked visit, enforces double-booking prevention with the `no_double_bookings` exclusion constraint, and captures immutable service snapshots.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `starts_at` | `utc_datetime` | Required; beginning of slot |
| `ends_at` | `utc_datetime` | Required; validated > `starts_at` |
| `duration_minutes` | `integer` | Default 30, max 240 |
| `status` | `string` | Enum: pending/confirmed/completed/cancelled/no_show/held (default `pending`) |
| `consultation_mode_snapshot` | `string` | Captured modality (`in_person`/`telemedicine`) |
| `meeting_url` | `string` | For telehealth |
| `notes` | `string` | Patient notes |
| `cancellation_reason` | `string` | Optional text |
| `cancelled_at` | `utc_datetime` | Timestamp of cancellation |
| `price_cents` | `integer` | Optional |
| `currency` | `string` | Default `EUR` |
| `source` | `string` | Default `patient_portal` |
| `reschedule_count` | `integer` | Default 0 |
| `service_name_snapshot` | `string` | Optional immutable service title |
| `service_duration_snapshot` | `integer` | Optional immutable duration |
| `service_price_cents_snapshot` | `integer` | Optional immutable fee |
| `service_currency_snapshot` | `string` | Optional immutable currency |
| `external_reference` | `string` | 3P calendar/payment id |
| `hold_expires_at` | `utc_datetime` | When a held slot auto-expires |
| `created_by_actor_type`/`_id` | `string`/`uuid` | Audit trail for creation |
| `cancelled_by_actor_type`/`_id` | `string`/`uuid` | Actor metadata for cancellations |
| `patient_timezone` | `string` | Captured at booking time |
| `doctor_timezone` | `string` | Captured at booking time |
| `inserted_at`/`updated_at` | `utc_datetime` | Managed by `timestamps()` |

**Foreign keys**: `patient_id` → `patients`, `doctor_id` → `doctors`, `doctor_location_id` → `doctor_locations`, `location_room_id` → `location_rooms`, `appointment_type_id` → `appointment_types`.

---

## Table: `appointment_events`
- **Module**: `Medic.Appointments.AppointmentEvent`
- **Purpose**: Immutable audit log describing status changes, reminders sent, etc.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `appointment_id` | `uuid` | FK to `appointments` |
| `occurred_at` | `utc_datetime` | Required |
| `actor_type` | `string` | e.g., `system`, `patient`, `doctor` |
| `actor_id` | `uuid` | Optional reference to actor |
| `action` | `string` | e.g., `booked`, `confirmed`, `cancelled` |
| `metadata` | `map` | JSON blob, default `%{}` |
| `inserted_at`/`updated_at` | `utc_datetime` | Standard timestamps |

---

## Table: `appointment_types`
- **Module**: `Medic.Appointments.AppointmentType`
- **Purpose**: Configurable services patients can book (duration, price, modality, rescheduling rules).

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `doctor_id` | `uuid` | Owning doctor |
| `slug` | `string` | Required, unique per doctor |
| `name` | `string` | Required patient-facing title |
| `description` | `string` | Optional |
| `duration_minutes` | `integer` | Default 30, <= 360 |
| `buffer_before_minutes` | `integer` | Default 0 |
| `buffer_after_minutes` | `integer` | Default 0 |
| `price_cents` | `integer` | Optional |
| `currency` | `string` | Default `EUR` |
| `consultation_mode` | `string` | `in_person`/`video`/`phone` |
| `default_location_id` | `uuid` | Optional FK |
| `default_room_id` | `uuid` | Optional FK |
| `is_active` | `boolean` | Default `true` |
| `allow_patient_reschedule` | `boolean` | Default `true` |
| `min_notice_minutes` | `integer` | Default 0 |
| `max_future_days` | `integer` | Default 60 |
| `max_reschedule_count` | `integer` | Default 2 |
| `notes` | `string` | Internal notes |
| `inserted_at`/`updated_at` | `utc_datetime` | Standard |

**Relationships**: `has_many :schedule_templates`, `has_many :appointments`, `has_many :appointment_type_locations`.

---

## Table: `appointment_type_locations`
- **Module**: `Medic.Appointments.AppointmentTypeLocation`
- **Purpose**: Many-to-many join gating each appointment type to allowed doctor locations.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `appointment_type_id` | `uuid` | FK to `appointment_types` |
| `doctor_location_id` | `uuid` | FK to `doctor_locations` |
| `inserted_at`/`updated_at` | `utc_datetime` | Standard |

**Constraint**: unique composite `appointment_type_id + doctor_location_id` prevents duplicates.

---

## Table: `availability_rules`
- **Module**: `Medic.Scheduling.AvailabilityRule`
- **Purpose**: Simplified weekly working windows editable from the doctor schedule UI.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `doctor_id` | `uuid` | FK to `doctors` |
| `day_of_week` | `integer` | ISO 1 (Mon) – 7 (Sun) |
| `start_time` | `time` | Daily start |
| `end_time` | `time` | Daily stop |
| `break_start` | `time` | Optional |
| `break_end` | `time` | Optional |
| `slot_duration_minutes` | `integer` | Default 30, <= 240 |
| `is_active` | `boolean` | Default `true` |
| `inserted_at`/`updated_at` | `utc_datetime` | Standard |

**Constraint**: unique `(doctor_id, day_of_week)` ensures a single rule per weekday.

---

## Table: `bookable_resources`
- **Module**: `Medic.Scheduling.BookableResource`
- **Purpose**: Canonical capacity units (rooms, telehealth slots, equipment) that appointments claim. Supports parallel sessions simply by adding more rows.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `doctor_id` | `uuid` | Owner |
| `doctor_location_id` | `uuid` | Optional location scope |
| `location_room_id` | `uuid` | Optional concrete room |
| `resource_type` | `string` | Enum: room/telehealth_slot/equipment/staff |
| `label` | `string` | Friendly name |
| `capacity` | `integer` | Default 1 (used for UI hints) |
| `is_active` | `boolean` | Default true |
| `inserted_at`/`updated_at` | `utc_datetime` | Standard |

---

## Table: `schedule_rules`
- **Module**: `Medic.Scheduling.ScheduleRule`
- **Purpose**: Canonical weekly working windows in the doctor’s timezone. Supports split shifts, per-service/per-location scoping, and configurable slot interval/buffers.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `doctor_id` | `uuid` | Owner |
| `timezone` | `string` | IANA TZ (default Europe/Athens) |
| `scope_appointment_type_id` | `uuid` | Optional filter |
| `scope_doctor_location_id` | `uuid` | Optional filter |
| `scope_location_room_id` | `uuid` | Optional filter |
| `day_of_week` | `integer` | 1–7 |
| `work_start_local` | `time` | Local start |
| `work_end_local` | `time` | Local end |
| `slot_interval_minutes` | `integer` | Default 30 |
| `buffer_before_minutes` / `buffer_after_minutes` | `integer` | Default 0 |
| `label` | `string` | Optional name |
| `priority` | `integer` | Sorting when overlapping rules exist |
| `inserted_at`/`updated_at` | `utc_datetime` | Standard |

---

## Table: `schedule_rule_breaks`
- **Module**: `Medic.Scheduling.ScheduleRuleBreak`
- **Purpose**: Recurring intraday breaks attached to schedule rules.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `schedule_rule_id` | `uuid` | FK |
| `break_start_local` | `time` | Required |
| `break_end_local` | `time` | Required |
| `label` | `string` | Optional |
| `inserted_at`/`updated_at` | `utc_datetime` | Standard |

---

## Table: `schedule_exceptions`
- **Module**: `Medic.Scheduling.ScheduleException`
- **Purpose**: Manual overrides layered on top of rules (blocked vs. available windows). Supersedes `availability_exceptions` going forward.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `doctor_id` | `uuid` | Owner |
| `schedule_rule_id` | `uuid` | Optional FK for context |
| `appointment_type_id` | `uuid` | Optional scope |
| `doctor_location_id` / `location_room_id` | `uuid` | Optional scope |
| `starts_at` / `ends_at` | `utc_datetime` | Required window |
| `exception_type` | `string` | `blocked` / `available` |
| `reason` | `string` | Optional |
| `source` | `string` | `manual`, `import`, etc. |
| `inserted_at`/`updated_at` | `utc_datetime` | Standard |

---

## Table: `schedule_templates`
- **Module**: `Medic.Scheduling.ScheduleTemplate`
- **Purpose**: Advanced version of availability rules that ties availability to a specific appointment type/location and supports buffers/parallel sessions.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `doctor_id` | `uuid` | FK |
| `doctor_location_id` | `uuid` | FK |
| `location_room_id` | `uuid` | FK |
| `appointment_type_id` | `uuid` | FK |
| `day_of_week` | `integer` | Required |
| `slot_duration_minutes` | `integer` | Default 30 |
| `work_start` | `time` | Required |
| `work_end` | `time` | Required |
| `buffer_before_minutes` | `integer` | Default 0 |
| `buffer_after_minutes` | `integer` | Default 0 |
| `max_parallel_sessions` | `integer` | Default 1 |
| `priority` | `integer` | Default 0 |
| `inserted_at`/`updated_at` | `utc_datetime` | Standard |

---

## Table: `schedule_template_breaks`
- **Module**: `Medic.Scheduling.ScheduleTemplateBreak`
- **Purpose**: Named intraday breaks associated with a template (lunch, rounds, etc.).

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `schedule_template_id` | `uuid` | FK to `schedule_templates` |
| `break_start` | `time` | Required |
| `break_end` | `time` | Required |
| `label` | `string` | Optional |
| `inserted_at`/`updated_at` | `utc_datetime` | Standard |

---

## Table: `availability_exceptions`
- **Module**: `Medic.Scheduling.AvailabilityException`
- **Purpose**: Manual overrides for single blocks (doctor day off) or ad-hoc openings.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `doctor_id` | `uuid` | FK |
| `appointment_type_id` | `uuid` | Optional FK |
| `doctor_location_id` | `uuid` | Optional FK |
| `starts_at` | `utc_datetime` | Required |
| `ends_at` | `utc_datetime` | Required |
| `status` | `string` | Default `blocked` (`blocked`/`available`) |
| `reason` | `string` | Optional descriptor |
| `source` | `string` | Default `manual` |
| `inserted_at`/`updated_at` | `utc_datetime` | Standard |

---

## Table: `time_off_requests`

---

## Table: `appointment_resource_claims`
- **Module**: `Medic.Appointments.AppointmentResourceClaim`
- **Purpose**: Binds an appointment to a `bookable_resource` and enforces overlap prevention with a GiST exclusion constraint. Supports releasing/holding resources.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `appointment_id` | `uuid` | FK to appointments |
| `bookable_resource_id` | `uuid` | FK to bookable_resources |
| `starts_at` / `ends_at` | `utc_datetime` | Mirrors appointment window |
| `status` | `string` | `active`, `released`, `cancelled` |
| `inserted_at`/`updated_at` | `utc_datetime` | Standard |

The DB-level constraint `EXCLUDE USING gist (resource_id WITH =, tsrange(starts_at, ends_at) WITH &&)` ensures a single resource cannot overlap while `status = 'active'`.
- **Module**: `Medic.Scheduling.TimeOffRequest`
- **Purpose**: Tracks PTO requests that, once approved, should yield availability exceptions.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `doctor_id` | `uuid` | FK |
| `starts_at` | `utc_datetime` | Required |
| `ends_at` | `utc_datetime` | Required |
| `status` | `string` | Default `pending` (`pending`/`approved`/`denied`) |
| `reason` | `string` | Optional |
| `notes` | `string` | Optional |
| `approved_by_id` | `uuid` | FK to `accounts` user who approved |
| `inserted_at`/`updated_at` | `utc_datetime` | Standard |

---

### How to extend
- When adding new booking tables, document them here with the same format so this file stays the canonical schema catalog for product + engineering.
- Source code references are provided so you can inspect validations or relationships directly in the Ash resources.
