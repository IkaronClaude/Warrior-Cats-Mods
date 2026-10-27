# tickets.md: the kanban board

Read the whole board (Goal, Doing, P0, P1, P2, P3) every session. When an item starts, move it to **Doing**. When it is
done, tick it and move it to **Archive**, dated and newest first.
"PX:" from the operator means: add a ticket at priority X. It does not mean "do it now".

**Key philosophy (operator, 2026-10-24):** the MVP and the MECHANICS come FIRST. Story is a huge undertaking. The current
story is thin ("go hunt", "go patrol", "go to your den", then sometimes some dialogue). It will fit neatly into the new
systems once they exist. So build the systems, then pour story into them.

## Goal
**NOW (operator, 2026-10-25): the proof of concept is done - work independently and put the custom patterns /
markings / colours INTO THE GAME'S UI (the creator), and store this extra character data in a sidecar file next to
the normal save (the save itself stays compatible), applied automatically when that save is loaded.**

**NOW (operator, 2026-10-24): a simple modding FRAMEWORK, open source, ASAP, so people can start fixing this mess.**
- Max priority hooks, as the community's biggest gripes: **customisation, name choice, PC controls**.
- Clean, extensible interfaces: other mods must be able to build on them and quickly add their own customisation
  (registries / APIs, not one-off patches).
