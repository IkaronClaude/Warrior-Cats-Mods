#!/bin/sh
# VM probe (2026-11-04, game already in the world): reload Clan Life with the debounced InteractSpot; the report mark
# (map.marks); a kit talk with the new lines.ini; the HUD objective panel's widget names (its icon); the save's quest
# progression fields with "Mentor" in them.
R=/c/Projects/WarriorCats-Mod
C="$LOCALAPPDATA/Wrc/Saved/wacatest_cmd.txt"; M="/z/Warrior Cats Clans of the Forest/Wrc/Binaries/Win64/ue4ss/Mods"
L="$M/../UE4SS.log"
send() { echo "$1" > "$C"; for i in $(seq 1 60); do [ -f "$C" ] || return 0; sleep 1; done; }
m=$(wc -l < "$L")
cp /c/Projects/WaCa-Core/Mods/shared/WaCa/WaCa.lua "$M/shared/WaCa/WaCa.lua"
touch "$M/WaCaClanLife/Scripts/main.lua"
for i in $(seq 1 90); do tail -n +$m "$L" | grep -a -q "murmurs: on" && break; sleep 2; done
sleep 30
send 'Lua local t = WaCa.Latest("map.marks") or {}; local out = {}; for k, v in pairs(t) do out[#out+1] = k .. "=" .. tostring(v) end; log("PROBE marks: %s", table.concat(out, " | "))'
send 'Lua local k; for _, c in ipairs(WaCa.Cats and WaCa.Cats() or {}) do if c.name and c.name:find("kit$") and c.actor then k = c break end end; if k then local q = k.actor:K2_GetActorLocation(); pc().Pawn:K2_SetActorLocation({ X = q.X + 120, Y = q.Y, Z = q.Z + 80 }, false, {}, true); log("PROBE beside %s", k.name) end'
sleep 8
cd $R && python tools/vm_input.py key 45
sleep 15
send 'Lua local out = {}; for _, w in ipairs(FindAllOf("WBP_GuiHudCurrentObjective_C") or {}) do if w:IsValid() then local names = {}; w.WidgetTree:ForEachWidget(function(c) local n = c:GetFName():ToString(); local cls = c:GetClass():GetFName():ToString(); if cls == "Image" then local tex = "?"; pcall(function() tex = c.Brush.ResourceObject:GetFName():ToString() end); names[#names+1] = n .. "<" .. tex .. ">" end end); out[#out+1] = w:GetFName():ToString() .. ": " .. table.concat(names, ", ") end end; log("PROBE objective images: %s", table.concat(out, " || "))'
send 'Lua local ch = WaCa.SaveCharacter(); local q = ch and ch.QuestProgression; local hits = {}; local function walk(t, path, depth) if depth > 6 or type(t) ~= "table" then return end for k, v in pairs(t) do local p = path .. "." .. tostring(k); if tostring(k):lower():find("mentor") or (type(v) == "string" and v:lower():find("mentor")) then hits[#hits+1] = p .. "=" .. tostring(v) end walk(v, p, depth + 1) end end; walk(ch or {}, "char", 0); log("PROBE mentor fields (%d): %s", #hits, table.concat(hits, " | "):sub(1, 1500))'
sleep 5
tail -n +$m "$L" | grep -a "PROBE\|kits:\|interact spot\|CMD failed" | cut -c12-1600
echo PROBE-DONE
