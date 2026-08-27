@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SwapResolution.ps1" %*
if errorlevel 1 pause
