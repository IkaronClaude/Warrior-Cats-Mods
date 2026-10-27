-- Fishing (tickets.md 9b, operator 2026-10-27): walking up to a fishing spot startles the fish - they're gone (the
-- spot's hint hidden, its interaction off) for StartleSeconds; once the cat has stood still on the spot that long,
-- they swim back and bite with Chance % (x the clan's factor - RiverClan 1.5 - and the season's / weather's): a bite re-enables the game's own catch,
-- no bite = another wait. config/hunting.ini [Fishing].
-- The spot's own interaction can't be watched (a teleported or walking cat raises no event the mod can see), so each
-- spot gets one of the game's own movement-modifier trigger boxes (its Blueprint, BP_MovementModifier_*, flag None =
-- no effect on the cat), whose overlap UFunctions are hooked: the cat entering / leaving the spot are events. The only
-- timed parts are the waits themselves (one callback each, only while the cat is on a spot).
local Fishing = {}

local WaCa, log, modDir
local cfg = { on = false, startle = 5, chance = 40, moving = 25, clans = {}, world = 1 }   -- world: weather.lua
local spots = {}                 -- area full name -> { spot = spot path, inside = bool, gen = n, state = "here" / "gone" }
local hooked = false

local function pathOf(o) return (o:GetFullName():gsub("^%S+ ", "")) end

local function player()
    for _, c in ipairs(FindAllOf("SwtPlayerController") or {}) do
        if c:IsValid() and c.Player and c.Pawn and c.Pawn:IsValid() then return c.Pawn end
    end
end

-- the cat's clan as the game saved it (the player's Customization "(ClanType=RiverClan,...)")
local function clan()
    local p = WaCa.GameProgress()
    local me = p and p["Gameplay.Combat.Character.Cat.Player"]
    return me and me.Customization and me.Customization:match("ClanType=(%w+)") or nil
end

local function setFish(entry, here)
    local spot = StaticFindObject(entry.spot)
    if not (spot and spot:IsValid()) then return end
    entry.state = here and "here" or "gone"
    pcall(function() spot.NS_PickUp_Hint:SetVisibility(here, false) end)
    pcall(function() spot.InteractionComponent:SetCollisionEnabled(here and 1 or 0) end)
end

local function still()
    local pawn = player()
    if not pawn then return false end
    local v = pawn:GetVelocity()
    return v.X * v.X + v.Y * v.Y < cfg.moving * cfg.moving
end

-- the fish are gone: after StartleSeconds, if the cat is still on the spot and standing still, they come back and
-- bite by chance; otherwise wait again (only while the cat stays on the spot)
local function waitForFish(entry)
    entry.gen = entry.gen + 1
    local gen = entry.gen
    ExecuteInGameThreadWithDelay(math.floor(cfg.startle * 1000), function()
        if gen ~= entry.gen then return end
        if not entry.inside then
            setFish(entry, true)                       -- the cat left: the fish are back for the next approach
            log("fishing: your cat left the spot - the fish are back")
            return
        end
        if not still() then
            log("fishing: the fish stay away - your cat isn't keeping still")
            waitForFish(entry)
            return
        end
        local factor = cfg.clans[clan() or ""] or 1.0
        local pct = math.min(100, cfg.chance * factor * cfg.world)
        local roll = math.random() * 100
        if roll < pct then
            setFish(entry, true)
            log("fishing: the fish are back and biting (chance %.0f%%, rolled %.0f) - catch it now", pct, roll)
        else
            log("fishing: the fish swim back but don't bite (chance %.0f%%, rolled %.0f) - keep still", pct, roll)
            waitForFish(entry)
        end
    end)
end

local function onArea(entering, areaName, otherName)
    local entry = spots[areaName]
    local pawn = player()
    if not (entry and pawn and otherName == pawn:GetFullName()) then return end
    entry.inside = entering
    if entering then log("fishing: your cat is at a fishing spot (%s, the fish are %s)", still() and "still" or "moving", entry.state) end
    if entering and entry.state == "here" and not still() then
        setFish(entry, false)
        log("fishing: your cat came at the spot moving - the fish are startled and gone")
        waitForFish(entry)
    elseif entering and entry.state == "gone" then
        waitForFish(entry)
    end
end

