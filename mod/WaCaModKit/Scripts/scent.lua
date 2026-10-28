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
local cfg = { on = false, kinds = {}, trail = nil, sink = 40, seconds = 12, opacity = 1.0, spacing = 250,
              puff = "/Game/Art/Vfx/Niagaras/GameplayElements/NS_Scent_Hint_Item.NS_Scent_Hint_Item",
              color = { R = 1.0, G = 0.55, B = 0.2, A = 1.0 },
              effect = "/Game/Art/Vfx/Niagaras/GameplayElements/NS_ScentTracking.NS_ScentTracking" }
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

-- the game's own scent effect along the laid path: NS_ScentTracking draws along a spline it is given (its user
-- parameters: Spline, SplineLength, Code_TrailOpacity, Code_Color - read from the asset), so it's spawned on the trail
-- element and bound to that element's spline (a spline data interface takes the actor's spline component) - the way
-- the quest trail feeds it. Removed after TrailSeconds.
local function scentLine(element, spline)
    local system = WaCa.LoadAsset(cfg.effect)
    if not system then return false end
    local lib = StaticFindObject("/Script/Niagara.Default__NiagaraFunctionLibrary")
    local comp = lib:SpawnSystemAttached(system, element.RootComponent or spline, FName("None"), { X = 0, Y = 0, Z = 0 },
        { pitch = 0, Yaw = 0, Roll = 0 }, 1, false, true, 0, false)       -- KeepWorldPosition: the spline is in world space
    if not (comp and comp:IsValid()) then return false end
    comp:SetVariableActor(FName("Spline"), element)
    comp:SetVariableFloat(FName("SplineLength"), spline:GetSplineLength())
    comp:SetVariableFloat(FName("Code_TrailOpacity"), cfg.opacity)
    comp:SetVariableLinearColor(FName("Code_Color"), cfg.color)
    pcall(function() comp:ReinitializeSystem() end)
    local name = (comp:GetFullName():gsub("^%S+ ", ""))
    ExecuteInGameThreadWithDelay(math.floor(cfg.seconds * 1000), function()
        local c = StaticFindObject(name)
        if c and c:IsValid() then pcall(function() c:DestroyComponent(c) end) end
    end)
    return true
end

-- the trail you can SEE: puffs of the game's scent hint effect (NS_Scent_Hint_Item - it renders on its own; the
-- spline-bound NS_ScentTracking above stayed invisible on the VM) every Spacing cm from the cat to the prey
local function puffs(a, b)
    local system = WaCa.LoadAsset(cfg.puff)
    if not system then return 0 end
    local lib = StaticFindObject("/Script/Niagara.Default__NiagaraFunctionLibrary")
    local steps = math.max(1, math.floor(math.sqrt((b.X - a.X) ^ 2 + (b.Y - a.Y) ^ 2) / cfg.spacing))
    local made = {}
    for i = 1, steps do
        local t = i / steps
        local ok, comp = pcall(function()
            return lib:SpawnSystemAtLocation(FindFirstOf("World"), system,
                { X = a.X + (b.X - a.X) * t, Y = a.Y + (b.Y - a.Y) * t, Z = a.Z + (b.Z - a.Z) * t - cfg.sink },
                { pitch = 0, Yaw = 0, Roll = 0 }, { X = 1, Y = 1, Z = 1 }, false, true, 0, false)
        end)
        if ok and comp and comp:IsValid() then table.insert(made, (comp:GetFullName():gsub("^%S+ ", ""))) end
    end
    ExecuteInGameThreadWithDelay(math.floor(cfg.seconds * 1000), function()
        for _, name in ipairs(made) do
            local c = StaticFindObject(name)
            if c and c:IsValid() then pcall(function() c:DestroyComponent(c) end) end
        end
    end)
    return #made
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
            scentLine(e, spl)                              -- and the scent itself along it, in the game's effect
            puffs(a, b)
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
    cfg.opacity = tonumber(s.Opacity or "") or cfg.opacity
    cfg.spacing = math.max(50, tonumber(s.Spacing or "") or cfg.spacing)
    if (s.Puff or "") ~= "" then cfg.puff = s.Puff end
    local col = WaCa.ParseColor and (s.Color or "") ~= "" and WaCa.ParseColor(s.Color)
    if col then cfg.color = col end
    cfg.seconds = math.max(1, tonumber(s.TrailSeconds or "") or cfg.seconds)
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
