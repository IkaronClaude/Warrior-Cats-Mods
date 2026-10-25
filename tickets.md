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
- [x] 0.6.0 (2026-10-25, operator goal "port the mod to the proper event/hook based system"): no polling anywhere.
      Native event bus on UE4SS's ProcessEvent callbacks (WaCaNative = UE4SS C++ mod built against the SDK), Lua
      WaCa.On / WaCa.Watch / WaCa.Ready, built-in ScreenShown / ScreenHidden / ScreenFocusIn / ScreenFocusOut /
      CatSpawned / SteamTextInput / Started; both Lua loops removed; WaCaNative_Command replaces the string-table
      channel. Headless-proven (PROJECT_PLAN.md "Event-driven foundation"). Not released yet (see the two P1s below).
- [ ] P1 CI secret UE4SS_SOURCE_TOKEN (operator): a GitHub token of an Epic-linked account that can read
  Re-UE4SS/UEPseudo, as a repository secret - the release workflow now builds the DLL from UE4SS source and fails
  without it. Then tag v0.6.0.
- [ ] P1 verify 0.6.0 on a GPU (operator's PC): CatSpawned in real gameplay (name / look / roster on spawn), the
  menu cursor staying visible without the old per-tick re-assert, the name box flow with a real keyboard and the
  Steam keyboard, the creator panel re-attaching after menu commands.
- [x] 0.5.5 (2026-10-25, operator): name box top right, no auto focus, part of the flow (the game's confirm rows are
      held while the name screen shows: confirm on the list = into the box, confirm in the box = on, via
      OnListenCommand(Button_A); Tab / L3 leave); Steam on-screen keyboard on a controller (floating first, then the
      full-screen one via GamepadTextInputDismissed_t -> steamtext.result); the warrior ceremony popup
      (GuiPopupWarriorName) gets the same box for the suffix. The typed name was IGNORED: the creation fingerprint
      read an empty preview actor (several GuiCatCustomActor exist: creator, portrait, inventory) - now every
      non-empty one, and the pending name shows during creation (name screen CatRef). Headshots: preview actors whose
      fingerprint equals the player's cat get the look. Menu clicks: no viewport mouse capture in menus (capture mode
      0, set after the input mode, which resets it). UNTESTED on a GPU: the whole name flow, OnListenCommand going
      on, Steam keyboards (refused on the VM: Steam logged out), clicks on the game's buttons.
- [x] 0.5.4 fix, tag moved (2026-10-25): reloading a save never applied WaCa overrides - NO sidecar was ever written
      for the operator. Root cause: the game keeps ONE save (saveSlots = [its GUID]) with MaxSlots=3 characters;
      CurrentSaveSlotIndex is the CHARACTER, but WaCa.CurrentSlot indexed saveSlots with it (only character 0 had a
      slot - my VM always ran character 0), and creation waited for a new saveSlots GUID that never comes. Now: slot
      id = "<GUID>-<character>" (old "<GUID>" file read for character 0); a creation is settled by fingerprint - the
      first player cat whose appearance values equal the creator preview's gets the choices (written at once), any
      other cat drops them. Save-manager slot calls are logged. Untested in a real creation (needs the GPU PC).
- [ ] P1 Escape AND BackSpace as menu back, natively: menus map raw keys to ECommands through DT_GamepadButtonsKeyboard
  rows (one FKey per row; DT_Keys is only key icons; no Button_B action mapping exists). Find the native lookup with a
  hardware watchpoint on the Button_B row's Key (dev.cpp) and detour it so Escape also yields Button_B / Button_Back.
- [ ] P1 mouse look has a max turn speed + stick-like acceleration (operator): the camera clamps the axis to the stick
  range and runs it through the stick curve. Find the camera's axis consumer and feed mouse deltas unclamped.
- [ ] P1 Spacebar also advances dialogue (operator 2026-10-25).
- [ ] P1 relocation framework for detours (operator 2026-10-25): every hook target found by several independent
  means (signature + fallback anchors: a string / UFunction native pointer / call-site chain), validated (prologue /
  call layout checks), logged, and a tools/ check that runs every signature against a new exe before a release.