- **EASE OF INSTALL / USE IS FRONT AND CENTER**: one download, one step, works; mods are folders you drop in.
- The Z: install is ours to modify freely (the operator's real install is on their main PC).

Long-term:
A Clans of the Forest that plays like a day in a Clan. You get real daily duties, and the clan's life is shown on screen
instead of narrated. Pacing and characters match the books. The mod sits on the shipped game (mod paks + UE4SS), with no
game data in this repo.

## Doing
- [ ] **P0 creator redesign: custom looks in the game's own creator UI** (operator 2026-10-25; merges the two creator
  redesign tickets, the "creator finding" note and the old "Creator UI injection").
  - [x] Our look is part of the game's look build (native hook on the colour / pattern-mask / markings-mask primitives,
        CatLookPart; 6b3d340) - no flash of the game's value, no repaint loop. VM-verified in the world.
  - [x] Custom looks REGISTERED by mods (namespaced ids, many mods at once) with a base-game FALLBACK: every enabled
        mod's looks/*.ini is discovered (IterateGameDirectories + enabled.txt / mods.txt), id "<Mod>/looks/<File>.ini",
        offered and added as a grid row with its Fallback / Label (creator.ini AutoLooks; 2357c88). VM: a test mod's
        TestMitts.ini became DT_Markings row 21 "Test Mitts" next to Colourpoint. Colour indices: still only the
        palette.ini swatches.
  - [~] Entries in the native pattern / marking grids. DONE so far: native row cloner (tables.cpp, d61c6fa), and at
        startup each offered pattern / markings look becomes a row of DT_Patterns / DT_Markings copied from its
        fallback's row (VM-verified: "WaCa_Colourpoint" added, copied from NewRow_11 = P13_Tabby, 24 rows). Choosing
        it (panel OnGriIdItemChanged + the grid's current item position) stores look:<Name> and keeps the fallback's
        index in the cat data. NOT VERIFIED: that the grid lists the extra row, and the choice handler - the VM
        cannot open the customisation screen (below). Next: operator check; an icon (IconHelper) for Colourpoint.
        The panel standalone lists 0 items (it fills natively only with a preview cat). For the operator check the
        log now says, on the first grid move, "grid lists N items (the game's own: 23, WaCa rows added: 1) - WaCa
        entries listed / NOT listed" - one look at the log answers whether the game fills the grid from the rows.
        Fixed: a reload no longer renumbers the WaCa entries (the game's rows counted without WaCa_ rows).
  - RESOLVED 2026-10-25: the "VM crash" on the customisation screen was the TEST HARNESS - it built the main menu by
    hand on the logos map (M_LogosMap), so the creator never had its level / preview cat. Through the real flow
    (logos -> splash -> Enter -> L_MainMenu_P) the customisation screen works on the VM.
  - DONE for PATTERNS (VM, real creator, 2026-10-25): the grids list UWrcGuiManager.ReadyPatterns /
    ReadyMarkings (fill: 0x1418C2740, found with a hardware watch on the grid's Items), built from the tables' rows -
    so the cloned WaCa row IS in the game's own grid (ReadyPatterns 0..23, WaCa_Colourpoint = 23; item labels are
    generic "Pattern N"). Choosing it logged "Pattern entry 23 chosen = Colourpoint (the cat keeps PatternIdx 12)"
    and rebuilt the preview cats with the WaCa look. Mapping = grid position -> ReadyPatterns index -> row.
    MARKINGS too: their fill (0x1418C33D0) adds 3 game items AHEAD of the ReadyMarkings loop; mapping = position -
    (items - indices). VM: the last markings item -> "Markings entry 23 chosen = TestMitts (the cat keeps
    MarkingIdx 3)". Labels: the WaCa pattern item is relabelled with its look's Label ("Colourpoint" instead of
    "Pattern 23"; VM read back 20 s later). Markings items have no name text. OPEN: an icon (IconHelper).
  - The customisation crash on the VM: AGuiScreenBasePreview's setup (0x141915150) takes the first
    GuiCatCustomActor tagged "Cat" - only the main menu level has one. Reached from the world (a saved cat loaded),
    there is none -> null CatRef -> crash. Test harness: WACA_TEST_CREATOR=1 selects an empty slot (new cat) via
    the screen's GriNav, so the creator always opens in the main menu level.
  - [ ] One checkbox "Customise online cat": unchecked = the online cat gets each custom look's fallback; checked =
        the online cat is customised separately with the native UI (remembered across toggles), a preview switch.
  - [~] Custom colours: a colour wheel / hex entry (the palettes already take extra swatches from palette.ini).
        2026-10-27, hex entry built (creator.lua): each palette gets a last "custom" swatch; choosing it in the game's
        picker (UGuiPopupColorPicker) shows a hex box on the picker, Enter sets that swatch + stores the colour like
        any extra swatch. VM-verified: picker detected, its palette from the colour panel's ControlSelected
        ("FurColors"), every move reports the selected index (read off the preview cat - the game applies it live).
        NEEDS THE OPERATOR: the fur picker shows 20 swatches (4 rows x 5) and arrow keys stop at row 4 - are the
        swatches past 20 (game 21-25, palette.ini extras, the custom one) reachable at all (mouse wheel / scroll)?
        If not, the custom colour needs another trigger (e.g. a key on the picker) - a UX call.
  - [x] Then: drop the WaCa side panel - DONE 2026-10-27: the panel only offers what the grids can't (pattern packs,
        whole-look presets; game shapes across rows with creator.ini PanelShapes = 1); with the default config
        there is no panel (VM: "no WaCa panel (the game's grids offer every WaCa choice)").
