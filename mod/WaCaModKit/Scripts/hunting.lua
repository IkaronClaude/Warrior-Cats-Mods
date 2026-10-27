-- Hunting (tickets.md 9, hunting rework).
-- Hunting by chance (operator 2026-10-27): the game's prey instakill no longer always works - the moment the cat lands
-- on the prey is rolled natively (hunt.cpp): chance = the cat's base chance by rank x the prey's factor by its kind,
-- never above 100% - critical miss. config/hunting.ini [Chance]: On, critical miss, per-rank chances, per-prey
-- factors (by the game's own prey kind names, ESwtQuestCharacterType - resolved from the enum, never copied).
-- Prey flee (EXPERIMENTAL, off): pounce prey that notices your cat runs away (prey.cpp) - not the open world's prey.
local Hunting = {}

local WaCa, log, modDir
local cfg = { flee = false, distance = 2500, speed = 1.0 }
local chance = { on = false, critMiss = 5, ranks = {}, factors = {}, kinds = {}, rank = nil, ifUnknown = nil, exp = true }
local hooked, huntHooked = false, false
local boosted = {}               -- prey -> its speed was raised once

local function pathOf(fullName) return (tostring(fullName):gsub("^%S+ ", "")) end

local function flee(preyName, catName)
    local prey, cat = StaticFindObject(pathOf(preyName)), StaticFindObject(pathOf(catName))
    if not (prey and prey:IsValid() and cat and cat:IsValid()) then return end
    local ok, err = pcall(function()
        local p, c = prey:K2_GetActorLocation(), cat:K2_GetActorLocation()
        local dx, dy = p.X - c.X, p.Y - c.Y
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 1 then dx, dy, len = 1, 0, 1 end
        local to = { X = p.X + dx / len * cfg.distance, Y = p.Y + dy / len * cfg.distance, Z = p.Z }
        local id = prey:GetFullName()
        if cfg.speed ~= 1.0 and not boosted[id] then
            boosted[id] = true
            pcall(function() prey.CharacterMovement.MaxWalkSpeed = prey.CharacterMovement.MaxWalkSpeed * cfg.speed end)
        end
        StaticFindObject("/Script/AIModule.Default__AIBlueprintHelperLibrary"):SimpleMoveToLocation(prey:GetController(), to)
        log("prey: %s flees from %s (%.0f units away)", prey:GetFName():ToString(), cat:GetFName():ToString(), cfg.distance)
    end)
    if not ok then log("prey: flee failed (%s)", tostring(err)) end
end

-- the game's prey kinds by name -> value (the enum itself, so new kinds need no change here)
local function preyKinds()
    local kinds = {}
    pcall(function()
        StaticFindObject("/Script/SwtQuest.ESwtQuestCharacterType"):ForEachName(function(name, value)
            kinds[(name:ToString():gsub("^.*::", ""))] = value
        end)
    end)
    return kinds
end

-- the rank names the game uses (ECharacterRank) -> value
local function rankValues()
    local ranks = {}
    pcall(function()
        StaticFindObject("/Script/SwtQuest.ECharacterRank"):ForEachName(function(name, value)
            ranks[(name:ToString():gsub("^.*::", ""))] = value
        end)
    end)
    return ranks
end

-- the rolled kinds as "value=factor,...": [Chance] PreyKinds (each also covers its Weak* variant), factor from
-- [PreyFactor] (a Weak* variant takes its kind's unless named itself), else 1.0. Unlisted kinds (cats: the game's
-- sneak attack) are never rolled.
local function factorList()
    local out = {}
    for name, value in pairs(preyKinds()) do
        local base = name:gsub("^Weak", "")
        if chance.kinds[name] or chance.kinds[base] then
            table.insert(out, value .. "=" .. (chance.factors[name] or chance.factors[base] or 1.0))
        end
    end
    return table.concat(out, ",")
end

local function sendChance()
    local base = chance.ranks[chance.rank or chance.ifUnknown or ""]
    local on = chance.on and base ~= nil
    WaCa.Command(string.format("HuntRoll|%s|%s|%s|%s", on and "1" or "0", tostring(base or 100), tostring(chance.critMiss),
        factorList()))
    if chance.on and not base then log("hunting: the cat's rank isn't known yet - every hunt works as in the game") end
end

-- EXP for a catch: what a fight against that prey gives - the game's own combat EXP table (CombatBaseExperience,
-- rows by prey kind name: BaseExperience), added the way the game adds EXP (native, level-ups included)
local expTable
local function experienceFor(kindName)
    if not (expTable and expTable:IsValid()) then
        expTable = nil
        for _, t in ipairs(FindAllOf("DataTable") or {}) do
            if t:IsValid() and t:GetFName():ToString():find("CombatBaseExperience") then expTable = t break end
        end
    end
    if not expTable then return nil end
    local amount
    expTable:ForEachRow(function(name, row)
        if tostring(name) == kindName then amount = row.BaseExperience end
    end)
    return amount
end

