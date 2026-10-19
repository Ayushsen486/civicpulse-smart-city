# CivicPulse — Production Deployment, Runbook & Launch Guide

> Operational runbook, container topology, environment configuration, database maintenance, disaster recovery procedures, and public launch checklist for the CivicPulse smart city platform.

---

## 1. Production Architecture & Container Topology

The CivicPulse platform uses a containerized multi-tier architecture orchestrated via Docker Compose:

```mermaid
graph TD
    UserClient[Citizen & Officer Mobile App] -->|HTTPS :443| LoadBalancer[TLS Termination / Gateway]
    AdminClient[Supervisor & Admin Web Browser] -->|HTTPS :443| LoadBalancer
    LoadBalancer -->|/api/*, /actuator/*| Backend[civicpulse-backend:1.0.0 (Temurin 21 JRE)]
    LoadBalancer -->|/*| AdminSPA[civicpulse-admin:1.0.0 (Nginx 1.27)]
    Backend -->|Port 5432| Postgres[(PostgreSQL 16 + PostGIS 3.4)]
    Backend -->|Port 6379| RedisCache[(Redis 7.2)]
    Backend -->|Local Volume / S3| Storage[(/var/civicpulse/uploads)]
```

### Container Specifications
| Service | Pinned Image | Base OS | Internal Port | Health Check |
|:---|:---|:---|:---:|:---|
| `postgres` | `postgis/postgis:16-3.4-alpine` | Alpine Linux | 5432 | `pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}` |
| `redis` | `redis:7.2-alpine` | Alpine Linux | 6379 | `redis-cli ping` |
| `backend` | `civicpulse-backend:1.0.0` | `eclipse-temurin:21-jre-alpine` | 8080 | `curl -f http://localhost:8080/actuator/health` |
| `admin` | `civicpulse-admin:1.0.0` | `nginx:1.27-alpine` | 80 | `wget -q --spider http://localhost:80/health` |
| `gateway` | `nginx:1.27-alpine` | Alpine Linux | 80, 443 | `wget -q --spider http://localhost:80/nginx-health` |

---

## 2. Environment Configuration & Secret Management

All sensitive parameters are externalized through environment variables. **Zero credentials or private keys may ever be committed to git.**

### Required Production Environment Variables
| Variable Name | Description | Example / Format |
|:---|:---|:---|
| `POSTGRES_DB` | Name of municipal database | `civicpulse` |
| `POSTGRES_USER` | Restricted PostgreSQL user | `civicpulse_prod` |
| `POSTGRES_PASSWORD` | Cryptographically random password | Minimum 32 characters |
| `POSTGRES_PORT` | Database host port | `5432` |
| `REDIS_PORT` | Redis cache port | `6379` |
| `REDIS_PASSWORD` | Optional Redis auth token | Minimum 32 characters |
| `SPRING_PROFILES_ACTIVE` | Active Spring Boot profile | `prod` |
| `SPRING_DATASOURCE_URL` | JDBC connection string | `jdbc:postgresql://postgres:5432/civicpulse` |
| `SPRING_DATASOURCE_USERNAME`| Backend DB username | `civicpulse_prod` |
| `SPRING_DATASOURCE_PASSWORD`| Backend DB password | Minimum 32 characters |
| `JWT_SECRET` | Base64 HMAC-SHA256 signing secret | Cryptographically generated ≥ 64 characters |
| `JWT_ACCESS_TOKEN_EXPIRY_MS` | Access token TTL (15 min) | `900000` |
| `JWT_REFRESH_TOKEN_EXPIRY_MS`| Refresh token TTL (7 days) | `604800000` |
| `CORS_ALLOWED_ORIGINS` | Explicit allow-listed origins | `https://admin.yourcity.gov,https://app.yourcity.gov` |
| `VITE_API_BASE_URL` | Reverse proxy API path for Admin | `/api/v1` |
| `UPLOAD_DIR` | Media attachment volume path | `/var/civicpulse/uploads` |
| `GOOGLE_MAPS_API_KEY` | Optional geocoding & tiles key | Alpha-numeric API key |
| `FIREBASE_CREDENTIALS_PATH` | Service account JSON path | `/etc/civicpulse/firebase.json` |

---

## 3. Configurable API Endpoints

### 3.1 Web Admin Dashboard
Configured at build time via `VITE_API_BASE_URL`. In production, this defaults to `/api/v1`, allowing the Nginx gateway to transparently route API requests to the backend without CORS complications.

