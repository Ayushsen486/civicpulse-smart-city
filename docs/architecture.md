# CivicPulse — System Architecture

## 1. Vision

CivicPulse is a civic-issue tracking and resolution platform for smart cities.
Citizens report infrastructure issues (potholes, broken streetlights, garbage,
water leaks, etc.) via a mobile app. City officers are dispatched to resolve
them. Supervisors monitor SLAs. Administrators manage the entire system through
a web dashboard.

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENTS                              │
│  ┌──────────────┐  ┌──────────────────────────────────────┐ │
│  │ Flutter App   │  │ React Admin Dashboard               │ │
│  │ (Citizen,     │  │ (Supervisor, Admin)                  │ │
│  │  Officer)     │  │                                      │ │
│  └──────┬───────┘  └──────────────┬───────────────────────┘ │
└─────────┼──────────────────────────┼────────────────────────┘
          │ HTTPS / JWT              │ HTTPS / JWT
          ▼                          ▼
┌─────────────────────────────────────────────────────────────┐
│                  API GATEWAY / NGINX                        │
│           (TLS termination, rate limiting)                  │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│              SPRING BOOT BACKEND (REST API)                 │
│  ┌──────────┬──────────┬───────────┬──────────┬──────────┐  │
│  │  Auth    │  Issues  │  Users    │  Notif.  │  Admin   │  │
│  │  Module  │  Module  │  Module   │  Module  │  Module  │  │
│  └──────────┴──────────┴───────────┴──────────┴──────────┘  │
│           Spring Security + JWT Filter Chain                │
└──────┬──────────────┬───────────────────┬───────────────────┘
       │              │                   │
       ▼              ▼                   ▼
┌────────────┐ ┌────────────────┐ ┌───────────────────┐
│ PostgreSQL │ │ Firebase Cloud │ │ File Storage      │
│ + PostGIS  │ │ Messaging      │ │ (Local/S3/GCS)    │
└────────────┘ └────────────────┘ └───────────────────┘
```

---

## 3. Actors & Roles

| Role         | Platform   | Capabilities |
|-------------|-----------|----------------------------------------------|
| **Citizen**  | Mobile     | Register, report issues, track status, upvote, comment |
| **Officer**  | Mobile     | View assigned issues, update status, add resolution photos |
| **Supervisor** | Dashboard | Monitor SLAs, reassign issues, view analytics, manage officers |
| **Admin**    | Dashboard  | Full system control, user management, category management, global settings |

---

## 4. Core Domain Concepts

### 4.1 Issue Lifecycle

```
                ┌───────────┐
                │  DRAFT    │  (citizen saves without submitting)
                └─────┬─────┘
                      │ submit
                      ▼
                ┌───────────┐
                │  PENDING  │  (awaiting triage)
                └─────┬─────┘
                      │ auto-assign or manual assign
                      ▼
                ┌───────────┐
          ┌─────│ ASSIGNED  │─────┐
          │     └─────┬─────┘     │
          │           │ officer   │ reassign
          │           │ starts    │
          │           ▼           │
          │     ┌───────────┐     │
          │     │IN_PROGRESS│     │
          │     └─────┬─────┘     │
          │           │ officer   │
          │           │ resolves  │
          │           ▼           │
          │     ┌───────────┐     │
          │     │ RESOLVED  │     │
          │     └─────┬─────┘     │
          │           │           │
          │     citizen│confirms  │citizen reopens
          │           ▼           │
          │     ┌───────────┐     │
          │     │  CLOSED   │◄────┘
          │     └───────────┘
          │           ▲
          │           │ auto-close after 7 days
          │           │ if citizen doesn't respond
          │     ┌───────────┐
          └────►│ REJECTED  │  (duplicate / invalid / out of jurisdiction)
                └───────────┘
