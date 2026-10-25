-- WaCa ModKit (Lua half). Key bindings live in the native half (config/keybinds.ini); this script applies
-- config/text.ini (text overrides), config/names.ini (your cat's free-form name) and config/appearance.ini (colours
-- and pattern packs).
local VERSION = "0.5.4"
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

-- Per-save data: the active save slot's own name / look, in a sidecar next to the game's save
-- (SaveGames/WrcGame.<save>-<character slot>.WaCaModKit.ini: [Name] Prefix / Suffix, [Appearance] the appearance.ini keys). A slot's
-- values win over config/names.ini and config/appearance.ini (the defaults for saves without their own). Changes made
-- in-game are written when the GAME saves - quitting without saving drops them, like the game's own changes.
local SLOT_HEADER = "; WaCa ModKit - this save slot's extra character data (written by the mod; the game's save is untouched)"
local slot = { id = nil, data = {}, dirty = false }
local onSlotChanged = {}          -- callbacks(newSlotId): the name / look state of the previous slot is reset

local function loadSlot(id)
    slot.id, slot.dirty = id, false
    slot.data = (id and WaCa.ReadIni(WaCa.SlotFile("WaCaModKit", id))) or nil
    -- 0.5.0 - 0.5.3 named character slot 0's sidecar after the save GUID alone: read it (written under the new name)
    local legacy = id and id:match("^(.+)%-0$")
    if not slot.data and legacy then
        slot.data = WaCa.ReadIni(WaCa.SlotFile("WaCaModKit", legacy))
        if slot.data then slot.dirty = true; log("save slot %s: read the old-style sidecar %s", id, legacy) end
    end
    slot.data = slot.data or {}
    slot.data[""] = nil
    for _, fn in ipairs(onSlotChanged) do fn(id) end
    if id then
        local n = 0
        for _, section in pairs(slot.data) do n = n + #(section.__order or {}) end
        log("save slot %s: %d values from its sidecar", id, n)
    end
end

local function saveSlot()
    if not slot.id or not slot.dirty then return end
    if WaCa.WriteIni(WaCa.SlotFile("WaCaModKit", slot.id), slot.data, SLOT_HEADER) then
        slot.dirty = false
        log("save slot %s: sidecar written", slot.id)
    end
end

-- a value of the active slot (nil when it has none)
local function slotValue(section, key)
    local t = slot.data[section]
    local v = t and t[key]
    if v == "" then return nil end
    return v
end

-- set / clear (nil) a value of the active slot; written with the game's next save
local function setSlotValue(section, key, value)
    if not slot.id then return false end
    local t = slot.data[section]
    if not t then
        t = { __order = {} }
        slot.data[section] = t
    end
    if t[key] == nil and value ~= nil then table.insert(t.__order, key) end
    t[key] = value
    slot.dirty = true
    return true
end

local function checkSlot()
    local id = WaCa.CurrentSlot()
    if id ~= slot.id then loadSlot(id) end
end

pcall(RegisterHook, "/Script/SwtEngine.SwtSaveManager:Save", function() end, function()
    ExecuteInGameThread(function() checkSlot(); saveSlot() end)
end)
-- the save manager's slot calls, logged (the character-slot flow is otherwise invisible in a player's log)
for _, fn in ipairs({ "SetSaveSlot", "K2_CreateSaveSlot", "Load", "ResetSave" }) do
    pcall(RegisterHook, "/Script/SwtEngine.SwtSaveManager:" .. fn, function() end, function()
        ExecuteInGameThread(function()
            log("save manager: %s (now %s)", fn, tostring(WaCa.CurrentSlot()))
            checkSlot()
        end)
    end)
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

local generatedPrefix = WaCa.NamePrefixText

-- another save loaded: the previous cat's rewritten entry goes back to the game's text
table.insert(onSlotChanged, function()
    if appliedKey then WaCa.SetText(appliedKey, originalText) end
    appliedKey, appliedText, originalText = nil, nil, nil
end)

