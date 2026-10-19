# CivicPulse — Implementation Plan

## Development Phases

---

### Phase 1: Foundation & Backend Core (Week 1–2)
**Goal**: Standing backend with auth, basic CRUD, and database.

| Task | Details |
|------|---------|
| 1.1 | Initialize Spring Boot project with Gradle (Kotlin DSL) |
| 1.2 | Configure PostgreSQL + PostGIS via Docker Compose |
| 1.3 | Set up Flyway migrations (users, wards, categories tables) |
| 1.4 | Implement User entity, repository, service |
| 1.5 | Implement JWT authentication (login, register, refresh, logout) |
| 1.6 | Implement Spring Security filter chain with role-based access |
| 1.7 | Implement Categories CRUD (admin-only) |
| 1.8 | Implement Wards CRUD with PostGIS boundaries |
| 1.9 | Global error handling (@ControllerAdvice + Problem Detail) |
| 1.10 | API response envelope + pagination utilities |
| 1.11 | Seed data migration (admin user, default categories, sample wards) |
| 1.12 | Integration tests with Testcontainers |

**Deliverable**: Runnable backend with `docker-compose up` → working auth + user management APIs.

---

### Phase 2: Issue Management Backend (Week 3–4)
**Goal**: Complete issue lifecycle on the backend.

| Task | Details | Status |
|------|---------|:---:|
| 2.1 | Flyway migrations for issues, attachments, comments, timeline, upvotes | **DONE** |
| 2.2 | Issue entity with PostGIS POINT geometry | **DONE** |
| 2.3 | Create issue endpoint (with category, location, attachments) | **DONE** |
| 2.4 | List issues with filtering (status, priority, category, ward) + cursor pagination | **DONE** |
| 2.5 | Issue detail endpoint with timeline | **DONE** |
| 2.6 | Status transitions with state machine validation | **DONE** |
| 2.7 | Assignment endpoint (supervisor assigns officer) | **DONE** |
| 2.8 | Comment and attachment endpoints | **DONE** |
| 2.9 | Upvote/downvote endpoint with denormalized count | **DONE** |
| 2.10 | Nearby issues geo-query (PostGIS ST_DWithin) | **DONE** |
| 2.11 | File upload service (multipart → local storage with configurable S3 swap) | **DONE** |
| 2.12 | Issue timeline event recording | **DONE** |

**Deliverable**: Full issue CRUD with geo-queries, state machine, and file uploads. (COMPLETED & VERIFIED)

---

### Phase 4: Flutter Mobile App — Core
**Goal**: Citizen & Officer core mobile app with auth, feed, AI suggestions, and issue reporting.

| Task | Details | Status |
|------|---------|:---:|
| 4.1 | Initialize Flutter project with Riverpod architecture | **DONE** |
| 4.2 | Design system: theme, typography, colors, reusable widgets | **DONE** |
| 4.3 | Auth screens (login, register) | **DONE** |
| 4.4 | Dio HTTP client with JWT interceptor (auto-refresh) | **DONE** |
| 4.5 | Feed screen with categories, filters, upvotes, and status pills | **DONE** |
| 4.6 | Report issue flow with GPS tagging and live debounced AI draft advice | **DONE** |
| 4.7 | Issue detail screen with status tracking, details, and upvotes | **DONE** |
| 4.8 | My Reports screen with personal submission filtering | **DONE** |
| 4.9 | English & Hindi (i18n) localization via ARB files | **DONE** |
| 4.10 | Zero-warning static analysis (`flutter analyze`) & automated test suite | **DONE** |

**Deliverable**: Citizen can register, log in, browse feed, report issues with GPS and real-time AI suggestions, track issue status, and view personal reports. (COMPLETED & VERIFIED)

---

### Phase 4: Officer Features + Notifications (Week 8–9)
**Goal**: Officer mobile experience + push notifications.

| Task | Details |
|------|---------|
| 4.1 | Officer role-specific home screen (assigned issues queue) |
| 4.2 | Navigate to issue location via Google Maps intent |
| 4.3 | Status update flow (start work → upload photos → resolve) |
| 4.4 | Internal notes (officer-only comments) |
| 4.5 | FCM integration: backend sends push via Firebase Admin SDK |
| 4.6 | Flutter FCM setup (foreground, background, terminated state) |
| 4.7 | Notification center screen in-app |
| 4.8 | Backend notification service (on status change, assignment, SLA breach) |
| 4.9 | Device token registration endpoint |
| 4.10 | Officer workload statistics |

**Deliverable**: Officers receive push notifications and can resolve issues end-to-end.

---

### Phase 5: SLA Engine + Smart Features (Week 10–11)
**Goal**: SLA enforcement, duplicate detection, auto-assignment.