```

### 4.2 Priority System

| Priority | SLA Target | Color  | Auto-escalation |
|----------|-----------|--------|-----------------|
| CRITICAL | 4 hours   | Red    | After 2 hours   |
| HIGH     | 24 hours  | Orange | After 12 hours  |
| MEDIUM   | 72 hours  | Yellow | After 48 hours  |
| LOW      | 7 days    | Green  | After 5 days    |

Priority is initially set by category defaults, then refined by:
1. AI-suggested priority based on description keywords
2. Supervisor manual override
3. Upvote count thresholds (e.g., >50 upvotes → auto-escalate)

### 4.3 Duplicate Detection

1. **Geo-proximity**: Issues within 100m radius of an existing open issue in the same category.
2. **Text similarity**: Cosine similarity of TF-IDF vectors on title + description (threshold: 0.7).
3. **Citizen confirmation**: "We found a similar issue nearby — is this the same?" → merge as upvote.

### 4.4 SLA Engine

- Each issue has an `sla_deadline` computed from `created_at + priority.sla_hours`.
- A scheduled job runs every 5 minutes to check for SLA breaches.
- On breach: notification to supervisor + auto-escalation + priority bump.
- Dashboard shows: SLA compliance %, avg resolution time, breached issues.

---

## 5. Authentication & Authorization

### 5.1 Auth Flow

```
┌──────────┐     POST /api/v1/auth/login         ┌─────────────┐
│  Client   │ ──────────────────────────────────► │  Auth       │
│ (App/Web) │ ◄────────────────────────────────── │  Controller │
│           │     { accessToken, refreshToken }   │             │
└──────────┘                                      └──────┬──────┘
      │                                                  │
      │  Authorization: Bearer <accessToken>             │ validates
      │  on every subsequent request                     ▼
      │                                           ┌─────────────┐
      └──────────────────────────────────────────►│ JWT Filter  │
                                                  └──────┬──────┘
                                                         │
                                                         ▼
                                                  ┌─────────────┐
                                                  │ Spring      │
                                                  │ Security    │
                                                  │ Context     │
                                                  └─────────────┘
