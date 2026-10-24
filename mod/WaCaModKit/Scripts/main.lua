-- WaCa ModKit (Lua half). Key bindings live in the native half (config/keybinds.ini); this script applies
-- config/text.ini (text overrides), config/names.ini (your cat's free-form name) and config/appearance.ini (colours
-- and pattern packs).
local VERSION = "0.3.0"
local WaCa = require("WaCa")

local modDir = debug.getinfo(1, "S").source:match("^@(.+)[/\\]Scripts[/\\]main%.lua$") or "."
local function log(fmt, ...) print(string.format("[WaCaModKit] " .. fmt .. "\n", ...)) end
log("%s loaded", VERSION)

-- config/text.ini: [Text] KEY = new text
local function applyTextOverrides()
    local ini = WaCa.ReadIni(modDir .. "/config/text.ini")
    local section = ini and ini["Text"]
    if not section then return end
    local n = 0
    for _, key in ipairs(section.__order) do
        if WaCa.SetText(key, section[key]) then n = n + 1 else log("text override %s did not apply", key) end
    end
    log("%d text overrides applied", n)
end

-- Free-form name (config/names.ini [Player] Prefix = ..., optional Suffix = ...). The game names a cat
-- <prefix><suffix>, both picked from its tables and stored as ids (PrefixNameId "STR_CAT_NAME12", SuffixNameId
-- "_PAW"); each combination is its own text entry ("STR_CAT_NAME12_PAW" = "Mosspaw"). We rewrite the entry of the
-- player's CURRENT name only (another cat may share the prefix with another suffix), and put the old one back when
-- the name changes (a new rank). The save keeps the game's ids: online content and uninstalling see the generated
-- name.
local appliedKey, appliedText, originalText = nil, nil, nil

local function playerCustomData()
    local pc = FindFirstOf("PlayerController")
    if not pc or not pc:IsValid() then return nil end
    local pawn = pc.Pawn
    if not pawn or not pawn:IsValid() then return nil end
    for _, comp in ipairs(FindAllOf("SwtAdventureCustomizableMeshComponent") or {}) do
        if comp:IsValid() and comp:GetOwner():GetFullName() == pawn:GetFullName() then return comp.CustomData end
    end
    return nil
end

-- the generated prefix's text: what "<prefix>kit" and "<prefix>paw" have in common ("Woodkit", "Woodpaw" -> "Wood");
-- remembered per prefix the first time, before any entry of it is rewritten
local generatedPrefixes = {}
local function generatedPrefix(prefixId)
    if generatedPrefixes[prefixId] then return generatedPrefixes[prefixId] end
    local a, b = WaCa.GetText(prefixId .. "_KIT"), WaCa.GetText(prefixId .. "_PAW")
    local n = 0
    while n < #a and n < #b and a:sub(n + 1, n + 1) == b:sub(n + 1, n + 1) do n = n + 1 end
    generatedPrefixes[prefixId] = a:sub(1, n)
    return generatedPrefixes[prefixId]
end

