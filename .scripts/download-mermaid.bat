@echo off
setlocal enabledelayedexpansion

:: ----------------------------------------
:: Configure Project Absolute Directory
:: ----------------------------------------

set PROJECT_DIR=%~dp0..
pushd "%PROJECT_DIR%"
set PROJECT_DIR=%CD%
popd

echo Project directory detected:
echo %PROJECT_DIR%

:: ----------------------------------------
:: Configuration
:: ----------------------------------------

set VERSION=11.6.0
set URL_JS=https://cdn.jsdelivr.net/npm/mermaid@%VERSION%/dist/mermaid.min.js
set URL_ESM_JS=https://cdn.jsdelivr.net/npm/mermaid@%VERSION%/dist/mermaid.esm.min.mjs
set URL_LICENSE=https://raw.githubusercontent.com/mermaid-js/mermaid/develop/LICENSE

set TARGET_WWW_DIR=%PROJECT_DIR%\wwwroot
set TARGET_JS_DIR=%TARGET_WWW_DIR%\js

set TARGET_JS_FILE=%TARGET_JS_DIR%\mermaid.min.js
set TARGET_ESM_JS_FILE=%TARGET_JS_DIR%\mermaid.esm.min.mjs
set TARGET_LICENSE=%TARGET_WWW_DIR%\LICENSE-mermaid.txt

:: ----------------------------------------
:: Create Directories
:: ----------------------------------------

if not exist "%TARGET_JS_DIR%" mkdir "%TARGET_JS_DIR%"

:: ----------------------------------------
:: Download Core Files
:: ----------------------------------------

echo Downloading core files...

curl -o "%TARGET_JS_FILE%" "%URL_JS%"
curl -o "%TARGET_ESM_JS_FILE%" "%URL_ESM_JS%"
curl -o "%TARGET_LICENSE%" "%URL_LICENSE%"

:: ----------------------------------------
:: Detect and Download additional JS if needed
:: ----------------------------------------

echo Detecting additional ESM dependency...
set ADDITIONAL_FILE=""

set TEMP_RESULT_FILE=detect_result.tmp

:: Find matching line
findstr /R "\.\/.*\.js" "%TARGET_ESM_JS_FILE%" > "%TEMP_RESULT_FILE%"

:: Initialize
set "ADDITIONAL_FILE="

:: Read line
for /f "delims=" %%l in (%TEMP_RESULT_FILE%) do (
    set "LINE=%%l"
)

:: Cleanup
del "%TEMP_RESULT_FILE%"


:: Parse manually
for /f "tokens=2 delims=\"\"" %%a in ("!LINE!") do (
    set "ADDITIONAL_FILE=%%a"
)

if not "%ADDITIONAL_FILE%"=="" (
    echo Detected additional JS file: %ADDITIONAL_FILE%
    
    set ADDITIONAL_FILE_FIXED=%ADDITIONAL_FILE:./=%
    set URL_ADDITIONAL_JS=https://cdn.jsdelivr.net/npm/mermaid@%VERSION%/dist/%ADDITIONAL_FILE_FIXED%
    set TARGET_ADDITIONAL_JS_FILE=%TARGET_JS_DIR%\%ADDITIONAL_FILE_FIXED%

    curl -o "%TARGET_ADDITIONAL_JS_FILE%" "%URL_ADDITIONAL_JS%"
) else (
    echo No additional file detected.
)

:: ----------------------------------------
:: Done
:: ----------------------------------------

echo.
echo ===================================
echo Finished downloading MermaidJS files
echo ===================================

@pause
