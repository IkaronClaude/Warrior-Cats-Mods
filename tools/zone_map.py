"""The game's zones from above (the zone-name triggers the test harness dumps to zones.json), one panel per zone of
interest - by default every clan's camp, found by its name in the game's string table:

    python tools/zone_map.py <zones.json> <Strings_EN.csv> <out.png> [--match " Camp$"] [--half 9000]

Each panel: the zone's area boxes (green) and gates (thin, bright green), the other zones' boxes around it (orange,
labelled), story cats (red, by role), den doors (blue), and the zone's outline as the clan loop uses it (the rectangle
around its area boxes + 10 m, white dashed). North up, 10 m grid.
"""
import argparse
import csv
import json
import math
import re

from PIL import Image, ImageDraw, ImageFont


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dump")
    ap.add_argument("strings")
    ap.add_argument("out")
    ap.add_argument("--match", default=r" Camp$", help="regex on the zone's English name")
    ap.add_argument("--half", type=float, default=9000, help="half the panel's size (cm)")
    ap.add_argument("--px-per-m", type=float, default=4)
    a = ap.parse_args()
    d = json.load(open(a.dump, encoding="utf-8"))
    text = {}
    with open(a.strings, encoding="utf-8", newline="") as f:
        for row in csv.reader(f):
            if len(row) >= 2:
                text[row[0]] = row[1]
    zones = d["zones"]
    for z in zones:
        z["text"] = text.get(z["name"], z["name"])
        z["gate"] = min(z["ex"], z["ey"]) < 150
    wanted = sorted({z["code"] for z in zones if re.search(a.match, z["text"])})
    scale = a.px_per_m / 100.0
    size = int(2 * a.half * scale)
    cols = 2
    rows = (len(wanted) + cols - 1) // cols
    img = Image.new("RGB", (cols * size, max(1, rows) * size), (24, 26, 30))
    dr = ImageDraw.Draw(img, "RGBA")
    try:
        font = ImageFont.truetype("arial.ttf", 12)
        big = ImageFont.truetype("arial.ttf", 16)
    except OSError:
        font = big = ImageFont.load_default()
    report = []
    for n, code in enumerate(wanted):
        mine = [z for z in zones if z["code"] == code]
        areas = [z for z in mine if not z["gate"]] or mine
        r = lambda z: max(z["ex"], z["ey"])
        x0 = min(z["x"] - r(z) for z in areas) - 1000
        x1 = max(z["x"] + r(z) for z in areas) + 1000
        y0 = min(z["y"] - r(z) for z in areas) - 1000
        y1 = max(z["y"] + r(z) for z in areas) + 1000
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        ox, oy = (n % cols) * size, (n // cols) * size

        def px(x, y):
            return (ox + (y - cy) * scale + size / 2, oy - (x - cx) * scale + size / 2)

        def poly(z):
            yaw = math.radians(z["yaw"])
            pts = []
            for sx, sy in ((1, 1), (1, -1), (-1, -1), (-1, 1)):
                lx, ly = sx * z["ex"], sy * z["ey"]
                pts.append(px(z["x"] + lx * math.cos(yaw) - ly * math.sin(yaw), z["y"] + lx * math.sin(yaw) + ly * math.cos(yaw)))
            return pts

        def inview(x, y):
            return abs(x - cx) < a.half and abs(y - cy) < a.half

        dr.rectangle([ox, oy, ox + size - 1, oy + size - 1], outline=(70, 70, 70))
        for i in range(-int(a.half // 1000), int(a.half // 1000) + 1):
            g = i * 1000
            p0, p1 = px(cx - a.half, cy + g), px(cx + a.half, cy + g)
            dr.line([p0, p1], fill=(255, 255, 255, 16))
            p0, p1 = px(cx + g, cy - a.half), px(cx + g, cy + a.half)
            dr.line([p0, p1], fill=(255, 255, 255, 16))
        for z in zones:
            if z["code"] == code or not inview(z["x"], z["y"]):
                continue
            pts = poly(z)
            dr.polygon(pts, outline=(255, 140, 0, 200), width=2)
            dr.text((min(p[0] for p in pts) + 2, min(p[1] for p in pts) + 2), z["code"], fill=(255, 160, 60), font=font)
        for z in mine:
            dr.polygon(poly(z), fill=(60, 230, 90, 40 if not z["gate"] else 120),
                       outline=(60, 230, 90, 255) if not z["gate"] else (160, 255, 160, 255), width=3)
        p0, p1 = px(x1, y0), px(x0, y1)
        for k in range(int(p0[0]), int(p1[0]), 12):
            dr.line([k, p0[1], min(k + 6, p1[0]), p0[1]], fill=(255, 255, 255), width=2)
            dr.line([k, p1[1], min(k + 6, p1[0]), p1[1]], fill=(255, 255, 255), width=2)
        for k in range(int(p0[1]), int(p1[1]), 12):
            dr.line([p0[0], k, p0[0], min(k + 6, p1[1])], fill=(255, 255, 255), width=2)
            dr.line([p1[0], k, p1[0], min(k + 6, p1[1])], fill=(255, 255, 255), width=2)
        inside_cats = []
        for s in d.get("story", []):
            if not inview(s["x"], s["y"]):
                continue
            x, y = px(s["x"], s["y"])
            dr.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(230, 60, 60))
            dr.text((x + 6, y - 6), s["role"], fill=(255, 150, 150), font=font)
            if x0 <= s["x"] <= x1 and y0 <= s["y"] <= y1:
                inside_cats.append(s["role"])
        inside_doors = 0
        for dd in d.get("doors", []):
            if not inview(dd["x"], dd["y"]):
                continue
            x, y = px(dd["x"], dd["y"])
            dr.rectangle([x - 4, y - 4, x + 4, y + 4], fill=(80, 160, 255))
            if x0 <= dd["x"] <= x1 and y0 <= dd["y"] <= y1:
                inside_doors += 1
        name = text.get(mine[0]["name"], mine[0]["name"])
        line = "%s  %s (%s): %d areas, %d gates, %.0f x %.0f m - %d story cats, %d den doors inside" % (
            code, name, mine[0]["name"], len([z for z in mine if not z["gate"]]), len([z for z in mine if z["gate"]]),
            (x1 - x0) / 100, (y1 - y0) / 100, len(inside_cats), inside_doors)
        report.append(line)
        dr.text((ox + 8, oy + 8), "%s - %s" % (code, name), fill=(240, 240, 240), font=big)
        dr.text((ox + 8, oy + 28), "%.0f x %.0f m, %d story cats, %d den doors inside" % (
            (x1 - x0) / 100, (y1 - y0) / 100, len(inside_cats), inside_doors), fill=(200, 200, 200), font=font)
    img.save(a.out)
    print("\n".join(report))
    print("wrote", a.out)


if __name__ == "__main__":
    main()
