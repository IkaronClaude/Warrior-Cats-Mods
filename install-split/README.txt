WaCa mods - test install (2026-11-04)

The fast way: double-click install-all.bat. It removes the old WaCa ModKit (if it's there), then installs all seven
mods, Core first. Needs UE4SS for Warrior Cats installed already (the Nexus download).

One at a time:
  0-Uninstall-old-WaCaModKit\uninstall-old.bat   run this first
  1-WaCa-Core-1.0.0\install.bat                  every other mod needs it
  2-WaCa-KeybindsMouse-1.0.0\install.bat
  3-WaCa-Looks-1.0.0\install.bat
  4-WaCa-ClanLife-0.8.0\install.bat
  5-WaCa-Hunting-0.8.0\install.bat
  6-WaCa-Graphics-1.0.0\install.bat
  7-WaCa-Cutscenes-0.1.0\install.bat

The scripts find the game through Steam, or ask for the game's folder.
- uninstall-old deletes nothing. It moves the old mod folder and its content pak to
  Wrc\Binaries\Win64\WaCaModKit-old-<time>; your old settings, looks and rosters are in there.
  It takes the WaCaModKit line out of mods.txt. UE4SS stays installed, because the new mods need it.
- install backs up any settings it replaces (Mods\<Mod>\config-backup-<time>) and puts in the new
  defaults. Each mod is switched on by its own enabled.txt.

Test switches (the release defaults are off): the clan sim (WaCaClanLife\config\clanlife.ini On = 1), and in
WaCaHunting\config\hunting.ini hunting by chance, fishing, fleeing prey and the wind (scent carried
downwind - prey notices you from upwind).

New since the last test bundle (2026-10-30), worth checking (ue4ss\UE4SS.log):
- Release fixes: a Gather step in a scene now ends (the screen faded back in); a cat shown for a scene is hidden again
  afterwards; on loading a save with no hunting role, once your cat is a Warrior or higher, a scene asks which role
  it takes (Hunter / Tracker / Fighter / Herbalist).
- Every mod's folder now has its docs: WaCaClanLife\docs\WRITING.md (the writer's guide), WaCaCore\docs\API.md.
- Try a story pack: copy Mods\WaCaClanLife\examples\WaCaStoryPackExample to Mods\WaCaStoryPackExample (it has its
  own enabled.txt) and restart - a Reach event at the reeds, a herb-round duty, cutscenes. Its story check result is
  in Saved\WaCaStoryCheck.txt.
- Talk to the deputy to turn in a task: "turned in (Deputy)". Put prey on the fresh-kill pile: "turned in (Pile)".
- The day status panel sits under the game's quest panel.
- If you use MothColorPicker: does it get along with WaCa Looks?

If something breaks: send UE4SS.log and Mods\WaCaCore\WaCaNative.log (and the newest folder in
%LOCALAPPDATA%\Wrc\Saved\Crashes if the game crashed).
