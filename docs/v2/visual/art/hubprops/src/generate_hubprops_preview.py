"""Deterministic schematic previews of the round-2 "hubprops" LookDev candidate.

WORK_QUEUE round 2 item 8. The candidate dresses four shop hubs with small primitive hero-prop
details (crates, produce, cups, desk lamp, lantern, sign). No imported mesh, no asset ID, so this
generator dumps partsFor() from the shipped HubPropCandidates.luau via Lune and draws a
front-elevation schematic per hub from that SAME data — the render cannot drift from the models.
REVIEW AID, not a Studio screenshot; no agent visually graded the art. Run from anywhere:
    python docs/v2/visual/art/hubprops/src/generate_hubprops_preview.py
"""

from pathlib import Path
import json, shutil, subprocess
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve()
ROOT = HERE.parents[6]
DUMP = HERE.parent / "dump_hubprops.luau"
RENDER = HERE.parent.parent / "render"
RENDER.mkdir(parents=True, exist_ok=True)

lune = shutil.which("lune") or str(Path.home() / ".rokit" / "bin" / "lune.exe")
data = json.loads(subprocess.check_output([lune, "run", str(DUMP)], cwd=str(ROOT)).decode("utf-8"))

PALETTE = {
    "kertas":"f3e9d2","tinta":"2b2118","tinta_lembut":"5b4a38","senja":"f6c97a",
    "padi":"9bb25a","daun":"6f8a3f","genteng":"a8452f","merah":"a83226",
    "bambu":"b98a5a","kunyit":"c99a2e","indigo":"3b4f6b","malam":"1f4e6b","ungu":"7652a8",
}
TITLES = {"pasar":"Pasar stall","warung":"Warung counter","polisi":"Pos Polisi desk","pakrt":"Pak RT table"}

FONT_B = ImageFont.truetype("arialbd.ttf", 17)
FONT = ImageFont.truetype("arial.ttf", 13)
FONT_S = ImageFont.truetype("arial.ttf", 11)
CW, CH, HEADER = 420, 560, 82
order = data["hubOrder"]
W = len(order) * CW + 40
H = HEADER + CH + 96
sheet = Image.new("RGB", (W, H), "#efe9dd")
d = ImageDraw.Draw(sheet)
d.rectangle((0, 0, W, HEADER - 8), fill="#2b2118")
d.text((20, 13), "hubprops  -  hero-prop details on the four shop hubs (CANDIDATE, not approved)",
       fill="#f3e9d2", font=FONT_B)
d.text((20, 42), "Front-elevation schematic dumped from HubPropCandidates.partsFor(). Offsets X/Y in anchor-local studs; Z is depth.",
       fill="#d8c9a8", font=FONT_S)
d.text((20, 60), "Attached to each hub's anchor part only while enabled. LookDev toggle: enable(\"hubprops\").",
       fill="#d8c9a8", font=FONT_S)

def shape_draw(dr, cx, cy, w, h, shape, fill):
    o = "#2b2118"
    if shape == "Sphere": dr.ellipse((cx-w/2, cy-h/2, cx+w/2, cy+h/2), fill=fill, outline=o, width=2)
    elif shape == "Cylinder": dr.rounded_rectangle((cx-w/2, cy-h/2, cx+w/2, cy+h/2), radius=min(w,h)/2, fill=fill, outline=o, width=2)
    elif shape == "Wedge": dr.polygon([(cx-w/2,cy+h/2),(cx+w/2,cy+h/2),(cx,cy-h/2)], fill=fill, outline=o)
    else: dr.rectangle((cx-w/2, cy-h/2, cx+w/2, cy+h/2), fill=fill, outline=o, width=2)

S = 11
base_y = HEADER + 300
for ci, key in enumerate(order):
    gx = 20 + ci * CW
    hub = data["hubs"][key]
    parts = data["parts"][key]
    d.rectangle((gx, HEADER+2, gx+CW-12, HEADER+CH-6), fill="#fbf7ee", outline="#c9b998", width=2)
    d.text((gx+12, HEADER+10), TITLES[key], fill="#2b2118", font=FONT)
    d.text((gx+12, HEADER+30), f"model {hub['model']}  /  anchor {hub['anchor']}  /  {len(parts)} parts",
           fill="#6a5b46", font=FONT_S)
    cx = gx + CW/2
    d.line((gx+16, base_y, gx+CW-28, base_y), fill="#b9a98a", width=2)
    for p in parts:
        ox, oy, _oz = p["offset"]; sx, sy, _sz = p["size"]
        px = cx + ox * S
        py = base_y - oy * S
        w, h = max(3, sx*S), max(3, sy*S)
        fill = "#" + PALETTE.get(p["color"], "999999")
        shape_draw(d, px, py, w, h, p["shape"], fill)
    ly = HEADER + CH - 92
    d.text((gx+12, ly), "Recipe parts:", fill="#2b2118", font=FONT)
    ly += 20
    for p in parts:
        d.rectangle((gx+12, ly+1, gx+24, ly+13), fill="#"+PALETTE.get(p["color"],"999999"), outline="#2b2118", width=1)
        d.text((gx+30, ly), f"{p['name']} [{p['shape']}] {p['material']}", fill="#3a3228", font=FONT_S)
        ly += 15

ly = HEADER + CH + 8
d.text((20, ly), "Colors are ART.md §3 palette tokens; the sign board uses each hub's own accent colour. Within budget: ≤12 parts per hub.",
       fill="#5b4a38", font=FONT_S)
d.text((20, ly+18), "Review aid derived from recipe data — NOT a Studio screenshot. Designer yes/no only; no agent visually graded this art.",
       fill="#5b4a38", font=FONT_S)

out = RENDER / "contact_sheet.png"
sheet.save(out)
print(f"wrote {out} ({sheet.width}x{sheet.height}) from HubPropCandidates.partsFor() via Lune")
print("hubs:", ", ".join(f"{k}={len(data['parts'][k])}" for k in order))
