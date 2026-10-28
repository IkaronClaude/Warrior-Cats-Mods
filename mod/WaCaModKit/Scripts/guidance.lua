-- StarClan's guidance leads to prey (tickets.md 24). The game guides you to a quest objective with a POI hint area
-- (BP_POI_HintArea_Quest): an actor whose sense-tracked component draws the scent trail in sense mode (Q), even from
-- far away. Here one such hint area is spawned per world (30 s after it's up - spawning while it still streams in
-- crashed the game, fishing) and attached to a prey creature: the nearest one of the wanted kinds between
-- MinDistance and MaxDistance, so the trail leads to prey you can't see yet. It moves on to new prey every in-game
-- hour and after a catch. config/hunting.ini [Guidance].
local Guidance = {}

local WaCa, log
local cfg = { on = false, kinds = {}, min = 1500, max = 9000 }
local HINT = "/Game/Gameplay/Blueprints/WorldElements/POIHintArea/BP_POI_HintArea_Quest.BP_POI_HintArea_Quest_C"
local hint                        -- the hint area's full name (held objects can go stale)
local target                      -- the prey it's on (full name)
local preyValues

local function pawn()
    for _, c in ipairs(FindAllOf("SwtPlayerController") or {}) do
        if c:IsValid() and c.Player and c.Pawn and c.Pawn:IsValid() then return c.Pawn end
    end
end

local function isPrey(creature)
    if not preyValues then
        preyValues = {}
        pcall(function()
            StaticFindObject("/Script/SwtQuest.ESwtQuestCharacterType"):ForEachName(function(name, v)
                preyValues[v] = (name:ToString():gsub("^.*::", ""):gsub("^Weak", ""))
            end)
        end)
    end
    local kind = preyValues[creature.CharacterType]
    return kind and cfg.kinds[kind] and kind or nil
end

local function hintActor()
    local h = hint and StaticFindObject(hint)
    if h and h:IsValid() then return h end
    local class = WaCa.LoadAsset(HINT)
    local p = pawn()
    if not (class and p) then return nil end
    local at = p:K2_GetActorLocation()
    h = p:GetWorld():SpawnActor(class, { X = at.X, Y = at.Y, Z = at.Z - 5000 }, { pitch = 0, Yaw = 0, Roll = 0 })
    if not (h and h:IsValid()) then return nil end
    pcall(function() h.SenseTrackedComponent.bTrackingEnabled = true end)
    pcall(function() h:OnQuestTracked(true, nil) end)       -- the game's own switch: tracked = shown in sense mode
    hint = (h:GetFullName():gsub("^%S+ ", ""))
    return h
end

-- put StarClan's sign on the nearest prey of the wanted kinds in range
local function retarget(why)
    local ok, err = pcall(function()
        local p = pawn()
        if not p then return end
        local at = p:K2_GetActorLocation()
        local best, bd, kind
        for _, c in ipairs(FindAllOf("BP_Exploration_Character_Base_C") or {}) do
            pcall(function()
                local k = c:IsValid() and not c.bHidden and isPrey(c)
                if k then
                    local q = c:K2_GetActorLocation()
                    local d = math.sqrt((q.X - at.X) ^ 2 + (q.Y - at.Y) ^ 2)
                    if d >= cfg.min and d <= cfg.max and (not bd or d < bd) then best, bd, kind = c, d, k end
                end
            end)
        end
        if not best then
            log("guidance: no %s between %d and %d - StarClan is silent (%s)", "prey", cfg.min, cfg.max, why)
            return
        end
        local h = hintActor()
        if not h then error("no hint area") end
        h:K2_DetachFromActor(1, 1, 1)
        h:K2_AttachToActor(best, FName("None"), 2, 2, 1, false)      -- snap to the prey, keep its scale
        target = best:GetFullName()
        log("guidance: StarClan points to a %s %.0f away (%s)", kind, bd, why)
    end)
    if not ok then log("guidance: failed (%s)", tostring(err)) end
end

function Guidance.Init(c)
    WaCa, log = c.WaCa, c.log
    local g = (WaCa.ReadIni(c.modDir .. "/config/hunting.ini") or {})["Guidance"] or {}
    cfg.on = (g.On or "0") == "1"
    cfg.min = tonumber(g.MinDistance or "") or cfg.min
    cfg.max = tonumber(g.MaxDistance or "") or cfg.max
    for kind in (g.PreyKinds or "Mice,Squirrel,Rabbit,Bird"):gmatch("[^,%s]+") do cfg.kinds[kind] = true end
    log("guidance: %s", cfg.on and "on" or "off")
    if not cfg.on then return end
    local armed, ready = false, false
    WaCa.On("ScreenShown", function(screen)
        if armed or not screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then return end
        armed = true
        ExecuteInGameThreadWithDelay(30000, function()
            ready = true                                   -- no spawn before (the world is still streaming in)
            retarget("the world is up")
        end)
    end)
    WaCa.On("HourChanged", function() if ready then retarget("a new hour") end end)
    WaCa.On("HuntCaught", function(_, prey)
        if target and tostring(prey):find(target:gsub("^%S+ ", ""), 1, true) then retarget("its prey was caught") end
    end)
end

return Guidance
