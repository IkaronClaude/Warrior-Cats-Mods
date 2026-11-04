#!/bin/sh
# VM test (2026-11-04): the pause menu's Clan tab (WaCa Core questtab.lua) on a fresh boot - no hot reloads (two in a
# row hung UE4SS again, 22:58). Pause > Quest > TriggerR to Side Quests > TriggerR to Clan (screenshot) > TriggerL back
# (screenshot); the quest tab's log lines.
D=/c/Projects/WarriorCats-Mod/tools/vm; R=/c/Projects/WarriorCats-Mod
C="$LOCALAPPDATA/Wrc/Saved/wacatest_cmd.txt"; L="/z/Warrior Cats Clans of the Forest/Wrc/Binaries/Win64/ue4ss/UE4SS.log"
S="$LOCALAPPDATA/Wrc/Saved/Screenshots/Windows"
shot() { last=$(ls -t "$S" | head -1); echo 'Shot' > "$C"; for i in $(seq 1 30); do n=$(ls -t "$S" | head -1); [ "$n" != "$last" ] && break; sleep 2; done; sleep 3; echo "SHOT $(ls -t "$S" | head -1)"; }
sh $D/boot_hi.sh > $D/boot_last.txt 2>&1
sleep 20
m=$(wc -l < "$L")
cd $R
python tools/vm_input.py key 1B
for i in $(seq 1 20); do tail -n +$m "$L" | grep -a -q "screen shown WBP_GuiScreenPause" && break; sleep 2; done
sleep 10
python tools/vm_input.py key 32; sleep 7
python tools/vm_input.py key 32; sleep 7
python tools/vm_input.py key 34; sleep 7
python tools/vm_input.py key 34; sleep 9
shot
python tools/vm_input.py key 33; sleep 9
shot
tail -n +$m "$L" | grep -a "quest tab\|COMMAND 1[0-2]\|screen shown WBP_GuiScreenPause" | cut -c12-220
echo TEST-DONE
