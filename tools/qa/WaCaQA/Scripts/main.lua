-- WaCaQA - a TEST-ONLY helper for the operator's QA run (QA-RUNBOOK.md): keys that send the WaCa events a player can't
-- trigger by hand (a story pack's Event: scenes, a duty now, a time skip, a cutscene, the wind). Not a release mod.
-- config/qa.ini [Keys]: <Key> = <Event> [<argument> ...]  (e.g. F5 = ClanEvent ScentLesson). Each press logs
-- "[WaCaQA] sent ..." to UE4SS.log and shows it on screen.
local hasCore, WaCa = pcall(require, "WaCa")
local function log(fmt, ...) print(string.format("[WaCaQA] " .. fmt .. "\n", ...)) end
if not (hasCore and WaCaNative_Command) then log("WaCa Core is missing") return end

local modDir = debug.getinfo(1, "S").source:match("^@(.+)[/\\]Scripts[/\\]") or "."
local ini = WaCa.ReadIni(modDir .. "/config/qa.ini") or {}
local keys = {}
for _, k in ipairs((ini["Keys"] or {}).__order or {}) do
    local parts = {}
    for w in tostring(ini["Keys"][k]):gmatch("%S+") do parts[#parts + 1] = tonumber(w) or w end
    if #parts > 0 then keys[k] = parts end
end
local n = 0
for _ in pairs(keys) do n = n + 1 end
log("%d key(s) from qa.ini", n)

WaCa.On("KeyDown", function(_, name)
    local p = keys[tostring(name)]
    if not p or WaCa.InMenu() then return end
    local text = table.concat(p, " ", 1)
    log("sent %s (%s)", text, tostring(name))
    WaCa.Emit("ShowLine", "QA: " .. text)
    WaCa.Emit(table.unpack(p))
end)

WaCa.Ready()
