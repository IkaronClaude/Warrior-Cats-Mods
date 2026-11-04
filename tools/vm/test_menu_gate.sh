#!/bin/sh
# VM test (2026-11-04): a scene asked for on Select Your Cat waits for the world (Clan Life's PlayScene gate), and a
# party cat that leads your cat goes with you again after (walkers' Unstage). Boots the game (boot_hi.sh).
D=/c/Projects/WarriorCats-Mod/tools/vm
C="$LOCALAPPDATA/Wrc/Saved/wacatest_cmd.txt"; L="/z/Warrior Cats Clans of the Forest/Wrc/Binaries/Win64/ue4ss/UE4SS.log"
sh $D/boot_hi.sh > $D/boot_last.txt 2>&1 &
sleep 40
timeout 900 tail -n 0 -F "$L" 2>/dev/null | grep -a -q -m1 "screen shown WBP_GuiScreenSelectYourCat"
echo 'Emit PlayScene Card: PROBE asked on Select Your Cat' > "$C"
timeout 900 tail -n 0 -F "$L" 2>/dev/null | grep -a -q -m1 "meeting place\|the camp is the game"
sleep 40
echo "== the gate"
grep -a "PROBE asked on Select\|not in the world\|in the menus - playing\|card: PROBE" "$L" | cut -c12-200
echo "== the party lead"
echo 'Emit PlayScene Lead: Rippleface @ Nightheart|Card: PROBE party lead done' > "$C"
for i in $(seq 1 60); do grep -a -q "goes with you again\|Nightheart is home again" "$L" && break; sleep 6; done
grep -a "Nightheart leads\|led your cat\|goes with you again\|Nightheart is home again" "$L" | cut -c12-200
echo TEST-DONE
