# WaCa ModKit installer: finds Warrior Cats: Clans of the Forest through Steam and copies the mod files in.
# Usage: double-click Install.bat (or: powershell -ExecutionPolicy Bypass -File Install.ps1 [-GameDir "<folder>"])
param([string]$GameDir = "", [switch]$Uninstall)

$ErrorActionPreference = "Stop"
$AppId = "3960600"
$Payload = Join-Path $PSScriptRoot "files"
$Marker = "ue4ss\WaCaModKit.installed"

function Find-Game {
    $steam = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
    if (-not $steam) { return $null }
    $libs = @($steam)
    $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) { $libs += $m.Groups[1].Value -replace '\\\\', '\' }
    }
    foreach ($lib in ($libs | Select-Object -Unique)) {
        $acf = Join-Path $lib "steamapps\appmanifest_$AppId.acf"
        if (Test-Path $acf) {
            $dir = [regex]::Match((Get-Content $acf -Raw), '"installdir"\s+"([^"]+)"').Groups[1].Value
            $full = Join-Path $lib "steamapps\common\$dir"
            if (Test-Path $full) { return $full }
        }
    }
    return $null
}

function Pick-Folder {
    Add-Type -AssemblyName System.Windows.Forms
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.Description = "Select the Warrior Cats: Clans of the Forest game folder (the one containing 'Wrc')"
    if ($d.ShowDialog() -eq "OK") { return $d.SelectedPath }
    return $null
}

if (-not $GameDir) { $GameDir = Find-Game }
if (-not $GameDir) {
    Write-Host "Could not find the game through Steam - please pick its folder."
    $GameDir = Pick-Folder
}
$Win64 = Join-Path $GameDir "Wrc\Binaries\Win64"
if (-not $GameDir -or -not (Test-Path $Win64)) {
    Write-Host "That doesn't look like the game folder (no Wrc\Binaries\Win64 inside): $GameDir" -ForegroundColor Red
    exit 1
}
Write-Host "Game folder: $GameDir"

if ($Uninstall) {
    if (-not (Test-Path (Join-Path $Win64 $Marker))) {
        Write-Host "WaCa ModKit is not installed there (or UE4SS was installed by something else - left alone)."
        exit 0
    }
    Remove-Item (Join-Path $Win64 "dwmapi.dll") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Win64 "ue4ss") -Recurse -Force
    Write-Host "WaCa ModKit and UE4SS removed. Your game files were never changed." -ForegroundColor Green
    exit 0
}

# keep the user's own config (keybinds, names, ...) and their other mods' entries in mods.txt on an update
$cfg = Join-Path $Win64 "ue4ss\Mods\WaCaModKit\config"
$modsTxt = Join-Path $Win64 "ue4ss\Mods\mods.txt"
$keep = $null
if (Test-Path $cfg) { $keep = Join-Path $env:TEMP "WaCaModKit-config-$(Get-Random)"; Copy-Item $cfg $keep -Recurse }
$oldMods = if (Test-Path $modsTxt) { Get-Content $modsTxt } else { @() }
Copy-Item (Join-Path $Payload "Wrc\Binaries\Win64\*") $Win64 -Recurse -Force
if ($keep) { Copy-Item (Join-Path $keep "*") $cfg -Recurse -Force; Remove-Item $keep -Recurse -Force }
if ($oldMods.Count -gt 0) {
    # the user's list stays as it was; only mods it doesn't mention yet are added (before the Keybinds line)
    $known = @{}
    foreach ($l in $oldMods) { if ($l -match '^\s*([^;:]+?)\s*:') { $known[$Matches[1]] = $true } }
    $add = foreach ($l in (Get-Content $modsTxt)) { if ($l -match '^\s*([^;:]+?)\s*:' -and -not $known[$Matches[1]]) { $l } }
    $add = @($add) + @("WaCaModKit : 1") | Where-Object { $_ -notmatch '^\s*WaCaModKit\s*:' -or -not $known['WaCaModKit'] } | Select-Object -Unique
    $merged = New-Object System.Collections.Generic.List[string]
    foreach ($l in $oldMods) {
        if ($l -match '^\s*Keybinds\s*:' -and $add) { $merged.AddRange([string[]]$add); $add = $null }
        if ($l -match '^\s*WaCaModKit\s*:') { $l = "WaCaModKit : 1" }
        $merged.Add($l)
    }
    if ($add) { $merged.AddRange([string[]]$add) }
    Set-Content $modsTxt $merged -Encoding ascii
}
New-Item -ItemType File -Force (Join-Path $Win64 $Marker) | Out-Null
Write-Host "WaCa ModKit installed. Start the game from Steam as usual." -ForegroundColor Green
Write-Host "Key bindings: $cfg\keybinds.ini"
