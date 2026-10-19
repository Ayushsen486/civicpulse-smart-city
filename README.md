# CivicPulse — Smart City Civic Issue Resolution Platform

> An enterprise-grade, full-stack civic engagement and municipal issue resolution platform built with Spring Boot 3.4 (Java 21 LTS), PostGIS spatial intelligence, React 19 administrative operations dashboard, and Flutter mobile applications for citizens and field officers.

---

## 1. System Architecture

```
smartcity/
├── civicpulse-backend/       # Spring Boot 3.4 REST API (Java 21 LTS)
├── civicpulse-admin/         # React 19 + TypeScript + Vite operations dashboard
├── civicpulse-app/           # Flutter 3.x mobile application (Citizen & Officer)
├── civicpulse-db/            # Flyway migrations (V001–V017) & PostGIS schemas
├── infrastructure/           # Docker Compose, Nginx gateway, backup scripts
├── docs/                     # Architecture, API specifications, and runbooks
└── .github/                  # CI/CD automated test & build workflows
```

---

## 2. Key Capabilities

1. **Geospatial Reporting**: Citizen reports geotagged with high-precision GPS coordinates using PostGIS `POINT(lng lat, 4326)` and administrative ward boundaries using PostGIS `POLYGON`.
2. **AI Intelligence Engine**: Automated category suggestion, safety hazard prioritization, and municipal department routing with confidence scoring and staff human-in-the-loop review.
3. **End-to-End Issue Lifecycle**: Finite state machine transitions (`REPORTED` → `ACKNOWLEDGED` → `ASSIGNED` → `IN_PROGRESS` → `RESOLVED` → `CLOSED`) with immutable timeline audit logs.
4. **Role-Based Workspaces**:
   - **Citizens**: Mobile app for issue submission, live feed discovery, photo attachment upload, upvoting, comments, and in-app status notifications.
   - **Officers**: Mobile & web queue for assigned complaints, on-site diagnostics, navigation, and resolution proof submission.
   - **Supervisors & Admins**: Web operations dashboard with real-time KPI metrics, officer dispatching, SLA tracking, and taxonomy management.
5. **Security & Compliance**: BCrypt cost 12, JWT 15m/7d rotation with SHA-256 hashed refresh tokens, method-level `@PreAuthorize` authorization, rate-limited public APIs, and RFC 7807 Problem Detail error handling.

---

## 3. Quickstart & Local Staging

### Prerequisites
- Docker & Docker Compose v2+
- Java 21 JDK (Eclipse Temurin)
- Node.js 22 LTS
- Flutter SDK 3.36+

### Start Full 5-Tier Platform via Docker Compose
```bash
# 1. Copy environment template
cp .env.example .env

# 2. Build multi-stage containers
docker compose build

# 3. Start services in detached mode
docker compose up -d

# 4. Verify service health
docker compose ps
```

### Access Platform Endpoints
- **Reverse Proxy Gateway**: `http://localhost/`
- **Admin Dashboard**: `http://localhost/` (or `http://localhost:5173` in standalone dev)
- **Spring Boot API**: `http://localhost/api/v1` (or `http://localhost:8080/api/v1`)
- **OpenAPI / Swagger Docs**: `http://localhost/swagger-ui/index.html`
- **Actuator Health**: `http://localhost/actuator/health`

---

## 4. Subproject Documentation

- [Spring Boot Backend README](file:///c:/Users/ayush/smartcity/civicpulse-backend/README.md)
- [Admin Operations Dashboard README](file:///c:/Users/ayush/smartcity/civicpulse-admin/README.md)
- [Mobile Flutter App README](file:///c:/Users/ayush/smartcity/civicpulse-app/README.md)
- [Database Migrations README](file:///c:/Users/ayush/smartcity/civicpulse-db/README.md)
- [Infrastructure & Gateway README](file:///c:/Users/ayush/smartcity/infrastructure/README.md)
- [Deployment & Operational Runbook](file:///c:/Users/ayush/smartcity/docs/deployment.md)
- [Security Audit & Hardening Report](file:///c:/Users/ayush/smartcity/docs/security-audit.md)
