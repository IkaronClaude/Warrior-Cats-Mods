-- Day / night cycle (tickets.md 4). The game's sky (BP_DayNightSky, one in the world: L_Lights) only switches fixed
-- looks; this moves it through a day: the sun's height (its movable DirectionalLight's pitch), the sun's and the sky
-- light's intensity (dimmed to NightLight at midnight) and the game's own night look (the sky's
-- "PostProcess-night", blended in by weight). config/daynight.ini. One scheduled step every UpdateSeconds while the
-- gameplay HUD is up (an animation step, not a state poll); the sky's own values at the start are the day's.
local DayNight = {}

local WaCa, log, modDir
local cfg = { on = false, dayMinutes = 24, startHour = 8, sunHeight = 60, nightLight = 0.15, nightLook = 1.0, step = 2,
              keep = true, bedHour = nil }
local day = 1                    -- days passed in this save (counted at BedHour, kept with the hour)
local restoredFor                -- the save slot whose hour was restored
local hour
local base                       -- the sky's own values, read once: { sun intensity, sky light intensity, sun yaw }
local running, generation = false, 0

local function sky()
    for _, s in ipairs(FindAllOf("BP_DayNightSky_C") or {}) do
        if s:IsValid() then return s end
    end
end

-- 0 at noon, 1 at midnight, smooth (the sun's elevation curve)
local function nightFactor(h)
    return (1 + math.cos((h - 0) / 24 * 2 * math.pi)) / 2      -- 1 at 0:00, 0 at 12:00
end

local function apply(s)
    local n = nightFactor(hour)
    local light = cfg.nightLight + (1 - cfg.nightLight) * (1 - n)
    local elevation = cfg.sunHeight * math.sin((hour - 6) / 12 * math.pi)      -- up 6:00-18:00, under the horizon at night
    local dl = s.DirectionalLight
    -- (this build's FRotator names its first field "pitch", lower case - a "Pitch" key is silently dropped)
    dl:K2_SetRelativeRotation({ pitch = -math.max(5, elevation), Yaw = base.yaw + (hour - 12) * 15, Roll = 0 }, false, {}, true)
    dl:SetIntensity(base.sun * light)
    s.SkyLight:SetIntensity(base.sky * light)
    local night = s["PostProcess-night"]
    night.bEnabled = n * cfg.nightLook > 0.01
    night.BlendWeight = n * cfg.nightLook
end

local function step(gen)
    ExecuteInGameThreadWithDelay(math.floor(cfg.step * 1000), function()
        if gen ~= generation or not running then return end
        local before = hour
        hour = (hour + cfg.step / (cfg.dayMinutes * 60) * 24) % 24
        -- the day ends at BedHour: DayEnded(nil, day) for other modules (exhaustion, pacing, day scripts)
        local crossed = false
        if not cfg.bedHour then crossed = false
        elseif hour >= before then crossed = before < cfg.bedHour and hour >= cfg.bedHour           -- the same day
        else crossed = before < cfg.bedHour or hour >= cfg.bedHour end                       -- past midnight
        if cfg.bedHour and crossed then
            log("daynight: day %d is over (%02d:00)", day, cfg.bedHour)
            WaCa.Emit("DayEnded", day)
            day = day + 1
        end
        local ok, err = pcall(function()
            local s = sky()
            if s then apply(s) end
        end)
        if not ok then log("daynight: failed (%s)", tostring(err)) end
        local whole = math.floor(hour)
        if whole ~= DayNight.lastHour then
            DayNight.lastHour = whole
            log("daynight: %02d:00", whole)
        end
        step(gen)
    end)
end

-- the hour now (0-24), or nil when the cycle is off - for other modules (day scripts, pacing)
function DayNight.Hour() return cfg.on and hour or nil end
-- the day number of this save (1 = the first), or nil when the cycle is off
function DayNight.Day() return cfg.on and day or nil end

-- KeepTime: the hour and the day count live with the save (a sidecar next to it, written when the GAME saves - like
-- the game's own progress), restored on the first save after loading a character
local function sidecar() return WaCa.SlotFile("WaCaDayNight") end
local function restore()
    local slotNow = WaCa.CurrentSlot()
    if not cfg.keep or not slotNow or restoredFor == slotNow then return end
    restoredFor = slotNow
    local data = WaCa.ReadIni(sidecar() or "") or {}
    local t = data["Time"] or {}
    if tonumber(t.Hour or "") then
        hour = tonumber(t.Hour) % 24
        day = math.max(1, math.floor(tonumber(t.Day or "") or 1))
        log("daynight: back to day %d, %02d:%02d (as saved)", day, math.floor(hour), math.floor(hour % 1 * 60))
    end
end
local function keep()
    if not cfg.keep then return end
    local path = sidecar()
    if not path then return end
    WaCa.WriteIni(path, { Time = { Hour = string.format("%.3f", hour), Day = tostring(day), __order = { "Hour", "Day" } },
        __order = { "Time" } }, "; WaCa ModKit - this save's time of day (daynight.ini KeepTime)")
end

function DayNight.Init(c)
    WaCa, log, modDir = c.WaCa, c.log, c.modDir
    local ini = WaCa.ReadIni(modDir .. "/config/daynight.ini") or {}
    local d = ini["DayNight"] or {}
    cfg.on = (d.On or "0") == "1"
    cfg.dayMinutes = math.max(1, tonumber(d.DayMinutes or "") or cfg.dayMinutes)
    cfg.startHour = tonumber(d.StartHour or "") or cfg.startHour
    cfg.sunHeight = tonumber(d.SunHeight or "") or cfg.sunHeight
    cfg.nightLight = tonumber(d.NightLight or "") or cfg.nightLight
    cfg.nightLook = tonumber(d.NightLook or "") or cfg.nightLook
    cfg.step = math.max(0.5, tonumber(d.UpdateSeconds or "") or cfg.step)
    hour = cfg.startHour % 24
    cfg.keep = (d.KeepTime or "1") ~= "0"
    cfg.bedHour = tonumber(d.BedHour or "")
    log("daynight: %s (a day = %d min, starting %02d:00)", cfg.on and "on" or "off", cfg.dayMinutes, math.floor(hour))
    if not cfg.on then return end
    WaCa.On("GameSaved", function()
        restore()
        keep()
    end)
    WaCa.On("ScreenShown", function(screen)
        if running or not screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then return end
        local s = sky()
        if not s then
            log("daynight: the world has no BP_DayNightSky - no cycle here")
            return
        end
        if not base then
            local ok = pcall(function()
                base = { sun = s.DirectionalLight.Intensity, sky = s.SkyLight.Intensity, yaw = s.DirectionalLight.RelativeRotation.Yaw }
            end)
            if not ok then return end
            log("daynight: the sky's day light: sun %.1f, sky light %.1f", base.sun, base.sky)
        end
        running = true
        generation = generation + 1
        step(generation)
    end)
    WaCa.On("ScreenHidden", function(screen)
        if screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then running = false end
    end)
end

return DayNight
