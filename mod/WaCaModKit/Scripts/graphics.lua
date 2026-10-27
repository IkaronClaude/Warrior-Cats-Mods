-- More graphics settings than the game's options screen: config/graphics.ini sets the engine's scalability groups
-- (sg.*, 0 low .. 3 epic, 4 cinematic) and any console variable. Applied through the engine's own console command
-- (KismetSystemLibrary.ExecuteConsoleCommand) when the game starts, and again whenever the game's options popup
-- (GuiPopupOptions) closes - the game re-applies its own settings there. An empty value leaves the game's.
local Graphics = {}

local WaCa, log, modDir
local applied = 0

-- the ini's [Scalability] keys -> the engine's scalability group console variables
local GROUPS = {
    ViewDistance = "sg.ViewDistanceQuality", AntiAliasing = "sg.AntiAliasingQuality", Shadows = "sg.ShadowQuality",
    GlobalIllumination = "sg.GlobalIlluminationQuality", Reflections = "sg.ReflectionQuality",
    PostProcess = "sg.PostProcessQuality", Textures = "sg.TextureQuality", Effects = "sg.EffectsQuality",
    Foliage = "sg.FoliageQuality", Shading = "sg.ShadingQuality", Landscape = "sg.LandscapeQuality",
}

local function commands()
    local ini = WaCa.ReadIni(modDir .. "/config/graphics.ini") or {}
    local list = {}
    local groups = ini["Scalability"] or {}
    for _, key in ipairs(groups.__order or {}) do
        local v = tostring(groups[key] or ""):match("^%s*(%d)%s*$")
        if GROUPS[key] and v then table.insert(list, GROUPS[key] .. " " .. v) end
    end
    local cvars = ini["CVars"] or {}
    for _, key in ipairs(cvars.__order or {}) do
        local v = tostring(cvars[key] or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if v ~= "" and key:match("^[%w%.%_]+$") then table.insert(list, key .. " " .. v) end
    end
    return list
end

local function apply(why)
    local list = commands()
    if #list == 0 then return end
    local ksl = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
    local pc
    for _, c in ipairs(FindAllOf("PlayerController") or {}) do
        if c:IsValid() and c.Player and c.Player:IsValid() then pc = c end
    end
    if not ksl or not pc then return end
    local done = 0
    for _, cmd in ipairs(list) do
        if pcall(function() ksl:ExecuteConsoleCommand(pc, cmd, pc) end) then done = done + 1 end
    end
    applied = applied + 1
    log("graphics.ini: %d of %d settings applied (%s): %s", done, #list, why, table.concat(list, ", "))
end

function Graphics.Init(c)
    WaCa, log, modDir = c.WaCa, c.log, c.modDir
    WaCa.On("Started", function() ExecuteInGameThread(function() apply("start") end) end)
    WaCa.On("ScreenHidden", function(screen)
        local cls = StaticFindObject("/Script/Wrc.GuiPopupOptions")
        local ok, yes = pcall(function() return cls and cls:IsValid() and screen:IsA(cls) end)
        if ok and yes then ExecuteInGameThread(function() apply("after the game's options") end) end
    end)
end

return Graphics