- [ ] P1 mouse look feel (operator): the camera clamps the mouse axis to the stick range and runs it through the stick
  curve (max turn speed, stick-like acceleration). Find the camera's axis consumer, feed mouse deltas unclamped.
  Started: WaCaNative_DevAxisBindings dumps an input component's axis bindings and their bound handlers (the
  controller's WrcInputComponent has 4 at +0xE0 incl. Player_Camera_Up / _Right, value-only - nothing bound).
  FOUND the consumer (WaCaNative_DevWatchAxis, a hardware watchpoint on the AxisValue): written by PlayerInput at
  0x1448DC259, read via UInputComponent::GetAxisValue (leaf 0x14408E6xx) from 0x14126C0E0 (returns to 0x14126C16B):
  abs + dead-zone compare + scale multiply (a sibling at 0x14126C1E0 reads a threshold at [rcx+0x748]). Next: name
  those constants / the caller chain, then detour 0x14126C0E0 for mouse input (raw delta, no dead zone / clamp).
  TRACED (WaCaNative_DevTraceCommandAxis): 0x14126C0E0 = dead zone helper; 0x141828B30 = per-command getter
  (vtable +0x1000; invert flags at this+0x8B3 / +0x8B4). Yaw: 0x1417A0B60 turn = sum over cam(63) / move(61) of
  sign * 2 * |v|^[this+0x1D4] (powf 0x147D46ED7), clamped to [-2, 2]; its caller 0x1417A61B0 (camera update) adds
  turn * [this+0x1CC] (turn speed) * dt to the yaw double at [owner+0x4E8]+0x3A0. Pitch: getter vtable +0x1008
  (cmd 62), clamped, separate path. 0x1417A6710 only resets an idle timer (+0x220) on camera input.
  PLAN: MouseX / MouseY out of Player_Camera_* into their own value-only bindings (standard UE input, keybind-menu
  friendly); detour the camera update 0x1417A61B0 (string / call-graph anchors via the relocation framework) and
  after it add delta * sensitivity straight to yaw (+ pitch on its path) - no dead zone, curve, clamp or dt.
  IMPLEMENTED (yaw) in camera.cpp: the mouse (GetInputMouseDelta, standard UE MouseX) goes into the game's own
  turn value as degrees / (turn speed * dt) - turn detour on the update's camera-right callee, anchors "LookAtYaw" +
  body checks. Direct writes to CameraActor+0x3A0 do NOT work (only honoured while the camera sees input; the
  camera tick clamps pitch +-89.9, yaw free, then smooths and recentres behind the cat when idle). VM-proven: the
  turn value carries the mouse (delta 37.8 -> 75.6 deg); the VIEW change could not be measured reliably on the VM
  (CameraCachePrivate reads flaky at 0.6 fps) -> OPERATOR CHECK. Mouse look on/off follows the menu cursor.
  PITCH done too: the raw axis getter (vtable +0x1008, hooked from the live vtable, anchored: the update calls that
  slot + the getter reads the invert flag) answers sign(total) and the pitch speed becomes |total| / dt for that
  frame (restored after) - stick + mouse degrees exactly, inside the game's pitch limits. VM: delta 5.6 -> 8.4 deg,
  game alive. MouseX / MouseY are out of Player_Camera_* (photo mode keeps them). Left: [Mouse] GameplayCapture = 3
  (drag to look) isn't honoured by the native path; the on-screen feel = operator check.
- [~] P1 Spacebar also advances dialogue (operator 2026-10-25): keybinds.ini [DialogueKeyAliases] SpaceBar = Enter
  while a QuestGiverWidget is up (d61c6fa). VM-verified with the game's own WBP_QuestGiver_Dialogue on screen: Space
  logged "dialogue: SpaceBar -> Enter". Left: the operator sees a real conversation advance.
- [x] P1 relocation framework for detours (operator 2026-10-25) - DONE 2026-10-25: every target now has two anchors
  (look: string + call graph from the full build; camera: string + body + callee; save: UFunction thunk + call
  layout; pitch getter: called slot + body), refused when they disagree, logged; tools/check_hooks.py checks all of
  them offline except the save hook's UFunction lookup (runtime only, logged at start-up). 5 of 5 + 6 cross-checks
  pass on the current exe. Original ticket: every hook target found by several independent means
  (signature + anchors: a string / UFunction native pointer / call-site chain), validated (prologue / call layout),
  logged, and a tools/ check that runs every target against a new exe before a release. Started: scan::FunctionUsing
  (string -> referencing code -> unwind-table function start -> prologue check) for the look hooks.
  DONE: tools/check_hooks.py <exe> - reads the targets from the native sources, resolves them offline the same way
  (4 of 4 unique on the current exe, same addresses as the runtime). Left: a second independent anchor per target
  (e.g. the call-site chain from SetDefaultCustomData to the three primitives) cross-checked.
  DONE too: scan::Reaches - each look primitive must be reachable from the full build within 2 calls (chained
  unwind bodies included) or it is NOT hooked; same check in the tool. VM: 3 of 3 "confirmed" at runtime.
