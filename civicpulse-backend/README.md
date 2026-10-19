# CivicPulse — Backend REST API & Intelligence Engine

The core REST API and computational intelligence engine for CivicPulse, built with **Java 21 (LTS)** and **Spring Boot 3.4**, implementing geospatial complaint ingestion, role-based triage workflows, and automated issue classification.

---

## 1. Architecture & Technology Stack

- **Runtime**: Java 21 LTS (Eclipse Temurin)
- **Framework**: Spring Boot 3.4
- **Build Tool**: Gradle (Kotlin DSL `build.gradle.kts`)
- **Database & Spatial**: PostgreSQL 16 + PostGIS 3.4 via Spring Data JPA and Hibernate Spatial (`org.hibernate.orm:hibernate-spatial`)
- **Database Migrations**: Flyway (`V001` through `V017`)
- **Security & Authorization**: Spring Security 6, BCrypt (cost factor 12), JJWT 0.12.6 with access (15 min) and refresh token (7 days) rotation
- **API Standard**: RESTful `/api/v1` endpoints with standard envelope `{ "data": ..., "meta": ..., "errors": [] }` and RFC 7807 Problem Details
- **Architecture Pattern**: Controller → Service → Repository layered architecture with clean DTO isolation
- **API Documentation**: OpenAPI 3.1 via SpringDoc OpenAPI (`/swagger-ui/index.html`)

---

## 2. Directory Layout

```
civicpulse-backend/
├── src/
│   ├── main/
│   │   ├── java/com/civicpulse/
│   │   │   ├── CivicpulseBackendApplication.java
│   │   │   ├── common/                # Standard ApiResponse, ApiMeta, ProblemDetail exception handlers
│   │   │   ├── config/                # SecurityConfig, CorsConfig, OpenApiConfig
│   │   │   ├── module/
│   │   │   │   ├── auth/              # JWT, User entity, AuthController, AuthService, TokenService
│   │   │   │   ├── issue/             # Issue, Category, Ward, Attachments, Comments, Upvotes, Timeline
│   │   │   │   └── intelligence/      # Phase 3 AI classification engine, suggest API, feedback learning
│   │   │   └── security/              # JwtAuthFilter, RateLimitFilter, UserPrincipal
│   │   └── resources/
│   │       ├── application.yml        # Base configuration & actuator settings
│   │       └── db/migration/          # Flyway SQL migrations (V001__... to V017__...)
│   └── test/                          # Unit and integration test suites (JUnit 5 + Mockito + Testcontainers)
├── Dockerfile                         # Hardened multi-stage build (JDK 21 builder → JRE 21 runner)
├── build.gradle.kts                   # Gradle Kotlin DSL build definition
└── settings.gradle.kts
```

---

## 3. Key REST API Endpoints (`/api/v1`)

### Authentication & Sessions
- `POST /api/v1/auth/register` — Citizen registration
- `POST /api/v1/auth/login` — Authentication for Citizen, Officer, Supervisor, and Admin
- `POST /api/v1/auth/refresh` — Single-use refresh token rotation
- `POST /api/v1/auth/logout` — Invalidate user session
- `GET /api/v1/auth/me` — Current authenticated user profile

### Issues & Complaints
- `POST /api/v1/issues` — Submit new civic issue with PostGIS geometry point
- `GET /api/v1/issues` — Paginated & filtered feed (status, priority, category, ward, distance)
- `GET /api/v1/issues/{id}` — Full issue details including timeline, upvotes, and attachments
- `POST /api/v1/issues/{id}/attachments` — Upload photographic/video evidence (multipart/form-data)
- `GET /api/v1/issues/{id}/attachments` — Retrieve photographic evidence
- `POST /api/v1/issues/{id}/upvote` — Citizen toggle upvote
- `POST /api/v1/issues/{id}/comments` — Add citizen or official comment
- `GET /api/v1/issues/{id}/comments` — List conversation comments
- `GET /api/v1/issues/{id}/timeline` — Audit log of status transitions and officer actions

### Triage, Dispatch & Management (Staff only)
- `PATCH /api/v1/issues/{id}/status` — Validated status transitions (OPEN → IN_PROGRESS → RESOLVED, etc.)
- `PATCH /api/v1/issues/{id}/assign` — Assign or reassign field officer (Supervisor/Admin only)
- `GET /api/v1/categories` — System categories with resolution SLAs
- `GET /api/v1/wards` — Municipal wards with PostGIS boundary geometries

### AI Intelligence Module
- `POST /api/v1/intelligence/suggest` — Real-time draft analysis for mobile and staff triage
- `GET /api/v1/intelligence/issues/{id}/recommendations` — Stored AI recommendation review
- `POST /api/v1/intelligence/issues/{id}/feedback` — Record staff acceptance or override for AI tuning

---

## 4. Building and Testing

### Run Tests
```bash
# Execute full unit, service, and controller test suite
./gradlew test
```

### Build Production Artifact
```bash
./gradlew bootJar -x test
```

### Run Locally
```bash
./gradlew bootRun
```

---

## 5. Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://localhost:5432/civicpulse` | PostgreSQL + PostGIS database connection |
| `SPRING_DATASOURCE_USERNAME` | `civicpulse` | Database username |
| `SPRING_DATASOURCE_PASSWORD` | `changeme_local_only` | Database password |
| `JWT_SECRET` | 256-bit base64 secret | HMAC-SHA256 signing secret |
| `SPRING_DATA_REDIS_HOST` | `localhost` | Redis instance host for token blacklist and caching |
| `SPRING_DATA_REDIS_PORT` | `6379` | Redis instance port |
