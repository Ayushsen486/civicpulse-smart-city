# CivicPulse — Deployment Guide

> Instructions for running the full stack locally and deploying to production.

## Local Development (Docker Compose)

### Prerequisites
- Docker Desktop ≥ 4.x
- Java 21 (for IDE / running backend outside Docker)
- Flutter SDK ≥ 3.24
- Node.js ≥ 20 LTS
- Android Studio / Xcode (for mobile emulators)

### Quick Start
```bash
# 1. Clone and enter the repo
git clone <repo-url> && cd smartcity

# 2. Copy environment file
cp .env.example .env
# Edit .env with your Google Maps API key, FCM credentials, etc.

# 3. Start infrastructure (database, nginx)
docker-compose up -d postgres nginx

# 4. Start backend (applies Flyway migrations automatically)
cd civicpulse-backend && ./gradlew bootRun --args='--spring.profiles.active=dev'

# 5. Start admin dashboard
cd civicpulse-admin && npm install && npm run dev

# 6. Start mobile app
cd civicpulse-app && flutter pub get && flutter run
```

### Docker Compose Services
| Service | Port | Description |
|---------|------|-------------|
| postgres | 5432 | PostgreSQL 16 + PostGIS |
| backend | 8080 | Spring Boot API |
| admin | 5173 | React dev server |
| nginx | 80/443 | Reverse proxy (production) |

## Production Deployment
*To be documented after Phase 7 (CI/CD pipeline).*
