#!/bin/sh
# VM test (2026-11-05, QA run): the map's hover name with the mouse RESTING on a mark (must not flip to "Player") and
# after PANNING the map away (must clear). Needs a booted game in the world, WaCaQA installed (NumPad 5 = Water duty).
# The VM's pause screen opens by itself at times (focus) - a real click on Resume (138,173 at 960x540) closes it.
cd /c/Projects/WarriorCats-Mod
L="/z/Warrior Cats Clans of the Forest/Wrc/Binaries/Win64/ue4ss/UE4SS.log"
C="$LOCALAPPDATA/Wrc/Saved/wacatest_cmd.txt"
inMenu() {
  local m=$(wc -l < "$L"); echo 'Lua log("PROBE menu %s", tostring(WaCa.InMenu()))' > "$C"
  timeout 30 sh -c "until tail -n +$m \"$L\" | grep -a -q 'PROBE menu'; do sleep 2; done"
  tail -n +$m "$L" | grep -a "PROBE menu" | tail -1 | grep -q "true"
}
resume() { for i in 1 2 3; do inMenu || return 0; python tools/vm_input.py realclick 138 173 >/dev/null; sleep 10; done; }
shot() { local m=$(wc -l < "$L"); echo Shot > "$C"; timeout 40 sh -c "until tail -n +$m \"$L\" | grep -a -q 'screenshot taken'; do sleep 2; done"; sleep 3
  cp "$LOCALAPPDATA/Wrc/Saved/Screenshots/Windows/$(ls -t "$LOCALAPPDATA/Wrc/Saved/Screenshots/Windows/" | head -1)" "$1"; }
timeout 600 sh -c "until grep -a -q 'duties: day [0-9]*, ' \"$L\"; do sleep 5; done"
sleep 10; resume
m=$(wc -l < "$L"); python tools/vm_input.py key 65 >/dev/null
timeout 60 sh -c "until tail -n +$m \"$L\" | grep -a -q 'soak moss at\|can.t give'; do sleep 3; done"
tail -n +$m "$L" | grep -a "soak moss at\|can't give" | cut -c12-120
sleep 12; resume
m=$(wc -l < "$L"); python tools/vm_input.py key 4D >/dev/null
timeout 60 sh -c "until tail -n +$m \"$L\" | grep -a -q 'screen shown WBP_GuiPopupWorldMap'; do sleep 2; done"
sleep 30; shot /c/Users/Claude/.claude/jobs/ca5d3294/tmp/hover_map.png
echo "MAP-OPEN"
