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
  (24 by default). The time of day is kept with your save (`KeepTime`); `BedHour` ends each day (midnight if
  empty; counts the days for seasons and later features).
- **Seasons and weather** (experimental, off by default, `config/weather.ini [Seasons] On = 1`): newleaf, greenleaf,
  leaf-fall and leaf-bare follow the days of your save (`DaysPerSeason`, counted by the day / night cycle - without
  it the season stays `StartSeason`). Each season has its own day length, light and sunlight tint, and makes hunting
  and fishing easier or harder (leaf-bare x0.6 hunting). Weather comes in spells of a few in-game hours rolled from
  the season's chances: overcast, rain and snow darken the light, thicken the fog and change the chances (rain:
  hunting x0.8, fishing x1.2). Kept with your save. Rain and snow fall around your cat and rain has its sound - from
  the mod's own content pak (`WaCaModKit_P` in `Wrc\Content\Paks\~mods`; `Effect`, `Sound`, `Volume` in the ini).
  Prey follows the season (`[Season.*] Prey`): in leaf-bare only part of the mice, rabbits and birds are about and
  hardly any squirrels - the rest are away (hidden, never destroyed) until a later season; every in-game hour some
  prey comes and goes (`PreyTurnover`), turning up at a random spot of its area (`PreyRandomPlaces`).
