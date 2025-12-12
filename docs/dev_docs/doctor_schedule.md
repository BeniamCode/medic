# Doctor Schedule Feature (Doctor Portal)

## Tech + entry points
- **Phoenix 1.8 / Inertia adapter** – `MedicWeb.DoctorScheduleController` serves `/doctor/schedule`, collects assigns, and renders the Inertia view `Doctor/Schedule` with the `assign_prop/3` helper.
- **React + Mantine UI** – front-end rendered from `assets/js/pages/doctor/Schedule.tsx`, styled with Mantine components. Localization uses `react-i18next` and `@mantine/dates` for inputs.
- **React Hook Form** – `useForm` + `Controller` manage the Add/Edit rule modal state with schema defined by `DEFAULT_VALUES`.
- **TanStack Query** – two `useMutation` hooks wrap the Inertia router calls for saving rules and blocking single days while surfacing loading states.
- **Scheduling context** – powered by Ash resources (`Medic.Scheduling.AvailabilityRule` & `AvailabilityException`) persisted via `Medic.Repo`.

## User flows on `/doctor/schedule`
1. **Landing view**
   - `DoctorScheduleController.show/2` loads the doctor linked to `conn.assigns.current_user`.
   - Availability rules are fetched with `Scheduling.list_availability_rules/2` (inactive included) and upcoming appointments via `Appointments.list_appointments/1` (preloading patients).
   - Each rule is serialized by `rule_props/1` (times formatted as `HH:MM` strings) before being sent to Inertia. Appointments are serialized via `appointment_props/1` (ISO datetimes for client formatting).

2. **Weekly rules summary + picker**
   - `dayOptions` hard-code ISO weekdays (1=Mon ... 7=Sun). Buttons across the weekly selector and summary table share this data to stay in sync.
   - `groupedRules` memoizes the `availabilityRules` prop by weekday for O(1) lookups. `initialDrafts` snapshot each day's latest saved values into a `draftRules` state map so edits are preserved while switching tabs before submitting.

3. **Day-off quick action**
   - Uses `DateInput` + `blockDayMutation`. Selecting a date then clicking **Block day** posts to `/doctor/schedule/day_off` with `{exception: {date: ISO-8601}}`. The route now shares the same authenticated `live_session` pipeline as the other schedule endpoints, so the Inertia call no longer 404s.
   - Server `block_day/2` converts the date into `DateTime` boundaries (00:00–23:59 UTC) and creates an `AvailabilityException` labeled `doctor_day_off`. Success flashes “Day blocked”; errors flash failure and re-render.

4. **Upcoming appointments feed**
   - Renders from `upcomingAppointments` prop, showing patient name, localized start time, and a status badge.

## "Add rule" modal (core interaction)
1. **Opening the modal**
   - Clicking **Add rule** (or **Edit** in the table) triggers `openModalForDay(day)`, which:
     - updates `modalDay`, clears any copy source, and `reset`s the React Hook Form state with the cached draft for that weekday.
     - toggles the Mantine `<Modal>` via `useDisclosure`.

2. **Form shape**
   - `DEFAULT_VALUES` aligns with the Phoenix controller’s `normalize_rule_params/1` contract (`day_of_week`, `start_time`, `end_time`, `break_start`, `break_end`, `slot_duration_minutes`, `is_active`).
   - Inputs inside the modal are implemented through `<Controller>` wrappers binding Mantine `TextInput`, `NumberInput`, and `Switch` components to React Hook Form. Since Mantine inputs are controlled components, the controllers translate `event.currentTarget.value` / `checked` into form state updates.
   - A `copy from another day` `<Select>` allows cloning pre-saved settings by copying `draftRules[sourceDay]` with a blank `id` so the server creates a new row instead of updating the source.

3. **Live slot preview**
   - `watch` from React Hook Form subscribes to `start_time`, `end_time`, and `slot_duration_minutes` changes. A subscription syncs edited values back into `draftRules` (in-memory) to keep unsaved edits per-day.
   - `buildPreviewSlots` translates the numeric duration into a chip list so doctors can see the times patients will see. Utility helpers `timeToMinutes` and `minutesToTime` keep formatting consistent with the backend.

4. **Saving (TanStack Query + Inertia)**
   - `saveRuleMutation` wraps an `Inertia.router.post('/doctor/schedule', { rule: values })`. TanStack handles pending state, disables the submit button, and closes the modal on success.
   - Phoenix controller `update/2` receives the payload, normalizes types (`String.to_integer`, blank-to-nil for breaks), stamps the doctor id, and either:
     - calls `Scheduling.create_availability_rule/1` when `id` is empty/nil (new rule), or
     - fetches the target rule via `Scheduling.get_availability_rule!/1` and runs `Scheduling.update_availability_rule/2`.
   - Validations come from the Ash resource (unique weekday per doctor, chronological time checks, optional break windows). Success flashes “Availability saved”; failure re-renders with “Unable to save rule”.

5. **Deleting and deactivating**
   - Each row includes a Delete button calling `router.delete(/doctor/schedule/:id)`. Server `delete/2` ensures the rule belongs to the logged-in doctor before `Scheduling.delete_availability_rule/1`.
   - The modal has a “Available this day” `Switch`. Toggling it posts `is_active: false` on save, and the summary table dims inactive rows via inline opacity + status badges.

## Data model quick reference
- **`availability_rules` table** (`Medic.Scheduling.AvailabilityRule`):
  - `doctor_id` FK, `day_of_week` (1-7), `start_time`, `end_time`, optional `break_start`/`break_end`, `slot_duration_minutes`, `is_active` boolean, timestamps.
  - Unique constraint `availability_rules_doctor_day_unique` ensures one weekly rule per weekday per doctor.
- **`availability_exceptions`** handle ad-hoc blocks created from the Day Off action.
- **Slot generation** downstream uses these records via `Medic.Scheduling.get_slots/3` (not directly on this page but consumes the same data).

## How to extend / debug
- Front-end entry: `assets/js/pages/doctor/Schedule.tsx`.
- Backend controller & routes: `lib/medic_web/controllers/doctor_schedule_controller.ex`, routes defined in `lib/medic_web/router.ex` under authenticated doctor scope.
- Domain logic: `lib/medic/scheduling.ex` and related Ash resources.
- To add new fields (e.g., buffers), update `DEFAULT_VALUES`, the form controllers, controller normalization, and `AvailabilityRule` schema together.
- For API interactions stick to Req via Phoenix contexts; front-end should continue to call Phoenix endpoints through the Inertia router so flash + auth handling remain centralized.