| Task | Details |
|------|---------|
| 5.1 | SLA computation on issue creation (based on priority + category) |
| 5.2 | Scheduled SLA check job (Spring @Scheduled, every 5 min) |
| 5.3 | SLA breach handler: notify supervisor, auto-escalate priority |
| 5.4 | Auto-close job: close RESOLVED issues after 7 days without citizen response |
| 5.5 | Duplicate detection: geo-proximity check on issue creation |
| 5.6 | Duplicate detection: text similarity (TF-IDF or simple keyword matching) |
| 5.7 | Merge duplicate API |
| 5.8 | Auto-assignment: round-robin by ward + workload-aware |
| 5.9 | Upvote threshold escalation (configurable) |

**Deliverable**: Automated SLA tracking, breach alerts, and basic duplicate detection.

---

### Phase 5: React Admin & Officer Operations Dashboard
**Goal**: Full operational dashboard for municipal supervisors, officers, and administrators.

| Task | Details | Status |
|------|---------|:---:|
| 5.1 | Initialize Vite 8 + React 19 + TypeScript + Tailwind v4 project (`civicpulse-admin/`) | **DONE** |
| 5.2 | Auth pages (login with Zod, session management, role-based protection) | **DONE** |
| 5.3 | Dashboard overview: real-time KPI cards (registered, active, urgent, resolved, breaches) | **DONE** |
| 5.4 | Issue management: data table with status, priority, category, ward, search filters & pagination | **DONE** |
| 5.5 | Issue detail: timeline audit ledger, embedded OpenStreetMap, comments, evidence photos | **DONE** |
| 5.6 | Lifecycle status transitions enforcing Spring Boot state machine with audit remarks | **DONE** |
| 5.7 | Officer dispatch & assignment queue integration (`/api/v1/users/officers`) | **DONE** |
| 5.8 | Phase 3 AI Intelligence review: Accept, Reject, Override recommendations & history audit | **DONE** |
| 5.9 | Category & SLA hours configuration CRUD (Admin only) | **DONE** |
| 5.10 | Ward & PostGIS boundary polygon configuration CRUD (Admin only) | **DONE** |
| 5.11 | Vitest automated test suite & clean production bundle build (`tsc -b && vite build`) | **DONE** |

**Deliverable**: Fully operational web dashboard for complaint triage, officer assignment, and AI recommendation review. (COMPLETED & VERIFIED)

---

### Phase 6: End-to-End Integration, Security Audit & Deployment Readiness
**Goal**: Complete cross-tier integration, security audit, and deployment readiness across mobile, backend, web dashboard, and infrastructure.

| Task | Details | Status |
|------|---------|:---:|
| 6.1 | End-to-end citizen reporting workflow integration with photo attachments | **DONE** |
| 6.2 | Officer & Administrator triage, dispatch, and AI review workflow integration | **DONE** |
| 6.3 | Cross-tier API contract alignment (`/api/v1`, standard envelope, error models) | **DONE** |
| 6.4 | Security audit (BCrypt cost 12, JWT 15m/7d rotation, RBAC, SQLi/XSS, secure uploads) | **DONE** |
| 6.5 | Multi-stage production Dockerfile for Spring Boot (`civicpulse-backend/Dockerfile`) | **DONE** |
| 6.6 | Multi-stage production Dockerfile for React dashboard (`civicpulse-admin/Dockerfile`) | **DONE** |
| 6.7 | Nginx reverse proxy gateway configuration (`infrastructure/nginx/nginx.conf`) | **DONE** |
| 6.8 | Production Docker Compose 5-tier topology with pinned tags & health checks | **DONE** |
| 6.9 | Subproject README for backend (`civicpulse-backend/README.md`) | **DONE** |
| 6.10 | Security audit report & runbook documentation (`docs/security-audit.md`, `docs/deployment.md`) | **DONE** |
| 6.11 | Automated test suite execution across backend, mobile app, and web dashboard | **DONE** |

**Deliverable**: Tested, integrated, deployment-ready CivicPulse smart city platform. (COMPLETED & VERIFIED)


| Task | Details |
|------|---------|
| 7.1 | Comprehensive API tests (happy path + edge cases) |
| 7.2 | Flutter widget + integration tests |
| 7.3 | React component + E2E tests (Playwright) |
| 7.4 | Performance optimization (query tuning, caching, image compression) |
| 7.5 | Security audit (OWASP top 10 checklist) |
| 7.6 | Rate limiting on public APIs |
| 7.7 | API documentation with Springdoc OpenAPI |
| 7.8 | Docker multi-stage production builds |
| 7.9 | CI/CD pipeline (GitHub Actions) |
| 7.10 | Logging, monitoring setup (structured logs, health endpoints) |
| 7.11 | i18n: English + Hindi for mobile app |
| 7.12 | App store build preparation (icons, splash, signing) |

**Deliverable**: Production-ready deployment with CI/CD.