```

### 5.2 Registration Flows

- **Citizen**: Self-registration → phone OTP verification → active.
- **Officer**: Admin creates account → officer receives email invite → sets password.
- **Supervisor**: Admin creates account → same invite flow.
- **Admin**: Seeded or created by another admin.

### 5.3 Role-Based Access Matrix

| Resource             | Citizen | Officer | Supervisor | Admin |
|---------------------|---------|---------|-----------|-------|
| Create issue         | ✅       | ✅       | ✅         | ✅     |
| View own issues      | ✅       | ✅       | ✅         | ✅     |
| View assigned issues | —       | ✅       | ✅         | ✅     |
| View all issues      | —       | —       | ✅         | ✅     |
| Update issue status  | limited | ✅       | ✅         | ✅     |
| Assign/reassign      | —       | —       | ✅         | ✅     |
| Manage users         | —       | —       | —         | ✅     |
| Manage categories    | —       | —       | —         | ✅     |
| View analytics       | —       | —       | ✅         | ✅     |
| System settings      | —       | —       | —         | ✅     |

---

## 6. API Module Design

### Module 1: Auth (`/api/v1/auth`)
| Method | Endpoint          | Description |
|--------|------------------|-------------|
| POST   | /register         | Citizen self-registration |
| POST   | /login            | Email + password login |
| POST   | /refresh          | Refresh access token |
| POST   | /logout           | Invalidate refresh token |
| POST   | /forgot-password  | Send reset email/OTP |
| POST   | /reset-password   | Set new password with token |
| POST   | /verify-phone     | Verify phone OTP |

### Module 2: Users (`/api/v1/users`)
| Method | Endpoint              | Description |
|--------|-----------------------|-------------|
| GET    | /me                   | Current user profile |
| PUT    | /me                   | Update own profile |
| PUT    | /me/avatar            | Upload avatar |
| PUT    | /me/fcm-token         | Register FCM device token |
| GET    | /                     | List users (admin) |
| POST   | /                     | Create user (admin) |
| GET    | /{id}                 | Get user detail (admin) |
| PUT    | /{id}                 | Update user (admin) |
| DELETE | /{id}                 | Soft-delete user (admin) |
| GET    | /officers             | List officers (supervisor+) |
| GET    | /officers/{id}/workload | Officer workload stats |

### Module 3: Issues (`/api/v1/issues`)
| Method | Endpoint                     | Description |
|--------|------------------------------|-------------|
| POST   | /                            | Create issue |
| GET    | /                            | List issues (filtered, paginated) |
| GET    | /{id}                        | Get issue detail |
| PUT    | /{id}                        | Update issue |
| PATCH  | /{id}/status                 | Change status |
| POST   | /{id}/assign                 | Assign to officer |
| POST   | /{id}/upvote                 | Upvote issue |
| DELETE | /{id}/upvote                 | Remove upvote |
| GET    | /{id}/timeline               | Issue activity timeline |
| POST   | /{id}/comments               | Add comment |
| GET    | /{id}/comments               | List comments |
| POST   | /{id}/attachments            | Upload photos/videos |
| GET    | /nearby                      | Geo-query nearby issues |
| GET    | /duplicates                  | Find potential duplicates |
| POST   | /{id}/merge                  | Merge duplicate into parent |

### Module 4: Categories (`/api/v1/categories`)
| Method | Endpoint    | Description |
|--------|------------|-------------|
| GET    | /           | List all categories |
| POST   | /           | Create category (admin) |
| PUT    | /{id}       | Update category (admin) |
| DELETE | /{id}       | Delete category (admin) |

### Module 5: Notifications (`/api/v1/notifications`)
| Method | Endpoint         | Description |
|--------|-----------------|-------------|
| GET    | /                | List user's notifications |
| PUT    | /{id}/read       | Mark as read |
| PUT    | /read-all        | Mark all as read |
| GET    | /unread-count    | Get unread count |

### Module 6: Analytics (`/api/v1/analytics`)
| Method | Endpoint              | Description |
|--------|-----------------------|-------------|
| GET    | /dashboard            | Dashboard summary stats |
| GET    | /issues/by-category   | Issues grouped by category |
| GET    | /issues/by-status     | Issues grouped by status |
| GET    | /issues/by-ward       | Issues grouped by ward/zone |
| GET    | /sla/compliance       | SLA compliance metrics |
| GET    | /officers/performance | Officer performance rankings |
| GET    | /trends               | Issue trends over time |
| GET    | /heatmap              | Geo-heatmap data |

### Module 7: Admin (`/api/v1/admin`)
| Method | Endpoint              | Description |
|--------|-----------------------|-------------|
| GET    | /settings             | Get system settings |
| PUT    | /settings             | Update system settings |
| GET    | /wards                | List wards/zones |
| POST   | /wards                | Create ward |
| PUT    | /wards/{id}           | Update ward |
| GET    | /audit-log            | System audit trail |

---

## 7. Database Schema

### 7.1 Entity-Relationship Overview

```
users ─────────┐
  │             │
  │ 1:N         │ 1:N
  ▼             ▼
issues ◄───── issue_assignments
  │
  ├── 1:N ──► issue_comments
  ├── 1:N ──► issue_attachments
  ├── 1:N ──► issue_timeline_events
  ├── N:N ──► issue_upvotes
  └── N:1 ──► categories
                 │
                 └── N:1 ──► wards

