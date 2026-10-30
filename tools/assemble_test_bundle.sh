#!/bin/sh
# Builds the per-mod install folders for an operator test (Z:/WaCa/WaCa-mods-test-<date>): each repo's package
# (tools/package.ps1) under <n>-<Repo>-<version>/files, with install-split's install.bat / install.ps1, the
# uninstall-old folder, install-all.bat and README.txt; the test switches on (the clan sim; hunting by chance, fishing, fleeing).
# Usage: assemble_test_bundle.sh <out dir>
set -e
O="$1"; S=/c/Projects/WarriorCats-Mod/install-split
[ -n "$O" ] || { echo "usage: $0 <out dir>"; exit 1; }
for r in Core KeybindsMouse Looks ClanLife Hunting Graphics Cutscenes; do
  powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Projects\WaCa-$r\tools\package.ps1" >/dev/null
done
mkdir -p "$O/0-Uninstall-old-WaCaModKit"
cp "$S/uninstall-old.ps1" "$S/uninstall-old.bat" "$O/0-Uninstall-old-WaCaModKit/"
i=1
for r in Core KeybindsMouse Looks ClanLife Hunting Graphics Cutscenes; do
  pkg=$(ls -d /c/Projects/WaCa-$r/dist/WaCa-$r-*/ | head -1); p=$(basename "$pkg")
  d="$O/$i-$p"; mkdir -p "$d/files"
  [ -d "$d/files/Wrc" ] && mv "$d/files/Wrc" "$d/files/Wrc.old-$(date +%H%M%S)"
  cp -r "$pkg/Wrc" "$d/files/"
  cp "$S/install.ps1" "$d/"
  printf '@echo off\r\nrem WaCa %s: double-click to install (finds the game through Steam).\r\npowershell -NoProfile -ExecutionPolicy Bypass -File "%%~dp0install.ps1" %%*\r\npause\r\n' "$r" > "$d/install.bat"
  i=$((i+1))
done
cp "$S/install-all.bat" "$S/README.txt" "$O/"
M="Wrc/Binaries/Win64/ue4ss/Mods"
sed -i 's/^On = 0$/On = 1/' "$O"/4-WaCa-ClanLife-*/files/$M/WaCaClanLife/config/clanlife.ini
# (hunting by chance, fishing, fleeing on - NOT the scent trail or the StarClan guidance: the game has both, ours were
# ugly - operator 2026-10-30)
H=$(ls "$O"/5-WaCa-Hunting-*/files/$M/WaCaHunting/config/hunting.ini)
sed -i -E 's/^(On|Flee) *= *0\s*$/\1 = 1/' "$H"
awk '/^\[Guidance\]/{g=1} g&&/^On *=/{$0="On = 0";g=0} {print}' "$H" > "$H.tmp" && mv "$H.tmp" "$H"
echo "bundle in $O"
