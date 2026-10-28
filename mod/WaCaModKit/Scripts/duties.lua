-- The clan's day (tickets.md 15): every morning your cat gets the day's duties from the clan's needs - hunt when the
-- fresh-kill pile is low (the save's GameplayProgression.FreshKill.Value, 0-100), patrol the border - and at the
-- day's end the duties done raise your standing in the clan, the ones skipped lower it (kept with the save; the
-- pacing ticket 14 reads it). Below MaxRank only (the deputy hands duties out, not gets them). config/duties.ini.
--   Hunt: catch N prey (the HuntCaught event - hunting.ini [Chance] On).
--   Train (tickets.md 6): a sparring fight with the clan's move teacher (the story cat ...WarriorMoveLearn - the game
--     has no mentor role; else the nearest clanmate), for cats up to [Train] MaxRank: go to them, the fight starts
--     (the game's own combat, the TrainingGrounds encounter), win or lose it counts and the bond with them grows.
--   Patrol: check N border points - spots in the generators' areas 20-90 m away, marked like StarClan's guidance
--     (a POI hint area: the trail in sense mode + scent puffs at each sense pulse); a point is checked when your cat
--     comes within Reach of it (looked at every in-game hour and every sense pulse).
-- Cards (the centre message) say the duties at dawn, each one done, and the day's verdict at its end.
local Duties = {}

local WaCa, log, DayNight
local cfg = { on = false, maxRank = "Deputy", huntMin = 1, huntMax = 3, pileLow = 50, patrolPoints = 2, pileReward = 10,
              companions = 2, companionRadius = 3000,
              train = true, trainMaxRank = "Apprentice", trainBond = 2,
              trainTag = "Gameplay.Combat.Generator.Fixed.TrainingGrounds",
              huntingGround = true,
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

local function ranks()
    local out = {}
    pcall(function()
        StaticFindObject("/Script/SwtQuest.ECharacterRank"):ForEachName(function(n, v) out[n:ToString():gsub("^.*::", "")] = v end)
    end)
    local p = WaCa.GameProgress()
    return out, p and tonumber(p.Rank)
end

local function rankAllows()
    local r, rank = ranks()
    return not (rank and r[cfg.maxRank] and rank >= r[cfg.maxRank])
end

-- --- training: a sparring fight ---

local roleNames
local function roleName(v)
    if not roleNames then
        roleNames = {}
        pcall(function()
            StaticFindObject("/Script/SwtQuest.ENarrativeRole"):ForEachName(function(n, x) roleNames[x] = n:ToString():gsub("^.*::", "") end)
        end)
    end
    return roleNames[v]
end

-- the sparring partner: the clan's move teacher (a story cat), else the nearest clanmate - its object path, its story
-- role (for the bond; nil for a plain clanmate) and a name for the cards
local function trainingPartner()
    local p = pc() and pc().Pawn
    if not p then return nil end
    for _, a in ipairs(FindAllOf("QuestBaseActor") or {}) do
        local found
        pcall(function()
            local name = a:IsValid() and not a.bHidden and a.narrativeRole and roleName(a.narrativeRole)
            if name and name:find("WarriorMoveLearn$") then
                found = { path = (a:GetFullName():gsub("^%S+ ", "")), role = a.narrativeRole, who = "the clan's move teacher" }
            end
        end)
        if found then return found end
    end
    local at = p:K2_GetActorLocation()
    local best, bd
    for _, c in ipairs(FindAllOf("BP_Exploration_Character_Base_C") or {}) do
        pcall(function()
            if c:IsValid() and c.CharacterType == 1 and c:GetAddress() ~= p:GetAddress() then
                local q = c:K2_GetActorLocation()
                local d = (q.X - at.X) ^ 2 + (q.Y - at.Y) ^ 2
                if not bd or d < bd then best, bd = c, d end
            end
        end)
    end
    return best and { path = (best:GetFullName():gsub("^%S+ ", "")), who = "a clanmate" } or nil
end

-- the fight, the game's own way: its combat boxes start one when the player's character overlaps them - the handler
-- (SwtAdventureCombatBoxComponent::OnBeginOverlap, exe 0x1417E1370) checks the actor is player-controlled, the
-- component is its capsule and the box's OWNER is not that actor (an owner that is a character is the opponent), then
-- starts combat (0x141803400) with the box's CombatType + CombatTag. So: a box made inside the partner, TrainingGrounds
-- (5) + the TrainingGrounds encounter, its overlap called for the player. VM 2026-10-28: the turn-based fight opens.
local function startSpar(partner)
    local p = pc() and pc().Pawn
    local owner = StaticFindObject(partner.path)
    if not (p and owner and owner:IsValid()) then return false end
    local ok, err = pcall(function()
        local box = StaticConstructObject(StaticFindObject("/Script/SwtAdventure.SwtAdventureCombatBoxComponent"), owner,
            FName("WaCaSparBox"))
        box.CombatType = 5
        box.CombatTag = { TagName = FName(cfg.trainTag) }
        box:OnBeginOverlap(box, p, p.CapsuleComponent, 0, false, {})
    end)
    if not ok then log("duties: the sparring fight didn't start: %s", tostring(err)) end
    return ok
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

-- the hunting ground for the day's hunt (tickets.md 8, hunting missions): a prey creature about 20-90 m away, its
-- spot marked like the patrol points - the clan sends you where the prey is this season (preyworld.lua hides the
-- rest), the sense trail shows the way
local function huntingGround()
    local p = pc() and pc().Pawn
    if not p then return nil end
    local at = p:K2_GetActorLocation()
    local kinds = {}
    pcall(function()
        StaticFindObject("/Script/SwtQuest.ESwtQuestCharacterType"):ForEachName(function(n, v)
            kinds[v] = (n:ToString():gsub("^.*::", ""):gsub("^Weak", ""))
        end)
    end)
    local prey = { Mice = true, Squirrel = true, Rabbit = true, Bird = true }
    local found = {}
    for _, c in ipairs(FindAllOf("BP_Exploration_Character_Base_C") or {}) do
        pcall(function()
            if c:IsValid() and not c.bHidden and prey[kinds[c.CharacterType] or ""] then
                local q = c:K2_GetActorLocation()
                local d = math.sqrt((q.X - at.X) ^ 2 + (q.Y - at.Y) ^ 2)
                if d >= cfg.minDist and d <= cfg.maxDist then table.insert(found, { q, kinds[c.CharacterType] }) end
            end
        end)
    end
    if #found == 0 then return nil end
    local pick = found[math.random(#found)]
    local point = { X = pick[1].X, Y = pick[1].Y, Z = pick[1].Z, kind = pick[2] }
    pcall(function()
        local marker = p:GetWorld():SpawnActor(WaCa.LoadAsset(HINT), point, { pitch = 0, Yaw = 0, Roll = 0 })
        pcall(function() marker.SenseTrackedComponent.bTrackingEnabled = true end)
        pcall(function() marker:OnQuestTracked(true, nil) end)
        point.marker = (marker:GetFullName():gsub("^%S+ ", ""))
    end)
    return point
end

-- the clan's fresh-kill pile (its resource component, on the game state) - a finished hunt adds to it the game's way
local function pileComponent()
    for _, comp in ipairs(FindAllOf("SwtAdventureFreshKillPileComponent") or {}) do
        if comp:IsValid() then return comp end
    end
end

-- clanmates on the patrol (tickets.md 7): the nearest idle clan cats walk with you - their own AI paused, an AI
-- MoveToActor on your cat (it keeps following a moving goal) - until the patrol is done or the day ends
local function companionsJoin(n)
    local out = {}
    if n <= 0 then return out end
    local p = pc() and pc().Pawn
    if not p then return out end
    local at = p:K2_GetActorLocation()
    local catType
    pcall(function()
        StaticFindObject("/Script/SwtQuest.ESwtQuestCharacterType"):ForEachName(function(name, v)
            if name:ToString():gsub("^.*::", "") == "Cat" then catType = v end
        end)
    end)
    local near = {}
    for _, c in ipairs(FindAllOf("BP_Exploration_Character_Base_C") or {}) do
        pcall(function()
            if c:IsValid() and c.CharacterType == catType and not c.bHidden then
                local q = c:K2_GetActorLocation()
                local d = (q.X - at.X) ^ 2 + (q.Y - at.Y) ^ 2
                if d < cfg.companionRadius ^ 2 then table.insert(near, { c, d }) end
            end
        end)
    end
    table.sort(near, function(a, b) return a[2] < b[2] end)
    for i = 1, math.min(n, #near) do
        local cat = near[i][1]
        local ok = pcall(function()
            local ai = cat.Controller
            pcall(function() ai.BrainComponent:StopLogic("WaCa: on patrol") end)
            ai:MoveToActor(p, 250.0, true, true, false, nil, true)
        end)
        if ok then table.insert(out, (cat:GetFullName():gsub("^%S+ ", ""))) end
    end
    if #out > 0 then log("duties: %d clanmate(s) join your patrol", #out) end
    return out
end

local function companionsLeave(list)
    for _, name in ipairs(list or {}) do
        local cat = StaticFindObject(name)
        pcall(function()
            local ai = cat.Controller
            ai:StopMovement()
            ai.BrainComponent:RestartLogic()
        end)
    end
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
    if today.train then
        table.insert(parts, string.format("spar with %s (%s)", today.train.who, today.train.done and "done" or "not yet"))
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
    if hunt > 0 then
        today.hunt = { need = hunt, got = 0 }
        if cfg.huntingGround then today.hunt.ground = huntingGround() end
    end
    if patrol > 0 then
        today.patrol = patrolPoints(patrol)
        today.companions = companionsJoin(cfg.companions)
    end
    if cfg.train then
        local r, rank = ranks()
        if not (rank and r[cfg.trainMaxRank] and rank > r[cfg.trainMaxRank]) then today.train = trainingPartner() end
    end
    if not today.hunt and not today.patrol and not today.train then
        log("duties: day %d - no duties today", day)
        today = nil
        return
    end
    log("duties: day %d (fresh-kill pile %d) - %s", day, pile, summary())
    local ground = today.hunt and today.hunt.ground
    card(string.format("Today's duties: %s.%s", summary(),
        ground and string.format(" %s are about in the hunting ground the patrol marked.", ground.kind) or ""))
end

local function checkTrain(at)
    local t = today and today.train
    if not t or t.done or t.fighting or require("menus").InMenu() then return end
    local partner = StaticFindObject(t.path)
    if not (partner and partner:IsValid()) then return end
    local q = partner:K2_GetActorLocation()
    if math.sqrt((q.X - at.X) ^ 2 + (q.Y - at.Y) ^ 2) > cfg.reach then return end
    if startSpar(t) then
        t.fighting = true
        log("duties: sparring with %s", t.who)
    end
end

-- the fight is over (its end screen): the training counts, win or lose, and the bond grows
local function sparOver()
    local t = today and today.train
    if not (t and t.fighting) then return end
    t.fighting, t.done = false, true
    local bond = t.role and cfg.trainBond > 0 and WaCaNative_AddBond and WaCaNative_AddBond(t.role, cfg.trainBond)
    log("duties: sparring done%s", bond and string.format(" - bond with %s +%d", t.who, cfg.trainBond) or "")
    card(string.format("Training done - %s.", summary()))
end

local function checkPatrol()
    local p = today and pc() and pc().Pawn
    if not p then return end
    local at = p:K2_GetActorLocation()
    checkTrain(at)
    if not today.patrol then return end
    for i, pt in ipairs(today.patrol) do
        if not pt.done and math.sqrt((pt.X - at.X) ^ 2 + (pt.Y - at.Y) ^ 2) <= cfg.reach then
            pt.done = true
            removeMarker(pt)
            log("duties: border point %d checked", i)
            local all = true
            for _, q in ipairs(today.patrol) do if not q.done then all = false end end
            if all then companionsLeave(today.companions) today.companions = nil end
            card(string.format("Border point checked - %s.", summary()))
        end
    end
end

-- the day's end: done duties raise standing, missed ones lower it
local function verdict()
    if not today then return end
    local done, missed = 0, 0
    if today.hunt then
        if today.hunt.ground then removeMarker(today.hunt.ground) end
        if today.hunt.got >= today.hunt.need then
            done = done + 1
            -- the hunt's prey goes onto the clan's fresh-kill pile
            local pile = pileComponent()
            local now = pile and cfg.pileReward > 0 and WaCaNative_AddResource and WaCaNative_AddResource(pile:GetAddress(), cfg.pileReward)
            if now then log("duties: the hunt fed the clan - fresh-kill pile +%d = %.0f", cfg.pileReward, now) end
        else
            missed = missed + 1
        end
    end
    if today.patrol then
        local all = true
        for _, pt in ipairs(today.patrol) do
            if not pt.done then all = false end
            removeMarker(pt)
        end
        if all then done = done + 1 else missed = missed + 1 end
    end
    if today.train then
        if today.train.done then done = done + 1 else missed = missed + 1 end
    end
    companionsLeave(today.companions)
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
    cfg.pileReward = tonumber(h.PileReward or "") or cfg.pileReward
    cfg.huntingGround = (h.HuntingGround or "1") ~= "0"
    local p = ini["Patrol"] or {}
    cfg.patrolPoints = math.max(0, math.floor(tonumber(p.Points or "") or cfg.patrolPoints))
    cfg.reach = tonumber(p.Reach or "") or cfg.reach
    cfg.companions = math.max(0, math.floor(tonumber(p.Companions or "") or cfg.companions))
    cfg.minDist = tonumber(p.MinDistance or "") or cfg.minDist
    cfg.maxDist = tonumber(p.MaxDistance or "") or cfg.maxDist
    local t = ini["Train"] or {}
    cfg.train = (t.On or "1") ~= "0"
    cfg.trainMaxRank = (t.MaxRank or "") ~= "" and t.MaxRank or cfg.trainMaxRank
    cfg.trainBond = tonumber(t.Bond or "") or cfg.trainBond
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
    -- the fight's end: its end screen, or the combat manager's EndCombat (whichever comes first; the second finds no
    -- fight running)
    WaCa.On("ScreenShown", function(screen)
        if screen:GetClass():GetFName():ToString() == "WBP_GuiHudCombatOver_C" then sparOver() end
    end)
    WaCa.Watch("EndCombat", "/Script/SwtAdventure.SwtAdventureCombatManager", "WaCaSparEnd", "post")
    WaCa.On("WaCaSparEnd", function() sparOver() end)
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
