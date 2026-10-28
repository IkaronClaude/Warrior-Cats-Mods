-- Clan cats say more than one thing (tickets.md 11). The game's chatter is its "filler" monologue: one line per cat
-- role, story chapter and tone (QST_Story.Monologue.Filler.<Role>.<Chapter>.<n>.Context.<n>.<Tone> - 755 groups,
-- each exactly ONE line - so every cat repeats itself). config/lines.ini adds pools of lines per role (or All) and
-- time of day; every in-game hour each filler line is, by chance (Share), one of its pool's lines for the hour, or
-- the game's own again. The text itself is swapped in the game's string table (WaCa.SetText) - the game picks the
-- key as always, so story lines keep their place and the change is just more to say. Needs the day / night cycle
-- for the time of day (without it: Day lines, rolled once per world).
local Lines = {}

local WaCa, log, DayNight
local cfg = { on = false, share = 0.5, pools = {} }   -- pools[role][period] = { lines }
local filler                                          -- { key, role } for every filler key
local original = {}                                   -- key -> the game's own text

local PERIODS = { { "Night", 0 }, { "Morning", 5 }, { "Day", 11 }, { "Evening", 17 }, { "Night", 21 } }
local function period(hour)
    local name = "Night"
    for _, p in ipairs(PERIODS) do if hour >= p[2] then name = p[1] end end
    return name
end

local function fillerKeys()
    if filler then return filler end
    filler = {}
    local ok, keys = pcall(function()
        return StaticFindObject("/Script/Engine.Default__KismetStringTableLibrary"):GetKeysFromStringTable(FName("SwtStrings"))
    end)
    if not ok or not keys then return filler end
    for i = 1, #keys do
        local k = keys[i]
        local key = type(k) == "string" and k or (k.ToString and k:ToString()) or (k.get and k:get():ToString()) or tostring(k)
        local role = key:match("^QST_Story%.Monologue%.Filler%.([^.]+)%.")
        if role then table.insert(filler, { key = key, role = role }) end
    end
    return filler
end

-- this hour's lines for a role: its own pool + All's, for the period, plus their "Any" lines
local function poolFor(role, p)
    local out = {}
    for _, who in ipairs({ role, "All" }) do
        local r = cfg.pools[who]
        if r then
            for _, l in ipairs(r[p] or {}) do table.insert(out, l) end
            for _, l in ipairs(r.Any or {}) do table.insert(out, l) end
        end
    end
    return out
end

local function roll(hour)
    local p = period(hour or 12)
    local swapped = 0
    for _, f in ipairs(fillerKeys()) do
        local pool = poolFor(f.role, p)
        if #pool > 0 then
            original[f.key] = original[f.key] or WaCa.GetText(f.key)
            local text = (math.random() < cfg.share) and pool[math.random(#pool)] or original[f.key]
            if WaCa.SetText(f.key, text) and text ~= original[f.key] then swapped = swapped + 1 end
        end
    end
    log("lines: %s - %d clan cat lines changed for now", p, swapped)
end

function Lines.Init(c)
    WaCa, log, DayNight = c.WaCa, c.log, c.DayNight
    local ini = WaCa.ReadIni(c.modDir .. "/config/lines.ini") or {}
    local l = ini["Lines"] or {}
    cfg.on = (l.On or "0") == "1"
    cfg.share = math.max(0, math.min(1, tonumber(l.Share or "") or cfg.share))
    local n = 0
    for section, sec in pairs(ini) do
        local role = section:match("^Lines%.(.+)$")
        if role then
            cfg.pools[role] = {}
            for _, key in ipairs(sec.__order or {}) do
                local p = key:match("^(%a+)%d*$")          -- Morning1, Morning2, Night, Any3 ...
                if p and sec[key] ~= "" then
                    cfg.pools[role][p] = cfg.pools[role][p] or {}
                    table.insert(cfg.pools[role][p], sec[key])
                    n = n + 1
                end
            end
        end
    end
    log("lines: %s (%d extra lines)", cfg.on and "on" or "off", n)
    if not cfg.on or n == 0 then return end
    WaCa.On("HourChanged", function(hour) roll(hour) end)
    local rolled = false
    WaCa.On("ScreenShown", function(screen)
        if rolled or not screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then return end
        rolled = true
        roll(DayNight.Hour())
    end)
end

return Lines
