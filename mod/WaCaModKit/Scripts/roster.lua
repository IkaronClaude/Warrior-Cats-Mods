-- The game's procedural cats: fixes, and fixed ("pinned") cats for specific roles.
--
-- The generator (UWrcNPCGenerationManager) keeps the generated cats per rank (NPCClansData: EGiverRole -> list of
-- FCatCustomData, each with its ClanType) and the story cats per story role (NarrativeCustomDataMap: ENarrativeRole ->
-- FCatCustomData). Spawned NPCs carry a copy in their SwtAdventureCustomizableMeshComponent.CustomData. All of it is
-- saved by the game, so everything here only ever writes VANILLA values (existing name ids, table indices): the save
-- stays valid without the mod.
--
-- 1. Doubled names: a suffix that repeats the prefix ("Blaze" + "blaze") is replaced by another suffix that cats of
--    the same rank already use - picked deterministically from the prefix, so the same cat always gets the same name.
-- 2. Pinned cats (config/roster.ini lists roster files): a section per cat -
--      [Narrative.ThunderClanDeputy]   a story cat (wacaroles.lua: ENarrativeRole)
--      [ThunderClan.Leader]            the first cat of that rank in that clan (EClanType . EGiverRole)
--      [ThunderClan.Warrior.3]         the third one
--    keys: any FCatCustomData field (WaCa.CAT_DATA_FIELDS: FurColorIdx = 4, PatternIdx = 12, BodyValue = 3, CatSize =
--    1.1, AccesoryHeadId = ..., PrefixNameId = STR_CAT_NAME12, SuffixNameId = _HEART ...), Name = <any text> (the
--    shown name), and the appearance.ini keys (Fur = #hex, Tail.Fur, MarkingsMask = game:M12_Mask, Look = ...).
local Roster = {}
local roles = require("wacaroles")

local WaCa, log, modDir, modsDir, applyLook
local fieldSet = {}

local function enumName(enum, value)
    for k, v in pairs(roles[enum]) do if v == value then return k end end
    return tostring(value)
end

local function hash(s)
    local h = 7
    for i = 1, #s do h = (h * 31 + s:byte(i)) % 2147483647 end
    return h
end

local function isDoubled(prefixId, suffixId)
    if suffixId == "_KIT" or suffixId == "_PAW" then return false end
    local p, s = WaCa.NamePrefixText(prefixId):lower(), WaCa.NameSuffixText(prefixId, suffixId):lower()
    return p ~= "" and p == s
end

-- FCatCustomData values from a proxy, as plain strings
local function str(v) return v and v.ToString and v:ToString() or tostring(v) end

-- the generator's lists: calls fn(data, rank value, index within its clan + rank) for every generated cat
local function eachGenerated(manager, fn)
    local counters = {}
    manager.NPCClansData:ForEach(function(k, v)
        local rank = k:get()
        v:get().CustomDataArray:ForEach(function(_, e)
            local d = e:get()
            local key = tostring(d.ClanType) .. "." .. tostring(rank)
            counters[key] = (counters[key] or 0) + 1
            fn(d, rank, counters[key])
        end)
    end)
end

-- the suffixes each rank uses (for replacing a doubled one with a natural choice)
local function suffixPools(manager)
    local pools = {}
    eachGenerated(manager, function(d, rank)
        local s = str(d.SuffixNameId)
        pools[rank] = pools[rank] or { set = {}, list = {} }
        if s ~= "" and not pools[rank].set[s] then
            pools[rank].set[s] = true
            table.insert(pools[rank].list, s)
        end
    end)
    for _, p in pairs(pools) do table.sort(p.list) end
    return pools
end

local renamed = {}   -- old full key -> new suffix id (also applied to spawned NPCs with that name)
local function fixDoubled(d, rank, pools)
    local prefixId, suffixId = str(d.PrefixNameId), str(d.SuffixNameId)
    if prefixId == "" or not isDoubled(prefixId, suffixId) then return end
    local pool = pools[rank] or pools[roles.EGiverRole.Warrior] or { list = {} }
    local candidates = {}
    for _, s in ipairs(pool.list) do
        if not isDoubled(prefixId, s) and s ~= "_KIT" and s ~= "_PAW" then table.insert(candidates, s) end
    end
    if #candidates == 0 then return end
    local new = candidates[hash(prefixId) % #candidates + 1]
    renamed[prefixId .. suffixId] = new
    d.SuffixNameId = new
    log("renamed %s -> %s (doubled name)", WaCa.GetText(prefixId .. suffixId), WaCa.GetText(prefixId .. new))
end

-- the active roster sections, merged in config/roster.ini's order (later files win per key)
local function loadRosters()
    local cfg = WaCa.ReadIni(modDir .. "/config/roster.ini")
    local list = cfg and cfg["Roster"] and cfg["Roster"].Rosters or ""
    local sections = {}
    for name in list:gmatch("[^,]+") do
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        local path = name:find("[/\\]") and (modsDir .. "/" .. name) or (modDir .. "/rosters/" .. name .. ".ini")
        local ini = WaCa.ReadIni(path)
        if not ini then
            log("roster '%s' not found (%s)", name, path)
        else
            for section, t in pairs(ini) do
                if section ~= "" then
                    sections[section] = sections[section] or { __order = {} }
                    for _, k in ipairs(t.__order) do
                        if sections[section][k] == nil then table.insert(sections[section].__order, k) end
                        sections[section][k] = t[k]
                    end
                end
            end
        end
    end
    return sections
end

local pinnedLooks = {}   -- full name key -> roster section (for its appearance keys, applied to the spawned NPC)

local function pin(d, section, label)
    local before = str(d.PrefixNameId) .. str(d.SuffixNameId)
    for _, k in ipairs(section.__order) do
        if fieldSet[k] then
            local v = section[k]
            local cur = d[k]
            if type(cur) == "boolean" then v = (v == "true" or v == "1")
            elseif type(cur) == "number" then v = tonumber(v) end
            if v ~= nil then pcall(function() d[k] = v end) end
        end
    end
    local key = str(d.PrefixNameId) .. str(d.SuffixNameId)
    if section.Name and section.Name ~= "" and WaCa.GetText(key) ~= section.Name then WaCa.SetText(key, section.Name) end
    pinnedLooks[key] = section
    if before ~= key then renamed[before] = str(d.SuffixNameId) end
    return label
end

-- copy the pinned / fixed values onto one spawned NPC's own data (it was copied from the generator at spawn)
local function syncCat(comp)
    if not comp or not comp:IsValid() then return end
    local d = comp.CustomData
    local prefixId, suffixId = str(d.PrefixNameId), str(d.SuffixNameId)
    local key = prefixId .. suffixId
    local changed = false
    if renamed[key] then
        d.SuffixNameId = renamed[key]
        key = prefixId .. renamed[key]
        changed = true
    end
    local section = pinnedLooks[key]
    if section then
        for _, k in ipairs(section.__order) do
            if fieldSet[k] and k ~= "PrefixNameId" and k ~= "SuffixNameId" then
                local v = section[k]
                local cur = d[k]
                if type(cur) == "boolean" then v = (v == "true" or v == "1")
                elseif type(cur) == "number" then v = tonumber(v) end
                if v ~= nil and cur ~= v then pcall(function() d[k] = v end) changed = true end
            end
        end
        applyLook(comp, section)
    end
    if changed then pcall(function() comp:RefreshShape() end) end
end

-- every cat already in the world (after the generator ran: the ones spawned before it)
local function syncSpawned()
    for _, comp in ipairs(FindAllOf("SwtAdventureCustomizableMeshComponent") or {}) do syncCat(comp) end
end

-- a cat began play (the CatSpawned event): its own copy of the data gets the pinned / fixed values
function Roster.SyncCat(comp)
    syncCat(comp)
end

local lastStamp = nil
-- one pass over the generator's cats; cheap when nothing changed (force = after a generation / a load)
function Roster.Run(force)
    local manager = FindFirstOf("WrcNPCGenerationManager")
    if not manager or not manager:IsValid() then return end
    local count = 0
    pcall(function() eachGenerated(manager, function() count = count + 1 end) end)
    if count == 0 then return end
    local stamp = tostring(count) .. "/" .. tostring(WaCa.CurrentSlot())
    if not force and stamp == lastStamp then
        syncSpawned()
        return
    end
    lastStamp = stamp
    local sections = loadRosters()
    local pools = suffixPools(manager)
    local pinned = {}
    eachGenerated(manager, function(d, rank, index)
        local clan = enumName("EClanType", d.ClanType)
        local rankName = enumName("EGiverRole", rank)
        local section = sections[clan .. "." .. rankName .. "." .. index] or (index == 1 and sections[clan .. "." .. rankName])
        if section then table.insert(pinned, pin(d, section, clan .. "." .. rankName .. "." .. index))
        else fixDoubled(d, rank, pools) end
    end)
    manager.NarrativeCustomDataMap:ForEach(function(k, v)
        local d = v:get()
        local section = sections["Narrative." .. enumName("ENarrativeRole", k:get())]
        if section then table.insert(pinned, pin(d, section, "Narrative." .. enumName("ENarrativeRole", k:get())))
        else fixDoubled(d, d.Role, pools) end
    end)
    log("procedural cats: %d checked, %d pinned%s", count, #pinned, #pinned > 0 and (" (" .. table.concat(pinned, ", ") .. ")") or "")
    syncSpawned()
end

function Roster.Init(ctx)
    WaCa, log, modDir, modsDir, applyLook = ctx.WaCa, ctx.log, ctx.modDir, ctx.modsDir, ctx.applyLook
    for _, f in ipairs(WaCa.CAT_DATA_FIELDS) do fieldSet[f] = true end
    pcall(RegisterHook, "/Script/SwtQuest.QuestManager:OnNPCGenerationCompleted", function() end, function()
        ExecuteInGameThread(function() Roster.Run(true) end)
    end)
end

return Roster
