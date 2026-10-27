-- The character creator: extra colours in the game's own colour pickers, and a free-form name field on the name screen.
--
-- Colours: the pickers show the GUI manager's palettes (USwtAdventureGuiManager.FurColors / PatternMaskColors /
-- MarkingMaskColors, 25 each); a cat stores an index into them (FurColorIdx / Pattern01ColorIdx / Pattern02ColorIdx).
-- We append config/palette.ini's colours to the palettes, so they appear as swatches. A cat must never keep such an
-- index (a save without the mod would point past the palette): as soon as one is picked, its exact colour goes into
-- the character's look (sidecar [Appearance]) and the index goes back to the nearest of the game's own colours - the
-- look then paints the exact colour on top.
--
-- Name: the name screen gets a text box ("your name"); the game's own name list stays as the ONLINE name (what the
-- save and online features keep). The typed name becomes the character's [Name] Prefix.
--
-- Everything chosen while creating a cat is held as pending and written into the new save slot's sidecar when the
-- game creates that slot (and saved with the game's next save); loading an existing save instead drops it.
local Creator = {}

local WaCa, log, modDir, modsDir, ctx
-- the colour index fields -> their palette, the look's colour slot. Verified in the game's code (2026-10-25 build,
-- 0x1417B2155): "Pattern Mask Color" = PatternMaskColors[Pattern01ColorIdx], "Markings Mask Color" =
-- MarkingMaskColors[Pattern02ColorIdx]; the index is checked against the palette's CURRENT length (so appended colours
-- render, and an index past the end is skipped, never a crash)
local PALETTES = {
    { field = "FurColorIdx", palette = "FurColors", slot = "Fur", section = "Fur" },
    { field = "Pattern01ColorIdx", palette = "PatternMaskColors", slot = "Pattern", section = "Pattern" },
    { field = "Pattern02ColorIdx", palette = "MarkingMaskColors", slot = "Markings", section = "Markings" },
}
local vanillaCount = {}          -- palette -> the game's own colour count (before ours)
local customIndex = {}           -- palette -> the 0-based index of its custom (hex box) swatch, the last one
local extended = false

local pending = nil              -- { Name = {...}, Appearance = {...}, print, closedAt } while creating
local gridRows                   -- the WaCa rows in the creator grids (with GRID_KINDS, below)
local CREATOR_SCREENS = { "GuiScreenSelectClan", "GuiScreenCustomization", "GuiScreenSelectTraits", "GuiScreenSelectName" }

local function hex(c) return string.format("#%02X%02X%02X", c.R, c.G, c.B) end
local function lin(c) c = c / 255; return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4 end

