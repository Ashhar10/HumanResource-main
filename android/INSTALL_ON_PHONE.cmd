@echo off
title Install Elipse HR Portal on Android Device
cd /d "%~dp0"

echo ========================================================
echo   Elipse HR Portal - USB / ADB Phone Installer
echo ========================================================
echo.

set "ANDROID_HOME=C:\Users\Pc\AppData\Local\Android\Sdk"
set "ADB=%ANDROID_HOME%\platform-tools\adb.exe"

if not exist "%ADB%" (
    echo [ERROR] ADB tool not found at: %ADB%
    pause
    exit /b 1
)

if not exist "Elipse HR Portal.apk" (
    echo [ERROR] "Elipse HR Portal.apk" not found! Run BUILD_ANDROID_APK.cmd first.
    pause
    exit /b 1
)

echo Checking for connected Android devices...
"%ADB%" devices
echo.

echo Installing "Elipse HR Portal.apk" onto device...
"%ADB%" install -r "Elipse HR Portal.apk"
if %errorlevel% neq 0 (
    echo.
    echo [NOTE] If install failed, ensure:
    echo   1. "USB Debugging" is enabled on your phone (Developer Options).
    echo   2. You approved the "Allow USB Debugging" popup on your phone screen.
    echo.
    pause
    exit /b %errorlevel%
)

echo.
echo ========================================================
echo   SUCCESS: App installed on your Android device!
echo ========================================================
echo.
pause
