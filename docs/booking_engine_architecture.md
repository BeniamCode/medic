# Booking Engine Architecture

## Domain Overview

Medic's scheduling platform replaces Cal.com with a verticalized booking stack built around doctors, appointment types, and realtime availability guarantees. Everything revolves around deterministic schedule templates + overrides, atomic appointment booking, and cross-channel notifications.

## Core Entities

### Doctor
- Already exists in `Medic.Doctors.Doctor`
- Needs associations to: locations, appointment types, schedule templates, time off records, calendar connections.

### Location (`doctor_locations`)
- Fields: `id (uuid)`, `doctor_id (uuid)`, `name`, `address`, `city`, `country`, `timezone`, `lat`, `lng`, `is_primary`.
- A doctor can operate across multiple sites, each with its own timezone + rooms.
- Index on `doctor_id` for lookups.

### Consultation Room (`location_rooms`)
- Fields: `id (uuid)`, `doctor_location_id`, `name`, `capacity`, `is_virtual`.
- Used to prevent double-bookings per room when multiple appointments happen concurrently.

### Appointment Type (`appointment_types`)
- Scoped per doctor (with optional global templates later).
- Fields: `id`, `doctor_id`, `slug`, `name`, `description`, `duration_minutes`, `buffer_before_minutes`, `buffer_after_minutes`, `price_cents`, `currency`, `consultation_mode` (`in_person`, `video`, `phone`), `default_location_id`, `default_room_id`, `is_active`, `allow_patient_reschedule`, `min_notice_minutes`, `max_future_days`.
- Associations: `has_many appointment_type_locations` join for multi-site availability.
- Unique index on `(doctor_id, slug)`.

### Weekly Schedule Template (`schedule_templates`)
- Records a doctor's recurring weekly cadence.
- Fields: `id`, `doctor_id`, `location_id`, `room_id`, `day_of_week`, `slot_duration_minutes`, `work_start`, `work_end`, `buffer_before_minutes`, `buffer_after_minutes`, `max_parallel_sessions`, `priority`.
- Additional table `schedule_template_breaks` containing `break_start`, `break_end`, optional reason.

### Availability Overrides
- `availability_exceptions`: explicit `start_at`, `end_at`, `status` (`blocked`, `available`), optional appointment type restriction, optional location.
- `time_off_requests`: doctor-managed PTO/vacation with approvals, persisted as `blocked` overrides.

### Appointment (`appointments` table update)
- Extend with `doctor_location_id`, `location_room_id`, `appointment_type_id`, `price_cents`, `currency`, `source` (`patient_portal`, `doctor`, `api`), `reschedule_count`, `cancelled_by`, `patient_timezone`, `doctor_timezone`.
- Maintain `status` state machine: `pending`, `confirmed`, `declined`, `cancelled`, `completed`, `no_show`.

### Patient Profile (already in `Medic.Patients.Patient`)
- Additional fields: `preferred_language`, `preferred_timezone`, `communication_preferences` (JSONB), `emergency_contact`.

### Booking Audit (`appointment_events`)
- Append-only log: `id`, `appointment_id`, `occurred_at`, `actor_type`, `actor_id`, `action`, `metadata` (JSONB).
- Powers timeline UI + compliance.

### Notification Dispatch (`notifications` existing)
- Extend schema to include `channel` (`email`, `sms`, `push`), `template`, `payload`, `sent_at`, `provider_message_id`, `error_reason`.
- Build service layered on Swoosh + SMS adapter.

### Calendar Connections (`calendar_connections`)
- Store OAuth tokens for Google (and future providers).
- Fields: `id`, `doctor_id`, `provider`, `access_token`, `refresh_token`, `expires_at`, `scopes`, `sync_cursor`, `last_synced_at`, encrypted columns via `cloak_ecto` or custom AES.

### Synced External Events (`external_busy_times`)
- Flattened busy ranges from remote calendars.
- Fields: `id`, `doctor_id`, `connection_id`, `external_id`, `starts_at`, `ends_at`, `status`, `source`, `last_seen_at`.

## Services & Context Modules

