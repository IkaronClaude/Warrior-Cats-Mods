# A release WITH the content pak (rain / snow / rain sound), from a machine with Unreal 5.7.4 (the VM): GitHub's
# release runners have no Unreal, so the zip the release workflow attaches has no content pak. This builds the
# content, the native DLL, UE4SS (from the pinned source build) and the release zip with all of it, and with -Upload
# replaces the release's zip by it (gh release upload --clobber) - players still download ONE zip.
#   tools\release_with_content.ps1 -Version 0.8.0 [-Upload]
# Run it after the release workflow finished for that tag (it replaces that zip).
param([Parameter(Mandatory = $true)][string]$Version, [switch]$Upload)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

Write-Host "== content pak"
& (Join-Path $PSScriptRoot "build_content.ps1")
if (-not (Test-Path (Join-Path $root "dist\content\WaCaModKit_P.utoc"))) { throw "no content pak built" }

Write-Host "== native DLL"
$ErrorActionPreference = "Continue"      # (native tools print progress to stderr - Windows PowerShell calls that an error)
& cmd /c (Join-Path $root "native\build.bat") 2>&1 | Out-Host
$built = $LASTEXITCODE
$ErrorActionPreference = "Stop"
if ($built -ne 0) { throw "native build failed" }

Write-Host "== UE4SS (the pinned build)"
$ue4ss = Join-Path $root "tools\bin\ue4ss"
if (-not (Test-Path (Join-Path $ue4ss "ue4ss\UE4SS.dll"))) {
    $ErrorActionPreference = "Continue"
    python (Join-Path $PSScriptRoot "ue4ss_release.py") (Join-Path $root "tools\bin\src\RE-UE4SS") `
        (Join-Path $root "native\build\Game__Shipping__Win64\bin") $ue4ss 2>&1 | Out-Host
    $packed = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    if ($packed -ne 0) { throw "UE4SS packaging failed" }
}

Write-Host "== release zip"
& (Join-Path $PSScriptRoot "package.ps1") -Version $Version
$zip = Join-Path $root "dist\WaCaModKit-$Version.zip"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$inside = [System.IO.Compression.ZipFile]::OpenRead($zip)
try { $hasPak = @($inside.Entries | Where-Object { $_.FullName -like "*~mods/WaCaModKit_P.utoc" -or $_.FullName -like "*~mods\WaCaModKit_P.utoc" }).Count -gt 0 }
finally { $inside.Dispose() }
if (-not $hasPak) { throw "the zip has no content pak" }
Write-Host "built $zip (with the content pak)"

if ($Upload) {
    $gh = Join-Path $root "tools\bin\gh\bin\gh.exe"
    & $gh release upload "v$Version" $zip --clobber --repo IkaronClaude/Warrior-Cats-Mods
    if ($LASTEXITCODE -ne 0) { throw "upload failed" }
    Write-Host "release v$Version now has the zip with the content pak"
}
