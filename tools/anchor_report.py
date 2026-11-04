"""Every function referencing an anchor string, with its first bytes and the body features the native hook checks -
to see why an anchor + prologue lookup failed on a new game build (2026-11-04: camera.cpp's "LookAtYaw" on patch 1.1).
usage: python -I anchor_report.py <unpacked exe> <anchor> [body pattern ...]
Uses WaCa Core's tools/check_hooks.py for the scanning (its helpers, up to its report: the runtime's scan.h resolution)."""
import os, sys

exe, anchor, patterns = sys.argv[1], sys.argv[2], sys.argv[3:]
hooks = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "WaCa-Core", "tools", "check_hooks.py")
src = open(hooks, encoding="utf-8").read()
lib = src[:src.index("\nfailed = 0")] + "\n" + src[src.index("\ndef body_count"):src.index("\nVAR = ")]
sys.argv = [hooks, exe]
g = {"__file__": hooks, "__name__": "check_hooks_lib"}
exec(compile(lib, hooks, "exec"), g)

IB, image = g["IB"], g["image"]
for s in g["find_ascii"](anchor):
    for fn in g["referencing_functions"](s):
        r = g["primary_range"](fn)
        size = (r[1] - r[0]) if r else 0
        head = " ".join(f"{b:02X}" for b in image[fn:fn + 12])
        feats = "  ".join(f"[{p}] x{g['body_count'](fn, p)}" for p in patterns)
        print(f"0x{IB + fn:X}  {size:6d} B  {head}  {feats}")

# --callees <fn hex> <pattern>: the functions <fn> calls (E8 rel32) whose body has the pattern
if os.environ.get("CALLEES"):
    import struct
    fn = int(os.environ["CALLEES"], 16) - IB
    pat = os.environ["PAT"]
    r = g["primary_range"](fn)
    seen = []
    for p in range(r[0], r[1] - 4):
        if image[p] != 0xE8:
            continue
        t = p + 5 + struct.unpack_from("<i", image, p + 1)[0]
        if t in seen or not g["primary_range"](t):
            continue
        seen.append(t)
        n = g["body_count"](t, pat)
        if n:
            print(f"callee 0x{IB + t:X} [{pat}] x{n}  {g['primary_range'](t)[1] - t} B")
    print(f"{len(seen)} callee(s) checked")
