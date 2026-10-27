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
- [x] **P0 creator redesign: custom looks in the game's own creator UI** (all parts done 2026-10-27; operator checks below) (operator 2026-10-25; merges the two creator
  redesign tickets, the "creator finding" note and the old "Creator UI injection").
  - [x] Our look is part of the game's look build (native hook on the colour / pattern-mask / markings-mask primitives,
        CatLookPart; 6b3d340) - no flash of the game's value, no repaint loop. VM-verified in the world.
  - [x] Custom looks REGISTERED by mods (namespaced ids, many mods at once) with a base-game FALLBACK: every enabled
        mod's looks/*.ini is discovered (IterateGameDirectories + enabled.txt / mods.txt), id "<Mod>/looks/<File>.ini",
        offered and added as a grid row with its Fallback / Label (creator.ini AutoLooks; 2357c88). VM: a test mod's
        TestMitts.ini became DT_Markings row 21 "Test Mitts" next to Colourpoint. Colour indices: still only the
        palette.ini swatches.
  - [x] Entries in the native pattern / marking grids (2026-10-27; left: a custom ICON needs an image asset - art). DONE so far: native row cloner (tables.cpp, d61c6fa), and at
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
  - [x] One checkbox "Customise online cat" - DONE 2026-10-27: checkbox top right on the customisation screen (or
        F8). On = the preview shows the online cat (no WaCa look: readAppearance -> empty) and the game's controls edit
        only the game values (a WaCa grid entry gives the online cat its fallback, game shapes don't clear the WaCa
        look, no hex box). Off = your cat with the WaCa look. Both kept across toggles. VM, real F8: ON -> preview
        rebuilt bare, WaCa pattern chosen -> "online cat gets its fallback", F8 -> off -> WaCa look back.
  - [x] Custom colours - DONE 2026-10-27 (hex entry): the game's colour pickers get a hex box (top right) showing
        the selected swatch's colour; #RRGGBB + Enter puts that exact colour in the look (the save keeps the selected
        game colour); picking a swatch afterwards drops it (last choice wins). VM, real keys: box shown (#FBD5A7),
        #3366CC typed -> cats rebuilt, swatch 12 picked -> typed colour dropped. FINDING: the pickers are a FIXED grid
        (0x1418E90C0: 4 + flag rows x 5 - the flag most likely the DLC), nothing scrolls, so palette.ini's extra
        swatches never showed (README corrected); more rows would expose the DLC row to non-owners - not done.
        A colour WHEEL instead of the box = a UX extra, if wanted.
  - [x] Then: drop the WaCa side panel - DONE 2026-10-27: the panel only offers what the grids can't (pattern packs,
        whole-look presets; game shapes across rows with creator.ini PanelShapes = 1); with the default config
        there is no panel (VM: "no WaCa panel (the game's grids offer every WaCa choice)").
