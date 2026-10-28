@echo off
rem Removes the old all-in-one WaCa ModKit (UE4SS stays). Run this BEFORE installing the WaCa mods.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall-old.ps1" %*
pause