- [x] 0.5.4 (2026-10-25, operator; cursor fix: game-and-UI input mode + Default cursor, bShowMouseCursor alone showed nothing): the name box takes keyboard focus when the name screen opens (no mouse was
      visible to click it) and lost its blurry hint text; the mouse cursor shows in every menu (menus.lua: any shown
      screen that isn't GuiScreenGame / a Hud, or a popup on the game screen), hidden in gameplay; the installer asks
      keep / reset settings on an update (old ones to config-backup-<date>; -KeepConfig / -ResetConfig). The pause
      menu not closing on Escape was the operator's OLD keybinds.ini - re-test after a reset. Untested on a GPU: the
      cursor actually appearing, mouse clicks on the game's own buttons (P1 mouse ticket stays open).
- [ ] P0 creator redesign, refined (operator 2026-10-25, replaces the online/local mode toggle below):
  - Custom looks (patterns / markings / colours) are REGISTERED by mods - many mods at once without interfering
    (namespaced ids, no shared-slot collisions) - and each declares a BASE-GAME FALLBACK (the modder's closest vanilla
    pattern / marking / colour indices).
  - One checkbox in the creator: "Customise online cat". UNCHECKED (default): the online cat = each chosen custom
    look's fallback values, automatically. CHECKED: the online cat is customised separately with the native UI, and
    a preview switch shows either the local or the online cat.
  - The online customisation is remembered: check > customise > uncheck > re-check restores those online edits.
    Creating the cat with the box unchecked uses the fallbacks.
- [ ] P0 creator redesign (operator 2026-10-25): use the NATIVE customisation UI, not a side panel.
  - Hook the native pattern / marking scroll grid (with its preview) so mods add entries there; the game ships DLC
    patterns, so find how DLC rows join the grid (DT_Patterns / DLC data) and ride that.
  - A mode switch in the editor: "online cat" (vanilla data, what others see) vs "local cat" (WaCa look); extra grid
    entries / colours only in local mode; a "copy online look to local" button. Drop the per-row "pattern override" UI.
  - Apply our look in the same refresh as the game's (no flash of the vanilla pattern after a colour change): hook the
    material build, not a re-apply after it.
  - Custom colours have no UI: a colour wheel / hex entry in local mode.
- [x] (0.5.5) P1 cat headshots / portraits show the ONLINE look (operator 2026-10-25): the in-game places that render a
  "headshot" of the player's cat ignore the WaCa override - find the portrait capture actor / render target and give
  it the local look too (WaCa.PlayerCats only covers the pawn, cutscene cats and the creator preview).
- [ ] creator redesign finding (2026-10-25): DT_Patterns = 23 rows NewRow..NewRow_21 (PatternType 0-22), DT_Markings
  20 rows, on USwtAdventureGameInstance (PatternsDataTable / MarkingsDataTable / DeluxeDataTable). The native grid
  (mcGuiPatternPanel.mcGuiGrid, WBP_GuiCustomizationPatternItem_C items) is only filled in the real flow (0 items
  headless). UE4SS UDataTable:AddRow fails here ("ICppStructOps::Copy unavailable") - adding a row needs native code.
- [ ] P1 mouse in menus (operator 2026-10-25): the splash can't be skipped with a click; menus can't be used with the
  mouse. Found: controller bShowMouseCursor = false; screens navigate a USwtNavigation (CurrentControl) of GuiControls
  that each have a UMG mcGuiButtonCollision; USwtScreen has OnUIPress / OnUIRelease(Control). Next: cursor on in
  menus, hover -> selection, click -> confirm; splash: click = a key press.
- [x] 0.5.3 fix, tag moved (2026-10-25): the creator crash ROOT CAUSE - LoopAsync ran our Lua on a worker thread
      while game-thread hooks used the same Lua state (VM table corruption; reproduced headless with F6 x 75, gone
      after moving every loop to LoopInGameThreadWithDelay). Also: F6 never wrapped to "No override" (a nil value
      kept in the key order broke the look merge); the panel vanished for ~1 min after backing out and returning
      (FindFirstOf found the old hidden screen until GC); backing out (BackSpace / Escape) reverts that screen's WaCa
      choices; Colourpoint is a pattern shape (looks with Row = Pattern), tail / ears = the pattern colour.
- [ ] 0.5.3 fix, tag moved (2026-10-25, operator: a crash in the creator after a long time cycling custom patterns; the custom
      patterns did not render on the cat). Crash: inside UE4SS during a hook (PCallStack all UE4SS -> game 0x4A1BDD2),
      read of 0xFFFFFFFFFFFFFFFF = a stale object. Fixed the likely cause: the creator held widget wrappers (name box,
      panel buttons / values) and texture objects across ticks and identified screens by ADDRESS (a rebuilt screen
      can reuse it) - now screens by full name, widgets / textures found again by name every time. Patterns not
      rendering: the re-apply check only compared one colour, so when the game loaded its own pattern texture after a
      refresh we never put ours back - the check now covers every colour and every mask. OPEN: the operator's
      re-test; the UE4SS.log of a crash if it happens again (it is overwritten by the next launch).
- [x] 0.5.3 (2026-10-25, operator): the creator preview actor (GuiCatCustomActor) is reused by "Select Your Cat"
      (Dapplepatch got the player's look) - the preview counts as the player's cat only while a creator screen is
      open, and gets the game's look back (RefreshPattern) when the creator closes. Menus: Escape AND BackSpace go
      back everywhere ([KeyAliases] Escape = BackSpace, [UIIcons] Esc icon; [UIKeys] empty by default), the installer
      migrates the old default keybinds.ini.
- [ ] **Per-save sidecar (goal 2026-10-25).** DONE (data layer): SaveGames/WrcGame.<slot>.WaCaModKit.ini ([Name]
      Prefix / Suffix, [Appearance] = appearance.ini keys) loads when the active slot (SwtSaveManager.SaveGame
      .saveSlots[CurrentSaveSlotIndex], a GUID) changes and wins over the global inis; in-game changes are written on
      the game's own Save (hook). Verified headless: slot detection + sidecar load. OPEN: the write path end to end
      (needs the UI to change a value, then a game save).
- [ ] **Creator UI injection (goal 2026-10-25).** The creator: UGuiCustomizationColorPanel (UGuiOptionColorListControl
      buttons for fur / pattern / markings / iris L / R -> UGuiColorPickerGrid of UGuiColorPickerSlotGrid swatches),
      UGuiCustomizationPatternPanel / MarkingsPanel (UGuiCustomizationGrid / UGuiMarkingsGrid of grid items),
      AGuiCatCustomActor = the preview. Plan: extra swatches / entries in those grids (CreateWidget of the grid's
      GridItemClass, added to Items + the canvas + GridNavigation), a choice -> the slot's [Appearance] + a vanilla
      fallback index in the game's data. Needs live observation of the creator (open it headless via Lua).
      0.5.0 (2026-10-25): DONE, verified headless as far as possible (creator.lua):
      - palettes extended from config/palette.ini (FurColors / PatternMaskColors / MarkingMaskColors 25 + ours);
        a custom index on any player cat -> its exact colour into the look + the nearest game index (verified: idx 30
        -> #A8989F recorded, idx 11 kept); pairing VERIFIED in the game code (0x1417B2155: Pattern01ColorIdx -> PatternMaskColors, Pattern02ColorIdx -> MarkingMaskColors; index bounds-checked against the current palette length)
      - name screen: EditableTextBox "your name" + the game's list noted as the online name (verified on the real
        WBP_GuiScreenSelectName shown headless; typed text captured)
      - WaCa panel on the customisation screen (look / pattern shape / markings shape; arrows via LMB + IsHovered, F5-F7)
        (verified hosted on the name screen - the customisation screen can't be built outside the creator; its root
        is a CanvasPanel like the name screen's)
      - pending creation -> the NEW save slot's sidecar (verified: K2_CreateSaveSlot + Save -> sidecar with Prefix +
        Fur); an existing save loaded instead drops it
      0.5.1: save -> fresh restart round trip verified headless (run 1: creation + K2_CreateSaveSlot + Save writes
      the sidecar; run 2: the slot's sidecar loads and the look is applied to the player cats); name-box re-store spam
      after the commit fixed.
      0.5.2: the module's own panel ATTACHED TO THE REAL CUSTOMISATION SCREEN headless (WBP_GuiScreenCustomization
      created, not shown - showing it outside the creator flow crashes - with creator.ini AttachHidden = 1): all 7
      panel widgets in its CanvasRoot, F7 / F5 change the choices and the panel's value text. The real screen has the
      colour panel + its fur option. Palette sizes: of the 33 game functions that touch all four palettes, none uses a
      fixed 25 - the code works from the arrays' length (the colour apply code bounds-checks against it).
      OPEN (needs a GPU - the VM has none; headless stops at the splash, which reads real input): the operator's
      real-creator test - position / font of the name box and the WaCa panel, clicking the panel arrows, the panel on
      the real customisation screen.
      Headless navigation is blocked at the splash ("press any key" needs real input).
- [ ] **Escape as "back" in menus** (operator test: menus use BackSpace, the pause menu shows a BackSpace close
      button). Source: UXD/Buttons/DT_GamepadButtonsKeyboard rows Button_B / Button_Back = BackSpace (key + hint
      icon). Fix at the data: those rows -> Escape (+ the Esc icon). 0.3.1: DONE - [UIKeys] rewrites the rows natively
      (ui.cpp, UDataTable::RowMap in place, verified headless). OPEN: the operator's test (does the pause menu close
      cleanly on Escape, with Escape also bound to Player_Pause?).
- [ ] **ModKit 0.1 release (2026-10-24).** Built and committed: `dist/WaCaModKit-0.1.0.zip` (`tools/package.ps1`).
      - [x] Native key rebinding: a detour of the game's default-binding apply step (WaCaNative) + `keybinds.ini`
            (Pause = Escape). Verified headless: the signatures are found, the defaults are logged (the whole keyboard
            table), the overrides are applied on every rebuild.
      - [x] Installer: Install.bat finds the game via Steam, keeps the user's keybinds on update; Uninstall.bat.
            Tested on the Z: copy.
      - [ ] **Operator test on a real PC:** Escape pauses, P no longer does; the install works through the real Steam
            launch (SteamStub exe + dwmapi proxy).
      - [ ] **GitHub repo + first release** (needs the operator: there's no `gh` here; the repo name / owner is theirs
            to pick).

## P0: Foundation (nothing else can start until this works)
- [ ] **Engine version + toolchain.** Pin the exact UE5 version. It is not in the exe strings: the exe is SteamStub-
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
- [ ] **UE4SS injection.** Get UE4SS running: check SteamStub / EOS / any anti-cheat; the game uses the EOS SDK for its
      online content. Live object dump + C++ header dump for a skeleton project. Lua hello-world hook on a gameplay
      function.
- [ ] **Mod pipeline.** A skeleton UE project in the matching engine version (dummy classes from the header dump). Cook a
      test Blueprint mod and load it from a `~mods` pak (IoStore: retoc / ZenTools for repacking). Prove ONE change
      end to end, e.g. a string edit.
- [ ] **Deploy rule.** Installing a mod writes into the game folder on Z:. Agree with the operator where mods are
      installed and how to uninstall cleanly; never rm -rf on Z:. Back up any file before overwriting it.

## P1: MVP mechanics
- [ ] **Procedural names: no doubled prefix / suffix** (operator 2026-10-25: "Blazeblaze"). The NPC name generator
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
- [ ] **19b. PC controls: mouse.** Replace the tank-style arrow-key controls with mouse camera / movement.
- [ ] **3. Free-form name input.** The player types any name. Keep an auto-generated fallback name for online content
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
- [ ] **4. Day / night cycle.** Duties at specific times of day (dawn patrol, night watch).
- [ ] **9. Hunting rework.** On detection, small prey FLEES instead of charging you; you can still catch it if you're
      fast enough. No more prey combat.
- [ ] **8. Real hunting missions.** Hunting patrols with goals: fresh-kill pile needs, territory, seasons.
- [ ] **7. Real patrols.** Cats join you just for the patrol (temporary party), with border marking and events.
- [ ] **6. Combat training with your mentor.** Actual training sessions, not narrated.
- [ ] **14. Pacing.** Progression must come from time + duties + training, not "3 hunts until deputy". No old deputy
      getting canned for "not doing enough" at your own ceremony. Ceremonies need proper preconditions.

- [ ] **Dialogue text bugs (operator, 2026-10-24).** Some lines show unfilled format arguments, e.g. "It seems that 1's
      Prophecy is true": a name placeholder left as an argument index or default. Find the dialogue tables
      (`Quests/NpcDialogues`, `Quests/StoryDialogues`, `Sequencer/DT_QuestSequenceDialogues`) and the FText format
      call that fills them. List every line whose placeholders the game doesn't fill, then fix it: either supply the
      argument at the format call (hook) or patch the text.

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

## P3: Later / big content
- [ ] **Decouple cat stats from looks** (frequently requested by players; operator 2026-10-25). Today body type /
      traits drive both the visuals and the stats. Add a separate set of visual sliders / choices whose list carries no
      stat effect; the visuals read from it, the stats keep the original choice.
- [ ] **Story.** Pour the existing thin story into the new systems, then expand it toward the books (needs 15 + 17).
- [ ] **12. Romance + kits (far future).** The friendship system already exists. Add a mate, kits of your own, watching
      them grow up. Maybe in a free-play mode after the story concludes.
- [ ] **16. RiverClan cats swim.** Feasibility unknown (water volumes, animation set, nav).

## Archive
- (none yet)
