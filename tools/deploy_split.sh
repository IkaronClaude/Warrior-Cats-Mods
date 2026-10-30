#!/bin/sh
# Copies the split repos' scripts (and the given config files) into the VM's game install on Z: - dev iteration only;
# the test install's own config switches stay. Usage: deploy_split.sh [config files relative to a mod's config/ ...]
M="/z/Warrior Cats Clans of the Forest/Wrc/Binaries/Win64/ue4ss/Mods"
for pair in Core:WaCaCore KeybindsMouse:WaCaKeybinds Looks:WaCaLooks ClanLife:WaCaClanLife Hunting:WaCaHunting Graphics:WaCaGraphics Cutscenes:WaCaCutscenes; do
  repo=${pair%%:*}; mod=${pair##*:}
  cp /c/Projects/WaCa-$repo/Mods/$mod/Scripts/*.lua "$M/$mod/Scripts/"
done
cp /c/Projects/WaCa-Core/Mods/shared/WaCa/*.lua "$M/shared/WaCa/"
cp /c/Projects/WaCa-Core/native/out/main.dll "$M/WaCaCore/dlls/main.dll" 2>/dev/null || echo "(main.dll in use - not copied)"
for f in "$@"; do
  for pair in KeybindsMouse:WaCaKeybinds Looks:WaCaLooks ClanLife:WaCaClanLife Hunting:WaCaHunting Graphics:WaCaGraphics Core:WaCaCore; do
    repo=${pair%%:*}; mod=${pair##*:}
    [ -f /c/Projects/WaCa-$repo/Mods/$mod/config/$f ] && cp /c/Projects/WaCa-$repo/Mods/$mod/config/$f "$M/$mod/config/$f" && echo "config $mod/$f"
  done
done
echo deployed
