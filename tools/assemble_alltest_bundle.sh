#!/bin/sh
# The operator's EVERYTHING-ON test bundle (2026-11-04): assemble_test_bundle.sh's per-mod install folders, every
# feature switched on (all_on.py), the example story pack as install number 8, and its README; zipped next to it.
# Usage: assemble_alltest_bundle.sh <out dir>      (e.g. Z:/WaCa/WaCa-mods-alltest-<date>)
set -e
O="$1"; T=/c/Projects/WarriorCats-Mod/tools; S=/c/Projects/WarriorCats-Mod/install-split
[ -n "$O" ] || { echo "usage: $0 <out dir>"; exit 1; }
sh $T/assemble_test_bundle.sh "$O" | tail -1
rm -f /c/Projects/WaCa-*/dist/*.zip
python $T/all_on.py "$O" | tail -1
P="$O/8-WaCaStoryPackExample"
mkdir -p "$P/files/Wrc/Binaries/Win64/ue4ss/Mods"
cp -r /c/Projects/WaCa-ClanLife/examples/WaCaStoryPackExample "$P/files/Wrc/Binaries/Win64/ue4ss/Mods/"
cp $S/install.ps1 "$P/"
printf '@echo off\r\nrem WaCa example story pack: double-click to install (finds the game through Steam).\r\npowershell -NoProfile -ExecutionPolicy Bypass -File "%%~dp0install.ps1" %%*\r\npause\r\n' > "$P/install.bat"
python - "$O/install-all.bat" <<'EOF'
import sys
p = sys.argv[1]; t = open(p, newline="").read()
add = 'echo.\r\npowershell -NoProfile -ExecutionPolicy Bypass -File "%~dp08-WaCaStoryPackExample\\install.ps1" %*\r\nif errorlevel 1 goto end\r\n'
if "8-WaCaStoryPackExample" not in t:
    t = t.replace(":end", add + ":end", 1)
open(p, "w", newline="").write(t)
EOF
cp $S/README-alltest.txt "$O/README.txt"
z="$(cygpath -w "$(dirname "$O")")"; n="$(basename "$O")"
powershell -NoProfile -Command "Set-Location '$z'; if (Test-Path '$n.zip') { Remove-Item '$n.zip' }; & \"\$env:SystemRoot\System32\tar.exe\" -a -cf '$n.zip' '$n'"
echo "bundle in $O (+ $n.zip)"
