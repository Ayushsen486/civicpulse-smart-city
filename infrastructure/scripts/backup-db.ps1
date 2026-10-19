# CivicPulse Database Backup Script (PowerShell)
# Creates a compressed PostgreSQL/PostGIS dump.

param(
    [string]$BackupDir = ".\backups"
)

$ErrorActionPreference = "Stop"

if (!(Test-Path -Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dumpFile = Join-Path $BackupDir "civicpulse_backup_$timestamp.dump"

Write-Host "[INFO] Starting CivicPulse PostgreSQL backup..." -ForegroundColor Cyan

# Use docker-compose if running via docker, otherwise local pg_dump
if (Get-Command docker -ErrorAction SilentlyContinue) {
    docker compose exec -T postgres pg_dump -U civicpulse -d civicpulse -Fc > $dumpFile
} elseif (Test-Path "C:\Users\ayush\pgsql\bin\pg_dump.exe") {
    $env:PGPASSWORD = "changeme_local_only"
    & "C:\Users\ayush\pgsql\bin\pg_dump.exe" -U civicpulse -d civicpulse -h localhost -p 5432 -Fc -f $dumpFile
} else {
    Write-Error "Neither Docker nor pg_dump found on PATH."
}

if (Test-Path $dumpFile) {
    $size = (Get-Item $dumpFile).Length / 1MB
    Write-Host "[SUCCESS] Backup created successfully: $dumpFile ($([math]::Round($size, 2)) MB)" -ForegroundColor Green
}
