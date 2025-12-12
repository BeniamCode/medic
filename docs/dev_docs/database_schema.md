# Database Schema Inventory

This document captures the latest schema snapshot straight from `medic_dev.db`. The application itself runs on **PostgreSQL everywhere (dev/test/prod)** via `Medic.Repo` (`AshPostgres.Repo`). The SQLite file is just a developer aid for quickly browsing the schema offline.

## Engines by environment
| Environment | Adapter | Config reference | Notes |
| --- | --- | --- | --- |
| Dev | PostgreSQL (`postgrex`) | `config/dev.exs:4` | Defaults to `postgres://postgres:postgres@localhost/medic_dev` (matches `docker-compose.yml:5`). |
| Test | PostgreSQL (`postgrex`) | `config/test.exs:6` | Uses sandboxed DB `medic_test` per partition. |
| Prod | PostgreSQL (`postgrex`) | `config/runtime.exs:3-25` | Reads `DATABASE_URL`; fallback `DATABASE_PATH` requires a Postgres connection string (there is no Turso/libSQL adapter in deps). |

### Turso / libSQL?
No references exist in the codebase (`rg "turso"` ⇒ none), and `mix.exs` only pulls in `postgrex` + `ash_postgres`. Therefore Turso/SQLite is **not** used by the running app—only Postgres.

## Tables overview
| Table | Purpose |
| --- | --- |
| `appointments` | Stores patient bookings created via Cal.com sync or the internal booking UI |
| `doctors` | Canonical profile + marketplace metadata for each doctor account |
| `patients` | Patient profile records tied 1:1 to `users` |
| `specialties` | Medical specialty lookup used by doctors and search filters |
| `users` | Authentication surface for all roles (patients, doctors, admins) |
| `users_tokens` | Email confirmation/reset tokens keyed by context |
| `schema_migrations` | Ecto migration ledger |

---

## `appointments`
```
CREATE TABLE appointments (
  id TEXT PRIMARY KEY,
  patient_id TEXT REFERENCES patients(id) ON DELETE SET NULL,
  doctor_id TEXT NOT NULL REFERENCES doctors(id) ON DELETE SET NULL,
  scheduled_at TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 30,
  status TEXT NOT NULL DEFAULT 'pending',
  cal_com_booking_id TEXT,
  cal_com_uid TEXT UNIQUE,
  meeting_url TEXT,
  appointment_type TEXT DEFAULT 'in_person',
  notes TEXT,
  cancellation_reason TEXT,
  cancelled_at TEXT,
  inserted_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX appointments_patient_id_index ON appointments(patient_id);
CREATE INDEX appointments_doctor_id_index ON appointments(doctor_id);
CREATE INDEX appointments_scheduled_at_index ON appointments(scheduled_at);
CREATE INDEX appointments_status_index ON appointments(status);
```

**Notes**
- Maintains Cal.com identifiers to reconcile external bookings.
- Status defaults to `pending`; additional statuses enforced at the application layer.

---

## `doctors`
```
CREATE TABLE doctors (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  specialty_id TEXT REFERENCES specialties(id) ON DELETE SET NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  bio TEXT,
  bio_el TEXT,
  profile_image_url TEXT,
  location_lat NUMERIC,
  location_lng NUMERIC,
  address TEXT,
  city TEXT,
  rating NUMERIC DEFAULT 0.0,
  review_count INTEGER DEFAULT 0,
  consultation_fee DECIMAL(10,2),
  cal_com_user_id TEXT,
  cal_com_event_type_id TEXT,
  cal_com_username TEXT,
  next_available_slot TEXT,
  verified_at TEXT,
  inserted_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE UNIQUE INDEX doctors_user_id_index ON doctors(user_id);
CREATE INDEX doctors_specialty_id_index ON doctors(specialty_id);
CREATE INDEX doctors_city_index ON doctors(city);
CREATE INDEX doctors_rating_index ON doctors(rating);
CREATE INDEX doctors_next_available_slot_index ON doctors(next_available_slot);
```

**Notes**
- Links directly to the `users` table for authentication; deleting the user cascades to doctor profile.
- Stores marketplace metrics (rating/reviews) and Cal.com sync identifiers.

---

## `patients`
```
CREATE TABLE patients (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  date_of_birth TEXT,
  phone TEXT,
  emergency_contact TEXT,
  profile_image_url TEXT,
  inserted_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE UNIQUE INDEX patients_user_id_index ON patients(user_id);
```

**Notes**
- Every patient account maps to exactly one `users` row.
- Stores emergency contact metadata for future triage features.

---

## `specialties`
```
CREATE TABLE specialties (
  id TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_el TEXT NOT NULL,
  slug TEXT NOT NULL,
  icon TEXT,
  inserted_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE UNIQUE INDEX specialties_slug_index ON specialties(slug);
```

**Notes**
- Slugs drive localized filtering; both English and Greek names are stored for bilingual experiences.

---

## `users`
```
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  hashed_password TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'patient',
  confirmed_at TEXT,
  totp_secret BLOB,
  inserted_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

**Notes**
- Roles currently include `patient`, `doctor`, and `admin`.
- `totp_secret` column exists for future MFA support.

---

## `users_tokens`
```
CREATE TABLE users_tokens (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token BLOB NOT NULL,
  context TEXT NOT NULL,
  sent_to TEXT,
  inserted_at TEXT NOT NULL
);
CREATE INDEX users_tokens_user_id_index ON users_tokens(user_id);
CREATE UNIQUE INDEX users_tokens_context_token_index ON users_tokens(context, token);
```

**Notes**
- Used for confirmation, password reset, and similar flows.
- Composite unique index ensures each raw token/context pair exists only once.

---

## `schema_migrations`
```
CREATE TABLE schema_migrations (
  version INTEGER PRIMARY KEY,
  inserted_at TEXT
);
```

**Notes**
- Managed by Ecto to track which migrations have been applied locally.

---

### Updating this document
Run `sqlite3 medic_dev.db '.schema <table>'` whenever migrations change, then update the relevant section so fellow developers can browse every table structure without opening the DB file.