-- the palette colours from config/palette.ini ([Fur] / [Pattern] / [Markings] Colours = #RRGGBB, ...)
local function extendPalettes()
    if extended then return end
    local gm = FindFirstOf("SwtAdventureGuiManager")
    if not gm or not gm:IsValid() then return end
    local ini = WaCa.ReadIni(modDir .. "/config/palette.ini") or {}
    for _, p in ipairs(PALETTES) do
        local arr = gm[p.palette]
        local extras = {}
        local list = ini[p.section] and ini[p.section].Colours or ""
        for text in list:gmatch("[^,%s]+") do
            local h = text:match("^#?(%x%x%x%x%x%x)$")
            if h then table.insert(extras, "#" .. h:upper()) end
        end
        -- already ours (a reload into a running game): the palette ends with our extras + the custom swatch
        local tail = #extras + 1
        local ours = #arr > tail
        for i, h in ipairs(extras) do
            if ours and hex(arr[#arr - tail + i]) ~= h then ours = false end
        end
        if ours then
            vanillaCount[p.palette] = #arr - tail
        else
            vanillaCount[p.palette] = #arr
            for _, h in ipairs(extras) do
                arr[#arr + 1] = { R = tonumber(h:sub(2, 3), 16), G = tonumber(h:sub(4, 5), 16), B = tonumber(h:sub(6, 7), 16), A = 255 }
            end
            -- the CUSTOM swatch, last: its colour is whatever the player types into the picker's hex box
            -- (palette.ini [<slot>] Custom = the starting colour)
            local start = (ini[p.section] and ini[p.section].Custom or ""):match("^#?(%x%x%x%x%x%x)$") or "FFFFFF"
            arr[#arr + 1] = { R = tonumber(start:sub(1, 2), 16), G = tonumber(start:sub(3, 4), 16), B = tonumber(start:sub(5, 6), 16), A = 255 }
        end
        customIndex[p.palette] = #arr - 1
        log("palette %s: %d game colours + %d + the custom swatch%s", p.palette, vanillaCount[p.palette], #extras,
            ours and " (already there)" or "")
    end
    extended = true
end

local function nearestVanilla(arr, count, c)
    local best, bestD = 0, math.huge
    for i = 1, count do
        local v = arr[i]
        local d = (lin(v.R) - lin(c.R)) ^ 2 + (lin(v.G) - lin(c.G)) ^ 2 + (lin(v.B) - lin(c.B)) ^ 2
        if d < bestD then best, bestD = i - 1, d end
    end
    return best
end

-- The screens that are up, by class name -> { full name, ... } (newest last), kept from the ScreenShown / ScreenHidden
-- events. A screen is known by its full name (unique per instance): leaving a screen and coming back makes a new
-- instance while the old one stays findable until garbage collection (about a minute), and a Lua wrapper of a freed
-- widget crashed the game when called (operator 2026-10-25) - so screens are looked up again by name when needed.
local shown = {}
local classes = {}                -- native class name -> UClass (the screens are WBP_* subclasses of these)

local function nativeClass(name)
    local c = classes[name]
    if c and c:IsValid() then return c end
    for _, module in ipairs({ "Wrc", "SwtEngine", "SwtAdventure" }) do
        c = StaticFindObject("/Script/" .. module .. "." .. name)
        if c and c:IsValid() then classes[name] = c return c end
    end
    return nil
end

local function screenId(screen) return screen:GetFullName() end

-- the instance of a screen class that is up (the newest), or nil; anyInstance: also one that was built but is not up
-- (headless tests attach the panel to the real customisation screen, which can't be shown outside the creator flow)
local function shownScreen(cls, anyInstance)
    local list = shown[cls]
    for i = #(list or {}), 1, -1 do
        local s = StaticFindObject((list[i]:gsub("^%S+ ", "")))
        if s and s:IsValid() then return s end
    end
    if anyInstance then
        local last
        for _, s in ipairs(FindAllOf(cls) or {}) do if s:IsValid() then last = s end end
        return last
    end
    return nil
end
Creator.ShownScreen = shownScreen

local function creatorOpen()
    for _, cls in ipairs(CREATOR_SCREENS) do
        if shown[cls] and #shown[cls] > 0 then return true end
    end
    return false
end

-- where a choice goes: the pending creation while creating, else the active save slot
local function store(section, key, value)
    if pending then
        pending[section] = pending[section] or { __order = {} }
        if value == nil then
            -- "no override": the key goes away entirely (an ordered key without a value broke the look merge)
            pending[section][key] = nil
            for i, k in ipairs(pending[section].__order) do
                if k == key then table.remove(pending[section].__order, i) break end
            end
            return
        end
        if pending[section][key] == nil then table.insert(pending[section].__order, key) end
        pending[section][key] = value
    else
        ctx.setSlotValue(section, key, value)
    end
end

-- a custom swatch picked on one of the player's cats (the creator preview included): keep its colour, give the game
-- back one of its own indices
local function sanitize()
    if not extended then return end
    local gm = FindFirstOf("SwtAdventureGuiManager")
    for _, cat in ipairs(WaCa.PlayerCats(creatorOpen())) do
        local d = cat.CustomData
        local changed = false
        for _, p in ipairs(PALETTES) do
            local idx = d[p.field]
            local count = vanillaCount[p.palette]
            if idx and count and idx >= count then
                local arr = gm[p.palette]
                if idx < #arr then
                    local c = arr[idx + 1]
                    local near = nearestVanilla(arr, count, c)
                    store("Appearance", p.slot, hex(c))
                    d[p.field] = near
                    changed = true
                    log("custom %s colour %s chosen (the game keeps its colour #%d)", p.slot, hex(c), near)
                else
                    d[p.field] = 0
                end
            end
        end
        if changed then
            local owner = cat:GetOwner()
            if owner and owner:IsValid() and owner.RefreshPattern then pcall(function() owner:RefreshPattern() end) end
            ctx.refreshLook()
        end
    end
end

-- Widgets are never held across ticks: the game destroys and rebuilds screens (a new one can land at the same address),
-- and a call on a stale Lua wrapper of a freed object crashed the game (operator 2026-10-25, after a long time in the
-- creator). A screen is known by its full name (unique per instance), our widgets are found again by name in its tree.
local function treePath(screen) return (screen.WidgetTree:GetFullName():gsub("^%S+ ", "")) end
local function child(tree, name)
    local o = StaticFindObject(tree .. "." .. name)
    return o and o:IsValid() and o or nil
end

-- the name screen: our text box + label, and the game's list noted as the online name
local function newWidget(className, outer, name)
    local cls = StaticFindObject("/Script/UMG." .. className)
    return StaticConstructObject(cls, outer, FName(name))
end

local function place(canvas, widget, x, y, w, h)
    local slot = canvas:AddChildToCanvas(widget)
    slot:SetAnchors({ Minimum = { X = 0.5, Y = 0.5 }, Maximum = { X = 0.5, Y = 0.5 } })
    slot:SetAlignment({ X = 0.5, Y = 0.5 })
    slot:SetPosition({ X = x, Y = y })
    slot:SetSize({ X = w, Y = h })
end

local creatorCfg, creatorCfgTime = {}, -1
local function cfgValue(key)
    if os.time() - creatorCfgTime >= 5 then          -- read on use, cached a few seconds (edits apply without a restart)
        local ini = WaCa.ReadIni(modDir .. "/config/creator.ini") or {}
        creatorCfg, creatorCfgTime = ini["Creator"] or {}, os.time()
    end
    return creatorCfg[key] or ""
end

-- The name screen flow (operator 2026-10-25): the box sits top right and is part of the flow - the game's "confirm"
-- (Enter / the gamepad's confirm button) on the name list moves INTO the box (Steam's on-screen keyboard on a
-- controller), and confirming in the box goes on to the next screen. The game's own confirm is held back meanwhile
-- (its Button_A / Button_Confirm rows get no key), so Enter on the list can no longer skip the custom name. The
-- creator.ini NameBoxKeys (Tab, the left stick click by default) leave the box without going on.
local CONFIRM_ROWS = { "Button_A", "Button_Confirm" }
-- the screens with a name box: the creator's name screen (your own name = the prefix) and the warrior ceremony's
-- suffix choice (your own warrior suffix)
local NAME_SCREENS = {
    { cls = "GuiScreenSelectName", key = "Prefix", hint = "Your cat's name",
      label = "Your cat's own name (optional) - confirm to type it, confirm again to go on" },
    { cls = "GuiPopupWarriorName", key = "Suffix", hint = "Your warrior suffix",
      label = "Your own warrior suffix (optional, e.g. heart) - confirm to type it, confirm again to go on" },
}
local name = nil   -- { screen, tree, held = { {table, row, key} }, confirmKeys = {key = true}, focused, leaving, steamWait }

local function nameBox() return name and child(name.tree, "WaCaNameBox") or nil end

local function boxKeys()
    local keys = {}
    for k in (cfgValue("NameBoxKeys") ~= "" and cfgValue("NameBoxKeys") or "Tab, Gamepad_LeftThumbstick"):gmatch("[^,%s]+") do
        keys[k] = true
    end
    return keys
end

-- hold back the game's confirm on every menu-key table (keyboard + each gamepad type); the keys are remembered
-- Every row bound to a confirm key is held, not just the confirm rows: a key fires every row it is bound to, and the
-- keyboard table also binds Enter to Button_Skip - with only Button_A / Button_Confirm held, Enter still went on to the
-- next screen through Skip (operator 2026-10-25).
local function holdConfirm()
    if name.held then return end
    name.held, name.confirmKeys = {}, {}
    for _, t in ipairs(WaCa.MenuKeyTables()) do
        local keys = {}
        for _, row in ipairs(CONFIRM_ROWS) do
            local key = WaCa.UIRowKey(t, row)
            if key and key ~= "None" then keys[key] = true; name.confirmKeys[key] = true end
        end
        local tpath = t:GetFullName():gsub("^%S+ ", "")
        local rows = WaCa.UIRows(t)
        if #rows == 0 then rows = CONFIRM_ROWS end
        for _, row in ipairs(rows) do
            local key = WaCa.UIRowKey(t, row)
            if key and keys[key] then
                table.insert(name.held, { t = tpath, row = row, key = key })
                WaCa.SetUIKeyIn(t, row, "None")
            end
        end
    end
    local rowNames = {}
    for _, h in ipairs(name.held) do rowNames[h.row] = true end
    local list = {}
    for r in pairs(rowNames) do table.insert(list, r) end
    table.sort(list)
    log("name screen: the game's confirm goes into the name box first (%d menu rows held: %s)", #name.held,
        table.concat(list, ", "))
end

local function releaseConfirm()
    if not name or not name.held then return end
    for _, h in ipairs(name.held) do
        local t = StaticFindObject(h.t)
        if t and t:IsValid() then WaCa.SetUIKeyIn(t, h.row, h.key) end
    end
    name.held = nil
end

local function focusBox(withController)
    local box = nameBox()
    if not box then return end
    name.wantFocus = true          -- the focus-in event that follows is the box's (HasKeyboardFocus can lag behind it)
    pcall(function() box:SetKeyboardFocus() end)
    if withController then
        name.steamWait = true      -- the full-screen keyboard's answer arrives as the SteamTextInput event
        local existing = box:GetText():ToString():gsub("|", "")
        WaCa.Command("SteamKeyboard|" .. name.spec.hint .. "|" .. existing)
    end
    log("name screen: typing in the name box%s", withController and " (Steam keyboard)" or "")
end

local function leaveBox()
    name.leaving = true
    pcall(function() StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary"):SetFocusToGameViewport() end)
end

-- on to the next screen: the game's confirm comes back, and the screen gets the confirm command it would have had
local function goOn(screen)
    releaseConfirm()
    local pc
    for _, c in ipairs(FindAllOf("SwtPlayerController") or {}) do
        if c:IsValid() and c.Player and c.Player:IsValid() then pc = c end
    end
    local ok, err = pcall(function() screen:OnListenCommand(5, 0, pc) end)     -- Button_A, IE_Pressed
    log("name screen: name done - on to the next screen%s", ok and "" or (" (" .. tostring(err) .. ")"))
end

local function currentValue(key)
    if pending then return pending.Name and pending.Name[key] or "" end
    return ctx.slotValue("Name", key) or ""
end

local function setupNameScreen(screen, spec)
    local canvas = screen.WidgetTree.RootWidget
    if not canvas or not canvas:IsValid() or not canvas.AddChildToCanvas then
        log("name screen: no root canvas")
        return
    end
    local info
    pcall(function() info = screen.mcGuiTextInfo end)
    if info and info:IsValid() then
        local text = info:GetText():ToString()
        if not text:find("online name", 1, true) then
            info:SetText(FText(text .. "  (your online name)"))
        end
    end
    local label = newWidget("TextBlock", screen.WidgetTree, "WaCaNameLabel")
    label:SetText(FText(spec.label))
    local box = newWidget("EditableTextBox", screen.WidgetTree, "WaCaNameBox")
    -- Return in the box commits and lets go of the keyboard: that focus loss is "name done, on to the next screen"
    pcall(function() box.ClearKeyboardFocusOnCommit = true end)
    -- no hint text: the box draws it in the engine's default style (blurry and barely legible - operator 2026-10-25)
    if info and info:IsValid() then
        pcall(function() label:SetFont(info.Font) end)
        pcall(function() box.WidgetStyle.TextStyle.Font = info.Font end)
    end
    box:SetText(FText(currentValue(spec.key)))
    -- top right
    local function corner(widget, y, w, h)
        local slot = canvas:AddChildToCanvas(widget)
        slot:SetAnchors({ Minimum = { X = 1, Y = 0 }, Maximum = { X = 1, Y = 0 } })
        slot:SetAlignment({ X = 1, Y = 0 })
        slot:SetPosition({ X = -80, Y = y })
        slot:SetSize({ X = w, Y = h })
    end
    corner(label, 60, 1100, 80)
    corner(box, 150, 900, 100)
    releaseConfirm()
    name = { spec = spec, screen = screenId(screen), tree = treePath(screen) }
    holdConfirm()
    log("name screen: name box added (top right)")
end

local function storeTyped(box)
    local key = name.spec.key
    local typed = box:GetText():ToString():gsub("^%s+", ""):gsub("%s+$", "")
    if typed ~= currentValue(key) then
        store("Name", key, typed ~= "" and typed or nil)
        log("name %s typed: %s", key:lower(), typed ~= "" and typed or "(the game's)")
    end
end

-- the name screen spec of a screen, or nil
local function nameSpec(screen)
    for _, sp in ipairs(NAME_SCREENS) do
        local cls = nativeClass(sp.cls)
        if cls and screen:IsA(cls) then return sp end
    end
    return nil
end

-- the name screen whose box we manage, when it is this screen
local function ourNameScreen(screen)
    return name and name.screen == screenId(screen) and nameBox() or nil
end

local function nameScreenShown(screen)
    local spec = nameSpec(screen)
    if not spec then return end
    local ok, err = pcall(setupNameScreen, screen, spec)
    if not ok then log("name screen: %s", tostring(err)) end
end

-- the screen goes (back, or on): the last typing is kept, the game's confirm comes back
local function nameScreenHidden(screen)
    local box = ourNameScreen(screen)
    if box then storeTyped(box) end
    if name and name.screen == screenId(screen) then
        releaseConfirm()
        name = nil
    end
end

-- keyboard focus entered / left the name screen's widgets: the box took the keyboard / let it go (Enter in it = on to
-- the next screen; our leave keys = back to the list)
-- The game's own screens don't use keyboard focus (they navigate their own way), so focus entering the name screen IS
-- the box taking it - by our confirm, or a mouse click into it. (HasKeyboardFocus lags behind the event: a click into
-- the box then Return did nothing - operator 2026-10-25.)
local function nameFocusIn(screen)
    if not ourNameScreen(screen) then return end
    name.focused = true
    name.wantFocus = nil
end

local function nameFocusOut(screen)
    local box = ourNameScreen(screen)
    if not box then return end
    storeTyped(box)
    if not name.focused then return end
    name.focused = false
    if name.leaving then name.leaving = false else goOn(screen) end
end

-- Steam's full-screen keyboard answered
local function steamText(submitted, text)
    if not name or not name.steamWait then return end
    name.steamWait = nil
    local screen = shownScreen(name.spec.cls)
    local box = screen and ourNameScreen(screen)
    if not box or submitted ~= "1" then return end
    box:SetText(FText(text or ""))
    storeTyped(box)
    goOn(screen)
end

-- a key on the name screen (the raw key hook): the game's confirm on the list = into the box; a leave key = out
function Creator.NameKey(key)
    if not name or not shownScreen(name.spec.cls) then return end
    local box = nameBox()
    if not box then return end
    local inBox = name.focused or box:HasKeyboardFocus()
    local gamepad = key:find("^Gamepad") ~= nil
    if not inBox and name.confirmKeys and name.confirmKeys[key] then
        focusBox(gamepad)
    elseif inBox and boxKeys()[key] then
        leaveBox()
    elseif not inBox and boxKeys()[key] then
        focusBox(gamepad)
    end
end

-- Creating starts when a creator screen shows. Its choices are kept as "pending" until the created cat shows up in
-- the game: while the creator is open we fingerprint the preview cat's appearance values; the first player cat seen
-- after it closed with the SAME fingerprint is the new cat (its save slot gets the choices, written at once), any
-- other cat means the creation was abandoned (the choices are dropped). The save manager's slot calls are not used:
-- a new character does not add a slot id, and the creation flow need not go through hookable functions.
-- every non-empty preview fingerprint seen while the creator is open (there are several preview actors - the creator
-- preview, portrait and inventory views; the first one found was an empty record and nothing ever matched)
local function previewFingerprints(into)
    for _, comp in ipairs(WaCa.PreviewCats()) do
        local p = WaCa.CatFingerprint(comp.CustomData)
        if p then into[p] = true end
    end
end

-- the creator preview's appearance record (the first non-empty one), for showing the pending name during creation
function Creator.PreviewData()
    local s = shownScreen("GuiScreenSelectName")
    local ref = s and s.CatRef
    local comp = ref and ref:IsValid() and ref.CustomizableMeshComponent
    if comp and comp:IsValid() then return comp.CustomData end
    for _, comp in ipairs(WaCa.PreviewCats()) do
        if WaCa.CatFingerprint(comp.CustomData) then return comp.CustomData end
    end
    return nil
end

-- the name typed in the creator while creating, or nil
function Creator.PendingName()
    return pending and pending.Name and pending.Name.Prefix or nil
end

-- the preview's CURRENT look (an earlier choice must not match later); kept as it was when no preview is left
local function refreshPrints()
    local prints = {}
    previewFingerprints(prints)
    if next(prints) then pending.prints = prints end
end

-- a screen came (ScreenShown, the screen list already updated): a creator screen starts / continues the creation, any
-- other screen closes it. Never decided on ScreenHidden: the game tears a screen down a frame before it builds the
-- next, so between two creator screens none is up (that gap logged "creator closed" on every step - operator
-- 2026-10-25).
local function trackCreation()
    if creatorOpen() then
        if not pending or pending.closedAt and os.time() - pending.closedAt > 10 then
            -- a fresh creation (one abandoned before it would have been dropped at the next player cat anyway)
            pending = {}
            log("character creation started")
        end
        pending.closedAt = nil
        refreshPrints()
    elseif pending and not pending.closedAt then
        pending.closedAt = os.time()
        log("character creator closed (creation pending until the new cat shows up)")
    end
end

-- called with the player's cat (its CustomData) whenever there is one: settles a pending creation
function Creator.OnPlayerCat(customData)
    if not pending or not pending.closedAt then return end
    local print = WaCa.CatFingerprint(customData)
    if print and pending.prints and pending.prints[print] then
        local n = 0
        for _, section in ipairs({ "Name", "Appearance" }) do
            for _, k in ipairs(pending[section] and pending[section].__order or {}) do
                ctx.setSlotValue(section, k, pending[section][k])
                n = n + 1
            end
        end
        ctx.writeSlot()
        log("character creation saved with the new cat's save slot %s (%d values)", tostring(ctx.slotId()), n)
    else
        local seen = {}
        for p in pairs(pending.prints or {}) do table.insert(seen, p) end
        log("character creation dropped (the cat in the game is not the one created: %s vs %s)", tostring(print),
            #seen > 0 and table.concat(seen, " / ") or "none")
    end
    pending = nil
    ctx.refreshLook()
end

-- the active slot changed: nothing to do for a pending creation (settled by OnPlayerCat)
function Creator.OnSlotChanged(id) end

-- is the character creator open? (one of its screens is up, or the creation hasn't closed yet: between two of its
-- screens none is up for a frame or two)
function Creator.IsOpen()
    return creatorOpen() or (pending ~= nil and not pending.closedAt)
end

-- the look to show on the creator preview while creating (pending), or nil
function Creator.PendingLook()
    return pending and (pending.Appearance or { __order = {} }) or nil
end

---------------------------------------------------------------------------------------------------------------------
-- The WaCa panel on the customisation screen: a look preset, and the SHAPE of the pattern / markings from any of the
-- game's patterns or markings (or a pattern pack) - two markings combined, a marking as the pattern ... Clicked with
-- the mouse (a left click on a hovered arrow, seen through the raw key hook) or cycled with F5 / F6 / F7.
local roles = require("wacaroles")
local panel = nil          -- { screen = address, rows = { {key, choices, index, value TextBlock, prev, next} } }

local function sortedEnum(enum, pattern)
    local out = {}
    for k, v in pairs(roles[enum] or {}) do if k:match(pattern) then table.insert(out, { k, v }) end end
    table.sort(out, function(a, b) return a[2] < b[2] end)
    local names = {}
    for _, e in ipairs(out) do table.insert(names, e[1]) end
    return names
end

-- A look's id: "<Name>" = WaCa ModKit's own looks/<Name>.ini, "<Mod>/looks/<File>.ini" = another mod's (the same
-- rule as main.lua's mergeLook). Its file, read.
local function lookIni(id)
    local path = id:find("[/\\]") and (modsDir .. "/" .. id) or (modDir .. "/looks/" .. id .. ".ini")
    return WaCa.ReadIni(path)
end

-- the enabled mods (UE4SS: a mod's enabled.txt, or "<Mod> : 1" in Mods/mods.txt)
local function enabledMods(mods)
    local listed = {}
    local txt = io.open(modsDir .. "/mods.txt", "r")
    if txt then
        for line in txt:lines() do
            local name, on = line:match("^%s*([^:;%s][^:]-)%s*:%s*(%d)")
            if name then listed[name] = on == "1" end
        end
        txt:close()
    end
    local out = {}
    for name, dir in pairs(mods) do
        if type(dir) == "table" and not tostring(name):match("^__") then
            local hasEnabled = false
            for _, f in pairs(dir.__files or {}) do
                if tostring(f.__name):lower() == "enabled.txt" then hasEnabled = true end
            end
            if hasEnabled or listed[name] then out[name] = dir end
        end
    end
    return out
end

-- Looks other mods bring: every enabled mod's looks/*.ini with a [Look] section - a mod is a folder you drop in, no
-- config edit (creator.ini AutoLooks = 0 turns it off). Ids "<Mod>/looks/<File>.ini". Read once per game.
local discovered
local function discoveredLooks()
    if discovered then return discovered end
    discovered = {}
    local ini = WaCa.ReadIni(modDir .. "/config/creator.ini") or {}
    if ((ini["Creator"] or {}).AutoLooks or "1") == "0" then return discovered end
    local ok, err = pcall(function()
        local mods = IterateGameDirectories().Game.Binaries.Win64.ue4ss.Mods
        local own = modDir:match("([^/\\]+)$")
        for name, dir in pairs(enabledMods(mods)) do
            local looks = name ~= own and (dir.looks or dir.Looks)
            for _, f in pairs(looks and looks.__files or {}) do
                local file = tostring(f.__name)
                if file:lower():match("%.ini$") then
                    local id = name .. "/" .. (dir.looks and "looks" or "Looks") .. "/" .. file
                    if (lookIni(id) or {})["Look"] then table.insert(discovered, id) end
                end
            end
        end
    end)
    if not ok then log("looks: other mods' looks not read (%s)", tostring(err)) end
    table.sort(discovered)
    if #discovered > 0 then log("looks from other mods: %s", table.concat(discovered, ", ")) end
    return discovered
end

-- the looks offered (creator.ini Looks, then the other mods') with the row each belongs to: a look file's
-- "Row = Pattern" / "Row = Markings" lists it among that row's shapes (a look that IS a pattern, e.g. Colourpoint);
-- no Row = the Look row
local function offeredLooks()
    local ini = WaCa.ReadIni(modDir .. "/config/creator.ini") or {}
    local out = {}
    local function offer(id)
        local l = lookIni(id)
        local row = l and l["Look"] and l["Look"].Row or ""
        table.insert(out, { name = id, row = row ~= "" and row .. "Mask" or "Look" })
    end
    for name in ((ini["Creator"] or {}).Looks or ""):gmatch("[^,]+") do
        offer((name:gsub("^%s+", ""):gsub("%s+$", "")))
    end
    for _, id in ipairs(discoveredLooks()) do offer(id) end
    return out
end

-- a look's display name: its Label, else the file / look name
local function lookLabel(id)
    local l = lookIni(id)
    local label = l and l["Look"] and l["Look"].Label
    if label and label ~= "" then return label end
    return (id:match("([^/\\]+)%.ini$") or id)
end

local function choicesFor(key)
    local ini = WaCa.ReadIni(modDir .. "/config/creator.ini") or {}
    local cfg = ini["Creator"] or {}
    local list = { { label = "No override", value = nil } }
    for _, l in ipairs(offeredLooks()) do
        if l.row == key then
            table.insert(list, { label = key == "Look" and lookLabel(l.name) or lookLabel(l.name) .. " (WaCa)",
                                 value = key == "Look" and l.name or "look:" .. l.name })
        end
    end
    if key ~= "Look" then
        for _, n in ipairs(sortedEnum("EPatternType", "^P%d")) do table.insert(list, { label = n:gsub("_", " "), value = "game:" .. n }) end
        for _, n in ipairs(sortedEnum("EMarkingType", "^M%d")) do table.insert(list, { label = n:gsub("_", " "), value = "game:" .. n }) end
        for name in (cfg.Packs or ""):gmatch("[^,]+") do
            name = name:gsub("^%s+", ""):gsub("%s+$", "")
            table.insert(list, { label = name .. " (pack)", value = name })
        end
    end
    return list
end

-- the screen that hosts the panel (creator.ini PanelScreen; the customisation screen - other values are for tests)
local function panelScreen()
    local s = cfgValue("PanelScreen")
    return s ~= "" and s or "GuiScreenCustomization"
end
-- debug (creator.ini AttachHidden = 1): attach the panel to the screen even while it isn't shown - for headless tests
-- on the real customisation screen, which can't be shown outside the creator flow
local function attachHidden() return cfgValue("AttachHidden") == "1" end

local ROWS = {
    { key = "Look", label = "Look (F5)", fkey = "F5" },
    { key = "PatternMask", label = "Pattern shape (F6)", fkey = "F6" },
    { key = "MarkingsMask", label = "Markings shape (F7)", fkey = "F7" },
}

-- a copy of a pending section (to revert to when the player backs out of the screen)
local function copySection(s)
    local out = { __order = {} }
    for _, k in ipairs(s and s.__order or {}) do
        if s[k] ~= nil then out[k] = s[k]; table.insert(out.__order, k) end
    end
    return out
end

local function rowText(row)
    return row.choices[row.index].label
end

-- The base-game fallback of a WaCa pattern / markings shape: the game pattern (or marking) the cat really gets, so
-- the game shows the matching colour picker (it hides the pattern colour while the cat has no pattern - operator
-- 2026-10-25, Colourpoint chosen on a cat without a pattern) and other players see the fallback. A game shape is its
-- own fallback; a look names one ("Fallback = P13_Tabby" in its [Look]); a pattern pack: creator.ini PackFallback.
local FALLBACK_FIELD = { PatternMask = { field = "PatternIdx", enum = "EPatternType" },
                         MarkingsMask = { field = "MarkingIdx", enum = "EMarkingType" } }

local function fallbackFor(rowKey, value)
    local f = FALLBACK_FIELD[rowKey]
    if not f or not value then return nil end
    local name = value:match("^game:(.+)$")
    if not name then
        local look = value:match("^look:(.+)$")
        if look then
            local l = lookIni(look)
            name = l and l["Look"] and l["Look"].Fallback
        else
            name = cfgValue("PackFallback")
        end
    end
    local idx = name and roles[f.enum] and roles[f.enum][name]
    return idx and f or nil, idx
end

-- the creator preview cats without a game pattern / marking get the shape's fallback
local function applyFallback(rowKey, value)
    local f, idx = fallbackFor(rowKey, value)
    if not f then return end
    for _, comp in ipairs(WaCa.PreviewCats()) do
        local d = comp.CustomData
        local cur = d[f.field]
        if cur and cur < 0 then
            d[f.field] = idx
            log("creator: %s %d -> %d (the WaCa shape's base-game fallback)", f.field, cur, idx)
        elseif cur then
            -- logged so a "no pattern" value other than a negative one shows up in a player's log
            log("creator: %s stays %d (the cat has its own game shape)", f.field, cur)
        end
    end
end

local function setChoice(row, index)
    row.index = (index - 1) % #row.choices + 1
    local value = row.choices[row.index].value
    store("Appearance", row.key, value)
    applyFallback(row.key, value)
    local value = panel and child(panel.tree, "WaCaPanelValue" .. row.n)
    if value then value:SetText(FText(rowText(row))) end
    log("creator: %s = %s", row.key, rowText(row))
    -- the preview cats are rebuilt by the game, with the new look in the build (main.lua's look hook)
    ctx.refreshLook()
end

local function setupPanel(screen)
    local canvas = screen.WidgetTree.RootWidget
    if not canvas or not canvas:IsValid() or not canvas.AddChildToCanvas then return end
    local font = screen.mcGuiTextNamePanel and screen.mcGuiTextNamePanel:IsValid() and screen.mcGuiTextNamePanel.Font
    local function text(name, s)
        local t = newWidget("TextBlock", screen.WidgetTree, name)
        t:SetText(FText(s))
        if font then pcall(function() t:SetFont(font) end) end
        return t
    end
    local function button(name, s)
        local b = newWidget("Button", screen.WidgetTree, name)
        b:SetContent(text(name .. "Text", s))
        return b
    end
    local function at(widget, x, y, w, h)
        local slot = canvas:AddChildToCanvas(widget)
        slot:SetAnchors({ Minimum = { X = 1, Y = 0.5 }, Maximum = { X = 1, Y = 0.5 } })
        slot:SetAlignment({ X = 0, Y = 0.5 })
        slot:SetPosition({ X = x, Y = y })
        slot:SetSize({ X = w, Y = h })
    end
    -- the same screen again (the panel only needed re-adding): keep the look to revert to from when it first showed
    local snapshot = panel and panel.screen == screenId(screen) and panel.snapshot
        or (pending and copySection(pending.Appearance))
    panel = { screen = screenId(screen), tree = treePath(screen), rows = {}, snapshot = snapshot }
    local look = pending and pending.Appearance or {}
    local rows = {}
    -- What the game's own grids already offer is not repeated here: WaCa pattern / markings looks are entries of
    -- those grids (gridRows), and the game's shapes are its grids too - offered here across rows (a marking as the
    -- pattern shape) only with creator.ini PanelShapes = 1. What's left: pattern packs and whole-look presets. With
    -- nothing left, there is no panel.
    local inGrid = {}
    for _, state in pairs(gridRows) do
        for _, e in ipairs(state.entries) do inGrid["look:" .. e.look] = true end
    end
    local crossShapes = cfgValue("PanelShapes") == "1"
    for _, r in ipairs(ROWS) do
        local choices = {}
        for _, c in ipairs(choicesFor(r.key)) do
            local v = c.value and tostring(c.value) or ""
            if not inGrid[v] and (crossShapes or not v:match("^game:")) then table.insert(choices, c) end
        end
        if #choices > 1 then table.insert(rows, { r = r, choices = choices }) end     -- a row with no choices: hidden
    end
    if #rows == 0 then
        log("customisation screen: no WaCa panel (the game's grids offer every WaCa choice)")
        panel = { screen = screenId(screen), tree = treePath(screen), rows = {}, snapshot = snapshot, empty = true }
        return
    end
    at(text("WaCaPanelTitle", "WaCa ModKit"), -1150, 200, 1000, 80)
    for i, e in ipairs(rows) do
        local r = e.r
        local row = { n = i, key = r.key, fkey = r.fkey, choices = e.choices, index = 1 }
        for j, c in ipairs(row.choices) do if c.value == look[r.key] then row.index = j end end
        local y = 200 + i * 110
        at(text("WaCaPanelLabel" .. i, r.label), -1150, y, 520, 90)
        at(button("WaCaPanelPrev" .. i, "<"), -620, y, 90, 90)
        at(text("WaCaPanelValue" .. i, rowText(row)), -510, y, 380, 90)
        at(button("WaCaPanelNext" .. i, ">"), -120, y, 90, 90)
        panel.rows[i] = row
    end
    log("customisation screen: WaCa panel added")
end

-- the panel's screen when it is the one showing (by its unique name - never a stale object), else nil
local function panelHost()
    return shownScreen(panelScreen(), attachHidden())
end

-- our title still sits in the screen's root canvas (a screen that rebuilds its content drops our widgets, which then
-- linger unattached until garbage collection)
local function panelAttached(screen)
    local title = child(panel.tree, "WaCaPanelTitle")
    local parent = title and title:GetParent()
    local root = screen.WidgetTree.RootWidget
    return parent and parent:IsValid() and root and root:IsValid() and parent:GetFullName() == root:GetFullName()
end

-- the panel on its screen (added, or added again when the screen dropped it)
local function ensurePanel(screen)
    if not screen or not (pending or attachHidden()) then return end
    if not panel or panel.screen ~= screenId(screen) or not (panel.empty or panelAttached(screen)) then
        local ok, err = pcall(setupPanel, screen)
        if not ok then log("customisation screen: %s", tostring(err)) panel = nil end
    end
end

local function isPanelScreen(screen)
    local cls = nativeClass(panelScreen())
    return cls and screen:IsA(cls)
end

-- the panel's screen goes: backed out of (BackSpace / Escape just before) = its WaCa choices are dropped, like the game
-- drops its own; confirmed = they stay
local function panelHidden(screen)
    if not panel or panel.screen ~= screenId(screen) then return end
    if panel.backAt and os.time() - panel.backAt <= 3 and pending and panel.snapshot then
        pending.Appearance = copySection(panel.snapshot)
        log("customisation screen: backed out - WaCa choices reverted")
        ctx.refreshLook()
    end
    panel.backAt = nil
end

-- clicks (a left click while one of our arrows is hovered) and F5 / F6 / F7
local function onKey(name)
    if not panel then return end
    local screen = panelHost()
    if not screen or screenId(screen) ~= panel.screen then return end
    if name == "LeftMouseButton" then
        for _, row in ipairs(panel.rows) do
            local prev, next = child(panel.tree, "WaCaPanelPrev" .. row.n), child(panel.tree, "WaCaPanelNext" .. row.n)
            if prev and prev:IsHovered() then setChoice(row, row.index - 1) return end
            if next and next:IsHovered() then setChoice(row, row.index + 1) return end
        end
    else
        if name == "BackSpace" or name == "Escape" then panel.backAt = os.time() return end
        for _, row in ipairs(panel.rows) do
            if row.fkey == name then setChoice(row, row.index + 1) return end
        end
    end
end

-- the screens we care about that this screen is (native class names)
local function trackedAs(screen)
    local out = {}
    local names = { panelScreen() }
    for _, n in ipairs(CREATOR_SCREENS) do table.insert(names, n) end
    for _, sp in ipairs(NAME_SCREENS) do table.insert(names, sp.cls) end
    for _, n in ipairs(names) do
        local cls = nativeClass(n)
        if cls and screen:IsA(cls) then out[n] = true end
    end
    return out
end

local labelGridItems       -- (defined with the grid entries below)

local function onScreenShown(screen)
    extendPalettes()                         -- the GUI manager exists once screens show
    local id = screenId(screen)
    for n in pairs(trackedAs(screen)) do
        shown[n] = shown[n] or {}
        table.insert(shown[n], id)
    end
    trackCreation()
    sanitize()
    nameScreenShown(screen)
    local customization = nativeClass("GuiScreenCustomization")
    if customization and screen:IsA(customization) then labelGridItems(screen) end
    if isPanelScreen(screen) then ensurePanel(screen) end
    if attachHidden() then ensurePanel(shownScreen(panelScreen(), true)) end
end

local function onScreenHidden(screen)
    local id = screenId(screen)
    nameScreenHidden(screen)
    panelHidden(screen)
    local tracked = trackedAs(screen)
    for n in pairs(tracked) do
        local list = shown[n] or {}
        for i = #list, 1, -1 do if list[i] == id then table.remove(list, i) end end
    end
    -- a creator screen going: the preview still shows the look chosen on it (whether the creator closes is decided
    -- by the next screen to show)
    if pending and not pending.closedAt then
        for _, n in ipairs(CREATOR_SCREENS) do
            if tracked[n] then refreshPrints() break end
        end
    end
end

---------------------------------------------------------------------------------------------------------------------
-- WaCa looks as entries of the game's OWN pattern / markings grids. Each offered look that is a pattern or markings
-- shape (creator.ini Looks, look file "Row = Pattern" / "Row = Markings") becomes a row of the game's table
-- (DT_Patterns / DT_Markings), a copy of its fallback's row (WaCaNative_CloneTableRow), named after the look - the
-- creator lists it like the game's own (its icon: the look's "Icon = /Game/...", else the fallback's). Choosing it
-- stores the look (look:<Name>), and the cat's data keeps the FALLBACK's index: the save stays valid without the mod
-- and other players see the fallback. Choosing one of the game's entries clears the WaCa shape for that slot.
-- Which entry was chosen comes from the grid itself (its navigation's current item), after the panel's own
-- OnGriIdItemChanged - the cat's data can't tell (a copied row has the fallback's type).
local GRID_KINDS = {
    Pattern = { table = "/Game/Gameplay/DataTables/Customization/DT_Patterns.DT_Patterns", typeField = "PatternType",
                enum = "EPatternType", maskKey = "PatternMask", panel = "/Script/Wrc.GuiCustomizationPatternPanel",
                panelField = "mcGuiPatternPanel", ready = "ReadyPatterns" },
    Markings = { table = "/Game/Gameplay/DataTables/Customization/DT_Markings.DT_Markings", typeField = "MarkingType",
                 enum = "EMarkingType", maskKey = "MarkingsMask", panel = "/Script/Wrc.GuiCustomizationMarkingsPanel",
                 panelField = "mcGuiMarkingsPanel", ready = "ReadyMarkings" },
}
gridRows = {}             -- kind -> { vanilla = n, entries = { {look, fallback} ... } in the order added }

local function tableRows(t)
    local names, data = {}, {}
    pcall(function()
        t:ForEachRow(function(name, row)
            table.insert(names, tostring(name))
            table.insert(data, row)
        end)
    end)
    return names, data
end

local function addGridRows()
    for kind, k in pairs(GRID_KINDS) do
        local t = StaticFindObject(k.table)
        if not t or not t:IsValid() then
            local ok, loaded = pcall(LoadAsset, k.table)
            t = ok and loaded or nil
        end
        if not t or not t:IsValid() or not WaCaNative_CloneTableRow then
            log("creator grid: %s table not available - no WaCa entries in it", kind)
        else
            local names, data = tableRows(t)
            -- the game's own rows only: a reload (or a second Started) finds our WaCa_ rows already in the table
            local vanilla = 0
            for _, name in ipairs(names) do
                if not name:match("^WaCa_") then vanilla = vanilla + 1 end
            end
            local state = { vanilla = vanilla, entries = {} }
            for _, l in ipairs(offeredLooks()) do
                if l.row == k.maskKey then
                    local file = lookIni(l.name)
                    local look = file and file["Look"] or {}
                    local fallback = roles[k.enum] and roles[k.enum][look.Fallback or ""]
                    -- the fallback's own row is the source (found by its type); none = the table's first row
                    local source = names[1]
                    for i, row in ipairs(data) do
                        local ok, ty = pcall(function() return row[k.typeField] end)
                        if ok and ty == fallback then source = names[i] break end
                    end
                    local rowName = "WaCa_" .. l.name:gsub("[^%w]", "_")
                    if source and WaCaNative_CloneTableRow(t:GetAddress(), source, rowName) then
                        WaCaNative_SetTableField(t:GetAddress(), rowName, "StringName", lookLabel(l.name))
                        if (look.Icon or "") ~= "" then WaCaNative_SetTableField(t:GetAddress(), rowName, "IconHelper", look.Icon) end
                        table.insert(state.entries, { look = l.name, fallback = fallback })
                        log("creator grid: %s entry %d = %s (fallback %s, copied from %s)", kind,
                            state.vanilla + #state.entries, l.name, tostring(look.Fallback), source)
                    end
                end
            end
            gridRows[kind] = state
        end
    end
end

-- the position (0-based) of the grid's current item, or nil
local function gridPosition(grid)
    local current
    pcall(function() current = grid.GridNavigation.CurrentControl end)
    if not current or not current:IsValid() then return nil end
    local id = current:GetFullName()
    local position
    pcall(function()
        for i = 1, #grid.Items do
            local item = grid.Items[i]
            if item:IsValid() and item:GetFullName() == id then position = i - 1 break end
        end
    end)
    return position
end

-- The game labels its grid items by position ("Pattern 1".."Pattern 23" - the WaCa item would read "Pattern 23" too):
-- once the customisation screen has filled its grids, the WaCa items get their look's label. Items without a name
-- text (the markings grid's) are left as they are.
labelGridItems = function(screen)
    for kind, k in pairs(GRID_KINDS) do
        local state = gridRows[kind]
        if state and #state.entries > 0 then
            pcall(function()
                local grid = screen[k.panelField].mcGuiGrid
                local ready = FindFirstOf("WrcGuiManager")[k.ready]
                local offset = #grid.Items - #ready
                for i = 1, #ready do
                    local entry = ready[i] >= state.vanilla and state.entries[ready[i] - state.vanilla + 1]
                    local item = entry and grid.Items[offset + i]
                    if item and item:IsValid() then
                        local ok = pcall(function() item.mcGuiTextName:SetText(FText(lookLabel(entry.look))) end)
                        local now = "?"
                        pcall(function() now = item.mcGuiTextName:GetText():ToString() end)
                        log("creator grid: %s item %d labelled %s (%s)", kind, offset + i, now, ok and "set" or "no name text")
                    end
                end
            end)
        end
    end
end

local function onGridChanged(kind, panel)
    local state = gridRows[kind]
    local grid
    pcall(function() grid = panel.mcGuiGrid end)
    -- The grid lists UWrcGuiManager.ReadyPatterns / ReadyMarkings: one item per index, in that order - the tables'
    -- row indices, ours included (VM 2026-10-25: ReadyPatterns 0..23 with WaCa_Colourpoint = 23; the items' labels
    -- are generic, "Pattern 1".."Pattern 23"). So a grid position is a row through that list; an index past the game's
    -- own rows is a WaCa entry. The markings grid adds its own items BEFORE the list's (its fill, 0x1418C33D0, adds
    -- them ahead of the loop over ReadyMarkings: 24 items for 21 indices), so the list starts at item (items -
    -- indices); those leading items are the game's. A grid with FEWER items than its list: no mapping.
    if not (state and grid and grid:IsValid()) then return end
    local n, ready = 0, nil
    pcall(function() n = #grid.Items end)
    pcall(function()
        local gm = FindFirstOf("WrcGuiManager")
        ready = kind == "Pattern" and gm.ReadyPatterns or gm.ReadyMarkings
    end)
    local count = 0
    pcall(function() count = #ready end)
    if not state.counted then
        state.counted = true
        log("creator grid: %s grid lists %d items, the ready list %d indices from item %d (the game's rows: %d, WaCa "
            .. "rows: %d)%s", kind, n, count, n - count, state.vanilla, #state.entries,
            n >= count and "" or " - fewer items than indices: no WaCa choice here")
    end
    if n < count then return end
    local position = gridPosition(grid)
    if not position then return end
    local index
    local at = position - (n - count)               -- 0-based place in the ready list; < 0 = a leading game item
    if at >= 0 then pcall(function() index = ready[at + 1] end) end
    if index == nil then index = -1 end
    local k = GRID_KINDS[kind]
    local entry = state.entries[index - state.vanilla + 1]
    local f = FALLBACK_FIELD[k.maskKey]
    if index >= state.vanilla and entry then
        store("Appearance", k.maskKey, "look:" .. entry.look)
        -- the cat's data: the fallback (the game may have stored our row's position)
        for _, comp in ipairs(WaCa.PreviewCats()) do
            local d = comp.CustomData
            if entry.fallback and d[f.field] and d[f.field] >= state.vanilla then d[f.field] = entry.fallback end
        end
        log("creator grid: %s entry %d chosen = %s (the cat keeps %s %s)", kind, position, entry.look, f.field,
            tostring(entry.fallback))
    else
        local had = pending and pending.Appearance and pending.Appearance[k.maskKey]
        if had and tostring(had):match("^look:") then
            store("Appearance", k.maskKey, nil)
            log("creator grid: %s entry %d chosen (a game shape - the WaCa shape is cleared)", kind, position)
        end
    end
    ctx.refreshLook()
end

---------------------------------------------------------------------------------------------------------------------
-- The custom colour: each palette's last swatch is the player's own. Choosing it in the game's colour picker
-- (UGuiPopupColorPicker - its grid lists the palette, one item per colour) shows a hex box on the picker; Enter
-- in the box sets that swatch's colour, and it is stored like any extra swatch (the exact colour in the look, the
-- nearest game colour in the save - sanitize). Which palette the picker shows: the colour panel's selected control.
local COLOUR_CONTROLS = { mcGuiOptionFurColor = "FurColors", mcGuiOptionPattern = "PatternMaskColors",
                          mcGuiOptionMarkings = "MarkingMaskColors" }
local picker = nil               -- { id, palette, box } while a colour picker is up

local function pickerPalette()
    for _, panelObj in ipairs(FindAllOf("GuiCustomizationColorPanel") or {}) do
        -- every object checked before use: GetFName on a NULL reference is a native read of 0x18 inside UE4SS - no
        -- pcall catches that, it took the game down (VM 2026-10-27)
        local ok, name = pcall(function()
            if not panelObj:IsValid() then return nil end
            local control = panelObj.ControlSelected
            return control and control:IsValid() and control:GetFName():ToString() or nil
        end)
        if ok and name and COLOUR_CONTROLS[name] then return COLOUR_CONTROLS[name] end
    end
    return nil
end

local function hexBox()
    local box = picker and picker.box and StaticFindObject(picker.box)
    return box and box:IsValid() and box or nil
end

local function showHexBox(screen, palette)
    if hexBox() then return end
    local canvas = screen.WidgetTree.RootWidget
    if not canvas or not canvas:IsValid() or not canvas.AddChildToCanvas then return end
    local box = newWidget("EditableTextBox", screen.WidgetTree, "WaCaHexBox")
    pcall(function() box.ClearKeyboardFocusOnCommit = true end)
    local arr = FindFirstOf("SwtAdventureGuiManager")[palette]
    box:SetText(FText(hex(arr[customIndex[palette] + 1])))
    local slot = canvas:AddChildToCanvas(box)
    slot:SetAnchors({ Minimum = { X = 1, Y = 0 }, Maximum = { X = 1, Y = 0 } })
    slot:SetAlignment({ X = 1, Y = 0 })
    slot:SetPosition({ X = -80, Y = 150 })
    slot:SetSize({ X = 420, Y = 100 })
    picker.box = box:GetFullName():gsub("^%S+ ", "")
    log("colour picker: custom %s swatch - hex box shown (type #RRGGBB, Enter)", palette)
end

-- the picker's selection moved: the game has just put that colour on the preview cat, so the cat's colour index IS
-- the selected swatch (the picker's grid can't tell: it only keeps the visible swatches - 20 items for a 41-colour
-- palette, reused while scrolling; VM 2026-10-27). The custom swatch's index shows the box.
local function onPickerColour(screen)
    if not picker or not picker.palette then return end
    local field
    for _, e in ipairs(PALETTES) do if e.palette == picker.palette then field = e.field end end
    for _, comp in ipairs(WaCa.PreviewCats()) do
        local ok, idx = pcall(function() return comp.CustomData[field] end)
        local key = comp:GetFullName()
        picker.last = picker.last or {}
        if ok and idx ~= picker.last[key] then
            picker.last[key] = idx
            log("colour picker: %s colour %s selected%s", picker.palette, tostring(idx),
                idx == customIndex[picker.palette] and " (the custom swatch)" or "")
        end
        if ok and idx == customIndex[picker.palette] then
            showHexBox(screen, picker.palette)
            return
        end
    end
end

-- the box let go of the keyboard (Enter commits and clears the focus): its colour, if it is one
local function hexCommitted()
    local box = hexBox()
    if not box or not picker.palette then return end
    local h = box:GetText():ToString():match("^%s*#?(%x%x%x%x%x%x)%s*$")
    if not h then
        log("colour picker: '%s' is not a #RRGGBB colour", box:GetText():ToString())
        return
    end
    local p
    for _, e in ipairs(PALETTES) do if e.palette == picker.palette then p = e end end
    local arr = FindFirstOf("SwtAdventureGuiManager")[picker.palette]
    local c = { R = tonumber(h:sub(1, 2), 16), G = tonumber(h:sub(3, 4), 16), B = tonumber(h:sub(5, 6), 16), A = 255 }
    arr[customIndex[picker.palette] + 1] = c
    -- the swatch on screen too
    pcall(function()
        local screen = StaticFindObject(picker.id)
        local item = screen.mcGuiGrid.Items[customIndex[picker.palette] + 1]
        item.mcGuiColor:SetColorAndOpacity({ R = lin(c.R), G = lin(c.G), B = lin(c.B), A = 1 })
    end)
    store("Appearance", p.slot, hex(c))
    log("custom %s colour %s typed", p.slot, hex(c))
    ctx.refreshLook()
end

function Creator.Init(c)
    ctx = c
    WaCa, log, modDir = c.WaCa, c.log, c.modDir
    modsDir = c.modsDir or (modDir:match("^(.+)[/\\][^/\\]+$") or modDir)
    WaCa.On("ScreenShown", onScreenShown)
    WaCa.On("ScreenHidden", onScreenHidden)
    WaCa.On("ScreenFocusIn", nameFocusIn)
    WaCa.On("ScreenFocusOut", nameFocusOut)
    WaCa.On("SteamTextInput", function(_, submitted, text) steamText(submitted, text) end)
    -- WaCa looks in the game's own pattern / markings grids (rows added once the game is up)
    -- the custom colour swatch: the picker comes, its grid moves, the hex box commits, the picker goes
    WaCa.On("ScreenShown", function(screen)
        local cls = nativeClass("GuiPopupColorPicker")
        if cls and screen:IsA(cls) then
            extendPalettes()
            picker = { id = screenId(screen), palette = pickerPalette() }
            log("colour picker: %s", tostring(picker.palette or "(not a fur / pattern / markings colour)"))
        end
    end)
    WaCa.Watch("OnGridIdColorChanged", "/Script/Wrc.GuiPopupColorPicker", "WaCaPickerColour", "post")
    WaCa.On("WaCaPickerColour", function(screen) onPickerColour(screen) end)
    WaCa.On("ScreenFocusOut", function(screen)
        if picker and screenId(screen) == picker.id then hexCommitted() end
    end)
    WaCa.On("ScreenHidden", function(screen)
        if picker and screenId(screen) == picker.id then picker = nil end
    end)
    WaCa.On("Started", addGridRows)
    -- loaded into a running game (a reload): the tables are there already, and the screens replayed as ScreenShown
    -- come BEFORE Started - so the rows are registered now (adding them again is harmless: an existing row is reused)
    if StaticFindObject(GRID_KINDS.Pattern.table) then pcall(addGridRows) end
    for kind, k in pairs(GRID_KINDS) do
        local event = "WaCaGrid" .. kind
        WaCa.Watch("OnGriIdItemChanged", k.panel, event, "post")
        WaCa.On(event, function(panel) onGridChanged(kind, panel) end)
    end
    -- after a menu command on the panel's screen (it may have rebuilt its content and dropped our widgets)
    pcall(RegisterHook, "/Script/SwtEngine.SwtScreen:OnListenCommand", function() end, function(self)
        local screen = self:get()
        if screen and screen:IsValid() and isPanelScreen(screen) then
            local id = screenId(screen)
            ExecuteInGameThread(function()
                local s = StaticFindObject((id:gsub("^%S+ ", "")))
                if s and s:IsValid() then ensurePanel(s) end
            end)
        end
    end)
    pcall(RegisterHook, "/Script/Wrc.GuiPopupColorPicker:OnGridIdColorChanged", function() end, function()
        ExecuteInGameThread(sanitize)
    end)
    -- raw key presses (KeyDown fires as the key reaches the game window, before the game handles it): the reaction
    -- runs on the next tick, after the game saw the key - focusing the name box on Enter at once let that same Enter
    -- commit the empty box
    WaCa.On("KeyDown", function(_, name)
        ExecuteInGameThread(function() Creator.NameKey(name) end)
        if name == "LeftMouseButton" or name == "F5" or name == "F6" or name == "F7" or name == "BackSpace" or name == "Escape" then
            ExecuteInGameThread(function() onKey(name) end)
        end
    end)
end

return Creator
