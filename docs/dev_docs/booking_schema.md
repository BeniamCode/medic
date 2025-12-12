# Booking Schema Reference

> Central reference for all database tables that power availability, slot generation, and appointment booking.

## Entity map
- **appointments** – actual patient bookings plus pricing + status auditing.
- **appointment_events** – append-only event log for appointment lifecycle updates.
- **appointment_types** – doctor-defined services (duration, price, modality) exposed to patients.
- **appointment_type_locations** – join table that scopes a service to one or more practice locations.
- **availability_rules** – weekly recurring working windows captured from `/doctor/schedule` (see `doctor_schedule.md`).
- **schedule_templates** & **schedule_template_breaks** – more advanced recurring templates per appointment type/location, including structured breaks.
- **availability_exceptions** – single-day blocks or overrides such as the "Block day" action.
- **time_off_requests** – HR-style PTO approvals that eventually generate availability exceptions.

---

## Table: `appointments`
- **Module**: `Medic.Appointments.Appointment`
- **Purpose**: Stores every booked visit, enforces double-booking prevention with the `no_double_bookings` exclusion constraint.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `starts_at` | `utc_datetime` | Required; beginning of slot |
| `ends_at` | `utc_datetime` | Required; validated > `starts_at` |
| `duration_minutes` | `integer` | Default 30, max 240 |
| `status` | `string` | Enum: pending/confirmed/completed/cancelled/no_show (default `pending`) |
| `appointment_type` | `string` | Legacy modality (`in_person`/`telemedicine`) |
| `meeting_url` | `string` | For telehealth |
| `notes` | `string` | Patient notes |
| `cancellation_reason` | `string` | Optional text |
| `cancelled_at` | `utc_datetime` | Timestamp of cancellation |
| `price_cents` | `integer` | Optional |
| `currency` | `string` | Default `EUR` |
| `source` | `string` | Default `patient_portal` |
| `reschedule_count` | `integer` | Default 0 |
| `cancelled_by` | `string` | Actor who cancelled |
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
