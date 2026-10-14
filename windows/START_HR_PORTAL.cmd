@echo off
title Elipse HR Portal - Desktop App
cd /d "%~dp0"
echo ===================================================================
echo               Launching Elipse HR Portal Desktop App
echo ===================================================================
if exist "%~dp0Elipse HR Portal.exe" (
    start "" "%~dp0Elipse HR Portal.exe"
    exit
) else if exist "%~dp0..\hr-portal-web\release\win-unpacked\Elipse HR Portal.exe" (
    start "" "%~dp0..\hr-portal-web\release\win-unpacked\Elipse HR Portal.exe"
    exit
) else (
    echo Executable not found! Run BUILD_WINDOWS_EXE.cmd to build it.
    pause
)
