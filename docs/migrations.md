# CivicPulse — Migration Log

> Track every Flyway migration with context for future developers.

| Version | Date | Author | File | Tables / Objects | Description |
|---------|------|--------|------|------------------|-------------|
| V001 | 2026-10-09 | CivicPulse Core | `V001__enable_extensions.sql` | Extensions: `uuid-ossp`, `postgis`, `pgcrypto` | Enable PostgreSQL extensions for UUID generation, GIS spatial operations, and cryptographic hashing |
| V002 | 2026-10-09 | CivicPulse Core | `V002__create_users.sql` | `users` | Core user identity table supporting Citizen, Officer, Supervisor, Admin roles with soft delete |
| V003 | 2026-10-09 | CivicPulse Core | `V003__create_wards.sql` | `wards`, FK `users.ward_id` | Administrative municipal wards with PostGIS polygon boundaries and user ward assignment |
| V004 | 2026-10-09 | CivicPulse Core | `V004__create_categories.sql` | `categories` | Hierarchical issue categories with SLA overrides, icons, hex colors, and default priorities |
| V005 | 2026-10-09 | CivicPulse Core | `V005__create_issues.sql` | `issues` | Central civic issue reports with PostGIS POINT geometry, auto-increment display IDs, SLA deadlines |
| V006 | 2026-10-09 | CivicPulse Core | `V006__create_issue_attachments.sql` | `issue_attachments` | Photographic/video evidence attached to issues with before/after resolution flags |
| V007 | 2026-10-09 | CivicPulse Core | `V007__create_issue_comments.sql` | `issue_comments` | Public discussion and officer-only internal operational notes |
| V008 | 2026-10-09 | CivicPulse Core | `V008__create_issue_upvotes.sql` | `issue_upvotes` | Many-to-many citizen upvote junction table with composite primary key |
| V009 | 2026-10-09 | CivicPulse Core | `V009__create_issue_timeline.sql` | `issue_timeline_events` | Immutable audit trail tracking state transitions, assignments, and priority changes |
| V010 | 2026-10-09 | CivicPulse Core | `V010__create_issue_assignments.sql` | `issue_assignments` | Assignment history mapping field officers to issues with assignment timestamps and active flag |
| V011 | 2026-10-09 | CivicPulse Core | `V011__create_notifications.sql` | `notifications`, `user_devices` | In-app user notifications and mobile device FCM registration tokens |
| V012 | 2026-10-09 | CivicPulse Core | `V012__create_refresh_tokens.sql` | `refresh_tokens` | Secure SHA-256 hashed JWT refresh token persistence with revocation tracking |
| V013 | 2026-10-09 | CivicPulse Core | `V013__create_system_settings.sql` | `system_settings` | Key-value application runtime configuration with administrative audit tracking |
| V014 | 2026-10-09 | CivicPulse Core | `V014__create_audit_log.sql` | `audit_log` | High-level administrative activity and governance audit log |
| V015 | 2026-10-09 | CivicPulse Core | `V015__seed_data.sql` | Seed records in `wards`, `users`, `categories` | Initial bootstrap data: 5 sample municipal wards, default admin user, and category taxonomy |
| V016 | 2026-10-10 | CivicPulse Core | `V016__enhance_issue_management_schema.sql` | `issues`, `issue_attachments`, `issue_timeline_events`, `issue_comments` | Phase 2 enhancements: status state machine expansion, public issue reference, attachment classification, timeline remarks, soft-deletes |
| V017 | 2026-10-10 | CivicPulse Core | `V017__create_issue_intelligence.sql` | `issue_intelligence_recommendations` | Phase 3: AI-Powered Issue Intelligence recommendations, confidence scores, review status, and overrides |

---

## Migration Details

### V001 — Enable Required Extensions
- **File**: `V001__enable_extensions.sql`
- **Extensions**: `uuid-ossp`, `postgis`, `pgcrypto`
- **Purpose**: Enables standard UUID generation (`gen_random_uuid()`), PostGIS spatial geometry operations (`GEOMETRY(POINT, 4326)` and `GEOMETRY(POLYGON, 4326)`), and cryptographic functions (`crypt`, `gen_salt`).

### V002 — Create `users` Table
- **File**: `V002__create_users.sql`
- **Tables**: `users`
- **Key Columns**:
  - `id`: UUID PRIMARY KEY DEFAULT `gen_random_uuid()`
  - `email`: VARCHAR(255) UNIQUE NOT NULL
  - `phone`: VARCHAR(20) UNIQUE
  - `role`: VARCHAR(20) CHECK (`role IN ('CITIZEN', 'OFFICER', 'SUPERVISOR', 'ADMIN')`)
  - `deleted_at`: TIMESTAMPTZ (soft delete support)
- **Indexes**: `idx_users_email`, `idx_users_role`, `idx_users_deleted_at`

### V003 — Create `wards` Table
- **File**: `V003__create_wards.sql`
- **Tables**: `wards`
- **Key Columns**:
  - `boundary`: `GEOMETRY(POLYGON, 4326)` (spatial boundary of the municipal ward)