### 3.2 Mobile App (Flutter)
Configured at compile/runtime using Flutter's declarative `--dart-define` flag:
```bash
# Build Android APK pointing to production domain
flutter build apk --release --dart-define=API_URL=https://api.yourcity.gov/api/v1

# Build iOS release bundle
flutter build ipa --release --dart-define=API_URL=https://api.yourcity.gov/api/v1

# Build Web distribution
flutter build web --release --dart-define=API_URL=https://api.yourcity.gov/api/v1
```

---

## 4. Staging & Deployment Runbook

### 4.1 Local Staging Verification
```bash
# 1. Clone repository
git clone https://github.com/civicpulse/civicpulse.git
cd civicpulse

# 2. Copy and populate environment file
cp .env.example .env
# Fill in secure values in .env

# 3. Build multi-stage container images
docker compose build

# 4. Start 5-tier topology in detached mode
docker compose up -d

# 5. Verify container health status
docker compose ps
```

### 4.2 Endpoint Health Verification
```bash
# Gateway reverse proxy
curl http://localhost/nginx-health

# Spring Boot actuator health
curl http://localhost/actuator/health

# Web Admin SPA health
curl http://localhost/health
```

---

## 5. Database Maintenance & Backup Operations

### 5.1 Automated Migrations
Migrations (`V001` through `V017`) execute automatically on backend boot via Flyway. Hibernate `ddl-auto` is strictly set to `validate` in all environments, preventing accidental schema modifications.

### 5.2 Scheduled Database Backup (Daily Routine)
```bash
# Linux / macOS:
./infrastructure/scripts/backup-db.sh

# Windows PowerShell:
.\infrastructure\scripts\backup-db.ps1 -BackupDir .\backups
```

### 5.3 Database Disaster Recovery Restoration
```bash
# Linux / macOS:
./infrastructure/scripts/restore-db.sh backups/civicpulse_backup_YYYYMMDD_HHMMSS.dump

# Windows PowerShell:
.\infrastructure\scripts\restore-db.ps1 -BackupFile backups\civicpulse_backup_YYYYMMDD_HHMMSS.dump
```

---

## 6. Rollback & Disaster Recovery Procedures

### 6.1 Application Version Rollback
1. If a newly deployed backend or admin container image exhibits issues, revert the container image tag in `docker-compose.yml` to the previous stable release hash.
2. Perform a zero-downtime rolling reload:
   ```bash
   docker compose up -d --no-deps backend
   ```
3. Verify actuator health:
   ```bash
   curl -f http://localhost/actuator/health
   ```

### 6.2 Database Migration Rollback
Per [AGENTS.md](file:///c:/Users/ayush/smartcity/AGENTS.md) Rule 2.4, Flyway migrations are strictly forward-only. If a schema migration must be rolled back:
1. Stop backend services: `docker compose stop backend`
2. Restore database from the pre-release snapshot:
   ```bash
   ./infrastructure/scripts/restore-db.sh pre_release_snapshot.dump
   ```
3. Restart backend services: `docker compose start backend`

---

## 7. Public Launch Checklist

Before public launch, operators must verify each requirement:

- [x] **Zero `latest` Tags**: All images pinned (`postgis:16-3.4-alpine`, `redis:7.2-alpine`, `nginx:1.27-alpine`).
- [x] **Multi-Stage Builds**: Hardened JDK 21 $\to$ JRE 21 and Node 22 $\to$ Nginx builds implemented.
- [x] **Non-Root Execution**: Backend runs as unprivileged user `civicpulse`.
- [x] **Health Checks Configured**: Docker Compose contains healthchecks on all 5 services.
- [x] **Safe Error Handling**: `application-prod.yml` disables stack traces and internal message leakage.
- [x] **Flyway Migrations**: All 17 migrations verified against PostgreSQL 16 + PostGIS 3.4.
- [x] **Automated Test Quality Gates**:
  - Spring Boot Backend: 72 tests (71 passed, 0 failures, 1 skipped).
  - Flutter Mobile: `flutter analyze` 0 warnings, 6/6 tests passed.
  - React Admin: 9/9 Vitest tests passed, `tsc -b && vite build` passed.
- [ ] **Domain & DNS**: Point municipal DNS records (e.g. `api.yourcity.gov`, `admin.yourcity.gov`) to gateway IP.
- [ ] **TLS / SSL Certificates**: Install valid Let's Encrypt or municipal TLS certificates in Nginx gateway.
- [ ] **Production Credentials**: Generate unique, high-entropy passwords for PostgreSQL, Redis, and JWT secret.
- [ ] **Mobile App Store Signing**: Sign Android release bundle (.aab) with upload keystore and iOS with Apple Developer provisioning profile.