1. **Availability Service** (`Medic.Scheduling.AvailabilityEngine`)
   - Input: doctor, date range, appointment type.
   - Combines schedule templates, breaks, overrides, existing appointments, and external busy times.
   - Emits normalized slot structs `%Slot{starts_at, ends_at, location_id, room_id, appointment_type_id, capacity_left}`.
   - Responsible for applying buffer rules and ensuring timezone-safe conversions (store in UTC, compute via `Timex` or `Calendar`).

2. **Booking Service** (`Medic.Bookings`) 
   - Orchestrates patient booking/reschedule/cancel flows.
   - Validates patient contact info, reason, and appointment type compatibility.
   - Persists booking, writes audit event, schedules notifications, and triggers calendar sync writes.
   - Exposes `book_slot/4`, `reschedule/3`, `cancel/3`, `list_patient_bookings/2`, `list_doctor_schedule/2` APIs.

3. **Doctor Availability Manager** (`Medic.Doctors.Availability`)
   - CRUD endpoints for schedule templates, breaks, time off, overrides, multi-location assignments.
   - LiveView UI for doctors to update weekly templates with drag/drop interactions (phase 2).

4. **Notification Pipeline** (`Medic.Notifications.Dispatcher`)
   - Accepts event payloads (booking_created, reminder_due, cancellation) and resolves templates.
   - Enqueues background jobs via Oban for retries and scheduled reminders.

5. **Calendar Sync Service** (`Medic.CalendarSync`)
   - Handles OAuth, token refresh, incremental sync, change detection, and push notifications.
   - Normalizes remote events into `external_busy_times` and issues writes back to provider for confirmed appointments.

6. **Patient Portal LiveView** (`MedicWeb.PatientPortalLive`)
   - Authenticated view for patients to see upcoming/past appointments, reschedule/cancel, and update preferences.

7. **Doctor Console LiveView** (`MedicWeb.DoctorScheduleLive`)
   - Agenda views (list/day/week), quick actions (accept/decline, block time, edit templates), and analytics cards.

## Workflow Highlights

1. **Slot Generation**
   - Query schedule templates for date range, group by day.
   - Expand into raw slots using `slot_duration`.
   - Apply breaks + overrides to prune.
   - Fetch booked appointments and external busy ranges, subtract buffers.
   - Return final list with metadata for UI tooltips.

2. **Booking Flow**
   - Patient selects appointment type.
   - Availability API returns slots respecting type-specific rules.
   - Booking service transactionally inserts appointment with `for update` locks on `appointments` table to avoid race conditions.
   - On success: create audit event, dispatch notifications, push to Google via sync service.

3. **Reschedule/Cancel Policies**
   - Each appointment type stores `min_notice_minutes` and `max_reschedule_count`.
   - Booking service enforces these rules; system can decline operations returning actionable errors for UI.

4. **Notifications**
   - Templates stored under `priv/templates/notifications/`.
   - Reminder scheduling uses Oban cron job to enqueue `ReminderWorker` which inspects `appointments` table for upcoming events and schedules channel-specific dispatches.

5. **Calendar Sync**
   - OAuth handshake handled in UI; tokens stored encrypted.
   - Background job polls Google incremental sync API using saved `sync_token`.
   - Busy events inserted into `external_busy_times` to influence availability calculations.

## Data Access Patterns

- Use Ecto for transactional data writes even though Ash resources exist; wrap inside contexts for clarity.
- Preload associations when rendering LiveViews to avoid N+1 (appointments -> patient -> contact info).
- Add database indexes for frequent queries: `appointments (doctor_id, starts_at)`, `availability_exceptions (doctor_id, starts_at)`, etc.

## Testing Strategy

- Unit tests for availability math via doctests + data-driven cases.
- LiveView tests to ensure booking/reschedule flows behave.
- Integration tests hitting booking API with simulated concurrent bookings via `Task.async_stream`.
- Mock Google API via `Req.Test` adapters for deterministic sync tests.

This document guides the upcoming implementation sequence and provides a single source of truth for engineers contributing to the booking engine.