users ──── 1:N ──► notifications
users ──── 1:N ──► refresh_tokens
users ──── 1:N ──► user_devices (FCM tokens)
```

### 7.2 Table Definitions

#### `users`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() |
| email | VARCHAR(255) | UNIQUE, NOT NULL |
| phone | VARCHAR(20) | UNIQUE |
| password_hash | VARCHAR(255) | NOT NULL |
| first_name | VARCHAR(100) | NOT NULL |
| last_name | VARCHAR(100) | NOT NULL |
| role | VARCHAR(20) | NOT NULL, CHECK (CITIZEN, OFFICER, SUPERVISOR, ADMIN) |
| avatar_url | VARCHAR(500) | |
| is_active | BOOLEAN | DEFAULT true |
| is_phone_verified | BOOLEAN | DEFAULT false |
| is_email_verified | BOOLEAN | DEFAULT false |
| ward_id | UUID | FK → wards(id), nullable (for officers) |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |
| deleted_at | TIMESTAMPTZ | nullable (soft delete) |

#### `wards`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| name | VARCHAR(100) | NOT NULL |
| code | VARCHAR(20) | UNIQUE, NOT NULL |
| boundary | GEOMETRY(POLYGON, 4326) | PostGIS polygon |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |

#### `categories`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| name | VARCHAR(100) | NOT NULL |
| slug | VARCHAR(100) | UNIQUE, NOT NULL |
| icon | VARCHAR(50) | |
| color | VARCHAR(7) | hex color |
| default_priority | VARCHAR(20) | DEFAULT 'MEDIUM' |
| sla_hours_override | INTEGER | nullable (overrides priority SLA) |
| is_active | BOOLEAN | DEFAULT true |
| parent_id | UUID | FK → categories(id), nullable (subcategories) |
| sort_order | INTEGER | DEFAULT 0 |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |

#### `issues`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| issue_number | SERIAL | UNIQUE, auto-increment display ID |
| title | VARCHAR(255) | NOT NULL |
| description | TEXT | |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'PENDING' |
| priority | VARCHAR(20) | NOT NULL, DEFAULT 'MEDIUM' |
| category_id | UUID | FK → categories(id), NOT NULL |
| reporter_id | UUID | FK → users(id), NOT NULL |
| assigned_officer_id | UUID | FK → users(id), nullable |
| ward_id | UUID | FK → wards(id), nullable |
| location | GEOMETRY(POINT, 4326) | NOT NULL |
| address | TEXT | reverse-geocoded or user-entered |
| landmark | VARCHAR(255) | |
| upvote_count | INTEGER | DEFAULT 0 |
| comment_count | INTEGER | DEFAULT 0 |
| sla_deadline | TIMESTAMPTZ | computed on create/priority change |
| sla_breached | BOOLEAN | DEFAULT false |
| is_duplicate | BOOLEAN | DEFAULT false |
| parent_issue_id | UUID | FK → issues(id), nullable (for duplicates) |
| resolved_at | TIMESTAMPTZ | |
| closed_at | TIMESTAMPTZ | |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |
| deleted_at | TIMESTAMPTZ | nullable |

#### `issue_attachments`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| issue_id | UUID | FK → issues(id), NOT NULL |
| uploaded_by | UUID | FK → users(id), NOT NULL |
| file_url | VARCHAR(500) | NOT NULL |
| file_type | VARCHAR(20) | image, video |
| file_size | INTEGER | bytes |
| is_before | BOOLEAN | DEFAULT true (before vs after resolution) |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |

#### `issue_comments`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| issue_id | UUID | FK → issues(id), NOT NULL |
| author_id | UUID | FK → users(id), NOT NULL |
| body | TEXT | NOT NULL |
| is_internal | BOOLEAN | DEFAULT false (officer-only notes) |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |

#### `issue_upvotes`
| Column | Type | Constraints |
|--------|------|-------------|
| issue_id | UUID | FK → issues(id) |
| user_id | UUID | FK → users(id) |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| **PK** | | (issue_id, user_id) |

#### `issue_timeline_events`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| issue_id | UUID | FK → issues(id), NOT NULL |
| actor_id | UUID | FK → users(id) |
| event_type | VARCHAR(50) | NOT NULL (CREATED, STATUS_CHANGED, ASSIGNED, COMMENTED, etc.) |
| old_value | VARCHAR(255) | |
| new_value | VARCHAR(255) | |
| metadata | JSONB | extra context |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |

#### `issue_assignments`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| issue_id | UUID | FK → issues(id), NOT NULL |
| officer_id | UUID | FK → users(id), NOT NULL |
| assigned_by | UUID | FK → users(id), NOT NULL |
| assigned_at | TIMESTAMPTZ | DEFAULT NOW() |
| unassigned_at | TIMESTAMPTZ | nullable |
| is_current | BOOLEAN | DEFAULT true |

#### `notifications`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK → users(id), NOT NULL |
| title | VARCHAR(255) | NOT NULL |
| body | TEXT | |
| type | VARCHAR(50) | ISSUE_UPDATE, SLA_BREACH, ASSIGNMENT, etc. |
| reference_type | VARCHAR(50) | nullable (e.g., 'ISSUE') |
| reference_id | UUID | nullable (e.g., issue UUID) |
| is_read | BOOLEAN | DEFAULT false |
| sent_at | TIMESTAMPTZ | DEFAULT NOW() |

#### `user_devices`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK → users(id), NOT NULL |
| fcm_token | VARCHAR(500) | NOT NULL |
| device_type | VARCHAR(20) | android, ios |
| last_used_at | TIMESTAMPTZ | DEFAULT NOW() |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |

#### `refresh_tokens`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK → users(id), NOT NULL |
| token_hash | VARCHAR(255) | NOT NULL |
| expires_at | TIMESTAMPTZ | NOT NULL |
| is_revoked | BOOLEAN | DEFAULT false |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |

#### `system_settings`
| Column | Type | Constraints |
|--------|------|-------------|
| key | VARCHAR(100) | PK |
| value | TEXT | NOT NULL |
| description | VARCHAR(255) | |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_by | UUID | FK → users(id) |

#### `audit_log`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| actor_id | UUID | FK → users(id) |
| action | VARCHAR(100) | NOT NULL |
| entity_type | VARCHAR(50) | |
| entity_id | UUID | |
| details | JSONB | |
| ip_address | VARCHAR(45) | |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |

### 7.3 Key Indexes

```sql
-- Spatial index for geo-queries
CREATE INDEX idx_issues_location ON issues USING GIST (location);
CREATE INDEX idx_wards_boundary ON wards USING GIST (boundary);