- **The story as days** (experimental, off by default, `config/days.ini`): the story as data - one `[Day.N]` per story
  day with its scenes per phase (morning / afternoon / evening: a card or one of the game's conversations), its duties,
  season and weather, and when to move on (`Advance = Always / Duties / Rank:Warrior`); until then the story day
  repeats, scenes already seen skipped. `Like = M` copies an earlier day. Kept with your save. Example days inside.
- **Exhaustion** (experimental, off by default, `config/exhaustion.ini`): a resource, not a meter to watch - it only
  goes down when your cat does something: a pounce on prey (`PerPounce`, caught or missed) or a fight (`PerFight`),
  more late at night. Walking and exploring cost nothing. Tired, your cat moves slower and hunts and fights worse,
  exhausted even more so - so one cat can only hunt so much in a day. Resting (the time-skip key) resets it. Kept
  with your save.
- **Wading** (on, `config/wading.ini`): the game has no swimming - stepping into water slows your cat (shallow
  `Shallow`, deep `Deep`), RiverClan cats only part of it (`RiverClan`). Read from the floor under each footstep.
- **The clan loop** (experimental, off by default, `config/duties.ini` + `clanevents.ini`, needs the day / night
  cycle): the clan's day in thirds - morning, noon, evening - each the same loop: the deputy gives your cat a task
  (hunt N prey - every prey caught feeds the clan's pile, hunt on as long as you like; patrol N border points out in
  the territory, clanmates walk with you; training - a sparring fight with the clan's move teacher, the game's own
  fight; or free time), you do it and explore as long as you like (a done task never sends you home), you turn it in
  at its end point (a hunt: the catch onto the fresh-kill pile; a patrol: report to the deputy - `[Task.<Kind>]
  TurnIn`), then the clan's event of that third, if any (a clan meeting,
  the Gathering; in the evening eating together and sharing tongues - `clanevents.ini`), and the next third. The sky
  shows each third's hour - no wall clock, no race against the day. After the evening: sleep (the rest key) or the
  night watch (go to the camp's entrance - a short cutscene shows the night passing). At the day's end the tasks done
  raise your standing in the clan, the missed ones lower it (kept with your save). From `MaxRank` (Deputy) on you get
  none. Every step has hook points for the story: see "Story and the clan loop" below.
- **Gatherings** (experimental, off by default, `config/gatherings.ini`, needs the clan loop): every `Every` days the
  leader names the cats who go to the Gathering - your cat by chance, more likely with a good standing and the
  leader's favour (a story variable), never while banned (a punishment the story can give: `GatheringBan`). The
  announcement, going and staying behind are scenes; the outcome is a story variable (`Gathering.Chosen`) the
  story's own beats can follow (e.g. rogues attack the camp while the others are away).
- **Time skips** (experimental, off by default, `config/timeskip.ini On = 1`, needs the day / night cycle): time passes
  on purpose - your cat rests with `RestKey` (F9) and `RestDays` pass (1 = to the next morning, 7 = a quarter moon); a
  card in the game's own style says so ("A quarter moon passes. It is leaf-bare.") and the season, weather and prey
  move on with it. Day scripts and other modules can skip time too.
- **More for clan cats to say** (experimental, off by default, `config/lines.ini`): the game gives each cat role one
  line per story chapter, so cats repeat themselves. Add lines per role (or for all cats) and time of day (Morning /
  Day / Evening / Night / Any); every in-game hour each cat's line is one of them by chance (`Share`), or the game's
  own. A few example lines are in the ini.
- **Scenes** (experimental, off by default, `config/events.ini`, needs the day / night cycle): things happen on screen
  at a time of day - a card ("The full moon rises - the Gathering is tonight.") and / or one of the game's own
  conversations with the nearest clanmate, on a day, every N days or daily, once or repeating (remembered with the
  save). The conversation ids are listed in `config/events-dialogues.txt` the first time you're in the world.
- **Specialisation** (off by default, `config/roles.ini Role = Hunter / Tracker / Fighter`): from `MinRank` on your
  cat is better at some things and worse at others - Hunter catches more, Tracker fishes better and moves quieter
  (prey hears it for a shorter time after loud ground), Fighter hits harder and takes less in fights (`Combat`,
  `Guard`). Needs hunting by chance on. Add your own roles in the ini.
- **Clan activities** (experimental, off by default, `config/activities.ini [Ambient] On = 1`): clanmates near your cat
  that stand still now and then sit, nap, sniff around or play-fight in pairs - the game's own animations. Which
  activities, how often (`Every`) and how near (`Radius`) are in the ini. **Joining** (`[Join] On = 1`): next to a
  story cat (your mentor, the leader ...) press G and your cats spend time together; afterwards your bond with that
  cat grows (`Bond` points, the game's own bonding - saved, ranks up like a good dialogue answer), once per cat and day.
- **Dialogue name fixes** (`config/text.ini [Placeholders]`): the game's own text misspells some name placeholders
  (`{THE WARROR FATHER}`, `{THE MISTRUSTUL LEADER}` ...), so those lines never showed the cat's name - the mod
  corrects them at load (6 lines; only the misspelled token is changed). Also the rogue cat "Chesnut" is spelled
  Chestnut (`[Text] STR_ROGUE_CAT_NAME_1`).
- **Fishing** (experimental, off by default, `config/hunting.ini [Fishing] On = 1`): walking up to a fishing spot
  startles the fish - they're gone for a few seconds. Keep still on the spot and they come back and bite by chance
  (`Chance`, x your clan's factor: RiverClan 1.5); a bite = the game's own catch is there. Fishing spots become active 30 s
  after you enter the world (setting them up earlier, while the world was still loading, could crash the game).
- **Scent trails** (experimental, off by default, `config/hunting.ini [Scent] Trails = 1`): in sense mode (Q) a scent
  trail leads from your cat to the prey the game marks nearby - glowing scent puffs on the ground (the game's own scent
  effect, every `Spacing` cm), fading after `TrailSeconds`.
- **StarClan's guidance** (experimental, off by default, `config/hunting.ini [Guidance] On = 1`): in sense mode the
  game's own quest-guidance trail leads to a prey creature you can't see yet (1500-9000 cm away), and scent puffs show
  the first stretch of the way (`ShowLength`); it follows the prey and moves on to new prey every in-game hour and after
  a catch.
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
  like the included **Colourpoint** (`PatternMask = look:Colourpoint`). The **shape apart from the stats**
  (`BodyValue`, `FaceValue`, `FurValue`, `EyeValue`, `WhiskerValue`, `TailIdx`, `EarIdx`, `CatSize`): your cat can
  look different from the body its stats came from. Display only - the save keeps the game's look and stats.
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
local mi = WaCa.LoadAsset("/Game/Mods/MyMod/MI_Thing.MI_Thing")  -- also from your own pak in Paks\~mods
```
(UE4SS's own `LoadAsset` only finds assets in the game's AssetRegistry, so it returns nil for anything in a mod pak;
`WaCa.LoadAsset` falls back to the engine's own load.) Making a pak: see `tools\build_content.ps1` - cook in a project
named `Wrc`, with the game's renderer settings, Nanite off on meshes, shader code not shared.
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

### Story and the clan loop
**Your mod's own files, no edits to anyone else's:** every clan-loop config (`duties`, `clanevents`, `days`,
`events`, `gatherings`, `lines`, `patrols`) is WaCa ModKit's file plus `<YourMod>/content/<name>.ini` of every
enabled mod, in load order (`WaCa.ReadContent`). A section only you have is simply added (two mods' clan events both
exist); a section several mods share gets the numbered keys of each APPENDED (`Step1`, `Line1`, `Morning1` ... - two
mods can add beats to the same story day or lines to the same dialogue); a plain key is set by the later mod (logged);
`Off = 1` in your own copy of a section turns another mod's off.

Dialogue by days (`lines.ini`): `[Dialogue.Queen1]` `Who = RiverClanQueen`, `Days = 1-6`, `Require = ...`,
`Case = Talk | Patrol` (`Leader = <role>`), `Line1`...: that cat says one of the lines all day, a new one each day from
a grab bag (no repeats until all came, the last two of a bag wait out the next refill); the random filler pools
`[Lines.<Role>.<Tag>]` take `Days` / `Require` too. `Lines.Pick(name, lines, day)` is the same grab bag for any mod.
Scenes are lines of steps, run one after another, each waiting for its end (`events.lua`, the one scene runner):
`Card: <text>`, `Dialogue: <id> @ <who>` (the game's own conversations and cinematics, ids in
`config/events-dialogues.txt`; who = Deputy, Leader, MedicineCat, Teacher, Nearest or a story role), `Fade: <s>` /
`FadeIn: <s>`, `Wait: <s>`, `Bond: <points> @ <who>`, `Emit: <event>`, `Hook: <name>`. They go into the configs at the
loop's hook points - no code: `duties.ini` `[Third.<Third>]` `Start1...` / `Event1...` and `[Assign.<Task>]` (how the
deputy gives it), `[NightWatch]` (its cutscene), `clanevents.ini` `[Event.<Name>]` (When / Chance / Day / Every / Once
/ Require / steps), `gatherings.ini` (`[Announce]` / `[Chosen]` / `[NotChosen]` / `[Attend]` / `[StayBehind]`),
`days.ini` per story day (`<Third>Start`, `<Third>` beats, `<Third>Duty`, `NightDuty = Hunt` for a night hunt,
`Gathering = Yes` / `GatheringPick = Chosen`). Story variables, kept with the save: `Set: LeaderFavour = 2`,
`Add: GatheringBan 1`, and `If: LeaderFavour >= 5, Rank >= 2` (the rest of the scene only then); clan events take
`Require =` the same conditions; built-in ones: `Day`, `Rank`, `Standing`, `Gathering.Chosen`, `Gathering.Count`.
From Lua:
```lua
local Events = require("events")                          -- inside WaCaModKit; other mods: the WaCa events below
Events.Run({ "Card: The leader calls you.", "Dialogue: <id> @ Leader", "Bond: 2 @ Leader" }, function() ... end)
Events.Hook("ClanThirdEnd", function(ctx, continue)       -- blocking: the loop waits for continue()
    -- your cutscene / scene for ctx.THIRD of day ctx.DAY ...
    continue()
end)                                                      -- also ClanThirdStart, ClanAssign, ClanNight
WaCa.On("TaskDone", function(day, third, task) ... end)  -- also ClanThird, TaskAssigned, TaskTurnedIn, ClanThirdEnded, CampEntered / CampLeft, ClanNight, DutiesJudged
Events.SetVar("LeaderFavour", Events.Var("LeaderFavour") + 3)     -- story variables; Events.Check("LeaderFavour >= 5")
Events.Hook("GatheringStayBehind", function(ctx, continue) ... end) -- also GatheringAttend; WaCa.On("GatheringHeld", ...)
local Follow = require("follow")                          -- cats moving together
local pack = Follow.Group(Follow.Nearest(3), pawn)        -- they follow, holding back while the leader sneaks
Follow.Travel(cats, island, {}, function(g) ... end)      -- a group walks to a place together; Follow.Release(pack)
```
The game's sequencer is open to every mod as events: `SequenceStarted` / `SequenceFinished` (manager, the sequence's
id), `SequenceEnded`, `DialogueStarted` (manager, the dialogue's id), `DialogueNext`. Any other function: `WaCa.Watch`
with a fifth argument hands one of its parameters to the handler - an object, or text (a name, a gameplay tag, a
string, a number, a bool): `WaCa.Watch("SequencerStarted", "/Script/SwtEngine.SwtSequencerManager", "MyEvent",
"post", "sequenceId")`.

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
- `tools\package.ps1`: builds `dist\WaCaModKit-<version>.zip`. Needs UE4SS extracted into `tools\bin\ue4ss`:
  `python tools/ue4ss_release.py tools/bin/src/RE-UE4SS native/build/Game__Shipping__Win64/bin tools/bin/ue4ss`
  packages it from the UE4SS build `native\build.bat` made, with UE4SS's own packager (the release workflow does
  this; UE4SS's rolling experimental release doesn't keep old builds to download).
- `tools\build_content.ps1`: builds the mod's content pak (`dist\content\WaCaModKit_P.pak/.utoc/.ucas`: the rain /
  snow look and the rain sound) with Unreal Engine 5.7.4, headless: the sources are generated
  (`content/scripts/make_sources.py`), the assets made by `content/scripts/build_assets.py` in the content project
  `content/Wrc` (named like the game so the paths match), cooked into their own IoStore container. `package.ps1`
  adds it to the release (installed into `Wrc\Content\Paks\~mods`).
- `tools\release_with_content.ps1 -Version X [-Upload]`: GitHub's release runners have no Unreal, so the zip the release
  workflow attaches has no content pak. Run this on the Unreal machine after the workflow finished: it builds the
  content, the native DLL and the release zip with all of it, checks the pak is inside, and with `-Upload` replaces the
  release's zip (players still download one zip). (The alternative: a self-hosted runner on that machine for the
  release workflow, which could then call `build_content.ps1` itself.)
- `tools/check_hooks.py <unpacked exe>`: checks every native hook target against a game exe (run it on a game update
  before a release); the targets are read from the native sources.
- `tools/AssetDump`: a headless CUE4Parse reader for the game's paks (for research; output stays out of git).

No game files or game data are in this repository.

## License
Apache License 2.0 (see LICENSE). Third party: UE4SS (MIT, shipped in releases), MinHook (BSD-2, `native/third_party/minhook`).
