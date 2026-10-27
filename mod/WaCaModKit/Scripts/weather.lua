-- Seasons and weather (tickets.md 21). config/weather.ini. World state other modules read and react to:
--   Weather.Season() / Weather.Current()          the season / weather now (nil when off)
--   events SeasonChanged(name, previous), WeatherChanged(name, previous), WorldFactors(hunt, fish)
-- The season follows the save's day count (daynight.lua counts the days; without the cycle the season stays
-- StartSeason). Weather comes in spells rolled from the season's chances, counted down in in-game hours (daynight's
-- HourChanged) - no timers of its own except the look's fade. The look goes through DayNight.SetLook (light, sky
-- light, fog, sunlight tint, the season's day length / night light); an Effect / Sound asset (rain from the WaCa
-- content pak) plays around the player's cat while its weather lasts.
local Weather = {}

local WaCa, log, modDir, DayNight
local cfg = { on = false, order = {}, start = 1, days = 7, minHours = 3, maxHours = 10, fade = 20,
              seasons = {}, weathers = {} }
local season, current, hoursLeft
local restoredFor
local shown = { look = nil, gen = 0 }            -- the look on screen now (faded towards the target)
local effect = { name = nil }                    -- the playing weather effect / sound

local function player()
    for _, c in ipairs(FindAllOf("SwtPlayerController") or {}) do
        if c:IsValid() and c.Player and c.Pawn and c.Pawn:IsValid() then return c.Pawn end
    end
end

local function numbers(s)
    if not s or s == "" then return nil end
    local out = {}
    for n in s:gmatch("[^,]+") do table.insert(out, tonumber((n:gsub("%s", ""))) or 1) end
    return #out == 3 and out or nil
end

-- a [Season.*] / [Weather.*] section as a look + factors
local function readLook(sec)
    sec = sec or {}
    return { light = tonumber(sec.Light or ""), sky = tonumber(sec.Sky or ""), fog = tonumber(sec.Fog or ""),
             color = numbers(sec.Color), dayMinutes = tonumber(sec.DayMinutes or ""),
             nightLight = tonumber(sec.NightLight or ""), hunt = tonumber(sec.Hunt or "") or 1,
             fish = tonumber(sec.Fish or "") or 1, effect = sec.Effect ~= "" and sec.Effect or nil,
             sound = sec.Sound ~= "" and sec.Sound or nil, chances = {} }
end

-- "Clear=50, Rain=25" -> { {name, weight}, ... } in order
local function chances(s)
    local out = {}
    for name, w in (s or ""):gmatch("([^=,%s]+)%s*=%s*([%d%.]+)") do table.insert(out, { name, tonumber(w) }) end
    return out
end

local function seasonFor(day)
    if #cfg.order == 0 then return nil end
    local i = cfg.start
    if day then i = (cfg.start - 1 + math.floor((day - 1) / cfg.days)) % #cfg.order + 1 end
    return cfg.order[i]
end

