# Booking Delivery Plan

## Phase 1 – Data Layer Foundations (Week 1)
1. **Migrations**
   - Create tables: `doctor_locations`, `location_rooms`, `appointment_types`, `appointment_type_locations`, `schedule_templates`, `schedule_template_breaks`, `availability_exceptions`, `time_off_requests`, `appointment_events`, `calendar_connections`, `external_busy_times`.
   - Extend `appointments`, `patients`, `notifications` with new columns and indexes.
2. **Contexts & Schemas**
   - Implement Ash resources + Ecto contexts for the new tables.
   - Shared validations (buffers, overlapping breaks, unique slugs).
3. **Seeds/Factories**
   - Update `priv/repo/seeds.exs` and test factories to include new structures for realistic fixtures.

## Phase 2 – Availability Engine (Week 2)
1. **Slot computation service** leveraging templates + overrides + busy times.
2. **Buffer + type-aware logic** to enforce `min_notice`, `max_future` and `capacity`.
3. **Unit tests** covering complex scheduling edge cases across multiple locations and overrides.

## Phase 3 – Booking & Patient Flow (Week 3)
1. **Booking context (`Medic.Bookings`)** orchestrating create/reschedule/cancel.
2. **LiveView booking wizard**: doctor details, appointment type selection, calendar UI, patient form, confirmation.
3. **Patient portal LiveView** with list + actions + event timeline.
4. **Email templates** for confirmation and cancellation.

## Phase 4 – Doctor Console & Availability Management (Week 4)
1. **Doctor agenda LiveView** with day/week toggle, accept/decline, and inline blocking.
2. **Schedule builder UI** to edit weekly templates + breaks + overrides.
3. **Time off request workflow**.

## Phase 5 – Notifications & Calendar Sync (Week 5)
1. **Notification dispatcher** with Swoosh email + SMS abstraction, hooking into booking events.
2. **Reminder scheduling** jobs using Oban.
3. **Google Calendar sync** MVP: OAuth, busy time import, event write-back, conflict resolution.

## Phase 6 – Polish & QA (Week 6)
1. Accessibility + responsive audit of all new LiveViews.
2. Load testing of slot generation and booking endpoints.
3. Observability instrumentation (Telemetry metrics + logs) and dashboard setup.
4. Run `mix precommit` and finalize deployment documentation.

Each phase feeds demoable increments; we can parallelize by assigning engineers to data layer, LiveViews, and integrations, but maintain clear API contracts per phase. This roadmap doubles as the backlog for tracking progress in Linear/Jira.
