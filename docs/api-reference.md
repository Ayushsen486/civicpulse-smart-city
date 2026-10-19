# CivicPulse — REST API Reference

> Complete endpoint catalog and specification for CivicPulse API v1.
> Fully documented with request/response schemas, role constraints, and validation rules.

## 1. Base URL
```
Development : http://localhost:8080/api/v1
Production  : https://api.civicpulse.city/api/v1
```

## 2. Authentication & Authorization
All endpoints except `/auth/login`, `/auth/register`, `/auth/refresh`, public categories, and public attachments require:
```
Authorization: Bearer <access_token>
```
Access token TTL: 15 minutes. Refresh token TTL: 7 days with automatic rotation.

## 3. Response Envelope (AGENTS.md Rule 4)
```json
{
  "data": { ... },
  "meta": {
    "timestamp": "2026-10-10T15:00:00Z",
    "page": {
      "page": 0,
      "size": 20,
      "totalElements": 45,
      "totalPages": 3,
      "hasNext": true,
      "hasPrevious": false
    }
  },
  "errors": []
}
```

## 4. Error Response (RFC 7807 Problem Detail)
```json
{
  "type": "https://civicpulse.city/errors/validation",
  "title": "Validation Failed",
  "status": 400,
  "detail": "2 fields failed validation",
  "errors": [
    { "field": "title", "message": "must not be blank" },
    { "field": "latitude", "message": "Latitude must be between -90 and 90" }
  ]
}
```

---

## 5. Endpoints Reference

### 5.1 Authentication (`/auth`)
| Method | Endpoint | Access | Description |
|:---|:---|:---|:---|
| `POST` | `/api/v1/auth/register` | Public | Citizen self-registration with email and password |
| `POST` | `/api/v1/auth/login` | Public | Authenticates credentials, returns access & refresh tokens |
| `POST` | `/api/v1/auth/refresh` | Public | Rotates refresh token, issues new access token |
| `POST` | `/api/v1/auth/logout` | Authenticated | Revokes current refresh token session |

### 5.2 Users (`/users`)
| Method | Endpoint | Access | Description |
|:---|:---|:---|:---|
| `GET` | `/api/v1/users/me` | Authenticated | Current user profile |
| `PUT` | `/api/v1/users/me` | Authenticated | Self-update profile details |
| `GET` | `/api/v1/users` | Admin | Paginated list of users with optional `role` filter |
| `POST` | `/api/v1/users` | Admin | Administrative account provisioning |
| `GET` | `/api/v1/users/{id}` | Admin | Detailed user profile |
| `PUT` | `/api/v1/users/{id}` | Admin | Edit user roles or active status |
| `DELETE` | `/api/v1/users/{id}` | Admin | Soft-delete user account |
| `GET` | `/api/v1/users/officers` | Supervisor, Admin | Available field officers queue |

### 5.3 Categories (`/categories`)
| Method | Endpoint | Access | Description |
|:---|:---|:---|:---|
| `GET` | `/api/v1/categories` | Public | Active categories taxonomy with subcategories |
| `GET` | `/api/v1/categories/{id}` | Public | Category details by ID |
| `POST` | `/api/v1/categories` | Admin | Create category with SLA override |
| `PUT` | `/api/v1/categories/{id}` | Admin | Update SLA, hierarchy, or status |
| `DELETE` | `/api/v1/categories/{id}` | Admin | Delete category |

### 5.4 Wards (`/wards`)
| Method | Endpoint | Access | Description |
|:---|:---|:---|:---|
| `GET` | `/api/v1/wards` | Authenticated | List all administrative municipal wards |
| `GET` | `/api/v1/wards/{id}` | Authenticated | Ward detail with PostGIS boundary WKT |
| `GET` | `/api/v1/wards/lookup` | Authenticated | Spatial reverse-lookup (`lat`, `lng`) to matching ward |
| `POST` | `/api/v1/wards` | Admin | Create ward with polygon boundary WKT |
| `PUT` | `/api/v1/wards/{id}` | Admin | Update ward boundary or metadata |
| `DELETE` | `/api/v1/wards/{id}` | Admin | Delete ward |

