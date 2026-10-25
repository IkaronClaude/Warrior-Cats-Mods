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

local WaCa, log, modDir, ctx
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
local extended = false

local pending = nil              -- { Name = {...}, Appearance = {...}, print, closedAt } while creating
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
        vanillaCount[p.palette] = #arr
        local list = ini[p.section] and ini[p.section].Colours or ""
        local n = 0
        for text in list:gmatch("[^,%s]+") do
            local h = text:match("^#?(%x%x%x%x%x%x)$")
            if h then
                arr[#arr + 1] = { R = tonumber(h:sub(1, 2), 16), G = tonumber(h:sub(3, 4), 16), B = tonumber(h:sub(5, 6), 16), A = 255 }
                n = n + 1
            end
        end
        log("palette %s: %d game colours + %d", p.palette, vanillaCount[p.palette], n)
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

-- the instance of a screen class that is showing (or, with anyInstance, the newest one). Never FindFirstOf: leaving a
-- screen and coming back makes a new instance, and the old hidden one stays findable until garbage collection runs
-- (about a minute) - the WaCa panel vanished for that long (operator 2026-10-25).
local function shownScreen(cls, anyInstance)
    local last
    for _, s in ipairs(FindAllOf(cls) or {}) do
        if s:IsValid() then
            if s:IsInViewport() then return s end
            last = s
        end
    end
    return anyInstance and last or nil
end
Creator.ShownScreen = shownScreen

local function creatorOpen()
    for _, cls in ipairs(CREATOR_SCREENS) do
        if shownScreen(cls) then return true end
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
local function screenId(screen) return screen:GetFullName() end
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
    if os.time() - creatorCfgTime >= 5 then          -- the panel polls often: re-read creator.ini every few seconds
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
local function holdConfirm()
    if name.held then return end
    name.held, name.confirmKeys = {}, {}
    for _, t in ipairs(WaCa.MenuKeyTables()) do
        for _, row in ipairs(CONFIRM_ROWS) do
            local key = WaCa.UIRowKey(t, row)
            if key and key ~= "None" then
                table.insert(name.held, { t = t:GetFullName():gsub("^%S+ ", ""), row = row, key = key })
                name.confirmKeys[key] = true
                WaCa.SetUIKeyIn(t, row, "None")
            end
        end
    end
    log("name screen: the game's confirm goes into the name box first (%d menu rows held)", #name.held)
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
    pcall(function() box:SetKeyboardFocus() end)
    name.focused = true
    if withController then
        name.steamWait = ctx.modDir .. "/steamtext.result"
        local existing = box:GetText():ToString():gsub("|", "")
        WaCa.Command("SteamKeyboard|" .. name.spec.hint .. "|" .. existing .. "|" .. name.steamWait)
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

local function updateNameScreen()
    local screen, spec
    for _, sp in ipairs(NAME_SCREENS) do
        screen = shownScreen(sp.cls)
        if screen then spec = sp break end
    end
    if not screen then
        if name then releaseConfirm(); name = nil end      -- left the screen (back, or on): the game's confirm back
        return
    end
    local box = name and name.screen == screenId(screen) and nameBox() or nil
    if not box then
        local ok, err = pcall(setupNameScreen, screen, spec)
        if not ok then log("name screen: %s", tostring(err)) end
        return
    end
    storeTyped(box)
    -- Steam's full-screen keyboard answered
    if name.steamWait then
        local f = io.open(name.steamWait, "rb")
        if f then
            local submitted = f:read("l")
            local text = f:read("a") or ""
            f:close()
            os.remove(name.steamWait)
            name.steamWait = nil
            if submitted == "1" then
                box:SetText(FText(text))
                storeTyped(box)
                goOn(screen)
                return
            end
        end
    end
    -- the box let go of the keyboard: confirmed in it (Enter) = on to the next screen; our leave keys = back to the list
    local focused = box:HasKeyboardFocus()
    if name.focused and not focused then
        name.focused = false
        if name.leaving then name.leaving = false else goOn(screen) end
    end
end

-- a key on the name screen (the raw key hook): the game's confirm on the list = into the box; a leave key = out
function Creator.NameKey(key)
    if not name or not shownScreen(name.spec.cls) then return end
    local box = nameBox()
    if not box then return end
    local inBox = box:HasKeyboardFocus()
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

local function trackCreation()
    local open = creatorOpen()
    if open then
        if not pending or pending.closedAt and os.time() - pending.closedAt > 10 then
            -- a fresh creation (one abandoned before it would have been dropped at the next player cat anyway)
            pending = {}
            log("character creation started")
        end
        pending.closedAt = nil
        pending.prints = {}                  -- the CURRENT look only: an earlier choice must not match later
        previewFingerprints(pending.prints)
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

-- is one of the character creator's screens showing?
function Creator.IsOpen()
    return creatorOpen()
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

-- the looks offered (creator.ini Looks) with the row each belongs to: a look file's "Row = Pattern" / "Row =
-- Markings" lists it among that row's shapes (a look that IS a pattern, e.g. Colourpoint); no Row = the Look row
local function offeredLooks()
    local ini = WaCa.ReadIni(modDir .. "/config/creator.ini") or {}
    local out = {}
    for name in ((ini["Creator"] or {}).Looks or ""):gmatch("[^,]+") do
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        local l = WaCa.ReadIni(modDir .. "/looks/" .. name .. ".ini")
        local row = l and l["Look"] and l["Look"].Row or ""
        table.insert(out, { name = name, row = row ~= "" and row .. "Mask" or "Look" })
    end
    return out
end

local function choicesFor(key)
    local ini = WaCa.ReadIni(modDir .. "/config/creator.ini") or {}
    local cfg = ini["Creator"] or {}
    local list = { { label = "No override", value = nil } }
    for _, l in ipairs(offeredLooks()) do
        if l.row == key then
            table.insert(list, { label = key == "Look" and l.name or l.name .. " (WaCa)",
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

local function setChoice(row, index)
    row.index = (index - 1) % #row.choices + 1
    local value = row.choices[row.index].value
    store("Appearance", row.key, value)
    local value = panel and child(panel.tree, "WaCaPanelValue" .. row.n)
    if value then value:SetText(FText(rowText(row))) end
    log("creator: %s = %s", row.key, rowText(row))
    -- back to the game's own look first (a mask set earlier stays otherwise), then ours on top
    for _, actor in ipairs(FindAllOf("GuiCatCustomActor") or {}) do
        if actor:IsValid() then pcall(function() actor:RefreshPattern() end) end
    end
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
    at(text("WaCaPanelTitle", "WaCa ModKit"), -1150, 200, 1000, 80)
    local look = pending and pending.Appearance or {}
    local rows = {}
    for _, r in ipairs(ROWS) do
        local choices = choicesFor(r.key)
        if #choices > 1 then table.insert(rows, { r = r, choices = choices }) end     -- a row with no choices: hidden
    end
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

local function updatePanel()
    local screen = panelHost()
    if not screen then
        -- the screen went away: backed out of (BackSpace / Escape just before) = its WaCa choices are dropped, like the
        -- game drops its own; confirmed = they stay
        if panel and panel.backAt and os.time() - panel.backAt <= 3 and pending and panel.snapshot then
            pending.Appearance = copySection(panel.snapshot)
            log("customisation screen: backed out - WaCa choices reverted")
            ctx.refreshLook()
        end
        if panel then panel.backAt = nil end
        return
    end
    if not panel or panel.screen ~= screenId(screen) or not panelAttached(screen) then
        local ok, err = pcall(setupPanel, screen)
        if not ok then log("customisation screen: %s", tostring(err)) panel = nil end
    end
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

-- the name screen, polled often (typing then confirming quickly must not lose the last letters)
function Creator.FastTick()
    updateNameScreen()
    if pending or attachHidden() then updatePanel() end
end

function Creator.Tick()
    extendPalettes()
    trackCreation()
    sanitize()
    updateNameScreen()
end

function Creator.Init(c)
    ctx = c
    WaCa, log, modDir = c.WaCa, c.log, c.modDir
    pcall(RegisterHook, "/Script/Wrc.GuiPopupColorPicker:OnGridIdColorChanged", function() end, function()
        ExecuteInGameThread(sanitize)
    end)
    pcall(RegisterHook, "/Script/SwtEngine.SwtPlayerController:OnKeyPressed", function(_, key)
        local ok, name = pcall(function() return key:get().KeyName:ToString() end)
        if ok then
            local k = name
            ExecuteInGameThread(function() Creator.NameKey(k) end)
        end
        if ok and (name == "LeftMouseButton" or name == "F5" or name == "F6" or name == "F7" or name == "BackSpace" or name == "Escape") then
            ExecuteInGameThread(function() onKey(name) end)
        end
    end)
end

return Creator
