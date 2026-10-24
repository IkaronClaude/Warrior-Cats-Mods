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

---------------------------------------------------------------------------------------------------------------------
-- Cat appearance. A cat's look is one USwtAdventureCustomizableMeshComponent (on the player's pawn, on every NPC, on
-- the creation screen's preview); its mesh parts (body, tail, ears, fur cards) all use the material M_Characters_Base,
-- whose parameters below are the coat. Changes made here are what you SEE: the save keeps the game's choices.

-- the coat's colour slots -> material parameters
WaCa.COAT_COLORS = {
    Fur = "Fur Color", Pattern = "Pattern Mask Color", Markings = "Markings Mask Color", Paws = "Paws Color",
    Ears = "Ears Color", Nose = "Nose Color", Whiskers = "Whiskers Color",
}
-- the coat's shape textures (white = the slot's colour) -> material parameters
WaCa.COAT_MASKS = { Pattern = "Pattern Mask", Markings = "Markings Mask" }
WaCa.CAT_PARTS = { "SkelMeshComp", "TailSkelMeshComp", "EarSkelMeshComp", "FurSkelMeshComp" }

-- "#RRGGBB" / "RRGGBB" / "r, g, b" (0-255) -> a linear colour {X, Y, Z} as the material wants it (the game's colours
-- are linear: its own F8940B orange is stored as 0.93 / 0.30 / 0.004)
function WaCa.ParseColor(text)
    if not text or text == "" then return nil end
    local r, g, b
    local hex = text:match("^#?(%x%x%x%x%x%x)$")
    if hex then
        r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
    else
        r, g, b = text:match("^(%d+)%s*,%s*(%d+)%s*,%s*(%d+)$")
        r, g, b = tonumber(r), tonumber(g), tonumber(b)
    end
    if not (r and g and b) then return nil end
    local function lin(c)
        c = c / 255
        return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
    end
    return { X = lin(r), Y = lin(g), Z = lin(b) }
end

-- the mesh parts of a cat (skeletal mesh components that exist)
function WaCa.CatParts(cat)
    local out = {}
    for _, name in ipairs(WaCa.CAT_PARTS) do
        local part = cat[name]
        if part and part:IsValid() then table.insert(out, part) end
    end
    return out
end

-- a part's role from its material: MI_Cat_Body -> "Body", MI_Cat_Tails_A -> "Tails_A", MI_Cat_Fur_Bony -> "Fur_Bony"
-- (pattern packs name their mask files after it)
function WaCa.PartRole(part, slot)
    local m = part:GetMaterial(slot or 0)
    if not m or not m:IsValid() then return nil end
    local name = m:GetFName():ToString()
    if m:GetClass():GetFName():ToString() == "MaterialInstanceDynamic" and m.Parent and m.Parent:IsValid() then
        name = m.Parent:GetFName():ToString()
    end
    return name:match("^MI_Cat_(.-)_CelShaded") or name:match("^MI_Cat_(.+)$")
end

-- set one coat colour (a WaCa.COAT_COLORS slot or a raw parameter name) on every part of a cat
function WaCa.SetCatColor(cat, slot, color)
    local param = FName(WaCa.COAT_COLORS[slot] or slot)
    for _, part in ipairs(WaCa.CatParts(cat)) do part:SetVectorParameterValueOnMaterials(param, color) end
end

-- the material instance a part draws with, made dynamic if it isn't yet (so its parameters can change)
local function dynamicMaterial(part, slot)
    local m = part:GetMaterial(slot)
    if not m or not m:IsValid() then return nil end
    if m:GetClass():GetFName():ToString() == "MaterialInstanceDynamic" then return m end
    return part:CreateDynamicMaterialInstance(slot, m, FName("None"))
end

-- set a texture parameter on all of one part's materials
function WaCa.SetPartTexture(part, param, texture)
    for i = 0, part:GetNumMaterials() - 1 do
        local mid = dynamicMaterial(part, i)
        if mid and mid:IsValid() then mid:SetTextureParameterValue(FName(param), texture) end
    end
end

