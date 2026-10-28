# Removes the old all-in-one WaCa ModKit (0.6.x and earlier) before installing the split WaCa mods.
# UE4SS stays (the WaCa mods need it). Nothing is deleted: the old mod folder and its content pak are moved to
# Wrc\Binaries\Win64\WaCaModKit-old-<time> - your old settings, saved looks and rosters are in there.
# Usage: double-click uninstall-old.bat (or: powershell -ExecutionPolicy Bypass -File uninstall-old.ps1 [-GameDir "<folder>"])
param([string]$GameDir = "")

$ErrorActionPreference = "Stop"
$AppId = "3960600"
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"

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

$ModsDir = Join-Path $Win64 "ue4ss\Mods"
$old = Join-Path $ModsDir "WaCaModKit"
$paks = @()
foreach ($dir in "~mods", "LogicMods") {
    $p = Join-Path $GameDir "Wrc\Content\Paks\$dir"
    if (Test-Path $p) { $paks += Get-ChildItem $p -File -Filter "WaCaModKit_P.*" }
}
$marker = Join-Path $Win64 "ue4ss\WaCaModKit.installed"
if (-not (Test-Path $old) -and -not $paks -and -not (Test-Path $marker)) {
    Write-Host "The old WaCa ModKit isn't installed there - nothing to do." -ForegroundColor Green
    exit 0
}

$backup = Join-Path $Win64 "WaCaModKit-old-$Stamp"
New-Item -ItemType Directory -Force $backup | Out-Null
if (Test-Path $old) { Move-Item $old (Join-Path $backup "WaCaModKit") }
foreach ($pak in $paks) {
    # (Paks\~mods and Paks\LogicMods can both hold one: each into its own folder)
    $dest = Join-Path $backup ("Paks-" + $pak.Directory.Name)
    New-Item -ItemType Directory -Force $dest | Out-Null
    Move-Item $pak.FullName $dest
}

# mods.txt: the old mod's line goes (the rest of the list stays as it was)
$modsTxt = Join-Path $ModsDir "mods.txt"
if (Test-Path $modsTxt) {
    $lines = Get-Content $modsTxt
    if ($lines | Where-Object { $_ -match '^\s*WaCaModKit\s*:' }) {
        Copy-Item $modsTxt (Join-Path $backup "mods.txt")
        Set-Content $modsTxt ($lines | Where-Object { $_ -notmatch '^\s*WaCaModKit\s*:' }) -Encoding ascii
    }
}
# (the old installer's marker: without it, the old Uninstall.bat can no longer remove UE4SS, which the new mods need)
if (Test-Path $marker) { Move-Item $marker $backup }

Write-Host "The old WaCa ModKit is removed (UE4SS stays)." -ForegroundColor Green
Write-Host "Your old settings, saved looks and rosters were moved to: $backup"
Write-Host "Now install WaCa Core, then the other WaCa mods (or run install-all.bat)."
