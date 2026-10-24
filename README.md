# WaCa ModKit

An open-source modding framework and fix pack for **Warrior Cats: Clans of the Forest** (Unreal Engine 5.7).

**Players:** download the latest release zip, extract it, double-click `Install.bat` and start the game from Steam
as usual. `Uninstall.bat` removes everything; the mod never modifies game files.

## What's in 0.3.1
- **Escape** pauses (instead of P), and goes back / closes in menus (instead of BackSpace), with the Esc icon shown.
- **Mouse look**: the camera (the gamepad's right stick) follows the mouse; sensitivity in `keybinds.ini`.
- **Rebind any keyboard/mouse key** in `ue4ss/Mods/WaCaModKit/config/keybinds.ini`: gameplay commands
  (`[Actions]` / `[Axes]`), the menus' own keys and their icons (`[UIKeys]`), and key aliases (`[KeyAliases]`). Every
  command and its default is listed inside. Gamepad bindings are untouched.

- **Free-form name** for your cat: `config/names.ini` (`Prefix = Moss` gives Mosskit, Mosspaw, Moss<warrior suffix>;
  optional own warrior `Suffix`). Only what you see changes: your save keeps the game's name, so online features and
  uninstalling are safe.
- **Text overrides:** replace any text the game shows in `config/text.ini` (fixes, renames).

- **Customisation** (`config/appearance.ini`): any colour for every part of the coat (fur, pattern, markings, paw
  pads, inner ears, nose, whiskers), per-part colours (`Tail.Fur = #3E2B22`), any of the game's 23 patterns and 20
  markings in either mask slot (`MarkingsMask = game:M12_Mask`, so two markings can be combined), PNG pattern packs,
  and looks: presets like the included **Colourpoint** (`Look = Colourpoint`). Display only - the save keeps the
  game's look.
- **Per-save data** (in development): each save slot can carry its own name and look in a sidecar file next to the
  game's save (`%LOCALAPPDATA%\Wrc\Saved\SaveGames\WrcGame.<slot>.WaCaModKit.ini`, `[Name]` / `[Appearance]`). It is
  loaded automatically with that save and wins over the global `names.ini` / `appearance.ini`; the game's save file is
  never modified. Choosing custom options inside the game's own creator is next.

## For modders
Other UE4SS Lua mods can use the shared API:
```lua
local WaCa = require("WaCa")
WaCa.SetText("STR_MAINMENU_PROPHECY_MODE", "Story Mode")   -- any game text, by its key
print(WaCa.GetText("STR_CAT_NAME1_PAW"))                    -- "Woodpaw"
```
Appearance from code (any cat's `SwtAdventureCustomizableMeshComponent`):
```lua
WaCa.SetCatColor(cat, "Fur", WaCa.ParseColor("#EFE6D6"))
WaCa.SetPartColor(cat, "Tail", "Fur", WaCa.ParseColor("#3E2B22"))
WaCa.SetCatMask(cat, "Markings", "game:M12_Mask")        -- or a folder of PNG masks
for _, cat in ipairs(WaCa.PlayerCats()) do ... end       -- the player's cat + the creation preview
```
Per-save data for your own mod (one sidecar file per mod and save slot):
```lua
local file = WaCa.SlotFile("MyMod")                       -- nil until a save slot is active
local data = WaCa.ReadIni(file) or {}
WaCa.WriteIni(file, data)
```
Menu keys from code: `WaCa.SetUIKey("Button_B", "Escape")`.

Content without code: a look is an ini file (`WaCaModKit/looks/*.ini`, or `Look = YourMod/looks/X.ini`); a pattern
pack is a folder of PNG masks (`WaCaModKit/patterns/README.txt`).

All game text is one string table (`SwtStrings`, from `Gameplay/Strings/NonAsset/Strings_<LANG>.csv`). Cat names are
entries in it too: `STR_CAT_NAME<n><suffix id>`.

## How it works
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) loads the mod: Lua scripts plus a small native DLL.
- `native/` (WaCaNative) finds the game's code by byte signatures and detours it with MinHook. For key bindings, it
  rewrites the game's natively built default bindings before they're installed, so rebinding is real, not layered on
  top.
- The DLL loads as a UE4SS C++ mod, but needs no UE4SS SDK.

## Building
- `native\build.bat`: needs Visual Studio's C++ tools; produces `native\out\main.dll`.
- `tools\package.ps1`: builds `dist\WaCaModKit-<version>.zip`. Needs UE4SS extracted into `tools\bin\ue4ss`.
- `tools/AssetDump`: a headless CUE4Parse reader for the game's paks (for research; output stays out of git).

No game files or game data are in this repository.

## License
Apache License 2.0 (see LICENSE). Third party: UE4SS (MIT, shipped in releases), MinHook (BSD-2, `native/third_party/minhook`).
