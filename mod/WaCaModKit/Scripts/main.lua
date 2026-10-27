-- WaCa ModKit (Lua half). Key bindings live in the native half (config/keybinds.ini); this script applies
-- config/text.ini (text overrides), config/names.ini (your cat's free-form name) and config/appearance.ini (colours
-- and pattern packs).
local VERSION = "0.6.0"
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

local Creator = require("creator")

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

-- the game saves from native code (a RegisterHook on SwtSaveManager:Save never saw those): WaCaNative raises
-- GameSaved after every save, whoever called it
WaCa.On("GameSaved", function(_, context)
    log("game saved (%s, slot %s)%s", tostring(context), tostring(WaCa.CurrentSlot()),
        slot.dirty and " - writing the sidecar" or "")
    checkSlot()
    saveSlot()
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
    -- while creating: the name typed in the creator, on the preview cat (the screens after the name screen show it)
    local creating = Creator.PendingName()
    if creating then
        custom = creating
        data = data or Creator.PreviewData()
    end
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
        for _, k in ipairs(l.__order) do if k ~= "Row" and k ~= "Fallback" then add(k, l[k]) end end
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


local function readAppearance()
    -- "Customise online cat" in the creator: the preview shows the cat as other players will see it - no WaCa look
    if Creator.OnlinePreview() then return mergeLook({ __order = {} }) end
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

-- The look is applied where the game BUILDS it (native CatLookPart, appearance.cpp): right after the game writes a
-- colour or a mask to one part of a cat, that cat's WaCa look puts its own value on the same part, in the same call.
-- No repaint afterwards and no check whether the look is still there: each build of the game includes it. When the
-- look itself changes (a creator choice, another save, an edited ini), the cats it belongs to are simply rebuilt by
-- the game (rebuildCats).

-- a coat colour slot's value for one part: the part's own "Tail.Fur = ..." first, then the whole-cat value. A
-- per-part value may name a coat slot ("Tail.Fur = Pattern": the tail in the pattern's colour, whatever the colour
-- picker chose) - the configured colour of that slot, else the game's current one on this part.
local function partColor(cfg, partName, part, slot)
    local value = cfg[partName .. "." .. slot]
    if value and WaCa.COAT_COLORS[value] then
        local own = WaCa.ParseColor(cfg[value])
        if own then return own end
        local m = part:GetMaterial(0)
        if not m or not m:IsValid() then return nil end
        local v = m:K2_GetVectorParameterValue(FName(WaCa.COAT_COLORS[value]))
        return { X = v.R, Y = v.G, Z = v.B }
    end
    return WaCa.ParseColor(value) or WaCa.ParseColor(cfg[slot])
end

local function applyColours(cfg, partName, part)
    for slot, param in pairs(WaCa.COAT_COLORS) do
        local color = partColor(cfg, partName, part, slot)
        if color then part:SetVectorParameterValueOnMaterials(FName(param), color) end
    end
end

local function applyMask(cfg, part, maskSlot)
    local source = cfg[maskSlot .. "Mask"]
    if source and source ~= "" then WaCa.SetPartMask(part, maskSlot, maskSource(source)) end
end

-- Which cats are the player's: the pawn's, a cutscene cat flagged bIsPlayer, and the creator's preview actors (all of
-- them while creating; elsewhere those showing the player's cat - its headshots). Decided per component, cached until
-- something that changes the answer happens (another save, the creator opening / closing, a new pawn).
local playerCache, playerPrint = {}, nil
local previewClass = nil
local function forgetPlayerCats() playerCache, playerPrint = {}, nil end
table.insert(onSlotChanged, forgetPlayerCats)

local function isPlayerCat(comp)
    local id = comp:GetFullName()
    local known = playerCache[id]
    if known ~= nil then return known end
    local owner = comp:GetOwner()
    local result = false
    if owner and owner:IsValid() then
        local pc = FindFirstOf("PlayerController")
        local pawn = pc and pc:IsValid() and pc.Pawn
        if pawn and pawn:IsValid() and pawn:GetFullName() == owner:GetFullName() then
            result = true
        else
            local ok, flagged = pcall(function() return owner.bIsPlayer end)
            if ok and flagged == true then
                result = true
            else
                previewClass = previewClass or StaticFindObject("/Script/Wrc.GuiCatCustomActor")
                if previewClass and owner:IsA(previewClass) then
                    if Creator.IsOpen() then
                        result = true
                    else
                        if playerPrint == nil then
                            local data = playerCustomData()
                            playerPrint = data and WaCa.CatFingerprint(data) or false
                        end
                        result = playerPrint and WaCa.CatFingerprint(comp.CustomData) == playerPrint or false
                    end
                end
            end
        end
    end
    playerCache[id] = result
    return result
end

-- the player's look, read once per change (the ini files are not read per event)
local lookCache = nil
local function playerLook()
    if not lookCache then
        local cfg, stamp = readAppearance()
        lookCache = { cfg = cfg, stamp = stamp }
    end
    return lookCache.cfg, lookCache.stamp
end

local Roster
local requestRefresh               -- (defined below) the once-per-tick refresh

-- the WaCa look of a cat component, or nil (the player's, or a pinned roster cat's)
local function lookFor(comp)
    if isPlayerCat(comp) then
        local cfg, stamp = playerLook()
        if stamp ~= "" then return cfg end
        return nil
    end
    return Roster and Roster.LookFor(comp) or nil
end

local builtWithLook = {}     -- component -> true once a build of the game included its WaCa look

WaCa.On("CatLookPart", function(comp, what, partFullName)
    if not comp or not comp:IsValid() then return end
    local cfg = lookFor(comp)
    if not cfg then return end
    local partName, part = WaCa.PartNameOf(comp, partFullName)
    if not part then return end
    if what == "PatternMask" then applyMask(cfg, part, "Pattern")
    elseif what == "MarkingsMask" then applyMask(cfg, part, "Markings")
    else applyColours(cfg, partName, part) end
    local id = comp:GetFullName()
    if not builtWithLook[id] then log("look: %s built with the WaCa look", id:match("([^.:]+%.[^.:]+)$") or id) end
    builtWithLook[id] = true
end)

-- the game rebuilds a cat's look (and with it, through the hook, ours)
local function rebuild(comp)
    local owner = comp:GetOwner()
    previewClass = previewClass or StaticFindObject("/Script/Wrc.GuiCatCustomActor")
    if owner and owner:IsValid() and previewClass and owner:IsA(previewClass) then
        pcall(function() owner:RefreshPattern() end)
    elseif not WaCa.RebuildLook(comp) then
        -- RefreshShape alone does not run the look build on an in-world cat (VM, 2026-10-25): only a fallback
        pcall(function() comp:RefreshShape() end)
    end
end

-- the player's cats that need a build with the current look: all of them when the look changed, else the ones that
-- were never built with it (a pawn whose first build came before it was known as the player's)
local function rebuildCats(all)
    for _, comp in ipairs(WaCa.PlayerCats(Creator.IsOpen())) do
        local id = comp:GetFullName()
        if all or builtWithLook[id] == nil then
            builtWithLook[id] = nil
            log("look: rebuilding %s", id:match("([^.:]+%.[^.:]+)$") or id)
            rebuild(comp)
            if not builtWithLook[id] then builtWithLook[id] = false end     -- built, but without a look (none set)
        end
    end
end

-- the look changed (or the set of player cats did): fresh look, fresh answers, the player's cats rebuilt
local function lookChanged()
    lookCache = nil
    forgetPlayerCats()
    rebuildCats(true)
end
table.insert(onSlotChanged, function() lookCache, builtWithLook = nil, {} end)

-- the player's cats after a change in the game (a screen, a spawn): the ini may have been edited, the creator may have
-- opened or closed, a new pawn may need its first build with the look
local function applyAppearance()
    local _, oldStamp = playerLook()
    lookCache = nil
    forgetPlayerCats()
    local _, stamp = playerLook()
    if stamp ~= oldStamp then
        log("look changed: the player's cats are rebuilt")
        rebuildCats(true)
    else
        rebuildCats(false)
    end
end

-- The game's procedural cats: doubled names fixed, pinned cats from config/roster.ini (roster.lua)
Roster = require("roster")
Roster.Init({
    WaCa = WaCa, log = log, modDir = modDir, modsDir = modsDir,
    lookOf = function(section) return (mergeLook(section)) end,
})
table.insert(onSlotChanged, function() Roster.Run(true) end)

-- The character creator: extra palette colours + the name field (creator.lua)
Creator.Init({
    WaCa = WaCa, log = log, modDir = modDir, modsDir = modsDir, setSlotValue = setSlotValue, slotValue = slotValue,
    refreshLook = lookChanged,
    writeSlot = function() slot.dirty = true; saveSlot() end,
    slotId = function() return slot.id end,
})
table.insert(onSlotChanged, Creator.OnSlotChanged)

-- Key aliases (config/keybinds.ini [KeyAliases] Key = OtherKey[, ...]): pressing Key also presses OtherKey. The game's
-- menus read raw keys (SwtPlayerController.OnKeyPressed / OnKeyReleased) rather than bindings - many use BackSpace as
-- "back" - so "Escape = BackSpace" makes Escape work as back in menus too.
local aliases = {}
local dialogueAliases = {}
local function readAliases(ini, section)
    local out = {}
    for _, k in ipairs(ini and ini[section] and ini[section].__order or {}) do
        local targets = {}
        for t in ini[section][k]:gmatch("[^,%s]+") do table.insert(targets, t) end
        out[k] = targets
    end
    return out
end
local function loadAliases()
    local ini = WaCa.ReadIni(modDir .. "/config/keybinds.ini")
    aliases = readAliases(ini, "KeyAliases")
    dialogueAliases = readAliases(ini, "DialogueKeyAliases")
end
loadAliases()

-- Dialogue keys ([DialogueKeyAliases] Key = OtherKey): while a conversation is on screen, pressing Key also presses
-- OtherKey as a real key press - SpaceBar = Enter: Space advances / confirms dialogue like Enter does (operator
-- 2026-10-25). A conversation is the game's QuestGiverWidget (its "next" prompt is Button_Confirm = Enter); it is
-- looked up when such a key is pressed, not tracked.
local function dialogueUp()
    for _, w in ipairs(FindAllOf("QuestGiverWidget") or {}) do
        if w:IsValid() and w:IsInViewport() and w:IsVisible() then return true end
    end
    return false
end
WaCa.On("KeyDown", function(_, name)
    local targets = dialogueAliases[name]
    if not targets or not dialogueUp() then return end
    for _, target in ipairs(targets) do
        if not dialogueAliases[target] then
            log("dialogue: %s -> %s", name, target)
            WaCa.Command("PressKey|" .. target)
        end
    end
end)

-- Dialogue text check (tickets.md "Dialogue text bugs": "It seems that 1's Prophecy is true"): the game fills the
-- role placeholders of its lines ({THE AGING LEADER}, {PLAYER} ...) from data, and some come out unfilled or as a
-- number. Every line, once shown in full (the conversation widget's OnTypewriterDone), is checked for a placeholder
-- left in braces or a bare number where a name goes ("1's"); a hit is logged with the dialogue node it came from,
-- so the source line can be found and fixed (or patched with WaCa.SetText).
WaCa.Watch("OnTypewriterDone", "/Script/SwtQuest.QuestGiverWidget", "WaCaDialogueLineShown", "post")
WaCa.On("WaCaDialogueLineShown", function(widget)
    local text, node = "", "?"
    pcall(function()
        local rich = widget.mcGuiTextParagraphRich
        if rich and rich:IsValid() then text = rich:GetText():ToString() end
        if text == "" then text = widget.mcGuiTextParagraph:GetText():ToString() end
    end)
    pcall(function()
        local n = widget.CurrentDialogueNode
        if n and n:IsValid() then node = n:GetFullName():gsub("^%S+ ", "") end
    end)
    local plain = text:gsub("<[^>]*>", "")           -- rich text markup out
    local brace = plain:match("{[^}]*}")
    local number = plain:match("%f[%w](%d+)'s%f[%W]")
    if brace or number then
        log("dialogue: UNFILLED %s in \"%s\" (node %s)", brace or (number .. "'s"), plain, node)
    end
end)

-- An alias posts a REAL key press of its target to the game window (native PressKey): menus only react to real input
-- - calling the controller's OnKeyPressed with the target never reached them (Escape did nothing, operator
-- 2026-10-25). Presses come from the raw KeyDown event (the window's own key messages, before the game routes them -
-- so a paused game or a key bound to nothing still counts). A target that is itself aliased is skipped (no loops).
WaCa.On("KeyDown", function(_, name)
    -- only in menus: in gameplay Escape is the game's pause key - a BackSpace with it reached the pause menu while it
    -- was being built and crashed the game (VM, 2026-10-25)
    if not aliases[name] or not require("menus").InMenu() then return end
    for _, target in ipairs(aliases[name] or {}) do
        if not aliases[target] then WaCa.Command("PressKey|" .. target) end
    end
end)
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

-- Everything below reacts to the game (WaCa.On events, hooks) - nothing runs on a timer. Handlers run on the game
-- thread; no Lua may run off it in this mod (LoopAsync on a worker thread next to the game-thread hooks corrupted Lua's
-- tables and crashed the game in 0.5.3).
local Menus = require("menus")
Menus.Init({ WaCa = WaCa, log = log, modDir = modDir })
local Dev = require("dev")
Dev.Init({ WaCa = WaCa, log = log, modDir = modDir })
-- more graphics settings (config/graphics.ini)
require("graphics").Init({ WaCa = WaCa, log = log, modDir = modDir })

-- the game's text and tables: loaded by the time a screen shows with text (the first screens are the splash)
local textApplied = false
local function gameReady()
    if textApplied or not WaCa.IsTextReady() then return end
    textApplied = true
    applyTextOverrides()
    applyUIKeys()
    Dev.OnGameReady()
end

-- the player's cat as it is now: a pending creation settled, the name (it changes with your rank - the ceremony is a
-- screen) and the look applied
local function refreshPlayer(force)
    checkSlot()
    local cat = playerCustomData()
    if cat then Creator.OnPlayerCat(cat) end
    applyName()
    applyAppearance(force)
end

-- Events can come in bursts (a level or cutscene starting spawns dozens of characters in one frame): the refresh is
-- not done per event but ONCE, on the next game tick, however many events asked for it. (Doing it per event froze
-- the intro cutscene - one frame every few seconds, operator 2026-10-25.)
local refreshDue, forceDue = false, false
requestRefresh = function(force)
    if force then forceDue = true end
    if refreshDue then return end
    refreshDue = true
    ExecuteInGameThread(function()
        local f = forceDue
        refreshDue, forceDue = false, false
        local t = os.clock()
        local ok, err = pcall(refreshPlayer, f)
        if not ok then log("refresh: %s", tostring(err)) end
        local ms = (os.clock() - t) * 1000
        if ms > 20 then log("refresh took %.0f ms", ms) end
    end)
end

local function guarded(label, fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then log("%s: %s", label, tostring(err)) end
    end
end

-- the player's own cat (its pawn, or a cutscene cat flagged as the player)
local function isPlayerCat(actor)
    if not actor or not actor:IsValid() then return false end
    local pc = FindFirstOf("PlayerController")
    local pawn = pc and pc:IsValid() and pc.Pawn
    if pawn and pawn:IsValid() and pawn:GetFullName() == actor:GetFullName() then return true end
    local ok, flagged = pcall(function() return actor.bIsPlayer end)
    return ok and flagged == true
end

WaCa.On("ScreenShown", guarded("screen shown", function()
    gameReady()
    requestRefresh()
end))
WaCa.On("ScreenHidden", guarded("screen hidden", function() requestRefresh() end))
WaCa.On("CatSpawned", guarded("cat spawned", function(actor)
    Roster.SyncCat(WaCa.CatComponent(actor))
    if isPlayerCat(actor) then requestRefresh() end
end))

WaCa.Ready()
