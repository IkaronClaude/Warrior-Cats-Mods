# tickets.md: the kanban board

Read the whole board (Goal, Doing, P0, P1, P2, P3) every session. When an item starts, move it to **Doing**. When it is
done, tick it and move it to **Archive**, dated and newest first.
"PX:" from the operator means: add a ticket at priority X. It does not mean "do it now".

**Key philosophy (operator, 2026-10-24):** the MVP and the MECHANICS come FIRST. Story is a huge undertaking. The current
story is thin ("go hunt", "go patrol", "go to your den", then sometimes some dialogue). It will fit neatly into the new
systems once they exist. So build the systems, then pour story into them.

## Goal
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
- [ ] **19a. PC controls: bindings.** Pause on Esc: DONE in 0.1 (awaiting the operator's test). Still open: hint
      that quests are on K (UI), an in-game rebinding UI (the game's own GuiCustomConfigKey screen should read / write
      our bindings), mouse bindings for the camera.
- [ ] **19b. PC controls: mouse.** Replace the tank-style arrow-key controls with mouse camera / movement.
- [ ] **3. Free-form name input.** The player types any name. Keep an auto-generated fallback name for online content
      (minor relevance); find what the online side reads.
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
- [ ] **18. More graphics options.** The current ones are very lackluster; expose the engine's scalability groups +
      extras.

## P3: Later / big content
- [ ] **Story.** Pour the existing thin story into the new systems, then expand it toward the books (needs 15 + 17).
- [ ] **12. Romance + kits (far future).** The friendship system already exists. Add a mate, kits of your own, watching
      them grow up. Maybe in a free-play mode after the story concludes.
- [ ] **16. RiverClan cats swim.** Feasibility unknown (water volumes, animation set, nav).

## Archive
- (none yet)
