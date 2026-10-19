@echo off
title CivicPulse Smart City - All Services Manager
cd /d "%~dp0"

echo ======================================================
echo    CivicPulse Smart City - Starting 24/7 Services
echo ======================================================
echo.

:: 1. PostgreSQL Database Server
echo [1/4] Checking PostgreSQL database on port 5432...
netstat -ano | findstr /r ":5432 " >nul
if %errorlevel% neq 0 (
    echo   Starting PostgreSQL database...
    if exist "C:\Users\ayush\pgdata\postmaster.pid" (
        del /f /q "C:\Users\ayush\pgdata\postmaster.pid" 2>nul
    )
    start /min "CivicPulse-PostgreSQL" "C:\Users\ayush\pgsql\bin\postgres.exe" -D "C:\Users\ayush\pgdata"
    timeout /t 3 /nobreak >nul
    echo   PostgreSQL started successfully.
) else (
    echo   PostgreSQL is already running on port 5432.
)

:: 2. Spring Boot REST Backend
echo.
echo [2/4] Checking Spring Boot Backend on port 8080...
netstat -ano | findstr /r ":8080 " >nul
if %errorlevel% neq 0 (
    echo   Starting Spring Boot REST API...
    cd /d "%~dp0civicpulse-backend"
    start /min "CivicPulse-Backend" cmd /c "gradlew.bat bootRun"
    cd /d "%~dp0"
    echo   Backend startup initiated.
) else (
    echo   Spring Boot Backend is already running on port 8080.
)

:: 3. React + TypeScript Admin Dashboard
echo.
echo [3/4] Checking Admin Portal on port 3000...
netstat -ano | findstr /r ":3000 " >nul
if %errorlevel% neq 0 (
    echo   Starting CivicPulse Admin Dashboard...
    cd /d "%~dp0civicpulse-admin"
    start /min "CivicPulse-Admin" cmd /c "npm run dev"
    cd /d "%~dp0"
    echo   Admin Dashboard startup initiated.
) else (
    echo   Admin Dashboard is already running on port 3000.
)

:: 4. ADB Reverse Forwarding for Connected Mobile Devices
echo.
echo [4/4] Setting up ADB reverse tunnel for mobile phones...
where adb >nul 2>&1
if %errorlevel% equ 0 (
    adb reverse tcp:8080 tcp:8080 2>nul
    adb reverse tcp:3000 tcp:3000 2>nul
    echo   ADB reverse active for port 8080 and port 3000.
) else (
    if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
        "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080 2>nul
        "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:3000 tcp:3000 2>nul
        echo   ADB reverse active for port 8080 and port 3000.
    )
)

echo.
echo ======================================================
echo    All CivicPulse Services are Running!
echo ======================================================
echo  - Admin Portal:    http://localhost:3000/map
echo  - Network Portal:  http://10.209.125.178:3000/map
echo  - Backend API:     http://localhost:8080/api/v1
echo  - Database:        localhost:5432 (civicpulse)
echo ======================================================
