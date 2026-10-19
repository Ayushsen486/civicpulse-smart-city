# CivicPulse — Infrastructure & Deployment

Containerization, reverse proxy routing, and operational maintenance scripts for CivicPulse.

---

## 1. Directory Structure

```
infrastructure/
├── nginx/
│   └── nginx.conf          # Reverse proxy, rate limiting, and security headers
├── scripts/
│   ├── init-postgis.sh     # Docker container PostGIS extension initializer
│   ├── backup-db.sh        # Bash database backup script (pg_dump -Fc)
│   ├── restore-db.sh       # Bash database restore script (pg_restore)
│   ├── backup-db.ps1       # PowerShell database backup script
│   └── restore-db.ps1      # PowerShell database restore script
└── README.md
```

---

## 2. Docker Compose Topology

The platform orchestrates 5 production-hardened containers with pinned tags:

1. **`postgres`** (`postgis/postgis:16-3.4-alpine`): Relational & spatial store with PostGIS 3.4.
2. **`redis`** (`redis:7.2-alpine`): In-memory caching and session management.
3. **`backend`** (`civicpulse-backend:1.0.0`): Spring Boot 3.4 API running on Eclipse Temurin 21 JRE as non-root user.
4. **`admin`** (`civicpulse-admin:1.0.0`): React 19 SPA built via multi-stage Node 22 and served via Nginx 1.27 Alpine.
5. **`gateway`** (`nginx:1.27-alpine`): Unified reverse proxy handling SSL termination, rate limiting, and HTTP security headers.

---

## 3. Operational Commands

### Start All Services
```bash
docker compose up -d
```

### Check Service Health
```bash
docker compose ps
```

### Inspect Container Logs
```bash
# View backend logs
docker compose logs -f backend

# View reverse proxy logs
docker compose logs -f gateway
```

### Database Backup & Restoration
```bash
# Create timestamped compressed backup
./infrastructure/scripts/backup-db.sh
# or on Windows PowerShell:
.\infrastructure\scripts\backup-db.ps1

# Restore from backup archive
./infrastructure/scripts/restore-db.sh backups/civicpulse_backup_YYYYMMDD_HHMMSS.dump
# or on Windows PowerShell:
.\infrastructure\scripts\restore-db.ps1 -BackupFile backups\civicpulse_backup_YYYYMMDD_HHMMSS.dump
```
