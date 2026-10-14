@echo off
title Build Website for Production Hosting
cd /d "%~dp0"
echo ===================================================================
echo               Building Production Website Files
echo ===================================================================
echo.
call npm run build
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed! Check errors above.
    pause
    exit /b 1
)

echo.
echo ===================================================================
echo SUCCESS! Your production website files are ready in:
echo %~dp0dist
echo Upload the contents of the "dist" folder to your web host!
echo ===================================================================
echo.
pause
