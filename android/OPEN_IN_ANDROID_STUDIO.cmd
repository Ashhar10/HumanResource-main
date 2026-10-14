@echo off
title Open Project in Android Studio
cd /d "%~dp0"

set "STUDIO=C:\Program Files\Android\Android Studio\bin\studio64.exe"

if exist "%STUDIO%" (
    echo Opening Elipse HR Portal Android project in Android Studio...
    start "" "%STUDIO%" "%~dp0"
) else (
    echo Android Studio not found at standard path: %STUDIO%
    pause
)
