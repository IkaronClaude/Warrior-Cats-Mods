-- Exhaustion (tickets.md 4, Dredge-style): staying out late and doing too much tires your cat - it walks slower and is
-- worse at hunting and fighting - and sleep (a rest: the time-skip key, timeskip.ini) resets it. Tiredness 0-100 grows
-- every in-game hour awake (PerHour; LateFactor x after LateHour until dawn) and with every duty done (duties.lua);
-- at Tired / Exhausted the effects step in. Kept with the save. Emits TiredFactors(hunt, damage) - hunting.lua folds
-- them into the hunting chance and the combat scaling. config/exhaustion.ini.
local Exhaustion = {}

local WaCa, log, DayNight
local cfg = { on = false, perHour = 4, late = 22, dawn = 5, lateFactor = 2.5, perDuty = 5,
              levels = { { name = "Tired", at = 60, speed = 0.85, hunt = 0.85, damage = 0.9 },
                         { name = "Exhausted", at = 85, speed = 0.65, hunt = 0.6, damage = 0.75 } } }
local CARD = "/Game/Art/UXD/Blueprints/Popups/WBP_GuiPopupCenterMessage.WBP_GuiPopupCenterMessage_C"
local tired = 0
local level = 0                     -- 0 = fresh, 1 = Tired, 2 = Exhausted
local restoredFor

local function pawn()
    for _, c in ipairs(FindAllOf("SwtPlayerController") or {}) do
        if c:IsValid() and c.Player and c.Pawn and c.Pawn:IsValid() then return c.Pawn end
    end
end

local function card(text)
    pcall(function()
        local c
        for _, x in ipairs(FindAllOf("SwtPlayerController") or {}) do if x:IsValid() and x.Player then c = x end end
        local w = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary"):Create(c, WaCa.LoadAsset(CARD), c)
        w:AddToViewport(60)
        w.mcGuiTextInfo:SetText(FText(text))
        local name = (w:GetFullName():gsub("^%S+ ", ""))
        ExecuteInGameThreadWithDelay(6000, function()
            local o = StaticFindObject(name)
            if o and o:IsValid() then o:RemoveFromParent() end
        end)
    end)
end

-- other slow-downs of the cat (WaCa.Emit("SpeedFactor", source, factor), e.g. wading.lua) - the one time dilation is
-- the product of them all and the tiredness
local speedFactors = {}

-- the effects of the current level: walking speed now, hunting / damage through TiredFactors
local function apply()
    local l = cfg.levels[level]
    local speed, hunt, damage = 1, 1, 1
    if l then speed, hunt, damage = l.speed, l.hunt, l.damage end
    for _, f in pairs(speedFactors) do speed = speed * f end
    -- (MaxWalkSpeed is set by the game every frame for its walk / run / crouch states - VM: an override never held;
    -- the cat's own time dilation slows its movement AND animations: a sluggish, tired cat)
    pcall(function() pawn().CustomTimeDilation = speed end)
    WaCa.Emit("TiredFactors", hunt, damage)
end

local function setTired(value, why)
    tired = math.max(0, math.min(100, value))
    local now = 0
    for i, l in ipairs(cfg.levels) do if tired >= l.at then now = i end end
    if now ~= level then
        local was = level
        level = now
        local l = cfg.levels[level]
        log("exhaustion: %s (%.0f, %s)", l and l.name or "rested", tired, why)
        if now > was then card(now == #cfg.levels and "Your cat is exhausted - it needs sleep." or "Your cat is getting tired.")
        else card("Your cat is rested.") end
        apply()
    end
end

function Exhaustion.Tiredness() return tired end

function Exhaustion.Add(points, why) setTired(tired + points, why or "effort") end

local function sidecar() return WaCa.SlotFile("WaCaExhaustion") end

function Exhaustion.Init(c)
    WaCa, log, DayNight = c.WaCa, c.log, c.DayNight
    -- (before any early return: other slow-downs work with exhaustion off too)
    WaCa.On("SpeedFactor", function(source, factor)
        if type(source) ~= "string" then return end
        speedFactors[source] = (factor and factor ~= 1) and factor or nil
        apply()
    end)
    local ini = WaCa.ReadIni(c.modDir .. "/config/exhaustion.ini") or {}
    local e = ini["Exhaustion"] or {}
    cfg.on = (e.On or "0") == "1"
    cfg.perHour = tonumber(e.PerHour or "") or cfg.perHour
    cfg.late = tonumber(e.LateHour or "") or cfg.late
    cfg.dawn = tonumber(e.DawnHour or "") or cfg.dawn
    cfg.lateFactor = tonumber(e.LateFactor or "") or cfg.lateFactor
    cfg.perDuty = tonumber(e.PerDuty or "") or cfg.perDuty
    for i, name in ipairs({ "Tired", "Exhausted" }) do
        local sec = ini[name] or {}
        local l = cfg.levels[i]
        l.at = tonumber(sec.At or "") or l.at
        l.speed = tonumber(sec.Speed or "") or l.speed
        l.hunt = tonumber(sec.Hunt or "") or l.hunt
        l.damage = tonumber(sec.Damage or "") or l.damage
    end
    log("exhaustion: %s", cfg.on and "on" or "off")
    if not cfg.on then return end
    WaCa.On("HourChanged", function(hour)
        local late = hour >= cfg.late or hour < cfg.dawn
        setTired(tired + cfg.perHour * (late and cfg.lateFactor or 1), late and "a late hour" or "an hour awake")
    end)
    WaCa.On("TimeSkipped", function() setTired(0, "slept") end)
    WaCa.On("DutiesJudged", function(_, done) if done and done > 0 then setTired(tired + cfg.perDuty * done, "duties done") end end)
    WaCa.On("ScreenShown", function(screen)
        if screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then apply() end
    end)
    WaCa.On("GameSaved", function()
        local slot = WaCa.CurrentSlot()
        if slot and restoredFor ~= slot then
            restoredFor = slot
            local t = (WaCa.ReadIni(sidecar() or "") or {})["Exhaustion"] or {}
            if tonumber(t.Tiredness or "") then setTired(tonumber(t.Tiredness), "as saved") end
        end
        local path = sidecar()
        if path then
            WaCa.WriteIni(path, { Exhaustion = { Tiredness = string.format("%.1f", tired), __order = { "Tiredness" } },
                __order = { "Exhaustion" } }, "; WaCa ModKit - your cat's tiredness (exhaustion.ini)")
        end
    end)
end

return Exhaustion