---

## Proposed Folder Structure

```
smartcity/
│
├── AGENTS.md
├── README.md
├── docker-compose.yml
├── .env.example
├── .gitignore
│
├── docs/
│   ├── architecture.md
│   ├── implementation-plan.md
│   ├── api-reference.md
│   ├── database-schema.md
│   ├── deployment-guide.md
│   ├── migrations.md
│   └── adr/
│       └── 001-monorepo-structure.md
│
├── civicpulse-backend/
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   ├── Dockerfile
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/civicpulse/
│   │   │   │   ├── CivicPulseApplication.java
│   │   │   │   ├── config/
│   │   │   │   │   ├── SecurityConfig.java
│   │   │   │   │   ├── JwtConfig.java
│   │   │   │   │   ├── WebConfig.java
│   │   │   │   │   └── OpenApiConfig.java
│   │   │   │   ├── security/
│   │   │   │   │   ├── JwtTokenProvider.java
│   │   │   │   │   ├── JwtAuthenticationFilter.java
│   │   │   │   │   └── UserDetailsServiceImpl.java
│   │   │   │   ├── common/
│   │   │   │   │   ├── ApiResponse.java
│   │   │   │   │   ├── PageResponse.java
│   │   │   │   │   ├── GlobalExceptionHandler.java
│   │   │   │   │   └── BaseEntity.java
│   │   │   │   ├── auth/
│   │   │   │   │   ├── AuthController.java
│   │   │   │   │   ├── AuthService.java
│   │   │   │   │   └── dto/ (LoginRequest, RegisterRequest, TokenResponse)
│   │   │   │   ├── user/
│   │   │   │   │   ├── UserController.java
│   │   │   │   │   ├── UserService.java
│   │   │   │   │   ├── UserRepository.java
│   │   │   │   │   ├── User.java
│   │   │   │   │   └── dto/
│   │   │   │   ├── issue/
│   │   │   │   │   ├── IssueController.java
│   │   │   │   │   ├── IssueService.java
│   │   │   │   │   ├── IssueRepository.java
│   │   │   │   │   ├── Issue.java
│   │   │   │   │   ├── IssueStateMachine.java
│   │   │   │   │   ├── dto/
│   │   │   │   │   ├── comment/
│   │   │   │   │   ├── attachment/
│   │   │   │   │   ├── timeline/
│   │   │   │   │   └── upvote/
│   │   │   │   ├── category/
│   │   │   │   ├── ward/
│   │   │   │   ├── notification/
│   │   │   │   ├── analytics/
│   │   │   │   ├── sla/
│   │   │   │   │   ├── SlaService.java
│   │   │   │   │   ├── SlaScheduler.java
│   │   │   │   │   └── SlaConfig.java
│   │   │   │   ├── duplicate/
│   │   │   │   │   ├── DuplicateDetectionService.java
│   │   │   │   │   └── GeoProximityService.java
│   │   │   │   └── admin/
│   │   │   └── resources/
│   │   │       ├── application.yml
│   │   │       ├── application-dev.yml
│   │   │       ├── application-prod.yml
│   │   │       └── db/migration/
│   │   │           ├── V001__create_users.sql
│   │   │           ├── V002__create_wards.sql
│   │   │           ├── V003__create_categories.sql
│   │   │           ├── V004__create_issues.sql
│   │   │           └── ...
│   │   └── test/
│   │       └── java/com/civicpulse/
│   │           ├── auth/
│   │           ├── issue/
│   │           └── ...
│
├── civicpulse-app/
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/
│   │   │   ├── theme/
│   │   │   │   ├── app_theme.dart
│   │   │   │   ├── app_colors.dart
│   │   │   │   └── app_typography.dart
│   │   │   ├── network/
│   │   │   │   ├── dio_client.dart
│   │   │   │   ├── api_endpoints.dart
│   │   │   │   └── interceptors/
│   │   │   ├── router/
│   │   │   │   └── app_router.dart
│   │   │   ├── constants/
│   │   │   ├── utils/
│   │   │   └── widgets/              (shared reusable widgets)
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── presentation/     (screens, widgets)
│   │   │   │   ├── application/      (providers, notifiers)
│   │   │   │   ├── domain/           (models, enums)
│   │   │   │   └── data/             (repositories, DTOs)
│   │   │   ├── home/
│   │   │   ├── issue/
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── screens/
│   │   │   │   │   │   ├── report_issue_screen.dart
│   │   │   │   │   │   ├── issue_detail_screen.dart
│   │   │   │   │   │   ├── my_issues_screen.dart
│   │   │   │   │   │   └── issue_map_screen.dart
│   │   │   │   │   └── widgets/
│   │   │   │   ├── application/
│   │   │   │   ├── domain/
│   │   │   │   └── data/
│   │   │   ├── officer/              (officer-specific screens)
│   │   │   ├── profile/
│   │   │   └── notifications/
│   │   └── l10n/
│   │       ├── app_en.arb
│   │       └── app_hi.arb
│   └── test/
│
├── civicpulse-admin/
│   ├── package.json
│   ├── vite.config.ts
│   ├── tsconfig.json
│   ├── Dockerfile
│   ├── src/
│   │   ├── main.tsx
│   │   ├── App.tsx
│   │   ├── api/                      (Axios client, endpoint definitions)
│   │   ├── auth/                     (login, auth context, guards)
│   │   ├── components/               (shared UI components)
│   │   ├── layouts/                  (dashboard layout, sidebar)
│   │   ├── pages/
│   │   │   ├── Dashboard.tsx
│   │   │   ├── Issues.tsx
│   │   │   ├── IssueDetail.tsx
│   │   │   ├── Users.tsx
│   │   │   ├── Categories.tsx
│   │   │   ├── Wards.tsx
│   │   │   ├── Analytics.tsx
│   │   │   ├── Settings.tsx
│   │   │   └── AuditLog.tsx
│   │   ├── hooks/
│   │   ├── stores/                   (Zustand stores)
│   │   ├── types/
│   │   └── utils/
│   └── public/
│
└── infrastructure/
    ├── docker/
    │   ├── backend.Dockerfile
    │   ├── admin.Dockerfile
    │   └── nginx/
    │       └── nginx.conf
    ├── scripts/
    │   ├── seed-data.sql
    │   └── init-postgis.sh
    └── monitoring/
        └── prometheus.yml (future)
```

