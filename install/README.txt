WaCa ModKit - mods and fixes for Warrior Cats: Clans of the Forest
==================================================================

INSTALL
  Double-click Install.bat. It finds the game through Steam and copies the files in.
  (Or by hand: copy the "Wrc" folder from "files" into the game's folder -
   Steam > right-click the game > Manage > Browse local files.)
  Then start the game from Steam as usual.
  Updating: it asks whether to keep your settings or reset them to the new defaults (old ones backed up).

UNINSTALL
  Double-click Uninstall.bat. Your game files are never modified; the mod only adds files.

WHAT IT DOES (0.6.0)
  The settings files are in <game>\Wrc\Binaries\Win64\ue4ss\Mods\WaCaModKit\config\ (each explains itself inside).

  In the character creator:
  - Type your own name on the name screen. The game's name list is your ONLINE name (what the save and online
    features keep); your typed name is what you see in the game. Confirm on the name list
    to type in the box (top right; Steam's keyboard on a controller), confirm again to go on. The warrior ceremony
    has the same box for your own warrior suffix.
  - More colours in the game's colour pickers (fur, pattern, markings) - palette.ini.
  - A WaCa panel on the customisation screen: the shape of the pattern / markings from any of the game's patterns
    and markings, or "Colourpoint" (coloured with the game's pattern colour) - combine two markings. Click the arrows
    or press F6 / F7. Backing out of the screen drops its WaCa choices.
  These choices are saved next to your save (WrcGame.<save>-<character slot>.WaCaModKit.ini in the game's save folder) and come back
  when you load it. The game's own save stays loadable without the mod.

  Everywhere:

  - Reacts to the game the moment something happens (a screen opens, a cat appears) instead of checking every
    few seconds: names, looks and the menu cursor are right at once.
  - The mouse cursor shows in menus.
  - Escape instead of P to pause; Escape also goes back / closes in every menu (BackSpace still works too).
  - Space advances a conversation (Enter still works too).
  - A click continues the "press any key" title screen.
  - Mouse look: the camera turns left / right exactly with the mouse (LookYaw in keybinds.ini).
  - Rebind any keyboard/mouse key: keybinds.ini (all commands and the game's defaults are listed inside).
  - Your own cat name: names.ini (Prefix = Moss -> Mosskit, Mosspaw, ...).
    Your save keeps the game's name, so online features and uninstalling are safe.
  - Change any game text: text.ini.
  - Your cat's look: appearance.ini - any colour for every part of the coat, the game's patterns and markings
    combined freely, and Colourpoint (PatternMask = look:Colourpoint).
  - No more doubled cat names from the game's generator ("Blazeblaze").
  - Fixed cats for specific roles: roster.ini + roster files (see the rosters folder's Example.ini) pin a story cat
    or a clan's leader / deputy / warriors ... to a name and look.

ADDING YOUR OWN MODS
  WaCa ModKit runs on UE4SS (https://github.com/UE4SS-RE/RE-UE4SS). Lua mods go in
  <game>\Wrc\Binaries\Win64\ue4ss\Mods\<YourMod>\Scripts\main.lua.

TROUBLESHOOTING
  Logs: ue4ss\UE4SS.log and ue4ss\Mods\WaCaModKit\WaCaNative.log next to the game's exe.
  After a game update, if a feature stops working, the log says which part could not be found.
