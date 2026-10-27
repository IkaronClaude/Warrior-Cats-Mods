"""Read-only: list the clan roster a save holds (tickets.md "1. Canon clan roster").

  python tools/roster_dump.py [path to WrcGame.json]      (default: %LOCALAPPDATA%/Wrc/Saved/SaveGames/WrcGame.json)

The game generates the clan once per new game and keeps it in the save: <save>.<character slot>.NPCData.NarrativeRoles
= { role: "(Role=..., BodyValue=..., ..., PrefixNameId=\"STR_...\", SuffixNameId=\"...\")" }. This prints every
slot's roles with their look values and name ids - the starting point for a roster.ini (role -> name + look). It
never writes the save."""
import json
import os
import re
import sys

path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.environ.get("LOCALAPPDATA", "."), "Wrc", "Saved", "SaveGames", "WrcGame.json")
with open(path, encoding="utf-8") as f:
    data = json.load(f)

FIELD = re.compile(r'(\w+)=("[^"]*"|[^,)]*)')
for save, slots in data.items():
    if not isinstance(slots, dict):
        continue
    for slot, content in slots.items():
        roles = (content.get("NPCData") or {}).get("NarrativeRoles") if isinstance(content, dict) else None
        if not roles:
            continue
        print(f"== save {save}, character slot {slot}: {len(roles)} roles")
        for role, value in sorted(roles.items()):
            fields = dict(FIELD.findall(value))
            name = f'{fields.get("PrefixNameId", "?").strip(chr(34))} + {fields.get("SuffixNameId", "?").strip(chr(34))}'
            look = ", ".join(f"{k}={v}" for k, v in fields.items() if k not in ("PrefixNameId", "SuffixNameId", "Role"))
            print(f"  {role:34} {fields.get('Role', '?'):14} name {name:44} {look}")
