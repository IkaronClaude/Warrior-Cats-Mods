@echo off
rem WaCa ModKit: double-click to install (finds the game through Steam).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1" %*
pause
