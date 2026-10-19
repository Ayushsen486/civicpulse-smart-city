@echo off
title CivicPulse - Public HTTPS Internet Link
echo ======================================================
echo    Generating Public HTTPS Link for CivicPulse Admin
echo ======================================================
echo.
echo Connecting to tunnel network...
echo Your permanent public link will appear below:
echo.
call npx -y localtunnel --port 3000 --subdomain civicpulse-admin-hub
pause
