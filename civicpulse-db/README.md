# CivicPulse — Database Migrations & Schemas

Flyway migration scripts and database definitions for the CivicPulse Smart City platform.

---

## 1. Engine & Extensions

- **Database Engine**: PostgreSQL 16 + PostGIS 3.4
- **Required Extensions**:
  - `postgis` — Geospatial point geometries and ward polygon boundaries (SRID 4326)
  - `uuid-ossp` — Primary key generation
  - `pgcrypto` — Cryptographic functions

---

## 2. Conventions & Rules (AGENTS.md)

- **Naming**: `snake_case` for all tables and columns. Plural table names (`issues`, `users`, `wards`).
- **Primary keys**: `UUID` generated via `gen_random_uuid()`.
- **Timestamps**: Every table includes `created_at` and `updated_at` (`TIMESTAMPTZ`, UTC).
- **Soft deletes**: `deleted_at TIMESTAMPTZ` where audit retention is required.
- **Foreign Keys**: Explicit foreign keys with B-tree indexes on every FK column.
- **Spatial Columns**: Indexed with GiST indexes (`CREATE INDEX ... USING GIST (location)`).

---

## 3. Migration Inventory (V001–V017)

| Migration | Title | Purpose |
|:---|:---|:---|
| `V001` | Extensions | Enables PostGIS, uuid-ossp, pgcrypto |
| `V002` | Users | Accounts with roles (`CITIZEN`, `OFFICER`, `SUPERVISOR`, `ADMIN`) |
| `V003` | Wards | Administrative ward boundaries (`GEOMETRY(POLYGON, 4326)`) |
| `V004` | Categories | Issue taxonomy with SLA resolution hours |
| `V005` | Issues | Civic complaint reports with spatial points (`GEOMETRY(POINT, 4326)`) |
| `V006` | Attachments | Evidentiary photos/videos with `is_before` flag |
| `V007` | Comments | Citizen discussions and staff internal notes |
| `V008` | Upvotes | Composite PK `(issue_id, user_id)` preventing duplicates |
| `V009` | Timeline Events | Immutable audit trail for lifecycle transitions |
| `V010` | Assignments | Historical officer dispatch records |
| `V011` | Notifications | In-app notifications & mobile FCM device tokens |
| `V012` | Refresh Tokens | SHA-256 hashed refresh token store with single-use rotation |
| `V013` | System Settings | Dynamic platform key-value configurations |
| `V014` | Audit Log | Security & administrative compliance event log |
| `V015` | Seed Data | Default administrative wards, categories, and bootstrap users |
| `V016` | Schema Enhancement | Reference numbers (`issue_reference`), attachment types, remarks |
| `V017` | Issue Intelligence | AI category/priority recommendations and staff review tracking |

---

## 4. Execution & Maintenance

Migrations are executed automatically on application startup by Spring Boot via Flyway:
- Source location: `civicpulse-backend/src/main/resources/db/migration/`
- Mirror location: `civicpulse-db/migrations/`
- Hibernate setting: `ddl-auto: validate` (prevents uncontrolled schema drift)
