@echo off
rem Builds native\out\main.dll (WaCaNative, the C++ half of WaCa ModKit). Needs Visual Studio's C++ tools.
setlocal
cd /d "%~dp0"
set VCVARS=C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat
if not exist "%VCVARS%" for /f "usebackq delims=" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath`) do set VCVARS=%%i\VC\Auxiliary\Build\vcvars64.bat
call "%VCVARS%" >nul 2>&1 || (echo Visual Studio C++ tools not found & exit /b 1)
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release || exit /b 1
cmake --build build || exit /b 1
if not exist out mkdir out
copy /y build\main.dll out\main.dll >nul
echo built %~dp0out\main.dll
