"""Turns every WaCa feature on in an assembled test bundle (assemble_test_bundle.sh's output) - for the operator's
'test everything' run (2026-11-04). Prints each change. Left as shipped: Clan Life's StoryCheck Watch (a story-file
save hot-reloads Clan Life - UE4SS's reload hang, tickets.md P3), the pile's Decay (0 = the mod's own: no decay),
screen layout (Right) and preferences (PutPlayerBack), and story-day content keys ([Day.N] Hunt / Patrol).
usage: python all_on.py <bundle dir>"""
import glob, os, re, sys

SET = {  # (file, key) -> value, in any section; "On" is set to 1 in every file
    ("hunting.ini", "Flee"): "1", ("hunting.ini", "Trails"): "1", ("hunting.ini", "PounceFromJumpRange"): "1",
    ("hunting.ini", "SightDuringPounce"): "1", ("hunting.ini", "Close"): "1",
    ("duties.ini", "Companions"): "2",
    ("cutscenes.ini", "Letterbox"): "2.39", ("cutscenes.ini", "Focus"): "2.8",
    ("creator.ini", "PanelShapes"): "1",
}
KEY = re.compile(r"^(\w+)(\s*=\s*)(\S*)(\s*)$")

root = sys.argv[1]
n = 0
for path in sorted(glob.glob(os.path.join(root, "*", "files", "Wrc", "Binaries", "Win64", "ue4ss", "Mods", "*", "config", "*.ini"))):
    name = os.path.basename(path)
    raw = open(path, "rb").read()
    text = raw.decode("utf-8-sig")
    nl = "\r\n" if "\r\n" in text else "\n"
    section, out, changed = "", [], []
    for line in text.split(nl):
        m = KEY.match(line)
        if line.startswith("["):
            section = line.strip()
        elif m:
            key, eq, val, tail = m.groups()
            want = "1" if key == "On" and val == "0" else SET.get((name, key)) if val in ("0", "") else None
            if want and want != val:
                line = key + eq + want + tail
                changed.append(f"{section} {key} {val} -> {want}")
        out.append(line)
    if changed:
        new = nl.join(out).encode("utf-8")
        if raw.startswith(b"\xef\xbb\xbf"): new = b"\xef\xbb\xbf" + new
        open(path, "wb").write(new)
        mod = path.split(os.sep + "Mods" + os.sep)[-1].split(os.sep)[0] if os.sep + "Mods" + os.sep in path else path
        for c in changed: print(f"{mod}/{name} {c}")
        n += len(changed)
print(f"{n} switch(es) turned on")
