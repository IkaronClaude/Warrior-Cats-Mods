-- Prey flee instead of charging (tickets.md 9, hunting rework): when a prey animal notices your cat, the game's own
-- reaction (charge / encounter) is skipped natively (prey.cpp) and the prey runs away from the cat - the engine's own
-- AI move (AIBlueprintHelperLibrary.SimpleMoveToLocation, one call per escape, no tick). The game's pounce still
-- catches it if you're fast enough. config/hunting.ini: Flee, FleeDistance, FleeSpeed, ExcludeTags (size tags that
-- keep the game's reaction - the log names each tag the first time it flees).
local Hunting = {}

local WaCa, log, modDir
local cfg = { flee = true, distance = 2500, speed = 1.0 }
local hooked = false
local boosted = {}               -- prey -> its speed was raised once

local function pathOf(fullName) return (tostring(fullName):gsub("^%S+ ", "")) end

local function flee(preyName, catName)
    local prey, cat = StaticFindObject(pathOf(preyName)), StaticFindObject(pathOf(catName))
    if not (prey and prey:IsValid() and cat and cat:IsValid()) then return end
    local ok, err = pcall(function()
        local p, c = prey:K2_GetActorLocation(), cat:K2_GetActorLocation()
        local dx, dy = p.X - c.X, p.Y - c.Y
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 1 then dx, dy, len = 1, 0, 1 end
        local to = { X = p.X + dx / len * cfg.distance, Y = p.Y + dy / len * cfg.distance, Z = p.Z }
        local id = prey:GetFullName()
        if cfg.speed ~= 1.0 and not boosted[id] then
            boosted[id] = true
            pcall(function() prey.CharacterMovement.MaxWalkSpeed = prey.CharacterMovement.MaxWalkSpeed * cfg.speed end)
        end
        StaticFindObject("/Script/AIModule.Default__AIBlueprintHelperLibrary"):SimpleMoveToLocation(prey:GetController(), to)
        log("prey: %s flees from %s (%.0f units away)", prey:GetFName():ToString(), cat:GetFName():ToString(), cfg.distance)
    end)
    if not ok then log("prey: flee failed (%s)", tostring(err)) end
end

function Hunting.Init(c)
    WaCa, log, modDir = c.WaCa, c.log, c.modDir
    local ini = WaCa.ReadIni(modDir .. "/config/hunting.ini") or {}
    local p = ini["Prey"] or {}
    cfg.flee = (p.Flee or "0") == "1"
    cfg.distance = tonumber(p.FleeDistance or "") or cfg.distance
    cfg.speed = tonumber(p.FleeSpeed or "") or cfg.speed
    WaCa.Command("PreyFlee|" .. (cfg.flee and "1" or "0") .. "|" .. (p.ExcludeTags or ""))
    if not cfg.flee then return end
    -- the reaction is hooked from the first live prey (its vtable)
    WaCa.Watch("ReceiveBeginPlay", "/Script/Wrc.WrcPouncePrey", "WaCaPreySpawned", "post")
    WaCa.On("WaCaPreySpawned", function(prey)
        if hooked then return end
        hooked = true
        local ok = WaCaNative_HookPrey and WaCaNative_HookPrey(prey:GetAddress())
        log("prey: detection reaction hooked: %s", tostring(ok))
    end)
    WaCa.On("PreyFlee", function(_, preyName, catName) flee(preyName, catName) end)
end

return Hunting
