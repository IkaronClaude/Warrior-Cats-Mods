# Builds the release: dist\WaCaModKit-<version>\ + .zip (UE4SS + WaCaModKit, ready to install).
# Needs: native\out\main.dll (native\build.bat) and UE4SS extracted in tools\bin\ue4ss (see PROJECT_PLAN.md).
param([string]$Version = "0.2.0")
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$name = "WaCaModKit-$Version"
$out = Join-Path $root "dist\$name"
$win64 = Join-Path $out "files\Wrc\Binaries\Win64"
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory -Force $win64 | Out-Null

# UE4SS (a clean copy of the release, not a test install)
Copy-Item (Join-Path $root "tools\bin\ue4ss\*") $win64 -Recurse
$mods = Join-Path $win64 "ue4ss\Mods"
# only what players need: the Blueprint mod loader (for other people's pak mods) + the built-in keybinds; no cheats
$enabled = @{ "BPML_GenericFunctions" = 1; "BPModLoaderMod" = 1; "Keybinds" = 1; "WaCaModKit" = 1 }
$list = (Get-ChildItem $mods -Directory | ForEach-Object Name) + "WaCaModKit" | Select-Object -Unique
$txt = foreach ($m in $list | Where-Object { $_ -ne "Keybinds" -and $_ -ne "shared" }) { "$m : $(if ($enabled[$m]) {1} else {0})" }
$txt += "", "; Built-in keybinds, do not move up!", "Keybinds : 1"
Set-Content (Join-Path $mods "mods.txt") $txt -Encoding ascii
$json = foreach ($m in $list | Where-Object { $_ -ne "shared" }) { [ordered]@{ mod_name = $m; mod_enabled = [bool]$enabled[$m] } }
ConvertTo-Json @($json) | Set-Content (Join-Path $mods "mods.json") -Encoding ascii

# WaCaModKit: the Lua scripts + config, and the native DLL
Copy-Item (Join-Path $root "mod\WaCaModKit") $mods -Recurse
Copy-Item (Join-Path $root "mod\shared\WaCa") (Join-Path $mods "shared") -Recurse      # the API other mods require
New-Item -ItemType Directory -Force (Join-Path $mods "WaCaModKit\dlls") | Out-Null
Copy-Item (Join-Path $root "native\out\main.dll") (Join-Path $mods "WaCaModKit\dlls\main.dll")
Copy-Item (Join-Path $root "LICENSE") (Join-Path $mods "WaCaModKit\LICENSE.txt") -ErrorAction SilentlyContinue

# installer + readme
Copy-Item (Join-Path $root "install\*") $out
$zip = Join-Path $root "dist\$name.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path $out -DestinationPath $zip
Write-Host "built $zip"