-- Composite indexes for common queries
CREATE INDEX idx_issues_status_priority ON issues (status, priority);
CREATE INDEX idx_issues_reporter ON issues (reporter_id);
CREATE INDEX idx_issues_assigned ON issues (assigned_officer_id);
CREATE INDEX idx_issues_category ON issues (category_id);
CREATE INDEX idx_issues_ward ON issues (ward_id);
CREATE INDEX idx_issues_sla ON issues (sla_breached, sla_deadline) WHERE deleted_at IS NULL;
CREATE INDEX idx_notifications_user_unread ON notifications (user_id) WHERE is_read = false;
```

---

## 8. Workflow Designs

### 8.1 Citizen Workflow
1. Opens app → sees map with nearby issues
2. Taps "Report Issue" → selects category → drops pin / uses current location
3. Adds title, description, photos → submits
4. Duplicate check runs → if duplicate found, citizen confirms or proceeds
5. Issue enters PENDING → citizen gets notification when assigned
6. Can track issue progress on map and timeline
7. When RESOLVED, citizen confirms or reopens within 7 days
8. Can upvote and comment on other citizens' issues

### 8.2 Officer Workflow
1. Logs in → sees assigned issues sorted by priority/SLA urgency
2. Views issue detail → navigates to location via Google Maps
3. Taps "Start Work" → status moves to IN_PROGRESS
4. After fixing, uploads "after" photos → taps "Mark Resolved"
5. Adds resolution notes → issue moves to RESOLVED
6. Dashboard shows personal stats: resolved today, open, SLA compliance

### 8.3 Supervisor Workflow
1. Logs into dashboard → sees SLA compliance overview
2. Reviews PENDING issues → assigns to officers by ward/workload
3. Monitors officer performance metrics
4. Gets alerted on SLA breaches → can reassign or escalate
5. Reviews resolved issues for quality
6. Views ward-wise heatmaps and trend analytics

### 8.4 Admin Workflow
1. Full dashboard access → system health overview
2. Manages user accounts (create officers, supervisors)
3. Manages categories and subcategories
4. Configures wards/zones with map-drawn boundaries
5. Adjusts SLA settings and priority thresholds
6. Reviews audit logs
7. Manages system settings (app branding, notification templates)

---

## 9. AI-Powered Issue Intelligence Module (Phase 3)

### 9.1 Overview & Provider Architecture
The Issue Intelligence Module provides automated categorization, multi-signal priority calculation, and municipal department routing for civic reports. It is built around the `IssueIntelligenceProvider` interface to ensure zero coupling between controllers/core services and the specific inference engine.

```
                  ┌──────────────────────────────┐
                  │    Issue Reporting Flow      │
                  │ (IssueService.createIssue)   │
                  └──────────────┬───────────────┘
                                 │
                   (Async / Safe Non-Blocking)
                                 ▼
                  ┌──────────────────────────────┐
                  │   IssueIntelligenceService   │
                  └──────────────┬───────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
       ┌───────────────────┐           ┌───────────────────┐
       │   Rule-Based      │           │    External AI    │
       │   Engine (Active) │           │ Provider (Future) │
       │ [RuleBased-       │           │ [Gemini / Claude /│
       │ Intelligence-     │           │  Local LLM]       │
       │ Provider]         │           │                   │
       └─────────┬─────────┘           └─────────┬─────────┘
                 └───────────────┬───────────────┘
                                 │ IssueAnalysisResult
                                 ▼
                  ┌──────────────────────────────┐
                  │   Recommendation Record      │
                  │   - Suggested Category       │
                  │   - Suggested Priority       │
                  │   - Routed Department        │
                  │   - Confidence Scores (0-1)  │
                  │   - Needs Human Review Flag  │
                  │   - Detailed Explanation     │
                  └──────────────┬───────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
      ┌─────────────────────┐         ┌─────────────────────┐
      │  Staff Review       │         │  Citizen Advisory   │
      │  (Accept/Reject/    │         │  (Pre-submission    │
      │   Override)         │         │   Draft Suggestion) │
      └─────────────────────┘         └─────────────────────┘
