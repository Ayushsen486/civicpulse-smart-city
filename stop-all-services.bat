@echo off
title CivicPulse Smart City - Stop All Services
echo ======================================================
echo    Stopping CivicPulse Services
echo ======================================================

echo Stopping Vite dev server on port 3000...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /r ":3000 "') do (
    taskkill /PID %%a /F >nul 2>&1
)

echo Stopping Spring Boot backend on port 8080...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /r ":8080 "') do (
    taskkill /PID %%a /F >nul 2>&1
)

echo Stopping PostgreSQL on port 5432...
if exist "C:\Users\ayush\pgsql\bin\pg_ctl.exe" (
    "C:\Users\ayush\pgsql\bin\pg_ctl.exe" stop -D "C:\Users\ayush\pgdata" -m fast >nul 2>&1
)
taskkill /IM postgres.exe /F >nul 2>&1

echo All CivicPulse services stopped.
pause
