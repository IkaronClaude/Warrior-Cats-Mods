# Asset map - how the game's systems work (for modding)

Descriptions and paths only (no game data). Found during the 2026-10-25 / 10-27 work; "VM" = checked live. The
game: UE 5.7, project `Wrc`, game modules `SwtEngine` / `SwtQuest` / `SwtAdventure` / `Wrc`.

## Clan cats / roster
- The clan is generated once per new game and **kept in the save**: `WrcGame.json` -> `<save>.<slot>.NPCData.NarrativeRoles`
  = `{ <role>: "(Role=..., BodyValue, FaceValue, FurValue, WhiskerValue, TailIdx, EarIdx, FurColorIdx,
  Pattern01ColorIdx, Pattern02ColorIdx, PatternIdx, MarkingIdx, EyeLeft/RightColorIdx, bOverrideColors,
  PrefixNameId="STR_..._NAME_n", SuffixNameId=...)" }`. Roles = the story's narrative roles (TheLoner,
  RiverClanDeputy, TheRegretfulWarrior, ...). A canon roster = rewriting these entries (before the slot loads).
- Which roles you've met: `GameplayProgression.Unlocked.NarrativeRoles`; party member stats:
  `GameplayProgression.Party.Stats`.
- Names: string table rows `STR_CAT_NAME<n>` + suffix rows (`_PAW`, ...); `config/names.ini` / text overrides.
- Placeholders in dialogue (`{THE AGING LEADER}`) are filled from these roles (`FNarrativeRolesStructByRank`).

## Dialogue / quests / text
- All English text: the string table `SwtStrings` <- `Gameplay/Strings/NonAsset/Strings_EN.csv` (8901 rows; keys like
  `QST_Story.Monologue.Filler.<Clan><Role>.*`). Runtime: `WaCa.GetText` / `WaCa.SetText` (VM).
- Conversations: `QuestGiverWidget` (WBP_QuestGiver_Dialogue / 2 / 3); next prompt `mcGuiNext`, answers `mcButton1..4`.
- Scripted dialogues: `SwtQuestSequencerManager.DialoguesToUse` = `DT_QuestSequenceDialogues` (rows:
  `SequenceDialogueId` tag, widget, `DialogueToUse` NpcDialogue asset); `PlaySequenceDialogue(tag, npc, player, ...)`
  opens one (VM).
- Quests: `UQuestBase` (rewards, ExperienceReward, DialogueSequencesByRank); progress in the save
  (`QuestProgression.Chapter00.<quest>`).

## Days / time
- No day cycle in the game. The sky: one `BP_DayNightSky` (level `L_Lights`) with fixed looks (Test* / StartIn* flags;
  post-processes neutralday / night / per clan / moonpool); movable DirectionalLight, SkyLight, height fog. The mod's
  `daynight.lua` drives it (VM).

## Hunting / prey / combat
- Roaming creatures = `BP_Exploration_Character_Base_C` (164 `BP_Enemy_Generator_C` + 4 boss generators);
  `CharacterType` = `ESwtQuestCharacterType` (Cat, Mice, Squirrel, Rabbit, Bird, Rat, Weak*, bosses ...).
- The instakill = `USwtAdventurePreyComponent` (on prey AND NPC cats - the sneak attack): landing = vtable +0xAA0
  (OnHunterLanded), the hunted sequence, OnHuntedSequencerFinish +0xAA8. The icon = the level-gap marker
  `WBP_GuiLevelWarning` (CanvasEnemyWeaker / Same / Stronger / Stronger2 / InstaKill), in the widget of the
  creature's WidgetComponent.
- Detection: `BP_Exploration_DetectionComponent` (sphere overlap). AI: behaviour trees with `BTTask_Enemy*` states
  (Idle / Checking / Walking / Grazing / Hunted).
- Combat EXP: `Gameplay/DataTables/NonAsset/CombatBaseExperience.csv`, loaded into the tuning manager
  (`BP_WrcTuningManager_C` on the game instance) as an unreflected map at +0x460 (hunt.cpp reads it).
- Noise: `ASwtAdventureMovementModifierArea` boxes (`BP_MovementModifier_Loud_C` x12 = loud ground,
  Hiding x29); flags `EAdventureMovementFlag` (Crouch, Run, Pounce, Hiding, Loud, ApproachingSneakVictim ...).
  Footsteps: `BP_AnimStepNotify` (USwtAdventureStepModifierNotifyState) by `EAdventurePhysicalFloorType`.
- Fishing spots: `BP_Interactable_Claw_FishingSpot_C` (InteractionComponent, EffectComponent reward, NS_PickUp_Hint).
- Fresh-kill pile: `ASwtAdventureFreshKillPileActor` / `USwtAdventureFreshKillPileComponent` (save:
  `GameplayProgression.FreshKill` {Value, Timer, Cycle}).

## Party
- `ASwtAdventureCharacter.Party`; party stats in the save (`Party.Stats`); clan activities pause / walk NPCs with
  their AI `BrainComponent` (StopLogic / RestartLogic, VM).

## Rank / progression
- Rank in the save: `GameplayProgression.Rank` (ECharacterRank 1 Apprentice .. 4 Leader), `Level`, `Experience`;
  saved with context "SavePlayerRank" on a change. Rank-ups: `URankUp` (RequiredLevel + Objectives),
  `UQuestObjectiveRankUpTask`; ceremonies = the RankUp* sequences (`Sequences` in the save).
- Live level / EXP: the player state's `LevelComponent` (unreflected: +0x120 level, +0x10C EXP, +0x110 next level;
  add-value = vtable +0x508).

## Input / graphics / save
- Input: the game's action / axis bindings (rebound by the mod from `keybinds.ini`); menus read raw keys
  (DT_GamepadButtonsKeyboard rows for icons).
- Graphics: scalability `sg.*` cvars + console vars (`graphics.ini`).
- Save: `%LOCALAPPDATA%/Wrc/Saved/SaveGames/WrcGame.json` (+ .sav); one save GUID with character slots; the mod's
  per-slot sidecars `WrcGame.<save>-<slot>.<Mod>.ini`. Saves go through `USwtSaveManager::Save` (hooked: GameSaved).

## Engine quirks of this build
- `FRotator`'s first field is lower-case `pitch` from Lua.
- Spawning actors in the first ~10 s after the world appears can crash (GetWorld null while streaming) - wait.
- Native components' overlap events don't reach ProcessEvent unless a Blueprint implements them.
