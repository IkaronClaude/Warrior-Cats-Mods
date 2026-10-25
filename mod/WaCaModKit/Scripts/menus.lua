-- The mouse cursor in menus: the game hides it everywhere (a console-style UI); it shows while any menu is up and
-- hides again in gameplay (mouse look). A "menu" = any screen up that is not the gameplay screen or a HUD, or a popup
-- on the gameplay screen (the pause menu, the map, ...). Decided whenever a screen comes or goes (the ScreenShown /
-- ScreenHidden events) and when keyboard focus moves between screens. config/keybinds.ini [Mouse] MenuCursor = 0
-- turns it off.
local Menus = {}

local WaCa, log, modDir
local gameScreenClass

local function isGameplay(screen)
    if gameScreenClass and gameScreenClass:IsValid() and screen:IsA(gameScreenClass) then return true end
    return screen:GetClass():GetFName():ToString():find("Hud", 1, true) ~= nil
end

-- true while a menu is showing; leaving = a screen being torn down (ScreenHidden: it still counts as in the viewport)
local function menuShowing(leaving)
    gameScreenClass = gameScreenClass or StaticFindObject("/Script/SwtEngine.GuiScreenGame")
    local leavingName = leaving and leaving:GetFullName()
    for _, s in ipairs(FindAllOf("SwtScreen") or {}) do
        if s:IsValid() and s:IsInViewport() and s:GetFullName() ~= leavingName then
            if not isGameplay(s) then return true end
            local popup = s.CurrentPopup
            if popup and popup:IsValid() and popup:GetFullName() ~= leavingName then return true end
        end
    end
    return false
end

local enabled = true
local shown = nil
local gameCaptureMode = nil      -- the viewport's mouse capture mode as the game set it

-- bShowMouseCursor alone shows nothing (operator 2026-10-25): the game viewport keeps the mouse captured with the
-- cursor hidden during capture, and the cursor type may be None. A menu gets "game and UI" input with the cursor kept
-- visible and the Default cursor; gameplay gets the game's "game only" mode back (mouse look captures the mouse).
local function applyCursor(c, want, transition)
    if c.bShowMouseCursor ~= want then c.bShowMouseCursor = want end
    if c.bEnableClickEvents ~= want then c.bEnableClickEvents = want end
    if c.bEnableMouseOverEvents ~= want then c.bEnableMouseOverEvents = want end
    if want and c.CurrentMouseCursor ~= 1 then c.CurrentMouseCursor = 1 end      -- EMouseCursor::Default
    if not transition then return end
    if gameCaptureMode == nil then
        pcall(function()
            gameCaptureMode = StaticFindObject("/Script/Engine.Default__GameplayStatics"):GetViewportMouseCaptureMode(c)
        end)
    end
    local lib = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    local ok, err
    if want then
        -- (player controller, widget to focus, mouse lock: DoNotLock, hide the cursor during capture: no, flush input)
        ok, err = pcall(function() lib:SetInputMode_GameAndUIEx(c, nil, 0, false, false) end)
    else
        ok, err = pcall(function() lib:SetInputMode_GameOnly(c, false) end)
    end
    if not ok then log("mouse cursor: input mode: %s", tostring(err)) end
    -- the viewport captures the mouse on a click (cursor hidden + locked: operator 2026-10-25) - no capture in menus,
    -- the game's own mode (read before the first change) back in gameplay. Set AFTER the input mode, which resets it
    local statics = StaticFindObject("/Script/Engine.Default__GameplayStatics")
    local ok0, err0 = pcall(function()
        statics:SetViewportMouseCaptureMode(c, want and 0 or gameCaptureMode)
    end)
    if not ok0 then log("mouse cursor: capture mode: %s", tostring(err0)) end
end

-- the cursor for the screens up now (a screen's own Construct may have changed the input mode: re-asserted each time)
local function update(leaving)
    if not enabled then return end
    local want = menuShowing(leaving)
    local transition = want ~= shown
    for _, c in ipairs(FindAllOf("SwtPlayerController") or {}) do
        if c:IsValid() and c.Player and c.Player:IsValid() then applyCursor(c, want, transition) end
    end
    if not transition then return end
    -- the first decision is only logged when it shows the cursor (at start-up the game's own state is "hidden")
    if shown ~= nil or want then log("mouse cursor %s", want and "shown (menu)" or "hidden (gameplay)") end
    shown = want
end

function Menus.Init(c)
    WaCa, log, modDir = c.WaCa, c.log, c.modDir
    local ini = WaCa.ReadIni(modDir .. "/config/keybinds.ini")
    local mouse = ini and ini["Mouse"] or {}
    enabled = (mouse.MenuCursor or "1") ~= "0"
    if not enabled then return end
    WaCa.On("ScreenShown", function() update(nil) end)
    WaCa.On("ScreenHidden", function(screen) update(screen) end)
    WaCa.On("ScreenFocusIn", function() update(nil) end)
    WaCa.On("ScreenFocusOut", function() update(nil) end)
end

return Menus
