-- WaCa ModKit - the shared Lua API. Any UE4SS Lua mod can use it:
--     local WaCa = require("WaCa")
--     WaCa.SetText("STR_MAINMENU_PROPHECY_MODE", "Story Mode")     -- replace any game text
--     print(WaCa.GetText("STR_CAT_NAME1_PAW"))                     -- "Woodpaw"
-- Game text lives in one string table ("SwtStrings", from Strings_<LANG>.csv); cat names are entries too
-- (STR_CAT_NAME<n><suffix id>, e.g. STR_CAT_NAME1_PAW). Overrides change what the game shows; saves are untouched.
-- Needs WaCa ModKit's native part (WaCaModKit/dlls/main.dll), which applies the changes on the game thread.
local WaCa = {}

local TABLE = "SwtStrings"
local stringTables = nil

local function lib()
    if not stringTables or not stringTables:IsValid() then
        stringTables = StaticFindObject("/Script/Engine.Default__KismetStringTableLibrary")
    end
    return stringTables
end

-- the text the game has for a key ("" when there is none / the table isn't loaded yet)
function WaCa.GetText(key)
    local l = lib()
    if not l or not l:IsValid() then return "" end
    return l:GetTableEntrySourceString(FName(TABLE), key):ToString()
end

-- true once the game has loaded its text
function WaCa.IsTextReady()
    return WaCa.GetText("STR_WINDOW_TITLE_BAR") ~= ""
end

-- replace the text of a key ("|" is not allowed in either); applied by the native part at once
function WaCa.SetText(key, text)
    if not WaCa.Command("SetText|" .. key .. "|" .. text) then return false end
    return WaCa.GetText(key) == text
end

-- Cat names: a cat stores a prefix id (PrefixNameId "STR_CAT_NAME12") and a suffix id (SuffixNameId "_PAW"); each
-- combination is one text entry (STR_CAT_NAME12_PAW = "Mosspaw"; all combinations exist).
-- The prefix's own text: what "<prefix>kit" and "<prefix>paw" have in common ("Woodkit", "Woodpaw" -> "Wood").
-- Remembered per prefix the first time, before any entry of it is rewritten.
local prefixTexts = {}
function WaCa.NamePrefixText(prefixId)
    if prefixTexts[prefixId] then return prefixTexts[prefixId] end
    local a, b = WaCa.GetText(prefixId .. "_KIT"), WaCa.GetText(prefixId .. "_PAW")
    local n = 0
    while n < #a and n < #b and a:sub(n + 1, n + 1) == b:sub(n + 1, n + 1) do n = n + 1 end
    if n > 0 then prefixTexts[prefixId] = a:sub(1, n) end
    return a:sub(1, n)
end

-- the suffix's own text for a combination ("STR_CAT_NAME3", "_BLAZE" -> "blaze"), or "" when unknown
function WaCa.NameSuffixText(prefixId, suffixId)
    local prefix = WaCa.NamePrefixText(prefixId)
    local full = WaCa.GetText(prefixId .. suffixId)
    if prefix == "" or full:sub(1, #prefix) ~= prefix then return "" end
    return full:sub(#prefix + 1)
end

-- the FCatCustomData fields a roster / mod may set (everything but the combat stats tag)
WaCa.CAT_DATA_FIELDS = {
    "ClanType", "Role", "BodyOffset", "FaceOffset", "FurOffset", "TailOffset", "EarOffset", "EyeOffset",
    "WhiskerOffset", "BodyValue", "FaceValue", "FurValue", "EyeValue", "WhiskerValue", "TailIdx", "EarIdx", "FurIdx",
    "FurColorIdx", "Pattern01ColorIdx", "Pattern02ColorIdx", "PatternIdx", "MarkingIdx", "EyeLeftColorIdx",
    "EyeRightColorIdx", "bOverrideColors", "Design", "PrefixNameId", "SuffixNameId", "Gender", "CatSize",
    "AccesoryNeckId", "AccesoryPawId", "AccesoryHeadId", "AccesoryBodyId", "AccesoryNeckVar", "AccesoryPawVar",
    "AccesoryHeadVar", "AccesoryBodyVar", "ScarEyeId", "ScarEarId", "ScarBodyId", "ScarChestId",
}

-- send a command to WaCa ModKit's native part ("Verb|arg|arg..."); false when the native part is missing or the verb
-- is unknown
function WaCa.Command(cmd)
    if not WaCaNative_Command then return false end
    return WaCaNative_Command(cmd)
end

---------------------------------------------------------------------------------------------------------------------
-- Events: the game tells the mod when something happens - nothing polls. The native part turns UE4SS's ProcessEvent
-- callbacks into events (any UFunction by name, Blueprint events included) and adds its own; handlers run on the game
-- thread.
--     WaCa.On("ScreenShown", function(screen) ... end)           a game screen / popup entered the viewport
--     WaCa.Watch("ReceiveBeginPlay", "/Script/Engine.Pawn", "PawnSpawned")   your own event from any function
--     WaCa.Ready()          LAST line of your main.lua: events are delivered from then on
-- Built-in events (watched as soon as someone listens):
--     ScreenShown(screen) / ScreenHidden(screen)    a USwtScreen (screens and popups) built / torn down: the widget's
--                                                   Construct / Destruct (hidden fires while it is still valid)
--     ScreenFocusIn(screen) / ScreenFocusOut(screen) keyboard focus entered / left the screen's widgets (a text box in
--                                                   it took / lost the keyboard: typing, Enter, focus moved away)
--     SteamTextInput(nil, submitted "1"/"0", text)   Steam's full-screen keyboard closed (WaCa.Command SteamKeyboard)
--     KeyDown(nil, keyName)                         a key / mouse button pressed ("Escape", "A", "LeftMouseButton"),
--                                                   as it reaches the game window - before the game routes it, so
--                                                   also while paused or when nothing is bound to it
--     GameSaved(nil, context)                       right after every game save (the save manager's native save,
--                                                   whoever called it) - write per-save data (WaCa.SlotFile) here
--     Started(nil)                                  the first event after WaCa.Ready(), on the game thread; the
--                                                   screens already up arrive as ScreenShown just before it
-- Don't run Lua off the game thread in a mod that uses events (LoopAsync / ExecuteAsync): two OS threads in one Lua
-- state corrupt it.
--     CatSpawned(actor)                             a cat actor began play: the player's / an NPC's pawn, a quest
--                                                   actor, a cutscene cat
local BUILTIN = {
    ScreenShown = { { "Construct", "/Script/SwtEngine.SwtScreen", "post" } },
    ScreenHidden = { { "Destruct", "/Script/SwtEngine.SwtScreen", "pre" } },
    ScreenFocusIn = { { "OnAddedToFocusPath", "/Script/SwtEngine.SwtScreen", "post" } },
    ScreenFocusOut = { { "OnRemovedFromFocusPath", "/Script/SwtEngine.SwtScreen", "post" } },
    CatSpawned = {
        { "ReceiveBeginPlay", "/Script/SwtAdventure.SwtAdventureCharacter", "post" },
        { "ReceiveBeginPlay", "/Script/SwtAdventure.SwtAdventureQuestActor", "post" },
        { "ReceiveBeginPlay", "/Script/Wrc.WrcCatSkeletalMeshWithCustomization", "post" },
    },
}
local handlers = {}           -- event -> { fn, ... }
local watched = {}            -- "function|class|event" -> true once its native watch exists

local function dispatch(event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i], ...)
        if not ok then print(string.format("[WaCa] %s handler: %s\n", event, tostring(err))) end
    end
end

-- called by the native part for every event this mod's state watches
function WaCaNative_OnEvent(event, object, ...)
    if event == "Started" then
        -- the first event after WaCa.Ready(): the screens already up were shown before this mod listened - replay them
        if handlers["ScreenShown"] then
            for _, s in ipairs(FindAllOf("SwtScreen") or {}) do
                if s:IsValid() and s:IsInViewport() then dispatch("ScreenShown", s) end
            end
        end
    end
    dispatch(event, object, ...)
end

-- watch a UFunction (by name, on objects of a class) as an event; when = "pre" (before it runs) or "post" (default)
function WaCa.Watch(functionName, classPath, event, when)
    local id = functionName .. "|" .. classPath .. "|" .. event
    if watched[id] then return true end
    if not WaCaNative_Watch then return false end
    WaCaNative_Watch(functionName, classPath, event, when or "post")
    watched[id] = true
    return true
end

-- listen to an event (built-in, watched, or raised with WaCa.Emit)
function WaCa.On(event, fn)
    handlers[event] = handlers[event] or {}
    table.insert(handlers[event], fn)
    for _, w in ipairs(BUILTIN[event] or {}) do WaCa.Watch(w[1], w[2], event, w[3]) end
end

-- the cat look component of an actor (pawn, quest actor, cutscene cat, creator preview), or nil
local meshCompClass = nil
function WaCa.CatComponent(actor)
    if not actor or not actor:IsValid() then return nil end
    meshCompClass = meshCompClass or StaticFindObject("/Script/SwtAdventure.SwtAdventureCustomizableMeshComponent")
    local ok, comp = pcall(function() return actor:GetComponentByClass(meshCompClass) end)
    if ok and comp and comp:IsValid() then return comp end
    return nil
end

-- raise an event from Lua (to this mod's listeners, at once)
function WaCa.Emit(event, ...)
    dispatch(event, ...)
end

-- the mod's main.lua is done: events may arrive from now on (they are held back while it runs on UE4SS's loader thread)
function WaCa.Ready()
    if WaCaNative_Ready then WaCaNative_Ready() end
end

-- the menus' keyboard keys + hint icons: rows of UXD/Buttons/DT_GamepadButtonsKeyboard, keyed by command name
-- (Button_A = Enter, Button_B / Button_Back = BackSpace, Button_X = E, ...). Rebinds a row; the icon is the game's
-- own for that key (T_UI_Controller_Pc_<Key>_D) unless one is given, and kept as is when there's none.
WaCa.UI_KEYS_TABLE = "/Game/Gameplay/DataTables/UXD/Buttons/DT_GamepadButtonsKeyboard.DT_GamepadButtonsKeyboard"
function WaCa.SetUIKey(row, key, icon)
    local tbl = StaticFindObject(WaCa.UI_KEYS_TABLE)
    if not tbl or not tbl:IsValid() then
        local ok, loaded = pcall(LoadAsset, WaCa.UI_KEYS_TABLE)
        tbl = ok and loaded or nil
    end
    if not tbl or not tbl:IsValid() then return false end
    if not icon then
        local name = string.format("T_UI_Controller_Pc_%s_D", key)
        local path = string.format("/Game/Platforms/Windows/UXD/Textures/Controllers/Gameplay/%s.%s", name, name)
        local ok, tex = pcall(LoadAsset, path)
        icon = ok and tex and tex:IsValid() and path or ""
    end
    return WaCa.Command(string.format("SetUIKey|%X|%s|%s|%s", tbl:GetAddress(), row, key, icon))
end

-- every menu-key table: the keyboard one and one per gamepad type (USwtGuiManager.GamepadButtonsMap)
function WaCa.MenuKeyTables()
    local out, seen = {}, {}
    local function add(t)
        if t and t:IsValid() and not seen[t:GetAddress()] then
            seen[t:GetAddress()] = true
            table.insert(out, t)
        end
    end
    add(StaticFindObject(WaCa.UI_KEYS_TABLE))
    local gm = FindFirstOf("SwtGuiManager")
    local map = gm and gm:IsValid() and gm.GamepadButtonsMap
    if map and map:IsValid() then
        pcall(function()
            map.DataGamepadButtonsMap:ForEach(function(_, v) add(v:get()) end)
        end)
    end
    return out
end

-- every row name of a menu-key table ("Button_A", "Button_Skip", ...)
function WaCa.UIRows(tbl)
    local rows = {}
    pcall(function()
        tbl:ForEachRow(function(name) table.insert(rows, tostring(name)) end)
    end)
    return rows
end

-- a menu row's key name in a table ("Enter", "Gamepad_FaceButton_Bottom"), or nil
function WaCa.UIRowKey(tbl, row)
    local ok, key = pcall(function() return tbl:FindRow(row).Key.KeyName:ToString() end)
    return ok and key or nil
end

-- a menu row's key in a given table, its icon untouched ("None" = no key)
function WaCa.SetUIKeyIn(tbl, row, key)
    return WaCa.Command(string.format("SetUIKey|%X|%s|%s|", tbl:GetAddress(), row, key))
end

-- only the hint icon of a menu row (its key stays): e.g. SetUIIcon("Button_B", "Escape") shows Esc for "back" while
-- BackSpace still works (pair it with a key alias Escape -> BackSpace so Esc works too)
function WaCa.SetUIIcon(row, iconKey)
    local name = string.format("T_UI_Controller_Pc_%s_D", iconKey)
    local path = string.format("/Game/Platforms/Windows/UXD/Textures/Controllers/Gameplay/%s.%s", name, name)
    local ok, tex = pcall(LoadAsset, path)
    if not (ok and tex and tex:IsValid()) then return false end
    local tbl = StaticFindObject(WaCa.UI_KEYS_TABLE)
    if not tbl or not tbl:IsValid() then
        local ok2, loaded = pcall(LoadAsset, WaCa.UI_KEYS_TABLE)
        tbl = ok2 and loaded or nil
    end
    if not tbl or not tbl:IsValid() then return false end
    return WaCa.Command(string.format("SetUIKey|%X|%s||%s", tbl:GetAddress(), row, path))
end

-- a simple ini reader: { [section] = { key = value } }, keys in file order in section.__order
function WaCa.ReadIni(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local out, section = {}, ""
    out[section] = { __order = {} }
    for line in f:lines() do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" and not line:match("^[;#]") then
            local s = line:match("^%[(.+)%]$")
            if s then
                section = s
                out[section] = out[section] or { __order = {} }
            else
                local k, v = line:match("^([^=]+)=(.*)$")
                if k then
                    k = k:gsub("%s+$", ""); v = v:gsub("^%s+", "")
                    out[section][k] = v
                    table.insert(out[section].__order, k)
                end
            end
        end
    end
    f:close()
    return out
end

-- write { [section] = { key = value, __order = {...} } } as an ini (sections and keys in their __order when present)
function WaCa.WriteIni(path, data, header)
    local f = io.open(path, "w")
    if not f then return false end
    if header then f:write(header, "\n\n") end
    local sections = data.__order or {}
    if #sections == 0 then for k in pairs(data) do if k ~= "__order" then table.insert(sections, k) end end end
    for _, section in ipairs(sections) do
        local t = data[section]
        if t then
            f:write("[", section, "]\n")
            local keys = t.__order or {}
            if #keys == 0 then for k in pairs(t) do if k ~= "__order" then table.insert(keys, k) end end end
            for _, k in ipairs(keys) do
                if t[k] ~= nil then f:write(k, " = ", tostring(t[k]), "\n") end
            end
            f:write("\n")
        end
    end
    f:close()
    return true
end

---------------------------------------------------------------------------------------------------------------------
-- Per-save data. The game keeps every save slot in Saved/SaveGames/WrcGame.sav (a slot = a GUID, the active one
-- USwtSaveManager.SaveGame.saveSlots[CurrentSaveSlotIndex]). Mods keep their own data per slot in a sidecar file
-- next to it - WrcGame.<save>-<character slot>.<ModName>.ini - so the game's save stays exactly as the game wrote it.

-- the active save slot's id, or nil (main menu before a save is chosen, a new game before its first save)
-- The active character's save slot: "<save GUID>-<character slot>". The game keeps ONE save (saveSlots holds its
-- GUID, the same for every character on the account) with up to MaxSlots characters in it; CurrentSaveSlotIndex is the
-- character. (Before 0.5.4 the index was taken as an index into saveSlots - only character slot 0 ever had a sidecar.)
function WaCa.CurrentSlot()
    local sm = FindFirstOf("SwtSaveManager")
    if not sm or not sm:IsValid() then return nil end
    local sg = sm.SaveGame
    if not sg or not sg:IsValid() then return nil end
    local idx = sg.CurrentSaveSlotIndex
    if not idx or idx < 0 then return nil end
    local guid = #sg.saveSlots > 0 and sg.saveSlots[1]:ToString() or ""
    if guid == "" then guid = sg.GamerId:ToString() end
    if guid == "" then return nil end
    return string.format("%s-%d", guid, idx)
end

-- the game's save folder (%LOCALAPPDATA%/Wrc/Saved/SaveGames)
function WaCa.SaveDir()
    return (os.getenv("LOCALAPPDATA") or ".") .. "/Wrc/Saved/SaveGames"
end

-- a mod's sidecar file for a slot (the active one when slot is nil)
function WaCa.SlotFile(modName, slot)
    slot = slot or WaCa.CurrentSlot()
    if not slot then return nil end
    return string.format("%s/WrcGame.%s.%s.ini", WaCa.SaveDir(), slot, modName)
end

---------------------------------------------------------------------------------------------------------------------
-- Cat appearance. A cat's look is one USwtAdventureCustomizableMeshComponent (on the player's pawn, on every NPC, on
-- the creation screen's preview); its mesh parts (body, tail, ears, fur cards) all use the material M_Characters_Base,
-- whose parameters below are the coat. Changes made here are what you SEE: the save keeps the game's choices.

-- the coat's colour slots -> material parameters
WaCa.COAT_COLORS = {
    Fur = "Fur Color", Pattern = "Pattern Mask Color", Markings = "Markings Mask Color", Paws = "Paws Color",
    Ears = "Ears Color", Nose = "Nose Color", Whiskers = "Whiskers Color",
}
-- the coat's shape textures (white = the slot's colour) -> material parameters
WaCa.COAT_MASKS = { Pattern = "Pattern Mask", Markings = "Markings Mask" }
WaCa.CAT_PARTS = { "SkelMeshComp", "TailSkelMeshComp", "EarSkelMeshComp", "FurSkelMeshComp" }

-- "#RRGGBB" / "RRGGBB" / "r, g, b" (0-255) -> a linear colour {X, Y, Z} as the material wants it (the game's colours
-- are linear: its own F8940B orange is stored as 0.93 / 0.30 / 0.004)
function WaCa.ParseColor(text)
    if not text or text == "" then return nil end
    local r, g, b
    local hex = text:match("^#?(%x%x%x%x%x%x)$")
    if hex then
        r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
    else
        r, g, b = text:match("^(%d+)%s*,%s*(%d+)%s*,%s*(%d+)$")
        r, g, b = tonumber(r), tonumber(g), tonumber(b)
    end
    if not (r and g and b) then return nil end
    local function lin(c)
        c = c / 255
        return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
    end
    return { X = lin(r), Y = lin(g), Z = lin(b) }
end

-- the mesh parts of a cat (skeletal mesh components that exist)
function WaCa.CatParts(cat)
    local out = {}
    for _, name in ipairs(WaCa.CAT_PARTS) do
        local part = cat[name]
        if part and part:IsValid() then table.insert(out, part) end
    end
    return out
end

-- a part's role from its material: MI_Cat_Body -> "Body", MI_Cat_Tails_A -> "Tails_A", MI_Cat_Fur_Bony -> "Fur_Bony"
-- (pattern packs name their mask files after it)
function WaCa.PartRole(part, slot)
    local m = part:GetMaterial(slot or 0)
    if not m or not m:IsValid() then return nil end
    local name = m:GetFName():ToString()
    if m:GetClass():GetFName():ToString() == "MaterialInstanceDynamic" and m.Parent and m.Parent:IsValid() then
        name = m.Parent:GetFName():ToString()
    end
    return name:match("^MI_Cat_(.-)_CelShaded") or name:match("^MI_Cat_(.+)$")
end

-- set one coat colour (a WaCa.COAT_COLORS slot or a raw parameter name) on every part of a cat
function WaCa.SetCatColor(cat, slot, color)
    local param = FName(WaCa.COAT_COLORS[slot] or slot)
    for _, part in ipairs(WaCa.CatParts(cat)) do part:SetVectorParameterValueOnMaterials(param, color) end
end

-- the material instance a part draws with, made dynamic if it isn't yet (so its parameters can change)
local function dynamicMaterial(part, slot)
    local m = part:GetMaterial(slot)
    if not m or not m:IsValid() then return nil end
    if m:GetClass():GetFName():ToString() == "MaterialInstanceDynamic" then return m end
    return part:CreateDynamicMaterialInstance(slot, m, FName("None"))
end

-- set a texture parameter on all of one part's materials
function WaCa.SetPartTexture(part, param, texture)
    for i = 0, part:GetNumMaterials() - 1 do
        local mid = dynamicMaterial(part, i)
        if mid and mid:IsValid() then mid:SetTextureParameterValue(FName(param), texture) end
    end
end

-- load a PNG / JPG / TGA from disk as a texture (cached by path; nil when it can't be read)
-- (cached by the texture's object path, found again each time: a held object can be garbage-collected and a call on
-- its stale wrapper crashes the game)
local textures = {}
function WaCa.LoadTexture(path)
    local known = textures[path] and StaticFindObject(textures[path])
    if known and known:IsValid() then return known end
    local f = io.open(path, "rb")
    if not f then return nil end
    f:close()
    local lib = StaticFindObject("/Script/Engine.Default__KismetRenderingLibrary")
    local tex = lib:ImportFileAsTexture2D(FindFirstOf("World"), path)
    if tex and tex:IsValid() then
        textures[path] = (tex:GetFullName():gsub("^%S+ ", ""))
        return tex
    end
    return nil
end

-- the game's own mask texture for a part: a pattern (P01_Fishbone ... P23_Deluxe_Spotted) or a marking (M01_Sock ...
-- M20_Piebald) by its folder name, e.g. GameMask("M12_Mask", "Ears_A"). Loaded from the player's own game files.
function WaCa.GameMask(name, role)
    local kind = name:match("^P%d") and "Patterns" or "Markings"
    local tex = string.format("T_Cat_%s_%s_M", role, name)
    local path = string.format("/Game/Art/Characters/CatMaster/Textures/%s/%s/%s.%s", kind, name, tex, tex)
    local obj = StaticFindObject(path)
    if not obj or not obj:IsValid() then
        -- LoadAsset wants the full object path (Package.Object) and must run on the game thread (main.lua's callers do)
        local ok, loaded = pcall(LoadAsset, path)
        obj = ok and loaded or nil
    end
    return obj and obj:IsValid() and obj or nil
end

-- set one coat mask slot ("Pattern" or "Markings") on every part of a cat from a source:
--   "game:M12_Mask"  the game's own pattern / marking of that name (all parts it exists for)
--   "<folder>"       a pattern pack: PNGs named after the part roles (Body.png, Tails_A.png, Ears_B.png,
--                    Fur_Bony.png ...; Tails.png / Ears.png / Fur.png cover all variants of a part)
-- Parts the source has no mask for keep the game's. Returns how many parts changed.
-- one part's mask for a slot from a source (see SetCatMask); true when the source has one for this part
function WaCa.SetPartMask(part, maskSlot, source)
    local param = WaCa.COAT_MASKS[maskSlot] or maskSlot
    local game = source:match("^game:(.+)$")
    local role = WaCa.PartRole(part)
    local tex
    if role and game then
        tex = WaCa.GameMask(game, role)
    elseif role then
        tex = WaCa.LoadTexture(source .. "/" .. role .. ".png")
            or WaCa.LoadTexture(source .. "/" .. (role:match("^(%a+)") or role) .. ".png")
    end
    if not tex then return false end
    WaCa.SetPartTexture(part, param, tex)
    return true
end

function WaCa.SetCatMask(cat, maskSlot, source)
    local n = 0
    for _, part in ipairs(WaCa.CatParts(cat)) do
        if WaCa.SetPartMask(part, maskSlot, source) then n = n + 1 end
    end
    return n
end

-- the part's name (Body / Tail / Ears / Tufts) of one of a cat's mesh parts, by its full name, or nil
function WaCa.PartNameOf(cat, partFullName)
    for name, field in pairs(WaCa.PART_NAMES) do
        local part = cat[field]
        if part and part:IsValid() and part:GetFullName() == partFullName then return name, part end
    end
    return nil
end

-- the game builds a cat's whole look again from its own data (colours, patterns, markings - and, through the look
-- hook, every mod's look on top); comp = a cat's look component. False without WaCa ModKit's native part.
function WaCa.RebuildLook(comp)
    if not WaCaNative_RebuildLook or not comp or not comp:IsValid() then return false end
    return WaCaNative_RebuildLook(comp:GetAddress())
end

-- the parts by name, for per-part colours ("Tail.Fur = ..."): Body, Tail, Ears, Tufts (the fur cards)
WaCa.PART_NAMES = { Body = "SkelMeshComp", Tail = "TailSkelMeshComp", Ears = "EarSkelMeshComp", Tufts = "FurSkelMeshComp" }

-- set one coat colour on one named part only (e.g. a darker tail)
function WaCa.SetPartColor(cat, partName, slot, color)
    local part = cat[WaCa.PART_NAMES[partName] or partName]
    if part and part:IsValid() then part:SetVectorParameterValueOnMaterials(FName(WaCa.COAT_COLORS[slot] or slot), color) end
end

-- the player's cat: the customizable mesh on the player's pawn, the player's cat in cutscenes (bIsPlayer), and - only
-- when withPreview is true (pass true while the character creator is open) - the creator's preview cat. The game
-- reuses that preview actor on other screens ("Select Your Cat" shows other cats, e.g. Dapplepatch, with it).
-- a cat's appearance values as one string (FCatCustomData's look fields): two cats with the same fingerprint look
-- the same - the player's cat and its portraits / inventory views; nil for an empty (all-zero) record
WaCa.FINGERPRINT_FIELDS = { "ClanType", "Gender", "BodyValue", "FaceValue", "FurValue", "EyeValue", "WhiskerValue",
    "TailIdx", "EarIdx", "FurIdx", "FurColorIdx", "Pattern01ColorIdx", "Pattern02ColorIdx", "PatternIdx", "MarkingIdx",
    "EyeLeftColorIdx", "EyeRightColorIdx" }
function WaCa.CatFingerprint(d)
    local parts, any = {}, false
    for _, f in ipairs(WaCa.FINGERPRINT_FIELDS) do
        local ok, v = pcall(function() return d[f] end)
        v = ok and v or "?"
        if v ~= 0 and v ~= false and v ~= "?" then any = true end
        table.insert(parts, tostring(v))
    end
    return any and table.concat(parts, ",") or nil
end

-- the GuiCatCustomActor instances (the creator preview, the portrait / headshot and inventory views) with their
-- mesh components
function WaCa.PreviewCats()
    local out = {}
    for _, preview in ipairs(FindAllOf("GuiCatCustomActor") or {}) do
        local comp = preview:IsValid() and preview.CustomizableMeshComponent
        if comp and comp:IsValid() then table.insert(out, comp) end
    end
    return out
end

function WaCa.PlayerCats(withPreview)
    local out = {}
    local pc = FindFirstOf("PlayerController")
    local pawn = pc and pc:IsValid() and pc.Pawn
    local pawnName = pawn and pawn:IsValid() and pawn:GetFullName()
    local playerPrint
    if pawnName then
        for _, comp in ipairs(FindAllOf("SwtAdventureCustomizableMeshComponent") or {}) do
            if comp:IsValid() and comp:GetOwner():GetFullName() == pawnName then
                table.insert(out, comp)
                playerPrint = playerPrint or WaCa.CatFingerprint(comp.CustomData)
            end
        end
    end
    -- preview actors: all of them in the creator; elsewhere only those showing the player's cat (its headshots and
    -- inventory view - "Select Your Cat" reuses one for other cats, which have other values)
    for _, comp in ipairs(WaCa.PreviewCats()) do
        if withPreview or (playerPrint and WaCa.CatFingerprint(comp.CustomData) == playerPrint) then
            table.insert(out, comp)
        end
    end
    -- the player's cat as the creator and cutscenes show it (BP_WrcSK_Customization_Player and friends: a skeletal
    -- mesh actor flagged bIsPlayer)
    for _, actor in ipairs(FindAllOf("WrcCatSkeletalMeshWithCustomization") or {}) do
        if actor:IsValid() and actor.bIsPlayer then
            local comp = actor.MeshCustomizationComponent
            if comp and comp:IsValid() then table.insert(out, comp) end
        end
    end
    return out
end

return WaCa
