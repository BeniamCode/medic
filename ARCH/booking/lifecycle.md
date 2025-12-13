Here’s a professional, production-grade booking lifecycle that fits Phoenix + Ash + Postgres + Inertia + TanStack Query, with notifications, audit events, and where PubSub helps.

1) Booking lifecycle states

Use these statuses (simple, covers everything):

held – temporary reservation while patient is checking details / OTP / payment. Has hold_expires_at.

pending – request awaiting doctor approval (only if doctor requires approval). Has pending_expires_at.

confirmed – appointment is booked and reserved.

completed – appointment took place.

cancelled – cancelled by patient/doctor/system.

no_show – patient didn’t attend.

Key rule: capacity is consumed only while status ∈ {held, pending, confirmed}.

2) Allowed transitions (the state machine)
Core transitions

held → confirmed (auto-approve flow)

held → pending (doctor-approval flow)

held → cancelled (patient backs out OR hold expires)

pending → confirmed (doctor approves)

pending → cancelled (doctor rejects OR pending expires OR patient cancels)

confirmed → cancelled (patient/doctor cancels within policy)

confirmed → completed (doctor marks done OR auto-mark after end time + grace)

confirmed → no_show (doctor marks no-show OR auto-mark after grace)

completed/no_show/cancelled are terminal (no more changes except metadata/audit).

Reschedule (best practice)

Reschedule is not a “move the same row around freely”. Do it as:

Create a new appointment (held/pending/confirmed)

Link it: rescheduled_from_appointment_id

Cancel old one with reason rescheduled
This keeps audit clean and avoids weird histories.

3) What must happen in each booking action (atomic + auditable)

Every user-visible change should be an Ash action that is transactional:

A) hold_slot(patient, doctor, type, starts_at)

Transaction:

Insert appointment with status='held', hold_expires_at = now()+5min

Create resource claim (your overlap-proof lock)

Insert appointment_event: 'held_created'

Queue notifications? usually no (wait until confirmed/pending)

Failure modes:

resource claim overlap → “slot taken”

B) confirm_booking(appointment_id) (auto-approve)

Transaction:

Validate still held and not expired

Update status → confirmed

Insert event confirmed

Create notification jobs: confirmation + reminders (see below)

C) submit_request(appointment_id) (approval-required)

Transaction:

Validate still held and not expired

Update status → pending, set pending_expires_at = now()+24h (or 12h)

Event request_submitted

Queue doctor notification: “new request”

D) approve_request(appointment_id) / reject_request(appointment_id)

Transaction:

Approve: pending → confirmed, event approved, schedule reminders

Reject: pending → cancelled, event rejected, release capacity (delete claim), notify patient

E) cancel_appointment(actor, appointment_id)

Transaction:

Validate cancellation policy (min notice, cutoff, who can cancel)

Update → cancelled, set cancelled_at, cancelled_by_*, reason

Event cancelled

Release capacity (delete claim)

Queue notifications to the other party

F) complete_appointment(doctor, appointment_id) / mark_no_show

Transaction:

Update status, event, optional follow-up notifications (“you can appreciate this doctor”)

4) Appointment events (what to log)

Keep appointment_events append-only. Record at least:

held_created, hold_expired

request_submitted, approved, rejected, pending_expired

confirmed

cancelled_by_patient, cancelled_by_doctor, cancelled_by_system

rescheduled (metadata links new appointment id)

reminder_scheduled, reminder_sent, reminder_failed

completed, no_show

This becomes your single source of truth for audits and “why did this happen?”.

5) Notifications design (what, when, how)
Notification channels

Email: baseline (cheap, reliable)

SMS: optional; best for reminders/no-shows

Push: later if you have mobile app

In-app notifications: dashboard inbox for doctors

User preferences (must-have)

Store preferences per user/doctor:

channels allowed (email/sms/push)

reminder timing choices

quiet hours (optional)

language/locale

Notification schedule (recommended defaults)

When confirmed:

Patient: “Confirmed” immediately

Doctor: “New confirmed appointment” immediately

Reminders:

T-24h (email)

T-2h (sms/email)

T-15m (optional, sms)

Post-visit:

T+1h: “Thanks / instructions” (optional)

T+24h: “Appreciate this doctor” CTA (if you do appreciation)

When pending:

Doctor: immediate “new request”

Patient: “request received” immediately

If expiring soon: patient ping at T-(1h) from pending expiry

When cancelled:

Both parties notified immediately (and include next steps / rebook link)

Reliability best practice: Notification jobs + deliveries

Don’t “send email directly inside the action”. Instead:

Action creates notification_job rows (outbox pattern)

A worker processes jobs, records notification_deliveries

Delivery is idempotent (safe to retry)

Minimal tables you want:

notification_jobs (what to send, when)

notification_deliveries (attempt history, provider response, status)

notification_preferences (per user)

This avoids “booking succeeded but notification failed” being a mess.

6) Do you need PubSub?
Internally: Yes (strongly recommended)

Use Phoenix.PubSub inside the backend so that when an appointment changes you can:

invalidate availability caches

trigger workers

update dashboards in real time

decouple booking code from UI and notifications

Externally to the browser: optional but very useful

With Inertia, you can still use:

WebSocket channel (Phoenix Channels)

or SSE

What you get if you wire it:

Doctor dashboard updates instantly when a request arrives

Slot availability UI can refresh when a slot is taken

No manual refresh loops

Minimal approach that works great:

backend broadcasts "appointments:doctor:#{doctor_id}" events

frontend listens and calls queryClient.invalidateQueries(...) for:

appointmentsList(doctor_id, range)

availability(doctor_id, type_id, range)

If you don’t do realtime yet, polling every 15–30 seconds can work initially—but realtime is a “world class” feel, especially for doctors.

7) “Auto-approve toggle” (best UX + doctor control)

Add on appointment_types (or doctor settings):

requires_approval boolean default false

Behavior:

If requires_approval=false: held → confirmed immediately

If true: held → pending and notify doctor

This gives you modern UX without forcing doctors into discomfort.

8) What needs to be done (implementation checklist)
Booking core (must)

 resource-claim overlap prevention in Postgres

 Ash actions for each transition (held/confirm/request/approve/reject/cancel/complete/no_show)

 event log for every transition

 hold expiry job + pending expiry job

 cancellation policy enforcement (min notice, max reschedules)

Notifications (must for production)

 notification_jobs + deliveries tables

 worker processing (Oban is common in Phoenix; any job runner works)

 templates + localization

 idempotency keys per delivery

PubSub (recommended)

 internal broadcasts on key events

 optional socket/SSE to frontend for “world class” dashboard feel