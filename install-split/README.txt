WaCa mods - test install (2026-10-28)

The fast way: double-click install-all.bat. It removes the old WaCa ModKit, then installs all six mods, Core first.

One at a time:
  0-Uninstall-old-WaCaModKit\uninstall-old.bat   run this first
  1-WaCa-Core-1.0.0\install.bat                  every other mod needs it
  2-WaCa-KeybindsMouse-1.0.0\install.bat
  3-WaCa-Looks-1.0.0\install.bat
  4-WaCa-ClanLife-0.8.0\install.bat
  5-WaCa-Hunting-0.8.0\install.bat
  6-WaCa-Graphics-1.0.0\install.bat

The scripts find the game through Steam, or ask for the game's folder.
- uninstall-old deletes nothing. It moves the old mod folder and its content pak to
  Wrc\Binaries\Win64\WaCaModKit-old-<time>; your old settings, looks and rosters are in there.
  It takes the WaCaModKit line out of mods.txt. UE4SS stays installed, because the new mods need it.
- install backs up any settings it replaces (Mods\<Mod>\config-backup-<time>) and puts in the new
  defaults. Each mod is switched on by its own enabled.txt.

For this test, the clan sim is on: WaCaClanLife\config\clanlife.ini has On = 1. The release default is 0.

Worth checking while you play (ue4ss\UE4SS.log):
- Talk to the deputy to turn in a task: look for "turned in (Deputy)".
- Put prey on the fresh-kill pile: look for "turned in (Pile)".
- Report key F near the deputy: "reports to ...".
- The day status panel sits under the game's quest panel.
- If you use MothColorPicker: does it get along with WaCa Looks?
