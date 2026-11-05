#!/bin/sh
# VM test (2026-11-04, library exercise): the example pack's SoftMoss event - Say over the queen (S:queen =
# E:RiverClanQueen), Interact at ReedBank (places.ini via Events.Place), Pose Dig, Say, Bond. Boots the game.
D=/c/Projects/WarriorCats-Mod/tools/vm; R=/c/Projects/WarriorCats-Mod
C="$LOCALAPPDATA/Wrc/Saved/wacatest_cmd.txt"; L="/z/Warrior Cats Clans of the Forest/Wrc/Binaries/Win64/ue4ss/UE4SS.log"
send() { echo "$1" > "$C"; for i in $(seq 1 60); do [ -f "$C" ] || return 0; sleep 1; done; }
sh $D/boot_hi.sh > $D/boot_last.txt 2>&1
sleep 20
m=$(wc -l < "$L")
send 'Emit ClanEvent SoftMoss'
sleep 25
send 'Lua pc().Pawn:K2_SetActorLocation({ X = -45300, Y = 4200, Z = 700 }, false, {}, true); log("PROBE at ReedBank")'
sleep 12
cd $R && python tools/vm_input.py key 45
sleep 30
tail -n +$m "$L" | grep -a "PROBE\|SoftMoss\|says\|Interact\|pose\|bond\|Bond\|story check\|problem" | grep -v "party -" | cut -c12-240
echo TEST-DONE
