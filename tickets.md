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

## Release readiness 2026-11-04 (operator: "take stock of all the repos for each mod and get them 100% release ready")
Done in the repos (each committed locally; zips rebuilt with tools/package.ps1 and checked file by file against git):
- WaCa Core 1.0.0, Keybinds & Mouse 1.0.0, Looks 1.0.0, Graphics 1.0.0, Clan Life 0.8.0, Hunting 0.8.0, Cutscenes 0.1.0:
  versions agree (main.lua VERSION = NEXUS.md = zip name), clean trees, no debug switches on in the shipped configs.
- NEW release check `WaCa-Core/tools/check_lua.py Mods examples` (lupa + luaparser): every file compiles on Lua 5.5
  and no accidental globals. It found 3 REAL BUGS (a local called above its definition = a nil global at run time):
  Clan Life's Gather step (keepGathered - the fade never lifted, the step never ended), walkers' draw (a cat shown for
  a turn stayed drawn), Hunting's loadSaveRole (askRoleSoon - nobody was asked their role on a load); plus Clan Life's
  `staging` set as a global (the walkers never waited for a Gather) and 8 loop-variable assignments (read-only in 5.5).
  VM: a Gather scene ran through Release to its last card, the gathered-cats file written + cleared; Hunting / Looks /
  duty chances reloaded and read fine.
- A missing or too-old WaCa Core now says so: every mod `pcall(require, "WaCa")` (without Core the library is missing
  too - the "not installed" line could never show) and `WaCa.Needs("1.0.0", mod)`; Core has WaCa.VERSION /
  WaCa.AtLeast / WaCa.Needs (docs/API.md, HelloWaCa) and warns about a mixed install.
- The zips now carry docs/, examples/ and CONTRIBUTING.md beside README.md (the READMEs' links - docs/WRITING.md,
  docs/API.md, the example pack - pointed at files only the repo had).
- WaCa Cutscenes added to Core's mod table / Nexus list and to Clan Life's Nexus requirements (optional).
- VM 2026-11-04 19:56: seven hot reloads in a row (one per mod) hung the game (Not Responding, CPU flat) - the known
  UE4SS reload deadlock below (P3 "WaCa Core hot-reloaded TWICE"; fixed only in the test UE4SS build), not a release
  path (EnableAutoReloadingLuaMods is a test setting). Logs: Z:/WaCa/hangs-20261104-reload/.
Left for the operator (nothing else stands between the zips and a release):
- create the GitHub repos (IkaronClaude/WaCa-*: none exist yet) and push; then the README / NEXUS links resolve;
- the Nexus pages (login) and their links (the NEXUS.md TODOs);
- the UE4SS question: ship with the reload / freed-object patches 0001-0004 (our own UE4SS build) or the Nexus UE4SS;
  and confirm Core's DLL with the Nexus UE4SS download (Core NEXUS.md "Known issues");
- whether the writer tools (tools/new_pack.ps1, check_pack.py, the pack editor) ship in Clan Life's zip - WRITING.md
  names them; today they are repo-only;
- the default switches (Clan Life and Hunting ship mostly off - see the board below).

## Board status 2026-11-04 (EVERY open item, checked against its own text - all wait on the operator)
- Operator play-test 2026-10-30: fixed on the VM; the operator's retest of the drop.
- P1 leading = MANAGING the clan: first cut built; the full UI waits on the operator's rules (stats, outcomes, picker).
- Operator checks: the operator's list by definition.
- Mod pipeline: needs the Unreal editor installed (operator).
- THE CLAN LOOP: built + VM-verified; the operator's checks: a real conversation turn-in, a real pile deposit.
- Procedural names: done; the operator's in-game check.
- 19a PC controls: bindings: in-game rebinding built + VM-verified; the operator's feel check (the K hint: the pause page shows QUEST K).
- 19b PC controls: mouse: built + VM-verified; the operator's feel check.
- 3 Free-form name input: built + VM-verified (Select Your Cat too); the operator's real-game test.
- 1 Canon clan roster: built, off until the operator checks the names and picks the moment.
- 15 Clan-sim day: built; rank-ups by standing wait on pacing targets (14, operator).
- 4 Day / night cycle: built + VM-verified; the day length / feel is the operator's call.
- 25 Story as days: built (Day verified 2026-11-01; SetPackDay 2026-11-03); the real days = operator content.
- 9b Fishing: built + VM-verified, off; turning it on = operator.
- 9 Hunting rework: built (experimental, off; + the wind 2026-11-02, off); which creatures charge / on by default = operator decisions.
- 8 Real hunting missions: built; hunting-ground card + map mark VERIFIED 2026-11-01 (VM); hunting patrols on by default? (operator).
- 7 Real patrols: built + VM-verified; border-point events = operator content.
- 6 Combat training: built; a WON fight in play (operator - the VM can't win one).
- 14 Pacing: the target pace per rank (operator).
- 20 Intentional time skips: built + VM-verified with the operator's rules 2026-11-03 ([Skip.<Name>] Days / Pile / Card, the day's hunt / patrol set aside, a warning for duties on a skip); real skips in the story = operator content.
- 21 Seasons and weather: built + VM-verified; the look / sound on the operator's PC, the release pak (operator).
- 22 Prey follows the world: built + VM-verified; world events (poisoned river) = operator design.
- 23 Random prey spawns: built + VM-verified; a moved prey's pounce in play (operator - the VM's pounce fails on any prey).
- 24 StarClan guidance leads to prey: built + VERIFIED, off; turning it on = operator.
- Dialogue text bugs: fixed (sweeps both clans); lines the operator meets in play.
- Gatherings: groundwork + travel + other Clans (10-31) + the 12-cat party (11-01) built + VM-verified - the item's older
  'OPEN: other Clans' cats / 10+ cats travelling' lines are superseded by those; the story beats = operator.
- Mod stories (story packs): the operator's answers built 2026-11-03 - the quest-tab line with its detail (WaCa.QuestLine) and the Warn sync against the game's rank-ups; both halves seen via the game's own functions (StartQuestOfTag / OnPlayRankUpSequenceFinished); a real play-through promotion = operator, a save with side quests of its own, replaying skipped variables (operator).
- Story packs: starts + authoring: built + VM-verified (Day, Level, Name, Party, Watch; 2026-11-02 exercises: S-role murmurs, HerbCouncil cutscene + Lead event, story dialogue + its checks, renamed-cat nameplates, undrawn cast cats); start rank = operator decision; an editor = future.
- P1 Party members follow you: built + VM-verified; camera framing on the operator's camera; PartySetup by a later chapter needs such a save.
- Roles and the cast: S roles built + exercised; S roles in every line ({S:loner}, Say: S:loner) DONE 2026-11-04 (VM);
  new GAME-side roles, and whether a brought-in role cat bonds / joins a party = the operator's go.
- Fresh kill without hunger: deposit VM-verified; talking to the pile's cat in play (the VM can't talk to NPCs - re-tried
  2026-11-03: the cat placed 1.45 m in front of Freezesong + the game's interact command (65) on the HUD screen opened no
  conversation; the game's talk comes from the player's input / the prompt's own target) = operator.
- Cutscenes from text: built + VM-verified (incl. Wait, cast to other mods, [Rogue.<Name>] looks; 2026-11-02: load-time check, orbit fix, Letterbox / Focus options off); the look (and whether to turn Letterbox / Focus on) = operator.
- Nexus Mods: the operator's login (upload, Nexus-UE4SS DLL test, MothColorPicker).
- 17 + 10 Show, don't tell: framework built; which scenes = operator content.
- 11 Clan cat interactivity: built (off); lines / turning it on = operator.
- 5 Clan activities: built + bond gain VM-verified (off); turning it on = operator.
- 13 Less jack of all trades: built + VERIFIED (combat scaling); the operator's real fight with a role.
- 2 More customisation: built; the Colourpoint look (operator) + a colour wheel UI (needs the editor).
- 26 Prey scent trails: built (off); turning it on = operator.
- 27 Side threads: built + VM-verified (example thread); the real threads = operator content.
- Decouple cat stats from looks: built; the body shape in play + a real player size (scales collision) = operator.
- Story: operator content.
- 12 Romance + kits: a configurable draft built, off; the rules = operator.
- Frozen water in leaf-bare: RE-VERIFIED 2026-11-04 (VM, this save in leaf-bare): 'ice: 32 water surface(s) frozen (1 lake,
  31 river)' at load; your cat on a frozen stretch (Z 780 over ice 751) and the party cats followed onto it (Z 762 / 792,
  1.1 m away) - NPC cats on the ice confirmed today; IceRescue played from FellThroughIce in the full sweep. Was: ice, thin ice, rescue scene, NPCs on ice (10-31) built + VM-verified - the older 'Still open:
  NPC cats on the ice' line is superseded; the look = operator.
Closed in this pass: Time follows effort (built as part of 15), Murmurings (built + VM-verified), NPC patrols.
- P3 Core hot-reload hang: ROOT-CAUSED + FIXED in a UE4SS test build (lock lifetime, lock release, reload on the game thread) - VM: 6 Core reloads with the pause up, no hang / crash. Shipping it / test-only / upstream = operator.
- (archived) P2 a Lua call on a freed object: FIXED 2026-11-04 - the camera's 30-s plant list (camera.lua:132, pinned by the guard's
  traceback 44/44); the full sweep on the ORIGINAL UE4SS ran clean. (Was: RECURRED 11-03 23:24 - same fault, symbolised (a UFunction
  call on a freed object); a UE4SS guard built + VM-tested 2026-11-04 (patch 0004 - a stale call becomes a Lua error).
  Shipping it = the operator's UE4SS decision (with the reload patches); the exact caller needs a recurrence (the VM
  runs the original UE4SS so one is still caught). WaCa.Live now rejects destroyed (Garbage, bit 21) objects (VM).
