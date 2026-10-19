#!/bin/sh
# CivicPulse Database Backup Script
# Creates a compressed, custom-format PostgreSQL/PostGIS dump.

set -e

BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="${BACKUP_DIR}/civicpulse_backup_${TIMESTAMP}.dump"

mkdir -p "${BACKUP_DIR}"

echo "[INFO] Starting CivicPulse PostgreSQL backup..."
docker compose exec -T postgres pg_dump \
  -U "${POSTGRES_USER:-civicpulse}" \
  -d "${POSTGRES_DB:-civicpulse}" \
  -Fc \
  -v > "${FILENAME}"

echo "[SUCCESS] Backup completed successfully: ${FILENAME}"
echo "[INFO] File size: $(ls -lh "${FILENAME}" | awk '{print $5}')"
