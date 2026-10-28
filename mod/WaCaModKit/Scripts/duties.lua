-- The clan's day (tickets.md 15): every morning your cat gets the day's duties from the clan's needs - hunt when the
-- fresh-kill pile is low (the save's GameplayProgression.FreshKill.Value, 0-100), patrol the border - and at the
-- day's end the duties done raise your standing in the clan, the ones skipped lower it (kept with the save; the
-- pacing ticket 14 reads it). Below MaxRank only (the deputy hands duties out, not gets them). config/duties.ini.
--   Hunt: catch N prey (the HuntCaught event - hunting.ini [Chance] On).
--   Patrol: check N border points - spots in the generators' areas 20-90 m away, marked like StarClan's guidance
--     (a POI hint area: the trail in sense mode + scent puffs at each sense pulse); a point is checked when your cat
--     comes within Reach of it (looked at every in-game hour and every sense pulse).
-- Cards (the centre message) say the duties at dawn, each one done, and the day's verdict at its end.
local Duties = {}

local WaCa, log, DayNight
local cfg = { on = false, maxRank = "Deputy", huntMin = 1, huntMax = 3, pileLow = 50, patrolPoints = 2,
              reach = 800, minDist = 2000, maxDist = 9000, standingDone = 2, standingMissed = -1, seconds = 7 }
local CARD = "/Game/Art/UXD/Blueprints/Popups/WBP_GuiPopupCenterMessage.WBP_GuiPopupCenterMessage_C"
local HINT = "/Game/Gameplay/Blueprints/WorldElements/POIHintArea/BP_POI_HintArea_Quest.BP_POI_HintArea_Quest_C"
local plan                        -- day scripts' override for the next duties: { hunt = n, patrol = n }
local today                       -- { day, hunt = { need, got }, patrol = { points = { {X,Y,Z, done, marker} } } }
local standing = 0
local restoredFor
local ready = false

local function pc()
    for _, c in ipairs(FindAllOf("SwtPlayerController") or {}) do
        if c:IsValid() and c.Player then return c end
    end
end

local function card(text)
    pcall(function()
        local controller = pc()
        local w = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary"):Create(controller, WaCa.LoadAsset(CARD), controller)
        w:AddToViewport(60)
        w.mcGuiTextInfo:SetText(FText(text))
        local name = (w:GetFullName():gsub("^%S+ ", ""))
        ExecuteInGameThreadWithDelay(math.floor(cfg.seconds * 1000), function()
            local o = StaticFindObject(name)
            if o and o:IsValid() then o:RemoveFromParent() end
        end)
    end)
end

local function rankAllows()
    local ranks = {}
    pcall(function()
        StaticFindObject("/Script/SwtQuest.ECharacterRank"):ForEachName(function(n, v) ranks[n:ToString():gsub("^.*::", "")] = v end)
    end)
    local p = WaCa.GameProgress()
    local rank = p and tonumber(p.Rank)
    return not (rank and ranks[cfg.maxRank] and rank >= ranks[cfg.maxRank])
end

