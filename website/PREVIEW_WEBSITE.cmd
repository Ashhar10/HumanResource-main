@echo off
title Elipse HR Portal - Local Web Server Preview
cd /d "%~dp0"
echo ===================================================================
echo             Starting Local Website Preview Server
echo ===================================================================
echo.
echo Website will open at http://localhost:4173
echo Press Ctrl+C in this window to stop the preview server.
echo.
call npx vite preview --port 4173 --open
pause