-- load a PNG / JPG / TGA from disk as a texture (cached by path; nil when it can't be read)
local textures = {}
function WaCa.LoadTexture(path)
    if textures[path] and textures[path]:IsValid() then return textures[path] end
    local f = io.open(path, "rb")
    if not f then return nil end
    f:close()
    local lib = StaticFindObject("/Script/Engine.Default__KismetRenderingLibrary")
    local tex = lib:ImportFileAsTexture2D(FindFirstOf("World"), path)
    if tex and tex:IsValid() then
        textures[path] = tex
        return tex
    end
    return nil
end

-- the game's own mask texture for a part: a pattern (P01_Fishbone ... P23_Deluxe_Spotted) or a marking (M01_Sock ...
-- M20_Piebald) by its folder name, e.g. GameMask("M12_Mask", "Ears_A"). Loaded from the player's own game files.
function WaCa.GameMask(name, role)
    local kind = name:match("^P%d") and "Patterns" or "Markings"
    local tex = string.format("T_Cat_%s_%s_M", role, name)
    local path = string.format("/Game/Art/Characters/CatMaster/Textures/%s/%s/%s.%s", kind, name, tex, tex)
    local obj = StaticFindObject(path)
    if not obj or not obj:IsValid() then
        -- LoadAsset wants the full object path (Package.Object) and must run on the game thread (main.lua's callers do)
        local ok, loaded = pcall(LoadAsset, path)
        obj = ok and loaded or nil
    end
    return obj and obj:IsValid() and obj or nil
end

-- set one coat mask slot ("Pattern" or "Markings") on every part of a cat from a source:
--   "game:M12_Mask"  the game's own pattern / marking of that name (all parts it exists for)
--   "<folder>"       a pattern pack: PNGs named after the part roles (Body.png, Tails_A.png, Ears_B.png,
--                    Fur_Bony.png ...; Tails.png / Ears.png / Fur.png cover all variants of a part)
-- Parts the source has no mask for keep the game's. Returns how many parts changed.
function WaCa.SetCatMask(cat, maskSlot, source)
    local param = WaCa.COAT_MASKS[maskSlot] or maskSlot
    local game = source:match("^game:(.+)$")
    local n = 0
    for _, part in ipairs(WaCa.CatParts(cat)) do
        local role = WaCa.PartRole(part)
        local tex
        if role and game then
            tex = WaCa.GameMask(game, role)
        elseif role then
            tex = WaCa.LoadTexture(source .. "/" .. role .. ".png")
                or WaCa.LoadTexture(source .. "/" .. (role:match("^(%a+)") or role) .. ".png")
        end
        if tex then
            WaCa.SetPartTexture(part, param, tex)
            n = n + 1
        end
    end
    return n
end

-- the parts by name, for per-part colours ("Tail.Fur = ..."): Body, Tail, Ears, Tufts (the fur cards)
WaCa.PART_NAMES = { Body = "SkelMeshComp", Tail = "TailSkelMeshComp", Ears = "EarSkelMeshComp", Tufts = "FurSkelMeshComp" }

-- set one coat colour on one named part only (e.g. a darker tail)
function WaCa.SetPartColor(cat, partName, slot, color)
    local part = cat[WaCa.PART_NAMES[partName] or partName]
    if part and part:IsValid() then part:SetVectorParameterValueOnMaterials(FName(WaCa.COAT_COLORS[slot] or slot), color) end
end

-- the player's cat (the customizable mesh on the player's pawn) and the creation screen's preview cat, when present
function WaCa.PlayerCats()
    local out = {}
    local pc = FindFirstOf("PlayerController")
    local pawn = pc and pc:IsValid() and pc.Pawn
    local pawnName = pawn and pawn:IsValid() and pawn:GetFullName()
    if pawnName then
        for _, comp in ipairs(FindAllOf("SwtAdventureCustomizableMeshComponent") or {}) do
            if comp:IsValid() and comp:GetOwner():GetFullName() == pawnName then table.insert(out, comp) end
        end
    end
    for _, preview in ipairs(FindAllOf("GuiCatCustomActor") or {}) do
        local comp = preview:IsValid() and preview.CustomizableMeshComponent
        if comp and comp:IsValid() then table.insert(out, comp) end
    end
    return out
end

return WaCa
