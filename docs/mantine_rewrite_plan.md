# Mantine Rewrite Plan

Branch: `mantine`

## Objectives
1. Decommission Phoenix LiveView front-end in favor of Inertia.js + React.
2. Deliver a Mantine + Zustand powered UI with premium UX, micro-interactions, and responsive layouts.
3. Preserve Phoenix authentication/authorization flows, i18n via Gettext, and existing business logic contexts.
4. Keep patient/doctor/admin feature sets at parity or better.
5. Ensure multi-locale readiness and eliminate hard-coded strings.

## Architecture Changes
- **Server**
  - Add `:inertia_phoenix` dependency.
  - Introduce `MedicWeb.InertiaController` helpers and a plug that injects shared props (current_user, locale, flashes, permissions, translations).
  - Replace `live_session` routes in `lib/medic_web/router.ex` with controller actions that call `inertia/3`.
  - Expose supporting JSON endpoints for async React interactions (search filters, booking slots, schedule CRUD, admin actions).
  - Ensure authentication plugs remain enforced inside the same route scopes.

- **Client**
  - Replace `assets/js/app.js` with `app.tsx` bootstrapping the Inertia React app, Mantine providers, and Zustand stores.
  - Maintain Tailwind CSS pipeline but lean on Mantine components for layout/interaction polish.
  - Add packages: `react`, `react-dom`, `@inertiajs/core`, `@inertiajs/react`, `@inertiajs/progress`, `@mantine/core`, `@mantine/hooks`, `@mantine/dates`, `@mantine/notifications`, `@emotion/react`, `@emotion/styled`, `zustand`, `react-i18next`, `mapbox-gl` and wrappers, `@tabler/icons-react` (for icons alongside Phoenix <.icon> when needed), testing deps (`vitest`, `@testing-library/react`).
  - Create shared layouts (`PublicLayout`, `AuthenticatedLayout`, `AdminLayout`) with Mantine `AppShell`s.
  - Build Zustand stores for session, UI, search, booking, and admin state.
  - Implement translation hydration (server sends locale + translation map, client wires `react-i18next`).

## Page Inventory & React Targets
| Route | Current LiveView | Audience | React Component |
| --- | --- | --- | --- |
| `/` | `MedicWeb.HomeLive` | Public | `pages/Home.tsx` |
| `/search` | `MedicWeb.SearchLive` | Public/Auth | `pages/Search.tsx` |
| `/doctors/:id` | `MedicWeb.DoctorLive.Show` + Booking component | Public/Auth | `pages/DoctorProfile.tsx` |
| `/login` | `MedicWeb.UserLoginLive` | Guest | `pages/auth/Login.tsx` |
| `/register` | `MedicWeb.UserRegistrationLive` | Guest | `pages/auth/RegisterPatient.tsx` |
| `/register/doctor` | `MedicWeb.UserRegistrationLive` (:doctor) | Guest | `pages/auth/RegisterDoctor.tsx` |
| `/dashboard` | `MedicWeb.DashboardLive` | Patients | `pages/patient/Dashboard.tsx` |
| `/appointments/:id` | `MedicWeb.AppointmentLive.Show` | Patients | `pages/patient/AppointmentDetail.tsx` |
| `/settings` | `MedicWeb.SettingsLive` | Patients | `pages/patient/Settings.tsx` |
| `/onboarding/doctor` | `MedicWeb.DoctorOnboardingLive` | Doctors | `pages/doctor/Onboarding.tsx` |
| `/doctor/schedule` | `MedicWeb.DoctorLive.Schedule` | Doctors | `pages/doctor/Schedule.tsx` |
| `/dashboard/doctor` | `MedicWeb.DoctorDashboardLive` | Doctors | `pages/doctor/Dashboard.tsx` |
| `/dashboard/doctor/profile` | `MedicWeb.DoctorLive.Profile` | Doctors | `pages/doctor/Profile.tsx` |
| `/medic/login` | `MedicWeb.AdminLoginLive` | Admin | `pages/admin/Login.tsx` |
| `/medic/dashboard` | `MedicWeb.Admin.DashboardLive` | Admin | `pages/admin/Dashboard.tsx` |
| `/medic/doctors` (+edit) | `MedicWeb.Admin.DoctorLive.Index` | Admin | `pages/admin/Doctors.tsx` |
| `/medic/patients` (+edit) | `MedicWeb.Admin.PatientLive.Index` | Admin | `pages/admin/Patients.tsx` |
| `/medic/on_duty` | `MedicWeb.Admin.OnDutyLive` | Admin | `pages/admin/OnDuty.tsx` |
| `/medic/reviews` | `MedicWeb.Admin.ReviewLive.Index` | Admin | `pages/admin/Reviews.tsx` |
| `/medic/financials` | `MedicWeb.Admin.FinancialLive` | Admin | `pages/admin/Financials.tsx` |