local function applyName()
    local ini = WaCa.ReadIni(modDir .. "/config/names.ini")
    local cfg = ini and ini["Player"] or {}
    -- the save slot's own name wins over names.ini
    local custom = slotValue("Name", "Prefix") or cfg.Prefix or ""
    local ownSuffix = slotValue("Name", "Suffix") or cfg.Suffix or ""
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
-- A look is a file of appearance values (looks/<Name>.ini [Look], or "<Mod>/<path>.ini"). It applies through
-- Look = <Name>, or - for a look that is a pattern / marking shape (its "Row = Pattern" / "Row = Markings") - through
-- PatternMask / MarkingsMask = look:<Name>, so it is one choice among that row's shapes. The player's own values win.
local function mergeLook(own)
    local cfg, order = {}, {}
    local function add(k, v)
        if cfg[k] == nil then table.insert(order, k) end
        cfg[k] = v
    end
    local function addLook(look)
        local path = look:find("[/\\]") and (modsDir .. "/" .. look) or (modDir .. "/looks/" .. look .. ".ini")
        local lookIni = WaCa.ReadIni(path)
        local l = lookIni and lookIni["Look"]
        if not l then log("look '%s' not found (%s)", look, path) return end
        for _, k in ipairs(l.__order) do if k ~= "Row" then add(k, l[k]) end end
    end
    if (own.Look or "") ~= "" then addLook(own.Look) end
    for _, slot in ipairs({ "PatternMask", "MarkingsMask" }) do
        local name = own[slot] and tostring(own[slot]):match("^look:(.+)$")
        if name then addLook(name) end
    end
    for _, k in ipairs(own.__order or {}) do
        local v = own[k]
        if v ~= nil and v ~= "" and not tostring(v):match("^look:") then add(k, v) end
    end
    local stamp = {}
    for _, k in ipairs(order) do table.insert(stamp, k .. "=" .. cfg[k]) end
    return cfg, table.concat(stamp, ";")
end

local Creator = require("creator")

local function readAppearance()
    -- while creating a cat, the look chosen in the creator; else the save slot's own look (its [Appearance] section),
    -- which replaces appearance.ini as a whole
    local own = Creator.PendingLook() or slot.data["Appearance"]
    if not own or #(own.__order or {}) == 0 then
        local ini = WaCa.ReadIni(modDir .. "/config/appearance.ini")
        own = ini and ini["Player"] or {}
    end
    return mergeLook(own)
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
    -- a per-part value may name a coat colour instead of a hex ("Tail.Fur = Pattern": the tail in the pattern's
    -- colour, whatever the colour picker chose) - read from the body after the whole-cat colours went on
    local body = cat.SkelMeshComp
    local function coatColor(slotName)
        local own = WaCa.ParseColor(cfg[slotName])
        if own then return own end
        local m = body and body:IsValid() and body:GetMaterial(0)
        if not m or not m:IsValid() then return nil end
        local v = m:K2_GetVectorParameterValue(FName(WaCa.COAT_COLORS[slotName]))
        return { X = v.R, Y = v.G, Z = v.B }
    end
    for key, value in pairs(cfg) do
        local partName, slot = tostring(key):match("^(%a+)%.(%a+)$")
        if partName and WaCa.PART_NAMES[partName] and WaCa.COAT_COLORS[slot] then
            local color = WaCa.COAT_COLORS[value] and coatColor(value) or WaCa.ParseColor(value)
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
-- the body's material (dynamic), or nil
local function bodyMaterial(cat)
    local body = cat.SkelMeshComp
    if not body or not body:IsValid() then return nil end
    local m = body:GetMaterial(0)
    if not m or not m:IsValid() or m:GetClass():GetFName():ToString() ~= "MaterialInstanceDynamic" then return nil end
    return m
end