- **Constraints**: Adds `fk_users_ward` linking `users.ward_id` to `wards.id`.
- **Indexes**: GiST index on `boundary` (`idx_wards_boundary`), B-Tree on `code` (`idx_wards_code`), B-Tree on `users.ward_id` (`idx_users_ward_id`).

### V004 — Create `categories` Table
- **File**: `V004__create_categories.sql`
- **Tables**: `categories`
- **Key Columns**:
  - `slug`: VARCHAR(100) UNIQUE NOT NULL
  - `parent_id`: UUID self-referencing foreign key for hierarchical taxonomy
  - `default_priority`: CHECK (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`)
  - `sla_hours_override`: Optional category-specific SLA resolution target in hours
- **Indexes**: `idx_categories_parent_id`, `idx_categories_slug`, `idx_categories_is_active`

### V005 — Create `issues` Table
- **File**: `V005__create_issues.sql`
- **Tables**: `issues`
- **Key Columns**:
  - `issue_number`: SERIAL UNIQUE human-readable tracking ID
  - `status`: CHECK (`DRAFT`, `PENDING`, `ASSIGNED`, `IN_PROGRESS`, `RESOLVED`, `CLOSED`, `REOPENED`, `CANCELLED`)
  - `priority`: CHECK (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`)
  - `location`: `GEOMETRY(POINT, 4326)` NOT NULL (GIS coordinate of the report)
  - `sla_deadline`: TIMESTAMPTZ target resolution timestamp
  - `sla_breached`: BOOLEAN flag updated by background SLA engine
- **Foreign Keys**: `category_id` (RESTRICT), `reporter_id` (RESTRICT), `assigned_officer_id` (SET NULL), `ward_id` (SET NULL), `parent_issue_id` (SET NULL)
- **Indexes**: GiST index on `location`, composite index on `(status, priority)`, FK indexes, partial index on `(sla_breached, sla_deadline)` where `deleted_at IS NULL`.

### V006 — Create `issue_attachments` Table
- **File**: `V006__create_issue_attachments.sql`
- **Tables**: `issue_attachments`
- **Key Columns**: `file_url`, `file_type`, `file_size`, `is_before` (distinguishes initial damage vs officer resolution proof)
- **Foreign Keys**: `issue_id` (CASCADE), `uploaded_by` (RESTRICT)
- **Indexes**: `idx_issue_attachments_issue_id`, `idx_issue_attachments_uploaded_by`

### V007 — Create `issue_comments` Table
- **File**: `V007__create_issue_comments.sql`
- **Tables**: `issue_comments`
- **Key Columns**: `body`, `is_internal` (allows officers/supervisors to write private internal triage notes)
- **Foreign Keys**: `issue_id` (CASCADE), `author_id` (RESTRICT)
- **Indexes**: `idx_issue_comments_issue_id`, `idx_issue_comments_author_id`

### V008 — Create `issue_upvotes` Junction Table
- **File**: `V008__create_issue_upvotes.sql`
- **Tables**: `issue_upvotes`
- **Key Columns**: Composite PK `(issue_id, user_id)` preventing duplicate citizen votes
- **Foreign Keys**: `issue_id` (CASCADE), `user_id` (CASCADE)
- **Indexes**: `idx_issue_upvotes_user_id`

### V009 — Create `issue_timeline_events` Table
- **File**: `V009__create_issue_timeline.sql`
- **Tables**: `issue_timeline_events`
- **Key Columns**: `event_type`, `old_value`, `new_value`, `metadata` (JSONB)
- **Purpose**: Append-only immutable log for all lifecycle events (creation, assignment, status change, escalation).
- **Indexes**: `idx_issue_timeline_issue_id`, `idx_issue_timeline_actor_id`, `idx_issue_timeline_created_at`

### V010 — Create `issue_assignments` Table
- **File**: `V010__create_issue_assignments.sql`
- **Tables**: `issue_assignments`
- **Key Columns**: `officer_id`, `assigned_by`, `assigned_at`, `unassigned_at`, `is_current`
- **Purpose**: Full historical ledger of officer dispatches and reassignments.
- **Indexes**: `idx_issue_assignments_issue_id`, `idx_issue_assignments_officer_id`, `idx_issue_assignments_assigned_by`

### V011 — Create `notifications` & `user_devices` Tables
- **File**: `V011__create_notifications.sql`
- **Tables**: `notifications`, `user_devices`
- **Key Columns**:
  - `notifications`: `type`, `reference_type`, `reference_id`, `is_read`, `sent_at`
  - `user_devices`: `fcm_token`, `device_type`, `last_used_at`
- **Indexes**: `idx_notifications_user_id`, partial index `idx_notifications_user_unread`, `idx_user_devices_user_id`, `idx_user_devices_token`

