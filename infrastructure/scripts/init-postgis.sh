#!/bin/bash
# Enable required PostgreSQL extensions for CivicPulse.
# This script runs automatically on first database initialization.

set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
EOSQL

echo "PostGIS and pgcrypto extensions enabled successfully."
