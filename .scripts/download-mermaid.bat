@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0download-mermaid.ps1"
exit /b %errorlevel%