function Hunting.GrantExperience(kindValue)
    local kindName
    for name, value in pairs(preyKinds()) do
        if value == kindValue then kindName = name end
    end
    local amount = kindName and experienceFor(kindName)
    if not amount then
        log("hunting: no EXP for prey kind %s (the combat EXP table %s)", tostring(kindName or kindValue),
            expTable and "has no row for it" or "isn't loaded")
        return
    end
    local ok, granted = pcall(function()
        for _, c in ipairs(FindAllOf("SwtPlayerController") or {}) do
            if c:IsValid() and c.Player and c.PlayerState and c.PlayerState:IsValid() then
                return WaCaNative_AddExperience(c.PlayerState.LevelComponent:GetAddress(), amount)
            end
        end
        return false
    end)
    log("hunting: +%d EXP for the %s (%s)", amount, kindName, ok and granted and "granted" or ("not granted: " .. tostring(granted)))
end

-- the cat's rank: the player state's OnRankChanged(newRank)
function Hunting.SetRank(value)
    for name, v in pairs(rankValues()) do
        if v == value then
            if chance.rank ~= name then log("hunting: the cat is %s now", name) end
            chance.rank = name
        end
    end
    sendChance()
end

function Hunting.Init(c)
    WaCa, log, modDir = c.WaCa, c.log, c.modDir
    local ini = WaCa.ReadIni(modDir .. "/config/hunting.ini") or {}
    local p = ini["Prey"] or {}
    cfg.flee = (p.Flee or "0") == "1"
    cfg.distance = tonumber(p.FleeDistance or "") or cfg.distance
    cfg.speed = tonumber(p.FleeSpeed or "") or cfg.speed
    WaCa.Command("PreyFlee|" .. (cfg.flee and "1" or "0") .. "|" .. (p.ExcludeTags or ""))
    if cfg.flee then
        -- the reaction is hooked from the first live prey (its vtable)
        WaCa.Watch("ReceiveBeginPlay", "/Script/Wrc.WrcPouncePrey", "WaCaPreySpawned", "post")
        WaCa.On("WaCaPreySpawned", function(prey)
            if hooked then return end
            hooked = true
            local ok = WaCaNative_HookPrey and WaCaNative_HookPrey(prey:GetAddress())
            log("prey: detection reaction hooked: %s", tostring(ok))
        end)
        WaCa.On("PreyFlee", function(_, preyName, catName) flee(preyName, catName) end)
    end

    local ch = ini["Chance"] or {}
    chance.on = (ch.On or "0") == "1"
    chance.critMiss = tonumber(ch.CriticalMiss or "") or chance.critMiss
    if (ch.RankIfUnknown or "") ~= "" then chance.ifUnknown = ch.RankIfUnknown end
    for kind in (ch.PreyKinds or ""):gmatch("[^,%s]+") do chance.kinds[kind] = true end
    chance.exp = (ch.Experience or "1") ~= "0"
    for name, v in pairs(ini["RankChance"] or {}) do
        if name ~= "__order" and tonumber(v) then chance.ranks[name] = tonumber(v) end
    end
    for name, v in pairs(ini["PreyFactor"] or {}) do
        if name ~= "__order" and tonumber(v) then chance.factors[name] = tonumber(v) end
    end
    log("hunting: by chance %s (critical miss %s%%, rank if unknown: %s)", chance.on and "on" or "off",
        tostring(chance.critMiss), tostring(chance.ifUnknown or "none"))
    if not chance.on then return end
    -- the landing is hooked from the first live prey component (its vtable), once the world is up
    local function hookFrom(component)
        if huntHooked or not (component and component:IsValid()) then return end
        huntHooked = true
        log("hunting: landing hooked: %s", tostring(WaCaNative_HookHunt and WaCaNative_HookHunt(component:GetAddress())))
        sendChance()
    end
    -- (the world's prey exist once the gameplay HUD is up)
    WaCa.On("ScreenShown", function(screen)
        if huntHooked or not screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then return end
        for _, comp in ipairs(FindAllOf("SwtAdventurePreyComponent") or {}) do
            if comp:IsValid() then hookFrom(comp) return end
        end
    end)
    for _, comp in ipairs(FindAllOf("SwtAdventurePreyComponent") or {}) do
        if comp:IsValid() then hookFrom(comp) break end
    end
    -- the cat's rank as the game saved it (WrcGame.json GameplayProgression.Rank): read on the first save of a character
    -- (the game saves right after loading one) and whenever the game saves a new rank (context "SavePlayerRank")
    local rankSlot
    WaCa.On("GameSaved", function(_, context)
        local slot = WaCa.CurrentSlot()
        if slot == rankSlot and not tostring(context):find("Rank") then return end
        local progress = WaCa.GameProgress()
        if progress and progress.Rank then
            rankSlot = slot
            Hunting.SetRank(math.floor(progress.Rank))
        end
    end)
    -- live too (a watched event carries no parameters - the rank needs the UFunction hook's)
    pcall(function()
        RegisterHook("/Script/Wrc.WrcPlayerState:OnRankChanged", function(_, newRank)
            local v = newRank:get()
            ExecuteInGameThread(function() Hunting.SetRank(v) end)
        end)
    end)
    WaCa.On("HuntCaught", function(_, prey, _, kind, pct)
        log("hunting: caught %s (chance %s%%)", pathOf(prey):match("[^.]+$"), pct)
        if chance.exp then Hunting.GrantExperience(tonumber(kind)) end
    end)
    WaCa.On("HuntMissed", function(_, prey, _, kind, pct)
        log("hunting: missed %s (chance %s%%) - it got away", pathOf(prey):match("[^.]+$"), pct)
    end)
end

return Hunting
