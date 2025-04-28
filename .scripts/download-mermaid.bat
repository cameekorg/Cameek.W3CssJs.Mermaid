@echo.
@echo Download MermaidJS
@echo ===================
@echo https://www.jsdelivr.com/package/npm/mermaid
@echo.

:: Shorten the prompt temporarily
@prompt $S

:: Change the current directory to the script's directory
@pushd %~dp0

@echo Configuring Version and URLs
@echo ----------------------------
set VERSION=10.9.0
set URL_JS=https://cdn.jsdelivr.net/npm/mermaid@%VERSION%/dist/mermaid.min.js
set URL_ESM_JS=https://cdn.jsdelivr.net/npm/mermaid@%VERSION%/dist/mermaid.esm.min.mjs
set URL_LICENSE=https://raw.githubusercontent.com/mermaid-js/mermaid/develop/LICENSE

@echo.
@echo.

@echo Configuring Target Directories and Files
@echo ----------------------------------------
set TARGET_WWW_DIR=../wwwroot
set TARGET_JS_DIR=%TARGET_WWW_DIR%/js

set TARGET_JS_FILE=%TARGET_JS_DIR%/mermaid.min.js
set TARGET_ESM_JS_FILE=%TARGET_JS_DIR%/mermaid.esm.min.mjs
set TARGET_LICENSE=%TARGET_WWW_DIR%/LICENSE-mermaid.txt

@echo.
@echo.

@echo Creating Directories
@echo --------------------
if not exist "%TARGET_JS_DIR%" mkdir "%TARGET_JS_DIR%"
@echo.
@echo.

@echo Downloading Files
@echo -----------------
curl -o %TARGET_JS_FILE% %URL_JS%
curl -o %TARGET_ESM_JS_FILE% %URL_ESM_JS%
curl -o %TARGET_LICENSE% %URL_LICENSE%
@echo.
@echo.

:: Restore the previous directory
@popd

:: Reset the prompt to the default
@prompt

@echo.
@echo ===================================
@echo Finished downloading MermaidJS files
@echo.

@pause
