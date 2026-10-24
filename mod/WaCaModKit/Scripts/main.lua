-- WaCa ModKit (Lua half). Key bindings live in the native half (config/keybinds.ini); this script applies
-- config/text.ini (text overrides) and config/names.ini (your cat's free-form name).
local VERSION = "0.2.0"
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
    end)
    return false
end)
