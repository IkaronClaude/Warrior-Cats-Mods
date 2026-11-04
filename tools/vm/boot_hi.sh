#!/bin/sh
D=/c/Projects/WarriorCats-Mod/tools/vm
# (a crash since the last boot: its session logs kept with its report before this boot overwrites them)
CR="$LOCALAPPDATA/Wrc/Saved/Crashes"; LG="/z/Warrior Cats Clans of the Forest/Wrc/Binaries/Win64/ue4ss"
latest=$(ls -t "$CR" 2>/dev/null | head -1)
# (the log written in the same second as the crash report counts too: -nt missed a crash at 02:56 on 2026-11-03)
if [ -n "$latest" ] && [ ! "$LG/UE4SS.log" -nt "$CR/$latest/CrashContext.runtime-xml" ] && [ ! -f "$CR/$latest/UE4SS.log" ]; then
  cp "$LG/UE4SS.log" "$CR/$latest/UE4SS.log" 2>/dev/null; cp "$LG/Mods/WaCaCore/WaCaNative.log" "$CR/$latest/WaCaNative.log" 2>/dev/null
  echo "kept the crashed session's logs in $latest"
fi
cd /c/Projects/WarriorCats-Mod/tools
C="$LOCALAPPDATA/Wrc/Saved/wacatest_cmd.txt"; L="/z/Warrior Cats Clans of the Forest/Wrc/Binaries/Win64/ue4ss/UE4SS.log"
send() { echo "$1" > "$C"; for i in $(seq 1 60); do [ -f "$C" ] || return 0; sleep 1; done; }
taskkill //IM Wrc-Win64-Shipping-NoStub.exe //F >/dev/null 2>&1; sleep 3; rm -f "$C"
sh /c/Projects/WarriorCats-Mod/tools/deploy_split.sh | tail -1
sh $D/vm_run_hi.sh 10 >/dev/null 2>&1 &
sleep 30
timeout 500 tail -n 0 -F "$L" 2>/dev/null | grep -a -m1 "screen shown WBP_GuiScreenSelectYourCat" | cut -c1-100
sleep 25
for t in 1 2 3; do python vm_input.py key 0D; r=$(timeout 150 tail -n 0 -F "$L" 2>/dev/null | grep -a -m1 "the camp is the game.s zone\|meeting place" | cut -c1-100); [ -n "$r" ] && { echo "$r"; break; }; done
sleep 30
grep -a "STATUS\|duties: day\|task " "$L" | tail -6 | cut -c12-200
