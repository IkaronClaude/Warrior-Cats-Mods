WaCa mods - EVERYTHING ON test install (2026-11-04, build b)

Double-click install-all.bat. It moves the old WaCa ModKit aside (if it's there), installs all seven mods (Core
first) and, as number 8, the example story pack (WaCaStoryPackExample) so the story features have something to play.
Needs UE4SS for Warrior Cats installed already (the Nexus download). The scripts find the game through Steam, or ask
for its folder. Settings they replace are backed up (Mods\<Mod>\config-backup-<time>); nothing is deleted.

In this bundle every feature is ON (the release ships most of them off):
- Clan Life: the clan sim, day / night, story days, the clan's duties (hunting with 2 companions), story events,
  exhaustion, Gatherings, extra lines, patrols, romance, time skips, the camp's walking cats, seasons and weather,
  clan activities (ambient + joining in with G).
- Hunting: hunting by chance, fishing, fleeing prey, the wind, scent trails, StarClan guidance, the pounce only from
  jump range (you sneak the last metres) with the prey watching during the pounce, the pile's screen closing by itself.
- Cutscenes: a film look - letterbox 2.39 and depth of field f/2.8.
- Looks: any game pattern / marking as a coat row's shape in the creator (PanelShapes).
- The example story pack: a Reach event at the reeds, a herb-round duty, a newcomer apprentice, story days,
  cutscenes. Its story check: Saved\WaCaStoryCheck.txt.
Still off: the story-file Watch (it hot-reloads Clan Life, and UE4SS can hang on a hot reload) and the pile's decay
(off is the mod's feature: the pile no longer runs down on a timer).

Turning one thing off again: its file in ue4ss\Mods\<Mod>\config\, the On = 1 line -> 0 (each file explains itself).

Worth checking (ue4ss\UE4SS.log):
- A Gather step in a scene ends and the screen fades back in; a cat shown for a scene is hidden again afterwards.
- Once your cat is a Warrior or higher, loading a save with no hunting role asks which role it takes.
- Talk to the deputy to turn in a task ("turned in (Deputy)"); prey onto the fresh-kill pile ("turned in (Pile)").
- Every mod's folder has its docs: WaCaClanLife\docs\WRITING.md (the writer's guide), WaCaCore\docs\API.md.
- New in this build (b): the Bedding duty is two real interactions (E in the den, E out of camp - your cat bites up
  the moss, then digs); kits and newcomers can be talked to (E next to them); the cat you report to is marked on the
  map, and talking to it hands the duty in; cats' lines show over their heads; at most one murmur every 30 s; the
  duty line's icon is the map's leaf; a Clan tab in the pause menu's Quest page (after Side Quests).
- Patch 1.1: when the game handles the mouse itself (1.1 does), WaCa's menu mouse and mouse look switch off by
  themselves - the double clicks and stuck tabs should be gone. Keybinds' [Mouse] WhenTheGameHasMouse = Ours brings
  ours back. Please check the log for 'mouse: the game handles the mouse itself'.

If something breaks: send ue4ss\UE4SS.log and ue4ss\Mods\WaCaCore\WaCaNative.log (and the newest folder in
%LOCALAPPDATA%\Wrc\Saved\Crashes if the game crashed).