---

## Dependencies

### Backend (Gradle)
| Dependency | Purpose |
|-----------|---------|
| spring-boot-starter-web | REST API |
| spring-boot-starter-security | Auth |
| spring-boot-starter-data-jpa | ORM |
| spring-boot-starter-validation | DTO validation |
| hibernate-spatial | PostGIS support |
| flyway-core | DB migrations |
| jjwt (io.jsonwebtoken) | JWT creation/parsing |
| postgresql (driver) | JDBC driver |
| springdoc-openapi | API docs |
| firebase-admin | Push notifications |
| testcontainers | Integration tests |

### Flutter (pubspec.yaml)
| Dependency | Purpose |
|-----------|---------|
| flutter_riverpod / riverpod_annotation | State management |
| go_router | Navigation |
| dio | HTTP client |
| google_maps_flutter | Maps |
| image_picker / image_cropper | Photo capture |
| firebase_messaging | Push notifications |
| flutter_secure_storage | Token storage |
| geolocator | Device location |
| cached_network_image | Image caching |
| intl | i18n |
| freezed / json_serializable | Model codegen |

### React Admin (package.json)
| Dependency | Purpose |
|-----------|---------|
| react / react-dom | UI |
| react-router-dom | Routing |
| axios | HTTP |
| zustand | State |
| @tanstack/react-query | Server state |
| recharts | Charts |
| @react-google-maps/api | Maps |
| react-hook-form + zod | Forms + validation |
| tailwindcss | Styling |
| shadcn/ui | Component library |

---

## Risks & Mitigations

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|-----------|-----------|
| 1 | PostGIS spatial queries slow on large datasets | Performance | Medium | GiST indexes, spatial partitioning, query EXPLAIN analysis |
| 2 | FCM token management complexity | Notifications fail | Medium | Periodic token cleanup job, multi-device support |
| 3 | File upload abuse (large images/videos) | Storage costs, DoS | High | File size limits (10MB images, 50MB video), server-side compression |
| 4 | SLA scheduler missed executions | SLA breaches undetected | Low | Idempotent job design, distributed lock (ShedLock) |
| 5 | Duplicate detection false positives | User frustration | Medium | Soft suggestions (not auto-merge), configurable thresholds |
| 6 | Scope creep across 7 phases | Timeline slips | High | Strict phase gates, MVP-first mindset, defer nice-to-haves |
| 7 | Google Maps API costs | Budget overrun | Medium | Tile caching, request batching, fallback to OpenStreetMap |
| 8 | JWT token theft on mobile | Account compromise | Low | Secure storage, short TTL, token binding to device |
| 9 | Concurrent status updates (race conditions) | Data integrity | Medium | Optimistic locking (@Version), state machine validation |
| 10 | Multi-language support late in project | Retrofit cost | Low | Externalize all strings from Day 1 (ARB/i18n) |

---

## Next Step

**Phase 1: Foundation & Backend Core**

Awaiting your approval to begin implementation of:
1. Docker Compose (PostgreSQL + PostGIS)
2. Spring Boot project scaffold
3. Flyway base migrations
4. JWT authentication system
5. User, Category, Ward CRUD APIs
6. Seed data

No code will be written until you confirm.
