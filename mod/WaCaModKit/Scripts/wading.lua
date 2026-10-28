-- wading (tickets.md 16, config/wading.ini): the game has no swimming - water is a floor type (Water / DeepWater on the
-- adventure physical material, the one its step splashes come from). A cat stepping into water slows down, deeper water
-- more; RiverClan cats are at home in it and slow down less.
--
-- Event-driven: the game's step notify (BP_AnimStepNotify - VM 2026-10-28: the one the cat's walk raises; not the C++
-- USwtAdventureStepModifierNotifyState) fires on every footstep of every cat - it is ONE object per animation, so the watch hands over the stepping mesh (its "MeshComp") and only the player's own
-- steps count. The floor under the cat is the movement component's current floor (its hit's physical material).
local Wading = {}

local WaCa, log
local cfg = { on = false, shallow = 0.8, deep = 0.6, riverClan = 0.5 }
local FLOOR_DEEP, FLOOR_WATER = 3, 4          -- EAdventurePhysicalFloorType
local current = nil                           -- the floor type the last step was on (nil = not known yet)
local physClass = nil
local seenStep = false                        -- the first step read is logged once

local function player()
    for _, c in ipairs(FindAllOf("SwtPlayerController") or {}) do
        if c:IsValid() and c.Player and c.Pawn and c.Pawn:IsValid() then return c.Pawn end
    end
end

-- the cat's clan as the game saved it (as fishing.lua reads it)
local function clan()
    local p = WaCa.GameProgress()
    local me = p and p["Gameplay.Combat.Character.Cat.Player"]
    return me and me.Customization and me.Customization:match("ClanType=(%w+)") or nil
end

-- the floor type under the pawn, or nil (no floor / not one of the game's physical materials). The floor hit's own
-- physical material is not the game's (VM 2026-10-28: a plain one on the terrain), the floor mesh's material carries it
-- (PM_Terrain_Dirt on the RiverClan terrain) - the hit's first, then the mesh's
local function floorType(pawn)
    physClass = physClass or StaticFindObject("/Script/SwtAdventure.AdventurePhysicalMaterial")
    if not physClass then return nil end
    -- (a weak pointer is dereferenced; asking a plain UObject for "Get" is an error in UE4SS)
    local function deref(x)
        if x and tostring(x):match("^FWeakObjectPtr") then return x:Get() end
        return x
    end
    local function typeOf(pm)
        pm = deref(pm)
        if pm and pm:IsValid() and pm:IsA(physClass) then return pm.FloorType end
        return nil
    end
    local hit = pawn.CharacterMovement.CurrentFloor.HitResult
    local ok, t = pcall(typeOf, hit.PhysMaterial)
    if ok and t then return t end
    ok, t = pcall(function()
        local comp = deref(hit.Component)
        if not (comp and comp:IsValid()) then return nil end
        local mat = comp:GetMaterial(0)
        if not (mat and mat:IsValid()) then return nil end
        return typeOf(mat:GetPhysicalMaterial())
    end)
    return ok and t or nil
end

-- the slow-down for a floor: 1 on dry ground; RiverClan cats lose only part of it (RiverClan = 0.5: half)
local function factorFor(t)
    local f = 1
    if t == FLOOR_WATER then f = cfg.shallow elseif t == FLOOR_DEEP then f = cfg.deep end
    if f < 1 and clan() == "RiverClan" then f = 1 - (1 - f) * cfg.riverClan end
    return f
end

local function onStep(_, mesh)
    if not cfg.on or not mesh or not mesh:IsValid() then return end
    local pawn = player()
    if not pawn then return end
    local owner = mesh:GetOwner()
    if not (owner and owner:IsValid() and owner:GetAddress() == pawn:GetAddress()) then return end
    local t = floorType(pawn)
    if not seenStep then
        seenStep = true
        log("wading: the cat's steps are read (floor type %s)", tostring(t))
    end
    if t == current then return end
    local wasWet = current == FLOOR_WATER or current == FLOOR_DEEP
    current = t
    local f = factorFor(t)
    WaCa.Emit("SpeedFactor", "wading", f)
    local wet = t == FLOOR_WATER or t == FLOOR_DEEP
    if wet then log("wading: %s water - speed x%.2f", t == FLOOR_DEEP and "deep" or "shallow", f)
    elseif wasWet then log("wading: out of the water") end
end

function Wading.Init(c)
    WaCa, log = c.WaCa, c.log
    local ini = WaCa.ReadIni(c.modDir .. "/config/wading.ini") or {}
    local w = ini["Wading"] or {}
    cfg.on = (w.On or "1") == "1"
    cfg.shallow = tonumber(w.Shallow or "") or cfg.shallow
    cfg.deep = tonumber(w.Deep or "") or cfg.deep
    cfg.riverClan = tonumber(w.RiverClan or "") or cfg.riverClan
    if not cfg.on then return end
    WaCa.Watch("Received_Notify", "/Game/Gameplay/Blueprints/BP_AnimStepNotify.BP_AnimStepNotify_C", "CatStep", "pre",
        "MeshComp")
    WaCa.On("CatStep", onStep)
    log("wading: on (shallow x%.2f, deep x%.2f, RiverClan keeps %.0f%% of the slow-down)", cfg.shallow, cfg.deep,
        cfg.riverClan * 100)
end

return Wading
