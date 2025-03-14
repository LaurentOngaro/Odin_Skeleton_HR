@echo off

:: This script creates an optimized release build.

set OUT_DIR=build\release
set SRC_DIR=source

if not exist %OUT_DIR% mkdir %OUT_DIR%

odin build %SRC_DIR%\main_release -out:%OUT_DIR%\game_release.exe -strict-style -vet -no-bounds-check -o:speed -subsystem:windows
IF %ERRORLEVEL% NEQ 0 exit /b 1

xcopy /y /e /i assets %OUT_DIR%\assets > nul
IF %ERRORLEVEL% NEQ 0 exit /b 1

echo Release build created in %OUT_DIR%