```

### 9.2 Pluggable Provider Interface
```java
public interface IssueIntelligenceProvider {
    IssueAnalysisResult analyze(IssueAnalysisContext context);
    String getProviderName();
    String getProviderVersion();
}
```

- **Default Implementation**: `RuleBasedIntelligenceProvider` (`CivicPulse-RuleEngine v1.0.0`).
- **Swapping with an External AI Provider**:
  1. Create a class implementing `IssueIntelligenceProvider` (e.g. `GeminiIntelligenceProvider`).
  2. Map prompt inputs from `IssueAnalysisContext` (title, description, available taxonomy).
  3. Annotate with `@ConditionalOnProperty(name = "civicpulse.intelligence.provider", havingValue = "gemini")` and mark as `@Primary`.
  4. Ensure HTTP client timeouts (max 3000ms connect / 5000ms read) and fallback to `RuleBasedIntelligenceProvider` upon network or quota failure.
  5. Never log or transmit user credentials, reporter PII, or internal passwords in the prompt.

### 9.3 Priority & Routing Decision Matrix
1. **Safety Signals**: Gas leak, live wire, open manhole, electric shock, sinkhole, bridge collapse, deep trench.
2. **Scale / Disruption Signals**: Main road, highway, hospital, school, intersection, entire locality, flooding, major traffic.
3. **Multi-Signal Rule**:
   - `Safety Signal` + (`Scale Signal` OR `Urgency Signal`) ➔ **`CRITICAL`** (High confidence, flagged for mandatory human verification).
   - `Safety Signal` Alone ➔ **`HIGH`** (Escalated with safety flag, preventing false-alarm critical issues without corroborating evidence; `needsHumanReview = true`).
   - `Disruption` / `Urgency` Alone ➔ **`HIGH`**.
   - `Cosmetic` / `Minor` Indicators ➔ **`LOW`**.
   - Unmatched / Ambiguous Signals ➔ Default category priority + `needsHumanReview = true` (confidence < 0.70).

### 9.4 Staff Review & Audit Trail
- Field Officers assigned to an issue, Supervisors, and Administrators can review recommendations via `POST /api/v1/issues/{id}/intelligence/review`.
- Review actions:
  - `ACCEPT`: Sets `reviewStatus = ACCEPTED`. Automatically updates issue category, priority, and recalculates SLA deadline if requested.
  - `REJECT`: Sets `reviewStatus = REJECTED`. Leaves issue attributes untouched.
  - `OVERRIDE`: Sets `reviewStatus = OVERRIDDEN`. Applies officer-specified override category, priority, or department.
- Every review writes an immutable timeline event to `issue_timeline_events`.
- Citizens querying `GET /api/v1/issues/{id}/intelligence` receive recommendations for their own reports with internal staff notes and reviewer identity redacted.
