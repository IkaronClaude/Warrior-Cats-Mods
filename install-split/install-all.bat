@echo off
rem Removes the old WaCa ModKit, then installs every WaCa mod in this folder (Core first).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp00-Uninstall-old-WaCaModKit\uninstall-old.ps1" %*
if errorlevel 1 goto end
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp01-WaCa-Core-1.0.0\install.ps1" %*
if errorlevel 1 goto end
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp02-WaCa-KeybindsMouse-1.0.0\install.ps1" %*
if errorlevel 1 goto end
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp03-WaCa-Looks-1.0.0\install.ps1" %*
if errorlevel 1 goto end
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp04-WaCa-ClanLife-0.8.0\install.ps1" %*
if errorlevel 1 goto end
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp05-WaCa-Hunting-0.8.0\install.ps1" %*
if errorlevel 1 goto end
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp06-WaCa-Graphics-1.0.0\install.ps1" %*
if errorlevel 1 goto end
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp07-WaCa-Cutscenes-0.1.0\install.ps1" %*
if errorlevel 1 goto end
:end
pause
