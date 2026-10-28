@echo off
rem WaCa Core: double-click to install (finds the game through Steam).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
pause
