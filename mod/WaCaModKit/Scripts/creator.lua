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

local pending = nil              -- { Name = {...}, Appearance = {...}, knownSlots = {id = true} } while creating
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

local function creatorOpen()
    for _, cls in ipairs(CREATOR_SCREENS) do
        local s = FindFirstOf(cls)
        if s and s:IsValid() and s:IsInViewport() then return true end
    end
    return false
end

-- where a choice goes: the pending creation while creating, else the active save slot
local function store(section, key, value)
    if pending then
        pending[section] = pending[section] or { __order = {} }
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
local nameScreen, nameTree = nil, nil
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

local function setupNameScreen(screen)
    local canvas = screen.WidgetTree.RootWidget
    if not canvas or not canvas:IsValid() or not canvas.AddChildToCanvas then
        log("name screen: no root canvas")
        return
    end
    local info = screen.mcGuiTextInfo
    -- the game's list: the online name
    if info and info:IsValid() then
        local text = info:GetText():ToString()
        if not text:find("online name", 1, true) then
            info:SetText(FText(text .. "  (your online name - type your own name in the box)"))
        end
    end
    local nameLabel = newWidget("TextBlock", screen.WidgetTree, "WaCaNameLabel")
    nameLabel:SetText(FText("Your name (any text - empty = the online name)"))
    local nameBox = newWidget("EditableTextBox", screen.WidgetTree, "WaCaNameBox")
    nameBox:SetHintText(FText("Type your cat's name"))
    if info and info:IsValid() then
        pcall(function() nameLabel:SetFont(info.Font) end)
        pcall(function() nameBox.WidgetStyle.TextStyle.Font = info.Font end)
    end
    local current = pending and pending.Name and pending.Name.Prefix or ""
    nameBox:SetText(FText(current))
    place(canvas, nameLabel, 1250, -150, 1100, 90)
    place(canvas, nameBox, 1250, -40, 1100, 110)
    nameScreen, nameTree = screenId(screen), treePath(screen)
    log("name screen: name box added")
end

local function updateNameScreen()
    local screen = FindFirstOf("GuiScreenSelectName")
    if not screen or not screen:IsValid() or not screen:IsInViewport() then return end
    local box = nameScreen == screenId(screen) and child(nameTree, "WaCaNameBox") or nil
    if not box then
        local ok, err = pcall(setupNameScreen, screen)
        if not ok then log("name screen: %s", tostring(err)) end
        return
    end
    local typed = box:GetText():ToString():gsub("^%s+", ""):gsub("%s+$", "")
    local now
    if pending then now = pending.Name and pending.Name.Prefix or ""
    else now = ctx.slotValue("Name", "Prefix") or "" end
    if typed ~= now then
        store("Name", "Prefix", typed ~= "" and typed or nil)
        log("name typed: %s", typed ~= "" and typed or "(the online name)")
    end
end

-- creating starts when a creator screen shows; its choices go to the save slot the game creates next
local justCommitted = false      -- a creation was saved: the next one starts only after the creator closed
local function trackCreation()
    local open = creatorOpen()
    if not open then justCommitted = false end
    if open and not justCommitted then
        if not pending then
            pending = { knownSlots = {} }
            local sm = FindFirstOf("SwtSaveManager")
            local sg = sm and sm:IsValid() and sm.SaveGame
            if sg and sg:IsValid() then
                for i = 1, #sg.saveSlots do pending.knownSlots[sg.saveSlots[i]:ToString()] = true end
            end
            log("character creation started")
        end
    end
end

-- the active slot changed: a NEW slot is the created cat's (pending goes there), an existing one drops pending
function Creator.OnSlotChanged(id)
    if not pending or not id then return end
    if pending.knownSlots[id] then
        if not creatorOpen() then
            pending = nil
            log("character creation dropped (an existing save was loaded)")
        end
        return
    end
    for _, section in ipairs({ "Name", "Appearance" }) do
        for _, k in ipairs(pending[section] and pending[section].__order or {}) do
            ctx.setSlotValue(section, k, pending[section][k])
        end
    end
    log("character creation saved with the new save slot %s", id)
    pending = nil
    justCommitted = creatorOpen()
end

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

local function choicesFor(key)
    local ini = WaCa.ReadIni(modDir .. "/config/creator.ini") or {}
    local cfg = ini["Creator"] or {}
    local list = { { label = "(the game's)", value = nil } }
    if key == "Look" then
        for name in (cfg.Looks or ""):gmatch("[^,]+") do
            name = name:gsub("^%s+", ""):gsub("%s+$", "")
            table.insert(list, { label = name, value = name })
        end
    else
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
local creatorCfg, creatorCfgTime = {}, -1
local function cfgValue(key)
    if os.time() - creatorCfgTime >= 5 then          -- the panel polls often: re-read creator.ini every few seconds
        local ini = WaCa.ReadIni(modDir .. "/config/creator.ini") or {}
        creatorCfg, creatorCfgTime = ini["Creator"] or {}, os.time()
    end
    return creatorCfg[key] or ""
end
local function panelScreen()
    local s = cfgValue("PanelScreen")
    return s ~= "" and s or "GuiScreenCustomization"
end
-- debug (creator.ini AttachHidden = 1): attach the panel to the screen even while it isn't shown - for headless tests
-- on the real customisation screen, which can't be shown outside the creator flow
local function attachHidden() return cfgValue("AttachHidden") == "1" end

local ROWS = {
    { key = "Look", label = "Look (F5)" },
    { key = "PatternMask", label = "Pattern shape (F6)" },
    { key = "MarkingsMask", label = "Markings shape (F7)" },
}

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
    panel = { screen = screenId(screen), tree = treePath(screen), rows = {} }
    at(text("WaCaPanelTitle", "WaCa ModKit"), -1150, 200, 1000, 80)
    local look = pending and pending.Appearance or {}
    for i, r in ipairs(ROWS) do
        local row = { n = i, key = r.key, choices = choicesFor(r.key), index = 1 }
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
    local screen = FindFirstOf(panelScreen())
    if not screen or not screen:IsValid() or not (screen:IsInViewport() or attachHidden()) then return nil end
    return screen
end

local function updatePanel()
    local screen = panelHost()
    if not screen then return end
    if not panel or panel.screen ~= screenId(screen) or not child(panel.tree, "WaCaPanelTitle") then
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
        local n = ({ F5 = 1, F6 = 2, F7 = 3 })[name]
        if n and panel.rows[n] then setChoice(panel.rows[n], panel.rows[n].index + 1) end
    end
end

-- the name screen, polled often (typing then confirming quickly must not lose the last letters)
function Creator.FastTick()
    if pending then updateNameScreen() end
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
        if ok and (name == "LeftMouseButton" or name == "F5" or name == "F6" or name == "F7") then
            ExecuteInGameThread(function() onKey(name) end)
        end
    end)
end

return Creator
