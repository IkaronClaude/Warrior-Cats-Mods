# WaCa ModKit

An open-source modding framework and fix pack for **Warrior Cats: Clans of the Forest** (Unreal Engine 5.7).

**Players:** download the latest release zip, extract it, double-click `Install.bat` and start the game from Steam
as usual. `Uninstall.bat` removes everything; the mod never modifies game files.

## What's in 0.2
- Pause on **Escape** instead of P.
- **Mouse look**: the camera (the gamepad's right stick) follows the mouse; sensitivity in `keybinds.ini`.
- **Rebind any keyboard/mouse key** in `ue4ss/Mods/WaCaModKit/config/keybinds.ini`. Every command and its default
  is listed inside. Gamepad bindings are untouched.

- **Free-form name** for your cat: `config/names.ini` (`Prefix = Moss` gives Mosskit, Mosspaw, Moss<warrior suffix>;
  optional own warrior `Suffix`). Only what you see changes: your save keeps the game's name, so online features and
  uninstalling are safe.
- **Text overrides:** replace any text the game shows in `config/text.ini` (fixes, renames).

Coming next: more customisation (a colour wheel, colourpoint "Ragdoll" layouts), with APIs other mods can build on.

## For modders
Other UE4SS Lua mods can use the shared API:
```lua
local WaCa = require("WaCa")
WaCa.SetText("STR_MAINMENU_PROPHECY_MODE", "Story Mode")   -- any game text, by its key
print(WaCa.GetText("STR_CAT_NAME1_PAW"))                    -- "Woodpaw"
```
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
MIT. Third party: UE4SS (MIT, shipped in releases), MinHook (BSD-2, `native/third_party/minhook`).