local function applyName()
    local ini = WaCa.ReadIni(modDir .. "/config/names.ini")
    local cfg = ini and ini["Player"] or {}
    local custom, ownSuffix = cfg.Prefix or "", cfg.Suffix or ""
    local data = playerCustomData()
    if not data then return end
    local prefixId, suffixId = data.PrefixNameId:ToString(), data.SuffixNameId:ToString()
    if prefixId == "" then return end
    local key = prefixId .. suffixId
    if key ~= appliedKey and appliedKey then
        WaCa.SetText(appliedKey, originalText)        -- the previous form (old rank) back to the game's text
        appliedKey, appliedText, originalText = nil, nil, nil
    end
    local generated = generatedPrefix(prefixId)
    local original = key == appliedKey and originalText or WaCa.GetText(key)
    if custom == "" then
        if appliedKey then WaCa.SetText(appliedKey, originalText); appliedKey, appliedText, originalText = nil, nil, nil end
        return
    end
    if generated == "" or original:sub(1, #generated) ~= generated then return end
    local suffix = original:sub(#generated + 1)
    -- your own warrior suffix (names.ini Suffix) replaces the game's once you have one (not as a kit / apprentice)
    if ownSuffix ~= "" and suffixId ~= "_KIT" and suffixId ~= "_PAW" then suffix = ownSuffix end
    local name = custom .. suffix
    if key == appliedKey and name == appliedText then return end
    if WaCa.SetText(key, name) then
        appliedKey, appliedText, originalText = key, name, original
        log("your name: %s (the game's: %s)", name, original)
    end
end

-- Appearance (config/appearance.ini [Player]): any colour for each coat slot, and pattern packs for the coat's mask
-- slots. Applied to your cat and to the creation screen's preview; NPCs keep theirs. Only what you see changes.
local modsDir = modDir:match("^(.+)[/\\][^/\\]+$") or modDir
local appearanceStamp = nil

-- config/appearance.ini [Player], on top of an optional look preset (Look = Colourpoint -> looks/Colourpoint.ini,
-- or "<Mod>/<path>.ini" in another mod's folder): your own values win over the look's
local function readAppearance()
    local ini = WaCa.ReadIni(modDir .. "/config/appearance.ini")
    local own = ini and ini["Player"] or {}
    local cfg, order = {}, {}
    local look = own.Look or ""
    if look ~= "" then
        local path = look:find("[/\\]") and (modsDir .. "/" .. look) or (modDir .. "/looks/" .. look .. ".ini")
        local lookIni = WaCa.ReadIni(path)
        local l = lookIni and lookIni["Look"]
        if l then
            for _, k in ipairs(l.__order) do cfg[k] = l[k]; table.insert(order, k) end
        else
            log("look '%s' not found (%s)", look, path)
        end
    end
    for _, k in ipairs(own.__order or {}) do
        if own[k] ~= "" then
            if cfg[k] == nil then table.insert(order, k) end
            cfg[k] = own[k]
        end
    end
    local stamp = {}
    for _, k in ipairs(order) do table.insert(stamp, k .. "=" .. cfg[k]) end
    return cfg, table.concat(stamp, ";")
end

-- a mask source: "game:<name>" as is; a folder in WaCaModKit/patterns; or "<Mod>/<path>" inside another mod's folder
local function maskSource(name)
    if name:match("^game:") then return name end
    if name:find("[/\\]") then return modsDir .. "/" .. name end
    return modDir .. "/patterns/" .. name
end

local function applyAppearanceTo(cat, cfg)
    -- whole-cat colours first, then per-part ones ("Tail.Fur = #...") on top
    for slot in pairs(WaCa.COAT_COLORS) do
        local color = WaCa.ParseColor(cfg[slot])
        if color then WaCa.SetCatColor(cat, slot, color) end
    end
    for key, value in pairs(cfg) do
        local partName, slot = tostring(key):match("^(%a+)%.(%a+)$")
        if partName and WaCa.PART_NAMES[partName] and WaCa.COAT_COLORS[slot] then
            local color = WaCa.ParseColor(value)
            if color then WaCa.SetPartColor(cat, partName, slot, color) end
        end
    end
    for slot in pairs(WaCa.COAT_MASKS) do
        local source = cfg[slot .. "Mask"]
        if source and source ~= "" then
            if WaCa.SetCatMask(cat, slot, maskSource(source)) == 0 then log("%s mask '%s': no masks found", slot, source) end
        end
    end
end

-- true when the cat already shows our first configured colour (the game rebuilds materials on some refreshes)
local function showsAppearance(cat, cfg)
    for slot, param in pairs(WaCa.COAT_COLORS) do
        local want = WaCa.ParseColor(cfg[slot])
        if want then
            for _, part in ipairs(WaCa.CatParts(cat)) do
                local m = part:GetMaterial(0)
                if not m or not m:IsValid() or m:GetClass():GetFName():ToString() ~= "MaterialInstanceDynamic" then return false end
                local v = m:K2_GetVectorParameterValue(FName(param))
                return math.abs(v.R - want.X) < 0.002 and math.abs(v.G - want.Y) < 0.002 and math.abs(v.B - want.Z) < 0.002
            end
        end
    end
    return false
end

local appliedCats = {}
local function applyAppearance(force)
    local cfg, stamp = readAppearance()
    if stamp == "" then return end
    if stamp ~= appearanceStamp then appearanceStamp, appliedCats, force = stamp, {}, true end
    for _, cat in ipairs(WaCa.PlayerCats()) do
        local id = cat:GetFullName()
        if force or not appliedCats[id] or not showsAppearance(cat, cfg) then
            applyAppearanceTo(cat, cfg)
            if not appliedCats[id] then log("appearance applied to %s", id:match("([^.:]+)$") or id) end
            appliedCats[id] = true
        end
    end
end

-- straight after the game refreshes a cat's look
for _, fn in ipairs({ "/Script/SwtAdventure.SwtAdventureCustomizableMeshComponent:RefreshShape",
                      "/Script/Wrc.GuiCatCustomActor:RefreshPattern", "/Script/Wrc.GuiCatCustomActor:RefreshShape",
                      "/Script/Wrc.GuiCatCustomActor:SetCustomDataFromSave" }) do
    pcall(RegisterHook, fn, function() end, function() ExecuteInGameThread(function() applyAppearance(true) end) end)
end

-- wait for the game's text, then apply; the name is checked every few seconds (it changes with your rank)
local textApplied = false
LoopAsync(2000, function()
    ExecuteInGameThread(function()
        if not WaCa.IsTextReady() then return end
        if not textApplied then
            textApplied = true
            applyTextOverrides()
        end
        applyName()
        applyAppearance(false)
    end)
    return false
end)