- P3 default pad buttons for the mod keys: the plumbing works (KeyDown pad keys, [ModKeys] lists); which buttons = operator.
FULL SWEEP RUN 2026-11-04 06:21-07:40 (VM, original UE4SS, one script): all 14 example cutscenes - HerbLesson,
HerbalistsHonour (the game's ceremony, skipped by the NEW Scenes.Skip), GatheringNight (another zone), IceRescue,
RogueRaid, LonerVisit (its Ask answered), FightBeside, HerbCouncil, Envoy, Vigil, Scolding, NewApprentice, ElderTale,
FrostAtBorder - each to its end, no crash. Found + fixed by the sweep: the P2 crash (camera plant list), the skip that
left the game's scenes out (one stuck scene blocked every later one).
SWEEP PART 3 2026-11-04 07:10-07:40 (same boot, one script - the library beyond cutscenes):
  cast: S:apprentice = Blazeheart, S:herbalist = Mossfeather, S:storyteller = Nightheart (custom roles on save cats)
  custom cats: [Cat.Troutwing] pinned as Mossfeather, [Narrative.TheMistrustfulLeader] Lionstar pinned (roster)
  story check: 0 problems, 1 warning (the example's days while story days are off - correct)
  custom role: SetSpecialisation Scout -> 'hunting x1.05, damage taken x0.85 (15% better)'; Hunter restored (save kept)
  clan events: FellThroughIce -> IceRescue played + its card; FightBeside -> played; MentorTour -> card + Otterfeather
  leads - RUN TO ITS END 08:00-08:55: she came to your cat, led it to the den, 'waits for you' / 'goes on' as
  your cat fell behind / caught up, 'led your cat to Den:Apprentice's den' + the closing card (your cat kept at her side
  by a probe - the VM's walking input stalled on an obstacle); Reach:ReedBank -> 'you reached
  ReedBank (7 m) - not now: a cutscene plays' (the hold-back is right).
  Gatherings: GatheringNight cast the other Clans' cats (Sunstar = Clan:ThunderClan.Leader, Freezeface =
  Clan:ShadowClan) and played - the item's 'other Clans' cats' VERIFIED today, not just relabelled. Frozen water:
  IceRescue played from its FellThroughIce event; the reboot after (a test teleport sank the cat) loaded the save fine.
EXERCISE 2026-11-04 08:58 - The Border Watch (example pack: S:watcher = Palepool, met by Reach: S:watcher, card + cutscene
by role, Walk Away under a Behind camera): clean except one rough edge - a cutscene line naming a cat the scene didn't
cast ('I'll tell {Leader}') showed as typed. FIXED (Cast.NameFor; unknown keys logged once) - VM: 'I'll tell Lionstar'.
EXERCISE 2026-11-04 09:40 - a story gives a duty (HerbErrand -> HerbRound): found + fixed a REAL BUG - a duty's 'Pile'
point (and Reach: Pile) sat at the world's origin (the pile component's owner is the game state), unreachable; now the
camp's pile cat. Added the Duty: <name> step; duty points / cards name cats by role. VM: the round done end to end.
EXERCISE 2026-11-04 10:00 - Reach: on a brought-in role (S:loner = Rogue:Quill): looked up every step and misreported;
now said plainly once + skipped, and the story check flags Reach: mistakes before play (no cast / brought-in / bad x y z).
EXERCISE 2026-11-04 10:30 - every camera shot (example CameraTour): all eight frame; mistakes (no cat for Portrait,
one for Over) now caught by the cutscene check with the fix, and play-time says the real cause.
WHOLE-LIBRARY SWEEP 2026-11-04 10:50-11:55 (ONE script, one session - tools: scratchpad sweepall.sh):
  CUTSCENE HerbLesson: rbLesson: over (its End beat, 14.0 s) - 1 cat(s) back in their places
  CUTSCENE HerbalistsHonour: rbalistsHonour: the game didn't end its scene on the skip - ended here
  CUTSCENE GatheringNight: theringNight: over (its End beat, 18.0 s) - 6 cat(s) back in their places
  CUTSCENE IceRescue: eRescue: over (its End beat, 15.2 s) - 1 cat(s) back in their places
  CUTSCENE RogueRaid: gueRaid: over (its End beat, 21.2 s) - 4 cat(s) back in their places
  CUTSCENE LonerVisit: nerVisit: over (its End beat, 27.2 s) - 2 cat(s) back in their places
  CUTSCENE FightBeside: ghtBeside: over (its End beat, 22.0 s) - 1 cat(s) back in their places
  CUTSCENE HerbCouncil: rbCouncil: over (its End beat, 26.0 s) - 4 cat(s) back in their places
  CUTSCENE Envoy: voy: over (its End beat, 16.0 s) - 2 cat(s) back in their places
  CUTSCENE Vigil: gil: over (its End beat, 15.2 s) - 3 cat(s) back in their places
  CUTSCENE Scolding: olding: over (its End beat, 19.2 s) - 2 cat(s) back in their places
  CUTSCENE NewApprentice: wApprentice: over (its End beat, 14.0 s) - 1 cat(s) back in their places
  CUTSCENE ElderTale: derTale: over (its End beat, 17.2 s) - 2 cat(s) back in their places
  CUTSCENE FrostAtBorder: ostAtBorder: over (its End beat, 13.2 s) - 1 cat(s) back in their places
  CUTSCENE WatchReport: tchReport: over (its End beat, 16.0 s) - 1 cat(s) back in their places  ! tchReport: a line names {Leader} - no such cat about; 
  CUTSCENE CameraTour: meraTour: over (its End beat, 27.2 s) - 1 cat(s) back in their places
  CAST: le S:apprentice = Blazeheart;le S:herbalist = Mossfeather;le S:storyteller = Nightheart;
  ROSTER:  Narrative.TheMistrustfulLeader (Lionstar) pinned; Cat.Troutwing (Troutwing) pinned as Mossfeather;
  STORY CHECK: e: WaCa story check: 1 problem(s) in the story files - see Saved/WaCaStoryCheck.txt
  ROLE Scout: at is a Scout now - hunting x1.05 (5% better), fishing x1.00 (as before), damage dealt x0.95 (5% worse), damage taken x0.85 (15% better
  EVENT FellThroughIce: ies: FellThroughIce - the event IceRescue;eRescue: over (its End beat, 15.2 s) - 1 cat(s) back in their places;
  EVENT FightBeside: ies: FightBeside - the event FightBeside;ghtBeside: over (its End beat, 22.0 s) - 1 cat(s) back in their places;
  EVENT MentorTour (Lead): nts: Otterfeather led your cat to Den:Apprentice's den;d: Here it is. Get some rest - training starts at dawn.;
  DUTY by story (HerbErrand -> HerbRound): ies: a story gives the task HerbRound now;
  EVENT Reach:S:watcher: ies: you reached S:watcher (3 m) - event WatchReport;tchReport: over (its End beat, 16.0 s) - 1 cat(s) back in their places;
  GUARD/CRASH: UECC-Windows-039A890047EC77D854256FA40D868718_0000 (newest crash report); game running: 1
  SWEEPALL DONE
  -> found + fixed after it: {Leader} named only while in view (Cast.NameFor + undrawn story cats); a duty's cat point
     fixed where the cat stood (now follows her). The duty line's empty points = my own leftover follow probe steering
     the cat away (probes now have a stop switch); the duty itself re-verified 09:40 + the moving-cat point 12:40.
LIBRARY SWEEP - END STATE 2026-11-04 (each exercise = example-pack content written as a modder would, played on the VM,
every rough edge it showed fixed + re-played):
  custom ROLE      [Role.Scout] (Hunting roles)                    - key / factor checks, factors in words      DONE
  custom ROLE      S:herbalist / S:storyteller / S:loner / S:envoy - cast, murmurs, scenes, lines name them      DONE
  custom CAT       [Rogue.Frost], [Cat.<name>] roster, Quill       - look checks, own names, cast names in logs  DONE
  custom CUTSCENE  FrostAtBorder (walk in, threat, Sound, walk Away + Camera Behind), LonerVisit (Ask), ElderTale,
                   NewApprentice, HerbCouncil, RogueRaid                                                        DONE
  custom EVENTS    clan events by time, Event:, Reach:<place>, Reach:<cat>; cards naming roles                  DONE
  story days       days.ini / story.ini checks, SetPackDay, QuestLine, Warn sync                                DONE
  input            pad keys via the game's commands, [ModKeys] lists                                            DONE
No rough edge from these exercises is left open. What remains is play-feel / content / design = operator (above).
Exercise 2026-11-03 evening: ElderTale - pack role on a save's clanmate + newcomer by role + player in one cutscene,
the storyteller's question on the answer menu - clean (VM).
Pre-work 2026-11-03 night (cutscene library): Sound: beat (the game's cues), Beat2a keys, unknown keys reported, lines
naming an uncast cat left out; FIXED a real bug it surfaced - a cutscene removed a newcomer cast by role at its end
(WaCa.Cats 'spawned' vs Cutscenes' 'spawned' - now 'placed'). VM-verified.
  + Camera: Behind = <who> - a following shot behind a walking cat (VM: holds ~2.6 m behind, swings round on a turn).
  + custom cat exercise ([Rogue.Frost] + FrostAtBorder): misspelled look fields now named + left out; rogues no longer
    carry the source cat's name (a rogue From = Nightheart answered to 'Nightheart'). VM-verified.
  + custom role exercise ([Role.Scout]): unknown role keys / non-number factors named; the role line says each factor in
    words (Guard = damage taken, lower is better - the example itself got it backwards first). VM-verified.
  + roster exercise (WaCa Looks): unknown keys, bad colours and impossible [Cat.<name>] names (by the game's own name
    parts) are named with a 'did you mean'. VM-verified.
  + story days (Clan Life story check): misspelled day keys in days.ini / a pack's story.ini are problems with a 'did you
    mean'. VM-verified (no false positives on the real files).
  + [Cast] names: a misspelled cat name gets 'did you mean <the save's nearest cat>'. VM-verified.
  + scene polish: a cutscene's sounds fade out with it; clan events at a PLACE (When = Reach:<place> + Radius) - VM:
    reaching ReedBank played FrostAtBorder, once a day.
Exercise 2026-11-03 afternoon: NewApprentice cutscene - a newcomer cast by role (S:apprentice), its own Ask - clean.
Sweep 2026-11-03 evening (gamepad): KeyDown is keyboard / mouse only, so every Gamepad_ key name in the mods was dead -
fixed via the game's own input: Choice by screen commands (Button_Up/Down/A), the name box by OnKeyPressed (Core: watch
parameters can be several, FKey = its name). VM-tested with the inputs a pad produces; a physical pad = operator.
Boot helper: its 'nudge' reloads of the harness removed (one hung a boot).
  + Core raises the screens' Gamepad_ keys as KeyDown / KeyUp (once per press); [ModKeys] bindings may list several
  keys (WaCa.KeyIs) - VM: pad B skipped a cutscene via 'SpaceBar, Gamepad_FaceButton_Right', pad A entered the name box.
Closed 2026-11-03: P2 Choice look (the game's answer menu; Ask with a cast-slot speaker). Library exercises 2026-11-03: Ask
filled names + A1 speakers, Newcomer as S:<role>, SetPackDay.

## Doing
- [x] **P2 CUTSCENE SHOTS IN CRAMPED PLACES** (library exercise 2026-11-05, QueenThanks at the example pack's ReedBank -
      rocks on one side, a tree's crown over it): the cast and marks work (B1 = Tigerclaw, this save's RiverClanQueen), the
      SHOTS don't - Two found no spot that frames both cats: '100% clear' to the midpoint with a rock hiding the queen
      (fixed: seesAll - each framed cat must be visible too), then 3 m up in the canopy (55%), and a closer try (reverted)
      left both cats out of frame. Portrait took a 15%-clear spot 1.7 m off. Next: tell the writer at load / in the story
      check when a place has no clear Two / Wide spot (a fit test over the candidates), and look at the foliage check -
      it scored every spot low before (the moss spheres). Screens: ScreenShot01439-01442.
      DONE: a writer's note in the log when no spot frames a shot (best < 60%); the example's QueenThanks moved to the
      camp's pile - VM: an open view; the wide Two shot was the queen still WALKING IN (8-9 m apart) - the shot backs off
      to hold both, correctly. Authoring fix: Wide during the walk-in, Wait: B1, then Two (README tip) - VM: both cats
      framed by the pile, 4.4 m out at a 3.4 m gap. AND the place check before play (WaCa Cutscenes): VM flagged the
      example's Vigil at ReedBank (55%) - left there as the warning's example; moving it is the writer's call. DONE.
- [x] **WRITTEN 2026-11-04, VM TEST PENDING (the VM runner was stopped for low memory; not committed until tested):**
      Core: WaCa.Spawn, WaCa.InteractSpot (the game's Interact prompt anywhere; a reload's leftover spot removed),
      WaCa.Say / SayOrShow (a line on the cat's own nameplate row, else the screen line). Clan Life: Bedding = Interact
      in the den (Eat pose) + Interact out of camp (Dig pose), done ~2 s after each; kits / newcomers talkable
      ([Talk.Kit] / [Talk.Newcomer] in lines.ini); the cat to report to marked on the map ("Report to X", followed
      every 3 s); HUD "Back to camp:" instead of "... done - turn it in:"; talking = reporting also on 1.1's
      WBP_QuestGiver_Dialogue2 (no NpcRef: the nearest story cat within ReportRadius, logged which); murmurs at most
      one per [Murmurs] Every = 30 s (six in four seconds walking into camp, operator's log); flavour lines over the
      speaker (WaCa.Say); map marks drawn UNDER the game's icons. Keybinds: map names refreshed every 150 ms while the
      map is up (panning), the gamepad's screen-middle cursor when the mouse is still, "Pulse1" named by the nearest
      WaCa mark. Hunting: the wind announced once the HUD is up; Cutscenes: lines without the HUD dropped.
- [ ] **P0 THE GAME'S PATCH 1.1 (Steam, exe of 2026-11-02 - Z:/WaCa/game-20261102/, Steamless-unpacked there)** added
      mouse + keyboard arrow support, X / Y sensitivity sliders, left click for menus and interact, right click crouch,
      pause / exit moved from P to Esc (operator 2026-11-04). WaCa Keybinds & Mouse now DOUBLES much of it - likely the
      cause of the pause menu's double-click buttons, tabs that don't switch, hover that doesn't work, Space not
      accepting. Decide per feature what the game does now and CUT ours where it does (operator: "we will need to cut
      features likely"); keep only what 1.1 still lacks. The VM still runs the 2026-10-24 build - it needs 1.1.
      AND PATCH 1.2 (operator): a setting to turn off the follow camera (on by default for mouse controls); the MAP -
      mouse wheel zooms, WASD or the mouse moves it. (Our map hover / panning work overlaps that too.)
  - [x] Mouse look: the camera hook's anchor ("LookAtYaw" + an exact prologue) failed on 1.1 - check_hooks.py: the
        string is there with 10 referencing functions, none starts with the prologue. Operator: DON'T just patch the
        new bytes - find why the dynamic lookup failed and make it robust. Also check_hooks on 1.1: OnHuntedPounceReached,
        OnHuntedSequencerFinish, OnEncounterOverlap = ANCHORS DISAGREE (the slot cross-check finds no thunk).
        DONE 2026-11-04 (WaCa-Core 'Camera anchor by what the code does'): WHY it failed - the exact prologue: 1.1
        saves R15 not R14 and stores the axis id at other frame offsets. Now scan::FunctionUsingWhere("LookAtYaw",
        pitch slot call, 1) + wildcarded body checks: found on 1.1 (0x1417A4B80) and the old build (VM: hooked as
        before). On 1.1 the TURN is inlined (1.1's own mouse look) - logged as such, WaCa's mouse look stays off there.
        The three ANCHORS DISAGREE fail on the OLD build too and the runtime finds them on both: a weakness of
        check_hooks' thunk cross-check, not a 1.1 break. Tool: WarriorCats-Mod/tools/anchor_report.py.
        CHECKER FIXED 2026-11-05: each UFunction gets its own pattern (HookSlot's) - both builds now CONFIRMED for the
        hunt / prey hooks; OnEncounterOverlap = REFLECTION. 1.1's one report is true: no turn function (its own mouse look).
  - [ ] Exit popup ("you will exit the game. Are you sure?"): clicks work, HOVER doesn't.
- [ ] **Operator play-test 2026-11-04 (the everything-on bundle Z:/WaCa/WaCa-mods-alltest-20261104; logs
      Z:/WaCa/UE4SS.log + WaCaNative.log 20:39-20:42)**
  - [x] P1 Hunting's role question (a Clan Life Choice) popped up on Select Your Cat, "before a save is even loaded":
        the game loads the last save for the main menu's preview cat, so WaCa.CurrentSlot() is set in the menus.
        FIX (ClanLife events.lua, VM pending): a PlayScene asked for without the game's HUD waits, plays once it's up.
  - [x] P1 the same leak: Hunting's wind announced "The wind blows from the north-east." on the main menu (a ShowLine).
  - [ ] P1 "Every lag spike still causes the mouse to spin like crazy" (Keybinds & Mouse mouse look; the hitch drop
        in place isn't enough).
  - [ ] P1 Pause menu top bar (the left / right tabs): clicking a header marks it yellow, but the old tab stays yellow
        too and the page doesn't change.
  - [ ] P1 Pause menu left bar (Resume, Settings ...): the buttons only work with a DOUBLE click.
  - [x] P1 Space doesn't accept in the pause menu. FOUND: in menus Space is the game's own Button_Y (its menus' second
        action key - keybinds.ini [UIKeys] lists it); our SpaceBar = Enter alias is for dialogue only. OPERATOR: make
        Space accept in menus and move Button_Y to another key (which?), or keep the game's Y on Space?
        BUILT AS A RECIPE 2026-11-04 (keybinds.ini, commented: [UIKeys] Button_Y = F + [KeyAliases] SpaceBar = Enter) -
        VM: with it on, Space on Resume closed the pause menu. SHIPPED ON 2026-11-05 (the operator's report asked for it;
        Y moved to F) - say if Y should be another key.
  - [ ] P1 MOUSE LOOK IS OFF ON THE OPERATOR'S PC: WaCaNative.log '[camera] update: not found (anchor "LookAtYaw") -
        mouse look OFF'. The GAME UPDATED: the operator's Wrc-Win64-ShippingDRM.exe is 183,319,112 bytes, the VM's copy
        (2026-10-24) 183,670,344. Every other hook was found; the camera update moved. The spin on lag spikes = whatever
        turns the camera without our hook (no hitch drop there). NEEDS the new game files on Z: (the exe at least,
        unpacked with Steamless like Wrc-Win64-Shipping-NoStub.exe) to re-find the anchor and re-run check_hooks.py.
  - [x] P2 "Hollystar: Hollystar has been up since dawn again" - a murmur about {LEADER} given to the leader. FIX
        (murmurs.lua + the patrol meeting lines in walkers.lua): no line naming the speaker through a placeholder
        ({NAME} = its own name stays). VM pending.
  - [x] P1 SHOW, NOT TELL: the duty "Gather moss from the leader's den" finishes as soon as your cat enters the den -
        no real moss to pick up, only a big text card. The duty should spawn real interactable moss (the game's own
        collectable / interactable) at the points and count the pickups. FOUND (VM 2026-11-04): the game has no moss
        actor - BP_InteractableReward_Container_* are EffectSetups (reward data), not actors, so the Gather duty's
        moss class never matched (it always fell back to herbs) and nothing of that class can be spawned. Moss is a
        REWARD of the clawable / diggable interactables (BP_Interactable_Claw_Bush, _BirdNest, Dig_DirtMound:
        EffectToApply / EffectsToApply gameplay tags, RewardType). Next: spawn a clawable bush in the den with the moss
        reward's tag; the claw = the pickup (WaCaInteracted). Gather likewise: count the real pickup, not the area.
        DONE 2026-11-04/05 (VM): Bedding = two Interact spots (bite / dig); Gather = the pickup's own OnInteracted
        (arriving counts nothing). Operator's check: E on a real herb in play.
        AND 2026-11-05 (VM): Water = Interact at the water (Eat pose); a pack duty's point can be Interact<n> = <pose>
        (example HerbRound: Sniff at the den, Eat at the pile).
        LIBRARY: WaCa.Spawn(classPath, at, yaw, scale) added to Core (ground + always-spawn; SpawnCat uses it).
        AND the second half (operator): "throwing out" the moss is also only reaching a spot - wanted: an interact
        prompt there, your cat plays a digging animation, done ~2 s later (the game's Dig interactable, or Core's
        spawnable Interact prompt + AM_Interact_Dig).
  - [x] P2 Nightkit (a kit of your own, kits.lua) can't be talked to - it says a murmur when you walk past, but there is
        no conversation to repeat it / talk at all.
  - [x] P2 THE DUTY MARKER ON THE MAP: the day's duty marker is a green leaf (not very "questy" - acceptable), but on
        the world map it shows as a circle with green particles and the leaf icon is completely covered by the circle
        (white or orange).
  - [x] P2 The duty's HUD quest line should carry the SAME icon as its minimap / map mark (the green leaf), so the
        mark's meaning is obvious; today the HUD line for "throw out the moss" shows an orange cat-face logo.
  - [x] P1 NO GAME-Y WORDING (operator rule 2026-11-04): duty / quest text must sound like the clan, never like a video
        game ("The den's bedding is done - turn it in" is silly; "Go collect your loot from the quest giver" is a no-go).
        "Let's report to the deputy" works - but an APPRENTICE reports to its MENTOR, not the deputy. Sweep every
        card / HUD line / map label in the mods' configs and code for game words (turn in, quest, loot, reward,
        objective, complete).
  - [ ] P1 Reporting to the deputy by TALKING to him: he only says the game's "There's nothing new for you. StarClan
        guide your path" - our [Talk] line swap (duties.ini [Talk] Key -> Report / Busy) didn't show on the operator's
        PC (the game update may have changed that text's key; their log stops at 20:42 - need a newer one). The talk
        itself should be the report: his own reply about your work, and the duty handed in.
        OFFLINE 2026-11-05 (exe + pak dumps): NOT a 1.1 change - WBP_QuestGiver_Dialogue2 is in the old paks too and is a
        QuestGiverWidget (NpcRef present in both exes). So the swap's checks failed on the cat itself: the clan's deputy
        is the STORY role <Clan>Deputy (Otterfeather in the VM save), while several cats use the game's Deputy giver
        class (Tigerclaw = RiverClanQueen). duties now logs 'your cat talks to <name> (NpcRef)' - the next log shows who.
        1.1 mouse: Player_Mouse_Camera_Right / _Up are in the 1.1 exe only - the detection key is sound.
        LEAD (2026-11-05, not proven for the deputy): the game keeps TWO actors of one cat - Toadfrost in camp and a
        second 190 m off, both shown. A report check bound to one actor missed the other; reports now take a cat of the
        same name (S: roles; game roles already match by role name). The next log's 'your cat talks to' line shows
        which actor was talked to.
        FOUND 2026-11-05 (VM probe): Toadfrost has two actors, BOTH narrativeRole 29 (TheRegretfulWarrior): one in camp
        (class BP_Quest_Giver_Deputy - the GENERIC class of every camp quest cat, the kits too; NOT 'the deputy') and a
        BP_Quest_Filler parked 190 m off, not drawn. Role lookups now take the copy nearest your cat (Events.Who). The
        deputy role here is Otterfeather (role 31) - ONE actor in the VM save, so copies don't explain the dummy text
        here. Cats with two actors in it: Spikebranch, Toadfrost, Nightheart, Gooseheart, Freezesong, Lionstar.
  - [x] MENTOR (an apprentice reports to it): the game has no mentor in its data - no role text, no save field, no
        actor (WrcMentorCharacter / BP_Mentor_Character / AIC_Wrc_Tutorial_Mentor_Controller are the TUTORIAL's
        mentor only); its story names one only in dialogue, and RiverClan's lines name two ("{THE SELF DOUBTING
        WARRIOR} as your mentor", "{THE REGRETFUL WARRIOR} as your mentor"). BUILT (VM pending): an apprentice
        reports to S:mentor when a pack's [Cast] names one (WRITING.md), else the deputy.
        LIBRARY EXERCISE 2026-11-04 (VM, the whole event): steps Say / Interact + Events.Place - the example pack's SoftMoss.
        AND 2026-11-05 (VM): a CUSTOM CAT (WaCa Looks roster: Troutwing -> Mossfeather) cast as a role (S:herbalist)
        speaks over her own head (Say @ S:herbalist) - the plate found by her custom name. Clean. OPERATOR: a default mentor
        per clan for the base game - which story role (or derive it from the apprentice ceremony some other way)?
        DERIVED 2026-11-05 (no hardcoding): the story role your clan's lines call 'your mentor' most, among roles with a cat
        of your clan in the world - VM: RiverClan -> TheRegretfulWarrior (Toadfrost in the test save). Operator: override?
        LIBRARY EXERCISE 2026-11-05 (VM): the pack's ScentLesson (S:mentor Say -> Lead: ReedBank -> Interact Sniff -> Say ->
        Bond) ran end to end with Toadfrost. Fixed on the way: the checkers' false 'S:mentor has no cat'; Lead didn't take
        places.ini names; a far, unseen lead cat (148 m) is set down 12 m behind your cat first (Walkers.BringNear).
        + MentorPraise (a cutscene cast by S:mentor at ReedBank) played; a Reach event no longer fires in the middle of
        another scene (Events.Busy) - FrostAtTheReeds held back during the lesson, played on coming back after it.
        + ScentTrail (a pack duty: Interact at ReedBank, TurnIn = S:mentor): fixed duty points taking places.ini names,
        talking to an S: role cat counting as the report, the same-name second actor, the report-miss card's wording.
        + Story days on with the pack (VM): after a mod reload the story ran as day 1 till the next game save (6 min)
        while the save had day 2 / the pack day 3 - now restored when the HUD shows.
        + Gathering evening both ways (VM): Attend = Clan Life's fade/card then the pack's GatheringNight (docs: Clan
        Life's own sections can be Replaced); StayBehind = RogueRaid + LeaderFavour 2 / DefendedCamp 1. Per-cutscene
        PutPlayerBack (GatheringNight brings your cat home from the Island).
        + Activities: a pack's content/activities.ini now merges (ShareTongues played on Lionstar, VM). Configs still read
        alone, on purpose - player settings / world tuning, not story content: daynight.ini, clanlife.ini, weather.ini
        (a story sets its days' season / weather in days.ini).
        + Patrol: step (a story's own patrol) - VM: camp warriors walk to the reeds and home. Fixed on the way: no camp
        cat ever qualified for a patrol (all RiverClan camp cats give quests); a patrol's first cat waited for you the whole
        patrol; the leader went on patrol.
  - [x] P1 No map mark for going back to the cat you report to (the hand-in): mark the mentor / deputy / leader on the
        map (and minimap) once the duty's work is done.
  - [x] P2 A THIRD TAB in the pause menu's Quest page - "Clan" next to Main Quests / Side Quests - with Clan Life's
        quest info: the day's duty (what, where, progress) and the packs' stories. What exists: WaCa.QuestLine
        (2026-11-03, the operator's answer (c) then) = a display-only line in SIDE QUESTS for a pack's story; the duty
        isn't listed at all, and there is no third tab. The page's tabs are UGuiPausePanelQuest's (Main / Side, keys
        3 / 4, TriggerL / R). LAYOUT (offline dump, extracted/json/WBP_GuiPausePanelQuest.json): two tab buttons
        mcGuiButtonTabMainQuest / mcGuiButtonTabSideQuest (WBP_GuiButtonSubTabMenuSmall_C) and two lists
        mcGuiMainQuestList / mcGuiSideQuestList (WBP_GuiIListItemsQuest_C), in CanvasContent / CanvasTitle. PLAN: a
        third WBP_GuiButtonSubTabMenuSmall ("Clan") after the side tab; selecting it (click, TriggerR past Side, key 5)
        hides both lists and shows ours - entries made like WaCa.QuestLine's (the duty, then each pack story), detail on
        hover; the native tab state put back when Main / Side is chosen again.
        BUILT 2026-11-04 (WaCa-Core questtab.lua, VM screenshots): the Clan tab after Side Quests, TriggerR / click in,
        TriggerL / Main / Side out, the duty on it with its leaf. DetailDown 120 SEEN 23:49 (the title clear of the '4 >' hint). Open: only the
        first panel shows (a pack story's panel would be a second); the footer still says TRACK QUEST on it.
  - [x] P2 Map hover on our marks says "Pulse1" (a widget's name, not the mark's title).
  - [x] P2 Map hover's drop shadow is still way too far LEFT of its text.
  - [x] P2 Map hover text shows for the mouse only, not for the gamepad's centre cursor.
  - [x] P2 Panning the map while hovering: the hover text stays though the mark scrolled away from under the mouse.
  - [x] P2 the cats' flavour lines (murmurs, patrol / hunt lines) are liked, but the big bold message card (WaCa
        Cutscenes' ShowLine) is the wrong place for them. Operator idea: speech bubbles over the cat that says it.
- [ ] **Operator play-test 2026-10-30 - fixed, VM runs 2026-10-30 08:45-12:10 (drop Z:/WaCa/WaCa-mods-test-20261030c).**
  VM-CONFIRMED:
  - [x] P0 the deputy couldn't progress a third: the meeting place was a parked FILLER's spot (the leader role is also on
        a BP_Quest_Filler_C) behind a hidden 5 m report-key check. Now (ClanLife): your clan's leader = the
        quest-available story cat of your ClanType; the meeting place = the game's interactable
        (BP_Interactable_CInematic, mesh hidden) on open ground 2.5-4.5 m from the leader, clear of every story cat
        (world traces: ground, 3 m of sky, room at knee height - the camp has no navmesh); the game's own "E Interact";
        heard as Player_Interact (65). VM: E -> morning ends -> clan meeting -> afternoon (new spot) -> evening.
  - [x] Its mark: the game's scent-hint glow (NS_Scent_Hint_Item, User.Code_Color) in CYAN, replayed every 2.5 s (a
        one-shot burst); a cyan dot on the world map (mapmarks.lua: the game's white UI circle, axes read off the
        checkpoint icons - exact) with "Meeting place: give out the clan's tasks" on hover. No quest hint marker there
        (once tracked it guides to the tracked QUEST - the far StarClan target).
  - [x] "(F)" in the leader's goal: gone with the report key (F stays only for talk turn-ins, README).
  - [x] Prophecy / Defender flicker: one switch per crossing, none while jiggling on the overlap.
  - [x] Settings tab hover: no command sent, the list's selection stays (a row nav steps only on a click, shoulders
        only; a hover toward a tab had sent Down to the volume list). Click on Gameplay turns the page.
  - [x] Only the top menu screen takes the mouse (the pause menu's tabs were hovered through the Settings popup).
  - [x] Pause > Party: nothing of the hidden General page is hovered (non-current GuiPausePanel = not on screen).
  - [x] Pause > Quest: "Main / Side quests" clicks press TriggerL / R from the active tab (CanvasSelected) - only the
        sub-tab turns.
  - [x] Pause > Bonds scroll bar: a drag selects the row that far down (rows counted by the grid's own selection);
        drag down / up shows the list's end / start.
  - [x] Map names: legend names by core image name; the clan camps; the label font (a legend entry's - the title
        font drew a dark copy to the left).
  - [x] Names: a sidecar made for another cat ([Cat] PrefixNameId) is not used (VM: planted Cold/STR_CAT_NAME99 on
        Dapplepatch -> "not used", name stays). Custom name shows on the pause General card, the HUD and the PARTY
        page (VM, prefix "Mist": "MISTPATCH" in the party list). Dialogue {PLAYER}: not testable on the VM (no talk
        prompt at ~0.3 fps; the scripted sequences are ceremonies without {PLAYER}) - the operator's check.
  - [x] Our scent trail + StarClan guidance off in the test bundle.
  OPEN:
  - [ ] Camera spin when collecting: collecting shows no menu (VM) - so not the cursor-recapture jump; the VM can't send
        raw mouse input to reproduce. Core logs any frame where the mouse alone turns >= 45 deg (dt, delta) - read the
        operator's next log. (Recapture settle + hitch drop stay in.)
  - [x] Fresh-kill pile decay: it IS the pile component's tick (VM: tick on - countdown 1m27s -> 50s in 37 s of game
        time; off - stood at 49 s). Hunting [Pile] Decay = 0 (default): tick off at the HUD, the pause card's
        countdown hidden (VM: card shows 90/100, no timer).
  - [ ] THE POUNCE WALK (operator 2026-10-30 spec): the game's own detection (sound + sight) keeps running while the
        game walks the cat in, and stops only at the JUMP; spotted -> the prey flees, the cat's walk / jump carries on
        (or pounces at once: "spotted, tried anyway, missed"); a failed chance roll -> the prey flees AT THE JUMP.
        VM facts: detection flags Vision 1 / Sound 2 / Cone 4 / InPursue 8 (BT_Enemy services 7 and 15); prey
        detection sphere 16 m; pounce sphere 4 m, jump at SneakAttackWalkOffset 2 m; sneaking from behind NOT detected
        at 2.0 / 3.2 / 3.8 m (teleport-placed at 1.5 m: detected - teleport artefact or a close range). A pounce can't
        be started on the VM (Space = Player_Pounce 72, held or tapped; camera on the mouse; crouched; in range - the
        game shows no prompt) - so the walk / jump hooks can't be seen here: needs the operator's machine or a way to
        start the pounce. DONE meanwhile: the landing-loud check removed (Core 3912265, Hunting f08db93 - the prey is
        already caught there); [Prey] PounceFromJumpRange = 1 (VM: in range at 2.0 m, not at 3.8 m) as the
        alternative the operator named.
  - [x] Prey charging into battle (operator: "flee instead of charging"; "if you fail the first jump, it's gone"):
        Hunting peace.lua - on the game's detection (AWrcRoamingEnemy::OnCharacterDetected, ProcessEvent) or a
        missed / heard pounce, the listed kinds' AI stops, they dash off and are hidden after 1.5 s. Our loud-ground
        "heard" rule stays (the game's detection stops once the pounce plays - operator). VM: mouse heard the cat on
        loud ground -> ran off, hidden, no combat; heard-miss -> gone.
  - [x] Field mouse fighting back: the operator's log shows the pounce CAUGHT (95%, rolled 87) - the fight is the
        game's touch encounter (OnEncounterOverlap). Core PreyPeace + Hunting [Prey] NoFight (Mice / Squirrel / Rabbit /
        Bird): the call is dropped (VM: mouse touched - "no fight", no combat; rat touched - combat as before). The
        encounter capsule's collision off did NOT stop it. "0% - loud ground" label: VM-seen (cat on BP_MovementModifier_Loud,
        the prey 3 m off labelled "0% - loud ground").
  - [ ] Coldpatch: the operator's existing slot-0 sidecar has no owner record - they remove its [Name] once.
  - [ ] VM HANG 2026-10-30 15:29: the game thread stopped right after a hot reload of WaCaHunting (log ends at its
        "wading: on", 4 GB, the harness command file never read) - dev-only path; watch for it.
  - [ ] VM crashes in UE4SS Lua (null read 0x18, UE4SS+0x2aed17): 09:46 (walker + reloads) and 10:41 (my probe set a
        font material to nil). Watch for the first kind in clean runs.
  - [ ] A tab click right after the pause menu opened went "through its host" once (the next click worked).
  - [ ] Night: the den sleep wasn't re-run this time (teleport into the den didn't trigger it).
  - [ ] The map hover label shows the game's legend names; our own icons beyond the meeting place (hunting ground,
        den) - next.
- [ ] **P1 (operator 2026-10-28): leading = MANAGING the clan** (deputy / leader). Each duty third marks the clan's
      meeting place, where you assign the tasks (first cut 2026-10-28: the marker + F there ends the third). Later a
      proper UI: clan cats with stats that make them better at patrols or hunting, you build parties and send them out,
      the outcome depends on their stats - "lead" means deciding what the clan does, not bimbling around.
      DESIGN QUESTIONS FOR THE OPERATOR (2026-11-01, before building the full UI): (1) the stats - the clan's generic
      cats have none in the game (only story / party cats have combat levels); invent per-cat hunting / patrol / fighting
      skills (from what? rank, age, traits the game gives the player only), or use the combat level for all? (2) what an
      outcome changes - fresh-kill pile, border state, injuries, bond? (3) the screen: the game has no list-of-cats
      picker to reuse (its popups take 1-2 options; the Defender / Skirmish party screens are its only cat pickers -
      fed natively); a WaCa-built one (runtime text / image widgets, like the controls screen's hint line) is possible.
      Waiting for the rules - inventing them would be the kind of guess the operator rejected for romance.
- [ ] **P3: field cats can't go on patrols** (VM 2026-11-05): their AI moves (follow.lua) fail on this map (since
      2026-10-30), so the field-cat fallback was REMOVED (it claimed patrols nobody walked): no camp cat free = no patrol,
      logged. Open feature: move field cats (BP_Exploration_Character) with the walkers' mover, then let them patrol.
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

      Write the map into PROJECT_PLAN.md.
- [ ] **Mod pipeline.** A skeleton UE project in the matching engine version (dummy classes from the header dump). Cook a
      test Blueprint mod and load it from a `~mods` pak (IoStore: retoc / ZenTools for repacking). Prove ONE change
      end to end, e.g. a string edit.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Install the matching UE version, generate dummy C++ classes from CXXHeaderDump, cook a test pak with one new
        Niagara (rain) and load it via UE4SS's pak loading - unlocks rain + any custom content.

## P1: MVP mechanics
- [ ] **THE CLAN LOOP** (operator 2026-10-28, "the most important thing I want to see"): wake up -> the deputy assigns
      the task -> you do it (exploring as long as you like) -> return to camp -> the clan event of that time of day,
      if any (morning / noon / evening: warrior ceremonies, clan meetings ...; the evening: eating together, sharing
      tongues) -> the time advances by a FULL THIRD (8 hours) -> the next assignment. After the evening: sleep, or
      the night watch: go to a guard position, a short cutscene shows the time skip. Replaces the effort clock of the
      slot day (15) - time moves in whole thirds.
      BUILT 2026-10-28 (duties.lua rewritten again; duties.ini, NEW clanevents.ini; events.lua = the one scene runner):
      - thirds Morning / Noon / Evening (+ Night) at [Thirds] hours (the sky jumps there; DayNight.Drive - no wall
        clock; moved forward only within a day - never across the morning, VM: a restored night hour round the clock
        ended two days at once). Stages: start (beats) -> assign (the deputy: [Assign.<Task>] steps) -> task -> return
        -> event (back in camp: days.ini beats, clanevents.ini events by When / Chance / Day / Every / Once,
        [Third.X] Event steps) -> the next third. Night: Sleep (rest key) / NightWatch (the guard spot = where the cat
        last walked into camp; counts once it stepped away and back; the [NightWatch] cutscene: Fade + card, then
        DayNight.Skip, the morning fades in) / any task (story NightDuty = Hunt).
      - the camp = the median of the player's clan's story cats (VM: RiverClan, 22 cats, ~40 m; the game has NO camp
        trigger - its QuestBoxTriggers are small quest / race boxes, EventOnActivate all 0) + CampRadius. Where the cat
        is comes from its own FOOTSTEPS (every StepEvery-th) and sense pulses - a trigger box spawned at the camp never
        reported (teleports, VM); boxes kept for patrol points / the teacher as a second signal.
      - a done task never sends you home; its END POINT is a turn-in (operator 2026-10-28: "returning to camp
        shouldn't immediately trigger things"): [Task.<Kind>] TurnIn = Pile (the catch onto the fresh-kill pile - the
        game's UWrcAchievementsManager.OnContributeFreshKill) | Deputy (a talk with the deputy - the dialogue screen's
        NpcRef has a ...Deputy role) | Partner (talk to the cat the task was with - training: the mentor, back in camp;
        operator) | any role (Leader, MedicineCat ...) | None. Defaults: Hunt Pile, Patrol Deputy, Free Deputy,
        Train Partner. (The pile as an "end of afternoon" trigger: possible per task, not used - morning patrols.)
        VM STATUS 2026-10-28: the loop runs morning -> noon -> evening with the camp found by its den doors, camp in / out
        from the player's footsteps (on EVERY step - every 4th aliased with the VM's 2-step walks), Gatherings announced
        + picked, NPC patrols gathered and sent out (3 clanmates, 3 border points). NOT seen on the VM (operator play
        check): talking to the deputy (the VM never makes an NPC talkable - see the VM notes), a pile contribution, the
        Gathering's evening, the night watch's guard spot. Check in play whether the deputy ALWAYS offers a talk (else
        the report needs a fallback, e.g. its own interaction).
        VM FULL DAY 2026-10-28 (Free tasks turned in at the PILE - the game's own UWrcAchievementsManager
        OnContributeFreshKill called by the harness): morning -> meeting (200) -> noon -> evening -> sharing tongues
        (200) -> the Gathering (attended, Gathering.Count 1) -> night watch: away, onto camp gate 1 -> the cutscene ->
        "day 18 over" -> day 19 morning + its Gathering pick. The zone event fired for R-05. Fixed on the way: Bond @
        Nearest with a generic clanmate (its narrativeRole isn't a number). STILL UNSEEN: a talk with the deputy (the
        VM never opens one - even PlaySequenceDialogue with the deputy showed no dialogue screen); a REAL deposit at the
        pile (the harness called the achievements function itself).
      FIRST-RELEASE CUT 2026-10-28 (now in C:/Projects/WaCa-ClanLife, 0.8.0; ROADMAP.md there = in / later): the day at
      a glance (clan.status topic + hud.lua: a COPY of the game's own WBP_GuiHudCurrentObjective_C under the game's
      quest panel - the HUD is laid out in 3840 x 2160 units), clanlife.ini one switch (c.part), the REPORT KEY (F next
      to the deputy / partner - VM-VERIFIED: "reports to BP_Quest_Giver_Deputy (287 away)" -> turned in -> meeting),
      and from MaxRank on "yours to lead" thirds (F in camp ends them; time used to stand still for deputies).
      DEFERRED to their own mods (ROADMAP.md): story packs, cutscenes from text, the cast / ENarrativeRole, murmurings,
      apprentice duties, NPC jobs + patrol encounters, the party, the day-clock dial, fresh kill without hunger, story
      fixer. OPERATOR CHECKS LEFT: a real conversation turn-in with the deputy, a real pile deposit.
      PILE ON THE VM (2026-10-28, tried, NOT possible): the camp's pile is a quest giver (BP_Quest_Giver_FreshKill_C,
      RiverClan at -46119 3197; SwtAdventureFreshKillActor); its interaction is native (no UFunction - the class chain
      has only widget / overlap events) and opens WBP_GuiScreenFreshkillPile (GuiPopupFreshKill) - built by hand it
      stays empty (needs the native setup). E next to it does nothing on the VM (like NPC talk). The SwtAdventure
      FreshKillPileComponent is on the GameState (data only). So the deposit -> OnContributeFreshKill -> TaskTurnedIn
      Pile chain is verified only from OnContributeFreshKill on (VM full day); the screen part needs the operator.
      SCREEN PART 2026-10-31 (VM): the pile screen opens on the VM now (WaCa Core OpenPopup 86) and WaCa Hunting's
      Deposit drives it - 10 mice went on (+10 pts), and the game saved its achievement + inventory at the confirm (its
      own contribution path). A single run screen -> OnContributeFreshKill -> TaskTurnedIn with a Hunt task waiting
      still needs fresh-kill in hand (VM pounces don't finish at 0.5 fps); duties now LOGS a contribution no task waits
      for, so the link shows in any run.
      ONE RUN 2026-11-01 (VM, duties.ini Hunt-only + MaxRank Leader for the test - rank 3 = 'leads the clan's day', no
      tasks): 'the deputy: hunt 2 prey' -> HuntCaught x2 -> 'hunting done' -> the pile screen opened, Deposit ran:
      first 'nothing went on - the pile: Abundant' (78: each catch adds 4 to the pile itself), lowered to 38 ->
      'nothing went on - Scarcity': the cat carries no prey (the earlier deposit test used the save's rats). Adding
      prey from a script isn't possible: WrcInventoryComponent is fully native (no reflected functions / properties).
      So the last link - a deposit counted as the turn-in - still needs a real catch (the operator's play: pounces
      can't start on the VM). Also found: the test's 'out of camp' spot (-45000,4000) is inside R-05.
      - the third's end in ORDER (operator: a story's cutscene after the hand-in, BEFORE or AFTER the clan event):
        numbered slots, lowest first - story beats 100 (days.ini <Third>), clan events 200 (each its own Order =),
        story after-beats 300 (<Third>After), duties.ini [Third.X] Event 350, the ClanThirdEnd hook 400; logged. Walking into / out of camp only emits CampEntered / CampLeft (the night watch, patrols, mods).
      - THE CAMPS (VM 2026-10-28, zones.json + tools/zone_map.py): every clan's camp is one of the game's zones -
        R-05 RiverClan Camp (3 areas, 2 gates, 46 x 90 m), S-08 ShadowClan Camp (2 / 1, 33 x 57 m), T-10 ThunderClan
        Camp (1 / 2, 40 x 40 m), W-04 WindClan Camp (2 / 1, 62 x 78 m); the code's letter = the clan's initial. Found
        by its DEN DOORS (6-7 in each camp's outline, none elsewhere; the other clans' story cats aren't in the world),
        story cats as the fallback. The zone event (WrcZoneNameTrigger OnOverlapBegin, the entering actor handed over)
        fires for the player (VM: crossing R-03's gate) - entering / leaving camp = the game's own zone change.
      - hook points: steps in configs (Card / Dialogue @ who / Fade / FadeIn / Wait / Bond @ who / Emit / Hook),
        blocking Lua hooks ClanThirdStart / ClanAssign / ClanBackInCamp / ClanNight (Events.Hook), WaCa events
        ClanThird / TaskAssigned / TaskDone / BackInCamp / ClanNight / DutiesJudged; days.ini Days.Beats per third.
      - the game's sequencer for every mod: WaCa events SequenceStarted / SequenceFinished (id) / SequenceEnded /
        DialogueStarted (id) / DialogueNext; WaCa.Watch's 5th arg now hands over ANY simple parameter (native
        ReadParam: object / FName / gameplay tag / string / number / bool / enum).
      - offline (lupa, real events.lua, mocked world): morning hunt -> out -> 2 catches -> back -> meeting -> noon free
        -> out / back -> evening free -> share tongues + bond -> night watch -> away / back -> cutscene -> verdict
        "2 done +5" -> day 2 morning. VM: see below.
- [~] **Procedural names: no doubled prefix / suffix** (done, operator check open) (operator 2026-10-25: "Blazeblaze"). The NPC name generator
      (USwtAdventureNPCGenerationManager / UWrcNPCGenerationManager; tables PreffixName.csv / SuffixName.csv +
      the filter tables) must never pick a suffix that repeats the prefix (Blaze + blaze, Fern + fern ...). First tweak
      into the procedural generation.
      0.4.0: DONE (roster.lua) - the only doubled combination in the tables is Blaze + blaze; the fix is general
      (suffix text == prefix text) and replaces the suffix with one its rank uses, deterministically per prefix; runs
      after UQuestManager.OnNPCGenerationCompleted, on load and on slot change, and syncs spawned NPCs. OPEN: the
      operator's in-game check (log line "renamed ... (doubled name)").
- [ ] **19a. PC controls: bindings.** Pause on Esc: DONE in 0.1 (awaiting the operator's test). Still open: hint
      that quests are on K (UI), an in-game rebinding UI (the game's own GuiCustomConfigKey screen should read / write
      our bindings), mouse bindings for the camera.
      Keybind menu (operator 2026-10-25): keep everything mouse / key related standard-UE compatible so the menu can
      just read and write the engine's own input mappings (UPlayerInput action / axis mappings, the menus'
      DT_GamepadButtons* rows, the viewport capture mode) - the menu saves them to keybinds.ini, the one source. The
      raw KeyDown event only observes (aliases press real keys), so it stays compatible.
      IN-GAME REBINDING DONE 2026-11-01 (VM): the game ships an unused "Control Configuration" popup
      (WBP_GuiPopupControlConfig - 11 commands, gamepad + keyboard icons, a hidden "Reset Default"); Enter / a click
      on the pause menu's CONTROLS page opens it as the rebinding screen (Keybinds controls.lua): pick, press the new
      key, Escape cancels, Delete = the game's key (keeps mouse buttons via "Default"). Written to keybinds.ini
      [Actions] in place and applied LIVE (Core ApplyBindings - UPlayerInput layout read from AddActionMapping). Key
      ICONS / HINTS now follow keybinds.ini everywhere (the default-list getters SwtPlayerInput +0x348/+0x350 hooked):
      the controls page, the screen and the HUD prompt ('F Travel'). VM: Map = F live -> F opens the map, M nothing.
      OPEN: the operator's feel check; axes (move / camera) are not on the game's screen - still ini-only [DONE
      2026-11-03 (VM): direction rows on the controls screen - a left column, the game's key buttons + icons (DT_Keys),
      rebind / Delete / Reset write [Axes]]; the
      remaining 'quests are on K' hint - DONE 2026-11-02 (VM): the game's own hidden HUD quest button (scroll + the
      quests key, beside StarClan's Q) shown, keybinds.ini [Hints] QuestKey.
      MOD KEYS 2026-11-01 (VM): WaCa.ModKey(mod, name, default, label) - every mod's own keys in keybinds.ini
      [ModKeys] (Clan Life Report / JoinActivity / Rest / AskMate, Cutscenes Skip), announced so the controls screen
      warns on a clash: 'F is Interact now - it is also Clan Life's key to report a finished task', 'also Scent
      tracking'. The screen got a hint line in the game's font. A reload with the screen open no longer leaves every
      key swallowed (native releases on Lua stop; the mod closes a leftover screen). Drop Z:/WaCa/WaCa-mods-test-20261101q.
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
      VM 2026-10-29 (Looks a875e4f): the ceremony's suffix box typed "heart" -> HUD "GHHEART" - after a FIX: the game
      writes the new warrior name to the save's player Customization after the popup closes (the pawn copy stays old),
      so the override sat on the old name ("Dapplepool" showed). Now read from the save + re-applied on save / popup.
      NOTE: that test renamed the VM test cat Dapplepatch -> Dapplepool in its save (the list can't be driven back).
      RESTORED 2026-10-30: tools/save_edit.py rewrote the save's JSON (_POOL -> _PATCH, and the sidecar's test prefix "gh"
      removed); the game loaded it (hash not checked), Select Your Cat + HUD show DAPPLEPATCH, the game's next save kept it.
      OPEN: the operator's real-game test (does the shown name update? HUD / party / dialogue / ceremony). Then an
      in-game text box at cat creation (UMG, or a runtime-built EditableTextBox from Lua).
      SEEN 2026-11-01 (VM): Select Your Cat lists the GAME's name (a warrior start's EMBERHEART shows as 'SHARPPAW,
      Apprentice') - FIXED same day: while the list is up each renamed cat's entry shows its own name (VM: EMBERHEART).
- [ ] **1. Canon clan roster.** Remove the procedural generation of the clan cats. Lock the roster to a specific point
      in the books' timeline (pick the book / moment with the operator).
      PRE-WORK 2026-10-31: WaCa-Looks examples/WaCaCanonRosterDraft - RiverClan at Into the Wild (leader Crookedstar,
      deputy Leopardfur, medicine cat Mudfur, warriors Blackclaw / Stonefur / Heavystep / Loudbelly), names from memory,
      OFF until the operator checks them and picks the moment; live [<Clan>.<Rank>.<n>] pins added for it. VM: all
      applied (the deputy slot unused - the player is the deputy). The operator's: the book / moment, the other clans.
      MORE 2026-10-31: the draft covers all four clans (ThunderClan Bluestar / Redtail / Spottedleaf ..., ShadowClan
      Brokenstar / Blackfoot / Runningnose ..., WindClan Tallstar / Deadfoot / Barkface ...) - other clans' cats pin where
      the game brings them in (only RiverClan's at camp on the VM). LIBRARY FIX found by it: [<Clan>.<Job>.<n>] now
      stays with the same cat across sessions (WrcGame.<slot>.WaCaLooks.ini [Pins]; VM: two boots, Sagefang Heavystep
      both times). Test drop Z:/WaCa/WaCa-mods-test-20261031i. Still the operator's: check the names, pick the moment.
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
      BUILT 2026-10-28 (experimental, duties.ini On = 0): duties.lua - at each DayStarted (and 30 s into a session's
        first world) the duties from the clan's needs: Hunt N prey (Max when the save's FreshKill.Value < PileLow;
        counted by HuntCaught), Patrol N border points (random spots in generator areas 20-90 m away, each marked with
        the game's quest hint actor; checked within Reach at every in-game hour / sense pulse); at DayEnded the
        verdict: standing +Done per duty done, +Missed per missed, kept in a save sidecar (for 14 pacing) +
        DutiesJudged event; cards at dawn / each duty / the verdict; none from MaxRank (Deputy) on. VM (1-minute test
        days, Reach raised): "day 17 ... hunt 3 prey, patrol 2 border points" -> "border point 1/2 checked" -> "day 17
        over - 1 done, 1 missed: standing +1". Hunt counting not seen live (no pounce on the VM - same HuntCaught as
        hunting by chance). [2026-11-02: Train + NightWatch BUILT below; the deputy assigning = the P1 'leading = MANAGING' - first cut built, the full screen waits on the operator's design answers] Open: Train / Night watch duties, the deputy ASSIGNING duties, standing feeding rank-ups
        (14).
      THE SLOT DAY (operator 2026-10-28, answers: slots with one activity each; effort moves the clock; night = sleep
        or night watch, the story may set e.g. a night hunt; "exploration is super key": activities send you out into
        the territory and a done activity never forces you back to camp). BUILT 2026-10-28 (duties.lua rewritten,
        duties.ini [Day] / [Slots] / [Effort] / [NightWatch]; daynight.lua DayNight.Drive / Advance / Driven):
        - a day = 4 slots (Morning 6, Afternoon 12, Evening 17, Night 21; the day turns at the morning). At dawn each
          slot draws an activity by weight ([Slots]: Hunt / Patrol / Train / NightWatch / Sleep / Free; hunting x
          PileFactor when the pile is low; training only up to [Train] MaxRank) - or the story's (days.ini
          MorningDuty / AfternoonDuty / EveningDuty / NightDuty -> Duties.Plan(hunt, patrol, kinds)).
        - the clock: no wall clock - DayNight.Drive(morning hour) stops it; effort (PerStep footsteps of the player -
          the BP_AnimStepNotify watch with MeshComp, PerCatch per pounce caught or missed, PerFight) moves it through
          the slot ([Effort] <Slot> points = the whole slot), HELD at the slot's end until its activity is done; a
          done activity frees the rest of the slot (hunt on - every catch still feeds the pile: PilePerPrey; "make
          your own way back" after a patrol); the next slot comes with effort. Night: Sleep holds until the rest key;
          NightWatch passes in real minutes ([NightWatch] Minutes, an animation step chain) and ends the night (+
          Standing). Free slots run straight on.
        - verdict at the day's end (the morning, or a rest): activities begun and done / missed -> standing.
        - exploration: patrol points + hunting grounds 30-120 m away (MinDistance / MaxDistance 3000 / 12000).
        - offline sim (lupa, mocked clock): plan -> morning hunt held at 06:00 while open -> 2 catches -> done, the
          hunt goes on (10 of 2) -> afternoon by effort -> evening hunt -> night held at 05:59 -> rest -> verdict
          "2 done +4" -> day 2 morning. VM: see below.
        OPEN: the deputy ASSIGNING duties (from MaxRank on) [= the P1 'leading = MANAGING', waiting on the operator's design answers]; standing -> rank-ups (14, parked); which story points
        freeze time (DayNight.Freeze exists).
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
      EXHAUSTION REDEFINED 2026-10-28 (operator: "more a resource to manage ... caps how much you can hunt ... I don't
        want to watch an exhaustion meter 24/7 while just exploring - only when you do a thing, a fight or a
        pounce"): tiredness now ONLY from PerPounce (HuntCaught / HuntMissed) and PerFight (a fight whose popup
        opened: its end screen / EndCombat), x LateFactor late; PerHour / PerDuty removed. Hunt = 0 at Exhausted =
        a hard cap on a day's hunting (operator's call).
      EXHAUSTION BUILT 2026-10-28 (experimental, exhaustion.ini On = 0): tiredness 0-100, +PerHour per in-game hour
      awake (x LateFactor between LateHour and DawnHour), +PerDuty per duty done (DutiesJudged); at Tired (60) /
      Exhausted (85): the cat's CustomTimeDilation (moves + animates slower - MaxWalkSpeed is rewritten by the game
      every frame, an override never held, VM), hunting chance x and damage dealt x (TiredFactors -> hunting.lua ->
      HuntRoll / CombatScale); a rest (TimeSkipped) resets it; kept in a save sidecar; cards at each level. VM:
      "Tired (60)" -> "Exhausted (94, a late hour)", dilation 1.00 -> 0.65, "hunting: tiredness x0.60 hunting, x0.75
      damage", F9 -> "rested (0, slept)". Phases (morning / afternoon / evening) for day scripts: open (25).
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
      BUILT 2026-10-28 (experimental, days.ini On = 0): days.lua - [Day.N] per story day: Morning / Afternoon /
        Evening scenes (Card: / Dialogue:, played through Events.Play at the [Days] phase hours, each once per story
        day), Hunt / Patrol (Duties.Plan - instead of the clan's needs), Season / Weather (Weather.SetDay: a forced
        season + day weather chances), Advance = Always | Duties (all done - DutiesJudged) | Rank:<Name>; not met = the
        story day repeats (scenes seen skipped); Like = M copies, "none" turns a key off; the story day + scenes seen
        in a save sidecar. Inited before weather / duties so it sets their day up first. Resting now ENDS the day
        (DayNight.Skip emits DayEnded - the duty verdict runs). Offline test (lupa): advance / repeat / skip seen /
        Like. VM: "story day 1 ... season Greenleaf, weather Clear=100", its morning card; F9 -> "on to story day 2"
        with "patrol 2 border points"; F9 -> "story day 2 repeats (Duties not met)". Content (the real days): operator.
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
      UFunction - fires when the prompt shows). [SUPERSEDED - see the later DONE / FIXED] NEXT: hook InteractionWidget:SetInteract and walk onto a spot.
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
      hunting.ini. [SUPERSEDED - FIXED below] Next: find the area Blueprint's construction crash (symbolise 0x143E1AB60 / 0x143E1CDA0 under
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
        [SUPERSEDED - the DONE above reads the table] Next: find the loader (the struct's StaticStruct users / a watch on +0x10C during a won fight) and read
        the parsed rows from there - no copied numbers.
      - FUTURE (operator 2026-10-27): WIND DIRECTION. Prey that hunts by scent (all but birds) smells a cat that is
        upwind - circle it to approach downwind, and never from the front (its view). Later: by prey difficulty, it
        checks the scent / turns around more often.
        BUILT 2026-11-02 (WaCa-Hunting wind.lua, [Wind] On = 0): the wind turns every few in-game hours (said on screen);
        a scent prey with your cat upwind within 15 m notices it the game's own way (OnCharacterDetected) - NoFight:
        it runs off. VM: downwind nothing, upwind the mouse noticed + gone. OPEN for the operator: turn it on; the
        'never from the front' (its view) part is the game's own sight; prey difficulty: DONE 2026-11-02 (harder prey -
        [PreyFactor] < 1 - smells from further, up to Wary x Range; VM: a 'hard' mouse noticed the cat at 25 m).
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
      BUILT 2026-10-28 (on the duties, duties.ini [Hunt]): the hunt duty is the mission - its size from the pile
      (PileLow), a HUNTING GROUND marked (a prey creature of the season 20-90 m away, the guidance-style marker: sense
      mode shows the way; HuntingGround = 1), and a finished hunt adds PileReward to the clan's fresh-kill pile the
      game's own way: hunt::AddResource - any USwtQuestResourceComponent's add-value virtual +0x508. The level
      component's slot IS the anchored base add (0x14165B460: reads +0x10C, scales by +0x114); the pile's slot is an
      override (0x1417C1980: milestone before -> base add -> milestone after -> look update) - accepted because it
      calls the anchored base directly (scan::CalleeWhere); anything else refused (it was, before the override was
      understood). VM: the pile 95 + 5 -> 100 (WaCaNative_AddResource). The hunting-ground card: not seen yet (the
      VM stalled in its menus that run). Territory / season: the prey there follows preyworld.lua (the season's).
      VERIFIED 2026-11-01 (VM): a forced hunt -> HUD 'The hunting grounds - Hunt for the clan: Prey 0/2' + its map mark.
- [ ] **7. Real patrols.** Cats join you just for the patrol (temporary party), with border marking and events.
      PREPARED 2026-10-28: the patrol DUTY exists (duties.lua: border points marked, checked on arrival). Missing:
      clanmates walking WITH you. The party = ASwtAdventureCharacter.Party (TArray<ASwtAdventureCharacter*>, the
      save's GameplayProgression.Party) - the game's own followers. Plan: for the patrol duty, add 1-2 nearby
      clanmates to the player's Party (and remove them at the day's end), or move them along as activities.lua's
      pair walk does (AI MoveTo, brain paused) toward each border point; border marking = a scent puff (Scent.Puffs)
      + a card at each point. Needs the VM (whether Party accepts generic clanmates).
      BUILT 2026-10-28 (duties.ini [Patrol] Companions = 2): when the patrol duty starts, the nearest idle clanmates
        (within 30 m) pause their AI and MoveToActor your cat (it tracks a moving goal); they get their AI back when
        all border points are checked or the day ends. VM: "1 clanmate(s) join your patrol" (twice, 1-minute test
        days); the follow itself not confirmed (the 60 s check found none within 6 m - at the VM's 0.3 fps they cover a
        few units per game second, and the test days ended the patrol within a minute). Check in play.
      REBUILT 2026-10-31: the companions are the walkers' temporary party now (the field cats' AI moves fail on this
      map): the nearest plain camp cats walk a row behind you (the party beside), home at the patrol's end / in camp.
      VM: Turtleleaf + Slatefur followed 2.1 m behind from camp into the forest, home on release. TemporaryParty event.
      Still open: the patrol's border-point events (rival scent, prey) - design / story content.
      PREPARED 2026-10-27: no native patrol classes. Parties exist (ASwtAdventureCharacter.Party, OnPartyMemberDestroyed)
      - a patrol = a temporary party + a route. Needs: patrol goals / events.
      DRAFT DESIGN (2026-10-27, for the operator to adjust - built on what the code research found):
      - A patrol duty picks 2 clanmates (idle, nearest - activities.lua already finds them) as a temporary party
        (ASwtAdventureCharacter.Party) and 3-4 border points along the territory edge (the map's territory volumes;
        fallback: points from config). The cats follow (AI move, brain paused as in activities pairs).
      - At each point: scent-mark (a montage) and a small random event (rival scent -> an encounter, prey -> a hunt
        chance, nothing). Done -> party dissolves, duty done.
- [ ] **6. Combat training with your mentor.** Actual training sessions, not narrated.
      WAITING ON THE OPERATOR: a WON fight in play (the fight's end is counted - VM, fled).
      PREPARED 2026-10-28 (offline): the game HAS a training feature - the Training Grounds popup
      (WBP_GuiPopupTrainingGrounds = UGuiPopupAvailableMoves: learn attack moves from cats - panels General /
      Select / Completed, UGuiControlTrainingOptionCats 3 cats, 4 moves) + NPC training animations
      (A_CatMaster_NPC_Training_Attack / Hit / Stance) + a sparring encounter row DT_Combat_Generator
      "TrainingGrounds" (1 cat, OutOfClans, Tier4 AI, universal attacks 1/7/13/15) that no map places - started from
      code / a quest effect (USwtAdventureStartCombatEffect: CombatTags per rank, applied natively). Plan: a Train
      duty (duties.lua) = a sparring fight with the mentor: find the native "start combat by generator tag" the
      effect ends in (like AddPersonalBonding - by its string / the effect's vtable) and call it with the
      TrainingGrounds tag; win or lose -> EXP + bond with the mentor (bonds.cpp). Needs the VM.
      TRIED ON THE VM 2026-10-28 (no fight yet): (a) the nearest BP_Enemy_Generator_C with bUseQuestCombatTag +
        QuestCombatTags = TrainingGrounds, then OnNotifyInitCombat() - no combat. (b) the combat-type route:
        ESwtAdventureCombatType has TrainingGrounds = 5; USwtAdventureCombatBoxComponent {CombatType +0x568,
        CombatTag +0x56C} starts combat in its OnBeginOverlap UFunction - the world map has NO combat boxes; one
        constructed on the player pawn (StaticConstructObject) + OnBeginOverlap(box, pawn, capsule, 0, false, {})
        runs without error but no combat follows (unregistered component / its owner checked?). [SUPERSEDED - see the later DONE / FIXED] NEXT: disassemble
        that OnBeginOverlap (the class's natives table - the "OnBeginOverlap" string is shared between modules, the
        SwtQuest table is at 0x149ad0b50, find SwtAdventure's) to see its checks and the combat-manager call it
        ends in (USwtAdventureCombatManager, CombatClasses[5] = the training director) - then call that directly.
      SOLVED + BUILT 2026-10-28: the handler (exe 0x1417E1370 = the box's vtable slot +0xA88, reached from the exec
        0x1415FAE80; runtime base in the dump = 0x7FF66A4F0000) checks: OtherActor player-controlled (Pawn.Controller
        +0x2E0), OtherComp == its CapsuleComponent (+0x340), a state flag ([+0x878]+0x110 bit 3) clear, and the box's
        OWNER (+0xA8) != OtherActor - an owner that is a character becomes the opponent - then calls
        0x141803400(player, opponent|null, CombatType, CombatTag). Every earlier try had built the box ON THE PLAYER.
        A box made inside a clanmate (StaticConstructObject outer = the cat) + OnBeginOverlap -> the game's turn-based
        fight opened on the VM (party vs "Tiger", Attack / Rest / Herbs / Flee).
        The Train duty (duties.lua, duties.ini [Train] On = 1, MaxRank = Apprentice, Bond = 2): partner = the story cat
        ...WarriorMoveLearn (the game has no mentor role), else the nearest clanmate; checked with the patrol (hourly /
        sense pulse) within Reach; done at the fight's end (WBP_GuiHudCombatOver_C shown, or the combat manager's
        EndCombat) -> WaCaNative_AddBond(role, Bond). VM: "duties: sparring with the clan's move teacher" -> the combat
        popup. NOT yet seen: the fight's END being counted (the VM can't play the fight out - check in play).
      END SEEN 2026-11-01 (VM): the fight can be ended on the VM by FLEEING (Down x3, Enter - no minigame): Train ->
        next to Gooseheart -> the combat popup -> fled -> 'sparring done - bond with the clan's move teacher +2' ->
        'training done'. Fixed on the way: the teacher pick took a parked Filler copy first (not hidden, far off) - the
        duty waited by it; now the nearest real one. Drop Z:/WaCa/WaCa-mods-test-20261101h. (A WON fight: in play.)
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
        DONE 2026-11-03 (VM, from the log): a skip says what it changed - the season, the weather, how far the main
        story and each pack story moved - and plays as a scene (the world fades out, the card + the summary card, back
        in); WaCa.Emit('SkipDays', n). NOT done (rules for the operator): eating from the pile, duties resolved by
        standing, rank progress during a skip.
      DRAFT DESIGN (2026-10-27, for the operator to adjust - built on what the code research found):
      - A skip = jump DayNight.Day() by N with a full-screen card ("A moon passes...") listing what happened (duties
        auto-resolved by standing, prey eaten from the pile, rank progress) - the card is one of the game's own
        popups re-texted (WaCa.SetText) to avoid new widgets.
      OPERATOR ANSWERS 2026-11-03: the pile is eaten + duties auto-resolve - specifically: a time skip's definition can SET
        a new fresh-kill pile value to jump to (etc.); WARN if a mod puts duties on a time-skip event; the super-basic
        'go hunt' / 'go patrol' duties are SKIPPED when a skip happens.
        DONE same day (VM): [Skip.<Name>] Days / Pile / Card, Skip: step, the hunt / patrol set aside (0 missed), the
        story check warns about duties on a skip.
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
        VM-CHECKED 2026-10-31: the season and weather load with the save (one line, "as saved" - a double roll at load
        fixed), SetWeather Snow / Rain -> the effect on (snow flakes, rain streaks on screen), hunting / fishing factors
        follow (leaf-bare: rain x0.48 / x0.84). Look (flake size, rain density) = the operator's check.
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
        PREPARED 2026-10-28: tools/release_with_content.ps1 -Version X [-Upload] - builds content + native + UE4SS +
        the release zip WITH the pak (checked inside), -Upload replaces the release's zip (gh --clobber). Dry run on
        the VM: built, pak inside. The operator only says "upload" per release (or sets up a self-hosted runner).
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
        (no height jumps > 3 m in 8 checks), stable. TRIED ON THE VM 2026-11-01: preyworld's hide-move-show on a mouse,
        then the scripted pounce - but the same pounce on an UNMOVED mouse fails too (the held crouch doesn't take at the
        VM's frame rate: 'Detected true ... crouched false'), so the VM can't judge it. Open: a moved prey's pounce in real play (operator); habitat per
        species (fish only at water ...) - today a creature stays in its own generator's area, which is its habitat.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - On a timer step per in-game hour, pick a generator in the cat's area and spawn one prey of its kind at a random
        point of its habitat (fish only at fishing spots) - the generator's own spawn function if reflected, else
        SpawnActor of its character class (spawn only 30 s+ after world load - the streaming crash lesson).
- [ ] **24. (Bonus) StarClan guidance leads to prey.** The game's StarClan guidance feature points the player to
      these random prey spawns: hunting by following StarClan's lead. Find how the guidance feature picks its target.
      BUILT 2026-10-28 (experimental, hunting.ini [Guidance] On = 0): the game's guidance = a POI hint area actor
        (BP_POI_HintArea_Quest) at the objective, whose sense-tracked component makes the sense-mode trail (tracked
        from far: a quest hint 7138 away was a candidate). guidance.lua spawns ONE per world (30 s after the HUD - the
        streaming crash) and snaps it onto the nearest prey of PreyKinds between MinDistance and MaxDistance (it
        follows the prey), re-targeted every in-game hour and after a catch. VM: "StarClan points to a Bird 2226
        away"; in sense mode our hint area was a candidate with its tracker, exactly like the game's quest hint. The
        trail's look on screen: the same as the game's quest guidance (neither drew visibly in the VM's camera view at
        480x270 - check in play). Fixed: an hourly re-target could spawn it before the 30 s.
        VISIBLE WAY (2026-10-28): like the scent trail, the game draws trails only for its own quest targets - so at the
        start of a sense pulse StarClan's way is also shown as scent puffs (Scent.Puffs, the effect seen on screen for
        26) from the cat toward the prey, the first ShowLength cm (2500). VM: "StarClan shows the way (8 puffs)" with
        the cat 20 m before the guided mouse (that frame was blocked by a rock - the puff effect itself is the one
        confirmed visible).
        SEEN (04:16): the cat 11 m before the guided prey, sense mode - "StarClan shows the way (4 puffs)" and the
        glowing scent marker on screen between the cat and the prey (paw icon). VERIFIED.
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
      cat assigned yet, filled with a numeric default. [SUPERSEDED - see the later DONE / FIXED] Next: hook the role -> name resolution (find the data table the
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
      SYSTEMATIC 2026-10-31 (operator: "likely dozens or hundreds of broken lines"): the game fills every line with ONE
      function (exe 0x14162A000: {Player} {Friend} {The Traitor} {Clan} + each ENarrativeRole as "{%s}" of its spaced,
      upper-cased name, from THIS save's cast). WaCaNative_FillText runs it on any text: a sweep over all 8901
      string-table lines (RiverClan save, VM) - 1117 name someone, 682 leave a role in braces (roles of other clans'
      stories / not cast yet: generic dilemmas, ShadowClan's "Is that {THE AMBITIOUS APPRENTICE}'s scent?" - the shape
      of the reported "1's"). FIX: Core hooks that fill - a role with no cat shows in words ("the ambitious
      apprentice", capitalised at a sentence start, clans as ThunderClan ...), logged once per role; text.ini [Fill]
      Fallback = 1. Sweep after: 0 lines with a role in braces. Also: {RIVERCLAN MEDICINE CAT} spelling, WindClan's
      broken "how {X}'s death" sentence rewritten. Left to other code (not broken): {N} {M} {S} {H}, ${QST_...},
      {PLAYER ... NAME}. Test drop Z:/WaCa/WaCa-mods-test-20261031j. OPEN: a sweep in a save of each other clan (only
      a RiverClan save on the VM); the operator's own lines seen in play (the detector still logs any).
      COVERAGE checked 2026-10-31: the fill's 10 callers = the conversation text (rich text), the quest-dialogue talker,
      the voice-over timing, the contextual action prompts, the dilemma buttons (GuiButtonDilemma) - the families the
      sweep found broken all pass through it. Other clans' saves: the fallback doesn't depend on the save, and every
      placeholder's spelling was checked against the 104 role names statically (only the ones fixed in text.ini were
      off) - a per-clan sweep would only re-confirm. Remaining: text that never passes the fill (none found).
      OTHER-CLAN SWEEP DONE 2026-11-01 (VM): a ThunderClan cat made through the creator (Sharppaw, slot 1 - main menu ->
      Prophecy mode -> an empty slot -> ThunderClan -> creator -> name (Enter into WaCa's box, Enter again) -> traits
      -> the story). Its sweep: the game alone leaves a role in braces in 752 lines (RiverClan: 682 - the shared side
      stories' roles aren't cast early in any clan), as shown 0 - the fallback covers both clans. Polished: a role
      spoken TO goes without its article ('Thank you, resentful elder.' - was 'Thank you, the resentful elder.').
      Drop Z:/WaCa/WaCa-mods-test-20261101f.
      - Done part: misspelled placeholders fixed (text.ini [Placeholders]); the in-play detector names any other
        unfilled line - its fix is one text.ini line each once seen.

## P2: Depth, presentation
- [ ] **Gatherings** (operator 2026-10-28, big feature; mostly GROUNDWORK + modding tools now - it ties into the story
      WAITING ON THE OPERATOR: the story beats (the groundwork, travel, other Clans, the stay-behind raid are built + VM-verified).
      rework). Every N days (the story defines it) the leader picks who goes to the Gathering. Both outcomes are story:
      - chosen: the Gathering itself (scenes);
      - not chosen: what happens at home - e.g. rogues attack the camp while the others are away and your
        warrior-rank cat organises the defence: big accolades, points toward becoming deputy with the leader;
      - success / punishment as in the books: a choice in the main story (leaving the rogues alone - a forced choice -
        or facing them alone whatever you do) angers the leader: irresponsible -> not allowed to the next Gathering.
      Needs: story variables (leader favour / anger, bans) settable by scenes and read by conditions; the leader's pick
      from standing + those variables + the story's override; scene hook points for announce / chosen / not chosen.
      GROUNDWORK BUILT 2026-10-28 (gathering.lua, gatherings.ini, off; story variables in events.lua: Set / Add / If
      steps, Events.Var / SetVar / Check / Provide, kept with the save; clanevents Require): every Every days (or the
      story's Gathering = Yes) the leader announces at the AnnounceThird's start (ClanThirdStart hook), the pick =
      the story's GatheringPick, else never while GatheringBan > 0 (each missed Gathering takes one off) / below
      MinRank, else Base + PerStanding x standing + PerFavour x LeaderFavour %; back in camp in the Third: [Attend] /
      [StayBehind] scenes (Hook: GatheringAttend / GatheringStayBehind). Gathering.Chosen / Count for the story's beats.
      Offline: chosen -> attended, Count 1; GatheringBan 1 -> not chosen -> stay behind (+3 favour in the test scene),
      TRAVEL DONE 2026-10-31 (VM, with the walkers' mover - the AI walks fail on this map): gatherings.ini [Travel]
      Party / Place (I- = the Island: the game's zone trigger, Duties.ZonePlace - its only trigger is a thin gate box) /
      Stay; picked -> Party cats walk with you (Walkers.Escort); left behind -> they walk to the Island, stay, come home
      (Walkers.Patrol opts.stay); event GatheringTravel(chosen) for story mods. VM: Blackpool, Ridgewing, Pinepelt
      135 m to the Island and back (ground followed), 'the Gathering party is back'. Test drop
      Z:/WaCa/WaCa-mods-test-20261031k. Still open below: the Gathering's own scene / place at the Island.
      SCENE (library exercise, 2026-10-31, VM): the example story pack's [Attend] plays cutscene GatheringNight at
      Place = Zone:I- (new: the game's zones as cutscene places, WaCa.ZonePlace in Core). Rough edges it found and
      fixed in WaCa Cutscenes: a far place's ground isn't loaded (your cat goes there first, the scene starts after);
      the Island's zone marks its shore (the middle moves to open ground 3-10 m round it); the cats' name plates showed
      (hidden while a cutscene plays). Lionstar speaks to the cats on the Island's grass. Test drop
      Z:/WaCa/WaCa-mods-test-20261031l. OPEN: the other Clans' cats at the Gathering (their cats aren't in the world
      away from their territories - the Gathering would need to bring some in).
      OTHER CLANS DONE 2026-10-31 (VM): a RiverClan save holds only its story cats + ThunderClan's leader / deputy as
      DATA (NPCData.NarrativeRoles - the look's text form); the game's cutscene stand-ins outside a scene sit in an
      unloaded sublevel (can't move / draw). So: WaCa.SpawnCat spawns the game's cutscene cat class and ImportLook dresses
      it from that text (FProperty::ImportText + the game's rebuild); WaCa Cutscenes' cast Clan:<Clan>[.<Part>] brings
      one in (the save's story cat, else one made up from the save's cats, a name of its own) and removes it after.
      The Island Gathering: Sunstar (ThunderClan), Pebbleface (ShadowClan), Leopardsong (WindClan) sat with the
      RiverClan cats; none left after. Test drop Z:/WaCa/WaCa-mods-test-20261031m.
      ban cleared. OPEN: the 10+ cats travelling to the island (follow.lua Follow.Travel - see Following), the
      Gathering's own scene / place.
      BIG PARTY + STAY-BEHIND STORY 2026-11-01 (VM): the Gathering's trip takes the leader, deputy, medicine cat and named
      warriors too (plain warriors alone were 3 of the RiverClan camp; queens / kits / elders stay), in a ring round the
      place (12 cats within 3 m, 1.5 m apart - not a 13 m line into the lake). VM: Party 12 -> 8 (every eligible camp
      cat, Lionstar too) hid on the way, reached the Island, stayed, set off home. New event GatheringEvening(chosen)
      plays the evening's scene. Library exercise - the example pack's [StayBehind] = a rogue raid: cutscene RogueRaid
      (WaCa Cutscenes' new cast Rogue / Rogue:<Name> - clanless cats brought in), LeaderFavour +2, DefendedCamp = 1. VM:
      Slash and Ripple faced Dapplepatch, Spikebranch, Lionstar; lines, growl, hisses; rewards set. Seen on the way: a
      Lua hot reload (UE4SS reloads a mod whose files change) mid-trip leaves walkers stranded hidden - dev-only (a
      player doesn't swap Lua files mid-game). FIXED 2026-11-02 (the story check's Watch made it a writer's case): the cats away are
      put back home when Clan Life starts again (Saved/WaCaWalkersAway.ini; VM: a reload mid-lead -> put back home). Also found + fixed: an intermittent START-UP CRASH in WaCa Core's bridge
      (events delivered while UE4SS still started mods - now held until loading is quiet; ~8 clean boots by
      2026-11-01 04:10, no crash report since 00:27 - at the old ~2 in 15 that's encouraging, not yet proof).
      STRESS 2026-11-01 (VM): 6 boots in a row - each up, a command taken, no crash report - ~20 clean boots since the
      fix (incl. the stricter hold + states mutex of 06:30); at the old ~2 in 15 that would happen ~6% of the time by
      luck. Also: every montage call now null-safe (WaCa.PlayMontage / StopMontage). Drop ...20261101j.
      Drop Z:/WaCa/WaCa-mods-test-20261101b.
- [ ] **Mod stories (story packs)** (operator 2026-10-28): a mod can define its own story, like picking a clan's.
      - a pack declares itself (name, clan, required rank range, entry) and owns its days / beats / dialogue / quests;
        shown in the quest list as a story quest;
      - CONNECTED mode (the 1:1 cat link: two packs on one cat): a pack that declares the clan + rank it runs at can
        run alongside the main story on the same cat; otherwise standalone;
      - SYNC POINTS: a pack names the main-story milestones it must reach first (all of A's kit missions before the
        main story makes you apprentice); before main progress crosses one with a pack behind: "You are about to
        progress the main story. It is highly advised you finish [Mod A story], [Mod C story] before continuing, to
        avoid continuity errors.";
      - SUMMARIES: every pack beat can carry an optional Summary; crossing a sync point anyway shows the skipped beats'
        summaries ("what happened meanwhile") and the pack jumps to its sync point.
      Groundwork that exists: story days (days.lua), story variables + conditions (events.lua), scenes, the clan loop
      hooks. Needed: packs as units with their own story-day counters; a hook on main-story progress (the quest
      system: rank-up / quest completion) to warn / skip; a quest-list entry (research the quest HUD).
      DESIGN (2026-10-28, with the operator - "a mod story longer than the main story"):
      - THREE CLOCKS: the CALENDAR (the world's day count - seasons, weather, moons, Gathering dates; one per save);
        the MAIN STORY's position (story days that move on their Advance, else repeat); each PACK's own position
        (its own [Day.N] + Advance). Story days are positions, not dates - a longer pack just takes more calendar days.
      - <Mod>/content/story.ini: [Story] Name / Clan / Ranks / Mode = Connected; [Sync.<Name>] Main = Rank:X |
        Quest:<id> | MainDay:N, PackDay = N, Hold = Warn (default) | Gate; [Day.N] as days.ini + Summary.
      - pack behind at a sync point: Warn = the warning, crossing anyway jumps the pack to PackDay and shows the
        skipped days' Summaries; Gate = the main story's Advance also needs the pack there (its last day repeats as
        plain clan-loop days). Pack ahead: it holds (its sync day repeats: clan loop + its dialogue pools). Pack past
        the main story's end: the pack owns the story.
      - one calendar day, both stories: beats main first, then packs by declared priority (not load order); a
        third's task = the main story's, unless a pack declares Owns = <Third> in its sync window (two packs claiming
        it = a reported conflict); season / weather forced only by the main story (packs' requests apply otherwise);
        dialogue Days ranges resolve against the OWNING story's clock.
      - open questions for the operator: Warn or Gate as the default; on a skip, replay the skipped beats' story
        variable changes (Set / Add) or only show the summaries (replaying keeps later conditions consistent).
      REFINED (operator 2026-10-28: "each story its own independent day counter and progress condition - if not met,
      the previous day repeats for this story - with fixed sync points"):
      - every story is evaluated at the same calendar boundary against its OWN Advance; stories never read each
        other's day numbers;
      - sync points are NAMED (Sync.Apprentice ...), declared by their owner; each story says at which of its days it
        reaches one - renumbering a story doesn't break the others;
      - a sync point is a BARRIER: a story that reaches it repeats its sync day until every story that DECLARES that
        sync point is there, then they cross together (symmetric - nobody is "the long one");
      - the game's own main story (its quests / rank-ups) can't be held: against it the barrier is soft - the
        warning + summaries; between our stories (packs, days.lua's story) it is hard;
      - NO repeat limit (operator 2026-10-28: "if Mod A adds 20 days of apprentice story but mod B adds 2 and then 10
        of warrior, repeating B day 2 18x is fine") - a long wait is the normal case, not an error. Instead (LOW PRIO, operator) a STORY
        FIXER screen for a genuinely stuck story: every active story's day, what its Advance waits for, its next sync
        point; skip forward (with the summaries) or rewind a day, by hand;
      - the MAIN STORY needs small changes so it never continues on its own: forced steps ("go to camp after reaching
        lvl 11") become player-started ones ("reach lvl 11 > speak to the leader") - the sync-point warning then
        shows at that conversation, before anything moves;
      - QUEST CHOICE: when two quests / stories both need the player to speak to the same cat, speaking to it offers
        the choice which one to advance;
      - calendar things (seasons, moons, Gathering dates) stay on the calendar; a story waits for them with a
        condition (Require = Gathering.Today = 1).
      BUILT 2026-11-02 (WaCa Clan Life days.lua, content/story.ini): a pack's own story - [Story] Name / Priority, its
        own [Day.N]; its own day counter and Advance (+ new Advance = If: <conditions> for every story); a day with
        Sync = <Name> is a hard barrier between our stories (the refined design: symmetric, no repeat limit); beats after
        the main story's by Priority; every story's day + seen beats in the save's WaCaDays sidecar; the story check
        reads each pack's story.ini on its own; WRITING.md 7b; the example pack's 'The herbalist's lessons'. Offline
        (lupa): the sync wait + crossing together; VM: separate counters / repeats, the pack alone moving on, the sidecar.
        (a) DONE 2026-11-03 (operator: Warn) - [Sync.<Name>] Main = Rank:<Rank>: the warning when the game's rank-up
        quest comes, the jump + Summaries at the promotion; both seen via the game's own functions (see below). Replaying
        the skipped beats' variable changes: not built (operator's call); (b) DONE same day - Owns = <thirds> + <Third>Duty (VM: the example owns the Morning, HerbRound); (c) a quest-list
        entry for a pack's story - DONE 2026-11-03 (operator: display-only line WITH detail - WaCa.QuestLine, VM-verified); history: a step DONE 2026-11-02: a day's Goal shows as the story's own
        HUD panel (VM-seen); the game's quest list itself - RESEARCHED same day,
        OPERATOR'S CALL: the pause menu's QUEST tab (UGuiPausePanelQuest) has a main and a side list (UGuiIListItemsQuest,
        pooled WBP_GuiItemQuestPause entries) fed natively from ListQuestsStruct = TArray<FQuestStruct { UQuestBase*,
        UQuestLine*, UQuestLineNode* }> - the quest manager's real quest objects (UQuestManager.Quests), which the game
        saves and ticks. Options: (1) a REAL entry = constructing UQuestBase / UQuestLine objects into the quest
        manager - selectable, the detail panel works, but a made-up quest inside the game's saved quest state risks the
        saves; (2) a DISPLAY-ONLY line = a copy of an entry added to the side list after the game fills it - safe, but
        not selectable (navigation is native over ListQuestsStruct). The HUD panel above already shows the story; (d) the STORY FIXER screen (low prio, operator).
      OPERATOR ANSWERS 2026-11-03: (c) the QUEST tab = a DISPLAY-ONLY line WITH its detail panel ("this shouldn't be too
        hard") - the pack story in the side-quest list, and selecting it shows its detail; (a) sync with the game's own
        story = WARN (the warning before the game's story moves on; crossing anyway jumps the pack, summaries shown).
      (c) DONE 2026-11-03 (VM): WaCa.QuestLine (Core questlines.lua) - the pack's line in SIDE QUESTS, the mouse over
        it shows its goal + Place on the detail panel (Clan Life days.lua; SetPackDay to put a pack on a day). Not tried
        yet: a save with side quests of its own (the keep / put-back path). (a) WARN DONE 2026-11-03 (VM): [Sync.<Name>] Main =
        Rank:<Rank> - warning card when the rank-up quest comes, jump + 'meanwhile' Summaries when it happens (or on a save
        already past it). SEEN LIVE 2026-11-03 13:50 (save backed up + restored): the game's own QuestManager:StartQuestOfTag(
        Quest.Procedural.Progression.RankUp3) -> the HUD's real OnQuestAdded -> 'the game added a quest that makes your cat
        Leader' -> the pack warned; the card waited behind the game's conversation it opened. (Levelling to the cap
        gives no rank-up quest - they come from QuestLine_Main.) THE CROSSING SEEN TOO (14:20, save backed up + restored): the game's own
        OnPlayRankUpSequenceFinished on the RankUp3 task -> Core 'your cat's rank: Leader (promotion)' -> 'the game's story
        passed HerbalistsLessons (rank Leader, promotion): day 1 -> 3, 2 summaries' -> the 'meanwhile' + summary cards.
        Only Rank:<Rank> so far.
- [ ] **Story packs: standalone starts + writer-friendly authoring** (operator 2026-10-28, note for later): a mod story
      played with a NEW cat defines its entry point - e.g. a warrior start: "level 8, warrior, main story day 13" -
      and the creator must respect it: a warrior start picks a WARRIOR name at character creation (not a kit /
      apprentice name), and the story may start with someone already in the party (an apprentice). GOAL: the fandom
      has many talented writers - writing a story must be easy with little or no programming: plain files (the scene
      steps, days, dialogue pools as they are), good docs + examples, clear errors (a story checker that lists
      unknown roles / dialogue ids / broken conditions), maybe later an editor.
      STORY CHECK BUILT 2026-11-01 (VM, Clan Life storycheck.lua): at the start every story file with every mod's
      content is read as the scenes will be - unknown step kinds, cutscenes nobody defines (Cutscenes publishes its
      names), roles with no cat, unreadable conditions, variables nothing sets - log + Saved/WaCaStoryCheck.txt + a line
      on screen. VM: a test pack's 5 mistakes all reported; the shipped content clean. Found + fixed on the way: steps /
      day beats past 9 were silently dropped. Still open here: standalone starts (a creator entry point) and an editor.
      EDITOR, FIRST STEP 2026-11-04: tools/new_pack.ps1 (WaCa Clan Life) makes a working pack (role, meeting event, cutscene,
      murmurs, all commented) - VM: generated + played (Shadowheart). A visual editor stays future work.
      + tools/check_pack.py (2026-11-04): proofreads a pack offline (steps, beats, shots, roles, Reach:); found the example's
      missing S:apprentice newcomer event (added) and led to the Newcomer step waiting for its role (VM).
      + THE EDITOR (2026-11-04): tools/pack_editor/pack_editor.html - open a pack folder, edit events / cutscenes /
      murmurs / cast, live check, save only changed files (comments kept). Node + headless-Edge tested, incl. the page's
      own open / edit / save on an in-memory folder (test_page.py: one line changed, endings kept); only the native
      folder dialog itself is untested = the operator's first real try.
      STARTS BUILT 2026-11-01 (VM): a pack's content/start.ini [Start] Day / Level / Name = Warrior / Step1.. for a NEW
      cat only (level 1, no rank quest; an existing cat is recorded skipped): story day, level via the game's EXP one
      level-up at a time (WaCaNative_LevelInfo), steps, and Looks' name box asks for the whole warrior name (no kit
      suffix). VM: new ThunderClan cat EMBERHEART (slot 2) - box label, level 8 / 143 HP, the card. NOT possible yet:
      a start RANK (native quest data); Day needs story days on. PARTY added later the same day (Party = <roles>, VM ok).
      DAY VERIFIED (VM, story days switched on for the test): slot 1 (Sharppaw, level 1) -> 'story day 13 (the story
      pack's start)', the save's WaCaDays sidecar Day = 13, WaCaStart Applied = 1; days.ini put back (On = 0).
      START RANK - OPTION FOR THE OPERATOR: rank = the rank quests turned in (WaCa.PlayerRank); UQuestBase.QuestStatus is
      reflected (+0x2D5, 4 = QuestTurnedIn), so a start could mark Quest.Rank.N turned in. It would SKIP those quests'
      rewards, rank-up sequences and their place in the game's quest chain (the main story could stall or jump).
      Decide: should a warrior start skip the game's apprentice quests (and accept that), or stay rank-less?
      Example pack ships start.ini Off. Drop Z:/WaCa/WaCa-mods-test-20261101r. Still open: an editor.
      Drop Z:/WaCa/WaCa-mods-test-20261101m.
- [ ] **P1: Party members follow you as you roam the forest** (operator 2026-10-30) - BUILT + VM-tested 2026-10-30
      (Clan Life walkers.lua [Party]): the PARTY page's cats (Nightheart, Rippleface) leave camp with you, run alongside
      (0.8-1.1 m on the VM), catch up when 25 m behind / stuck, hold while you sneak, walk back to their spots in camp;
      hunt comments come from them. Camp story cats have no AI/movement (an AI move crashed the game), so the walkers'
      swept mover carries them. Fixed on the way: Clan Life's camp state stuck after a teleport in (no CampLeft);
      os.clock() is CPU time (2-9x the wall) -> Core WaCa.Now() everywhere.
      DONE since: (a) the party comes from the save (WaCa.PartyRoles: QuestProgression <chapter>.PartySetup roles -
      RiverClanKit = Nightheart, RiverClanWarriorSideRace = Rippleface), no pause menu needed (VM); (b) fights: the party
      waits while the combat manager has an enemy (it had been teleported into the arena) and is back beside the cat
      after (VM).
      STILL OPEN: (c) the VM camera sits 1.1 m behind the cat - check the formation on the operator's camera (Distance /
      Side in walkers.ini); (d) PartySetup by "latest chapter key" - check once a save has a second chapter.
- [ ] **Roles and the cast** (operator 2026-10-28, short / medium term goal):
      - SHORT: mods can add new cat roles. ROLES ARE COMPOUND KEYS (operator 2026-10-28, instead of patching the enum -
        which IS possible: UE4SS UEnum::InsertIntoNames, the role a uint8 up to 254; dropped as the riskier path):
        "E:<name>" = the game's ENarrativeRole (its tables / bonding / parties know it), "S:<name>" = a mod's string
        role, BOUND to a real cat (a generic clanmate or one we spawn) - only our layer knows it. A bare name = E.
        BUILT (events.lua): Events.BindRole("S:x", cat), Events.Role(key) -> kind, name; Events.Who resolves both
        (every scene "@ who"). S roles in dialogue DONE 2026-11-04 (VM): {S:loner} / {Leader} / a name in any of our
        lines (cards, murmurs, patrol lines, cutscene lines) = the cat's name, and Say: S:loner = ... as a speaker.
        Bonding / parties: a clanmate playing a role IS the game's cat (its bonding and party already work); a cat
        brought in per scene (Rogue:, Clan:) lives only in its scene - whether it should bond / join = operator.
        For the GAME to take compound roles, every ENarrativeRole read path needs a survey + patch (operator). Scope
        from the reflection dump (2026-10-28): the uint8 narrativeRole field in 10 classes (QuestBaseActor ...),
        FCharacterNarrativeRoleStruct (narrativeRole + characterTag: OptionAlly, ForcedParty ...), the maps
        IconicSkeletalMeshMap / NarrativeCustomDataMap, NarrativeRoleA-D, the UFunctions UpdatedRole / UpdatedClan,
        data-table rows carrying those; plus the NATIVE readers of the byte (switches, lookups) - only disassembly finds
        those (the enum's users: functions taking / comparing the role byte near its struct offsets).
        SURVEY (2026-10-28, a Sonnet research agent, static only - report scratchpad/enum_survey.md; the loop bound and
        the name lookup spot-checked by hand): every native role->text path goes through ONE lookup - the ENarrativeRole
        UEnum (cached global 0x14A8B6FD0) + UEnum::GetNameStringByValue 0x141C14B20; 26 functions use it: the save
        (NPCData/NarrativeRoles 0x141949ee0, Unlocked 0x1416a69b0 / 0x1416a731c, Party/Stats 0x14180f80e), bonding
        (AddPersonalBonding / Get 0x1416a0ef0 -> "Bonding/<name>"), reward keys, combat character tags, a "%s.%s.%s.%i"
        key builder (0x141815bdb, role via the actor's vtable+0x398 - probably the monologue key). THE SAVE STORES ROLE
        NAMES: a value with no name is dropped on save; an unknown name loads as None. Exactly THREE hard loops
        "cmp ebx, 0x68" (104 = the enum's count) won't see new values: 0x14162A64A ({role} text expansion),
        0x141798F1C, 0x1419353A1 (RoleFromName 0x1419352c0 - name -> value on load; the one that matters).
        RECOMMENDED: EXTEND the enum (UEnum::InsertIntoNames before the save manager loads; names like
        S_warrior_otterstream, values 105+) and patch the three bounds (imm8: 0x7F = ~21 custom roles) or detour
        RoleFromName to GetValueByName - then save, bonding, party stats and the key builders work unchanged; "S:" stays
        our layer's identity, mapped to the value. Dialogue then = string-table rows for the new name (clone a donor's).
        OPEN: Blueprint bytecode readers, the per-role DataTable (FSwtQuestNarrativeRoleStruct rows - which table), the
        other two loops' purpose, InsertIntoNames on this build's UEnum layout, ImportText of unknown names.
      - MEDIUM: every role becomes a FIXED cat (name + look): stories reference roles ("mentor"), a CAST file binds
        them ("mentor = Greystripe", his look - looks system / roster.lua) - a translation / setup swaps the cast, not
        the story. A CLAN SNAPSHOT = a cast file per book start (which book: undecided): every cat of the clan as it is
        then, the game's roles mapped onto them, the rest as mod roles bound to generic clanmates - the whole clan in.
      - DISPLAY: a role can hide itself - "warrior_1" cast as Silverpelt shows "Silverpelt\n[Warrior]" (name + rank);
        a lore mod's custom role "warrior_otterstream" shows as "Warrior": characters kept apart and tracked while the
        game's own rank system is honoured.
      RESEARCH first: how generic clanmates get their names and name plates; whether we can place extra cats or only
      re-cast the ones the world spawns.
      ANSWERED 2026-10-31: extra cats CAN be placed - WaCa.SpawnCat (the game's cutscene cat, dressed from any look's text
      form, e.g. the save's other-Clan story cats; no AI, no name plate); VM: three other-Clan cats at the Island.
      LIBRARY EXERCISE 2026-11-01 (VM) - a loner visits the camp: [Cast] S:loner = Rogue:Quill (new: a role played by a
      cat brought in per scene - Clan Life publishes roles.specs, Cutscenes spawns it), cutscene LonerVisit (Facing:
      Leader + you vs S:loner), a clan event setting SawLoner, the pack's LonerTalk murmurs. Rough edges found + fixed:
      the spawned role had no way in; murmurs' {LEADER} missed Lionstar (giver role) -> 'our leader' in lowercase -
      now Events.Who + a capital. Drop Z:/WaCa/WaCa-mods-test-20261101k.
- [ ] **Fresh kill without hunger** (operator 2026-10-28, future work): as the original hunger system goes, remove the
      WAITING ON THE OPERATOR: talking to the pile's cat in play (the deposit is VM-verified).
      "putting fresh-kill on the pile" screen - or at least force depositing EVERYTHING in the inventory at the pile -
      so every day is fresh. (The clan loop's hunt turn-in is the pile contribution: UWrcAchievementsManager
      OnContributeFreshKill.)
      FOUND 2026-10-31: the pile screen (UGuiPopupFreshKill: an inventory grid, CurrentItem, two command buttons)
      opens through a DIALOGUE action (UAdventureDialogueActionFreshKillPile - talking to the pile's cat, Mossfeather /
      BP_Quest_Giver_FreshKill_C); the inventory (USwtQuestInventoryComponent / USwtAdventureInventoryComponent /
      UWrcInventoryComponent) has NO reflected functions or fields - native only. VM: E beside the pile cat reaches the
      HUD (Player_Interact 65) but no conversation opens (as every NPC talk on the VM). NEXT (native, Core): find the
      inventory's item store and the screen's contribute call (its command buttons -> the grid's CurrentItem) and
      deposit every fresh-kill item when the pile screen opens; testable end to end only in the operator's play.
      DONE 2026-10-31 (VM) - no inventory RE needed: the pile screen is driven with its OWN commands. WaCa Core
      WaCaNative_OpenPopup(screen, 86) opens it as the dialogue's create-screen action does (screen vtable +0x5D0) - for
      testing; the screen's command handler (exe 0x1418f5f70): ShoulderL/R (TriggerL/R) -1/+1 on the amount (+0x588),
      capped by what you carry (+0x590) and the pile (+0x598, points per item +0x58C); Button_Confirm (26) gives. WaCa
      Hunting [Pile] Deposit = 1 (default) / Close: on the screen opening, each kind's amount raised till the game stops
      it, then confirmed. VM: pile 69 + 8 rats carried -> 'on the pile: 8 Rat Fresh-kill (+32 pts) - the pile: Full'
      (100). Test drop Z:/WaCa/WaCa-mods-test-20261031g. OPEN for the operator: in play by talking to the pile's cat
      (the VM can't talk to NPCs), and whether the screen should also skip itself (Close = 1).
- [ ] **Cutscenes from text** (operator 2026-10-28: "what a writer would need to truly build their own story"): a mod
      defines a cutscene in plain text, with prebuilt configs:
      - SHAPES: named, premade cat arrangements - e.g. "two sides facing: side 1 = cat1 + player, side 2 = cat2, cat3,
        cat4" - the writer only fills the slots with roles (the cast);
      - TYPES: the game's own cutscene kinds turned generic - a clan meeting, an apprentice ceremony (single / dual /
        triple), ...;
      - PLACES: named locations where a shape can play out - "RiverClan camp clearing", "hunting location 1" ...;
      - ACTIONS on a timeline: "look at: cat4", "say: cat2 line 1", emotes / animations ("cat3 bristling"), "walk in"
        for any cat with delays (two groups walking in to face each other);
      - CAMERA: simple named moves - "sweep above", "look at <cat>", "portrait shot player" ...
      The format must be standardised (this sketch isn't). Sketch:
        [Cutscene.RogueStandoff]  Shape = Facing_1v3   Place = RiverClanCampClearing
        Side1 = player, S:mentor   Side2 = E:RoguLeader, S:rogue_1, S:rogue_2
        At0 = WalkIn: Side2   At2 = Camera: SweepAbove   At4 = Say: E:RogueLeader "You're on our land now."
        At6 = Emote: S:mentor Bristle   At8 = Camera: Portrait player
      and played from any scene: "Cutscene: RogueStandoff" (a new events.lua step, waiting for its end).
      RESEARCH: the game's cinematic dialogues place cats on TEAM SPATIAL POINTS (USwtQuestTeamSpatialPointComponent
      TeamActorMain / Left / Right, LookAtPercentageOffset) and SwtSequencerManager binds actors into level sequences
      (AttachBoundActorToParentAnchor, SequencerStarted / Finished) - the shapes may map onto those; the game's camera
      actor (ASwtAdventureCameraActor), montages (SwtPlayMontageComponent) and emote animations for the actions; the
      cast (roles) for who stands where.
      PRINCIPLE (operator 2026-10-28): REUSE as much as possible - maximum freedom from what's there, mixing and
      matching the game's standard pieces; no 3D work. INVENTORY (tools/cinematic_catalog.py over dumps/files.txt -
      local output, asset names stay out of git): 125 level sequences - LS_Cinematic_RankUp_* (35: ceremonies per clan
      / rank), ProphecyIntro / Closure (32: clan meetings), Quest_SandboxG_EstablishingShot (camera), Quest_TalkToNPC
      (two-cat talk framing), Combat_End win / lose / flee, Gameplay_SneakAttack; 149 cat montages (hiss, warning
      growl, surprise, sleep, play, dig, win / lose, tail pose ...); 246 cat animations (15 photo-mode poses, idles,
      sit / sleep in-out, walk incl. crouching / backwards, run, drink, play, Creating_Memories - likely eating /
      sharing tongues). First types to build: ceremony (RankUp re-cast), clan meeting (Prophecy re-cast), two-cat talk.
      BUILT 2026-10-30 as its own mod (operator: "start building our cutscene toolkit as its own mod"):
      C:/Projects/WaCa-Cutscenes (local repo, no remote yet - commit 27b67d2), WaCa Cutscenes 0.1.0. The format
      standardised: [Cutscene.<Name>] Place / Shape / <Group> = cast list / BeatN = <s> <Action>: <who> [= <what>]
      [~blend]; shapes.ini (Facing, Circle, Line, Pair, Meeting, Ceremony - writer-extendable), places.ini, cast by
      part (your cat fills the rank it holds), beats WalkIn / Walk / Place / Look / Pose / Say / Card / Camera / Fade /
      FadeIn / Emit / End on game time; camera = a spawned CameraActor (Wide, High, Orbit, Portrait, Over, Two, Game),
      traced clear of rocks; the shape is fitted to the ground (turned / brought nearer; no marks in rocks or WATER -
      the floor type); subtitles = the game's centre card with its swirl hidden; events PlayCutscene /
      CutsceneStarted / Queued / Ended. Clan Life: the scene step Cutscene: <name> (commit 9352bc5); walkers and cards
      hold while one plays. VM 2026-10-30: five batches in the RiverClan camp - all of the above seen in the log and
      in screenshots.
      FOLLOW-UPS: (a) DONE 2026-10-31 (rises 1.5 / 3 m per direction before pulling in; VM: turned 110 deg + 3 m higher at
      the Leader's den, full 7.7 m) - was: the camera in tight spots (riverbank under tree roots: Wide pulled in to 1.7 m) - rise instead of
      shortening, or pick the open side; (b) game cinematics (LS_Cinematic_RankUp_* re-cast) as a shot type;
      (b) FOUND 2026-10-31: the ceremonies are sequence dialogues by tag (Gameplay.Narrative.RankUp.<Clan>.<Rank>, in
      events-dialogues.txt); PlaySequenceDialogue(tag, npc = Spikebranch, player) opened WBP_QuestGiver_Dialogue3_C but no
      level sequence played and nothing advanced it (confirm / back) - the ceremony needs the rank-up objective's
      context; the save's rank quests were untouched (backup Z:/WaCa/SaveGames-before-ceremonytest-20261031). Re-casting
      = native work on how the RankUp objective starts its sequence and binds cats (team spatial points
      SetTeamActorMain / Left / Right look like the cast handle).
      ENGINE PATH WORKS (2026-10-31, VM): the ceremony is a plain level sequence - LS_Cinematic_RankUp_ButLeader (+ per
      clan _C<Clan> and per shot _S* subsequences; 35 assets) - and the engine's own LevelSequencePlayer.Create +
      Play runs it from Lua (2400 frames; the view cut to its camera, dark: its cameras sit at the sequence's origin).
      [SUPERSEDED - see the later DONE / FIXED] NEXT: anchor it the game's way (USwtSequencerManager ParentAnchor / AttachBoundActorToParentAnchor - an actor at
      the camp's ceremony spot), list its bindings (MovieSceneSequence FindBindingsByTag / the director's
      SequenceEvent entry points) and bind our cast with ALevelSequenceActor SetBindingByTag - then a Cutscenes shot
      type 'Ceremony'. Save untouched by the test.
      Tried: setting the sequencer manager's ParentAnchor (normally Actor_2147475258 in the persistent level) to the
      player before Play - still black: the game attaches bound actors from its own director events while it plays
      the sequence through its manager; a free LevelSequencePlayer isn't anchored. Next: find what places the game's
      own ceremony (the RankUp task's native start) or move the LevelSequenceActor's transform origin (sequence
      'transform origin' override on the actor) to the camp spot.
      Tried too: the LevelSequenceActor's transform origin (bOverrideInstanceData, DefaultInstanceData.TransformOrigin)
      at the cat - still black: the cameras live in the per-shot subsequences, bound / spawned through the game's own
      start (director events, the manager). Needs the native trace of the RankUp task's sequence start + bindings.
      The game was restarted after the tests (a clean sequencer manager).
      NATIVE TRACE (2026-10-31): the RankUp task (UQuestObjectiveRankUpTask, vtable 0x149aa0388 in the dump's exe) has
      its own slots +0x2b0 / +0x2b8 / +0x2c8 / +0x2f8 (vs the camera-sequence task's). +0x2c8 (0x1416edab0) = its start:
      the player's rank (0x1416ae290) below the task's Rank -> an achievement by name ("OnBecameWarrior" ..., the
      achievements object's vtable +0x3a8), SET THE RANK (0x1416ae100(rank)), complete (+0x2f8), 0x141660c80. It
      plays NO sequence: the ceremony comes from ASwtQuestGameplayGameState::OnQuestStatusChanged (the quest done) ->
      the sequencer (native) -> OnPlayRankUpSequenceFinish(sequenceId). [SUPERSEDED - see the later DONE / FIXED] NEXT: that handler's native body -> the
      sequencer's play-by-tag call (RegisteredSequences by ESwtEngineSequencerType) and its bindings; call it with our
      cast. Never call 0x1416edab0 itself - it promotes the player.
      (b) DONE 2026-10-31 - the ceremony as a cutscene type, VM-verified end to end. Native: the game state's rank-up
      start (0x1418a8390, the func that binds &ThisClass::OnPlayRankUpSequenceFinish) builds a params block (+0x08 music,
      +0x18 rate, +0x28 TMap<FName, weak actor> replacements - passed empty, +0x7C type 3, +0x80 tag
      Gameplay.Narrative.RankUp.<Clan> / .Leader) and calls the sequencer manager's vtable +0x330 with a 'started'
      delegate it EXECUTES (an unbound one = null read 0x1412b7646 - crashed once). WaCa Core: WaCaNative_PlaySequence
      (sequences.cpp; our delegate = a copied weak-lambda vtable with Execute a no-op - the game's would wire the
      promotion) and WaCa.CopyLook(to, from) (SetDefaultCustomData with another cat's data). The scene's cats are
      stand-ins (WrcCatSkeletalMeshWithCustomization: Clan, GiverRole, Index), dressed by the game at each start (so
      nothing to restore). WaCa Cutscenes: Scene = RankUp / RankUp.Leader + <Job>[.<n>] = <who> (scenes.lua), stand-ins
      re-dressed on the game's look builds (CatLookPart), start = the skip prompt, end = OnSequenceFinished. VM: the
      [Cutscene.Ceremony] example (Leader = MedicineCat) - Freezesong leads the RiverClan ceremony; ends with the scene;
      rank unchanged (3). Test drop Z:/WaCa/WaCa-mods-test-20261031e. NOT YET: RankUp.Leader (Moonpool) only by
      reading - untested; the replacement map's use (ActorsReplaced stayed empty - possibly for spawnables only);
      Prophecy (clan meeting) scenes are the next type (Gameplay.Narrative.Prophecy.*, the same play).
      MORE 2026-10-31 (VM): RankUp.Leader (the Moonpool circle, your cat with a StarClan cat) and Prophecy.Closure.<Clan>
      (the StarClan line-up) play placed through the same call; Scene = Prophecy.Closure added (jobs StarClanAncestor,
      Manifestation.1-3 - a job falls back to any clan's stand-ins; dressed Freezesong + your cat, VM); each scene
      passes its own music (mus_cutscene_rankup_<Clan> / _leader, mus_moonpool_a - as the game; Music = to change;
      not audible on the VM). Test drop Z:/WaCa/WaCa-mods-test-20261031f. Prophecy INTRO scenes: not found in the
      game state's start (only Closure) - the intros are sequence dialogues (events-dialogues.txt).
      CORRECTION + DONE 2026-10-31 (VM): Gameplay.Narrative.Prophecy.Intro.<Clan> IS a registered sequence (type 3) - it
      plays placed (the leader by the river, a StarClan spirit, the leader by the stone): Scene = Prophecy.Intro added
      (no music: not in the traced start; Music = to set one). RankUp.Leader run AS A CUTSCENE: MedicineCat =
      Mossfeather, StarClanAncestor = Freezesong dressed; ended with the scene; rank unchanged. All four scenes
      (RankUp, RankUp.Leader, Prophecy.Intro, Prophecy.Closure) VM-run. Test drop Z:/WaCa/WaCa-mods-test-20261031h.
      (c) the camera's own named moves between two shots (dolly / crane) - COVERED by the blend: a shot then the next
      with ~<seconds> moves the camera there (Wide -> Portrait ~3 = a dolly in, a low shot -> High ~4 = a crane); (d) a skip key - DONE 2026-10-31 (SkipKey /
      SkipCutscene, VM); (e) a cat that isn't drawn
      can't be cast (Lionstar out of range at the river) - bring it in through a fade?; (f) Clan Life days.ini /
      clanevents.ini examples using Cutscene: - DONE 2026-10-30 (examples/WaCaStoryPackExample: [Event.HerbLesson] plays
      Cutscene: HerbLesson). (e) DONE 2026-10-31: an undrawn quest cat is cast,
      shown for the cutscene and hidden again (VM: Lionstar 90 m off, his line, back) - the look is the operator's check.
- [ ] **Nexus Mods: release, reuse the UE4SS upload, split into parts, a base mod** (operator 2026-10-28). Research
      WAITING ON THE OPERATOR: the Nexus login (upload, its UE4SS download, MothColorPicker).
      (Nexus public GraphQL API, game id 10777, domain warriorcatsclansoftheforest - 6 mods on 2026-10-28):
      - mod 2 "UE4SS For Warrior Cats - CotF" (CaptainJackalope): plain UE4SS v3.0.1-1181-g83330635 - THE SAME commit
        our release builds from source - sample mods removed, "keep your existing setup, don't reinstall per mod".
        -> ship MOD-ONLY packages that list it as the requirement (plus an optional all-in-one). OPEN: test that our
        C++ mod (built against our from-source UE4SS.dll) loads under that package's UE4SS.dll (same commit; MSVC ABI
        should match - verify on the VM with the operator's download; Nexus downloads need a login).
      - mod 4 "MothColorPicker" 0.4.1 (frostforest7): an RGB/HSV wheel in the creator (fur, pattern, markings, left /
        right eyes), saved when creation finishes; Full-Install / Mod-Only variants; MIT; AI code disclosed. OVERLAP
        with our creator colours (palette.ini swatches, appearance.ini, the custom-swatch sanitize in creator.lua):
        test both together; options - detect it and leave colours to it, or read its saved colours; take UI ideas.
      - the other mods: small cheats (infinite health / stamina / sprint, no NPC pushback).
      STATUS 2026-10-31: the split and the MOD-ONLY packages are done - seven repos, each tools/package.ps1 -> a
      package without UE4SS (0 UE4SS.dll / dwmapi.dll), each README naming WaCa Core; assemble_test_bundle.sh puts them
      in one drop with per-mod install.bat + install-all.bat (operator drops 2026-10-30 / 31). LEFT (operator): the
      Nexus pages / upload (login, go-ahead) and a test under Nexus mod 2's UE4SS download (login).
      PROPOSED SPLIT (UE4SS mods are separate Lua states - parts talk through WaCa events, which the C++ bridge then
      has to broadcast ACROSS states; shared libraries live in Mods/shared):
      1. WaCa Core - the BASE MOD others build on: shared/WaCa (events / Watch, text, tables, LoadAsset, ReadContent /
         EnabledMods, the SAVE SIDECAR API - one clean per-save store for every mod, story variables), the native
         WaCaNative.dll (bridge, hooks: areas, combat, hunt, bonds, saves, input, render), the content-pak loader.
      2. WaCa Clan Life (the story base - time of day is part of it, not split): daynight, weather + seasons (+ the
         content pak's rain / snow), timeskip, exhaustion, the clan loop (duties), scenes (events), story days, clan
         events, Gatherings, dialogue by days (lines), patrols, follow, activities.
      3. WaCa Hunting & Fishing: hunting by chance, prey world / flee, fishing, scent / guidance, wading.
      4. WaCa Looks: creator grid entries, appearance overrides, palettes, patterns / looks packs, names, rosters.
      5. WaCa Keybinds: keybinds.ini / menu keys. 6. WaCa Graphics: graphics.ini.
      7. CONTENT packs (no code): content/*.ini, looks/, patterns/ - the writers' path (stories, dialogue, events).
      NEEDED: cross-state events in the bridge; story variables / scene runner as shared libs; per-package zips
      (Wrc/Binaries/Win64/ue4ss/Mods/<Mod>/ + enabled.txt, mods.txt line); Nexus page per part (requirements,
      tested game build + exe hash, Vortex untested, AI-code disclosure, permissions); package.ps1 per part.
      DONE 2026-10-28: SPLIT into 6 local repos C:/Projects/WaCa-{Core,KeybindsMouse,Looks,ClanLife,Hunting,Graphics}
      (git init, first commit; NO remotes - the operator creates IkaronClaude/WaCa-* on GitHub). Each: Mods/<Mod>/
      (+ enabled.txt in the zip), README.md, NEXUS.md (paste-ready page: requirements, install, old-ModKit migration,
      GitHub link TODOs, contributions welcome, AI disclosure, permissions, changelog), CONTRIBUTING.md, LICENSE,
      tools/package.ps1 (zip from the game folder down, Windows tar - forward slashes), .github/workflows/release.yml.
      Core = native/ + Mods/shared/WaCa + docs/API.md + docs/EVENTS.md + examples/HelloWaCa. Cross-mod events:
      WaCaNative_Broadcast (JSON, sticky topics, WaCa.EventFrom). Speed of the cat: ONE owner (Core) for every mod's
      SpeedFactor. Keybinds: native reads Mods/WaCaKeybinds/config/keybinds.ini when that mod is on. preyworld moved to
      Clan Life (needs the season). Looks keeps the "WaCaModKit" sidecar name (old saves keep their looks).
      VM-VERIFIED (split install from the zips): all 6 load; keybinds from WaCaKeybinds; cursor menu / gameplay;
      Clan Life -> Hunting WorldFactors; SpeedFactor from another state applied (1 -> 0.5 -> 1); core.started sticky;
      HelloWaCa's content/text.ini merged + its sidecar written; Core alone (see below).
      OPEN: (1) the DLL under the NEXUS UE4SS download (same commit 8333063; ours is a from-source build) - needs the
      operator's download; (2) MothColorPicker + Looks together; (3) Nexus link TODOs in NEXUS.md once pages exist.
      RELEASE CHECK 2026-11-04: package.ps1 for Clan Life / Cutscenes / Core with today's changes - every script in its zip,
      enabled.txt + configs, nothing stray. DECISION (operator): the writer tools (tools/new_pack.ps1, check_pack.py,
      pack_editor/) are in no zip - ship them (in Clan Life's, or a separate writer kit on Nexus) or repo-only?
- [ ] **17 + 10. "Show, don't tell": a cutscene / event system.** Today everything happens off screen and someone tells
      you about it. You only learn you have an apprentice when he's suddenly in your party, and that he finished
      training when his name changes in the party menu. Needs a scripted-scene framework (Level Sequences / a dialogue
      runner) and events at specific times of the day.
      BUILT 2026-10-27 - the FRAMEWORK (experimental, events.ini On = 0): events.lua - [Event.<Name>] Hour, Day /
        Every, Once, Card (the centre-message card), Dialogue (one of the game's SequenceDialogueIds, played with the
        nearest clanmate via PlaySequenceDialogue); one-time scenes kept per save (sidecar); the 30 dialogue ids are
        listed into config/events-dialogues.txt from the game's own table at the first world load. VM: card at 22:00,
        then "Gameplay.Dialogue.Story.Monologue.Interaction.TheStarvingWarrior.Intro.2" opened the real conversation
        (Chesnut, screenshot). Fixed on the way: (a) HourChanged skipped hours a long step jumped past (scenes /
        weather countdowns lost) - now every crossed hour, and a time skip doesn't replay them; (b) the centre-message
        card counted as a MENU (cursor shown, scenes gated) - it's an overlay now.
        Open (content, operator): which scenes, when; a cutscene-grade scene (level sequences) later.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Event cards first: reuse PlaySequenceDialogue (a real conversation opened on the VM) for small scenes with
        the involved cats; later real cinematics via the game's level sequences (LS_Cinematic_*) re-targeted.

      The FRAMEWORK is core; the story content that fills it is P3. Do it once the clan-sim day (15) exists.
- [ ] **11. Clan cat interactivity.** Every cat repeats the same single line. Context lines (rank, relationship, time of
      day, current duty, recent events), plus interactions.
      FOUND 2026-10-28: the game's filler chatter = QST_Story.Monologue.Filler.<Role>.<Chapter>.<n>.Context.<n>.<Tone>
        - 755 role x chapter x tone groups, EACH ONE line (nothing to rotate without breaking the story context).
      BUILT 2026-10-28 (experimental, lines.ini On = 0): lines.lua - pools per role ([Lines.<Role>] or All) and time
        of day (Morning / Day / Evening / Night / Any); every in-game hour each filler key's text is, by chance Share,
        a pool line for the hour, else the game's own (swapped in the string table - the game still picks the key).
        VM: "Night - 824 clan cat lines changed", read back: Brightheart's line = "Look at Silverpelt tonight...".
        Open (content, operator): the lines themselves (7 examples in the ini); by relationship / rank needs the bond
        level per cat (5).
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
      PAIRS SOLVED 2026-11-01 (VM, in the RiverClan camp): the AI move fails on this map (as the walkers found) and in
        camp the nameless walkers activities picked are gone - pairs now use the camp's NAMED cats and the walkers'
        mover: Walkers.Pair(a, b, montage) - both to either side of their midpoint, face, play, home (set down in
        place after MaxWait). VM: Oakstorm + Cricketpelt play-fought; Tigerclaw + Lionstar walked 10 m each, met,
        play-fought. Drop Z:/WaCa/WaCa-mods-test-20261101e. (Ambient stays Off by default - the operator's call.)
      BOND GAIN - BUILT + VM-VERIFIED 2026-10-28 (activities.ini [Join] On = 0 by default): the game's own
        AddPersonalBonding (0x1416A0BD0 in this build) - a free function (cl = ENarrativeRole, edx = points) that adds,
        sets through the progression's virtual +0x560 and saves with context "AddPersonalBonding". bonds.cpp finds it by
        that string + prologue (check_hooks.py: OK, unique) and checks its body calls [rax+560h]; WaCaNative_AddBond.
        Join: next to a story cat (AQuestBaseActor with narrativeRole) press G -> both play the Join montage (the NPC
        through its mesh's anim instance) -> +Bond. VM: TheLoner 43 -> 45 in WrcGame.json, saved by the game
        ("game saved (AddPersonalBonding)"). Open: joining the AMBIENT activities (they run on generic clanmates,
        which have no bond), a nicer moment (camera, a line of dialogue). DONE 2026-11-03 (VM): a cat mid-activity is joined in
        THAT activity; the moment = a camera shot on the two (WaCa Cutscenes' new CameraMoment) + a line of the cat's
        ([Join] Camera / Line<n>) - VM: the Two shot, 'Heronshine: I hoped you'd come by.', bond +2. Joining a cat
        mid-activity VERIFIED live the same day (StartActivity Nap on RiverClanKit -> 'joining its Nap').
      BOND GAIN - FOUND 2026-10-28 (the next step, an exe job like AddExperience): bonds are kept per narrative role
        (save: GameplayProgression.Bonding = { <role>: points, <clan>: points, Nodes = answered dialogue nodes }, e.g.
        TheRegretfulWarrior 97, RiverClan 102); at runtime that map is NOT reflected. The game changes it through (a) its
        effect system - USwtAdventureUpdateRoleEffect.UpdateRoleStruct.AffectedBonding = [{ narrativeRole, Bonding }]
        (FSwtAdventureUpdateBondingStruct), applied natively (no reflected Apply), and (b) dialogue answers
        (UQuestDialogueEdge Score / ClanBonding, UQuestDialogueActionResolveBondAnswer). Plan: find the native
        "apply effect" virtual of USwtAdventureBaseEffect (or the bonding add it ends in), anchor it in check_hooks.py,
        and grant Bond = +n per finished joint activity through it (a constructed UpdateRoleEffect with
        AffectedBonding) - then the game's own level-up UI / rewards follow.
- [ ] **13. Less "jack of all trades".** Specialisation for your cat (strengths / weaknesses, roles).
      DRAFT DESIGN (2026-10-27, for the operator to adjust - built on what the code research found):
      - Specialisation = a role picked at warrior rank: Hunter (+15 hunt chance, -fight), Fighter (+combat damage,
        -hunt), Tracker (+fishing / scent, wider noise window for prey). Implemented as modifiers the existing
        systems read (hunting.ini factors, combat stats via the stats the save keeps). config: roles.ini.
      BUILT 2026-10-27 (off by default): config/roles.ini [Specialisation] Role / MinRank (Warrior) + [Role.*] Hunt /
        Fish / Noise multipliers; hunting.lua applies it once the saved rank reaches MinRank (ECharacterRank order):
        hunt chance x Hunt, fishing bite x Fish (RoleFactors event), the loud-ground noise window x Noise. Hunter 1.15
        hunt, Tracker 1.25 fish + 0.5 noise, Fighter 0.85 hunt. Open: choosing the role in game (a rank-up dialogue /
        menu), the noise window refreshes at the next ground change. Needs hunting.ini [Chance] On (the rank is read there).
      COMBAT (2026-10-27): [Role.*] Combat / Guard = damage the player's cat deals / takes (Fighter 1.25 / 0.85).
        combat.cpp: a ProcessEvent pre callback on ASwtAdventureCombatDirector::OnRegisterDamage(
        FSwtAdventureReceiveDamageStruct) - every hit is queued through it - scales Damage before the director queues
        it; attacker = CurrentTurnAttackCharacter, receiver = the struct's Character, the player's cat = the director's
        MainPlayerCharacter (it IS in the combat party - VM). All offsets by reflection (VM: struct +0, Character +0,
        Damage +12). VM: role on ("Fighter ... dealt x1.25, taken x0.85"), the hook resolved live in a real fight vs
        two forest rats; a scaled HIT not yet seen - the VM (0.6 fps) can't play the attack minigame and the Rest
        button pressed through the popup didn't take; a direct Lua call of OnRegisterDamage bypasses UE4SS's
        ProcessEvent callbacks (not a valid test). OPERATOR: one real fight with Role = Fighter -> WaCaNative.log
        "[combat] damage dealt / taken by your cat: X -> Y".
        VM 2026-10-28 (2 more fights vs forest rats, the combat menu driven with Enter): every hit passes the hook -
        15 logged ("[combat] hit: attacker is your cat 0/1, receiver is your cat 0/1, missed, damage" - kept for the
        first 30 hits per session), damage 10-114, layout right; a Lua watch saw one hit with attacker ==
        MainPlayerCharacter. In those 15 hits the player's own cat neither hit (its attack minigame can't be played at
        0.6 fps) nor was hit (the rats chose the allies) - so a SCALED hit is still unseen; the log line shows it in
        the first real fight.
        FIXED + VERIFIED (same night): the director in play is BP_CombatDirector_C (a Blueprint subclass) - the
        property lookup must search the class CHAIN (GetValuePtrByPropertyNameInChain); with the plain lookup both
        "attacker" and "player" were null, so nothing was ever scaled. VM after the fix, a real fight vs forest rats:
        "[combat] damage taken by your cat: 8 -> 7 (x0.85)", "30 -> 26", and "damage dealt by your cat: 35 -> 44 (x1.25)" -
        both directions VERIFIED.
      CHOOSING THE ROLE IN GAME BUILT 2026-11-02 (VM): with roles.ini Role empty, reaching MinRank asks (a Clan Life
      Choice - roles.ini [Specialisation] Ask / Question, [Role.*] Label; the first four roles in file order, a pack's
      after the mod's): Deputy save -> the question with Hunter / Tracker / Fighter / Herbalist, key 4 -> Herbalist,
      kept in the save's WaCaHunting.ini. Left: the operator's feel for the wording / the choice's look (P2 ticket).
- [ ] **2. More customisation.** "Ragdoll" colourpoint layout; more colours (a colour wheel?). Check how the coat
      WAITING ON THE OPERATOR: the Colourpoint look / a colour wheel UI (needs the editor).
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
      EYES CHECKED 2026-10-31 (VM): the eyes are the body mesh's material slot 2 (MID of MI_Cat_Eyes); the iris colour
      = an index per eye (IndexIrisColorCurveLeft / Right) into the game's eye-colour palette (texture
      CurveAtlas_Characters_Eyes_AllColors). WaCa Looks rosters already set it (EyeLeftColorIdx / EyeRightColorIdx -
      odd eyes too). Colours outside the palette = a new palette texture (art -> the pak pipeline). So eye colour is
      covered within the game's palette; open here: the colour wheel UI (editor), the colourpoint mask pack, the
      operator's look.

- [ ] **26. Prey scent / visual trails** (operator 2026-10-25: "sick for future work", like The Isle). Prey leaves
      trails - scent you detect (a sense / sniff mode) and visual signs (tracks, disturbed undergrowth) - that you can
      follow to the prey. Ties into 23 (random spawns: the trail is how you find them), 21 (rain washes scent out,
      snow keeps tracks) and 24 (StarClan guidance as an alternative lead).
      FOUND + BUILT 2026-10-28 (experimental, hunting.ini [Scent] Trails = 0): the game HAS the machinery - every
        roaming creature carries BP_SensedEnemy_TrackComponent (tracking on); sense mode (Q) collects nearby
        candidates (VM: a quest hint area, a herb, a pouch, a prey 300 away) and spawns their TrackerElementClass -
        BP_Sense_TrackerElement: NO path (bShowPath / bShowLinear / bUseSplineMesh off), only a target overlay. The
        game's quest-hint trail is BP_POI_Hint_TrackerElement_Duration (all three on, NS_ScentTracking, a duration).
        scent.lua swaps prey's TrackerElementClass to that trail class (world up + every creature spawn). The elements
        are spawned natively (their BeginPlay / OnTrackStateChange never pass ProcessEvent - a property hook can't
        work). VM: 63 prey switched; in sense mode a trail element spawned for the tracked prey. NOT yet seen on
        screen (the prey was off-camera at 480x270) - check in real play; tune the sense range later (which prey count
        as candidates is the game's own radius).
        2026-10-28 later: framed shots (the cat 6 m before the prey, in sense mode) showed NO trail - the prey's trail
        element had 0 spline points / 0 effects, while the game's quest trail had 24 points + 1 effect: the game makes
        PATHS only for its own quest targets. scent.lua now lays one (cat -> prey, 150 cm steps) when a sense pulse
        starts (the sense component's first BlendProgress; BlendsFinished = the pulse ENDED - VM-timed: 48 s later at
        0.3 fps) and calls the spline's SetupMeshes + the element's OnTrackStateChange. VM: "1 trail(s) laid to prey"
        in sense mode; the shot still shows no clear line (more particles at the prey) - NOT confirmed visually.
        [SUPERSEDED 2026-11-02: see VISIBLE below - built, off by default, the operator's look] Next:
        compare the element's spline meshes / Niagara with the quest trail's (reading RegisteredSplineVisualMeshes from
        Lua crashed UE4SS natively - do it in C++), or spawn the game's NS_ScentTracking along the path directly.
        Tried the latter (same night): NS_ScentTracking spawned every Spacing cm along the path for TrailSeconds - no
        error, but still nothing visible in the framed sense-mode shot. That system likely needs its user parameters
        (the spline / target it follows on the quest trail) - read them from the quest trail's NiagaraComponents in
        C++ next (Lua reads of those arrays crash UE4SS). STATUS: the trail is logically there (element + path + effect
        spawned), NOT visible yet - stays experimental, off by default.
        VISIBLE (2026-10-28 04:00): NS_ScentTracking's user parameters (read from the asset) are Spline / SplineLength /
        Code_TrailOpacity / Code_Color - it draws along a spline it's given; bound via SetVariableActor it still showed
        nothing on the VM. A control run proved spawned Niagara renders on the VM (NS_GPE_PickUp_Hint /
        NS_Scent_Hint_Item visible). So the trail you see = puffs of the game's NS_Scent_Hint_Item every Spacing cm
        (250) from the cat to the prey for TrailSeconds: VM shot in sense mode, the cat 6 m before a mouse - a glowing
        scent puff on the ground between them. The spline-bound NS_ScentTracking stays in as well (harmless).
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - A trail = a short line of the game's step Niagara (NS_Steps_* / scent sense effects) spawned behind moving
        prey every few metres, visible in sense mode (the game's ExplorationSenseComponent switches) - fades in N s.

## P3: Later / big content

- [ ] **P3: WaCa Core hot-reloaded TWICE in a row hangs the game (VM 2026-11-03, 2 of 2)** - one copy of a Core
      script over the share gave two 'Auto-reloading Lua mod WaCaCore' ~10 s apart; the game stopped responding after
      the second start's 'roles with no cat in this save' (0.1 fps). WaCaNative.log both ways: 'a mod stopping while an
      event runs - removed without waiting' then 'WaCaCore starting while an event runs - added without waiting' - the
      bridge's 2 s try_lock in LuaStopping / LuaStarted gave up and changed g_states with a delivery (OnProcessEvent
      holds g_statesMutex on the game thread) still in it. A real race in bridge.cpp, not fixed: a state can't simply be
      marked dead and swept later if the game thread is blocked INSIDE that state's Lua (UE4SS tears it down). Next:
      find what the delivery waits on (a dump of the hung game), then defer adds / removes to the game thread. Only
      with EnableAutoReloadingLuaMods = 1 (a test setting) - meanwhile Core changes are deployed by restarting the game.
      Logs: Z:/WaCa/hangs-20261103/ (UE4SS.log of both, WaCaNative.log of the second).
      REPRO 2026-11-03 11:50: a SINGLE Core reload (one cp, pause menu up) hung it too - so not the double reload.
      Stack scan of the hung game (Z:/WaCa/hangs-20261103/hang-1150-stacks.txt): NO main.dll (WaCaNative) frame on any
      thread; ~25 threads wait in the same UE4SS path (ntdll wait <- UE4SS+1356e38 / +1e48ab / +cae0eb ...), one more in
      WaitForSingleObject from UE4SS+20d823. Same picture as the 2026-11-02 reload deadlock (memory: not our code).
      Naming the frames needs this build's PDB: ours is v3.0.1 Beta g83330635, no longer published (experimental-latest
      is g236adf26) - trying a newer UE4SS = a whole-setup change, the operator's call. Earlier the same day a Core
      reload with the pause up worked (10:07), so it's timing-dependent. Rule meanwhile: Core changes = restart.
      DONE 2026-11-03 13:20 (Core 'Bridge: ... QUEUED'): the bridge race fixed - a start / stop the loader can't wait
      for is queued and applied by the game thread between deliveries (stopping state marked gone at once); VM: plain
      reloads fine, the queued path logged under a forced 8 s delivery. AND the hang REPRODUCED ON DEMAND that way: a
      reload while the game thread runs Lua (a busy KeyDown handler) hangs the game inside UE4SS (stacks: Z:/WaCa/
      hangs-20261103/hang-1318-forced-*), no main.dll frame. So the remaining hang = UE4SS (game-thread Lua vs its
      loader thread), not our bridge. Left: a newer UE4SS build to try (operator), or report it upstream with the repro.
      TRIED 2026-11-03 17:00: experimental-latest is only 15 commits ahead; the one lock fix in it (cdbc0b6 'Run queued
      events outside the event queue lock', UE4SS #1445) cherry-picked onto our 83330635 and UE4SS.dll built from our tree
      (main.dll unchanged - same headers): the forced repro STILL hangs. With our own build's PDB the stacks are named
      (Z:/WaCa/hangs-20261103/hang-1716-patched-stacks.txt + ue4ss-patched-test/): the game thread is in a ProcessEvent
      hook -> Lua -> LuaMadeSimple::process_lua_function (a C function called from the harness's Lua - its log/print)
      waiting on a lock; the event loop (UE4SSProgram::update) and every LuaMod::update_async thread just sleep, the 25
      rayon threads are idle - the reload itself finished. So: a lock left held across the reloaded mod's teardown, in
      UE4SS's Lua layer. Not fixed by #1445; the original UE4SS.dll is back on the VM. Next = UE4SS internals or an
      upstream report with this repro (outward-facing: operator's go).
      ROOT CAUSE FOUND 2026-11-03 18:20-19:50 (UE4SS built from our tree with fixes, live stack walks via dbghelp +
      symbol server, Z:/WaCa/hangs-20261103/ - livewalk.py in the session scratchpad):
      (1) UE4SS's LuaRaw/src/luauser.c guards EVERY Lua state with one global CRITICAL_SECTION, and DELETES it whenever
          any state closes (luai_userstateclose -> LuaLockFinal); a mod's hot reload closes its state, so the lock went
          away under the game thread's Lua - it waited forever on a lock showing free (LockCount -1, no owner).
      (2) Lua 5.4's lua_close takes lua_lock and never unlocks (fine for a per-state lock): with (1) fixed, UE4SS's
          FilesystemWatcher thread (it closes the reloaded mod's state) kept the global lock for good.
          Fix for both (patches 0001/0002 in Z:/WaCa/hangs-20261103/ue4ss-patches): made once (InitOnce), never deleted,
          released in LuaLockFinal by the thread that holds it. VM: the forced repro no longer hangs ('busy end').
      (3) THEN it crashes: UE4SS runs a delayed action (ExecuteInGameThreadWithDelay) on the game thread after picking
          it, while the watcher thread's uninstall erased it and closed its state -> luaV_execute on freed memory. Running
          actions under the actions lock (patch 0003) is WRONG - async loading deadlocks on it, the engine aborts at boot
          (2 of 2). The real fix: UE4SS must tear a mod down on the game thread (or never while the game thread is in
          that mod's Lua) - an architectural UE4SS change. The original UE4SS.dll is back on the VM.
      So: hot reload in UE4SS g83330635 is unsafe whenever any mod's Lua runs during it. Ours can't fix it from outside.
      AGAIN 2026-11-04 19:56 (original UE4SS): seven reloads 12 s apart (Core, Graphics, Keybinds, Looks, Hunting,
      Cutscenes, Clan Life), in the world - hung after Clan Life's start (Z:/WaCa/hangs-20261104-reload/).
      AND 22:58 the same day: two WaCaCore reloads 9 s apart (two files copied, the pause menu up) - hung after the
      second start's 'roles with no cat' (Z:/WaCa/hangs-20261104-reload2/). Test rule: one copy = one reload, or boot.
      FIXED IN A TEST BUILD 2026-11-03 20:40: (1)+(2) as above, and (3) the hot reload moved to the GAME THREAD - the
      file watcher only queues the mod's name, an engine-tick pre-callback does uninstall + restart between ticks (no mod
      Lua runs there). VM: the forced repro -> 'busy end', 'Auto-reloading ... (on the game thread)', Clan Life loaded,
      events after; 3 rounds of WaCaCore reloads (6 reloads) with the pause menu up -> alive, no crash (was 3 of 3 hangs).
      Patches: Z:/WaCa/hangs-20261103/ue4ss-patches-final (3; the wrong 'delayed actions under the lock' one dropped),
      build: .../ue4ss-gamethread-reload/. The VM is back on the ORIGINAL UE4SS (players' parity). Operator: ship a
      patched UE4SS / use it for testing only / report upstream with these patches.
      Upstream report (1)+(2)+(3) with the repro = the operator's go.
      2026-11-05 02:31 (VM): a SECOND Clan Life reload 42 s after the first - the game process was GONE (no crash
      report, no system event; the log ends at 'Auto-reloading'). Cause not known (a reload fault or the VM's memory
      reaper - not shown). Rule kept: one copy per reload; for two files, boot fresh.
- [ ] **P3: default PAD buttons for the mod keys (operator decision)** - since 2026-11-03 a pad button can be bound
      (keybinds.ini [ModKeys] <Mod>.<Name> = F, Gamepad_...), but none is by default: Report, JoinActivity, Rest,
      AskMate, Cutscenes.Skip. Which buttons are free in the game's pad layout = the operator's call.
      TRIED 2026-11-03 to find the free buttons from the game's data: its gameplay commands' pad keys are not in the
      engine's InputSettings (2 actions) nor readable on PlayerInput, and Core's capture keeps keyboard / mouse only - the
      game applies its PAD list only when a pad becomes the active device (input.cpp: the list runs again on each
      keyboard <-> gamepad switch). The VM has no pad, so the layout can't be read here: needs a pad connected (the
      operator's PC) to log the pad list the game applies, or the operator's pick.
- [ ] **27. Side threads** (operator 2026-10-25, future work). Quest chains spanning several days (25) that can be
      missed when not done by a given day, so the story isn't one fixed line.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Builds on 25: multi-day quest chains as day-script entries with their own state in the save sidecar.
      PRE-WORKED 2026-10-31 (library exercise, VM): side threads are DATA in a pack - clan events + story variables:
      Set takes another variable +/- n (Set: LostKit.Until = Day + 2), conditions name a variable on the right
      (Day <= LostKit.Until), When = Event:HuntCaught for the player's deed. Example pack: the lost kit (start one
      morning, a catch within two days finds her, else a patrol does - missed). VM: deadline 21 on day 19, the catch
      in time fired LostKitFound; past the deadline nothing. Drop Z:/WaCa/WaCa-mods-test-20261031u. The operator's:
      the real threads to write.
      MISSED ENDING run on the VM too (new: WaCa.Emit("ClanEvent", name) runs a clan event now, Require checked):
      refused before the deadline, after it the patrol card and LostKit = -1; a later catch finds nothing. Drop
      Z:/WaCa/WaCa-mods-test-20261031v.
- [ ] **Decouple cat stats from looks** (frequently requested by players; operator 2026-10-25). Today body type /
      WAITING ON THE OPERATOR: the visible body shape in play.
      traits drive both the visuals and the stats. Add a separate set of visual sliders / choices whose list carries no
      stat effect; the visuals read from it, the stats keep the original choice.
      PREPARED 2026-10-28 (offline): the stats are STORED in the save once the cat is made -
        GameplayProgression.Stats = "(Prowess=165,Strength=135,Resilience=140,Instinct=145,Agility=135,Stamina=100)"
        (+ Traits [{Type}]) - separate from the look (the cat's FCatCustomData: BodyValue, FaceValue, FurValue,
        WhiskerValue, TailIdx, EarIdx ..., the look component's CustomData, already read natively in bridge.cpp). So
        decoupling = a body / face override in appearance.ini ([Body] BodyValue / FaceValue / FurValue ...) applied to
        the player's look component after the game builds it (like the colour / mask overrides) - the stored stats are
        never touched, the creator's choice keeps setting them. [SUPERSEDED - BUILT + VM-checked below] NEXT (needs the VM): write those CustomData fields +
        WaCa.RebuildLook, check the shape changes and the save's Stats don't.
      BUILT 2026-10-28 (appearance.ini [Player] BodyValue / FaceValue / FurValue / EyeValue / WhiskerValue / TailIdx /
        EarIdx / CatSize, empty by default): main.lua writes them into the player cat's CustomData right before the
        look build and PUTS THE CAT'S OWN VALUES BACK right after (the build is synchronous) - the shape is built from
        the ini, nothing the game saves changes, the stats are never touched. VM: "look: the shape from appearance.ini
        (the stats stay)" applied before the rebuild; the visible change (BodyValue 100, CatSize 1.3) not judged at
        480x270 - check in play. Caveat: a rebuild by the GAME itself (creator, respawn) uses the own values until the
        mod's next look pass.
      CAVEAT FIXED 2026-10-31 (VM): a rebuild the mod didn't start (the game's own) is seen through CatLookPart and the
      shape goes on again right after (your cat only, coalesced); a skipped shape logs why. VM: CatSize 1.5 applied at
      boot and again after an outside rebuild; the cat's own CatSize (0.8) and the save's Stats unchanged. The visible
      size: the operator's look in play. Drop Z:/WaCa/WaCa-mods-test-20261031y.
      CatSize REMOVED 2026-10-31: measured on the VM, CatSize sizes nothing in the world (the look build and
      RefreshShape ignore it; it's the creator preview's anim CurrentScale) - so [Player] CatSize only pretended. The
      remaining keys (BodyValue / FaceValue / FurValue / EyeValue / WhiskerValue / TailIdx / EarIdx) are the operator's
      visual check. A real player size = the actor's scale - but that scales the collision capsule too (gameplay),
      so the operator's call. Drop Z:/WaCa/WaCa-mods-test-20261031z.
      DRAFT DESIGN (2026-10-27, for the operator to adjust - built on what the code research found):
      - Find where body type / size feed the stats (the save's Stats / Customization; the creator's choices) and
        override the stat base after creation from a separate pick (creator page or stats.ini), leaving the look.
- [ ] **Story.** Pour the existing thin story into the new systems, then expand it toward the books (needs 15 + 17).
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - After 15 + 25 exist: port the existing story beats into day scripts first (no new writing), then extend.
- [ ] **12. Romance + kits (far future).** The friendship system already exists. Add a mate, kits of your own, watching
      WAITING ON THE OPERATOR: the rules (a configurable draft is built, off).
      them grow up. Maybe in a free-play mode after the story concludes.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - The friendship (bond) system's top level unlocks "mate"; kits = new clan cats generated with the parents'
        looks (the look framework) after N days (seasons).
      PRE-WORK 2026-10-31 (WaCa Core, VM): the kits' looks - WaCa.LookOf(cat) (the game's text form of a cat's look,
      FProperty::ExportTextItem), WaCa.BlendLooks(a, b) (each trait from one parent, Role Kit, kit-sized, a new prefix
      + 'kit'), WaCa.SpawnCat / ImportLook to put the kit in the world. VM: your cat x Nightheart -> Stonekit by the camp
      stream. CORRECTION 2026-10-31: that kit was ADULT-sized - a look's CatSize sizes nothing in the world (measured:
      CatSize 0.8 -> 2.5 + a look build / RefreshShape moved no bone; it feeds the creator preview's anim only). Kits
      are now sized by actor scale: SpawnCat(look, at, yaw, scale), BlendLooks' third value (WaCa.KIT_SCALE 0.6); VM
      read-back: the kit's meshes at 0.60. The VM's screenshots didn't frame the pair - the operator's look in play.
      KITS GROUNDWORK 2026-11-01 (VM, Clan Life kits.lua / kits.ini): WaCa.Emit('HaveKits', mate[, count]) - 1-3 kits
      blended from your cat and the mate, named from the game's own unused prefixes (RemainingPreffixes - not 'Lionkit'
      beside Lionstar), kit-sized, placed in front of your clan's Nursery (the game's den door), kept with the save
      (sidecar written when the game saves); event KitsBorn. VM: Goosekit + Heronkit by RiverClan's nursery, back after
      a reboot. (A first version wiped its sidecar on a misread - fixed: read by number, never written unread.)
      Drop Z:/WaCa/WaCa-mods-test-20261101d.
      ROMANCE DRAFT 2026-11-01 (VM; Clan Life romance.ini, OFF by default - every rule there for the operator to change):
      the ask key (H) next to the story cat your cat FACES; yes when its bond is at MinBond (CloseBond - the save's own
      BondDialogues '<Role>_Reward_<Level>') and your cat is MinRank (Warrior)+ with no mate; kept with the save, event
      MateChosen, story var HasMate; KitsAfter (7) days later HaveKits. Kits grow up after kits.ini ApprenticeAfter
      (12) days: '...paw', drawn at 0.8. VM: Nightheart (bond 0) 'not that close yet'; Toadfrost (CloseBond) 'Yes';
      kits next day; Goosekit -> Goosepaw. Kit names now skip every living cat's (Lionkit beside Lionstar before).
      Also found + fixed: a Clan Life HOT RELOAD hung the game (bridge events during a 12 s main.lua; mod states
      removed under a delivery) - held while any mod loads, states under a recursive mutex; VM: reload mid-play, the
      game kept responding. Drop Z:/WaCa/WaCa-mods-test-20261101g.
      The operator's to decide: who can be a mate (the bond's CloseBond?), the asking, when kits come, where
      they live (the nursery), growing up. Drop Z:/WaCa/WaCa-mods-test-20261031x.
- [ ] **Frozen water in leaf-bare** (operator 2026-10-31, future work): the lake and / or parts of the river freeze,
      changing the terrain that can be walked (new paths across the ice); from that, a "falling through ice" mechanic /
      story arc. NOTES: water is visual planes + Water / DeepWater floor types (no water volumes - see 16), so ice =
      a walkable surface over the water plane in leaf-bare (WaCa Clan Life's seasons) + the floor read as ice; falling
      through = a scene (Cutscenes) / story beat (rescue, injury) at thin-ice spots.
      GROUNDWORK (2026-10-31, VM): the water planes CAN be made solid - SetCollisionEnabled + Block on the Pawn channel
      (wading now sets them query-only); in leaf-bare blocking the Pawn channel on chosen planes = walkable ice, an ice
      material swap for the look. Falling through: switch one plane's block off under the cat (thin ice) + a scene.
      VERIFIED (VM): 3 planes at the deep river spot set QueryAndPhysics + Block on Pawn - the cat stands ON the water
      (feet 853, surface ~845) instead of the riverbed (592).
      BUILT 2026-10-31 (WaCa Clan Life ice.lua, weather.ini [Ice] On / Season / Lake / River %): in leaf-bare the lake
      and River% of the river stretches (stable pick per plane) freeze - their water material as a dynamic instance,
      still and pale (no flow / ripples / caustics, opacity up, frost-white foam), solid to cats. Water meshes differ:
      river pieces / puddles have collision once on; the map-wide lake plane (SM_Water) only triangles - its mesh made
      to collide on them (CollisionTraceFlag 3 + collision toggled; SetStaticMesh(nil) crashed). Thaw: material and
      collision back; under the cat it drops onto the bed, over a hole (the lake) the ice under it holds till it steps
      off. Freeze event for stories, IceFrozen / IceThawed. VM: 32 frozen (1 lake, 31 river); river ice 629/627 -> bed
      576 on thaw; lake 752/750, held over the hole; camp unchanged; the lake a pale ice sheet in the screenshot.
      Drop Z:/WaCa/WaCa-mods-test-20261031q. OPEN: falling through (thin-ice spots: a scene + a story beat), NPC cats
      on the ice (the walkers' sweeps), the look checked by the operator.
      THIN ICE BUILT 2026-10-31 (VM): [Ice] ThinChance 15 % of the frozen river stretches (stable) give way after
      ThinSteps 6 footsteps (CatStep) - only over ground; the cat drops in, ShowLine 'The ice cracks beneath your paws!',
      event FellThroughIce(stretch) for a story's rescue / injury scene; the hole refreezes after Refreeze 60 s. Wading
      counts frozen water (through a hole = in water). VM (ThinChance 100 for the test): StaticMeshActor_151 gave way,
      the line, wading 'shallow water (21 cm)'. Drop Z:/WaCa/WaCa-mods-test-20261031r. OPEN: the story arc itself (a
      scene on FellThroughIce), NPC cats on the ice, the operator's look at it.
      STORY ARC (library exercise, 2026-10-31, VM): Clan Life clan events take When = Event:<name> (new - a data-only
      pack reacts to any event); the example pack's IceRescue (When = Event:FellThroughIce): a cutscene - the nearest
      clanmate hauls your cat out - then a card. VM: the ice gave way -> Rippleface 'Hold on - grab my scruff!' -> the
      card. Drop Z:/WaCa/WaCa-mods-test-20261031s. Still open: NPC cats on the ice; the operator's look.
      NPC CATS ON THE ICE DONE 2026-10-31 (VM): the walkers' ground trace skips open water (a bug wading's query-only
      planes would have caused: cats walking on the river) and stands on ice; Cutscenes' ground counts ice as dry. On the
      frozen lake: the party (Nightheart, Rippleface) and HerbLesson's Mossfeather at 767-768 (surface 750). Drop
      Z:/WaCa/WaCa-mods-test-20261031t. Left: the operator's look in play.

## Archive
- 2026-11-04 [x] **P2: a Lua call on a FREED object - UE4SS+0x3ecd05 - FIXED 2026-11-04 (WaCa Cutscenes 9d789bf)**: the camera's
      plant list (camera.lua plantsNow, kept 30 s) held foliage components a level stream-out FREES; plantFree called
      GetInstancesOverlappingSphere on them unchecked. Pinned by the guard build logging the Lua traceback: 44 of 44
      hits = camera.lua:132 (plantFree <- clear); the 3264 B size class = the foliage / HISM / grass components. Fix:
      WaCa.Live(c) before each use. PROOF: the full 14-cutscene sweep on the ORIGINAL UE4SS, no crash (3 crashes before
      it, GatheringNight 2 of 2). The UE4SS guard (patch 0004, now with the traceback log) stays a hardening option for
      the operator's UE4SS decision. History - was:
      it recurred. Both minidumps fault at the SAME instruction (UE4SS +0x3ecd05, `mov r9,[rcx+rax]` - UObject::
      ProcessEvent's virtual call) reading the same 0x1e3220f20: the object's first 8 bytes are 0x1_e3_22_0cc0 = an
      FMallocBinned2 FREE-BLOCK header (block 3264 B, pool 0x22, canary 0xE3) - the object had been destroyed and its
      memory given back, and Lua called a UFunction on it. (The old title's exe+0x1a95fd3 was only a caller frame.)
      Same stack both times: engine tick -> a UE4SS game-thread action -> 3 nested pcalls -> the call. Both dumps hold
      `IsInViewport`; the first also the harness probe `if s:IsValid() and s:IsInViewport()` over FindAllOf(pause
      screen) - so IsValid said yes and the next call met freed memory. The 2nd came 2.4 s after a cutscene line put
      the game's message card up (a screen change - the screen trackers run). Symbols: a UE4SS build of our commit
      (Z:/WaCa/hangs-20261103/ue4ss-plain-83330635, with PDB) + byte-matching (scratchpad rvafuzzy.py / symb.py).
      FOUND ON THE WAY (VM 2026-11-04, probes Z:/WaCa/probes/gc*.lua): UE4SS reads the engine's internal flags as
      before UE 5.4 - on this 5.7 game the reachable bit ROTATES 14 <-> 15 each GC, its "Unreachable" bit 28 is never
      set, and a destroyed actor carries Garbage = bit 21 and passes IsValid until the GC frees it. Fixed in WaCa.Live
      (Garbage = gone). NOT shown to be this crash: destroyed actors and dropped widgets left at the next GC with no
      frame in between where Lua could see them condemned (3 GCs watched). Open: which call.
      GUARD BUILT + VM-TESTED 2026-11-04 (a UE4SS patch - the bad read is inside UE4SS's own call wrapper, before any
      hook of ours): call_ufunction_from_lua checks the object's GUObjectArray slot still holds that very object, else
      a Lua error. Z:/WaCa/hangs-20261103/ue4ss-patches-final/0004-guard-call-on-freed-object.patch, build
      ue4ss-guard-freed/. VM: an actor destroyed + freed by a forced GC, then called through the kept Lua reference ->
      'Tried calling a function on an object that no longer exists' (pcall-able), live calls unaffected, the game ran
      on. Not airtight (the slot index is read from the object - fine while the allocator keeps the page). The VM is
      back on the ORIGINAL UE4SS (ce5e3c..., copy in ue4ss-vm-original/) so a recurrence is still caught there.
      OPERATOR: ship it with the reload patches 0001-0003 (our own UE4SS build) or not, and the upstream report
      (this guard + the pre-5.4 flags) - the same decision as the reload-hang ticket.

- [x] **(2026-11-03) P2: how a story's Choice looks (operator decision)** - built 2026-11-02 (WaCa Clan Life, Choice: <variable> =
        DONE 2026-11-03 (VM): the game's quest-dialogue answer menu - speaker plate, mouse / Up-Down-Enter / number keys
        (Clan Life events.lua). GAMEPAD 2026-11-03: the old pad key names could never fire (KeyDown = keyboard / mouse
        only); now the game's own screen commands move / answer (Button_Up / Down / A) - VM-tested with the commands a pad
        produces; a physical pad = operator.
      <question>; <answers>): the question and numbered answers on the game's centre card, answered with the number
      keys 1-4 (gamepad face buttons mapped, untested - no gamepad on the VM); VM-verified with the loner's visit. The
      operator's call: is that fine, or a menu of the game's own look (its dialogue-answer list) - which would be the
      next build.
      OPERATOR ANSWER 2026-11-03: the GAME'S ANSWER MENU - rebuild the Choice in the look of the game's own dialogue
        answers (research that widget).
- [x] 2026-11-03 - **P3: spawned cats (newcomers, kits) have no nameplate** - found 2026-11-03 checking a Newcomer on the VM: the
      game's clanmates float their name and rank over their heads; a cat WaCa.SpawnCat puts in the world shows none, so
      a new clanmate (Emberheart) can't be told apart in the camp. Next: find what gives the game's NPC cats their
      plate (the nameplate widget component WaCa Looks renames - which actor class / component adds it) and attach
      the same to spawned cats with the cat's name and rank.
      FIXED same day (VM): WaCa.Nameplate (Core) - the game's own plate widget on a screen-space widget component of the
      spawned cat; a newcomer's rank line copied from its clanmate's plate (WaCa.PlateRole - the game's word). Emberheart:
      'Emberheart / Warrior', one plate after a boot and after a Clan Life reload. Kits: name only (the game's 'Kit' text
      not found yet).
- [x] **Operator play-test of the split mods (2026-10-28) - fixed, VM-confirmed in bulk runs the same day.**
  - Rank: WaCa.PlayerRank = 1 + rank quests done (QuestProgression), promotions live (topic player.rank). VM: a new
    RiverClan apprentice -> rank 1, tasks from the deputy; Dapplepatch -> rank 3, lead mode. ALSO FOUND: the active cat
    slot is Shared.General.CurrentCatSlot - CurrentSaveSlotIndex stayed 0, so a new cat read another cat's day, names,
    sidecars (VM: slot 8 cat now "-8", day 1).
  - The day: morning / afternoon duties, the evening in camp (sharing tongues) staged (5 camp cats placed in a ring through a fade,
    poses, release - the camp cats are BP_Quest_Filler_C scenery, no controller), night: den sleep (My den / your rank's
    den by STR_DEN_* names; VM: walked into the warriors' den -> sleep pose, fade, day 2 at dawn). F9 off by default.
    THE EVENING SCENE REDONE + SEEN in daylight (VM 2026-10-28 evening, a dawn copy of the scene): the fillers were parked
    by the game (38/41 bodies off) and moved quest actors never drew -> the camp's WALKING cats (game AI characters),
    an arc in front of the camera (the camera sits ~1 m behind your cat - a ring hid them), movement held while
    staged, released back to their own spots (the saved transform was a live view - nobody went back before). Shots:
    5 clanmates sitting before Dapplepatch with the card; after: back 24-42 m away, walking on.
  - Deputy lines ([Talk]): VM with the game's dialogue widget + NpcRef = RiverClanDeputy: "free time turned in
    (Deputy)" and the line swapped to the report text, restored on close. Busy (VM, during "hunt 2 prey"): "Shouldn't
    you be out on your hunting? The clan is counting on you." - restored on close.
  - BULK RE-CHECK 2026-10-28/29 (960x540 where detail mattered): Colourpoint tile at full size (masked face, dark
    points, unlike the Tabby tiles); night HUD "Your den / Sleep in your nest"; F9 = nothing (0 rest lines); walked
    into the warriors' den -> "in its den - it goes to sleep" -> day 18 at dawn; dawn cards one at a time, no
    overlap (contact sheet); FISHING end to end: moving arrival -> startled, stays away while moving, still -> "back
    and biting (60%, rolled 35)" (earlier misses were a rat fight mid-test); hunting parts all report on (chance on
    63 prey, scent trails, guidance 10 puffs, wading). Found + fixed: "0 of 0 duties done" card after a night-start
    session - VM 2026-10-29: "day 18 over - 0 done, 0 missed", no card; and in the ORIGINAL setup (a fresh load that
    starts at night, sleep in the den): "the night begins (the session starts)" -> "0 done, 0 missed" -> no card. Hunt chance label: VM probe on a rabbit 3 m
    off - label "95%" visible inside the game's sneak-attack paw canvas (shown by the game when stalking). Known: a Hunting hot reload re-arms fishing spots
    twice (13 areas) - reload-only.
  - Card queue (timeskip + exhaustion too): dawn cards ~5 s apart, none overlapping; the first day + cards wait while a
    conversation / cutscene is up (VM: "the day starts once the conversation is over", then the day).
  - Lead mode: the meeting place marked; F there ends the third, F 594 away refused (VM).
  - Mouse (VM): hover selects via the game's own steps (main menu, Select Your Cat grid, clan crests via native rects,
    creator pattern / colour grids, pause menu); clicks = select + the real confirm key; footers by their key icon's
    command (Continue = Button_Y); creator 1 / 2 tabs; pause tabs on click only; map drag (held WASD) + wheel zoom
    (held Up / Down). Map icon INFO (the game has none): pointing at an icon shows its name by the cursor - from the
    map's own legend by texture, else the creature kind (VM: Player, Clan Outpost, Mice).
  - Name box: the screen maps Enter to its confirm commands itself (OnListenCommand 5 / 26 / 28 with the rows
    blanked) -> SwallowKey Enter while on the list; VM: Enter -> box, "cd" typed, Enter -> next screen.
  - Colourpoint: entry 24 of the pattern grid with Tabby's icon (looks like a second Tabby) - P2: its own icon.
- [x] **P2: Colourpoint needs its own grid icon** - done 2026-10-28: Icon = T_UI_Marking_12_D (masked face), VM-checked.
- [x] **P1: the evening = small groups by relationship, not one ring** (operator spec, 2026-10-28) - BUILT
  2026-10-29 (WaCa-ClanLife b0c1600): Groups: Tongues|Prey, config/relations.ini, names from the game's text, walk-in
  via the AI controller. VM: groups logged by name, tensions kept apart, cats walking to seats (leg 14: 3 of 6 walked
  all the way at the meal, 2 of 5 for tongues, the rest most of the way then set down - at the VM's 0.2-0.6 fps).
  Rules self-test on a made-up roster (WaCaGroupsSelfTest): tensions / leader-with-mate-or-deputy / sizes PASS,
  apprentices together 82% PASS.
  - [x] 2026-10-29 (c977490) walk-in: the cats' own behaviour tree was never paused (PauseLogic did nothing - their
    pacing overrode our order); StopLogic + a game-time clock -> VM 6 of 6 seated at the meal, 5 of 6 for tongues
    (one stuck on geometry, set down).
  - [x] 2026-10-29 (6bf0904) groups are fixed rules, never chance (operator): leader + mate + deputy unless
    LeaderAway / DeputyAway, queens with kits, by role in 3s / 2s, BigPrey for a 4; the camp's named cats take part
    where they stand (Lionstar, Freezesong, Tigerclaw ...). VM: self-test PASS on every rule; RiverClan's camp
    "1: Lionstar (Leader), your cat (Deputy)" at both group steps.
  - [x] 2026-10-29 (d38d2db) operator: "some randomness is fine but we need a control lever / override": per-day duty
    chances (days.ini <Third>Duties), RepeatFactor against repeats, group levers ([Pairs], [Tensions], story steps
    Pair / Part, LeaderAway / DeputyAway, BigPrey / NoBigPrey). VM self-tests PASS; real camp: Lionstar + your cat
    fixed, warrior groups by chance, a group of 4 round prey.
  - [x] 2026-10-29 (ClanLife) levers on the remaining dice: Event:<Name> = 1 / -1 + days.ini Events / NoEvents
    (VM self-test PASS), ClanPatrol = 1 / -1 (VM: "one leaves this evening - ClanPatrol = 1"), patrol points / hunt
    spot never the last ones again while there are others; other mods: WaCa.Emit("SetStoryVar", name, value).
    Untouched (cosmetic): camp idle activities, dialogue line shares, prey spawn spots.
  - [x] 2026-10-29 (6c2a7fc) camp cats keep their names per save: keyed by their spawn point (SpawnPointRef), the
    first name kept in WrcGame.<slot>.WaCaCampCats.ini and written back each load. VM: load 1 "6 new", load 2 "6
    kept" - the same six names. Groups never leave one cat alone (7 -> 3+2+2).
  - [ ] P3 (operator 2026-10-29: "just leave it and note it down as a ticket for later"): ShadowClan's lake-era
    meeting place - "the fallen log" for now (Victoria Holmes); look it up in the books later (fan sources also
    mention a branch / stump).
  - [ ] P2: the walk-in through a navmesh path (the 3 of 6 that slide along camp rocks) - a pathfinding order first,
    the straight move as fallback, was written and NOT verified (a rabbit stalk started a fight mid-run); reverted.
  - [x] 2026-10-29 (Hunting e76beda) hunt-chance label: it sat in the insta-kill paw, shown only for prey low enough
    to kill outright; now under the prey's level warning within LabelRange (15 m). VM: "95%" under the paw of a
    rabbit 5 m off (a prey picked with no creature within 25 m - fights mapped), nothing at the horizon. OPEN: the walking
  cats' names are random per load (name ties only hold for story cats - a per-save identity for camp cats?); only
  3-6 walking cats near RiverClan's camp, so 1-3 groups, not 5-6 (more cats = the parked quest cats, which don't draw
  when moved - stage them in place?).
  - Sharing tongues: 5-6 small circles of 2-3 cats each, spread over the camp.
  - Sharing prey: groups of 2 or 3, sometimes a group of 4 around a big piece of prey.
  - Who sits with whom follows like / dislike: two cats with tension (story tensions) never share tongues. The
    leader only ever with its mate and/or the deputy. Apprentices most likely with apprentices. Mates together, etc.
  - Needs: (1) each camp cat's identity - rank, clan, name (find it on the walking NPCs: CustomData /
    narrativeRole / CurrentRank as on AQuestBaseActor; the game's NPC generation manager hands out roles + names);
    (2) a cat-to-cat relationship table - the game only keeps the PLAYER's bond per story cat
    (AddPersonalBonding), so ClanLife needs its own (ini: Mates, Tensions, Friends; story beats change it via a
    step, e.g. `Tension: A B`); (3) group-aware staging: several small arcs/circles at camp spots (the game's
    target points / den fronts), each group facing its own middle, still all in view of the camera or framed one
    group at a time. Your cat joins a group by its own bonds/rank.
  - THREE different things, never mix the words (operator 2026-10-28):
    - the evening in camp = these small groups (eating, sharing tongues);
    - a CLAN MEETING / ceremony (apprentice / warrior naming, announcements) = the leader on its rock, "speaker on
      stage", the clan an AUDIENCE in rows / a fan facing it - the current Gather step (an arc facing one point) is
      the start of that layout, with the leader as the point;
    - THE GATHERING = all four clans meeting on the island (the game's own line: "the four become one under the silver
      moon ... where the Great Oak stands", STR_QUEST_FINDLOCATION_ISLAND_01) - gatherings.ini.
- [x] **P1: clan meetings use the books' words and each clan's own meeting place** - DONE 2026-10-29 (a551f49):
  {MEETINGPLACE} from duties.ini [MeetingPlace], ThunderClan = the Highledge, Default = the leader's rock; VM card
  verified. 2026-10-29 (e631a54): RiverClan = the Highstump, WindClan = the Tallrock, ShadowClan = the fallen log
  (Warriors Wiki / Victoria Holmes); VM: "... gather beneath the Highstump for a Clan meeting!" (RiverClan). (operator 2026-10-28): the
  summons as in the books - "Let all cats old enough to catch their own prey gather beneath the <place> for a Clan
  meeting" - and ceremonies in their book form. BUG NOW: clanevents.ini [Event.ClanMeeting] and days.ini (Evening
  card) say "the Highrock" for EVERY clan - and Highrock is ThunderClan's OLD FOREST spot (operator caught it); this
  game is the LAKE era (the island + Great Oak), where ThunderClan's leader speaks from the HIGHLEDGE (Twilight:
  Firestar on the Highledge above the stone hollow - confirmed via a book excerpt). The game's text names no meeting
  place (Strings_EN has none), so it's config per clan (e.g. clanevents.ini [MeetingPlace] ThunderClan = Highledge,
  ...); RiverClan / ShadowClan / WindClan's lake-era spots: from the books with the operator, don't guess. A
  {MEETINGPLACE} placeholder in cards.
- [x] 2026-10-29 **The camp's NAMED cats move about** (REBUILT - the costume walkers were rejected: operator "I don't
  want the unnamed cats to be assigned a name ... they should be the same type of object" -> "remove walkers, move
  named cats"; then "not all cats should walk, and ideally which walk should change ... the important cats (trainer,
  medicine cat) stay close to where they sit, idle cycle a bit ... they stop when spoken to"). walkers.lua now: the
  nameless walking cats hidden (AI stopped, no collision); each third of the day a few named quest cats move, longest
  -unmoved first - roamers (plain warriors / apprentices / elders) across camp to dens' fronts / fresh-kill / meeting
  place / another cat's spot and home; homebodies (any cat with a part) to a spot 1.5-3.5 m away and back. The game's
  walk anim (single-node, then back to the anim BP), swept moves, following the ground (knee-height WorldStatic trace:
  a level move buried Lionstar in his hillside, a trace from 3 m up put him in a tree). Only cats the game was SEEN
  drawing take part (hidden != out of range: an online-only giver never draws). Talk = the game's
  WBP_QuestGiver_Dialogue* screen (NpcRef = the cat): every mover holds, that cat stops; closed -> moving again.
  Walk:<Name> lever, walkers.ini Never. Public event WalkerMoves(name, path, home|away).
  VM 2026-10-29: turns + sets off / is there / home logs; walking cats drawn (WasRecentlyRendered) at 3-17 m;
  conversation with Blackheart mid-trip -> stops, released on close; turns wait for the world (a load-time turn crashed
  the game twice - fixed and re-booted clean; the walkers-off boot was clean too). A QuestBaseActor:OnDialogSetActive
  watch was dropped while bisecting (suspected, NOT proven; the dialogue screen covers it).
  Evening groups: named cats walk to their seats (scene speed, per-cat limit) - VM 9/9 walked in (4-19 m, 13 s),
  home again on release. ClanLife 551cb7c. SEEN 2026-10-29 (noon, VM): a named cat mid-stride crossing the grass
  (WalkerWalkTo, ClanLife). Suffix box SEEN on the ceremony's "CHOOSE WARRIOR NAME" popup (top right).
  FIXED (ClanLife c12f400): a mod reload mid-walk left cats on the walk anim - a turn now idles them where they
  stand (VM: "3 cat(s) left walking by an earlier run - idle again").
  **P3: more named camp cats** to make up for the 6 removed walkers (operator: "later add extra camp cats").
- [x] (walk-in BUILT 2026-10-29, see the P1 above) **P2: the evening in camp (sharing tongues / the meal) - the cats WALK in, with the game's own NPC logic** (operator 2026-10-28: "the game
  will have its own inbuilt logic for placing and displaying cats, for having them pace"). Found 2026-10-28 (VM):
  the camp's quest actors (fillers, deputy ...) are mostly PARKED (38/41 fillers: body SkeletalMeshComponent off,
  a DisableRequester on their USwtQuestHideByDistanceComponent); the rest are hidden by a 23 m hide sphere. Quest
  actors teleported into a ring never drew (body "visible", never rendered) - so Gather now uses the walking camp cats
  (ASwtAdventureWalkingNPC / BP_WalkingNPC_Character_Base_C, AIC_Wrc_WalkingNPC_Controller): moved in, the game shows
  them at once and their AI resumes (paused while staged). NEXT: let them walk in instead of a fade-cut -
  SimpleMoveToLocation did nothing while they were hidden/far (frozen out of range); try once in range, or drive the
  game's own BT tasks (BTTask_NPCSplineWalking, ASwtQuestWalkingSplineActor, ASwtQuestNPCTargetPoint.WalkingSpline,
  UQuestObjectiveTeleportNPCGiverTask + ASwtQuestNPCMoveObjectivePoint = the game's own "move a giver" step). Same
  machinery serves the P1 walk quests (mentor walks you to the den).
- [x] **P1 (operator 2026-10-28): "walk quests" for the story mod** (DONE 2026-11-01: the Lead step, VM-verified end to end) - e.g. promoted to apprentice, the mentor WALKS you
      to the apprentice den to meet the others: the cat leads (paths over, waits when you fall behind, goes on when you
      catch up), no quest marker. A scene step on follow.lua (Follow.Travel for the leader + the player's distance).
      Reuse the game's battle animations in cutscenes (hackles raised, sneaky / subdued poses - operator 2026-10-28).
      BUILT 2026-11-01 (Clan Life, scene step Lead: <place> @ <who>; example pack MentorTour): the cat comes to your
      cat first, leads (walkers' mover), waits when you're 6 m behind, goes on within 3.5 m; places Den:<den name> /
      Zone:<code> / Pile / a cat. VM: come-to-you, lead, wait, go on all seen. NEXT (VM, when the operator isn't
      playing): the arrival with the no-headway fallback (the 300 s limit ended a slow VM walk early).
      ARRIVAL SEEN 2026-11-01 11:11 (VM): Otterfeather came to your cat (26 m), led to the Apprentice's den (40.6 m),
      waited, went on, arrived on its own ('led your cat to Den:Apprentice's den', no fallback), the closing card.
      Writers: docs/WRITING.md (Clan Life). Drop Z:/WaCa/WaCa-mods-test-20261101n.
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
- [x] **UE4SS injection.** DONE: UE4SS 3.0.1 runs (Lua + the WaCaNative C++ mod), object + header dumps in dumps/. Get UE4SS running: check SteamStub / EOS / any anti-cheat; the game uses the EOS SDK for its
      online content. Live object dump + C++ header dump for a skeleton project. Lua hello-world hook on a gameplay
      function.
- [x] **Deploy rule.** DONE: the release zip installs / uninstalls itself (Install.bat / Uninstall.bat); the Z:
      install is ours to modify (operator), backups as *.vmtest-backup / before overwriting. Installing a mod writes into the game folder on Z:. Agree with the operator where mods are
      installed and how to uninstall cleanly; never rm -rf on Z:. Back up any file before overwriting it.
- [x] **Time follows effort, not the wall clock** (DONE - built as part of 15) (operator 2026-10-28: "bind time directly to cat exhaustion based on
      the current activity's time slot (morning / afternoon / night)"). Operator: "a true time of day cannot really be
      wired UNTIL we have the day/night clan sim" -> BUILT AS PART OF 15 (2026-10-28, see there): the clan's day
      drives the clock by the cat's effort per slot. Refined by the operator the same day: exhaustion is NOT the
      clock - it's a resource that only drops with things DONE (pounces, fights); walking moves the time but never
      tires (see 4).
- [x] **Sight during the pounce walk** (operator 2026-10-30, "ideally also sight" - if a proximity sense doesn't make
      prey uncatchable) - BUILT + VM-tested 2026-10-30, OFF by default: WaCa Core runs the game's own detection pass
      (WaCaNative_HuntDetect - the function UBTService_DetectionTask's tick calls) on the hunted prey through the walk.
      RESULT: by the game's own rules a WALKING cat 3 m off is noticed from any side (types 7 and 5, from behind and both
      sides: 6 of 6 noticed) - the very proximity sense the operator feared; that's why the game turns detection off
      for the walk. Kept as [Prey] SightDuringPounce = 1 (experimental). A sight that stays fair would need our own cone
      rule (the game's view cone without its proximity) - operator's call.
- [x] **Following: cats moving together** (operator 2026-10-28, big modding tool): many cats pathfinding together -
      DONE 2026-11-01: speed matching + fading out of view both built and VM-verified (see below).
      your pack runs through the forest with you and only holds back when you're sneaking; for Gatherings 10+ cats
      make their way over to the island. A Lua API (follow.lua): a group follows a leader (the player or any cat) at
      spread-out distances, matching walk / run, holding back while the leader sneaks; or travels to a place as a
      group (in formation, the slow ones caught up). Started from the patrol companions (duties.lua: AI MoveToActor,
      the cat's own brain paused).
      BUILT 2026-10-28 (follow.lua): Follow.Group(cats, leader, opts) - staggered MoveToActor, checked at the leader's
      FOOTSTEPS (every cat's steps are events - no ticking), holds back while the leader crouches (the game's
      OnExplorationCrouch, bValue handed over), catches up after; Follow.Travel(cats, place, opts, onArrive) -
      formation rings around the place, arrival checked at the travellers' steps; Follow.Release; Follow.Nearest.
      The patrol companions and patrols.lua use it. NOT yet seen on the VM (the companions' earlier MoveToActor
      version joined, the follow itself unconfirmed). OPEN: speed matching (run with the leader), fading out of view.
      STATUS 2026-10-31: the AI follow can't work on this map (field / camp cats have no movement component - AI moves
      fail, VM 2026-10-30), so the walkers' mover does it all, VM-verified: your party runs with you (walk / trot / run
      matched, holds while you sneak, catches up - the speed matching), escorts walk with you (patrol companions,
      TemporaryParty, the Gathering party), patrols and the Gathering party travel as a group to places and home. Left
      open: fading cats out when far from view (cosmetic, not started).
      DONE 2026-10-31 (VM, walkers.ini [Walkers] FadeAt 60 m): a walker that far from your cat and not drawn lately is
      hidden on its way and stepped without ground checks; shown again - set on the ground - within 0.8 x FadeAt or
      when it stops. VM: a 3-cat patrol hid past 60 m, showed at its stops (+0 cm), hid, and on the home leg showed at
      48 m set down 1.6-1.8 m (the straight line had drifted above the slope); all home. Not a real opacity fade (the
      cats are out of sight when it happens). Drop Z:/WaCa/WaCa-mods-test-20261031zb.
- [x] **NPC patrols heading out together** (operator 2026-10-28; DONE 2026-11-01): when the deputy assigns patrols, see them leave
      together. BUILT (patrols.lua, patrols.ini, off): at a third's start, by chance, Size cats from the camp travel
      together (Follow.Travel) to Points border points and home, then get their own AI back; their roles speak
      Case = Patrol lines meanwhile. OPEN: fade them out when not in view (future); talking to a patrol stops it a
      moment (future).
      BOTH DONE (checked 2026-11-01): the clan's patrols walk with the walkers' mover (Walkers.Patrol; the AI-walk
      path is only the fallback) - far + unseen = hidden on its way (VM: NpcPatrol 3 -> Blackwing, Pinefur, Paletail
      out, 'Pinefur is far out of view - hidden on its way'), meeting one stops it while each cat speaks (PatrolMeet).
- [x] **NPCs do their jobs** (operator 2026-10-28, future work): an NPC's task is real - it walks to its assigned
      DONE 2026-11-01: hunters (real prey), patrols, the medicine cat's herbs - all VM-verified.
      hunting spot and (optionally) tries to hunt; walk near it or its prey and it tells you to give it space and not
      ruin its hunt.
      BUILT 2026-10-31 (walkers.lua [Jobs]): hunters out at a morning / afternoon to the game's prey places 30-90 m
      from camp, a stay, home; near one while it hunts -> a line (ShowLine). VM: Blacktail out 66 m, its line on screen,
      home after. Not yet: the hunter actually catching prey (a pounce animation at the spot) - optional per the spec.
      DONE 2026-10-31 (VM): at its spot the hunter hunts - sniffs, stalks, leaps (the game's montages, a short lunge)
      and catches by chance ([Jobs] CatchChance 40 / TryEvery 25 s; event NpcHuntTry(name, caught)). VM: Pineblaze 5
      tries, 4 caught; Blackdash's mesh read live: AM_WC_Hunting_Leap then AM_Interact_Bite_1. Cutscenes poses Stalk /
      Pounce added. Test drop Z:/WaCa/WaCa-mods-test-20261031n. (Real prey to catch at the spot: not spawned - a
      visual hunt.)
      REAL PREY 2026-10-31 (VM): the hunter goes for the game's prey near its spot (15 m) - faces it, leaps onto it;
      caught -> WaCa Hunting's PreyTaken (gone, as the player's catch), missed -> PreyScare (bolts, gone); none near ->
      acted out. VM: Willowstorm caught one ('caught by Willowstorm'), Sagefur's missed prey ran off. Drop
      Z:/WaCa/WaCa-mods-test-20261031o.
      MEDICINE CAT 2026-11-01 (VM, [Jobs] Herbs = 1): each morning the medicine cat walks to one of the game's herb /
      moss pickups 20-90 m out, sniffs + digs, comes home (NpcGatherHerbs / NpcHerbs). VM: Freezesong 75 m out, gathered,
      home again. Drop Z:/WaCa/WaCa-mods-test-20261101i.
- [x] **Patrol encounters** (operator 2026-10-28, future work): run into a patrol out patrolling - it stops a moment,
      DONE 2026-11-01: the meet, each cat's line, VM-verified; talking to each cat = the game's conversation (operator's play).
      you can talk to them, and each cat (by who leads the patrol) says one of its assigned messages for the day for
      this case, or on normal days one of its patrol lines. The LINES are built (lines.ini [Dialogue.*] Case =
      Patrol / Leader, the daily grab bag); the stop-and-talk isn't.
      BUILT 2026-10-31: the clan's patrols walk with the walkers' mover now (camp cats, border points, home); meet one
      -> it stops, its leader says a [PatrolMeet] line (subtitle). VM: Owlleaf's patrol stopped and spoke, walked on.
      Talking to each cat (the game's conversation) stays the operator's check - the VM opens no conversations.
      EACH CAT SPEAKS 2026-10-31 (VM): on a meet every patrol cat says a line in turn (3 s apart): the leader's from
      [PatrolMeet], the others' from [PatrolMeet.Member], a cat's own [PatrolMeet.<Name>] first, by who leads
      [PatrolMeet.LedBy.<Name>]; {LEADER}; no line twice in one meet. VM: Maplefang, Cricketdash, Slatefeather each spoke.
      CRASH FIXED on the way: the walkers' ground check called GetMaterial(0):GetFName() on a hit with no material -
      the game died (null 0x18 in UE4SS) as a patrol set off. New WaCa.HitMaterialName (Core) used in walkers, stage,
      wading (the wading one ran every tick - a likely cause of the 16:24 crash too). Drop Z:/WaCa/WaCa-mods-test-20261031za.
- [x] **Dialogue by days + the daily grab bag** (operator 2026-10-28: "all dialog should be able to be defined like
      this, e.g. Queen 1 between Day 1 and 6 picks a random dialog to play each day out of 3"; "our filler pool must be
      able to change for given cats on given days"). BUILT (lines.lua): [Dialogue.<Name>] Who / Days / Require / Case /
      Leader / Line1..N - one pick per day by a grab bag (no repeat until all came; the last two of a bag wait out the
      next refill), kept with the save; random pools [Lines.<Role>.<Tag>] with Days / Require too; the game's own line
      comes back when nothing fits. Granularity = the game's filler keys: per role (named story cats have their own).
      Offline: A B C D -> D B A C | D B C A | B; queen days 1-5 pool, day 6 the story line, the kit's pool gone after
      day 3. Lua: Lines.Pick(name, lines, day).
- [x] **Overlapping mods: content from every mod** (operator 2026-10-28: "a modding framework ... if two mods have to
      overwrite the same ini, that's bad"). BUILT (WaCa.ReadContent + WaCa.EnabledMods): the clan configs (duties,
      clanevents, days, events, gatherings, lines, patrols) are WaCaModKit's file + every enabled mod's
      content/<name>.ini in load order: new sections added; shared sections get numbered keys APPENDED (two mods add
      beats to the same day / lines to the same dialogue), plain keys overridden by the later mod (logged); Off = 1
      turns another mod's section off.
- [x] **Explicit overrides instead of load order** (operator 2026-10-28: "load order as core design choice?" - no):
      WaCa.ReadContent today lets the later mod win a plain key. Make it explicit and order-independent: ids
      namespaced (<Mod>/<Section>); a mod overrides another's section only with Replaces = <Mod>/<Section>; two mods
      setting the same plain key without that = a reported CONFLICT (log + an in-game notice), not a silent winner.
      Load order only as the last tie-breaker. Appended steps stay per owning mod (see story packs).
      DONE 2026-11-01 (WaCa Core ReadContent; offline + VM): Replaces = <Mod>/<Section> replaces whole; a plain key two
      mods set differently without it = CONFLICT (logged with both mods + values, WaCa.ContentConflicts, a one-time
      notice in game); load order only breaks the tie; numbered keys append, Off = 1 allowed. VM: the shipped packs
      raise none; a test conflict -> the log line + the notice. Drop Z:/WaCa/WaCa-mods-test-20261101l.
- [x] **The party = who you're out with** (operator 2026-10-28; DONE 2026-11-01 for patrols, operator check left): the combat party should be the cats you're hunting /
      patrolling with that day, or when training your mentor / apprentice (not in a mentor-vs-apprentice spar).
      RESEARCH so far: the combat party is STORY cats by role (the save's GameplayProgression.Party.Stats keyed by
      narrative role: TheRegretfulWarrior, RiverClanDeputy ...); the game has a developer switch
      USwtAdventureCheatsManager.ForcedParty (TArray<FAdventureForcedPartyStruct>: CharacterNarrativeRole + Attacks)
      that likely sets the fight's party - try setting it from the task (patrol / hunt companions, the mentor) before
      a fight and clearing it after. Needs: companions picked from story cats (roles) rather than generic clanmates,
      or a mapping; VM test whether ForcedParty is honoured outside a dev build.
      TESTED 2026-11-01 (VM): ForcedParty is NOT honoured in the shipped game - written from Lua (read back: 1 entry,
      role 29 TheRegretfulWarrior), then a sparring fight (the game's own combat box, TrainingGrounds): the party on
      the fight screen was the same as without it (Nightheart, Dapplepatch, Rippleface - both screenshots). The
      fight's party = the save's party (QuestProgression PartySetup, the PARTY page). Next route, if wanted: the game's
      own party change (the PARTY page's set function) before a fight and back after - research.
      On the way (all fixed, VM): four crashes 'reading 0x10' were (a) UE4SS's game-thread timers firing while mods
      still loaded (now held - WaCa.lua's timer guard; 5/5 boots clean after 3 of 4 crashed) and (b) my probe reading
      a null combat MainCharacter; WaCa.CustomData made the look-data reads null-safe on non-cat characters.
      PARTY CHANGE RESEARCH (2026-11-01, parked - a native RE project): the party is set by quest tasks -
      UQuestObjectiveSavePartyTask (PartyRoles / <Clan>PartyRoles: TMap<ECharacterRank, {Setup: [narrative roles],
      OptionAlly}>, bClearOnQuestRemoved); 126 loaded, inside the quests' objectives (RankUp_0 [rank 2: RiverClanKit],
      combat milestones [rank 4: RiverClanKit + RiverClanWarriorMoveLearn] ...). The maps are reflected (editable from
      Lua); the live party is native (no reflected field). The task's vtable 0x149a9f440 overrides only +0x2b8
      (0x1416ee040 - empties its map: cleanup); the party is applied by the owning objective's native code. NEXT if
      wanted: trace the objective's start (where it reads its SavePartyTask) -> the party store, then a WaCaNative call.
      MORE (2026-11-01, VM): the pause PARTY tab only shows the party (no change in the game). The save keeps it as
      QuestProgression.Chapter00.PartySetup [{NarrativeRole, CharacterTag}] (WrcGame.json; RiverClanKit +
      RiverClanWarriorSideRace = the fight's Nightheart / Rippleface), read by the save's JSON code (exe 0x1416A555B,
      'PartySetup' UTF-16 at 0x149AE8298). AQuestPlayerController.Party (+0x838) is empty. A scan of 2614 objects
      (managers, save, quest components, one level into their arrays) found no live copy of that role list - it lives
      in native quest data. Routes: (a) trace the JSON reader at 0x1416A555B to its destination (then write it
      natively), (b) hook the combat director's party build (PlayerParty +0x460 / CharsPlayerPartyRef +0x4A0) at
      fight start, (c) edit PartySetup in the save between sessions (tools/save_edit.py - not live). Parked.
      BUILT 2026-11-01 (VM): the story fight's director keeps the party as roles at +0x788, filled by its virtual
      +0x9E0 - hooked there (Core party.cpp, WaCa.SetCombatParty / Party|<roles>): the list is replaced, the game
      builds the cats its own way. Spar with Party|29 -> Dapplepatch + TOADFROST. Clan Life: a patrol's story cats
      (patrols may now take the story cats the save keeps combat stats for - Party.Stats - first) fight beside you
      till the patrol ends: forced patrol next to Toadfrost -> Toadfrost + Otterfeather joined -> that fight party.
      Walkers now wait during spars too (a live director = a fight). HUNTS too: [Hunt] Companions (default 0 - a
      hunting patrol; VM with 2: Toadfrost + Otterfeather -> that party). Training = the spar itself (excluded). NOT YET:
      generic clanmates (no story role - the game's party fills in). OPERATOR: hunting patrols on by default?
      Story pack starts take Party = <roles> (kept every session). Drop Z:/WaCa/WaCa-mods-test-20261101s.
      LIBRARY: scene step Party: <story cats> (names anywhere in the world, E:<role>; none = the game's), kept with the
      save (VM: example FightBeside -> spar with Toadfrost; saved, next session restored). Drop ...20261101t.
      MORE: Party: S:<role> follows the role's [Cast] cat (VM: S:herbalist = Mossfeather fought beside you; S:loner,
      a brought-in Rogue, refused with the reason). Writers: [StoryCheck] Watch = 1 reloads on an edited story file (VM).
- [x] **Murmurings: what the clan thinks, every day** (DONE 2026-10-31, VM) (operator 2026-10-28, a note for later - side dialogue): replace
      the dummy filler text with real "murmurings" that change every day, even if not deep: how each cat feels about
      other cats, the leadership and recent events - so it SHOWS whether the leader is loved or trusted, whether the
      clan is split on a decision. Builds on lines.lua (filler pools) + the story variables (Gatherings) + recent
      events (duties' verdicts, the story's beats).
      BUILT 2026-10-31 (murmurs.lua, lines.ini [Murmurs] / [Murmur.<Name>] Require / Who / Line*): a camp cat you pass
      murmurs (subtitle) once a day by chance, lines from every matching set (Standing, Pile, Season, Weather,
      LeaderFavour, Gathering.Today ...), the daily grab bag. VM: two cats, matching sets, lines on screen. The talk-screen
      filler (lines.lua pools) can take the same sets later.
- [x] **Apprentice duties** (operator 2026-10-28, future work): new clan-loop tasks for apprentices (duties.lua task
      DONE 2026-11-01: gather / water / bedding + the report key (real F) VM-verified.
      kinds, drawn by [Tasks] weights / set by the story):
      - fetch fresh moss for the medicine cat (gather moss out in the territory, bring it to the medicine cat's den) -
        its turn-in: talk to the medicine cat ([Task.<Kind>] TurnIn = MedicineCat - supported);
      - clear out the old bedding moss (from the dens, out of camp);
      - water moss: soak moss in the lake / stream and bring it to cats too weak to move so they can drink - more
        often in greenleaf (summer), the season from weather.lua. Needs a "weak / sick cat" (an elder, the medicine
        den) and a carried-item state (no carry mechanic in the game yet - research: quest pickup items,
        BP_Objective_Base pickups).
      BUILT 2026-10-31 - GATHER (moss / herbs for the medicine cat): duties.lua task kind Gather, [Gather] Count /
      Reach / MinDistance / MaxRank (Apprentice), [Tasks] Gather weight; the game's own pickups (moss containers where
      the world has them - none loaded on the VM save - else healing herbs / catnip), marked, gathered by reaching
      them, turned in to the MedicineCat. VM: assigned, 3 spots, 3/3, 'turn it in: report to the medicine cat'.
      Operator check: the report key next to the medicine cat (the VM harness's keys have no key name). Still open:
      BUILT 2026-10-31 - WATER: soak moss at the nearest water (fishing spots), bring it to the elders (report:
      Elder - Sharpfoot on the VM save), x3 in greenleaf; the carrying is the task's own state, no carry mechanic needed.
      VM: soaked -> 'report to the elder'. All three apprentice duties built; operator check: the report key in play.
      BUILT 2026-10-31 - BEDDING: into one of the clan's dens (its inside point), the old moss to a marked spot out of
      camp, report to the deputy. VM: Medicine Cat's den -> taken -> thrown out -> report.
      REPORT KEY SEEN 2026-11-01 (VM, a REAL F key - vm_input key 46 carries the key name the harness's HoldKey lacks):
      water soaked -> next to the elder Sharpfoot, F -> 'water for the elders turned in (Elder)' -> the evening began
      with its clan event. The medicine cat / deputy turn-ins use the same report path (role by name). The log now
      names the cat (the actor's class misled: Sharpfoot is a BP_Quest_Giver_Deputy).
- [x] **18. More graphics options.** DONE 2026-10-27: config/graphics.ini - [Scalability] the engine's groups (sg.*),
      [CVars] any console variable (motion blur, DoF, fringe, screen %, t.MaxFPS listed), applied through
      ExecuteConsoleCommand at start and after the game's options popup closes. VM: read back sg.ShadowQuality 0,
      r.MotionBlurQuality 0, r.ScreenPercentage 50 (the VM's own setting would give 25). An in-game menu for them =
      with the keybind menu (19a).
- [x] **P3: cutscene shots through foliage** (FIXED 2026-11-02 by staging - see the end) (seen 2026-11-01, LonerVisit at the camp's river edge, 960x540): the
      camera looked through a bush (leaves and reeds across the frame, Quill at its edge). Foliage has no collision, so
      the sight trace can't see it. MEASURE FIRST (the camera 'bug' earlier the same night was a misread): project the
      cats to the screen and count foliage instances on the camera -> head line (an overlap / instanced-mesh query), then
      turn the shot. Data in hand: scratchpad cam_probe.lua.
      MEASURED (2026-11-02, VM 960x540): the blockers are a big tree's roots + LEAVES round the camp's river edge.
      Every physics query says clear (traces on Visibility / Camera, instanced-foliage overlaps: 0, plain meshes'
      bounds: only our rain cylinders). A scene-DEPTH capture from the camera pose works (cm along the view, read a
      frame later - scratchpad depth_probe.lua) but the leaves don't write depth (a 7x7 window read 100% seen while
      Lionstar was half hidden) - so it would only catch opaque blockers; built + REVERTED (never seen to trigger).
      What's left: an image check (a colour capture of the cat alone vs the full scene) or simply prefer shot
      directions away from big trees. Open, low priority - the shots are valid, just ugly in that one spot.
      IMAGE CHECK TRIED (2026-11-02, VM, scratchpad color_probe.lua): three HDR scene captures from the camera pose in
      one frame - the scene, the cat alone (show-only list), the sky alone (empty list); a cat pixel = cat-alone !=
      sky-alone, seen = scene ~ cat-alone. Result: the cat-alone capture equals the sky everywhere, even in a Two shot
      with Lionstar plainly on screen -> the cats don't render into scene captures (which also explains the depth
      check's '100% seen'), or the probe took Lionstar's parked home copy (two exist). Captures queue and render
      together at frame end (hiding a cat between two captures of one frame hid it in both). NEXT if picked up: take
      the cast actor from Cutscenes (not a name search), and check a cat's mesh in a capture's show-only list on open
      ground first; if cats never render in captures, this route is closed.
      DONE (same night): the PLAYER's own cat (unambiguous, on screen, open camp ground) in a show-only capture - with
      its attached actors (none) - the cat-alone image equals the sky-alone one except sky noise along the top row.
      The cats do NOT render into scene captures (all four capture checks: depth, difference, show-only, the player).
      CAPTURE ROUTE CLOSED. What remains is a placement rule (keep portrait / two shots out of big trees' crowns -
      e.g. a ring of traces at head height around the camera spot catching trunks/roots as a proxy for the leaves
      above them), to be judged by the operator's eyes at a real resolution. Low priority.
      RING RULE TRIED + REVERTED (2026-11-02): enclosure by 8 short traces (portrait spot 7/12 hit, open camp 0)
      counted as half-blocked - the Portrait turned 70 deg instead of -35 and a trunk filled the frame (Lionstar
      gone). The scene itself stands inside the tree's root zone: no camera direction round it is good. The fix
      belongs to the STAGING (Place = Here choosing a spot whose surroundings aren't enclosed - the same ring test on
      the scene's middle), not the camera. Next if picked up: score Place = Here candidates by enclosure (cheap, the
      measurement is in hand) and compare the frames at 960x540.
      DONE (2026-11-02, VM 960x540): Place = Here scores its spots by enclosure (EnclosedAt) - LonerVisit from the same
      spot was restaged 90 deg and the Lionstar portrait was clear and large. WaCa-Cutscenes 'Place = Here keeps scenes...'.
      2026-11-02: the camera itself now sees plants with no collision (WaCa Cutscenes Camera FoliageRadius -
      instance boxes along the line), not only staging - VM: the Portrait turned to a clear view past the reeds.
- [x] **P3: party cats in a cutscene's frame** (found 2026-11-01, library exercise; FIXED same day): the cats that follow you (walkers'
      party) hold where they stand during a cutscene - a scene placed Here has Nightheart / Rippleface standing in its
      shots. Fix: hide (or step aside) non-cast party cats within the stage's radius for the scene, back after.
      Also seen: two Toadfrost actors exist (one 140 m off, never drawn) - Cast takes the nearest; harmless so far.
      LIBRARY EXERCISE same day: FightBeside cutscene + the new Wait beat (Cutscenes) - VM ok.
      FIXED: Cutscenes sends the cast's paths with CutsceneStarted; Clan Life's walkers hide the party cats not in it for
      the scene (VM: '2 party cat(s) out of the cutscene's shots', the frame clear of them).
- [x] **P3: a cutscene camera behind scenery the trace can't see** (CLOSED 2026-11-01 - NOT A BUG, misread screenshots; 2026-11-01, FightBeside at the camp's river
      edge): the Two shot logged no 'blocked' (its sight trace on the Camera channel found the way clear) while the
      frame showed a rock face and no cats - likely a rock without collision on that channel. Next: trace on
      Visibility too / against the rendered depth, or check the cats' WasRecentlyRendered after the move and try the
      next direction when they aren't. Needs a closer look at a real resolution (0.5 fps / 480x270 is too coarse).
      MORE (same day, VM): on open camp ground the FightBeside shots frame both cats (Two, Portrait with TailUp) - the
      bad frames are the RIVER EDGE: Place = Here stages the scene where your cat stands, and there the Two shot went
      10 m out over the water (the frame a flat pale blue - the camera at / under the water's surface; water has no
      collision for the sight trace). Built meanwhile: [Camera] SeenCheck (turns a shot whose cats weren't rendered) -
      not seen firing yet. Next: keep the camera above the water surface (Hunting's wading finds the planes) or fit
      the stage away from water.
      TRIED (same day, VM, timed shots): WaterClear (camera held 60 cm above water - never triggered) and SeenCheck
      (never triggered: WasRecentlyRendered stays true for a cat behind roots / from the previous shot). At the river
      edge (-46706 6269, facing -90) the Two shot looked low along the water, the Portrait sat in tree roots - neither
      cat visible. Both fixes are in (guarded, harmless) but NOT proven. The real fix: Place = Here should pick an
      OPEN spot near the cat (ground flat, no roots / water / rock within the shapes' radius + camera distances),
      and the tests need a frame rate where frames can be judged (CLAUDE.md: -ResX 960 or a real PC). Still open.
      TRIED the open-spot fit (same day): Place = Here weighs camera room (clear + dry 7 m behind, 4.5 m to the sides)
      and looks up to 7.5 m out - at -46706 6269 it still chose the bank (room 3 of 3) and the Two / Portrait shots
      stayed low over the river behind reeds. The room test doesn't match what the shots see (they pick their side by
      the cats' line, reeds don't block traces). STOPPED here on purpose: judging framing at 0.5 fps / 480x270 is
      guesswork - needs a real-resolution session (or the operator's eyes). Committed, unproven, harmless elsewhere
      (open camp ground framed fine).
      RESOLVED BY MEASURING (same night, VM at 960x540 + a probe: each cat's head projected to the screen, and the
      line camera -> head traced on Visibility and Camera): at the 'bad' river-edge spot EVERY shot had its cats in
      frame with clear lines (Two: Toadfrost x789, Dapplepatch x265 of 960; Portrait: Toadfrost centred; Over:
      Dapplepatch in frame). The pale planes were the river seen from ABOVE (sky reflection, lily pads from above),
      not the camera under water; nothing is above the camera on any channel. So: legit shots of small cats on a
      bank, not a camera bug. The three 'fixes' built on the misread (SeenCheck, WaterClear, the room-aware fit) were
      REVERTED (WaCa-Cutscenes fc22449 / d67961f / 578c6be). Lesson (CLAUDE.md already says it): project to the
      screen before judging framing from a 480x270 screenshot. Tool: scratchpad cam_probe.lua.
- [x] **16. RiverClan cats swim.** Feasibility unknown (water volumes, animation set, nav).
      DONE 2026-11-01: wading + swimming + all three exits VM-verified; a paddle animation needs new art (the mod pipeline).
      PREPARED 2026-10-28 (offline): NO swim animation in the game (only fish / duck / swan swim VFX), NO water or
      physics volumes in any map (all 266 maps' names scanned) - water = visual planes + floor types:
      EAdventurePhysicalFloorType Water = 4 / DeepWater = 3 on UAdventurePhysicalMaterial.FloorType (+0xA8); the
      step notify (USwtAdventureStepModifierNotifyState) already spawns the water-step Niagara on them. So "swim" =
      WADE: on Water / DeepWater floors the cat slows (Speed registry with exhaustion: CustomTimeDilation) - maybe
      RiverClan cats less. The floor: the player's CharacterMovement.CurrentFloor.HitResult.PhysMaterial.FloorType,
      read per footstep - the step notify is ONE shared object per animation (a ProcessEvent watch can't tell whose
      step), so it needs a native detour on its Notify virtual (MeshComp is a parameter). Needs the VM to build +
      verify.
      BUILT 2026-10-28 (wading.lua, config/wading.ini, ON by default: Shallow 0.8, Deep 0.6, RiverClan 0.5 of it):
        - WaCaNative_Watch / WaCa.Watch take a 5th arg: an OBJECT PARAMETER of the watched function handed to the
          handler after the object - so a shared notify tells whose step it was (no native detour needed).
        - the cat's footsteps are BP_AnimStepNotify_C's Received_Notify (VM: the C++ step notify never fires it) -
          MeshComp's owner == the player pawn.
        - the floor: CurrentFloor.HitResult.PhysMaterial is a plain material on the terrain; the floor mesh's
          GetMaterial(0):GetPhysicalMaterial() is the game's (VM: PM_Terrain_Dirt -> "floor type 1"). Water =
          PM_Terrain_Water / PM_Terrain_DeepWater.
        - the slow-down: WaCa.Emit("SpeedFactor", "wading", f) - exhaustion.lua multiplies all SpeedFactors into the
          one CustomTimeDilation (works with exhaustion off too).
        NOT yet seen: a step INTO water on the VM (no water near the test spot; the VM can't steer) - check in play;
        GetMaterial(0) may miss a water material on a multi-material mesh (then: the hit's face material).
      FOUND 2026-10-31 (VM, with WaCa.Command HoldKey to walk and floor reads): the RiverClan riverbed is the TERRAIN MESH
      (StaticMeshComponent, MI_Terrain_RiverClan_Terrain); the cat's floor hit carries NO physical material and the
      mesh's material 0 is the terrain's -> the floor type reads Dirt / Rocks everywhere (a 60 x 60 m trace grid round
      the camp: Dirt 483, Rocks 107, Wood 1, no Water / Grass) - so wading's floor-type test can't see this river.
      Kismet traces return no per-face physical material either. Water itself = flat planes (MI_WC_Water_RiverClan_*
      StaticMeshComponents, 20 x 20 m, surface Z in their bounds) - but a plane's box also covers banks (the cat on a
      dry slope inside one, 2.5 m under its Z): box containment would misfire. NEXT: the water plane's actual surface
      under the cat (a trace against the plane mesh itself - complex collision / its triangles) or the terrain's
      collision face material (GetMaterialFromCollisionFaceIndex with a complex trace). Wading stays as built; its
      water read is the open bug here.
      MORE (VM): the water planes have NO collision (0 of them; traces on channels 0-5 all hit the terrain under the
      plane) - a trace can't find a water surface. The stream right by the RiverClan camp isn't one of the
      MI_WC_Water_RiverClan planes (none within 60 m) - river water is more than one kind of mesh. A plane seen from
      below may be invisible (one-sided), so 'cat under the plane's Z' might be right after all - needs an in-play look
      (operator) at a spot where the cat is visibly in the river, then read its floor / the planes there.
      FIXED 2026-10-31 (VM): wading measures the water by its SURFACE - the MI_WC_Water planes are set QueryOnly with
      every channel ignored (nothing walks on them), a world-static object trace at each step finds the surface over
      the cat's feet: shallow under DeepDepth 35 cm, deep above, dry under MinDepth 5 cm. VM: shallow 21 cm at the
      ford, deep 253 cm beyond, out; the camp's level plane not wet. Drop Z:/WaCa/WaCa-mods-test-20261031p.
      SWIMMING BUILT 2026-10-31 (VM, wading.ini [Swim]): deeper than Enter 60 cm the cat swims - movement mode Flying
      (no gravity, input still steers), a 100 ms tick holds it Sink 5 cm under the water surface (flying input follows
      the camera pitch: it sank 55 cm in 8 s without), MaxFlySpeed = walk x Speed 0.6 (RiverClan 0.9), the wading
      slow-down off meanwhile; walking again under Leave 40 cm or with no water over the cat; event Swim. VM: into
      2.56 m -> swimming, held at the surface while steered, on screen in the water; teleported out -> walking.
      OPEN: the shallow-water exit seen on its own (in play: swim to a bank); a steep bank may hold a swimming cat
      (deep right to the wall - no climb out); no paddle animation (none in the game - the mod pipeline's job).
      Drop Z:/WaCa/WaCa-mods-test-20261031zc.
      2026-10-31 later: the SHALLOW EXIT seen on its own (VM: swum forward into 33 / 36 cm -> walking). Steep banks:
      [Swim] Climb 80 - land (not water) 70 cm the way you steer, at / over the surface -> climbed out onto it. NOT
      VERIFIED: no steep bank within 30 m of the test spot (the river shelves gently there), and a placed bank failed
      for test reasons (no engine cube in the shipped game; a scaled world rock wasn't hit by the traces; a probe
      reading a null mesh crashed the game). Also seen: at -40866,6059 the swimming cat didn't move with W at all
      (earlier it swam 6 m) - unexplained. Operator check in play: swim to a steep bank. Drop ...20261031zd.
      SOLVED 2026-11-01 (VM): the stall = bank terrain UNDER a water plane that reaches over it (swept: terrain ahead
      on 3 sides, 30 cm under the surface); a flying cat steps up nothing. The look-ahead now also reads the bed under
      water ahead: under Leave cm -> out onto the shelf. One 35 s swim: out at 33 cm, 'onto the shallows ahead, 19 cm
      deep', 'climbed out onto the bank, 50 cm over the water' - all three exits seen, no stall. Left: a paddle
      animation (none in the game). Drop Z:/WaCa/WaCa-mods-test-20261101a.
      DRAFT PLAN (2026-10-27, for the operator to adjust):
      - Check the water volumes (PhysicsVolume bWaterVolume) and whether the cat's movement component has a swim mode
        (CharacterMovement MOVE_Swimming) with any animation; if none exists, a "wade" (slowed walk + splash effect,
        NS_Steps_Water / DeepWater exist) is the cheap version.
- [x] 2026-11-02 - **P3: the test harness stopped taking commands after many hot reloads (seen once, VM 2026-11-02)** - after ~10
      reloads of Clan Life / Cutscenes / Looks / Hunting within an hour (Watch + deploys), from ~09:56 the harness never
      read its command file again and Hunting's delayed start logged nothing, while the game ran and reloads still
      logged; a restart cleared it. CORRECTED the same day: Clan Life's 'day clock' line is not a heartbeat (it logs on
      hour changes), so 'every mod's timers stopped' was not shown - only the harness and maybe Hunting. NOT reproduced:
      15 Hunting reloads in a row, a delayed callback ran after every one. Nor 16 reloads rotating Clan Life / Cutscenes / Looks /
      Hunting (each followed by a harness delayed callback - all ran). Next if it comes back: which mods' delayed
      callbacks still run (one probe per mod), and whether the harness itself errored.
      2026-11-02 later: the harness's own loop hardened (WaCaTest main.lua, game dir only - backup main.lua.bak-20261102):
      the next poll is now armed FIRST and the file read is pcall'd - before, one error outside the per-line pcall ended
      the loop for good, one way to the symptom; a deliberate failing command is followed by working ones (VM). It also
      logs 'CMD poll N alive' every 300 polls (~10 min): a gap in those = the stall is back. Stays open: Hunting's
      delayed start went quiet too, which a harness-only error wouldn't explain.
      CAUSE FOUND (2026-11-02 evening, VM): reproduced in a soak - 37 hot reloads rotating Clan Life / Cutscenes / Looks /
      Hunting; on the 37th (a Hunting reload) the GAME hung, not the harness: 'not responding', ~0 CPU (blocked, not
      spinning), nothing logged after Hunting's start, the screen frozen. A live stack scan of every thread: the game
      thread deep in the Lua VM waiting on a lock, ~25 engine workers waiting in the same UE4SS hook path, no WaCa
      native code on any blocked stack - a deadlock inside UE4SS's file-watch auto-reload (EnableAutoReloadingLuaMods
      = 1, set for VM testing; UE4SS ships 0). Players never run it. Writers can (Clan Life's story-check Watch relies
      on it): WRITING.md now says to save before a writing session, and Watch says when the setting is off (it
      silently did nothing before). The harness hardening (poll armed first, read guarded, alive heartbeat) stays.
      My testing: after a hang, end the game and boot again (boot_hi.sh keeps the logs).
- [x] 2026-11-02 - **P2: a cutscene's Portrait framing on rough ground (WaCa Cutscenes camera)** - found 2026-11-02 exercising Ask:
      (the loner's visit at the riverbank, VM): (1) reeds stood between the camera and Lionstar - the camera's
      clear-view trace (Camera channel) didn't see them; (2) after a reboot, at another spot, the Portrait showed a
      high view under a rock with Lionstar small mid-screen, not a 1.7 m portrait - the log said '1.7 m from what it
      looks at' and 'turned 0 deg, 150 cm higher'. A trace forward from the camera (channels 0-2, simple and complex)
      hit nothing there. Next: log the Portrait's own camera / look points each tick and compare with the player
      camera manager's view (is our camera actor the view target during the hold?); for (1) find what collision the
      reeds have (none on any channel = can't be traced - then a sphere sweep / the foliage instances' bounds).
      Screenshots: scratchpad cutask4.png (reeds), cutask5.png (rock).
      (2) CAUSE FOUND + FIXED same day: the camera sat 45 cm from YOUR cat - Lionstar was looking at your cat, so 1.7 m
      in front of his face was your cat's body, and the cast's cats are left out of the clear-view trace. A cast cat
      on the line of sight now blocks (Camera CatGap 60), and the search tries small turns before big rises (it had
      gone 3 m straight up). VM: 309 cm from your cat, a side view. STILL OPEN (1): reeds block the view - a trace
      forward from the camera through them hit nothing on channels 0-2, simple or complex: no collision at all. Next:
      check foliage instances along the line by their bounds (InstancedStaticMeshComponent GetInstancesOverlappingSphere),
      limited to the components near the scene.

      (1) FIXED same day: plants with collision off are checked by their instances' boxes along the line (Camera
      FoliageRadius) - VM: the Portrait turned 70 deg to a clear view of Lionstar, no reeds. Measured: the camera
      164 cm from Lionstar (Portrait = 170 - how close a portrait should be is the operator's look).
- [x] 2026-11-02 - **P3: a Lua-side crash inside UE4SS (UE4SS+0x2aed17 / +0x2aed57) - 19 reports 10-28 .. 11-01 13:39, none on 11-02** -
      the crashed thread is in UE4SS's Lua interpreter (c7xxxx frames) under an object access (b9ddd4 / ba2b5c): some
      mod's Lua touched a game object no longer valid (pcall can't catch an access violation). The session's UE4SS.log
      is overwritten on the next start, so the script isn't known. 11-02: many boots and ~40 reloads, not once - maybe
      gone with that day's fixes, not proven. A soak the same day - 30 scenes in a row (every cutscene, Groups, a
      pack event, 3 rounds, ~75 min) - no crash. NEXT time it happens: copy UE4SS.log + WaCaNative.log BEFORE restarting
      (the last lines name the mod and the step), then fix that script. (Crash triage 11-02: the GC purge crash +0x1c64787
      fixed - gcguard; +0x1b355e5 at 08:57 was my own destroy-during-start, fixed; older groups stopped by 10-31.)

      CAUSE FOUND + FIXED 2026-11-02 (VM): reproduced on demand - UE4SS hands back a wrapper of NULL (not nil) from
      GetOwner / GetParent / FindFirstOf / object fields when there is no object, and any call on it (GetClass,
      GetFullName, a field) crashes natively reading 0x10 - pcall can't catch it. A probe calling GetClass() on a
      widget's 6th GetParent() gave exactly UE4SS+0x2aed57 / 'reading 0x10'; through the new WaCa.Live the same call
      returned nil. Every unchecked chain in our mods now goes through WaCa.Live (component owners, FindFirstOf
      managers, prey controller / movement, a widget tree - Core, Looks, Cutscenes, Hunting, Clan Life); API.md
      documents it. Which chain caused the 19 earlier reports is not known (their logs weren't kept) - a NEW
      0x2aed57 report reopens this (the logs are kept in the crash folder now).
- [x] 2026-11-02 **Engine crash in the GC purge (exe+0x1c64787)** (operator: fix it though pre-existing): WaCa Core gcguard.cpp - the null store skipped; VM 8 boots clean, the guard fired on one.
- [x] 2026-10-31 **Clan Life lost the save's day on a hot Lua reload** (P3): DayNight restores + starts the clock at
      Init when the world is already up, and Drive keeps a restored hour. VM: two reloads -> day 19, 13:00, Leaf-bare,
      the noon resumed.
- [x] 2026-10-31 **Framework: fixed cats for specific roles** (WaCa Looks roster, VM-tested): live pins by the cat's
      name ([Cat.Troutwing]), story role ([Narrative.RiverClanWarriorSideRace]) and clan + job ([RiverClan.MedicineCat]);
      name, the game's look values, CatSize (VM: Gooseheart 1.40 -> her root bone 1.22, the others 1.00), scars,
      accessories (any FCatCustomData field), WaCa colours / masks; story packs bring contentoster.ini. Traits: camp
      cats have none (only the player's creation data and its dialogue choices carry ECharacterTrait) - nothing to pin.
      The canon roster (1) builds on this.
- [x] 2026-10-30 **Time freezes at story points**: the game's own sequences / conversations and WaCa cutscenes freeze the
      clan's clock while they play (each lifted at its end, 5 min safety); story files freeze with a `Freeze: On` /
      `Freeze: Off` scene step; a third that would start while frozen waits (the clan's day and the sky never part).
      VM: a cutscene and the Freeze steps froze and released time; tasks given out while frozen -> "the evening waits
      - time stands still", Freeze: Off -> "the evening begins".
- [x] 2026-10-30 **Day clock HUD instead of an exhaustion meter** (Clan Life dayclock.lua, [DayClock]): a 24-hour dial
      top right (noon at the top), a mark where Morning / Noon / Evening / Night begin, a needle at the hour (the
      clan clock, else the third's start), the middle = tiredness (green / amber Tired / red Exhausted). Built from
      the game's round UI texture in the HUD canvas, event-driven. VM: drawn, needle at 13:00, tiredness 28 green.
      Operator: is the look right (size, place, colours)? A custom dial texture would need the content pak.
- [x] 2026-10-30 **Pounce walk, VM-tested** (Hunting 0620f72 + Core hunt.cpp): loud ground from the pounce key to the
      leap -> "starts - on loud ground", the prey runs, HuntFail -> the leap lands on "nothing to catch"; a normal pounce
      rolls at the leap and catches at the landing (+EXP); a missed roll bolts the prey at the leap; one pounce per prey,
      a key press that started no pounce lapses after 20 s. Still open: sight during the walk (proximity risk, not built);
      a VM test of loud ground crossed MID-walk (only "starts on loud ground" was tested).
- [x] 2026-10-30 **Library exercise: a story pack with no code** (ClanLife examples/WaCaStoryPackExample, VM-tested):
      custom cat (Looks [Cat.Troutwing] -> Mossfeather), custom role ([Cast] S:herbalist), custom cutscene (HerbLesson,
      both parts and lines on screen), clan event (Bond @ S:herbalist). Rough edges found and fixed: packs couldn't add
      roster cats (content/roster.ini); the rank-based roster pins found NO cat in this game version (generator keeps no
      lists -> live pins by name / story role); roles couldn't be cast without Lua ([Cast]); an unbound role waited for
      the next third (now retried every 10 s); Cutscenes didn't know S roles; no {PLAYER} in lines; Bond on S roles was a
      no-op; no subtitle for other mods (ShowLine); cat/player-name helpers duplicated (now Core WaCa.Cats/CatName/
      PlayerName); deploy_split missed Cutscenes.
- [x] 2026-10-30 **Hunt comments** (operator future work): the nearest clanmate within Radius says lines.ini [Hunt]
      Caught/Missed lines as a subtitle (VM: "Spikebranch: Nice catch, Dapplepatch!"). Nearest clanmate, not strictly
      "party" - a party filter is a follow-up if wanted.
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