## Feature Blueprints
### Search Experience
- Mantine `AppShell` split layout: filter rail (Accordion + Selects + RangeSlider) & result grid.
- Zustand `useSearchStore` drives query, filters, pagination, map bounds; server sync via `Inertia.visit` with partial component reloads.
- Map: Mapbox GL React component with custom doctor markers & cluster popovers, data from server prop `doctors_map`.
- Provide saved searches + chips for active filters; micro-interactions using Mantine `Transition`.

### Doctor Profile & Booking
- Sticky hero with doctor info, rating, verified badge.
- Tabs for Overview, Expertise, Reviews, Location.
- Booking drawer using Mantine `Drawer` (mobile) / `Affix` (desktop) with `DatePicker`, slot timeline, telemedicine toggle, notes textarea.
- Calendar fetch via `/api/doctors/:id/slots?week=YYYY-WW` (Req-backed controller) with SSE refresh option.
- Confirmation modal with celebratory animation.

### Patient Dashboard
- Mantine `Grid` with KPIs (RingProgress), upcoming timeline, history table.
- Quick-action cards (reschedule, join telemed) hooking existing appointment endpoints.

### Doctor Tools
- Schedule Manager: Weekly grid (custom component) with drag handles. Modal for editing rules, break periods.
- Profile editor: Multi-tab form for specialties, pricing, compliance, photos (upload to existing storage pipeline).
- Dashboard: KPI cards, next appointments list, tasks list.

### Admin Suite
- Shared `AdminLayout` with sticky sidebar, global search, theme toggle.
- Tables with server-side pagination filters, inline edits, bulk actions.
- Financial dashboards using Mantine Charts (line, bar). Export to CSV.

## APIs to Add / Reuse
- `/api/search` – JSON for incremental filtering.
- `/api/doctors/:id/slots` – time slots for booking.
- `/api/appointments/:id/cancel`, `/api/appointments/:id/reschedule` – JSON actions.
- `/api/doctor/schedule` – CRUD for availability rules.
- `/api/admin/...` – endpoints for data tables if Inertia partial reloads insufficient.

All controllers must rely on existing contexts (`Medic.Search`, `Medic.Scheduling`, `Medic.Appointments`, etc.) and use `Req` for outbound HTTP.

## Testing Strategy
- Phoenix request tests per Inertia endpoint to assert component name, props, auth checks.
- React unit tests via Vitest + Testing Library for filters, booking flow, schedule grid.
- Cypress (optional) for core flows once build stabilizes.
- Run `mix precommit` before every push.

## Checklist
- [x] Create `mantine` branch.
- [x] Document rewrite plan (this file).
- [x] Add `:inertia_phoenix` and configure shared props plug.
- [ ] Convert router scopes to Inertia controllers while keeping auth pipelines. *(Home/Search/Doctor public routes converted; remaining scopes pending)*
- [x] Scaffold React/Mantine app entry + providers + layouts.
- [ ] Build shared Zustand stores (session, ui, search, booking, admin).
- [ ] Reimplement public pages (Home, Search, DoctorProfile + booking).
- [ ] Reimplement auth + registration flows.
- [ ] Reimplement patient dashboard, appointment detail, settings.
- [ ] Reimplement doctor flows (dashboard, schedule, profile, onboarding).
- [ ] Reimplement admin suite (dashboard, doctors, patients, on-duty, reviews, financials).
- [ ] Build supporting JSON APIs (search, slots, schedule, booking, admin actions).
- [x] Wire translation hydration + enforce no hard-coded strings.
- [ ] Recreate notification/toast system via Mantine notifications.
- [ ] Add React + Phoenix tests; ensure `mix precommit` passes.
