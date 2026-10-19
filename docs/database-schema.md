# CivicPulse — Database Schema Reference

> Canonical reference for all tables. See `docs/architecture.md` §7 for
> design rationale and ER diagram.

## Conventions
- All PKs are `UUID DEFAULT gen_random_uuid()`.
- All tables have `created_at TIMESTAMPTZ DEFAULT NOW()` and `updated_at TIMESTAMPTZ DEFAULT NOW()`.
- Soft-deletable tables add `deleted_at TIMESTAMPTZ`.
- Spatial columns use SRID 4326 (WGS 84).
- JSONB used for semi-structured metadata only.
- All FKs have corresponding indexes.

## Tables

| # | Table | Description | Rows (est. yr1) |
|---|-------|------------|-----------------|
| 1 | `users` | All actors (citizen, officer, supervisor, admin) | 50k |
| 2 | `wards` | Administrative ward/zone boundaries | 50–200 |
| 3 | `categories` | Issue categories (hierarchical via parent_id) | 30–50 |
| 4 | `issues` | Core issue reports | 100k |
| 5 | `issue_attachments` | Photos/videos on issues | 300k |
| 6 | `issue_comments` | Citizen & officer comments | 200k |
| 7 | `issue_upvotes` | Citizen upvotes (junction table) | 500k |
| 8 | `issue_timeline_events` | Immutable audit trail per issue | 500k |
| 9 | `issue_assignments` | Assignment history per issue | 150k |
| 10 | `notifications` | In-app + push notification records | 1M |
| 11 | `user_devices` | FCM tokens per device | 60k |
| 12 | `refresh_tokens` | JWT refresh token store | 50k |
| 13 | `system_settings` | Key-value config store | ~20 |
| 14 | `audit_log` | Admin action audit trail | 100k |

## Migration Sequence (Flyway)

| Version | File | Tables Created |
|---------|------|---------------|
| V001 | `V001__enable_extensions.sql` | Enable `uuid-ossp`, `postgis` |
| V002 | `V002__create_users.sql` | `users` |
| V003 | `V003__create_wards.sql` | `wards` |
| V004 | `V004__create_categories.sql` | `categories` |
| V005 | `V005__create_issues.sql` | `issues` |
| V006 | `V006__create_issue_attachments.sql` | `issue_attachments` |
| V007 | `V007__create_issue_comments.sql` | `issue_comments` |
| V008 | `V008__create_issue_upvotes.sql` | `issue_upvotes` |
| V009 | `V009__create_issue_timeline.sql` | `issue_timeline_events` |
| V010 | `V010__create_issue_assignments.sql` | `issue_assignments` |
| V011 | `V011__create_notifications.sql` | `notifications`, `user_devices` |
| V012 | `V012__create_refresh_tokens.sql` | `refresh_tokens` |
| V013 | `V013__create_system_settings.sql` | `system_settings` |
| V014 | `V014__create_audit_log.sql` | `audit_log` |
| V015 | `V015__seed_data.sql` | Admin user, default categories, sample wards |

For full column-level definitions, see `docs/architecture.md` §7.2.
