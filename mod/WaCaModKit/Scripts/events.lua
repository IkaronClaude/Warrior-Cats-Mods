-- Scenes at given times (tickets.md 17 + 10, "show, don't tell"): things happen on screen at a time of day instead of
-- being told about later. config/events.ini [Event.<Name>]: when (Day / Every / Hour, from the day / night cycle's
-- HourChanged / DayStarted), what (a Card - the game's centre-message popup - and / or a Dialogue - one of the game's
-- own scripted conversations, SwtQuestSequencerManager:PlaySequenceDialogue, with the nearest clanmate), and Once =
-- 1 for one-time scenes (remembered per save, a sidecar written when the game saves). The framework the story fills:
-- the available Dialogue ids are listed into events-dialogues.txt (from the game's own table) at the first world load.
local Events = {}

local WaCa, log, modDir, DayNight
local CARD = "/Game/Art/UXD/Blueprints/Popups/WBP_GuiPopupCenterMessage.WBP_GuiPopupCenterMessage_C"
local list = {}                  -- { name, day, every, hour, card, dialogue, once, seconds }
local done = {}                  -- one-time scenes already played in this save
local restoredFor
local listed = false

local function pc()
    for _, c in ipairs(FindAllOf("SwtPlayerController") or {}) do
        if c:IsValid() and c.Player then return c end
    end
end

local function showCard(text, seconds)
    local ok, err = pcall(function()
        local class = WaCa.LoadAsset(CARD)
        local controller = pc()
        local w = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary"):Create(controller, class, controller)
        w:AddToViewport(60)
        w.mcGuiTextInfo:SetText(FText(text))       -- after AddToViewport (its construct sets a string-table key)
        local name = (w:GetFullName():gsub("^%S+ ", ""))
        ExecuteInGameThreadWithDelay(math.floor(seconds * 1000), function()
            local o = StaticFindObject(name)
            if o and o:IsValid() then o:RemoveFromParent() end
        end)
    end)
    if not ok then log("events: card failed (%s)", tostring(err)) end
end

-- the clanmate nearest to the player's cat (NPC cats: CharacterType Cat)
local function nearestClanmate(pawn)
    local catType
    pcall(function()
        StaticFindObject("/Script/SwtQuest.ESwtQuestCharacterType"):ForEachName(function(n, v)
            if n:ToString():gsub("^.*::", "") == "Cat" then catType = v end
        end)
    end)
    local at, best, bd = pawn:K2_GetActorLocation(), nil, nil
    for _, c in ipairs(FindAllOf("BP_Exploration_Character_Base_C") or {}) do
        pcall(function()
            if c:IsValid() and c.CharacterType == catType and not c.bHidden then
                local p = c:K2_GetActorLocation()
                local d = (p.X - at.X) ^ 2 + (p.Y - at.Y) ^ 2
                if not bd or d < bd then best, bd = c, d end
            end
        end)
    end
    return best
end

local function playDialogue(tag)
    local ok, err = pcall(function()
        local mgr = FindFirstOf("SwtQuestSequencerManager")
        local controller = pc()
        local pawn = controller and controller.Pawn
        if not (mgr and mgr:IsValid() and pawn) then error("no sequencer manager / player") end
        local npc = nearestClanmate(pawn)
        if not npc then error("no clanmate around") end
        mgr:PlaySequenceDialogue({ TagName = FName(tag) }, npc, pawn, false, false)
        log("events: dialogue %s with %s", tag, npc:GetFName():ToString())
    end)
    if not ok then log("events: dialogue %s failed (%s)", tag, tostring(err)) end
end

local function play(e, day)
    log("events: %s (day %d)", e.name, day)
    if e.card then showCard((e.card:gsub("{DAY}", tostring(day))), e.seconds) end
    if e.dialogue then playDialogue(e.dialogue) end
    if e.once then done[e.name] = true end
end

-- the scenes due at this hour of this day
local function due(hour, day)
    if require("menus").InMenu() then return end
    for _, e in ipairs(list) do
        local dayOk = (e.day and day == e.day) or (e.every and (day - (e.day or 1)) % e.every == 0 and day >= (e.day or 1))
            or (not e.day and not e.every)
        if dayOk and hour == e.hour and not done[e.name] then play(e, day) end
    end
end

-- the game's scripted conversations, for events.ini authors (from its own table - no game text in the mod)
local function listDialogues()
    if listed then return end
    listed = true
    pcall(function()
        local mgr = FindFirstOf("SwtQuestSequencerManager")
        local rows = {}
        mgr.DialoguesToUse:ForEachRow(function(name, row)
            local tag = "?"
            pcall(function() tag = row.SequenceDialogueId.TagName:ToString() end)
            table.insert(rows, tag)
        end)
        table.sort(rows)
        local f = io.open(modDir .. "/config/events-dialogues.txt", "w")
        if f then
            f:write("; the game's scripted conversations (events.ini Dialogue = ...), listed from its own table\n")
            f:write(table.concat(rows, "\n") .. "\n")
            f:close()
        end
        log("events: %d dialogue ids listed in config/events-dialogues.txt", #rows)
    end)
end

local function sidecar() return WaCa.SlotFile("WaCaEvents") end

function Events.Init(c)
    WaCa, log, modDir, DayNight = c.WaCa, c.log, c.modDir, c.DayNight
    local ini = WaCa.ReadIni(modDir .. "/config/events.ini") or {}
    if ((ini["Events"] or {}).On or "0") ~= "1" then
        log("events: off")
        return
    end
    for section, sec in pairs(ini) do
        local name = section:match("^Event%.(.+)$")
        if name and tonumber(sec.Hour or "") then
            table.insert(list, { name = name, day = tonumber(sec.Day or ""), every = tonumber(sec.Every or ""),
                hour = math.floor(tonumber(sec.Hour)), card = (sec.Card or "") ~= "" and sec.Card or nil,
                dialogue = (sec.Dialogue or "") ~= "" and sec.Dialogue or nil, once = (sec.Once or "0") == "1",
                seconds = tonumber(sec.CardSeconds or "") or 6 })
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    log("events: on (%d scenes)", #list)
    WaCa.On("HourChanged", function(hour, day) due(hour, day) end)
    WaCa.On("ScreenShown", function(screen)
        if screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then listDialogues() end
    end)
    -- one-time scenes played in this save: restored with the save, written when the game saves
    WaCa.On("GameSaved", function()
        local slot = WaCa.CurrentSlot()
        if slot and restoredFor ~= slot then
            restoredFor = slot
            done = {}
            for k, v in pairs((WaCa.ReadIni(sidecar() or "") or {})["Done"] or {}) do
                if k ~= "__order" and v == "1" then done[k] = true end
            end
        end
        local path = sidecar()
        if path then
            local d = { __order = {} }
            for k in pairs(done) do d[k] = "1" table.insert(d.__order, k) end
            WaCa.WriteIni(path, { Done = d, __order = { "Done" } }, "; WaCa ModKit - one-time scenes played in this save (events.ini)")
        end
    end)
end

return Events
