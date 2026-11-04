#!/bin/sh
# VM probe (2026-11-04): boot; a patrol duty; the map open; the textures of each map icon that has a "Pulse" texture
# (the duty points' quest-hint icons - their leaf is the HUD duty icon to use), walked the way WaCa Keybinds does it
# (the map's icon canvas only - a walk over every Image in the game crashed it: VM 2026-11-04 22:19). Then the map
# closed and a screenshot of the HUD panel.
D=/c/Projects/WarriorCats-Mod/tools/vm; R=/c/Projects/WarriorCats-Mod
C="$LOCALAPPDATA/Wrc/Saved/wacatest_cmd.txt"; L="/z/Warrior Cats Clans of the Forest/Wrc/Binaries/Win64/ue4ss/UE4SS.log"
send() { echo "$1" > "$C"; for i in $(seq 1 60); do [ -f "$C" ] || return 0; sleep 1; done; }
sh $D/boot_hi.sh > $D/boot_last.txt 2>&1
m=$(wc -l < "$L")
send 'Emit WaCaDutiesForce Patrol'
sleep 20
cd $R && python tools/vm_input.py key 4D
sleep 15
send 'Lua local img = StaticFindObject("/Script/UMG.Image"); local out = {}; local m; for _, w in ipairs(FindAllOf("GuiPopupWorldMap") or {}) do if w:IsValid() and w:IsInViewport() then m = w end end; if not m then log("PROBE no map") return end; local c = m.CanvasGenericIcons; for i = 0, c:GetChildrenCount() - 1 do local icon = c:GetChildAt(i); local texs = {}; local function walk(x, d) if not (x and x:IsValid()) or d > 6 then return end; if x:IsA(img) then pcall(function() local r = x.Brush.ResourceObject; if r and r:IsValid() then texs[#texs+1] = r:GetFullName():gsub("^%S+ ", "") end end) end; local ok, n = pcall(function() return x:GetChildrenCount() end); if ok and n then for j = 0, n - 1 do walk(x:GetChildAt(j), d + 1) end else pcall(function() walk(x.WidgetTree.RootWidget, d + 1) end) end end; walk(icon, 0); local all = table.concat(texs, ","); if all:find("Pulse") then out[#out+1] = icon:GetFName():ToString() .. ": " .. all end end; log("PROBE pulse icons (%d): %s", #out, table.concat(out, " || "):sub(1, 2500))'
sleep 5
python tools/vm_input.py key 1B
sleep 10
send 'Shot'
sleep 15
tail -n +$m "$L" | grep -a "PROBE\|CMD failed\|duties: day" | cut -c12-2700
echo PROBE-DONE
