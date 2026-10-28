-- The story as days (tickets.md 25): the story is data - config/days.ini, one [Day.N] per story day. A story day sets
-- its scenes per phase (Morning / Afternoon / Evening, at the [Days] phase hours: a card and / or one of the game's
-- conversations - events.lua plays them), the day's duties (duties.lua; instead of the clan's needs), its season and
-- weather chances (weather.lua), and the condition to move on (Advance). Until that holds the story day REPEATS:
-- same setup, minus the scenes already seen. Like = M copies day M's keys (only the ones it doesn't set itself).
-- The story day lives with the save (a sidecar). Needs the day / night cycle (its DayStarted / HourChanged).
--   Advance = Always | Duties (all of the day's duties done) | Rank:<Name> (the cat's rank reached, e.g. Rank:Warrior)
--   Morning / Afternoon / Evening = Card: <text>  or  Dialogue: <SequenceDialogueId>  (both: two lines, Morning2 ...)
local Days = {}

local WaCa, log, DayNight, Weather, Duties, Events
local cfg = { on = false, phases = { Morning = 7, Afternoon = 13, Evening = 19 }, days = {} }
local story = 1                    -- the story day the save is on
local seen = {}                    -- scenes played on this story day (repeats skip them): "Morning1" = true
local lastJudged                   -- the last DutiesJudged result: { done, missed }
local restoredFor

-- a key of story day n, following Like chains
local function get(n, key, depth)
    local d = cfg.days[n]
    if not d or (depth or 0) > 20 then return nil end
    if d[key] == "none" then return nil end           -- "none": nothing, not even what the Like day sets
    if d[key] ~= nil and d[key] ~= "" then return d[key] end
    if d.Like then return get(tonumber(d.Like), key, (depth or 0) + 1) end
    return nil
end

local function scenesOf(n, phase)
    local out = {}
    for _, suffix in ipairs({ "", "1", "2", "3", "4" }) do
        local v = get(n, phase .. suffix)
        if v then
            local kind, text = v:match("^%s*(%a+)%s*:%s*(.+)$")
            if kind and (kind == "Card" or kind == "Dialogue") then
                table.insert(out, { key = phase .. suffix, card = kind == "Card" and text or nil, dialogue = kind == "Dialogue" and text or nil })
            end
        end
    end
    return out
end

-- the day's setup: duties, season / weather
local function setUp(why)
    if not cfg.days[story] then
        log("days: story day %d has no [Day.%d] - the clan's needs decide", story, story)
        if Duties then Duties.Plan(nil, nil) end
        return
    end
    local hunt, patrol = tonumber(get(story, "Hunt") or ""), tonumber(get(story, "Patrol") or "")
    if Duties then Duties.Plan(hunt, patrol) end
    if Weather then Weather.SetDay(get(story, "Season"), get(story, "Weather")) end
    log("days: story day %d (%s) - duties hunt %s / patrol %s, season %s, weather %s, advance on %s", story, why,
        tostring(hunt or "by needs"), tostring(patrol or "by needs"), tostring(get(story, "Season") or "by days"),
        tostring(get(story, "Weather") or "the season's"), tostring(get(story, "Advance") or "Always"))
end

local function rankValue(name)
    local v
    pcall(function()
        StaticFindObject("/Script/SwtQuest.ECharacterRank"):ForEachName(function(n, val)
            if n:ToString():gsub("^.*::", "") == name then v = val end
        end)
    end)
    return v
end

-- did the story day's condition hold?
local function advances()
    local a = get(story, "Advance") or "Always"
    if a == "Always" then return true end
    if a == "Duties" then return lastJudged and lastJudged.missed == 0 and lastJudged.done > 0 end
    local rank = a:match("^Rank:%s*(%a+)$")
    if rank then
        local p = WaCa.GameProgress()
        return p and rankValue(rank) and tonumber(p.Rank) and tonumber(p.Rank) >= rankValue(rank) or false
    end
    return false
end

function Days.Story() return story end

local function sidecar() return WaCa.SlotFile("WaCaDays") end

function Days.Init(c)
    WaCa, log, DayNight = c.WaCa, c.log, c.DayNight
    Weather, Duties, Events = c.Weather, c.Duties, c.Events
    local ini = WaCa.ReadIni(c.modDir .. "/config/days.ini") or {}
    local d = ini["Days"] or {}
    cfg.on = (d.On or "0") == "1"
    for name in pairs(cfg.phases) do cfg.phases[name] = tonumber(d[name .. "Hour"] or "") or cfg.phases[name] end
    local n = 0
    for section, sec in pairs(ini) do
        local num = tonumber(section:match("^Day%.(%d+)$") or "")
        if num then cfg.days[num] = sec n = n + 1 end
    end
    log("days: %s (%d story days)", cfg.on and "on" or "off", n)
    if not cfg.on then return end
    local started = false
    WaCa.On("ScreenShown", function(screen)
        if started or not screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then return end
        started = true
        setUp("the session starts")
    end)
    WaCa.On("DutiesJudged", function(_, done, missed) lastJudged = { done = done, missed = missed } end)
    -- (registered before duties / weather react to the same DayStarted - main.lua inits days first)
    WaCa.On("DayStarted", function()
        if advances() then
            story = story + 1
            seen = {}
            log("days: on to story day %d", story)
        else
            log("days: story day %d repeats (%s not met)", story, get(story, "Advance") or "?")
        end
        lastJudged = nil
        setUp("a new day")
    end)
    WaCa.On("HourChanged", function(hour)
        for phase, at in pairs(cfg.phases) do
            if hour == at then
                for _, scene in ipairs(scenesOf(story, phase)) do
                    if not seen[scene.key] and Events then
                        seen[scene.key] = true
                        log("days: story day %d, %s: %s", story, scene.key, scene.card or scene.dialogue)
                        Events.Play({ card = scene.card, dialogue = scene.dialogue, seconds = 8 })
                    end
                end
            end
        end
    end)
    WaCa.On("GameSaved", function()
        local slot = WaCa.CurrentSlot()
        if slot and restoredFor ~= slot then
            restoredFor = slot
            local s = (WaCa.ReadIni(sidecar() or "") or {})["Story"] or {}
            if tonumber(s.Day or "") then
                story = math.floor(tonumber(s.Day))
                seen = {}
                for key in (s.Seen or ""):gmatch("[^,%s]+") do seen[key] = true end
                setUp("as saved")
            end
        end
        local path = sidecar()
        if path then
            local keys = {}
            for k in pairs(seen) do table.insert(keys, k) end
            WaCa.WriteIni(path, { Story = { Day = tostring(story), Seen = table.concat(keys, ","), __order = { "Day", "Seen" } },
                __order = { "Story" } }, "; WaCa ModKit - the story day this save is on (days.ini)")
        end
    end)
end

return Days