### 5.5 Issues (`/issues`) — Phase 2 Core
| Method | Endpoint | Access | Description |
|:---|:---|:---|:---|
| `POST` | `/api/v1/issues` | Authenticated | Report new civic issue with PostGIS coordinates |
| `GET` | `/api/v1/issues/{id}` | Authenticated | Get issue detail, upvote status, and attachments |
| `GET` | `/api/v1/issues` | Authenticated | Paginated issue list filtered by `status`, `priority`, `categoryId`, `wardId`, `reporterId` |
| `PUT` | `/api/v1/issues/{id}` | Authenticated | Update report (Citizens: own REPORTED only; Admin/Supervisor: any) |
| `PATCH` | `/api/v1/issues/{id}/status` | Role-enforced | State machine transition with remarks |
| `GET` | `/api/v1/issues/nearby` | Authenticated | Discover issues within radius using PostGIS `ST_DWithin` |
| `POST` | `/api/v1/issues/{id}/assign` | Supervisor, Admin | Dispatch officer, records assignment ledger & timeline |
| `POST` | `/api/v1/issues/{id}/reassign` | Supervisor, Admin | Reassign issue to another officer |
| `GET` | `/api/v1/issues/assigned-to-me` | Officer | Authenticated officer's dispatch queue |
| `GET` | `/api/v1/issues/{id}/timeline` | Authenticated | Complete immutable audit history of changes |
| `POST` | `/api/v1/issues/{id}/upvote` | Authenticated | Upvote issue (idempotent, single vote per user) |
| `DELETE` | `/api/v1/issues/{id}/upvote` | Authenticated | Remove citizen upvote |
| `POST` | `/api/v1/issues/{id}/comments` | Authenticated | Post comment (internal notes restricted to officers/supervisors) |
| `GET` | `/api/v1/issues/{id}/comments` | Authenticated | List comments (internal notes hidden from citizens) |
| `POST` | `/api/v1/issues/{id}/attachments` | Authenticated | Multipart upload with magic byte verification |
| `GET` | `/api/v1/issues/{id}/attachments` | Authenticated | List issue attachments |
| `GET` | `/api/v1/attachments/{storageKey}` | Public | Stream or download attachment file |

### 5.6 Issue Intelligence (`/api/v1/intelligence` & `/api/v1/issues/{id}/intelligence`)
| Method | Endpoint | Access | Description |
|:---|:---|:---|:---|
| `POST` | `/api/v1/intelligence/suggest` | Public / Authenticated | Advisory category, priority, and routing for draft reports before submission |
| `POST` | `/api/v1/issues/{id}/intelligence/analyze` | Officer, Supervisor, Admin | Analyzes existing issue using `IssueIntelligenceProvider`, creates recommendation record |
| `GET` | `/api/v1/issues/{id}/intelligence` | Authenticated | Retrieves current recommendation. Citizens restricted to own issues with internal notes redacted |
| `GET` | `/api/v1/issues/{id}/intelligence/history` | Supervisor, Admin | Complete audit history of intelligence recommendations for an issue |
| `POST` | `/api/v1/issues/{id}/intelligence/review` | Assigned Officer, Supervisor, Admin | Accepts, rejects, or overrides recommendation. Updates issue taxonomy & recalculated SLA |

#### Draft Advisory Request Example (`POST /api/v1/intelligence/suggest`)
```json
{
  "title": "Severe pipe burst flooding avenue",
  "description": "Drinking water pipeline leak gushing out near school junction causing major traffic hazard"
}
```
**Response (200 OK)**:
```json
{
  "data": {
    "suggestedCategoryId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "suggestedCategoryName": "Water Pipe Leak",
    "suggestedPriority": "CRITICAL",
    "recommendedDepartment": "Water Supply & Sewerage Board",
    "categoryConfidence": 0.90,
    "priorityConfidence": 0.92,
    "overallConfidence": 0.91,
    "explanation": "Categorized as 'Water Pipe Leak' based on matched keywords: pipe leak, pipeline burst. Recommended priority: CRITICAL due to confirmed safety hazard signals combined with disruption/urgency indicators. Routed to Water Supply & Sewerage Board. Marked for human triage and officer confirmation.",
    "needsHumanReview": true
  },
  "meta": { "timestamp": "2026-10-10T15:00:00Z" },
  "errors": []
}
```

