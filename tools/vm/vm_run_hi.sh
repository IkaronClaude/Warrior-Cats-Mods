# launch the game offscreen on the VM, into the world; then wait $1 seconds in it
G="/z/Warrior Cats Clans of the Forest/Wrc/Binaries/Win64"; R=/c/Projects/WarriorCats-Mod; L="$G/ue4ss/UE4SS.log"; T="$G/ue4ss/Mods/WaCaTest/Scripts/main.lua"
taskkill //IM Wrc-Win64-Shipping-NoStub.exe //F >/dev/null 2>&1; sleep 2
powershell -NoProfile -Command "Start-Process -FilePath '$(cygpath -w "$G")\Wrc-Win64-Shipping-NoStub.exe' -ArgumentList '-dx12','-warp','-wacaoffscreen','-windowed','-ResX=960','-ResY=540' -WorkingDirectory '$(cygpath -w "$G")'"
sleep 8
# (no "nudge" reloads of the harness any more - a hot reload during the boot can deadlock UE4SS, 2026-11-03; the log is
# read from its start, so a late splash is still found - just wait longer)
timeout 600 tail -n +1 -F "$L" 2>/dev/null | grep -q -m1 "screen shown WBP_GuiScreenSplash"
cd $R && python tools/vm_input.py key 0D
timeout 400 tail -n 0 -F "$L" 2>/dev/null | grep -m1 "screen shown WBP_GuiScreenSelectYourCat"
sleep 20; python tools/vm_input.py key 0D
timeout 400 tail -n +1 -F "$L" 2>/dev/null | grep -m1 "WBP_GuiHudGame"
sleep ${1:-60}
echo RUN-DONE
