Pattern packs: a folder here = a pack. Put black/white PNG masks in it (white = the colour of the slot you use the
pack for), one per mesh part, named after the part:
  Body.png
  Tails_A.png, Tails_B.png, Tails_Deluxe.png          (or Tails.png for all tails)
  Ears_A.png, Ears_B.png, Ears_Deluxe.png             (or Ears.png)
  Fur_Bony.png, Fur_Brawny.png, ... Fur_Trim.png      (or Fur.png) - the fur tufts per body type
Masks are in each mesh's UV layout (2048 x 2048 like the game's). Parts without a file keep the game's mask.
Use a pack in config/appearance.ini: PatternMask = <folder name>  or  MarkingsMask = <folder name>.
