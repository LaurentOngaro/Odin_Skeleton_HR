@echo off

:: This script starts a simple HTTP server to serve the contents of the build\web directory.

set OUT_DIR=build\web

if not exist "%OUT_DIR%" (
    echo Error: Directory "%OUT_DIR%" does not exist.
    exit /b 1
)

cd %OUT_DIR%

:: launch the server in another process
start python -m http.server 8000
echo Server started at http://localhost:8000

:: Open the default browser
start http://localhost:8000