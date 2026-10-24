@echo off
rem WaCa ModKit: double-click to remove the mod and UE4SS from the game folder.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1" -Uninstall %*
pause
