# WaCa mod installer: finds Warrior Cats: Clans of the Forest through Steam and copies the mod in this folder
# (files\Wrc\...) into the game's folder. The same script is in every WaCa mod's folder.
# Usage: double-click install.bat (or: powershell -ExecutionPolicy Bypass -File install.ps1 [-GameDir "<folder>"])
param([string]$GameDir = "")

$ErrorActionPreference = "Stop"
$AppId = "3960600"
$Payload = Join-Path $PSScriptRoot "files"
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

$Ue4ss = Join-Path $Win64 "ue4ss"
$ModsDir = Join-Path $Ue4ss "Mods"
if (-not (Test-Path (Join-Path $Ue4ss "UE4SS.dll"))) {
    Write-Host "UE4SS is not installed in this game folder - install UE4SS first (see the README), then run this again." -ForegroundColor Red
    exit 1
}
if (Test-Path (Join-Path $ModsDir "WaCaModKit")) {
    Write-Host "The old all-in-one WaCa ModKit is still installed - run uninstall-old.bat first, then this again." -ForegroundColor Red
    exit 1
}

$newMods = Get-ChildItem (Join-Path $Payload "Wrc\Binaries\Win64\ue4ss\Mods") -Directory
if (-not ($newMods | Where-Object { $_.Name -eq "WaCaCore" }) -and -not (Test-Path (Join-Path $ModsDir "WaCaCore"))) {
    Write-Host "WaCa Core isn't installed yet - every WaCa mod needs it. Install WaCa Core first, then this again." -ForegroundColor Red
    exit 1
}

# an update: the mod's settings from before are kept as config-backup-<time> (the new defaults go in)
foreach ($mod in $newMods) {
    $cfg = Join-Path $ModsDir "$($mod.Name)\config"
    if (Test-Path $cfg) {
        $backup = Join-Path $ModsDir "$($mod.Name)\config-backup-$Stamp"
        Copy-Item $cfg $backup -Recurse
        Write-Host "Your old $($mod.Name) settings: $backup"
    }
}

Copy-Item (Join-Path $Payload "Wrc\Binaries\Win64\*") $Win64 -Recurse -Force

$modsTxt = Join-Path $ModsDir "mods.txt"
foreach ($mod in $newMods) {
    if ($mod.Name -eq "shared") { continue }
    # (a disabled leftover from earlier - enabled.txt is what turns the mod on)
    Remove-Item (Join-Path $ModsDir "$($mod.Name)\enabled.txt.off") -Force -ErrorAction SilentlyContinue
    # (a "Mod : 0" line in mods.txt from earlier is switched on too)
    if (Test-Path $modsTxt) {
        $lines = Get-Content $modsTxt
        $pattern = '^\s*' + [regex]::Escape($mod.Name) + '\s*:\s*0\s*$'
        if ($lines | Where-Object { $_ -match $pattern }) {
            Set-Content $modsTxt ($lines | ForEach-Object { if ($_ -match $pattern) { "$($mod.Name) : 1" } else { $_ } }) -Encoding ascii
        }
    }
    Write-Host "Installed $($mod.Name)"
}

# content paks (Wrc\Content\Paks\~mods); a copy of the same pak in LogicMods from an earlier install would load twice
$paks = Join-Path $Payload "Wrc\Content\Paks\~mods"
if (Test-Path $paks) {
    $modPaks = Join-Path $GameDir "Wrc\Content\Paks\~mods"
    New-Item -ItemType Directory -Force $modPaks | Out-Null
    foreach ($pak in Get-ChildItem $paks -File) {
        Copy-Item $pak.FullName $modPaks -Force
        Remove-Item (Join-Path $GameDir "Wrc\Content\Paks\LogicMods\$($pak.Name)") -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Installed the content pak(s) into Wrc\Content\Paks\~mods"
}

Write-Host "Done. Start the game from Steam as usual." -ForegroundColor Green
