# CivicPulse Database Restoration Script (PowerShell)
# Restores a PostgreSQL/PostGIS dump created by pg_dump -Fc.

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile
)

$ErrorActionPreference = "Stop"

if (!(Test-Path -Path $BackupFile)) {
    Write-Error "Backup file does not exist: $BackupFile"
}

Write-Host "[WARNING] This will restore and overwrite existing tables in 'civicpulse'." -ForegroundColor Yellow
$confirmation = Read-Host "Type 'RESTORE' to proceed"

if ($confirmation -ne "RESTORE") {
    Write-Host "[ABORTED] Restoration cancelled by operator." -ForegroundColor Red
    Exit
}

Write-Host "[INFO] Restoring database from $BackupFile..." -ForegroundColor Cyan

if (Get-Command docker -ErrorAction SilentlyContinue) {
    Get-Content $BackupFile -Raw | docker compose exec -T postgres pg_restore -U civicpulse -d civicpulse --clean --if-exists
} elseif (Test-Path "C:\Users\ayush\pgsql\bin\pg_restore.exe") {
    $env:PGPASSWORD = "changeme_local_only"
    & "C:\Users\ayush\pgsql\bin\pg_restore.exe" -U civicpulse -d civicpulse -h localhost -p 5432 --clean --if-exists -v $BackupFile
} else {
    Write-Error "Neither Docker nor pg_restore found on PATH."
}

Write-Host "[SUCCESS] Database restored successfully." -ForegroundColor Green