local function rollWeather()
    local list = (cfg.seasons[season] or {}).chances or {}
    local total = 0
    for _, c in ipairs(list) do total = total + c[2] end
    if total <= 0 then return "Clear" end
    local r = math.random() * total
    for _, c in ipairs(list) do
        r = r - c[2]
        if r < 0 then return c[1] end
    end
    return list[#list][1]
end

-- the target look: the season's and the weather's multiplied (the season's overrides kept)
local function target()
    local s, w = cfg.seasons[season] or {}, cfg.weathers[current] or {}
    local function mul(a, b) return (a or 1) * (b or 1) end
    local sc, wc = s.color or { 1, 1, 1 }, w.color or { 1, 1, 1 }
    return { light = mul(s.light, w.light), sky = mul(s.sky, w.sky), fog = mul(s.fog, w.fog),
             color = { sc[1] * wc[1], sc[2] * wc[2], sc[3] * wc[3] },
             dayMinutes = s.dayMinutes, nightLight = s.nightLight }
end

-- fade the look on screen to the target over FadeSeconds (10 steps - an animation, ends by itself)
local function fadeLook()
    local to = target()
    local from = shown.look or to
    shown.gen = shown.gen + 1
    local gen, steps = shown.gen, (cfg.fade > 0 and shown.look) and 10 or 1
    local function lerp(a, b, t) return a + (b - a) * t end
    local function at(i)
        if gen ~= shown.gen then return end
        local t = i / steps
        shown.look = { light = lerp(from.light, to.light, t), sky = lerp(from.sky, to.sky, t), fog = lerp(from.fog, to.fog, t),
                       color = { lerp(from.color[1], to.color[1], t), lerp(from.color[2], to.color[2], t),
                                 lerp(from.color[3], to.color[3], t) },
                       dayMinutes = to.dayMinutes, nightLight = to.nightLight }
        DayNight.SetLook("weather", shown.look)
        if i < steps then
            ExecuteInGameThreadWithDelay(math.floor(cfg.fade * 1000 / steps), function() at(i + 1) end)
        end
    end
    at(1)
end

local function stopEffect()
    pcall(function()
        if effect.particles and effect.particles:IsValid() then effect.particles:DestroyComponent(effect.particles) end
    end)
    pcall(function()
        if effect.audio and effect.audio:IsValid() then effect.audio:FadeOut(3.0, 0.0, 0) end
    end)
    effect.particles, effect.audio, effect.name = nil, nil, nil
end

-- the weather's Effect (a Niagara system, attached to the player's cat) and Sound (2D, looping asset)
local function startEffect()
    local w = cfg.weathers[current] or {}
    if effect.name == current and ((effect.particles and effect.particles:IsValid()) or not w.effect) then return end
    stopEffect()
    if not w.effect and not w.sound then return end
    local pawn = player()
    if not pawn then return end
    effect.name = current
    if w.effect then
        local ok, err = pcall(function()
            local system = LoadAsset(w.effect)
            if not system or not system:IsValid() then error("not loadable: " .. w.effect) end
            local lib = StaticFindObject("/Script/Niagara.Default__NiagaraFunctionLibrary")
            effect.particles = lib:SpawnSystemAttached(system, pawn.RootComponent, FName("None"), { X = 0, Y = 0, Z = 0 },
                { pitch = 0, Yaw = 0, Roll = 0 }, 0, false, true, 0, false)
        end)
        if not ok then log("weather: %s effect failed (%s)", current, tostring(err)) end
    end
    if w.sound then
        local ok, err = pcall(function()
            local sound = LoadAsset(w.sound)
            if not sound or not sound:IsValid() then error("not loadable: " .. w.sound) end
            local gs = StaticFindObject("/Script/Engine.Default__GameplayStatics")
            effect.audio = gs:SpawnSound2D(pawn, sound, 1.0, 1.0, 0.0, nil, false, true)
            if effect.audio and effect.audio:IsValid() then effect.audio:FadeIn(3.0, 1.0, 0.0, 0) end
        end)
        if not ok then log("weather: %s sound failed (%s)", current, tostring(err)) end
    end
end

local function factors()
    local s, w = cfg.seasons[season] or {}, cfg.weathers[current] or {}
    local hunt, fish = (s.hunt or 1) * (w.hunt or 1), (s.fish or 1) * (w.fish or 1)
    WaCa.Emit("WorldFactors", hunt, fish)
    return hunt, fish
end

local function setWeather(name, hours, why)
    local previous = current
    current = name
    hoursLeft = hours
    local hunt, fish = factors()
    log("weather: %s for %d h (%s; %s) - hunting x%.2f, fishing x%.2f", current, hoursLeft, season or "no season",
        why, hunt, fish)
    if previous ~= current then WaCa.Emit("WeatherChanged", current, previous) end
    fadeLook()
    startEffect()
end

local function newSpell(why)
    setWeather(rollWeather(), math.random(cfg.minHours, math.max(cfg.minHours, cfg.maxHours)), why)
end

local function updateSeason(why)
    local now = seasonFor(DayNight.Day())
    if now == season then return end
    local previous = season
    season = now
    log("weather: the season is %s (%s)", season, why)
    WaCa.Emit("SeasonChanged", season, previous)
    newSpell("new season")
end

function Weather.Season() return cfg.on and season or nil end
function Weather.Current() return cfg.on and current or nil end
-- the hunting / fishing chance factors of the season and weather now (1, 1 when off)
function Weather.Factors()
    if not cfg.on then return 1, 1 end
    local s, w = cfg.seasons[season] or {}, cfg.weathers[current] or {}
    return (s.hunt or 1) * (w.hunt or 1), (s.fish or 1) * (w.fish or 1)
end
-- force a weather (dev / day scripts): Weather.Set("Rain", 6)
function Weather.Set(name, hours)
    if not cfg.weathers[name] then return false end
    setWeather(name, hours or cfg.minHours, "set")
    return true
end

-- the weather lives with the save (a sidecar, written when the game saves - like daynight's time)
local function sidecar() return WaCa.SlotFile("WaCaWeather") end
local function restore()
    local slotNow = WaCa.CurrentSlot()
    if not slotNow or restoredFor == slotNow then return end
    restoredFor = slotNow
    local w = (WaCa.ReadIni(sidecar() or "") or {})["Weather"] or {}
    updateSeason("save loaded")
    if w.Kind and cfg.weathers[w.Kind] then
        setWeather(w.Kind, math.max(1, tonumber(w.HoursLeft or "") or cfg.minHours), "as saved")
    end
end
local function keep()
    local path = sidecar()
    if not path or not current then return end
    WaCa.WriteIni(path, { Weather = { Kind = current, HoursLeft = tostring(hoursLeft), __order = { "Kind", "HoursLeft" } },
        __order = { "Weather" } }, "; WaCa ModKit - this save's weather (weather.ini)")
end

function Weather.Init(c)
    WaCa, log, modDir, DayNight = c.WaCa, c.log, c.modDir, c.DayNight
    local ini = WaCa.ReadIni(modDir .. "/config/weather.ini") or {}
    local s = ini["Seasons"] or {}
    cfg.on = (s.On or "0") == "1"
    for name in (s.Order or ""):gmatch("[^,]+") do table.insert(cfg.order, (name:gsub("^%s+", ""):gsub("%s+$", ""))) end
    for i, name in ipairs(cfg.order) do
        if name == (s.StartSeason or "") then cfg.start = i end
        local sec = ini["Season." .. name]
        cfg.seasons[name] = readLook(sec)
        cfg.seasons[name].chances = chances((sec or {}).Weather)
    end
    cfg.days = math.max(1, tonumber(s.DaysPerSeason or "") or cfg.days)
    local w = ini["Weather"] or {}
    cfg.minHours = math.max(1, math.floor(tonumber(w.MinHours or "") or cfg.minHours))
    cfg.maxHours = math.max(cfg.minHours, math.floor(tonumber(w.MaxHours or "") or cfg.maxHours))
    cfg.fade = math.max(0, tonumber(w.FadeSeconds or "") or cfg.fade)
    for section, sec in pairs(ini) do
        local name = section:match("^Weather%.(.+)$")
        if name then cfg.weathers[name] = readLook(sec) end
    end
    log("weather: %s (%d seasons, %d days each; %d weathers)", cfg.on and "on" or "off", #cfg.order, cfg.days,
        (function() local n = 0 for _ in pairs(cfg.weathers) do n = n + 1 end return n end)())
    if not cfg.on then return end
    season = seasonFor(DayNight.Day())

    WaCa.On("ScreenShown", function(screen)
        if not screen:GetClass():GetFName():ToString():find("^WBP_GuiHudGame") then return end
        if not current then newSpell("first roll") end
        fadeLook()
        startEffect()                       -- the effect is attached to the cat: a new world / pawn needs it again
    end)
    WaCa.On("HourChanged", function()
        if not current then return end
        hoursLeft = hoursLeft - 1
        if hoursLeft <= 0 then newSpell("the spell is over") end
    end)
    WaCa.On("DayStarted", function() updateSeason("a new day") end)
    WaCa.On("DayRestored", function() updateSeason("save loaded") end)
    WaCa.On("GameSaved", function()
        restore()
        keep()
    end)
end

return Weather
