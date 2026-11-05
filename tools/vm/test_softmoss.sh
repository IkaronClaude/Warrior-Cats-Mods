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
send 'Lua local best; for _, s in ipairs(FindAllOf("BP_Interactable_CInematic_C") or {}) do pcall(function() local q = s:K2_GetActorLocation(); if math.abs(q.X + 45300) < 200 and math.abs(q.Y - 4200) < 200 then best = q end end) end; if best then pc().Pawn:K2_SetActorLocation({ X = best.X + 60, Y = best.Y, Z = best.Z + 60 }, false, {}, true) end; log("PROBE at ReedBank, spot %s", tostring(best ~= nil))'
sleep 12
cd $R && python tools/vm_input.py key 45
sleep 22
S="$LOCALAPPDATA/Wrc/Saved/Screenshots/Windows"
for k in 1 2; do last=$(ls -t "$S" | head -1); send 'Shot'; for i in $(seq 1 20); do n=$(ls -t "$S" | head -1); [ "$n" != "$last" ] && break; sleep 2; done; echo "SHOT $(ls -t "$S" | head -1)"; sleep 4; done
sleep 15
tail -n +$m "$L" | grep -a "PROBE\|SoftMoss\|says\|Interact\|pose\|bond\|Bond\|story check\|problem\|QueenThanks\|cutscene\|line:" | grep -v "party -" | cut -c12-240
echo TEST-DONE
