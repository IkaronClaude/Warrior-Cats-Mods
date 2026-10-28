"""Top-down map of a camp from a world dump (the test harness writes campmap.json in the game):
static mesh bounding boxes cut at about floor level, NPC cats, story cats (by role), den doors and den triggers.

    python tools/camp_map.py <campmap.json> <out.png> [--slice-low 100] [--slice-high 250] [--px-per-m 6]

The slice keeps boxes that reach into [floor + low, floor + high] cm, the floor being the story cats' median height
(boxes taller than that band - trees, rocks, walls - are what a cat walks around). Colours: geometry boxes by their top height, outlines - invisible walls cyan, the game's
zone-name boxes orange (with their names), music triggers purple; the camp as the clan loop finds it green; cats yellow, story cats red with their role, den doors blue squares, den triggers blue outlines, the player green.
"""
import argparse
import json
import math

from PIL import Image, ImageDraw, ImageFont


# the actors whose bounds are what a cat walks around (characters / effects / triggers have huge bounds: widgets,
# detection ranges)
GEOMETRY = {"StaticMeshActor", "BP_StaticMesh_Transparency_C", "BP_PlatformAssetSimple_C", "InstancedFoliageActor"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dump")
    ap.add_argument("out")
    ap.add_argument("--slice-low", type=float, default=50)
    ap.add_argument("--slice-high", type=float, default=250)
    ap.add_argument("--px-per-m", type=float, default=6)
    ap.add_argument("--max-half", type=float, default=2500, help="skip geometry boxes larger than this half-size (cm)")
    a = ap.parse_args()
    d = json.load(open(a.dump, encoding="utf-8"))
    c = d["center"]
    half = d["half"]
    scale = a.px_per_m / 100.0                       # px per cm
    size = int(2 * half * scale)
    img = Image.new("RGB", (size, size), (24, 26, 30))
    dr = ImageDraw.Draw(img, "RGBA")
    try:
        font = ImageFont.truetype("arial.ttf", 12)
    except OSError:
        font = ImageFont.load_default()

    def px(x, y):
        # north (+X in UE) up, east (+Y) right
        return ((y - c["Y"]) * scale + size / 2, -(x - c["X"]) * scale + size / 2)

    def corners(b):
        # the box's corners turned by its yaw (geometry bounds are axis-aligned: yaw 0)
        yaw = math.radians(b.get("yaw", 0) if b.get("cls") == "BP_ZoneNameTrigger_C" else 0)
        pts = []
        for sx, sy in ((1, 1), (1, -1), (-1, -1), (-1, 1)):
            lx, ly = sx * b["ex"], sy * b["ey"]
            wx = b["x"] + lx * math.cos(yaw) - ly * math.sin(yaw)
            wy = b["y"] + lx * math.sin(yaw) + ly * math.cos(yaw)
            pts.append(px(wx, wy))
        return pts

    floor = c["Z"]
    lo, hi = floor + a.slice_low, floor + a.slice_high
    # grid every 10 m
    for i in range(-int(half // 1000), int(half // 1000) + 1):
        g = i * 1000
        x0, y0 = px(c["X"] - half, c["Y"] + g)
        x1, y1 = px(c["X"] + half, c["Y"] + g)
        dr.line([x0, y0, x1, y1], fill=(255, 255, 255, 18 if i % 5 else 45))
        x0, y0 = px(c["X"] + g, c["Y"] - half)
        x1, y1 = px(c["X"] + g, c["Y"] + half)
        dr.line([x0, y0, x1, y1], fill=(255, 255, 255, 18 if i % 5 else 45))
    kept = 0
    # outlines (not geometry): invisible walls, the zone-name boxes (the game's own named places), music triggers
    OUTLINE = {"BlockingVolume": (0, 220, 220, 230), "BP_ZoneNameTrigger_C": (255, 140, 0, 255),
               "BP_MusicSourceTrigger_C": (200, 90, 255, 230)}
    for b in d["boxes"]:
        col = OUTLINE.get(b.get("cls"))
        if not col:
            continue
        pts = corners(b)
        dr.polygon(pts, outline=col, width=3 if b["cls"] != "BlockingVolume" else 2)
        if b.get("label"):
            x0 = min(p[0] for p in pts)
            y0 = min(p[1] for p in pts)
            if 0 <= x0 < size and 0 <= y0 < size:
                dr.text((x0 + 4, y0 + 2), b["label"], fill=col, font=font)
    for b in d["boxes"]:
        if b.get("cls") not in GEOMETRY:
            continue
        zmin, zmax = b["z"] - b["ez"], b["z"] + b["ez"]
        if zmax < lo or zmin > hi or max(b["ex"], b["ey"]) > a.max_half:
            continue
        kept += 1
        t = max(0.0, min(1.0, (zmax - floor) / 1500.0))
        col = (int(90 + 140 * t), int(120 - 60 * t), int(90 + 30 * (1 - t)), 150)
        dr.polygon(corners(b), fill=col, outline=(255, 255, 255, 60))
    for t in d.get("triggers", []):
        x0, y0 = px(t["x"] + t["ex"], t["y"] - t["ey"])
        x1, y1 = px(t["x"] - t["ex"], t["y"] + t["ey"])
        dr.rectangle([x0, y0, x1, y1], outline=(80, 160, 255, 220), width=2)
    for dd in d.get("doors", []):
        x, y = px(dd["x"], dd["y"])
        if not (0 <= x < size and 0 <= y < size):
            continue
        dr.rectangle([x - 5, y - 5, x + 5, y + 5], fill=(80, 160, 255, 255))
        dr.text((x + 7, y - 6), dd["name"], fill=(150, 200, 255), font=font)
    for cat in d.get("cats", []):
        x, y = px(cat["x"], cat["y"])
        dr.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(240, 210, 60, 230))
    for s in d.get("story", []):
        x, y = px(s["x"], s["y"])
        dr.ellipse([x - 5, y - 5, x + 5, y + 5], fill=(230, 60, 60, 255))
        dr.text((x + 7, y - 6), s["role"], fill=(255, 150, 150), font=font)
    # the camp as the clan loop finds it (duties.lua): the zone whose area boxes hold the most of the clan's story
    # cats; its outline = the rectangle around its area boxes (not the gates), + 10 m
    clan = d.get("clan", "")
    mine = [s for s in d.get("story", []) if s["role"].startswith(clan)]
    zones = [b for b in d["boxes"] if b.get("cls") == "BP_ZoneNameTrigger_C"]

    def inside(b, p, m):
        yaw = math.radians(b.get("yaw", 0))
        dx, dy = p["x"] - b["x"], p["y"] - b["y"]
        lx = dx * math.cos(yaw) + dy * math.sin(yaw)
        ly = -dx * math.sin(yaw) + dy * math.cos(yaw)
        return abs(lx) <= b["ex"] + m and abs(ly) <= b["ey"] + m

    count = {}
    for b in zones:
        if min(b["ex"], b["ey"]) >= 150:
            code = b["label"].split(" /")[0]
            count[code] = count.get(code, 0) + sum(1 for p in mine if inside(b, p, 300))
    if count:
        code = max(count, key=count.get)
        mz = [b for b in zones if b["label"].startswith(code + " ") and min(b["ex"], b["ey"]) >= 150]
        r = lambda b: max(b["ex"], b["ey"])
        x0 = min(b["x"] - r(b) for b in mz) - 1000
        x1 = max(b["x"] + r(b) for b in mz) + 1000
        y0 = min(b["y"] - r(b) for b in mz) - 1000
        y1 = max(b["y"] + r(b) for b in mz) + 1000
        p0, p1 = px(x1, y0), px(x0, y1)
        dr.rectangle([p0[0], p0[1], p1[0], p1[1]], outline=(60, 230, 90, 255), width=3)
        dr.text((p0[0] + 4, p1[1] - 16), "camp: zone %s, %.0f x %.0f m" % (code, (x1 - x0) / 100, (y1 - y0) / 100),
                fill=(60, 230, 90), font=font)
    if d.get("player"):
        x, y = px(d["player"]["x"], d["player"]["y"])
        dr.ellipse([x - 6, y - 6, x + 6, y + 6], outline=(60, 230, 90), width=3)
    dr.text((8, 8), "%s - %d m square, N up, grid 10 m; boxes reaching %d..%d cm above the story cats' floor (%d kept)"
            % (d.get("clan", "?"), 2 * half / 100, a.slice_low, a.slice_high, kept), fill=(220, 220, 220), font=font)
    img.save(a.out)
    print("wrote", a.out, size, "px,", kept, "boxes,", len(d.get("cats", [])), "cats,", len(d.get("doors", [])), "doors")


if __name__ == "__main__":
    main()
