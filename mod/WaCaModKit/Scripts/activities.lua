-- Clan activities (tickets.md 5), ambient part: clanmates near the player that stand still now and then sit, nap,
-- sniff around or play-fight - the game's own montages (ACharacter.PlayAnimMontage), which NPC cats play while their
-- AI runs (VM, 2026-10-27). config/activities.ini: [Ambient] On / Every / Radius, [Activity.<Name>] Montage / Weight
-- / Pair. One scheduled callback per Every seconds while the player is in the world (a schedule, not a state poll):
-- it starts when the gameplay HUD comes and stops when it goes.
local Activities = {}

local WaCa, log, modDir
local cfg = { on = false, every = 20, radius = 3000, list = {}, total = 0 }
local running, generation = false, 0
local busyUntil = {}             -- cat name -> os.time() its activity ends

local function player()
    for _, c in ipairs(FindAllOf("SwtPlayerController") or {}) do
        if c:IsValid() and c.Player and c.Pawn and c.Pawn:IsValid() then return c.Pawn end
    end
end

-- clanmates (NPC cats, CharacterType Cat) near the player that stand still and aren't busy with an activity
local function idleCatsNear(pawn)
    local out = {}
    local catType
    pcall(function()
        StaticFindObject("/Script/SwtQuest.ESwtQuestCharacterType"):ForEachName(function(name, value)
            if name:ToString():gsub("^.*::", "") == "Cat" then catType = value end
        end)
    end)
    if not catType then return out end
    local at = pawn:K2_GetActorLocation()
    for _, c in ipairs(FindAllOf("BP_Exploration_Character_Base_C") or {}) do
        local ok, near = pcall(function()
            if not c:IsValid() or c.CharacterType ~= catType then return false end
            local p = c:K2_GetActorLocation()
            local v = c:GetVelocity()
            local d2 = (p.X - at.X) ^ 2 + (p.Y - at.Y) ^ 2
            -- not in the middle of an activity (NPC cats always run some montage of their own - only ours count)
            return d2 < cfg.radius * cfg.radius and (v.X * v.X + v.Y * v.Y) < 25 and (busyUntil[c:GetFName():ToString()] or 0) <= os.time()
        end)
        if ok and near then table.insert(out, c) end
        if not ok and not Activities.warned then
            Activities.warned = true
            log("activities: a clanmate couldn't be checked (%s)", tostring(near))
        end
    end
    return out
end

local function pick()
    local r = math.random() * cfg.total
    for _, a in ipairs(cfg.list) do
        r = r - a.weight
        if r <= 0 then return a end
    end
    return cfg.list[#cfg.list]
end

local function face(a, b)
    local pa, pb = a:K2_GetActorLocation(), b:K2_GetActorLocation()
    local yaw = math.deg(math.atan(pb.Y - pa.Y, pb.X - pa.X))
    a:K2_SetActorRotation({ Pitch = 0, Yaw = yaw, Roll = 0 }, false)
end

local function once()
    local pawn = player()
    if not pawn then return end
    local cats = idleCatsNear(pawn)
    if #cats == 0 then return end
    local activity = pick()
    local montage = activity and LoadAsset(activity.montage)
    if not montage then
        log("activities: %s - its montage %s doesn't load", activity and activity.name or "?", activity and activity.montage or "?")
        return
    end
    local first = cats[math.random(#cats)]
    if activity.pair then
        local partner
        local best
        local p = first:K2_GetActorLocation()
        for _, c in ipairs(cats) do
            if c ~= first then
                local q = c:K2_GetActorLocation()
                local d = (p.X - q.X) ^ 2 + (p.Y - q.Y) ^ 2
                if d < 600 * 600 and (not best or d < best) then partner, best = c, d end
            end
        end
        if not partner then return end                 -- nobody close enough to play with
        face(first, partner)
        face(partner, first)
        busyUntil[partner:GetFName():ToString()] = os.time() + math.ceil(partner:PlayAnimMontage(montage, 1.0, FName("None")))
        log("activities: %s and %s - %s", first:GetFName():ToString(), partner:GetFName():ToString(), activity.name)
    else
        log("activities: %s - %s", first:GetFName():ToString(), activity.name)
    end
    busyUntil[first:GetFName():ToString()] = os.time() + math.ceil(first:PlayAnimMontage(montage, 1.0, FName("None")))
end

local function schedule(gen)
    ExecuteInGameThreadWithDelay(math.floor(cfg.every * 1000), function()
        if gen ~= generation or not running then return end
        local ok, err = pcall(once)
        if not ok then log("activities: failed (%s)", tostring(err)) end
        schedule(gen)
    end)
end

function Activities.Init(c)
    WaCa, log, modDir = c.WaCa, c.log, c.modDir
    local ini = WaCa.ReadIni(modDir .. "/config/activities.ini") or {}
    local amb = ini["Ambient"] or {}
    cfg.on = (amb.On or "0") == "1"
    cfg.every = math.max(2, tonumber(amb.Every or "") or cfg.every)
    cfg.radius = tonumber(amb.Radius or "") or cfg.radius
    for section, keys in pairs(ini) do
        local name = section:match("^Activity%.(.+)$")
        if name and keys.Montage then
            local a = { name = name, montage = keys.Montage, weight = tonumber(keys.Weight or "") or 1, pair = keys.Pair == "1" }
            table.insert(cfg.list, a)
            cfg.total = cfg.total + a.weight
        end
    end
    table.sort(cfg.list, function(a, b) return a.name < b.name end)
    log("activities: ambient %s (%d activities, every %d s)", cfg.on and "on" or "off", #cfg.list, cfg.every)
    if not cfg.on or #cfg.list == 0 then return end
    WaCa.On("ScreenShown", function(screen)
        if running or not screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then return end
        running = true
        generation = generation + 1
        schedule(generation)
    end)
    WaCa.On("ScreenHidden", function(screen)
        if not screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then return end
        running = false
    end)
end

return Activities
