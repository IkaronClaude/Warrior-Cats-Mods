-- The mouse cursor in menus: the game hides it everywhere (a console-style UI); it shows while any menu is up and
-- hides again in gameplay (mouse look). A "menu" = any screen showing that is not the gameplay screen or a HUD, or a
-- popup on the gameplay screen (the pause menu, the map, ...). config/keybinds.ini [Mouse] MenuCursor = 0 turns it off.
local Menus = {}

local WaCa, log, modDir
local gameScreenClass

local function isGameplay(screen)
    if gameScreenClass and gameScreenClass:IsValid() and screen:IsA(gameScreenClass) then return true end
    return screen:GetClass():GetFName():ToString():find("Hud", 1, true) ~= nil
end

-- true while a menu is showing
local function menuShowing()
    gameScreenClass = gameScreenClass or StaticFindObject("/Script/SwtEngine.GuiScreenGame")
    for _, s in ipairs(FindAllOf("SwtScreen") or {}) do
        if s:IsValid() and s:IsInViewport() then
            if not isGameplay(s) then return true end
            local popup = s.CurrentPopup
            if popup and popup:IsValid() then return true end
        end
    end
    return false
end

local enabled = true
local shown = nil
function Menus.Tick()
    if not enabled then return end
    local want = menuShowing()
    if want == shown then return end
    for _, c in ipairs(FindAllOf("SwtPlayerController") or {}) do
        if c:IsValid() and c.Player and c.Player:IsValid() then
            c.bShowMouseCursor = want
            c.bEnableClickEvents = want
            c.bEnableMouseOverEvents = want
        end
    end
    -- the first decision is only logged when it shows the cursor (at start-up the game's own state is "hidden")
    if shown ~= nil or want then log("mouse cursor %s", want and "shown (menu)" or "hidden (gameplay)") end
    shown = want
end

function Menus.Init(c)
    WaCa, log, modDir = c.WaCa, c.log, c.modDir
    local ini = WaCa.ReadIni(modDir .. "/config/keybinds.ini")
    local mouse = ini and ini["Mouse"] or {}
    enabled = (mouse.MenuCursor or "1") ~= "0"
end

return Menus
