#!/bin/sh
# VM test (2026-11-04): the native camera lookup by what the code does (camera.cpp, FunctionUsingWhere) still hooks the
# old build; the Bedding duty's two Interact spots (WaCa.InteractSpot) - E in the den takes the old moss, E out of
# camp buries it, each after the animation. Boots the game (boot_hi.sh deploys scripts + main.dll).
D=/c/Projects/WarriorCats-Mod/tools/vm; R=/c/Projects/WarriorCats-Mod
C="$LOCALAPPDATA/Wrc/Saved/wacatest_cmd.txt"; G="/z/Warrior Cats Clans of the Forest/Wrc/Binaries/Win64/ue4ss"
L="$G/UE4SS.log"; N="$G/Mods/WaCaCore/WaCaNative.log"
sh $D/boot_hi.sh > $D/boot_last.txt 2>&1
echo "== the camera"
grep -a "\[camera\]" "$N" | head -4
echo "== bedding"
m=$(wc -l < "$L")
echo 'Emit WaCaDutiesForce Bedding' > "$C"
sleep 15
line=$(tail -n +$m "$L" | grep -a -m1 "the old bedding - from the")
echo "$line" | cut -c12-260
inside=$(echo "$line" | sed -E 's/.*inside at (-?[0-9]+) (-?[0-9]+) (-?[0-9]+).*/\1 \2 \3/')
out=$(echo "$line" | sed -E 's/.*out of camp at (-?[0-9]+) (-?[0-9]+).*/\1 \2/')
set -- $inside; echo "Lua pc().Pawn:K2_SetActorLocation({ X = $1, Y = $2, Z = $3 + 60 }, false, {}, true); log(\"PROBE in the den\")" > "$C"
sleep 10
cd $R && python tools/vm_input.py key 45
sleep 12
set -- $out; echo "Lua local p = pc().Pawn:K2_GetActorLocation(); pc().Pawn:K2_SetActorLocation({ X = $1, Y = $2, Z = p.Z + 300 }, false, {}, true); log(\"PROBE at the spot out of camp\")" > "$C"
sleep 12
python tools/vm_input.py key 45
sleep 15
tail -n +$m "$L" | grep -a "PROBE\|bedding\|Bury\|interact spot\|task\|duty" | grep -v "party -" | cut -c12-220 | head -30
echo TEST-DONE
