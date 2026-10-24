WaCa ModKit - mods and fixes for Warrior Cats: Clans of the Forest
==================================================================

INSTALL
  Double-click Install.bat. It finds the game through Steam and copies the files in.
  (Or by hand: copy the "Wrc" folder from "files" into the game's folder -
   Steam > right-click the game > Manage > Browse local files.)
  Then start the game from Steam as usual.

UNINSTALL
  Double-click Uninstall.bat. Your game files are never modified; the mod only adds files.

WHAT IT DOES (0.3.1)
  - Escape instead of P to pause, and Escape instead of BackSpace for back / close in menus.
  - Mouse look: the camera follows the mouse (sensitivity in keybinds.ini).
  - Rebind any keyboard/mouse key: edit
      <game>\Wrc\Binaries\Win64\ue4ss\Mods\WaCaModKit\config\keybinds.ini
    (all commands and the game's defaults are listed inside).
  - Your own cat name: edit config
ames.ini (Prefix = Moss -> Mosskit, Mosspaw, ...).
    Your save keeps the game's name, so online features and uninstalling are safe.
  - Change any game text: config	ext.ini.
  - Your cat's look: configppearance.ini - any colour for every part of the coat, the game's patterns and markings
    combined freely, and looks like "Colourpoint" (Look = Colourpoint).

ADDING YOUR OWN MODS
  WaCa ModKit runs on UE4SS (https://github.com/UE4SS-RE/RE-UE4SS). Lua mods go in
  <game>\Wrc\Binaries\Win64\ue4ss\Mods\<YourMod>\Scripts\main.lua.

TROUBLESHOOTING
  Logs: ue4ss\UE4SS.log and ue4ss\Mods\WaCaModKit\WaCaNative.log next to the game's exe.
  After a game update, if a feature stops working, the log says which part could not be found.
