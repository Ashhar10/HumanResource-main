@echo off
title Build Elipse HR Windows Executable (.exe)
cd /d "%~dp0"

echo ===================================================================
echo         Packaging Elipse HR Portal into Standalone Windows .exe
echo ===================================================================
echo.
echo Packaging into Windows .exe installer and portable executable...
call npx electron-builder --win
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Packaging failed!
    pause
    exit /b 1
)

echo.
echo Copying updated executables...
if exist "release\Elipse HR Portal 1.0.0.exe" copy /y "release\Elipse HR Portal 1.0.0.exe" "Elipse HR Portal.exe" >nul
if exist "release\Elipse HR Portal Setup 1.0.0.exe" copy /y "release\Elipse HR Portal Setup 1.0.0.exe" "Elipse HR Portal Setup.exe" >nul

echo ===================================================================
echo SUCCESS! Your Windows .exe has been updated in:
echo %~dp0
echo ===================================================================
pause
