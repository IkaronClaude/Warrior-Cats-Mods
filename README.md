# WaCa ModKit

An open-source modding framework and fix pack for **Warrior Cats: Clans of the Forest** (Unreal Engine 5.7).

**Players:** download the latest release zip, extract it, double-click `Install.bat` and start the game from Steam
as usual. `Uninstall.bat` removes everything; the mod never modifies game files. Updating over an older version
asks whether to keep your settings or reset them to the new defaults (the old ones are backed up).

## What's in 0.5.5

- **In the game's character creator:**
  - **Your own name:** a text box on the name screen. The game's name list stays as your *online* name (what the
    save and online features keep); the typed name is what you see in the game. The box (top right) is part of the
    screen's flow: confirm (Enter / the gamepad's confirm button) on the name list moves into the box - Steam's
    on-screen keyboard opens on a controller - and confirming in the box goes on. Tab / the left stick click leave the
    box (`creator.ini NameBoxKeys`). The warrior ceremony gets the same box for your own warrior **suffix**.
  - **Your own colours**: the game's colour pickers (fur, pattern, markings) get a hex box (top right) showing the
    selected swatch's colour - type any `#RRGGBB` and press Enter. Picking a swatch afterwards goes back to the game's
    colour. The save keeps the selected game colour; the exact one is in the WaCa file next to it.
  - **WaCa shapes in the game's own grids**: looks like **Colourpoint** (coloured with the game's pattern colour
    picker) are entries of the creator's pattern / markings grids, after the game's own - choose them like any other.
    Look mods add theirs the same way (a `looks/` folder in the mod).
  - **Customise online cat** (checkbox top right, or F8): the preview shows the cat other players will see - the
    game's values only - and the game's controls edit just that; off again, your WaCa look is back on top. Left off,
    each WaCa choice gives the online cat its fallback.
  - **A WaCa panel** on the customisation screen only for what the grids can't offer: PNG packs, whole-look presets,
    and (`creator.ini PanelShapes = 1`) any game pattern / marking as the shape of either row - so two markings can be
    combined. Click the arrows, or press F5 / F6 / F7. With none of those configured there is no panel. Backing out
    of the screen (BackSpace / Escape) drops that screen's WaCa choices, like the game's.
- **Saved with your save, applied when you load it:** everything chosen goes into a small file next to the game's
  save (`WrcGame.<save>-<character slot>.WaCaModKit.ini`), written when the game saves. The game's own save only ever gets the game's
  own values (a custom colour is saved as the nearest game colour), so it stays loadable without the mod.

## Also in 0.4
- **No more doubled names** from the game's generator ("Blazeblaze" gets another suffix its rank already uses; the
  same cat always gets the same name).
- **Fixed cats for specific roles** (`config/roster.ini` + roster files, see `rosters/Example.ini`): pin a story cat
  (`[Narrative.ThunderClanDeputy]`) or a clan's generated cat by rank (`[ThunderClan.Leader]`, `[RiverClan.Warrior.3]`)
  to a name, the game's own look values (body, fur, colours, pattern, markings, eyes, accessories, size, scars) and
  extra colours / masks. Only valid game values go into the save, so it stays loadable without the mod.

## Also in 0.3.1
- **The mouse cursor shows in menus** (the game hides it everywhere) and is not captured on a click there; hidden and
  captured again in gameplay for mouse look (`keybinds.ini [Mouse] MenuCursor = 0` for the game's behaviour).
- **Your look on your cat's portraits** (headshots, inventory view) too - any view showing your cat's appearance.
- **Left click** interacts (like E, which still works) and advances dialogue.
- **Escape** pauses (instead of P), and goes back / closes in every menu (the character creator included) - BackSpace keeps working too; the menus show the Esc icon.
- **Mouse look**: the camera turns directly with the mouse movement (no stick dead zone, curve or speed
  cap; `[Mouse] LookYaw` / `LookPitch` in `keybinds.ini`), the game's invert settings respected.
- **More graphics settings** (`config/graphics.ini`): the engine's scalability groups (shadows, effects, foliage,
  view distance ... 0 low - 4 cinematic) and any console variable (motion blur, depth of field, render resolution,
  frame cap ...). Applied at start and again after you close the game's own options.