-- true when the cat still shows the configured look: every configured colour and every configured mask on its body
-- (the game rebuilds materials on refreshes, and loads a newly chosen pattern texture a moment later - after which
-- our mask has to go on again)
local function showsAppearance(cat, cfg)
    local m = bodyMaterial(cat)
    if not m then return false end
    local checked = false
    for slot, param in pairs(WaCa.COAT_COLORS) do
        local want = WaCa.ParseColor(cfg[slot])
        if want then
            local v = m:K2_GetVectorParameterValue(FName(param))
            if math.abs(v.R - want.X) > 0.002 or math.abs(v.G - want.Y) > 0.002 or math.abs(v.B - want.Z) > 0.002 then return false end
            checked = true
        end
    end
    for slot, param in pairs(WaCa.COAT_MASKS) do
        local source = cfg[slot .. "Mask"]
        local game = source and source:match("^game:(.+)$")
        if game then
            local t = m:K2_GetTextureParameterValue(FName(param))
            local want = string.format("T_Cat_Body_%s_M", game)
            if not t or not t:IsValid() or t:GetFName():ToString() ~= want then return false end
            checked = true
        elseif source and source ~= "" then
            return false          -- a PNG pack: no cheap check - applied every pass
        end
    end
    return checked
end

local appliedCats = {}
table.insert(onSlotChanged, function() appearanceStamp, appliedCats = nil, {} end)
local function applyAppearance(force)
    local cfg, stamp = readAppearance()
    if stamp == "" then return end
    if stamp ~= appearanceStamp then appearanceStamp, appliedCats, force = stamp, {}, true end
    local creating = Creator.IsOpen()
    for _, cat in ipairs(WaCa.PlayerCats(creating)) do
        local id = cat:GetFullName()
        if force or not appliedCats[id] or not showsAppearance(cat, cfg) then
            applyAppearanceTo(cat, cfg)
            if not appliedCats[id] then log("appearance applied to %s", id:match("([^.:]+)$") or id) end
            appliedCats[id] = true
        end
    end
    -- the creator closed: a preview cat that got our look goes back to the game's own (the game reuses that actor
    -- for other cats, e.g. Dapplepatch on "Select Your Cat")
    if not creating then
        for _, preview in ipairs(FindAllOf("GuiCatCustomActor") or {}) do
            local comp = preview:IsValid() and preview.CustomizableMeshComponent
            local id = comp and comp:IsValid() and comp:GetFullName()
            if id and appliedCats[id] then
                appliedCats[id] = nil
                pcall(function() preview:RefreshPattern() end)
                log("creator closed: the preview cat is back to the game's look")
            end
        end
    end
end

-- The game's procedural cats: doubled names fixed, pinned cats from config/roster.ini (roster.lua)
local Roster = require("roster")
Roster.Init({
    WaCa = WaCa, log = log, modDir = modDir, modsDir = modsDir,
    applyLook = function(cat, section) applyAppearanceTo(cat, (mergeLook(section))) end,
})
table.insert(onSlotChanged, function() Roster.Run(true) end)

-- The character creator: extra palette colours + the name field (creator.lua)
Creator.Init({
    WaCa = WaCa, log = log, modDir = modDir, setSlotValue = setSlotValue, slotValue = slotValue,
    refreshLook = function() applyAppearance(true) end,
    writeSlot = function() slot.dirty = true; saveSlot() end,
    slotId = function() return slot.id end,
})
table.insert(onSlotChanged, Creator.OnSlotChanged)

-- straight after the game refreshes a cat's look
for _, fn in ipairs({ "/Script/SwtAdventure.SwtAdventureCustomizableMeshComponent:RefreshShape",
                      "/Script/Wrc.GuiCatCustomActor:RefreshPattern", "/Script/Wrc.GuiCatCustomActor:RefreshShape",
                      "/Script/Wrc.GuiCatCustomActor:SetCustomDataFromSave" }) do
    pcall(RegisterHook, fn, function() end, function() ExecuteInGameThread(function() applyAppearance(true) end) end)
end