-- spots for the patrol: random points in the areas of the generators 20-90 m away (where the clan's prey and
-- threats are - the border of what your cat knows), each marked with the game's quest hint (sense-mode trail)
local function patrolPoints(n)
    local p = pc() and pc().Pawn
    if not p then return {} end
    local at = p:K2_GetActorLocation()
    local candidates = {}
    for _, g in ipairs(FindAllOf("BP_Enemy_Generator_C") or {}) do
        pcall(function()
            local q = g:K2_GetActorLocation()
            local d = math.sqrt((q.X - at.X) ^ 2 + (q.Y - at.Y) ^ 2)
            if d >= cfg.minDist and d <= cfg.maxDist then table.insert(candidates, g) end
        end)
    end
    local out = {}
    local class = WaCa.LoadAsset(HINT)
    for _ = 1, math.min(n, #candidates) do
        local g = table.remove(candidates, math.random(#candidates))
        local ok = pcall(function()
            local area = g.AreaComponent
            local c, e = area:K2_GetComponentLocation(), area:GetScaledBoxExtent()
            local point = { X = c.X + (math.random() * 2 - 1) * e.X * 0.5, Y = c.Y + (math.random() * 2 - 1) * e.Y * 0.5, Z = c.Z }
            local marker = class and p:GetWorld():SpawnActor(class, point, { pitch = 0, Yaw = 0, Roll = 0 })
            if marker and marker:IsValid() then
                pcall(function() marker.SenseTrackedComponent.bTrackingEnabled = true end)
                pcall(function() marker:OnQuestTracked(true, nil) end)
                point.marker = (marker:GetFullName():gsub("^%S+ ", ""))
            end
            table.insert(out, point)
        end)
        if not ok then log("duties: a patrol point couldn't be placed") end
    end
    return out
end

local function removeMarker(point)
    local m = point.marker and StaticFindObject(point.marker)
    if m and m:IsValid() then pcall(function() m:K2_DestroyActor() end) end
    point.marker = nil
end

local function summary()
    local parts = {}
    if today.hunt then table.insert(parts, string.format("hunt %d prey (%d)", today.hunt.need, today.hunt.got)) end
    if today.patrol then
        local done = 0
        for _, pt in ipairs(today.patrol) do if pt.done then done = done + 1 end end
        table.insert(parts, string.format("patrol %d border points (%d)", #today.patrol, done))
    end
    return table.concat(parts, ", ")
end

-- the morning: the clan's needs -> today's duties
local function assign(day)
    if not rankAllows() then
        today = nil
        log("duties: your cat hands out the duties now (rank %s or above) - none for you", cfg.maxRank)
        return
    end
    local pile = 100
    pcall(function() pile = tonumber(WaCa.GameProgress().FreshKill.Value) or 100 end)
    today = { day = day }
    local hunt = pile < cfg.pileLow and cfg.huntMax or math.random(cfg.huntMin, cfg.huntMax)
    local patrol = cfg.patrolPoints
    if plan then hunt, patrol = plan.hunt or hunt, plan.patrol or patrol end
    if hunt > 0 then today.hunt = { need = hunt, got = 0 } end
    if patrol > 0 then today.patrol = patrolPoints(patrol) end
    if not today.hunt and not today.patrol then
        log("duties: day %d - no duties today", day)
        today = nil
        return
    end
    log("duties: day %d (fresh-kill pile %d) - %s", day, pile, summary())
    card(string.format("Today's duties: %s.", summary()))
end

local function checkPatrol()
    if not (today and today.patrol) then return end
    local p = pc() and pc().Pawn
    if not p then return end
    local at = p:K2_GetActorLocation()
    for i, pt in ipairs(today.patrol) do
        if not pt.done and math.sqrt((pt.X - at.X) ^ 2 + (pt.Y - at.Y) ^ 2) <= cfg.reach then
            pt.done = true
            removeMarker(pt)
            log("duties: border point %d checked", i)
            card(string.format("Border point checked - %s.", summary()))
        end
    end
end

-- the day's end: done duties raise standing, missed ones lower it
local function verdict()
    if not today then return end
    local done, missed = 0, 0
    if today.hunt then if today.hunt.got >= today.hunt.need then done = done + 1 else missed = missed + 1 end end
    if today.patrol then
        local all = true
        for _, pt in ipairs(today.patrol) do
            if not pt.done then all = false end
            removeMarker(pt)
        end
        if all then done = done + 1 else missed = missed + 1 end
    end
    local change = done * cfg.standingDone + missed * cfg.standingMissed
    standing = standing + change
    log("duties: day %d over - %d done, %d missed: standing %+d = %d", today.day, done, missed, change, standing)
    card(string.format("The day is over: %d of %d duties done. Your standing in the clan: %d.", done, done + missed, standing))
    WaCa.Emit("DutiesJudged", today.day, done, missed, standing)
    today = nil
end

function Duties.Standing() return standing end
-- day scripts (days.lua): the next duties' numbers (nil = the clan's needs decide)
function Duties.Plan(hunt, patrol) plan = (hunt or patrol) and { hunt = hunt, patrol = patrol } or nil end
function Duties.Today() return today end

local function sidecar() return WaCa.SlotFile("WaCaDuties") end

function Duties.Init(c)
    WaCa, log, DayNight = c.WaCa, c.log, c.DayNight
    local ini = WaCa.ReadIni(c.modDir .. "/config/duties.ini") or {}
    local d = ini["Duties"] or {}
    cfg.on = (d.On or "0") == "1"
    cfg.maxRank = (d.MaxRank or "") ~= "" and d.MaxRank or cfg.maxRank
    local h = ini["Hunt"] or {}
    cfg.huntMin = math.max(0, math.floor(tonumber(h.Min or "") or cfg.huntMin))
    cfg.huntMax = math.max(cfg.huntMin, math.floor(tonumber(h.Max or "") or cfg.huntMax))
    cfg.pileLow = tonumber(h.PileLow or "") or cfg.pileLow
    local p = ini["Patrol"] or {}
    cfg.patrolPoints = math.max(0, math.floor(tonumber(p.Points or "") or cfg.patrolPoints))
    cfg.reach = tonumber(p.Reach or "") or cfg.reach
    cfg.minDist = tonumber(p.MinDistance or "") or cfg.minDist
    cfg.maxDist = tonumber(p.MaxDistance or "") or cfg.maxDist
    local s = ini["Standing"] or {}
    cfg.standingDone = tonumber(s.Done or "") or cfg.standingDone
    cfg.standingMissed = tonumber(s.Missed or "") or cfg.standingMissed
    log("duties: %s", cfg.on and "on" or "off")
    if not cfg.on then return end
    -- the first world of a session: today's duties after the world has streamed in (spawning markers earlier crashed)
    local armed = false
    WaCa.On("ScreenShown", function(screen)
        if armed or not screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then return end
        armed = true
        ExecuteInGameThreadWithDelay(30000, function()
            ready = true
            if not today then assign(DayNight.Day() or 1) end
        end)
    end)
    WaCa.On("DayEnded", function() verdict() end)
    WaCa.On("DayStarted", function(day) if ready then assign(day) end end)
    WaCa.On("HourChanged", function() checkPatrol() end)
    WaCa.Watch("BlendProgress", "/Script/SwtAdventure.SwtAdventureExplorationSenseComponent", "WaCaDutySense", "post")
    WaCa.On("WaCaDutySense", function() checkPatrol() end)
    WaCa.On("HuntCaught", function()
        if today and today.hunt then
            today.hunt.got = today.hunt.got + 1
            log("duties: prey caught (%d of %d)", today.hunt.got, today.hunt.need)
            if today.hunt.got == today.hunt.need then card(string.format("Hunting duty done - %s.", summary())) end
        end
    end)
    -- standing lives with the save (written when the game saves)
    WaCa.On("GameSaved", function()
        local slot = WaCa.CurrentSlot()
        if slot and restoredFor ~= slot then
            restoredFor = slot
            local st = (WaCa.ReadIni(sidecar() or "") or {})["Standing"] or {}
            standing = tonumber(st.Value or "") or 0
        end
        local path = sidecar()
        if path then
            WaCa.WriteIni(path, { Standing = { Value = tostring(standing), __order = { "Value" } }, __order = { "Standing" } },
                "; WaCa ModKit - your cat's standing in the clan (duties.ini)")
        end
    end)
end

return Duties