#### Review Recommendation Request Example (`POST /api/v1/issues/{id}/intelligence/review`)
```json
{
  "action": "ACCEPT",
  "reviewNotes": "Inspected on site, pipeline burst confirmed by Junior Engineer",
  "applyToIssue": true
}
```
**Response (200 OK)**:
```json
{
  "data": {
    "id": "7fa85f64-5717-4562-b3fc-2c963f66afa7",
    "issueId": "2fa85f64-5717-4562-b3fc-2c963f66afa5",
    "suggestedCategoryId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "suggestedCategoryName": "Water Pipe Leak",
    "suggestedPriority": "CRITICAL",
    "recommendedDepartment": "Water Supply & Sewerage Board (WARD-01)",
    "categoryConfidence": 0.90,
    "priorityConfidence": 0.92,
    "routingConfidence": 0.90,
    "overallConfidence": 0.91,
    "explanation": "Categorized as 'Water Pipe Leak'...",
    "factors": {
      "categoryKeywords": ["pipeline burst (title)", "pipe leak (desc)"],
      "safetySignals": ["pipe burst"],
      "scaleSignals": ["school junction"],
      "wardJurisdiction": "WARD-01"
    },
    "providerName": "CivicPulse-RuleEngine",
    "providerVersion": "1.0.0",
    "needsHumanReview": true,
    "reviewStatus": "ACCEPTED",
    "reviewedById": "4fa85f64-5717-4562-b3fc-2c963f66afa8",
    "reviewedByName": "Vikram Singh",
    "reviewedAt": "2026-10-10T15:05:00Z",
    "reviewNotes": "Inspected on site, pipeline burst confirmed by Junior Engineer",
    "isCurrent": true,
    "createdAt": "2026-10-10T15:00:00Z",
    "updatedAt": "2026-10-10T15:05:00Z"
  },
  "meta": { "timestamp": "2026-10-10T15:05:00Z" },
  "errors": []
}
```

---

## 6. Issue State Machine Rules

```
                      ┌───────────────┐
                      │   REPORTED    │
                      └───────┬───────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
    ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
    │ ACKNOWLEDGED  │ │   REJECTED    │ │   CANCELLED   │
    └───────┬───────┘ └───────────────┘ └───────────────┘
            │
            ▼
    ┌───────────────┐
    │   ASSIGNED    │ ◀───── (Reassign)
    └───────┬───────┘
            │
            ▼
    ┌───────────────┐
    │  IN_PROGRESS  │
    └───────┬───────┘
            │
            ▼
    ┌───────────────┐
    │   RESOLVED    │
    └───────┬───────┘
            │
      ┌─────┴─────┐
      ▼           ▼
┌───────────┐┌───────────┐
│  CLOSED   ││ REOPENED  │ ──► [ASSIGNED / IN_PROGRESS]
└───────────┘└───────────┘
```

- **Role Constraints**:
  - `REPORTED → ACKNOWLEDGED`: Officer, Supervisor, Admin.
  - `ACKNOWLEDGED → ASSIGNED`: Supervisor, Admin.
  - `ASSIGNED → IN_PROGRESS`: Assigned Officer, Supervisor, Admin.
  - `IN_PROGRESS → RESOLVED`: Assigned Officer, Supervisor, Admin. (Citizens forbidden).
  - `RESOLVED → CLOSED`: Supervisor, Admin. (Citizens forbidden).
  - `RESOLVED → REOPENED`: Original reporting citizen, Supervisor, Admin.
  - `REPORTED → CANCELLED`: Original reporting citizen (while in REPORTED), Supervisor, Admin.
  - `* → REJECTED / DUPLICATE`: Supervisor, Admin.

## 7. Geospatial & File Upload Constraints
- **Nearby Search**:
  - Parameters: `lat` (-90 to 90), `lng` (-180 to 180), `radius` (10m to 50,000m, default 1,000m), `limit` (1 to 100).
  - Distance: Computed in meters using spherical PostGIS geography math (`ST_DWithin(location::geography, ...)`).
- **Attachments**:
  - Maximum size: 10 MB per file.
  - Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`, `image/gif`, `video/mp4`, `application/pdf`.
  - Content verification: Inspected via file magic bytes before storage.