### V012 — Create `refresh_tokens` Table
- **File**: `V012__create_refresh_tokens.sql`
- **Tables**: `refresh_tokens`
- **Key Columns**: `token_hash` (VARCHAR(255) UNIQUE NOT NULL), `expires_at`, `is_revoked`
- **Security**: Raw JWT refresh tokens are never stored plain-text; only secure hashes are persisted.
- **Indexes**: `idx_refresh_tokens_user_id`, `idx_refresh_tokens_token_hash`

### V013 — Create `system_settings` Table
- **File**: `V013__create_system_settings.sql`
- **Tables**: `system_settings`
- **Key Columns**: `key` (PK), `value`, `description`, `updated_by`
- **Foreign Keys**: `updated_by` (SET NULL)
- **Indexes**: `idx_system_settings_updated_by`

### V014 — Create `audit_log` Table
- **File**: `V014__create_audit_log.sql`
- **Tables**: `audit_log`
- **Key Columns**: `actor_id`, `action`, `entity_type`, `entity_id`, `details` (JSONB), `ip_address`
- **Purpose**: Compliance and security audit trail for administrative operations.
- **Indexes**: `idx_audit_log_actor_id`, `idx_audit_log_entity`, `idx_audit_log_created_at`

### V015 — Seed Data
- **File**: `V015__seed_data.sql`
- **Seed Entities**:
  1. **5 Administrative Wards**: Central (`WARD-01`), North (`WARD-02`), South (`WARD-03`), East (`WARD-04`), West (`WARD-05`) with geometric polygon boundaries.
  2. **Initial Administrator Account**: Email `admin@civicpulse.org`, password bcrypt cost factor 12 (`Admin@12345`), pre-verified.
  3. **5 Top-Level Categories**: Roads & Traffic, Sanitation & Waste, Water Supply, Street Lighting, Public Parks.
  4. **8 Granular Subcategories**: Potholes, Broken Footpath, Garbage Dump, Drain Blockage, Water Pipe Leak, No Water Supply, Broken Streetlight, Damaged Playground.

### V016 — Enhance Issue Management Schema (Phase 2)
- **File**: `V016__enhance_issue_management_schema.sql`
- **Tables Enhanced**: `issues`, `issue_attachments`, `issue_timeline_events`, `issue_comments`
- **Key Alterations**:
  - `issues.status`: Check constraint updated to support full state machine: `REPORTED`, `ACKNOWLEDGED`, `ASSIGNED`, `IN_PROGRESS`, `RESOLVED`, `CLOSED`, `REOPENED`, `REJECTED`, `DUPLICATE`, `CANCELLED` (with `REPORTED` as default).
  - `issues.issue_reference`: Unique public issue code (e.g. `ISS-2026-00001`).
  - `issues.priority_score`: Computed double precision priority score.
  - `issues.reopened_at` & `issues.reopened_by`: Reopen tracking and audit fields.
  - `issue_attachments`: Added `attachment_type` (`REPORT`, `BEFORE`, `AFTER`, `OTHER`), `storage_key`, `mime_type`, `original_filename`.
  - `issue_timeline_events.remarks`: Dedicated column for status change or assignment notes.
  - `issue_comments.deleted_at`: Soft-deletion audit support.
- **Indexes**: Added B-tree indexes on `issues(issue_reference)`, `issues(created_at DESC)`, `issues(status)`, `issues(priority)`, `issue_attachments(attachment_type)`.

### V017 — Create Issue Intelligence Recommendations (Phase 3)
- **File**: `V017__create_issue_intelligence.sql`
- **Tables**: `issue_intelligence_recommendations`
- **Key Columns**:
  - `id`: UUID PRIMARY KEY DEFAULT `gen_random_uuid()`
  - `issue_id`: UUID NOT NULL, FK to `issues(id)` ON DELETE CASCADE
  - `suggested_category_id`: UUID, FK to `categories(id)` ON DELETE SET NULL
  - `suggested_priority`: VARCHAR(20) NOT NULL CHECK (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`)
  - `recommended_department`: VARCHAR(100) NOT NULL
  - `category_confidence`, `priority_confidence`, `routing_confidence`, `overall_confidence`: DOUBLE PRECISION
  - `explanation`: TEXT NOT NULL
  - `factors`: JSONB (analysis signals and matching factors)
  - `provider_name`, `provider_version`: Provider attribution metadata
  - `needs_human_review`: BOOLEAN NOT NULL DEFAULT false
  - `review_status`: VARCHAR(20) CHECK (`PENDING_REVIEW`, `ACCEPTED`, `REJECTED`, `OVERRIDDEN`)
  - `reviewed_by`: UUID, FK to `users(id)` ON DELETE SET NULL
  - `reviewed_at`: TIMESTAMPTZ
  - `review_notes`: TEXT
  - `override_category_id`, `override_priority`, `override_department`: Review override values
  - `is_current`: BOOLEAN NOT NULL DEFAULT true (enables versioning with fast latest lookup)
- **Indexes**: B-tree on `issue_id`, composite on `(issue_id, is_current)`, `review_status`, partial index on `needs_human_review` where true, and `created_at DESC`.