- [~] P2 a click skips the splash: menus.lua - a left click while GuiScreenSplash is up presses Enter. VM-verified
  with the game's own WBP_GuiScreenSplash put on screen: the click logged "click on the splash - pressing Enter".
  Left: the operator sees the real splash continue.
- [x] Per-save sidecar: the write path end to end. FOUND + FIXED a real bug: the game saves through the native
  USwtSaveManager::Save (static; 111 C++ call sites), never through ProcessEvent - the Lua RegisterHook on
  SwtSaveManager:Save never fired, so in-game changes never reached the sidecar. saves.cpp hooks the native method
  (anchors: the Save UFunction's thunk -> its call after setne r8b) and raises GameSaved(nil, context) for every
  save; main.lua writes the sidecar on it. VM: GameSaved fired for SelectYourCat_OnFinishScreen /
  SavePlayerExperience / SavePlayerLevel / SaveStringData, game alive.
- [ ] **Operator checks** (only what the VM cannot show - everything else is verified there first):
  - mouse look / camera with a real mouse; the menu cursor with a real mouse
  - the name box with a real keyboard and the Steam keyboard; the creator panel on the real creator flow
  - Escape: pause menu open / close, back in every menu (VM-verified, feel)
  - the look on your own saves (VM-verified with a test look)
  - the creator: Colourpoint listed in the pattern grid (after the game's 23); choosing it shows Colourpoint, the
    game's patterns still work after it (the VM can't open that screen)
  - Space advances a conversation
  - a click on the splash ("press any key") continues
  - mouse look left / right: turns with the mouse at any speed, no stick cap; feel of LookYaw = 2.0; recentring
    while you hold the mouse still (the game's own behaviour)

## P0: Foundation (nothing else can start until this works)
- [x] **Engine version + toolchain.** DONE: UE 5.7.4 (PROJECT_PLAN.md; AssetDump EGame GAME_UE5_7, UE4SS 3.0.1). Pin the exact UE5 version. It is not in the exe strings: the exe is SteamStub-
      wrapped (`.bind` section). Hints: pak v12, utoc v8, so 5.4 or later. Get FModel to browse the paks, plus a
      `.usmap` mappings file (UE4SS dumper or community). Record versions + download sources in PROJECT_PLAN.md.
- [ ] **Asset map.** Extract (FModel export, into gitignored `extracted/`) and map how these work:
      - the clan-cat generator
      - dialogue / quest data (DataTables, string tables, `.locres`)
      - the day structure
      - hunting / prey AI
      - the party system
      - rank ceremonies
      - input bindings
      - graphics settings
      - save data (where the clan roster lives)

      Write the map into PROJECT_PLAN.md.
- [x] **UE4SS injection.** DONE: UE4SS 3.0.1 runs (Lua + the WaCaNative C++ mod), object + header dumps in dumps/. Get UE4SS running: check SteamStub / EOS / any anti-cheat; the game uses the EOS SDK for its
      online content. Live object dump + C++ header dump for a skeleton project. Lua hello-world hook on a gameplay
      function.
- [ ] **Mod pipeline.** A skeleton UE project in the matching engine version (dummy classes from the header dump). Cook a
      test Blueprint mod and load it from a `~mods` pak (IoStore: retoc / ZenTools for repacking). Prove ONE change
      end to end, e.g. a string edit.
- [x] **Deploy rule.** DONE: the release zip installs / uninstalls itself (Install.bat / Uninstall.bat); the Z:
      install is ours to modify (operator), backups as *.vmtest-backup / before overwriting. Installing a mod writes into the game folder on Z:. Agree with the operator where mods are
      installed and how to uninstall cleanly; never rm -rf on Z:. Back up any file before overwriting it.

## P1: MVP mechanics
- [~] **Procedural names: no doubled prefix / suffix** (done, operator check open) (operator 2026-10-25: "Blazeblaze"). The NPC name generator
      (USwtAdventureNPCGenerationManager / UWrcNPCGenerationManager; tables PreffixName.csv / SuffixName.csv +
      the filter tables) must never pick a suffix that repeats the prefix (Blaze + blaze, Fern + fern ...). First tweak
      into the procedural generation.
      0.4.0: DONE (roster.lua) - the only doubled combination in the tables is Blaze + blaze; the fix is general
      (suffix text == prefix text) and replaces the suffix with one its rank uses, deterministically per prefix; runs
      after UQuestManager.OnNPCGenerationCompleted, on load and on slot change, and syncs spawned NPCs. OPEN: the
      operator's in-game check (log line "renamed ... (doubled name)").
- [ ] **Framework: fixed cats for specific roles** (operator 2026-10-25, the next step after the doubled names; the
      base for "1. Canon clan roster"). Data-driven overrides of the procedural generation: for a clan + role (leader,
      deputy, medicine cat, mentor, specific warriors / apprentices ...), a fixed cat - name (any text, via the string
      table), look (FCatCustomData fields + WaCa colours / masks), size, traits. Content packs as ini files so the canon
      roster (and other mods) are just data. Hook points: UWrcNPCGenerationManager (NPCClansData TMap<EGiverRole,
      FCatCustomDataList>, NarrativeCustomDataMap TMap<ENarrativeRole, FCatCustomData>), the generator's
      CSVs (NpcGenerator, CatSize, Scars, ForcedAppearance ...).
- [ ] **19a. PC controls: bindings.** Pause on Esc: DONE in 0.1 (awaiting the operator's test). Still open: hint
      that quests are on K (UI), an in-game rebinding UI (the game's own GuiCustomConfigKey screen should read / write
      our bindings), mouse bindings for the camera.
      Keybind menu (operator 2026-10-25): keep everything mouse / key related standard-UE compatible so the menu can
      just read and write the engine's own input mappings (UPlayerInput action / axis mappings, the menus'
      DT_GamepadButtons* rows, the viewport capture mode) - the menu saves them to keybinds.ini, the one source. The
      raw KeyDown event only observes (aliases press real keys), so it stays compatible.
- [~] **19b. PC controls: mouse.** Replace the tank-style arrow-key controls with mouse camera / movement.
      2026-10-25: mouse CAMERA done (camera.cpp: yaw + pitch through the game's own turn / pitch steps, uncapped);
      movement relative to the camera = next.
- [~] **3. Free-form name input.** (names.ini + the creator's name box done; operator checks open) The player types any name. Keep an auto-generated fallback name for online content
      (minor relevance); find what the online side reads.
      0.2 (2026-10-24): `config/names.ini` (Prefix / optional warrior Suffix) rewrites the string-table entry of the
      player's CURRENT name (STR_CAT_NAME<n><suffix>); the save keeps the game's ids. Text overrides (WaCaNative
      text.cpp + shared Lua API `require("WaCa")`) are verified headless.
      OPEN: the operator's real-game test (does the shown name update? HUD / party / dialogue / ceremony). Then an
      in-game text box at cat creation (UMG, or a runtime-built EditableTextBox from Lua).
- [ ] **1. Canon clan roster.** Remove the procedural generation of the clan cats. Lock the roster to a specific point
      in the books' timeline (pick the book / moment with the operator).
- [ ] **15. Clan-sim day.** Each day you get assignments based on the clan's needs: hunt, patrol, night watch, train
      with your mentor, train your apprentice, ... From deputy rank on, your job becomes ASSIGNING the day's duties
      (then joining whichever you want). This is the backbone that 4 / 6 / 7 / 8 / 14 / 17 plug into.
- [ ] **4. Day / night cycle (Dredge-style, with exhaustion).** Operator 2026-10-25: like Dredge's day cycle, but the
      pressure is EXHAUSTION instead of spooky things - staying out late / doing too much tires your cat (slower,
      worse at hunting / fighting), sleep resets it. A day has three phases, the natural split points for duties:
      **morning** (dawn patrol, morning hunt), **afternoon**, **evening / night** (evening patrol, night watch).
      Sleeping skips to the next phase / day. The phases are what the day scripts (25) schedule against.
- [ ] **25. Story as days (day scripts).** Operator 2026-10-25: the story is defined in DAYS, as data, which keeps it
      organised. Each day defines:
      - per phase (morning / afternoon / evening): cutscenes, the main story quest if any, where you may go
      - the daily duties while below deputy, as chances (hunt 70% / patrol 30% ...) or fixed (train with mentor)
      - which cats get new dialogue
      - season / time of year, and the weather (fixed, or chances: rain 70% / snow 10% / sun 20%)
      - stats a day can copy from an earlier day ("as day 10") so runs of similar days stay short
      - the condition to move on to the next day. Until it holds, the day REPEATS: same setup, minus the cutscenes
        already seen and quests already done, with only the allowed randomness (weather, duty rolls).
      Examples from the operator:
      - Day 1: in the nursery as a kit, can't leave the den; talk to the other kits / mum; sleep to skip to evening.
        Evening: ceremony cutscene, promoted to apprentice. Summer, nice weather.
      - Day 2: morning: starting out with your mentor (cutscene). Afternoon: exploring the territory with your mentor
        (main quest, given locations). Evening: cutscene sharing the excitement with a cat made apprentice the same
        day.
      - Day 10: big story beat, promotion to warrior. Duties hunt 70% / patrol 30%; winter; rain 70% / snow 10% /
        sun 20%. Evening: vigil cutscene (awake all night).
      - Day 11: wake up in the afternoon (after the vigil); otherwise as day 10.
      - Day 12: wake up in the morning; as day 11; main quest: find and fight off the rogues. Repeats until the
        rogues are fought off.
      - Day 13: the next big story beat.
      This is the backbone 15 (clan-sim day) fills in from deputy rank on. Needs 4 (phases), 21 (season / weather) and
      the game's quest / cutscene / dialogue hooks.
- [ ] **9. Hunting rework.** On detection, small prey FLEES instead of charging you; you can still catch it if you're
      fast enough. No more prey combat.
- [ ] **8. Real hunting missions.** Hunting patrols with goals: fresh-kill pile needs, territory, seasons.
- [ ] **7. Real patrols.** Cats join you just for the patrol (temporary party), with border marking and events.
- [ ] **6. Combat training with your mentor.** Actual training sessions, not narrated.
- [ ] **14. Pacing.** Progression must come from time + duties + training, not "3 hunts until deputy". No old deputy
      getting canned for "not doing enough" at your own ceremony. Ceremonies need proper preconditions.

Living world (operator 2026-10-25: "that, plus the other planned features, will make the world feel properly REAL and
lived-in, and you'll naturally form bonds"). Builds on 4 / 8 / 9 / 15:
- [ ] **20. Intentional time skips.** Time passes on screen and on purpose ("a moon passes", with what happened in it),
      never implied by a story jump. A skip is a world event the other systems react to (season, prey, ages, ranks).
- [ ] **21. Seasons and weather.** A season cycle (newleaf / greenleaf / leaf-fall / leaf-bare) driven by the
      intentional time skips, and weather within a season. Both are world state that prey, patrols, duties and visuals
      read. Find what the game already has (sky / lighting / any weather actors, the level's time-of-day setup) before
      building new. Weights (operator 2026-10-25):
      - **Rain: very important.** Full rain (visuals, sound, wet ground) and its effects on prey / scent / patrols.
      - Sun / clear and the season's light: the baseline.
      - **Snow: low priority, minimal.** A proof of concept is enough (some snow piles here and there in leaf-bare).
- [ ] **22. Prey follows the world.** What hunting patrols bring back and what spawns depend on world state:
      - world events: e.g. a poisoned river = no fish. The player CAN still catch a fish there but can't put it on
        the fresh-kill pile (it's poisoned).
      - seasons: leaf-bare = fewer spawns and smaller patrol hauls, especially of prey that hibernates (no / few
        hibernators at all in deep winter).
      - one prey table per species with season / event / weather modifiers (data, so mods can add prey and events).
- [ ] **23. Random prey spawns.** Prey spawns at random times in random places (within each species' habitat: fish
      in water, birds in trees / open ground, voles in undergrowth ...), not at fixed points. Find the game's prey
      spawner first (the hunting / prey AI found under P0).
- [ ] **24. (Bonus) StarClan guidance leads to prey.** The game's StarClan guidance feature points the player to
      these random prey spawns: hunting by following StarClan's lead. Find how the guidance feature picks its target.

- [ ] **Dialogue text bugs (operator, 2026-10-24).** Some lines show unfilled format arguments, e.g. "It seems that 1's
      Prophecy is true": a name placeholder left as an argument index or default. Find the dialogue tables
      (`Quests/NpcDialogues`, `Quests/StoryDialogues`, `Sequencer/DT_QuestSequenceDialogues`) and the FText format
      call that fills them. List every line whose placeholders the game doesn't fill, then fix it: either supply the
      argument at the format call (hook) or patch the text.
      FINDINGS 2026-10-25: Strings_EN.csv has ~1300 role placeholders ({THE WARRIOR FATHER} 186, {PLAYER} 170,
      {THE INSECURE LEADER} 117, {THE AGING LEADER} 113, ... {PLAYER WARRIOR NAME}, {RIVER CLAN DEPUTY}) - NONE of
      those names is a literal in the exe, so they are filled from DATA (role -> current cat, the wacaroles mapping),
      not code. {Player} (77 UTF-16 literals in the exe) and {Friend} (2) are code-supplied, so the two case-variant
      lines (TheUnchosenApprentice "Good-bye, {Player}", STR_DEN_VISIT_FRIEND_HELPED) are likely fine. The reported
      "It seems that 1's Prophecy is true" isn't an EN line as such: most likely a role placeholder whose role had no
      cat assigned yet, filled with a numeric default. Next: hook the role -> name resolution (find the data table the
      roles come from) and log every role resolved to a number / empty; needs a story save at that point (operator's
      save, or reach it on the VM).

## P2: Depth, presentation
- [ ] **17 + 10. "Show, don't tell": a cutscene / event system.** Today everything happens off screen and someone tells
      you about it. You only learn you have an apprentice when he's suddenly in your party, and that he finished
      training when his name changes in the party menu. Needs a scripted-scene framework (Level Sequences / a dialogue
      runner) and events at specific times of the day.

      The FRAMEWORK is core; the story content that fills it is P3. Do it once the clan-sim day (15) exists.
- [ ] **11. Clan cat interactivity.** Every cat repeats the same single line. Context lines (rank, relationship, time of
      day, current duty, recent events), plus interactions.
- [ ] **5. Clan activities.** Sharing tongues, sharing stories: ambient camp life + player-joinable activities.
- [ ] **13. Less "jack of all trades".** Specialisation for your cat (strengths / weaknesses, roles).
- [ ] **2. More customisation.** "Ragdoll" colourpoint layout; more colours (a colour wheel?). Check how the coat
      material / masks work first.
      0.3 (2026-10-25): DONE as a framework. Coat = M_Characters_Base parameters ("Fur Color", "Pattern Mask Color",
      "Markings Mask Color", "Paws Color" = pads, "Ears Color" = inner ears, "Nose Color", "Whiskers Color"; textures
      "Pattern Mask" / "Markings Mask"; Custom Zones = pads + nose only). config/appearance.ini: colours (hex,
      sRGB -> linear), per-part colours, the game's patterns / markings by name in either slot, PNG packs, looks
      (looks/Colourpoint.ini). Verified headless (colour read-back, PNG import, game mask load).
      OPEN: the operator's visual check of the Colourpoint look (tune its ini); eye colour (atlas-based, M_Characters_Eyes);
      an in-game colour wheel UI (needs the editor - now installing 5.7.4); a real colourpoint mask pack (generated
      from the meshes on the player's PC - no game-derived art in the repo).
- [ ] **18. More graphics options.** The current ones are very lackluster; expose the engine's scalability groups +
      extras.

- [ ] **26. Prey scent / visual trails** (operator 2026-10-25: "sick for future work", like The Isle). Prey leaves
      trails - scent you detect (a sense / sniff mode) and visual signs (tracks, disturbed undergrowth) - that you can
      follow to the prey. Ties into 23 (random spawns: the trail is how you find them), 21 (rain washes scent out,
      snow keeps tracks) and 24 (StarClan guidance as an alternative lead).

## P3: Later / big content
- [ ] **27. Side threads** (operator 2026-10-25, future work). Quest chains spanning several days (25) that can be
      missed when not done by a given day, so the story isn't one fixed line.
- [ ] **Decouple cat stats from looks** (frequently requested by players; operator 2026-10-25). Today body type /
      traits drive both the visuals and the stats. Add a separate set of visual sliders / choices whose list carries no
      stat effect; the visuals read from it, the stats keep the original choice.
- [ ] **Story.** Pour the existing thin story into the new systems, then expand it toward the books (needs 15 + 17).
- [ ] **12. Romance + kits (far future).** The friendship system already exists. Add a mate, kits of your own, watching
      them grow up. Maybe in a free-play mode after the story concludes.
- [ ] **16. RiverClan cats swim.** Feasibility unknown (water volumes, animation set, nav).

## Archive
- [x] 2026-10-25 Escape as menu back + pause close: raw KeyDown events (DispatchMessageW) + the Escape = BackSpace alias
      as a real key press, menus only. VM-verified: Escape opens the pause menu in gameplay and closes it; back in
      menus. (Replaces the Button_B watchpoint plan and the 0.3.1 / 0.5.3 [UIKeys] attempts.)
- [x] 2026-10-25 Mouse clicks in the game's menus: the hovered control pressed through its host (OnUIPress /
      OnUIRelease) - the game binds nothing to its buttons' click events on PC. VM-verified (main menu -> Defender).
- [x] 2026-10-25 Cursor in the world: overlay screens (GuiScreenOnlineOver ...) are not menus; decisions on the next
      tick (changing the input mode inside the game's input handling crashed). VM-verified menu <-> gameplay.
- [x] 2026-10-25 0.6.0 event-driven foundation (native event bus on UE4SS's ProcessEvent callbacks, WaCa.On /
      Watch / Ready, no Lua loops); CI builds the DLL from UE4SS source (secret UE4SS_SOURCE_TOKEN), build cache.
- [x] 2026-10-25 The overlay look (repaint after the game's refresh, "still shows our look" checks) - replaced by the
      look build hook; with it the 0.5.3 stale-object crash fix and the 0.6.0 repaint loop (frozen cutscene).
- [x] 2026-10-25 0.5.x creator work: name box flow (Enter rows incl. Button_Skip held), Steam keyboard, palettes,
      side panel, per-character save sidecars (slot = GUID + character), headshots get the look.
- [x] 2026-10-24 ModKit 0.1: native key rebinding (keybinds.ini), installer / uninstaller, GitHub repo + releases.
