#!/bin/sh
# CivicPulse Database Restoration Script
# Restores a PostgreSQL/PostGIS database from a custom-format dump.

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_backup_file.dump>"
  exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "[ERROR] Backup file not found: ${BACKUP_FILE}"
  exit 1
fi

echo "[WARNING] You are about to restore database '${POSTGRES_DB:-civicpulse}' from '${BACKUP_FILE}'."
echo "[WARNING] This will clean and replace existing tables."
read -p "Type 'RESTORE' to confirm: " CONFIRM

if [ "${CONFIRM}" != "RESTORE" ]; then
  echo "[ABORTED] Restoration cancelled by user."
  exit 0
fi

echo "[INFO] Restoring CivicPulse database..."
docker compose exec -T postgres pg_restore \
  -U "${POSTGRES_USER:-civicpulse}" \
  -d "${POSTGRES_DB:-civicpulse}" \
  --clean \
  --if-exists \
  -v < "${BACKUP_FILE}"

echo "[SUCCESS] Database restored successfully from ${BACKUP_FILE}."