- **Hunting by chance** (experimental, off by default, `config/hunting.ini [Chance] On = 1`): the prey instakill
  succeeds only by chance - your rank's chance (apprentice 20%, warrior 80%, deputy / leader 130%) x the prey's factor
  (rabbit 0.5), always at least a 5% critical miss. A miss and the prey gets away. Only prey kinds (`PreyKinds`) are
  rolled - the sneak attack on cats stays the game's. A catch gives the EXP a fight against that prey gives (the game's
  own combat EXP table; `Experience = 1`). Landing from loud ground (the game's own noisy leaf litter) or just after
  leaving it: the prey hears you and gets away (`Noise`, `NoiseWindow`). The success chance shows under the game's hunt
  icon over the prey. Every roll is in WaCaNative.log (`[hunt] landed on ...`).
- **Day / night cycle** (experimental, off by default, `config/daynight.ini [DayNight] On = 1`): the sun crosses the
  sky, the light dims at night and the game's own night look blends in - a full day takes `DayMinutes` real minutes
  (24 by default), starting at `StartHour`.
- **Clan activities** (experimental, off by default, `config/activities.ini [Ambient] On = 1`): clanmates near your cat
  that stand still now and then sit, nap, sniff around or play-fight in pairs - the game's own animations. Which
  activities, how often (`Every`) and how near (`Radius`) are in the ini.
- **Dialogue name fixes** (`config/text.ini [Placeholders]`): the game's own text misspells some name placeholders
  (`{THE WARROR FATHER}`, `{THE MISTRUSTUL LEADER}` ...), so those lines never showed the cat's name - the mod
  corrects them at load (6 lines; only the misspelled token is changed).
- **Fishing** (experimental, off by default, `config/hunting.ini [Fishing] On = 1`): walking up to a fishing spot
  startles the fish - they're gone for a few seconds. Keep still on the spot and they come back and bite by chance
  (`Chance`, x your clan's factor: RiverClan 1.5); a bite = the game's own catch is there. Fishing spots become active 30 s
  after you enter the world (setting them up earlier, while the world was still loading, could crash the game).
- **Prey flee** (experimental, off by default, `config/hunting.ini Flee = 1`): pounce prey that notices your cat runs
  away instead of reacting. The open world's charging prey are different creatures - not covered yet.
- **Camera-relative movement**: A / D move your cat sideways relative to the camera instead of turning the camera
  ("tank" controls); only the mouse / camera keys turn the camera. `[Mouse] CameraRelativeMove = 0` = the game's.
- **Rebind any keyboard/mouse key** in `ue4ss/Mods/WaCaModKit/config/keybinds.ini`: gameplay commands
  (`[Actions]` / `[Axes]`), the menus' own keys and their icons (`[UIKeys]`), key aliases in menus (`[KeyAliases]`) and in conversations (`[DialogueKeyAliases]`: Space and a left click advance dialogue - a click on an answer choice just picks it). Every
  command and its default is listed inside. Gamepad bindings are untouched.

- **Free-form name** for your cat: `config/names.ini` (`Prefix = Moss` gives Mosskit, Mosspaw, Moss<warrior suffix>;
  optional own warrior `Suffix`). Only what you see changes: your save keeps the game's name, so online features and
  uninstalling are safe.
- **Text overrides:** replace any text the game shows in `config/text.ini` (fixes, renames).

- **Customisation** (`config/appearance.ini`): any colour for every part of the coat (fur, pattern, markings, paw
  pads, inner ears, nose, whiskers), per-part colours (`Tail.Fur = #3E2B22`), any of the game's 23 patterns and 20
  markings in either mask slot (`MarkingsMask = game:M12_Mask`, so two markings can be combined), PNG pattern packs,
  per-part colours that follow a coat colour (`Tail.Fur = Pattern`), and looks: presets (`Look = Name`) or shapes
  like the included **Colourpoint** (`PatternMask = look:Colourpoint`). Display only - the save keeps the
  game's look.
- **Per-save data:** each save slot carries its own name and look in a sidecar file next to the game's save
  (`%LOCALAPPDATA%\Wrc\Saved\SaveGames\WrcGame.<save>-<character slot>.WaCaModKit.ini`, `[Name]` / `[Appearance]`), loaded
  automatically with that save; it wins over the global `names.ini` / `appearance.ini` (the defaults for saves without
  their own). The game's save file is never modified by the mod.

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
Menu keys from code: `WaCa.SetUIKey("Button_B", "Escape")` (replaces the key) or `WaCa.SetUIIcon("Button_B", "Escape")` (icon only).

Events: react to the game instead of polling it. Handlers run on the game thread.
```lua
WaCa.On("ScreenShown", function(screen) ... end)     -- also ScreenHidden, ScreenFocusIn / ScreenFocusOut, CatSpawned, GameSaved
WaCa.Watch("ReceiveBeginPlay", "/Script/Engine.Pawn", "PawnSpawned")   -- any UFunction by name, Blueprint events too
WaCa.On("PawnSpawned", function(pawn) ... end)
WaCa.Ready()                                          -- the LAST line of your main.lua
```
Events are held back until `WaCa.Ready()`. Then `Started` fires, and the screens already up arrive as `ScreenShown`.
Don't run Lua off the game thread in a mod that uses events (`LoopAsync` / `ExecuteAsync`): two threads in one Lua
state corrupt it.

Content without code: a look is an ini file (`WaCaModKit/looks/*.ini`, or `Look = YourMod/looks/X.ini`; with
`Row = Pattern` / `Row = Markings` it is offered as one of that row's shapes, see `looks/Colourpoint.ini`); a pattern
pack is a folder of PNG masks (`WaCaModKit/patterns/README.txt`).
A look mod needs no config edit: every enabled mod's `looks/*.ini` is offered automatically (id
`<Mod>/looks/<File>.ini`; `creator.ini` `AutoLooks = 0` turns that off). Such a look is an entry in the creator's own pattern / markings grid: a copy of its `Fallback =` shape's row in
the game's table, named by `Label =` (else the look's name), with its grid icon from `Icon = /Game/...` (else the
fallback's). The saved cat keeps the fallback's index, so the save works without the mod.

Rows of the game's data tables from code: `WaCaNative_CloneTableRow(table:GetAddress(), "FromRow", "NewRow")` and
`WaCaNative_SetTableField(table:GetAddress(), "NewRow", "Field", "value")` (text, `/Game/...` asset paths, enum names,
numbers, bools).

All game text is one string table (`SwtStrings`, from `Gameplay/Strings/NonAsset/Strings_<LANG>.csv`). Cat names are
entries in it too: `STR_CAT_NAME<n><suffix id>`.

## How it works
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) loads the mod: Lua scripts plus a native DLL (a UE4SS C++ mod).
- Everything is event-driven, with no timers or polling. The DLL turns UE4SS's own ProcessEvent callbacks into events
  for every Lua mod (`WaCa.On`), so Blueprint events Lua's `RegisterHook` can't reach (a screen's
  `Construct` / `Destruct`) work too. It gives Lua real functions (`WaCaNative_*`) for its native commands.
- For game code UE4SS has no hook for, `native/` finds the function by byte signature and detours it with MinHook.
  For key bindings, it rewrites the game's natively built default bindings before they're installed, so rebinding is
  real, not layered on top.

## Building
- `native\build.bat`: produces `native\out\main.dll`. It builds against the UE4SS SDK: a RE-UE4SS source checkout
  (with submodules) at the commit of the UE4SS release we ship, in `tools\bin\src\RE-UE4SS` or `WACA_UE4SS_DIR`.
  Needs Visual Studio's C++ tools and Rust. UE4SS's Unreal submodule is private: it needs a GitHub account linked to
  Epic Games. The release workflow uses the secret `UE4SS_SOURCE_TOKEN` for it. The first build takes about
  10 minutes.
- `tools\package.ps1`: builds `dist\WaCaModKit-<version>.zip`. Needs UE4SS extracted into `tools\bin\ue4ss`.
- `tools/check_hooks.py <unpacked exe>`: checks every native hook target against a game exe (run it on a game update
  before a release); the targets are read from the native sources.
- `tools/AssetDump`: a headless CUE4Parse reader for the game's paks (for research; output stays out of git).

No game files or game data are in this repository.

## License
Apache License 2.0 (see LICENSE). Third party: UE4SS (MIT, shipped in releases), MinHook (BSD-2, `native/third_party/minhook`).
