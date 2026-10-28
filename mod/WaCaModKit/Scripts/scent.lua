-- Scent trails to prey (tickets.md 26). The game's sense mode (Q) already tracks what's near: every roaming creature
-- carries a BP_SensedEnemy_TrackComponent, and sensing spawns its TrackerElementClass (BP_Sense_TrackerElement: no
-- path, only an overlay on the target). The game's own quest-hint trail is another tracker element class
-- (BP_POI_Hint_TrackerElement_Duration: path + spline mesh + the scent Niagara, fading after a while). So each prey's
-- track component gets that class instead (when the world is up and when a creature spawns) - sense mode then
-- draws a scent trail from your cat to the prey, in the game's own trail look. The elements are spawned natively
-- (their BeginPlay / state calls never pass ProcessEvent), hence the class swap rather than a hook.
-- The game has PATHS only for its own quest targets (its track path manager's): a prey's trail element gets none
-- (0 spline points, nothing drawn - VM). So when a sense pulse starts (the sense component's first BlendProgress -
-- its timeline tick, it passes ProcessEvent; BlendsFinished = the pulse is over, VM-timed), every prey trail without
-- points gets one laid: from the cat to the prey, a little under the surface like the game's, its meshes built
-- (SetupMeshes) and the element switched off / on to draw it.
-- config/hunting.ini [Scent].
local Scent = {}

local WaCa, log
local cfg = { on = false, kinds = {}, trail = nil, sink = 40 }
local TRAIL = "/Game/Gameplay/Blueprints/WorldElements/TrackerElements/BP_POI_Hint_TrackerElement_Duration.BP_POI_Hint_TrackerElement_Duration_C"
local preyValues
local trailClass, trackClass
local count = 0

local function preyKind(value)
    if not preyValues then
        preyValues = {}
        pcall(function()
            StaticFindObject("/Script/SwtQuest.ESwtQuestCharacterType"):ForEachName(function(name, v)
                preyValues[v] = (name:ToString():gsub("^.*::", ""):gsub("^Weak", ""))
            end)
        end)
    end
    local kind = preyValues[value]
    return kind and cfg.kinds[kind] and kind or nil
end

-- give one creature's sense track the trail class (prey only)
local function trailFor(creature)
    if not preyKind(creature.CharacterType) then return false end
    trailClass = trailClass or WaCa.LoadAsset(cfg.trail)
    trackClass = trackClass or StaticFindObject("/Script/SwtAdventure.SwtAdventureSenseTrackedComponent")
    if not (trailClass and trackClass) then return false end
    local comps = creature:K2_GetComponentsByClass(trackClass)
    local done = false
    for i = 1, #comps do
        local comp = comps[i]
        comp = (comp.get and comp:get()) or comp
        if comp:IsValid() then
            comp.TrackerElementClass = trailClass
            done = true
        end
    end
    return done
end

local function trailAll(why)
    local n = 0
    for _, c in ipairs(FindAllOf("BP_Exploration_Character_Base_C") or {}) do
        local ok, done = pcall(trailFor, c)
        if ok and done then n = n + 1 end
    end
    count = count + n
    log("scent: %s - %d prey leave a trail in sense mode", why, n)
end

-- lay a path (cat -> prey) into each prey trail element that has none
local function layPaths()
    local pawn
    for _, c in ipairs(FindAllOf("SwtPlayerController") or {}) do
        if c:IsValid() and c.Player and c.Pawn and c.Pawn:IsValid() then pawn = c.Pawn end
    end
    if not pawn then return end
    local a = pawn:K2_GetActorLocation()
    local n = 0
    for _, e in ipairs(FindAllOf("BP_POI_Hint_TrackerElement_Duration_C") or {}) do
        pcall(function()
            local owner = e:GetOwner()
            if not (owner and owner:IsValid() and owner.CharacterType and preyKind(owner.CharacterType)) then return end
            local spl = e.EngineSplineMeshComponent
            if spl:GetNumberOfSplinePoints() > 1 then return end
            local b = owner:K2_GetActorLocation()
            local steps = math.max(2, math.floor(math.sqrt((b.X - a.X) ^ 2 + (b.Y - a.Y) ^ 2) / 150))
            spl:ClearSplinePoints(false)
            for i = 0, steps do
                local t = i / steps
                spl:AddSplinePoint({ X = a.X + (b.X - a.X) * t, Y = a.Y + (b.Y - a.Y) * t, Z = a.Z + (b.Z - a.Z) * t - cfg.sink },
                    1, i == steps)
            end
            spl:SetupMeshes()                              -- the visible trail: meshes along the spline
            e:OnTrackStateChange(false)
            e:OnTrackStateChange(true)
            n = n + 1
        end)
    end
    if n > 0 then log("scent: %d trail(s) laid to prey", n) end
end

function Scent.Init(c)
    WaCa, log = c.WaCa, c.log
    local s = (WaCa.ReadIni(c.modDir .. "/config/hunting.ini") or {})["Scent"] or {}
    cfg.on = (s.Trails or "0") == "1"
    cfg.trail = (s.TrailClass or "") ~= "" and s.TrailClass or TRAIL
    for kind in (s.PreyKinds or "Mice,Squirrel,Rabbit,Bird,Fish"):gmatch("[^,%s]+") do cfg.kinds[kind] = true end
    log("scent: trails %s", cfg.on and "on" or "off")
    if not cfg.on then return end
    WaCa.On("ScreenShown", function(screen)
        if screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then trailAll("the world is up") end
    end)
    WaCa.Watch("ReceiveBeginPlay",
        "/Game/Gameplay/Blueprints/Characters/ExplorationCharacters/BP_Exploration_Character_Base.BP_Exploration_Character_Base_C",
        "WaCaScentCreature", "post")
    WaCa.On("WaCaScentCreature", function(creature) pcall(trailFor, creature) end)
    local pulse = false
    WaCa.Watch("BlendProgress", "/Script/SwtAdventure.SwtAdventureExplorationSenseComponent", "WaCaSenseTick", "post")
    WaCa.Watch("BlendsFinished", "/Script/SwtAdventure.SwtAdventureExplorationSenseComponent", "WaCaSenseOver", "post")
    WaCa.On("WaCaSenseTick", function()
        if pulse then return end
        pulse = true
        -- (the tracker elements appear as the pulse finds its candidates - a moment after it starts)
        ExecuteInGameThreadWithDelay(1500, function()
            local ok, err = pcall(layPaths)
            if not ok then log("scent: laying trails failed (%s)", tostring(err)) end
        end)
    end)
    WaCa.On("WaCaSenseOver", function() pulse = false end)
end

return Scent
