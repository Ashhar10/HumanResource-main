@echo off
title Elipse HR Portal - Native Desktop Application
cd /d "%~dp0..\website"
echo ===================================================================
echo             Launching Elipse HR Desktop Application
echo ===================================================================
echo.
npx electron .
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Application stopped. Press any key to close.
    pause >nul
)