-- a trigger box of the game's own movement-modifier kind on every fishing spot (flag None)
local function armSpots()
    -- the game's own Blueprint of it (its overlap is bound there - a bare native one never reports), flag cleared
    local areaClass
    for _, a in ipairs(FindAllOf("SwtAdventureMovementModifierArea") or {}) do
        -- always the same variant (the first found differed per run - Loud / Hiding / Invisible - and a run crashed)
        if a:IsValid() and a:GetClass():GetFName():ToString():find("^BP_MovementModifier_Loud") then areaClass = a:GetClass() break end
    end
    if not areaClass then
        log("fishing: the game's movement-modifier areas aren't loaded - spots not armed")
        return
    end
    -- one spot per half second (spawning them all at once, right as the world came up, crashed the game inside the
    -- Blueprint's construction - FinishSpawningActor, VM 2026-10-27)
    local list = {}
    for _, spot in ipairs(FindAllOf("BP_Interactable_Claw_FishingSpot_C") or {}) do
        if spot:IsValid() then table.insert(list, pathOf(spot)) end
    end
    local n = 0
    local function armOne(i)
        if i > #list then
            log("fishing: %d fishing spots armed (clan %s: x%.1f)", n, tostring(clan()), cfg.clans[clan() or ""] or 1.0)
            return
        end
        local ok, err = pcall(function()
            local spot = StaticFindObject(list[i])
            if not (spot and spot:IsValid()) then return end
            local p = spot:K2_GetActorLocation()
            local area = spot:GetWorld():SpawnActor(areaClass, p, { pitch = 0, Yaw = 0, Roll = 0 })
            area.MovementFlag = 0
            area.TriggerBox:SetCollisionProfileName(FName("OverlapAllDynamic"), true)
            area.TriggerBox:SetBoxExtent({ X = cfg.radius, Y = cfg.radius, Z = 200 }, true)
            spots[pathOf(area)] = { spot = list[i], inside = false, gen = 0, state = "here" }
            n = n + 1
        end)
        if not ok then log("fishing: a spot couldn't be armed (%s)", tostring(err)) end
        ExecuteInGameThreadWithDelay(500, function() armOne(i + 1) end)
    end
    armOne(1)
end

function Fishing.Init(c)
    WaCa, log, modDir = c.WaCa, c.log, c.modDir
    local ini = WaCa.ReadIni(modDir .. "/config/hunting.ini") or {}
    local f = ini["Fishing"] or {}
    cfg.on = (f.On or "0") == "1"
    cfg.startle = tonumber(f.StartleSeconds or "") or cfg.startle
    cfg.chance = tonumber(f.Chance or "") or cfg.chance
    cfg.radius = tonumber(f.Radius or "") or 250
    for name, v in pairs(ini["FishingClan"] or {}) do
        if name ~= "__order" and tonumber(v) then cfg.clans[name] = tonumber(v) end
    end
    log("fishing: %s", cfg.on and "on" or "off")
    if not cfg.on then return end
    -- seasons / weather (weather.lua): fish bite better in the rain, worse in leaf-bare
    WaCa.On("WorldFactors", function(_, fish) cfg.world = fish end)
    if not hooked then
        hooked = true
        -- the spots' trigger boxes report through areas.cpp (AreaOverlap: area, actor, "1" / "0", flag)
        WaCa.On("AreaOverlap", function(_, area, other, entering, flag)
            if tonumber(flag) ~= 0 then return end
            local path = area:gsub("^%S+ ", "")
            local entry = spots[path]
            local pawn = player()
            if not (entry and pawn) then return end
            local now = entering == "1"
            if now ~= entry.inside then onArea(now, path, other) end
        end)
    end
    -- the spots exist once the world is up (the gameplay HUD)
    local armed = false
    WaCa.On("ScreenShown", function(screen)
        if armed or not screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then return end
        armed = true
        for _, area in ipairs(FindAllOf("SwtAdventureMovementModifierArea") or {}) do
            if area:IsValid() then
                if WaCaNative_HookAreas then WaCaNative_HookAreas(area:GetAddress()) end
                break
            end
        end
        -- spawning from inside the screen's hook crashed the game once (VM): on the game thread's next tick instead
        -- 30 s in: every crash (4 runs) came 0-10 s after the HUD while the world was still streaming in, the game's
        -- own GetWorld coming back null under FinishSpawningActor; 100 spawns 20 s in never crashed (VM stress test)
        ExecuteInGameThreadWithDelay(30000, function()
            local ok, err = pcall(armSpots)
            if not ok then log("fishing: arming failed (%s)", tostring(err)) end
        end)
    end)
end

return Fishing