- [x] P1 mouse look feel (operator) - implemented 2026-10-25/27 (yaw + pitch + camera-relative movement); feel = operator check: the camera clamps the mouse axis to the stick range and runs it through the stick
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
- [x] P1 Spacebar also advances dialogue (operator 2026-10-25): keybinds.ini [DialogueKeyAliases] SpaceBar = Enter
  while a QuestGiverWidget is up (d61c6fa). VM-verified with the game's own WBP_QuestGiver_Dialogue on screen: Space
  logged "dialogue: SpaceBar -> Enter". Left: the operator sees a real conversation advance.
  2026-10-27 (operator): a LEFT CLICK advances dialogue too ([DialogueKeyAliases] LeftMouseButton = Enter) - except while
  answer choices show (QuestGiverWidget mcButton1..4 visible): the click picks the choice itself.
  2026-10-27: a VM real-conversation attempt failed to OPEN one - teleported 150 / walked in from 400 units to the
  nearest quest giver (BP_Quest_Giver_Deputy_C), held E: QuestPlayerController.OnCanInteract never fired, no
  QuestGiverWidget. At 0.3 fps the walk barely moves and that NPC may have nothing to say - an operator press in
  play is the cheap check.
  2026-10-27 (later): walked in for real - 300 units in front of the deputy, then held a movement key: the cat walks
  (~30 units / wall s at 0.3 fps) but camera-relative, so W led away (1429) and S came to 203 then drifted to 607;
  E there: no conversation. Steering the VM cat precisely needs the camera's actual yaw (the game camera ignores
  SetControlRotation) - and that NPC may have nothing to say. Kept for the operator's one press in play (Space AND
  now a left click, operator 2026-10-27).
  DONE 2026-10-27 - VERIFIED IN A REAL CONVERSATION on the VM: started the game's way (the sequencer manager's
  PlaySequenceDialogue with a tag from its own DT_QuestSequenceDialogues - "Unique2_RiverClan_TheVengefulRogue" with
  the nearest NPC; WBP_QuestGiver_Dialogue2_C). Space -> "dialogue: SpaceBar -> Enter", the line advanced ("The walls
  are closing in ..." -> "They've abandoned you ..."); a left click -> "LeftMouseButton -> Enter", advanced the same.
  Found on the way: a plain line shows answer button 1 too, so "choices up" is now "the game's next prompt
  (mcGuiNext) not shown" (visible up the parent chain); and a POSTED click never raised KeyDown on the VM until the
  hook was checked - it does (0x201 seen); the earlier misses were the choices rule.
- [x] P1 relocation framework for detours (operator 2026-10-25) - DONE 2026-10-25: every target now has two anchors
  (look: string + call graph from the full build; camera: string + body + callee; save: UFunction thunk + call
  layout; pitch getter: called slot + body), refused when they disagree, logged; tools/check_hooks.py checks all of
  them offline - the save hook too (2026-10-27: its thunk found in the exe's native function tables, the one "Save" entry
  whose thunk holds the call layout). 5 of 5 + 6 cross-checks
  pass on the current exe. Original ticket: every hook target found by several independent means
  (signature + anchors: a string / UFunction native pointer / call-site chain), validated (prologue / call layout),
  logged, and a tools/ check that runs every target against a new exe before a release. Started: scan::FunctionUsing
  (string -> referencing code -> unwind-table function start -> prologue check) for the look hooks.
  DONE: tools/check_hooks.py <exe> - reads the targets from the native sources, resolves them offline the same way
  (4 of 4 unique on the current exe, same addresses as the runtime). Left: a second independent anchor per target
  (e.g. the call-site chain from SetDefaultCustomData to the three primitives) cross-checked.
  DONE too: scan::Reaches - each look primitive must be reachable from the full build within 2 calls (chained
  unwind bodies included) or it is NOT hooked; same check in the tool. VM: 3 of 3 "confirmed" at runtime.
- [x] P2 a click skips the splash - VERIFIED 2026-10-27 on the REAL splash: a click -> "click on the splash - pressing
  Enter" -> the main menu. menus.lua - a left click while GuiScreenSplash is up presses Enter. VM-verified
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
  - the creator: WaCa patterns / markings in the game's grids (Colourpoint labelled), the hex box on the colour
    picker, "Customise online cat" (F8), no side panel by default
  - A / D strafing relative to the camera (CameraRelativeMove)
  - mouse look left / right: turns with the mouse at any speed, no stick cap; feel of LookYaw = 2.0; recentring
    while you hold the mouse still (the game's own behaviour)

## P0: Foundation (nothing else can start until this works)
- [x] **Engine version + toolchain.** DONE: UE 5.7.4 (PROJECT_PLAN.md; AssetDump EGame GAME_UE5_7, UE4SS 3.0.1). Pin the exact UE5 version. It is not in the exe strings: the exe is SteamStub-
      wrapped (`.bind` section). Hints: pak v12, utoc v8, so 5.4 or later. Get FModel to browse the paks, plus a
      `.usmap` mappings file (UE4SS dumper or community). Record versions + download sources in PROJECT_PLAN.md.
- [x] **Asset map.** DONE 2026-10-27: docs/ASSET_MAP.md (every listed area; the roster lives in the save - NPCData.NarrativeRoles). Extract (FModel export, into gitignored `extracted/`) and map how these work:
      - the clan-cat generator
      - dialogue / quest data (DataTables, string tables, `.locres`)
      - the day structure
      - hunting / prey AI
      - the party system
      - rank ceremonies
      - input bindings
      - graphics settings
      - save data (where the clan roster lives)
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Script the FModel-style export with tools/AssetDump for the listed asset folders into extracted/ (gitignored)
        and write a one-page map (what each blueprint / table controls) - no operator input needed, just time.

      Write the map into PROJECT_PLAN.md.
- [x] **UE4SS injection.** DONE: UE4SS 3.0.1 runs (Lua + the WaCaNative C++ mod), object + header dumps in dumps/. Get UE4SS running: check SteamStub / EOS / any anti-cheat; the game uses the EOS SDK for its
      online content. Live object dump + C++ header dump for a skeleton project. Lua hello-world hook on a gameplay
      function.
- [ ] **Mod pipeline.** A skeleton UE project in the matching engine version (dummy classes from the header dump). Cook a
      test Blueprint mod and load it from a `~mods` pak (IoStore: retoc / ZenTools for repacking). Prove ONE change
      end to end, e.g. a string edit.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Install the matching UE version, generate dummy C++ classes from CXXHeaderDump, cook a test pak with one new
        Niagara (rain) and load it via UE4SS's pak loading - unlocks rain + any custom content.
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
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - = the roster.ini plan under 1 (role -> name + look over the generated cats).
- [ ] **19a. PC controls: bindings.** Pause on Esc: DONE in 0.1 (awaiting the operator's test). Still open: hint
      that quests are on K (UI), an in-game rebinding UI (the game's own GuiCustomConfigKey screen should read / write
      our bindings), mouse bindings for the camera.
      Keybind menu (operator 2026-10-25): keep everything mouse / key related standard-UE compatible so the menu can
      just read and write the engine's own input mappings (UPlayerInput action / axis mappings, the menus'
      DT_GamepadButtons* rows, the viewport capture mode) - the menu saves them to keybinds.ini, the one source. The
      raw KeyDown event only observes (aliases press real keys), so it stays compatible.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Remaining: the on-screen key hints to follow keybinds.ini ([UIIcons] already covers menus; gameplay hints use
        the same icon table - extend the row list).
- [~] **19b. PC controls: mouse.** Replace the tank-style arrow-key controls with mouse camera / movement.
      2026-10-25: mouse CAMERA done (camera.cpp: yaw + pitch through the game's own turn / pitch steps, uncapped).
      2026-10-27: camera-relative MOVEMENT done: the game's movement already is camera-relative (0x1417A4940 moves
      along the camera's forward / right on the ground), but its turn function added movement-right to the CAMERA
      turn (tank feel). Now movement-right reads 0 for the turn function (dead-zone getter vtable +0x1000, hooked
      from the live vtable; anchors: turn calls that slot, the getter reads the invert flag) - A / D strafe, only
      the camera axis / mouse turns the camera. keybinds.ini [Mouse] CameraRelativeMove (default 1). VM: holding
      D -> "movement-right 1.00 kept out of the camera turn". OPEN: the operator's feel check (does the cat turn to
      face its strafe direction, or sidestep? both are the game's own animation choice).
- [~] **3. Free-form name input.** (names.ini + the creator's name box done; operator checks open) The player types any name. Keep an auto-generated fallback name for online content
      (minor relevance); find what the online side reads.
      0.2 (2026-10-24): `config/names.ini` (Prefix / optional warrior Suffix) rewrites the string-table entry of the
      player's CURRENT name (STR_CAT_NAME<n><suffix>); the save keeps the game's ids. Text overrides (WaCaNative
      text.cpp + shared Lua API `require("WaCa")`) are verified headless.
      OPEN: the operator's real-game test (does the shown name update? HUD / party / dialogue / ceremony). Then an
      in-game text box at cat creation (UMG, or a runtime-built EditableTextBox from Lua).
- [ ] **1. Canon clan roster.** Remove the procedural generation of the clan cats. Lock the roster to a specific point
      in the books' timeline (pick the book / moment with the operator).
      DRAFT DESIGN (2026-10-27, for the operator to adjust - built on what the code research found):
      - roster.ini per clan: role -> name + look (the existing name / look framework); applied when the clan is
        generated (the game's procedural roster) by replacing the generated cats' names / looks for those roles.
      PREPARED 2026-10-27: the roster is SAVE DATA - <save>.<slot>.NPCData.NarrativeRoles (role -> "(Role, ClanType,
      BodyValue, FaceValue, FurValue, EyeValue, WhiskerValue, TailIdx, EarIdx, FurColorIdx, Pattern01/02ColorIdx,
      PatternIdx, MarkingIdx, EyeLeft/RightColorIdx, bOverrideColors, PrefixNameId, SuffixNameId)"), 28 roles on the
      VM save; roles change rank with the story (RiverClanDeputy -> Elder). tools/roster_dump.py lists it (read-only).
      BUILD STEPS (operator OK needed - it writes the save): 1) roster.ini [Role.<name>] with any of those fields;
      2) on the character's first load (save-manager Load hook - saves.cpp already finds the save manager), rewrite
      the matching NarrativeRoles entries in the loaded save object (in memory, before the clan spawns) - never the
      file directly; 3) the game then saves it like its own data. Backup: the mod copies WrcGame.json/.sav to a
      dated backup before the first rewrite. Alternative without touching the save: names via text.ini rows
      (STR_CAT_NAME<n><suffix>) - already possible today.
- [ ] **15. Clan-sim day.** Each day you get assignments based on the clan's needs: hunt, patrol, night watch, train
      with your mentor, train your apprentice, ... From deputy rank on, your job becomes ASSIGNING the day's duties
      (then joining whichever you want). This is the backbone that 4 / 6 / 7 / 8 / 14 / 17 plug into.
      DRAFT DESIGN (2026-10-27, for the operator to adjust - built on what the code research found):
      - A day = daynight.lua's day (DayEnded at BedHour). At dawn the deputy hands out 1-2 duties from the clan's
        needs: fresh-kill pile low (USwtAdventureFreshKillPileComponent value) -> HUNT; border / rival tension ->
        PATROL; apprentice rank -> TRAINING; random -> NIGHT WATCH / gather moss / visit elders.
      - Duties are tracked by events the mod already sees: hunt = HuntCaught (n prey), patrol = AreaOverlap /
        reaching marker points, training = a combat with the mentor (OnCombatStarted / Finished).
      - At BedHour: done duties raise standing (a WaCa sidecar value per save; feeds 14 Pacing); skipped ones lower
        it. config: duties.ini (duty weights, counts, standing per duty).
- [ ] **4. Day / night cycle (Dredge-style, with exhaustion).** Operator 2026-10-25: like Dredge's day cycle, but the
      pressure is EXHAUSTION instead of spooky things - staying out late / doing too much tires your cat (slower,
      worse at hunting / fighting), sleep resets it. A day has three phases, the natural split points for duties:
      **morning** (dawn patrol, morning hunt), **afternoon**, **evening / night** (evening patrol, night watch).
      Sleeping skips to the next phase / day. The phases are what the day scripts (25) schedule against.
      PREPARED 2026-10-27: there is NO day / night cycle in the game - BP_DayNightSky (Art/Environment/Tools/Sky)
      only switches fixed looks (TestDay / TestNight / TestThunderClan ... / StartCinematicNight; StartIn* flags;
      a post-process per look: neutralday, night, each clan, moonpool). A cycle = new: turn its DirectionalLight /
      SunDiscDirection over time and blend PostProcess-neutralday <-> PostProcess-night (+ SkyLight, fog). Needs: the
      day length, what ends a day (exhaustion), what happens at night.
      BUILT 2026-10-27 (daynight.lua + config/daynight.ini, off by default): the world's one BP_DayNightSky
      (L_Lights) - its movable DirectionalLight (pitch = sun height, yaw = across the sky), sun + SkyLight intensity
      dimmed to NightLight at midnight, the sky's own "PostProcess-night" blended in by weight; DayMinutes per day,
      StartHour, one step per UpdateSeconds while the HUD is up. DayNight.Hour() for other modules (day scripts,
      pacing, exhaustion). VM (2-minute day): 21:00 -> 09:00: sun pitch -5 (night floor) -> -12.5 (06:00) -> -40
      (09:00), intensity and night look follow (0.83 -> 0.17). Found: this build's FRotator field is "pitch" (lower
      case) - a { Pitch = } table silently keeps 0 (activities / fishing fixed too). OPEN for the operator: day
      length, what ends a day / exhaustion, whether the hour persists in the save (now: StartHour each session).
      PREPARED (same day): KeepTime = 1 keeps the hour + a day count in a sidecar written when the game saves,
      restored on load (VM: "back to day 1, 20:00 (as saved)"); BedHour ends each day: log + WaCa event
      DayEnded(nil, day) + day count (VM, 1-minute days, bedtime 22: "day 1 is over", "day 2 is over");
      DayNight.Hour() / DayNight.Day() for other modules. Exhaustion / pacing can hang on DayEnded - the operator
      only picks the numbers (DayMinutes, BedHour) and what a day's end does.
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
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - days.ini / one file per story day: [Day.N] conditions (rank, duties done, previous choices) + the scenes to play
        (the game's own sequence dialogues by tag - PlaySequenceDialogue, verified on the VM) + which quests unlock.
        Driven by DayNight's DayEnded; the current day number lives in the save sidecar.
- [ ] **9b. Fishing (operator 2026-10-27).** Walking near a fishing spot startles the fish: they disappear for 5 s.
      Stand still on the spot for 5 s and they swim again; then a catch is an X% chance (rolled like hunting). Clan
      bonus: RiverClan +50% fishing chance (config: per-clan factors). Prep: find the game's fishing spot actor /
      fish (CombatBaseExperience has a Fish row: 10 EXP; ESwtQuestCharacterType has fish kinds?), its interaction and
      the fish visuals (to hide / show), the player's clan (save: Customization ClanType / EClanType).
      PREPARED 2026-10-27: the spot = BP_Interactable_Claw_FishingSpot (Gameplay/Blueprints/WorldElements/
      Interactables): components InteractionComponent (SwtQuestInteractSphereComponent), EffectComponent (the reward -
      BP_InteractableReward_Container_Fish), NS_PickUp_Hint (the visible "fish here" sparkle), MoveTo; BP event
      OnInteracted. PLAN: startle = the cat enters the spot's sphere while moving (velocity > threshold) -> hide the
      hint + block the interaction (SwtAdventureInteractableActor ResetInteractable / the sphere's collision) for 5 s
      (one delayed callback); re-armed only after the cat stood still 5 s on it (velocity check at that one callback,
      re-scheduled while it keeps still / moves - bounded). Catch = OnInteracted rolled like the hunt (native detour
      of the interactable's OnInteracted virtual, the hunt.cpp pattern) - chance from hunting.ini [Fishing] Chance +
      per-clan factor (RiverClan 1.5; the clan from the save's Customization ClanType); a miss skips the reward.
      VM 2026-10-27: 7 fishing spots in the world (BP_Interactable_Claw_FishingSpot_C, interaction radius 75).
      Cat teleported onto one: QuestPlayerController.OnCanInteract did NOT fire (UE4SS hook; its native body is
      inlined into the thunk 0x14160D270 - reached through a delegate, if at all) -> the startle trigger needs another
      proximity event. Candidates: the spot's InteractionComponent overlap (a native delegate - find its handler like
      the prey's OnActorOverlapped), or the game's interaction prompt widget (InteractionWidget:SetInteract, a
      UFunction - fires when the prompt shows). NEXT: hook InteractionWidget:SetInteract and walk onto a spot.
      Tried same day: InteractionWidget:SetInteract doesn't fire either when the cat is teleported off / onto a spot -
      like the quest giver (Space-dialogue ticket), a teleported cat never becomes "can interact" on the VM. The game's
      interaction focus needs a real approach (not reproducible at 0.3 fps) - the startle trigger is the one open
      piece; the rest (hide hint, 5 s timers, roll, clan factor) is straightforward once it fires.
      BUILT 2026-10-27 (fishing.lua, hunting.ini [Fishing] / [FishingClan], off by default): each spot gets a trigger
      box of the game's own Blueprint movement-modifier class (flag cleared - a bare native one never reported), so
      the cat entering / leaving a spot are overlap events. Moving in -> hint hidden + interaction off; after
      StartleSeconds: left -> fish back; still -> bite roll (Chance x clan factor, clan read from the save:
      RiverClan); no bite -> wait again. VM: 10 spots armed (RiverClan x1.5); moving arrival -> "startled and gone";
      still arrival -> nothing; spawning inside the HUD hook crashed the game once -> now 2 s later on the game
      thread. DONE 2026-10-27: the whole flow on the VM - moving arrival -> "startled and gone"; 5 s later still ->
      "swim back but don't bite (chance 60%, rolled 72)" -> next round "back and biting (chance 60%, rolled 9)"
      (RiverClan 40 x 1.5). Two crash fixes on the way: UE4SS's native RegisterHook on the areas' overlap
      UFunctions crashed the game on world load (twice, same stack) and those calls never pass ProcessEvent (a
      WaCa.Watch saw nothing) -> areas.cpp detours the areas' overlap virtuals (+0x760 begin / +0x768 end, anchors
      checked offline + live) and emits AreaOverlap(area, actor, entering, flag) - hunting's loud ground uses it too
      (re-verified: "on loud ground" -> both landings heard). The live OnRankChanged RegisterHook is gone too (the
      save follows rank changes).
      CRASH (same day, 3 runs): "reading 0x18c" right as the world came up - the stack's UFunction frame is
      GameplayStatics:FinishSpawningActor = fishing's spawn (the "2 s later" deferral only hid it behind the last log
      line), with the area class taken from whichever BP_MovementModifier_* FindAllOf returned first (it varied per
      run). Now: always BP_MovementModifier_Loud_C, armed 10 s after the HUD, one spot per 0.5 s. Stability run: no
      crash, 7 spots armed.
      NOT SOLVED (same day, later): the Loud variant, one-by-one 10 s after the HUD, crashed again in
      FinishSpawningActor (run 15:52) - the Blueprint's construction reads 0x18c sometimes (~1 in 5 runs). Tried
      instead: the engine's native TriggerBox (spawns safely, overlaps the cat - IsOverlappingActor true) but its
      ReceiveActorBegin/EndOverlap never reach a watch (no Blueprint implements them, so the engine skips the event)
      -> no arrival events; reverted to the Blueprint version, off by default with a KNOWN ISSUE note in
      hunting.ini. Next: find the area Blueprint's construction crash (symbolise 0x143E1AB60 / 0x143E1CDA0 under
      FinishSpawningActor), or detour AActor::NotifyActorBeginOverlap on the TriggerBox (a virtual - find its slot).
      ANALYSIS (same day): the crash is 0x143E1AE02 in 0x143E1AB60 (under GameplayStatics:FinishSpawningActor):
      `call 0x143E241E0; movzx ecx, byte [rax+0x18C]` - 0x143E241E0 is a GetWorld-style accessor that returns NULL
      when the object is a class default (RF 0x10) or its outer is flagged garbage (object-array flag bit 28) - i.e.
      the spawned area's level / outer was being torn down (world-partition streaming) while the Blueprint was
      constructed. Fix to try next: spawn into the fishing spot's OWN level only while that level is visible and
      not unloading (spot:GetLevel(), skip spots whose level is going away), or arm a spot only when the cat comes
      within streaming range of it (re-armed per streaming-in), instead of all 7 at world start.
      FIXED (same day): a stress test spawned 100 of the same Blueprint 20 s after the HUD - no crash; all 4 crashes
      had been 0-10 s after the HUD (world still streaming in). Spots now arm 30 s after the HUD; a full run with
      fishing on: 7 spots armed, no crash.
      Simpler chance model that keeps the game's own catch: on re-arm (5 s still) roll the bite - a hit re-enables
      the interaction, a miss keeps the fish away another round (no native reward blocking needed).
- [ ] **9. Hunting rework.** On detection, small prey FLEES instead of charging you; you can still catch it if you're
      fast enough. No more prey combat.
      SPEC (operator 2026-10-27): the game's instakill (the icon) is too easy.
      - NOISE: during the "instakill cutscene" the cat can loudly walk through leaf litter and the prey doesn't notice
        - it should notice and FLEE.
      - SUCCESS CHANCE per hunt instead of a sure kill, by the cat (rank, or day): apprentice ~20%, warrior ~80%,
        seasoned warrior / deputy 130% base. Prey difficulty multiplies it (rabbit x0.5). Always a 5% critical miss
        (so the effective chance never exceeds 95%). A miss = the prey escapes (flees).
      - Keep: catch = the game's instakill; rats stay hostile; pacing later.
      - SUCCESS CHANCE ON SCREEN (operator 2026-10-27): when the hunt icon (the instakill logo) shows over the prey,
        show the success chance as text under the logo (e.g. "65%") - the same number the roll will use (rank x
        prey factor, capped by the critical miss; "heard" on loud ground).
        BUILT 2026-10-27: the icon is CanvasEnemyInstaKill in the prey's WBP_GuiLevelWarning (the mcGuiLevelWarning of
        the widget its WidgetComponent shows); hunting.lua adds a TextBlock "WaCaHuntChance" INTO that canvas (so it
        shows only with the icon), text = the roll's own chance; set when the world comes up, when new markers are
        built (Construct of WBP_GuiLevelWarning_C, one pass per burst) and on a rank change. VM: "success chance
        shown on 63 prey". NOT SEEN on screen yet (the VM camera / marker distance) - operator: does "65%" sit
        nicely under the icon? (position: 4 px under the canvas bottom, centred, the default font).
        VM tries to SEE it (twice): the cat put 250 units behind a mouse + its icon forced visible + screenshots - the
        game camera ignores SetControlRotation, the mouse stays a dot at the frame's edge and its marker doesn't
        render at that distance. Seeing it needs the camera steered (mouse look) - a check for the operator's eyes.
        Later: the camera CAN be steered on the VM - read PlayerCameraManager.CameraCachePrivate.POV, hold the
        arrow keys (Player_Camera_Right) until within 15 degrees (it got to 5). With the mouse in view, 200 units in
        front of the crouched cat, the game still showed no instakill icon and Space gave no landing - the hunt
        needs more than position (the prey unaware / a real approach). Kept for the operator's play check.
        The icon's meaning: WBP_GuiLevelWarning holds CanvasEnemyWeaker / Same / Stronger / Stronger2 / InstaKill -
        a LEVEL-GAP marker (the instakill icon = far below the cat's level), shown only while the marker itself is up
        (all 153 hidden at rest, VM). So the chance label appears exactly on the prey the game marks instakillable.
        Last VM try: camera steered onto the mouse (6 degrees off) + its marker, level-warning widget, instakill
        canvas and widget component all forced visible, screenshot 8 s later - still nothing drawn: the game draws
        these markers by more than their visibility flags. The label's look is the operator's check in play.
        Also tried: sense mode (Q held, the screen darkens) with the camera on the mouse - no marker, no landing.
      - FLEE / CHASE (operator 2026-10-27): the game has none today; a prey that flees and can be chased would be a
        cool addition but is FUTURE WORK. For now a miss / a noticed cat = the prey is no longer instakillable (the
        game's normal reaction), not a flee. prey.cpp / hunting.lua's pounce-prey flee stays off.
      - EXP (operator 2026-10-27): a successful hunt gives the EXP a FIGHT against that prey would have given (the
        instakill currently skips it). Find the combat reward path (exp per CharacterType / the encounter's reward)
        and grant the same amount on a catch.
        FOUND: the amounts are the game's own table Gameplay/DataTables/NonAsset/CombatBaseExperience.csv
        (FSwtAdventureCombatBaseExperience: Enemy, BaseExperience, DifficultyOffset; rows = CharacterType names:
        Mice 25, Squirrel 30, Rabbit 40, Bird 30, Rat 60, Weak* lower) - read it at runtime by the prey's
        CharacterType name, no copies. The grant itself is native-only (no UFunction adds EXP) - trace the combat-end
        path to it (FQuestExperienceStruct {Level, Experience, MaxExperience}; RankUp:OnLevelUp listens).
      - INSTAKILL CHAIN (traced 2026-10-27, exe of 2026-10-25): the roaming prey's USwtAdventurePreyComponent
        (vtable from a live one, WaCaNative_DevVirtual): +0xAA0 OnHunterLanded 0x1417C97C0 = the cat LANDS on the
        prey -> broadcasts the component's unreflected delegate at +0x5A8 (the hunted sequence) and, with
        bRequiresInteract, drops the component from the cat's interactables (+0x770). +0xAA8 OnHuntedSequencerFinish
        0x1417C9810 = the sequence ended (the kill's aftermath). +0xAB0 OnHuntedPounceReached 0x1417C9A60 = only
        stops the hunter's movement when a pounce ends (not the kill). PLAN: detour +0xAA0 - roll the chance; a miss
        skips the original (no sequence; the prey goes on as the game makes it); a hit runs it and later grants the
        CombatBaseExperience EXP. Anchor: the OnHunterLanded thunk (UFunction) calls [rax+0xAA0].
        VM: Space / E with the cat crouched 60 units behind a mouse (pounce range 1) did not start a pounce - at
        0.3 fps a 50 ms key tap falls inside one frame; a 6 s held Space didn't either. Unknown what the game needs
        (an on-screen prompt? approach by walking?). Operator: "Space once close enough; loud ground before that
        and it flees".
      - BUILT 2026-10-27 (experimental, hunting.ini [Chance] On = 0 by default): hunt.cpp detours +0xAA0 (anchor
        checked offline + live), rolls rank chance x prey factor (cap 100% - CriticalMiss); only [Chance] PreyKinds
        (+ Weak*) are rolled - NPC cats carry the same component for the sneak attack and pass through. The rank comes
        from the game's own save (WrcGame.json <save>.<slot>.GameplayProgression.Rank; re-read on GameSaved
        "SavePlayerRank"); live OnRankChanged too. VM (hand-fired landings): Deputy -> mice 95%, rabbit 65%, 5 caught,
        1 critical miss (rolled 96). NOT YET: a REAL pounce (VM can't trigger one), EXP on a catch, the noise check.
        Level component (unreflected): +0x120 Level, +0x124 max level (20), +0x154.. stats; its resource SetValue
        0x1416588A0 (virtual, clamps to max - no level-up) saves "Experience" - the add-with-level-up is still to find.
      - EXP (2026-10-27): the grant is built - hunt::AddExperience calls the level component's resource add-value
        (vtable +0x508 = 0x14165B460: scales by the EXP multiplier +0x114, current EXP +0x10C (396 = the save's),
        next-level threshold +0x110; anchors = those two field reads, once each) via WaCaNative_AddExperience; Lua
        grants the prey kind's BaseExperience on HuntCaught ([Chance] Experience = 1). DONE 2026-10-27: the table
        lives in the tuning manager (BP_WrcTuningManager_C on the game instance - found by vtable: its init, slot
        +0x378, tail-calls the loader) as an unreflected TMap<FString, row> at +0x460 (0x28 elements; anchors: the
        loader's lea rdx,[rbx+460h] + the map's shape). VM: rabbit +40, mouse +25 -> EXP 396 -> 461; a critical
        miss rolled 100. (Old note: the amounts table is
        the NonAsset CSV Gameplay/DataTables/NonAsset/CombatBaseExperience.csv - NOT a loaded DataTable (no runtime
        object; the 34 combat DTs don't include it), read by code not yet found (no path string; the struct is
        SwtAdventureCombatBaseExperience). VM: 3 caught mice -> "no EXP ... table isn't loaded", EXP stayed 396.
        Next: find the loader (the struct's StaticStruct users / a watch on +0x10C during a won fight) and read
        the parsed rows from there - no copied numbers.
      - FUTURE (operator 2026-10-27): WIND DIRECTION. Prey that hunts by scent (all but birds) smells a cat that is
        upwind - circle it to approach downwind, and never from the front (its view). Later: by prey difficulty, it
        checks the scent / turns around more often.
      - NOISE (operator: "in the instakill cutscene the cat can loudly walk through leaf litter - should make it
        flee"): FOUND 2026-10-27 - the game defines NO physical surface types (Wrc/Config/DefaultEngine.ini has no
        PhysicalSurfaces; nothing reads a surface type), so "loud ground" is not a surface system to hook. Prey
        detection is crouch / presence based (OnCrouch). OPERATOR: what exactly makes it loud - the footstep SOUND
        on leaves, or not crouching / moving fast during the approach? With that, the rule hooks the approach
        (bRequiresInteract interaction -> OnHunterLanded) and fails the roll when it applies.
        CORRECTED + BUILT 2026-10-27: the game HAS ground types - its own (EAdventurePhysicalFloorType: Grass, Dirt,
        Wood, DeepWater, Water, TileRoof, Rocks, DryLeafs, Mud, Metal; the step cue S_Cue_cat_step switches on
        StepType; BP_AnimStepNotify = USwtAdventureStepModifierNotifyState) - not engine surface names. And the
        game's NOISE system: ASwtAdventureMovementModifierArea trigger boxes give EAdventureMovementFlag Loud (32) -
        12 BP_MovementModifier_Loud_C in the world (+29 Hiding); also ApproachingSneakVictim (4096) = the instakill
        approach. Rule: hunting.lua tracks the cat entering / leaving Loud areas (their overlap UFunctions; params read
        INSIDE the hook - deferring them crashed the game on world load) -> HuntLoud; hunt.cpp: a landing while on loud
        ground or within NoiseWindow (3 s) of leaving it = heard, the prey escapes, no roll. hunting.ini Noise /
        NoiseWindow. VM: cat moved into BP_MovementModifier_Loud_C_2 -> "on loud ground"; 2 mouse landings -> both
        heard. Possible refinement: also DryLeafs floor steps outside the Loud areas (the step notify).
      PREPARED 2026-10-27 (research, nothing built yet):
      - Prey = AWrcPouncePrey (ACharacter): PreyGenerator, ExplorationDetectionComponent (USwtAdventureDetection-
        Component: USphereComponent, Range EAdventureDetectionRange, DetectedCharacters, DetectionType),
        ExplorationPreyComponent (USwtAdventurePreyComponent: SneakAttackWalkOffset / Height, ActorsInPounceRange,
        OnHuntedPounceReached, OnHunterLanded), DimensionsTag (size class -> "small prey").
      - Detection: UFunction AWrcPouncePrey:OnCharacterDetected(detectedCharacter) - native; its exec thunk
        (0x14186A250) calls the prey's VIRTUAL vtable +0x9F0 = the real reaction (the charge / encounter start).
      - Plan: hook vtable +0x9F0 from a live prey (as camera.cpp hooks the axis getters; anchors: the thunk found by
        UFunction name calls that slot - checkable offline like the save hook). For small prey (DimensionsTag), skip
        the original and flee: AIController MoveToLocation / AddMovementInput away from the hunter, despawn past a
        distance; the pounce (OnHuntedPounceReached / OnHunterLanded) stays the way to catch it. Config: which
        dimension tags flee, flee speed / distance.
      - Operator input wanted: which prey flee (all small? by tag), how far / fast, what happens to the encounter
        system for larger prey.
      BUILT 2026-10-27 for AWrcPouncePrey (prey.cpp + hunting.lua + config/hunting.ini: Flee, FleeDistance,
      FleeSpeed, ExcludeTags): the reaction (vtable +0x9F0) hooked from the first live prey, skipped for non-excluded
      size tags; PreyFlee event -> AIBlueprintHelperLibrary.SimpleMoveToLocation away from the cat; the pounce still
      catches it. NOT YET SEEN WORKING: no pounce prey spawned in the open world on the VM (0 live). The world has 168
      generators - BP_Enemy_Generator_C x164 and BP_Boss_Generator_C x4, none of them pounce prey - so the animals
      that CHARGE you may be the enemy encounters, not pounce prey. OPERATOR: which creatures charge you (pounce prey
      during hunts, or the roaming enemies)? If the enemies: the same flee goes on their encounter start
      (ASwtAdventureCharacter OnEncounterOverlap / EncounterActor).
      ANSWERED (VM, 2026-10-27): the prey that charge you are COMBAT characters - BP_Exploration_Character_Base_C from
      the 164 BP_Enemy_Generator_C, with ESwtQuestCharacterType Mice x25 / Squirrel x12 / Rabbit x14 / Bird x12 (+ Rat
      x12, large enemies x7, cats x66 at one spot). Their chase = their AI (Blueprint behaviour tree), the fight =
      OnEncounterOverlap (touching the cat). Pounce prey: 0 in the open world. So prey.cpp / hunting.lua (pounce prey)
      is NOT this feature - switched OFF by default (hunting.ini Flee = 0, experimental). The real build: for prey
      CharacterTypes, no chase (detection / AI) and no fight on touch. OPERATOR DECISION NEEDED: what "catching" is
      without combat (instant catch on touch? a fresh-kill item? a short chase-pounce?), and whether rats stay hostile.
      OPERATOR 2026-10-27: catch = instant on touch; rats stay hostile; pacing later; hunting = next. AND: "there
      already exists a hunting mechanic plus icon for prey that can be instakilled" -> the roaming prey carry
      USwtAdventurePreyComponent (VM: rabbit / mouse, bRequiresInteract, SneakAttackWalkOffset 200) - the catch IS
      the game's instakill; nothing new needed for it.
      TRACED: a prey's detection = its BP_Exploration_DetectionComponent's sphere overlap (the cat lands in
      DetectedCharacters inside the engine's overlap processing, 0x141C3C920 <- 0x141C23E70) - the charge starts from
      a Blueprint overlap reaction / the AI behaviour tree (roaming states Idle / Checking / Walking / Grazing /
      Hunted, no flee state), not a native function. (After the test teleport the game went back to the main menu -
      unexplained, mind it when testing.)
      PLAN A (next, simple): for small-prey CharacterTypes (Mice / Squirrel / Rabbit / Bird + Weak*), switch off the
      ENCOUNTER collision (OnEncounterOverlap) - a charging prey can't start a fight, and next to you the game's
      instakill catches it. PLAN B (flee proper): also stop the chase - identify the behaviour tree's chase branch
      (BT asset export) and send the prey away instead (SimpleMoveToLocation), re-issued when the tree retargets.
- [ ] **8. Real hunting missions.** Hunting patrols with goals: fresh-kill pile needs, territory, seasons.
      PREPARED 2026-10-27: the fresh-kill pile exists natively - ASwtAdventureFreshKillPileActor with
      USwtAdventureFreshKillPileComponent (a USwtQuestResourceComponent: a quest resource value),
      USwtAdventureGainFreshKillEffect, UGuiPopupFreshKill, UAdventureDialogueActionFreshKillPile. Pile needs = that
      resource; prey = combat characters by type (Mice / Squirrel / Rabbit / Bird / Rat, see 9). Needs: the mission
      goals.
- [ ] **7. Real patrols.** Cats join you just for the patrol (temporary party), with border marking and events.
      PREPARED 2026-10-27: no native patrol classes. Parties exist (ASwtAdventureCharacter.Party, OnPartyMemberDestroyed)
      - a patrol = a temporary party + a route. Needs: patrol goals / events.
      DRAFT DESIGN (2026-10-27, for the operator to adjust - built on what the code research found):
      - A patrol duty picks 2 clanmates (idle, nearest - activities.lua already finds them) as a temporary party
        (ASwtAdventureCharacter.Party) and 3-4 border points along the territory edge (the map's territory volumes;
        fallback: points from config). The cats follow (AI move, brain paused as in activities pairs).
      - At each point: scent-mark (a montage) and a small random event (rival scent -> an encounter, prey -> a hunt
        chance, nothing). Done -> party dissolves, duty done.
- [ ] **6. Combat training with your mentor.** Actual training sessions, not narrated.
      DRAFT DESIGN (2026-10-27, for the operator to adjust - built on what the code research found):
      - A training duty starts a combat with the mentor (the game's own combat, a friendly variant: no injuries);
        win / lose both give EXP (CombatBaseExperience "Cat" row = 45) and a technique point; config: training.ini.
      - Needs: how the game starts a sparring combat (Skirmish / DT_Combat_Skirmish already exists - reuse it).
- [ ] **14. Pacing.** Progression must come from time + duties + training, not "3 hunts until deputy". No old deputy
      getting canned for "not doing enough" at your own ceremony. Ceremonies need proper preconditions.

Living world (operator 2026-10-25: "that, plus the other planned features, will make the world feel properly REAL and
lived-in, and you'll naturally form bonds"). Builds on 4 / 8 / 9 / 15:
      PREPARED 2026-10-27: rank-ups are URankUp objectives - RequiredLevel (player level) + Objectives (quests) - and
      UQuestObjectiveRankUpTask (Rank, Tasks; the rank-up sequence). So "3 hunts until deputy" = those objective
      lists / levels in the quest data. Pacing hooks: raise RequiredLevel / add objectives (data), or gate rank-ups on
      days / duties served (with 15 / 25). Needs: the target pace per rank.
- [ ] **20. Intentional time skips.** Time passes on screen and on purpose ("a moon passes", with what happened in it),
      never implied by a story jump. A skip is a world event the other systems react to (season, prey, ages, ranks).
      BUILT 2026-10-27 (experimental, timeskip.ini On = 0 by default): DayNight.Skip(days, hour) moves the save's day
        count and emits TimeSkipped + DayStarted (season, weather, prey follow); timeskip.lua shows the card on the
        game's own WBP_GuiPopupCenterMessage (text set AFTER AddToViewport - its construct fills a string-table key),
        rest key F9 (RestDays; only in the world: not in a menu, the cat present). VM: F9 -> "A quarter moon passes.
        It is Leaf-fall." on screen, the season / weather / prey moved on, day 1 -> 8 -> 15 (leaf-bare, snow).
        Screenshots need "shot showui" - plain "shot" leaves ALL UI out (why the hunt label was "never seen").
        Open: what happened during the skip (duties auto-resolved, the fresh-kill pile eaten, rank progress) once
        those systems exist (15 / 25); a nicer card than the centre message (event cards, 17 + 10).
      DRAFT DESIGN (2026-10-27, for the operator to adjust - built on what the code research found):
      - A skip = jump DayNight.Day() by N with a full-screen card ("A moon passes...") listing what happened (duties
        auto-resolved by standing, prey eaten from the pile, rank progress) - the card is one of the game's own
        popups re-texted (WaCa.SetText) to avoid new widgets.
- [ ] **21. Seasons and weather.** A season cycle (newleaf / greenleaf / leaf-fall / leaf-bare) driven by the
      intentional time skips, and weather within a season. Both are world state that prey, patrols, duties and visuals
      read. Find what the game already has (sky / lighting / any weather actors, the level's time-of-day setup) before
      building new. Weights (operator 2026-10-25):
      - **Rain: very important.** Full rain (visuals, sound, wet ground) and its effects on prey / scent / patrols.
      - Sun / clear and the season's light: the baseline.
      - **Snow: low priority, minimal.** A proof of concept is enough (some snow piles here and there in leaf-bare).
      PREPARED 2026-10-27: no native weather / season classes; the sky is BP_DayNightSky's fixed looks (see 4). Rain =
      new (a Niagara system + wet materials / post-process); seasons = new state driving the look and 22 / 23.
      TRIED 2026-10-27 (VM, with screenshots - Unreal's "shot" console command works offscreen, Saved/Screenshots):
      the game ships NO rain effect. Candidates seen: NS_DropsFalling (User.Area, User.Color - a small drip; 4
      copies above the cat with a big Area: nothing visible), M_PP_RainDrops (screen drops; added as a weighted
      blendable on the active post-process: nothing visible), puddle decals, T_rain_ripples02, S_Cue_Wind. Real rain
      = a NEW Niagara asset made in the Unreal editor and shipped in a mod pak (a content pipeline the mod doesn't
      have yet) - the weather logic itself (when, how long, darker light via daynight) is easy on top of it.
      DRAFT DESIGN (2026-10-27, for the operator to adjust - built on what the code research found):
      - Season = days (DayNight.Day()): N days per season (default 7), stored in the save sidecar with the day.
      - Season drives: day length (DayMinutes per season), night light, prey factors (hunting.ini per season: leaf-
        bare = 0.6 x chance, fewer prey), fishing chance, and the look (post-process tint per season).
      - Weather (rain) waits on a rain asset (mod pak); until then: overcast = darker light + fog (sky light /
        ExponentialHeightFog density - both on the sky actor).
      BUILT 2026-10-27 (experimental, weather.ini [Seasons] On = 0 by default): weather.lua - seasons from the save's
        day count (daynight now counts days at midnight without a BedHour, emits DayStarted / HourChanged), weather
        spells (MinHours-MaxHours in-game hours) rolled from each season's chances, kept in a save sidecar. The look
        goes through DayNight.SetLook (sun / sky light x, fog density x, sunlight tint, the season's DayMinutes /
        NightLight), faded over FadeSeconds; works with the cycle off too (the sky's own look, dimmed / tinted).
        Hunting (base chance x) and fishing (bite chance x) follow WorldFactors (season x weather). Effect / Sound
        slots per weather (a Niagara system attached to the cat, a 2D looping sound) - empty until the content pak.
        Offline logic test (lupa, 60 days): seasons turn every 7 days, Snow only in leaf-bare. NOT YET VM-CHECKED
        (the VM's Steam was busy - the game stalled at the logos, with the stock UE4SS too).
        CONTENT PAK BUILT (same day): tools/build_content.ps1 - UE 5.7.4 on the VM, fully headless (~1 min):
        generated sources (an open cylinder .obj, a synthesized seamless rain loop .wav), assets made by
        content/scripts/build_assets.py in the content project content/Wrc (M_WaCaPrecip = one Custom HLSL node:
        falling streaks / flakes, depth + near-camera fade; MI_WaCaRain / MI_WaCaSnow; SW_WaCaRainLoop looping),
        Label_WaCaContent -> chunk 7701 -> its own IoStore container (5 assets, 405 KB, shaders inline:
        bShareMaterialShaderCode off) -> dist/content/WaCaModKit_P.* -> Paks/~mods (package.ps1 + installer).
        weather.lua: a material Effect = 3 cylinder layers (EffectLayers) added to the cat as components; Niagara
        still supported. Pitfalls: Interchange import asserts headless unless Interchange.FeatureFlags.Import.
        SyncToBrowser 0; CameraDepthFade is a material function in UE5 (built from PixelDepth instead).
        IN-GAME (VM, 2026-10-27 evening): WORKS - the pak mounts from ~mods (an empty .pak is fine), the assets load,
        the 3 rain layers draw around the cat (screenshots), the rain sound starts, no crash with the effect on.
        Three bugs found + fixed on the way: (a) UE4SS's LoadAsset only finds AssetRegistry assets -> nil for any
        mod pak: WaCa.LoadAsset falls back to KismetSystemLibrary LoadAsset_Blocking (soft ref) - a modder API now;
        (b) "GPU Crash dump Triggered" seconds after loading the MESH: UE 5.7 imports meshes with Nanite ON - now off
        (build_assets.py); (c) the content project now compiles under the game's own [/Script/Engine.RendererSettings]
        (r.AllowStaticLighting=False, r.VirtualTextures ...), read from the player's paks by build_content.ps1 into
        the generated DefaultEngine.ini (template committed, no game data in git).
        The VM's "stuck at the logos" since this evening: the logo clips' media player never opens (not playing /
        preparing / ready) - the test harness (VM only, unshipped) calls the screen's own OnVideoComplete for a clip
        that doesn't play; not a mod issue. (My earlier "Steam is busy" guess was wrong: Steam was logged in fine.)
        TUNING (operator): the default streaks are too thin / faint to see at the VM's 480x270; EffectParams in
        weather.ini (Opacity, Width, Columns, Rows, Length, Speed, Density, Glow) tunes the look without a rebuild.
        OPEN: (1) the look at a real resolution + the sound level (operator's PC);
        (2) the release CI has no Unreal - the pak must be built on the VM and shipped (operator's call: attach a
        separate content zip to the release, or a self-hosted runner).
- [ ] **22. Prey follows the world.** What hunting patrols bring back and what spawns depend on world state:
      - world events: e.g. a poisoned river = no fish. The player CAN still catch a fish there but can't put it on
        the fresh-kill pile (it's poisoned).
      - seasons: leaf-bare = fewer spawns and smaller patrol hauls, especially of prey that hibernates (no / few
        hibernators at all in deep winter).
      - one prey table per species with season / event / weather modifiers (data, so mods can add prey and events).
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Prey counts per area follow the season + the fresh-kill pile: the enemy generators (BP_Enemy_Generator_C, 164)
        get their spawn tables / caps adjusted per season (find their spawn-table property on a live generator).
      FOUND 2026-10-27 (paks, AssetDump): the 163 generators sit in L_General_Gameplay; each picks a combat setup TAG
        per player clan x rank (ThunderClanCombatTags.ApprenticeSetup = Gameplay.Combat.Generator.Fixed.Mice.03 ...),
        resolved by DT_Combat_Generator rows (323: GeneratorTag, NumParty, CharacterParty {kind, Level}) - the count
        is baked per row (Mice.01/.02/.03 = parties of 1/2/3). No per-generator spawn cap is reflected.
      BUILT 2026-10-27 (with weather.ini [Seasons] On): preyworld.lua - [Season.*] Prey = Mice=0.6, Squirrel=0.2 ...
        = the share of each kind about that season (Weak* = its kind). Each roaming creature is rolled once per season
        (on spawn - a ReceiveBeginPlay watch on BP_Exploration_Character_Base_C - and on a season change); an absent
        one is hidden, collision off, its AI's brain stopped - NOT destroyed (the generator would respawn it). Offline
        test (400 stub creatures): leaf-bare hides ~40% mice / ~80% squirrels, all back in greenleaf.
        VM 2026-10-27: leaf-bare start -> 35 of 148 creatures away, hourly turnover running, snow falling (shot),
        hunting x0.54, stable. Open: patrol hauls / fresh-kill pile by season (needs the patrol system - 15), world events
        (poisoned river = no fish).
- [ ] **23. Random prey spawns.** Prey spawns at random times in random places (within each species' habitat: fish
      in water, birds in trees / open ground, voles in undergrowth ...), not at fixed points. Find the game's prey
      spawner first (the hunting / prey AI found under P0).
      BUILT 2026-10-27 (random TIMES): preyworld.lua - every in-game hour (daynight HourChanged) PreyTurnover (0.2) of
        the creatures roll again against the season's share, so prey comes and goes during the day. Random PLACES
        (PreyRandomPlaces = 1): a creature coming back appears at a random point of its nearest generator's
        AreaComponent box, dropped from 1.5 m above. VM: 24 came back elsewhere in 3 min, none fell through the world
        (no height jumps > 3 m in 8 checks), stable. Open: a moved prey's pounce in real play (operator); habitat per
        species (fish only at water ...) - today a creature stays in its own generator's area, which is its habitat.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - On a timer step per in-game hour, pick a generator in the cat's area and spawn one prey of its kind at a random
        point of its habitat (fish only at fishing spots) - the generator's own spawn function if reflected, else
        SpawnActor of its character class (spawn only 30 s+ after world load - the streaming crash lesson).
- [ ] **24. (Bonus) StarClan guidance leads to prey.** The game's StarClan guidance feature points the player to
      these random prey spawns: hunting by following StarClan's lead. Find how the guidance feature picks its target.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Hook the game's StarClan guidance target (its quest-objective / scent-objective actors, e.g.
        BP_ScentObjectiveFish) and point it at the nearest prey of the kind the clan needs.

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
      FIXED 2026-10-27 (one class of it): the game's own English text MISSPELLS name placeholders - {THE WARROR
      FATHER}, {Warrior father}, {THE MISTRUSTUL LEADER}, {THE MISTRUSTING LEADER}, {THE VENGEFUL WARRIOR}, {Player} -
      so those names never get filled in. config/text.ini [Placeholders] WRONG = RIGHT; at load every string-table
      line (GetKeysFromStringTable, 8901) holding {WRONG} is rewritten to {RIGHT} at runtime (no game text shipped).
      VM: 6 lines fixed (TheUnchosenApprentice / Crowfeather / TheZealousWarrior / RiverClanQueen /
      TheMistrustfulLeader / RiverClanApprentice). The "1's Prophecy" line itself isn't in Strings_EN.csv as worded -
      the detector below still logs any other unfilled line in play.
      Checked 2026-10-27: STR_CLAN_COMPLETION "{CLAN} Prophecy {N}%" renders correctly ("RiverClan Prophecy 56%" on Select
      Your Cat, VM); no "{X}'s Prophecy" / "It seems that ... Prophecy" line exists in Strings_EN.csv. The reported line
      must come from another source (a sequence subtitle / a DT text) - the in-play detector names it when seen. Not fixed: {THE TRAITOR} (likely a real
      dynamic role - left as is). Every placeholder the text uses was counted (Strings_EN.csv: {THE WARRIOR FATHER}
      186, {PLAYER} 170 ... down to these one-offs).
      2026-10-27: main.lua now checks every dialogue line once shown in full (QuestGiverWidget.OnTypewriterDone) and
      logs "dialogue: UNFILLED ..." with the dialogue node for a {placeholder} or a number before 's - any playthrough
      (the operator's included) names the broken line and its node.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Done part: misspelled placeholders fixed (text.ini [Placeholders]); the in-play detector names any other
        unfilled line - its fix is one text.ini line each once seen.

## P2: Depth, presentation
- [ ] **17 + 10. "Show, don't tell": a cutscene / event system.** Today everything happens off screen and someone tells
      you about it. You only learn you have an apprentice when he's suddenly in your party, and that he finished
      training when his name changes in the party menu. Needs a scripted-scene framework (Level Sequences / a dialogue
      runner) and events at specific times of the day.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Event cards first: reuse PlaySequenceDialogue (a real conversation opened on the VM) for small scenes with
        the involved cats; later real cinematics via the game's level sequences (LS_Cinematic_*) re-targeted.

      The FRAMEWORK is core; the story content that fills it is P3. Do it once the clan-sim day (15) exists.
- [ ] **11. Clan cat interactivity.** Every cat repeats the same single line. Context lines (rank, relationship, time of
      day, current duty, recent events), plus interactions.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Context lines by rank / relationship / time of day: the game's own Strings_EN rows already exist per role
        (QST_Story.Monologue.Filler.<Clan><Role>.*) - pick the line by context instead of the fixed one (hook the
        filler monologue choice), DayNight.Hour() for morning / night lines.
- [ ] **5. Clan activities.** Sharing tongues, sharing stories: ambient camp life + player-joinable activities.
      PREPARED 2026-10-27: no native activity system (no sharing-tongues / grooming classes). Bonds exist: UBondDialogue,
      UQuestDialogueActionResolveBondAnswer (the friendship system the bond level-up UI shows). Activities = new
      (animations + a bond gain through that dialogue action). Needs: which activities, with whom, their effect.
      PLAN 2026-10-27 (implementable; operator only tunes the list):
      - ANIMATIONS the game ships (cat montages): AM_Interact_Sleep_1/2/3, AM_CatMaster_SimpleSit,
        AM_Interact_Play / AM_Interact_Play_Toy, AM_Interact_Sniffing, AM_SC_Wrestle (+ A_CatMaster_SC_Wrestle),
        AM_Interact_Sharpen, AM_Interact_Dig. NO grooming / tongue-sharing animation - "sharing tongues" = SimpleSit
        + Sniffing side by side until an animation exists (or a WaCa look-at pose).
      - AMBIENT (no input): camp NPC cats (BP_Exploration_Character_Base_C with CharacterType Cat inside the camp area)
        pick an activity from config/activities.ini on a timer EVENT (one ExecuteInGameThreadWithDelay per cat, no
        tick): Character:PlayAnimMontage(montage) - pairs face each other first (K2_SetActorRotation).
      - JOINABLE: near a clanmate playing one (distance check on the key press only) the interact key joins: the
        player plays the same montage facing them; on its end -> bond gain through the game's bond system (the save's
        Bonding nodes / UQuestDialogueActionResolveBondAnswer - find its native add-bond the way AddExperience was
        found) and a small fresh effect (rested = stamina, play = EXP), all from activities.ini.
      - activities.ini: [Activity.<Name>] Montage = ..., Pair = 1, Where = Camp, Weight = ..., Bond = +n,
        Duration = s - the operator tweaks which / how often / rewards.
      - NOT YET VERIFIED: PlayAnimMontage on an NPC whose AI is running (it may be overridden by the behaviour tree's
        own montages - then pause its brain while it plays).
      BUILT 2026-10-27 - AMBIENT (experimental, activities.ini [Ambient] On = 0 by default): activities.lua - every
        Every s while the gameplay HUD is up, one clanmate (CharacterType Cat, within Radius, standing still, not busy
        with an earlier activity) plays a weighted [Activity.*] montage; Pair = 1 activities face two cats and play on
        both. VM: Sit / Sniff / Nap on a clanmate, one at a time (busy tracked by the montage's own length - NPC cats
        ALWAYS run a montage of their own, so IsAnyMontagePlaying can't be used). NOT VERIFIED: a pair (PlayFight) -
        only one idle clanmate near the VM cat. NEXT: joinable activities + bond gain (the plan above).
        PAIRS (VM 2026-10-27): 66 idle clanmates in the world, NO two within 500 units of each other - NPC cats stand
        spread out, so a pair activity never finds a partner in place. NEXT for pairs: the partner walks over first
        (an AI move to the first cat + its move-completed event, then both play) - activities.lua picks partners
        within 600 only, so PlayFight effectively never runs until then.
        BUILT (same day): the partner (nearest idle clanmate within PairRadius 2500 - the world's closest idle pair
        was 1701 apart) walks over with one AI move; ONE callback after distance / MaxWalkSpeed + 1 s checks the gap
        (<= 300 -> both face + play; else logged "didn't get to"). VM: the move started but covered 57 of 1701 units
        in 27 s wall time - UNRESOLVED whether the VM's 0.3 fps (game time far behind the wall-time delay) or the
        cat's behaviour tree overriding the move. To settle in real play (operator) or with game-time delays.
        SETTLED (same day): BOTH. (1) game time: at 0.3 fps 27 wall s = 5.6 game s - the check now follows GAME time
        (GetTimeSeconds; re-checks while the partner is still closing in, at most 4). (2) the behaviour tree: with
        the AI running the partner moved 12 units in 5 game s; its BrainComponent now StopLogic()s for the walk +
        the activity and RestartLogic()s after (or when it gives up). VM: the partner then walked 1788 -> 1269 units
        (about 47 units / game s, not the 300 MaxWalkSpeed) and stopped there - path blocked / nav. Open: the walk
        speed and where camp cats stand in real play (the VM cat isn't in a camp; the closest idle pair was 1600-1800
        apart) - tune PairRadius in play.
        Later (same day): BOTH cats now walk to the midpoint (AI paused on both). VM: 1701 -> 926 units, then stalled
        -> gave up cleanly ("didn't get to", AI restarted). That pair is likely not reachable on foot; a nav-path
        check (NavigationSystemV1.FindPathToLocationSynchronously) returns NOTHING from Lua - even for 300 units of
        open ground - so partners stay chosen by straight-line distance and an unreachable walk gives up. The world's
        idle clanmates near the VM cat stand 1700+ apart (6 pairs within 2500 of 66 idle) - a real camp is the test.
- [ ] **13. Less "jack of all trades".** Specialisation for your cat (strengths / weaknesses, roles).
      DRAFT DESIGN (2026-10-27, for the operator to adjust - built on what the code research found):
      - Specialisation = a role picked at warrior rank: Hunter (+15 hunt chance, -fight), Fighter (+combat damage,
        -hunt), Tracker (+fishing / scent, wider noise window for prey). Implemented as modifiers the existing
        systems read (hunting.ini factors, combat stats via the stats the save keeps). config: roles.ini.
      BUILT 2026-10-27 (off by default): config/roles.ini [Specialisation] Role / MinRank (Warrior) + [Role.*] Hunt /
        Fish / Noise multipliers; hunting.lua applies it once the saved rank reaches MinRank (ECharacterRank order):
        hunt chance x Hunt, fishing bite x Fish (RoleFactors event), the loud-ground noise window x Noise. Hunter 1.15
        hunt, Tracker 1.25 fish + 0.5 noise, Fighter 0.85 hunt. Open: Fighter's combat strength (hook the combat
        stats), choosing the role in game (a rank-up dialogue / menu), the noise window refreshes at the next ground
        change. Needs hunting.ini [Chance] On (the rank is read there).
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
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - More patterns / markings need new textures -> the mod pipeline (pak); colour wheel = the hex box (done).
- [x] **18. More graphics options.** DONE 2026-10-27: config/graphics.ini - [Scalability] the engine's groups (sg.*),
      [CVars] any console variable (motion blur, DoF, fringe, screen %, t.MaxFPS listed), applied through
      ExecuteConsoleCommand at start and after the game's options popup closes. VM: read back sg.ShadowQuality 0,
      r.MotionBlurQuality 0, r.ScreenPercentage 50 (the VM's own setting would give 25). An in-game menu for them =
      with the keybind menu (19a).

- [ ] **26. Prey scent / visual trails** (operator 2026-10-25: "sick for future work", like The Isle). Prey leaves
      trails - scent you detect (a sense / sniff mode) and visual signs (tracks, disturbed undergrowth) - that you can
      follow to the prey. Ties into 23 (random spawns: the trail is how you find them), 21 (rain washes scent out,
      snow keeps tracks) and 24 (StarClan guidance as an alternative lead).
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - A trail = a short line of the game's step Niagara (NS_Steps_* / scent sense effects) spawned behind moving
        prey every few metres, visible in sense mode (the game's ExplorationSenseComponent switches) - fades in N s.

## P3: Later / big content
- [ ] **27. Side threads** (operator 2026-10-25, future work). Quest chains spanning several days (25) that can be
      missed when not done by a given day, so the story isn't one fixed line.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Builds on 25: multi-day quest chains as day-script entries with their own state in the save sidecar.
- [ ] **Decouple cat stats from looks** (frequently requested by players; operator 2026-10-25). Today body type /
      traits drive both the visuals and the stats. Add a separate set of visual sliders / choices whose list carries no
      stat effect; the visuals read from it, the stats keep the original choice.
      DRAFT DESIGN (2026-10-27, for the operator to adjust - built on what the code research found):
      - Find where body type / size feed the stats (the save's Stats / Customization; the creator's choices) and
        override the stat base after creation from a separate pick (creator page or stats.ini), leaving the look.
- [ ] **Story.** Pour the existing thin story into the new systems, then expand it toward the books (needs 15 + 17).
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - After 15 + 25 exist: port the existing story beats into day scripts first (no new writing), then extend.
- [ ] **12. Romance + kits (far future).** The friendship system already exists. Add a mate, kits of your own, watching
      them grow up. Maybe in a free-play mode after the story concludes.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - The friendship (bond) system's top level unlocks "mate"; kits = new clan cats generated with the parents'
        looks (the look framework) after N days (seasons).
- [ ] **16. RiverClan cats swim.** Feasibility unknown (water volumes, animation set, nav).
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Check the water volumes (PhysicsVolume bWaterVolume) and whether the cat's movement component has a swim mode
        (CharacterMovement MOVE_Swimming) with any animation; if none exists, a "wade" (slowed walk + splash effect,
        NS_Steps_Water / DeepWater exist) is the cheap version.

## Archive
- [x] 2026-10-27 RELEASED 0.7.0 (operator go): hunting by chance, fishing, day / night, clan activities, dialogue
      click / space, left-click interact, placeholder fixes, the start-up crash fix.
- [x] 2026-10-27 CRASH FIX - the watch dispatcher (bridge.cpp OnProcessEvent): a start-up crash in main.dll+0xACDC
      (reading freed memory in the g_watches loop) - mods register / drop watches on UE4SS's mod thread while the game
      thread dispatches. Now the list is mutex-guarded (atomic count fast path), and events are delivered after the
      lock (handlers may add watches). Was likely behind some "random" crashes at start-up too.

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
