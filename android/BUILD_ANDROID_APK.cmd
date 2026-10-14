@echo off
title Rebuild Elipse HR Portal Android APK
cd /d "%~dp0"

echo ========================================================
echo   Elipse HR Portal - Android APK Builder
echo ========================================================
echo.

set "JAVA_HOME=C:\Program Files\Java\jdk-17"
set "ANDROID_HOME=C:\Users\Pc\AppData\Local\Android\Sdk"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%"

echo [1/2] Compiling Android APK with Gradle...
call gradlew.bat assembleDebug
if %errorlevel% neq 0 (
    echo [ERROR] Gradle build failed.
    pause
    exit /b %errorlevel%
)

echo [2/2] Copying APK to android\Elipse HR Portal.apk...
copy /y "app\build\outputs\apk\debug\app-debug.apk" "Elipse HR Portal.apk" >nul

echo.
echo ========================================================
echo   SUCCESS: Android APK is ready!
echo   Location: %~dp0Elipse HR Portal.apk
echo ========================================================
echo.
pause
