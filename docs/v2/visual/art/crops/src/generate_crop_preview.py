"""Deterministic schematic previews of the round-2 "crops" LookDev candidate.

WORK_QUEUE round 2 item 7. The candidate shows low-poly growth-stage models (bibit/tumbuh/siap)
for all 12 crops in Config/Crops, built from Roblox primitive parts. There is no imported mesh
and no asset ID, so this generator dumps partsFor() from the shipped CropModelCandidates.luau via
Lune and draws a front-elevation schematic per crop/stage from that SAME data — the gallery render
can never drift from the shipped models.

It is a REVIEW AID derived from the recipe data, not a Studio screenshot; the live enable/disable
proof lives in docs/v2/evidence/h/2026-11-19-crop-candidates/. No agent visually graded the art.

Run from anywhere: python docs/v2/visual/art/crops/src/generate_crop_preview.py
"""

from pathlib import Path
import json
import shutil
import subprocess
import sys
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve()
ROOT = HERE.parents[6]
DUMP = HERE.parent / "dump_crops.luau"
RENDER = HERE.parent.parent / "render"
RENDER.mkdir(parents=True, exist_ok=True)

# Ask Lune for the exact partsFor() output so the render reads the shipped recipe, not a copy.
lune = shutil.which("lune") or str(Path.home() / ".rokit" / "bin" / "lune.exe")
raw = subprocess.check_output([lune, "run", str(DUMP)], cwd=str(ROOT))
data = json.loads(raw.decode("utf-8"))

PALETTE = {
    "kertas": "f3e9d2", "tinta": "2b2118", "tinta_lembut": "5b4a38", "senja": "f6c97a",
    "padi": "9bb25a", "daun": "6f8a3f", "genteng": "a8452f", "merah": "a83226",
    "bambu": "b98a5a", "kunyit": "c99a2e", "indigo": "3b4f6b", "malam": "1f4e6b",
    "ungu": "7652a8",
}
CROP_COLORS = {
    "padi": "padi", "singkong": "bambu", "jagung": "kunyit", "bawang": "ungu",
    "cabai": "merah", "tembakau": "daun", "kopi": "genteng", "tebu": "padi",
    "kakao": "bambu", "cengkeh": "genteng", "durian": "padi", "sawit": "padi",
}

STAGES = data["stages"]
CROPS = data["cropIds"]
MODELS = data["models"]

FONT_B = ImageFont.truetype("arialbd.ttf", 18)
FONT = ImageFont.truetype("arial.ttf", 13)
FONT_S = ImageFont.truetype("arial.ttf", 11)

CW, CH = 150, 210
HEADER = 92
COLS = len(CROPS)
W = COLS * CW + 60
H = HEADER + len(STAGES) * CH + 70

sheet = Image.new("RGB", (W, H), "#efe9dd")
d = ImageDraw.Draw(sheet)
d.rectangle((0, 0, W, HEADER - 8), fill="#2b2118")
d.text((24, 14), "crops  -  low-poly growth-stage models (CANDIDATE, not approved)",
       fill="#f3e9d2", font=FONT_B)
d.text((24, 42), "bibit (seedling) / tumbuh (growing) / siap (ready). Front-elevation schematic dumped from CropModelCandidates.partsFor().",
       fill="#d8c9a8", font=FONT_S)
d.text((24, 62), "12 crops x 3 stages. Offsets X/Y in studs; Z is depth (label only). LookDev toggle: enable(\"crops\").",
       fill="#d8c9a8", font=FONT_S)


def colortoken(token, crop):
    if token == "crop":
        token = CROP_COLORS.get(crop, "tinta_lembut")
    return "#" + PALETTE.get(token, "999999")


def shape_draw(dr, cx, cy, w, h, shape, fill):
    outline = "#2b2118"
    if shape == "Sphere":
        dr.ellipse((cx - w/2, cy - h/2, cx + w/2, cy + h/2), fill=fill, outline=outline, width=2)
    elif shape == "Cylinder":
        dr.rounded_rectangle((cx - w/2, cy - h/2, cx + w/2, cy + h/2), radius=min(w, h)/2,
                             fill=fill, outline=outline, width=2)
    elif shape == "Wedge":
        dr.polygon([(cx - w/2, cy + h/2), (cx + w/2, cy + h/2), (cx, cy - h/2)],
                   fill=fill, outline=outline)
    else:
        dr.rectangle((cx - w/2, cy - h/2, cx + w/2, cy + h/2), fill=fill, outline=outline, width=2)


S = 15  # pixels per stud
for ci, crop in enumerate(CROPS):
    gx = 30 + ci * CW
    d.text((gx, HEADER + 2), crop, fill="#2b2118", font=FONT)
    for ri, stage in enumerate(STAGES):
        gy = HEADER + 26 + ri * CH
        d.rectangle((gx - 4, gy, gx + CW - 8, gy + CH - 8), fill="#fbf7ee", outline="#c9b998", width=1)
        d.text((gx, gy + 4), f"{crop} / {stage}", fill="#6a5b46", font=FONT_S)
        parts = MODELS[crop][stage]
        cx = gx + (CW - 8) / 2
        ground = gy + CH - 22
        d.line((gx, ground, gx + CW - 12, ground), fill="#b9a98a", width=2)
        # Draw back-to-front: accents/leaves first, stem, fruit last so fruit reads on top.
        order = {"Accent": 0, "Leaf": 1, "Stem": 2, "Fruit": 3}
        def key(p):
            for k in order:
                if p["name"].startswith(k):
                    return order[k]
            return 2
        for p in sorted(parts, key=key):
            ox, oy, _oz = p["offset"]
            sx, sy, _sz = p["size"]
            px = cx + ox * S
            py = ground - oy * S
            w = max(4, sx * S)
            h = max(4, sy * S)
            shape_draw(d, px, py, w, h, p["shape"], colortoken(p["color"], crop))
        d.text((gx, gy + CH - 18), f"{len(parts)} parts", fill="#8a7b64", font=FONT_S)

ly = HEADER + len(STAGES) * CH + 14
d.text((30, ly), "Shapes: Block / Cylinder / Sphere / Wedge. Colors are ART.md palette tokens; \"crop\" uses the crop's own config colour.",
       fill="#5b4a38", font=FONT_S)
d.text((30, ly + 18), "Review aid derived from recipe data — NOT a Studio screenshot. Designer yes/no only; no agent visually graded this art.",
       fill="#5b4a38", font=FONT_S)

out = RENDER / "contact_sheet.png"
sheet.save(out)
print(f"wrote {out} ({sheet.width}x{sheet.height}) from CropModelCandidates.partsFor() via Lune")
print(f"crops={len(CROPS)} stages={STAGES} total models={len(CROPS)*len(STAGES)}")