-- Key aliases (config/keybinds.ini [KeyAliases] Key = OtherKey[, ...]): pressing Key also presses OtherKey. The game's
-- menus read raw keys (SwtPlayerController.OnKeyPressed / OnKeyReleased) rather than bindings - many use BackSpace as
-- "back" - so "Escape = BackSpace" makes Escape work as back in menus too.
local aliases = {}
local function loadAliases()
    local ini = WaCa.ReadIni(modDir .. "/config/keybinds.ini")
    aliases = {}
    for _, k in ipairs(ini and ini["KeyAliases"] and ini["KeyAliases"].__order or {}) do
        local targets = {}
        for t in ini["KeyAliases"][k]:gmatch("[^,%s]+") do table.insert(targets, t) end
        aliases[k] = targets
    end
end
loadAliases()

local inAlias = false
local function aliasHook(fnName)
    return function(self, key)
        if inAlias then return end
        local ok, name = pcall(function() return key:get().KeyName:ToString() end)
        if not ok or not aliases[name] then return end
        local controller = self:get()
        inAlias = true
        for _, target in ipairs(aliases[name]) do
            pcall(function() controller[fnName](controller, { KeyName = FName(target) }) end)
        end
        inAlias = false
    end
end
for _, fn in ipairs({ "OnKeyPressed", "OnKeyReleased", "OnKeyRepeat" }) do
    local ok, err = pcall(RegisterHook, "/Script/SwtEngine.SwtPlayerController:" .. fn, aliasHook(fn))
    if not ok then log("key aliases: could not hook %s (%s)", fn, tostring(err)) end
end
local n = 0
for _ in pairs(aliases) do n = n + 1 end
log("%d key aliases", n)

-- Menu keys (config/keybinds.ini [UIKeys] Row = Key): the menus' own keyboard keys and hint icons
local function applyUIKeys()
    local ini = WaCa.ReadIni(modDir .. "/config/keybinds.ini")
    local keys, icons = ini and ini["UIKeys"], ini and ini["UIIcons"]
    for _, row in ipairs(keys and keys.__order or {}) do
        if not WaCa.SetUIKey(row, keys[row]) then log("menu key %s: the key table is not loaded", row) end
    end
    for _, row in ipairs(icons and icons.__order or {}) do
        if not WaCa.SetUIIcon(row, icons[row]) then log("menu icon %s: no icon for %s", row, icons[row]) end
    end
    log("%d menu keys, %d menu icons set", keys and #keys.__order or 0, icons and #icons.__order or 0)
end

-- Every loop runs ON THE GAME THREAD (LoopInGameThreadWithDelay). LoopAsync runs its callback on a worker thread with
-- the same Lua state the game-thread hooks use; the two at once corrupted Lua's tables and crashed the game inside
-- the Lua VM (operator 2026-10-25: after a while cycling patterns in the creator; reproduced headless with F6 x 75).
local Menus = require("menus")
Menus.Init({ WaCa = WaCa, log = log, modDir = modDir })

LoopInGameThreadWithDelay(300, function()
    local ok, err = pcall(Creator.FastTick)
    if not ok then log("creator tick: %s", tostring(err)) end
    ok, err = pcall(Menus.Tick)
    if not ok then log("menu tick: %s", tostring(err)) end
end)

-- wait for the game's text, then apply; the name is checked every few seconds (it changes with your rank)
local textApplied = false
local function slowTick()
    if not WaCa.IsTextReady() then return end
    if not textApplied then
        textApplied = true
        applyTextOverrides()
        applyUIKeys()
    end
    checkSlot()
    Creator.Tick()
    local cat = playerCustomData()
    if cat then Creator.OnPlayerCat(cat) end
    applyName()
    applyAppearance(false)
    Roster.Run(false)
end
LoopInGameThreadWithDelay(2000, function()
    local ok, err = pcall(slowTick)
    if not ok then log("tick: %s", tostring(err)) end
end)
