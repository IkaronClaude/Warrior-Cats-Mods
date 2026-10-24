-- WaCa ModKit - the shared Lua API. Any UE4SS Lua mod can use it:
--     local WaCa = require("WaCa")
--     WaCa.SetText("STR_MAINMENU_PROPHECY_MODE", "Story Mode")     -- replace any game text
--     print(WaCa.GetText("STR_CAT_NAME1_PAW"))                     -- "Woodpaw"
-- Game text lives in one string table ("SwtStrings", from Strings_<LANG>.csv); cat names are entries too
-- (STR_CAT_NAME<n><suffix id>, e.g. STR_CAT_NAME1_PAW). Overrides change what the game shows; saves are untouched.
-- Needs WaCa ModKit's native part (WaCaModKit/dlls/main.dll), which applies the changes on the game thread.
local WaCa = {}

local TABLE = "SwtStrings"
local stringTables = nil

local function lib()
    if not stringTables or not stringTables:IsValid() then
        stringTables = StaticFindObject("/Script/Engine.Default__KismetStringTableLibrary")
    end
    return stringTables
end

-- the text the game has for a key ("" when there is none / the table isn't loaded yet)
function WaCa.GetText(key)
    local l = lib()
    if not l or not l:IsValid() then return "" end
    return l:GetTableEntrySourceString(FName(TABLE), key):ToString()
end

-- true once the game has loaded its text
function WaCa.IsTextReady()
    return WaCa.GetText("STR_WINDOW_TITLE_BAR") ~= ""
end

-- replace the text of a key ("|" is not allowed in either). The native side receives it through the engine's own
-- string-table lookup (the "WACA:" key prefix), on the game thread.
function WaCa.SetText(key, text)
    local l = lib()
    if not l or not l:IsValid() then return false end
    l:GetTableEntrySourceString(FName(TABLE), "WACA:SetText|" .. key .. "|" .. text)
    return WaCa.GetText(key) == text
end

-- a simple ini reader: { [section] = { key = value } }, keys in file order in section.__order
function WaCa.ReadIni(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local out, section = {}, ""
    out[section] = { __order = {} }
    for line in f:lines() do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" and not line:match("^[;#]") then
            local s = line:match("^%[(.+)%]$")
            if s then
                section = s
                out[section] = out[section] or { __order = {} }
            else
                local k, v = line:match("^([^=]+)=(.*)$")
                if k then
                    k = k:gsub("%s+$", ""); v = v:gsub("^%s+", "")
                    out[section][k] = v
                    table.insert(out[section].__order, k)
                end
            end
        end
    end
    f:close()
    return out
end

return WaCa
