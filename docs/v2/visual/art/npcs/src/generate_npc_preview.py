"""Deterministic schematic previews of the round-2 "npcs" LookDev candidate.

WORK_QUEUE round 2 item 6. The candidate adds procedural Roblox primitive parts to the live
box NPCs (Pak RT, Tengkulak, Polisi, debt collector) from src/shared/NpcModelCandidates.luau.
There is no imported mesh and no asset ID, so this generator reads that Luau source DIRECTLY
(parsing the palette and every detail recipe) and draws a front-elevation schematic per NPC:
the box body, each detail piece at its X/Y offset, and a labelled legend with shape, palette
token and offsets. It is a REVIEW AID derived from the shipped recipe data, not a Studio
screenshot; the live enable/disable proof lives in docs/v2/evidence/h/2026-11-19-npc-candidates/.

No randomness. Run from anywhere: python docs/v2/visual/art/npcs/src/generate_npc_preview.py
"""

from pathlib import Path
import re
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
RENDER = ROOT / "render"
RENDER.mkdir(parents=True, exist_ok=True)
SOURCE = Path(__file__).resolve().parents[6] / "src" / "shared" / "NpcModelCandidates.luau"

src = SOURCE.read_text(encoding="utf-8")

# --- Parse palette ---------------------------------------------------------------------------
palette = {}
pal_block = re.search(r"NpcModelCandidates\.palette\s*=\s*\{(.*?)\n\}", src, re.S)
for token, hexv in re.findall(r'(\w+)\s*=\s*"([0-9a-fA-F]{6})"', pal_block.group(1)):
    palette[token] = "#" + hexv

# --- Parse recipes ---------------------------------------------------------------------------
recipes = {}
in_recipes = False
current = None
detail_re = re.compile(
    r'\{\s*name\s*=\s*"([^"]+)",\s*attachTo\s*=\s*"([^"]+)",\s*shape\s*=\s*"([^"]+)",'
    r'\s*size\s*=\s*\{\s*([-\d.]+),\s*([-\d.]+),\s*([-\d.]+)\s*\},'
    r'\s*offset\s*=\s*\{\s*([-\d.]+),\s*([-\d.]+),\s*([-\d.]+)\s*\},'
    r'\s*color\s*=\s*"([^"]+)"\s*\}'
)
for line in src.splitlines():
    if "NpcModelCandidates.recipes" in line and "{" in line:
        in_recipes = True
        continue
    if not in_recipes:
        continue
    if re.match(r"^\}", line):
        in_recipes = False
        continue
    key = re.match(r"^\s*(\w+)\s*=\s*\{", line)
    if key:
        current = key.group(1)
        recipes[current] = []
        continue
    m = detail_re.search(line)
    if m and current:
        name, attach, shape = m.group(1), m.group(2), m.group(3)
        size = tuple(float(m.group(i)) for i in (4, 5, 6))
        offset = tuple(float(m.group(i)) for i in (7, 8, 9))
        color = m.group(10)
        recipes[current].append((name, attach, shape, size, offset, color))

assert set(recipes) >= {"pakrt", "tengkulak", "polisi", "debt_collector"}, recipes.keys()
assert all(len(v) >= 4 for v in recipes.values())

# --- Layout ----------------------------------------------------------------------------------
SCALE = 34  # pixels per stud
PANEL_W, PANEL_H = 400, 720
BODY = {
    "pakrt": ("#5B4A38", "#8a6a44", "#c9a97a"),
    "tengkulak": ("#2f2a25", "#7a3a29", "#b08a5a"),
    "polisi": ("#1f4e6b", "#3b4f6b", "#e8dcc0"),
    "debt_collector": ("#24201c", "#2f2a25", "#b8a98f"),
}
LABELS = {
    "pakrt": "Pak RT",
    "tengkulak": "Tengkulak (Bang Jago)",
    "polisi": "Polisi Desa",
    "debt_collector": "Debt Collector",
}
TORSO_CY, HEAD_CY = 300, 150
PANEL_PAD = 16

try:
    FONT = ImageFont.truetype("arial.ttf", 15)
    FONT_B = ImageFont.truetype("arialbd.ttf", 20)
    FONT_S = ImageFont.truetype("arial.ttf", 13)
except OSError:
    FONT = FONT_B = FONT_S = ImageFont.load_default()

keys = ["pakrt", "tengkulak", "polisi", "debt_collector"]
sheet = Image.new("RGB", (PANEL_W * len(keys), PANEL_H + 70), "#efe9dd")
draw = ImageDraw.Draw(sheet)
draw.rectangle((0, 0, sheet.width, 64), fill="#2b2118")
draw.text((20, 16), "npcs  -  procedural caricature details (CANDIDATE, not approved)",
          fill="#f3e9d2", font=FONT_B)
draw.text((20, 42), "Front-elevation schematic parsed from NpcModelCandidates.luau. Offsets X/Y in studs; Z is depth (not shown). LookDev toggle: enable(\"npcs\").",
          fill="#d8c9a8", font=FONT_S)


def shape_draw(d, cx, cy, w, h, shape, fill, outline):
    if shape == "Sphere":
        d.ellipse((cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), fill=fill, outline=outline, width=2)
    elif shape == "Cylinder":
        d.rounded_rectangle((cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), radius=w / 2,
                            fill=fill, outline=outline, width=2)
    elif shape == "Wedge":
        d.polygon([(cx - w / 2, cy + h / 2), (cx + w / 2, cy + h / 2), (cx - w / 2, cy - h / 2)],
                  fill=fill, outline=outline)
    else:
        d.rectangle((cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), fill=fill, outline=outline, width=2)


for idx, key in enumerate(keys):
    ox = idx * PANEL_W
    torso_c, leg_c, head_c = BODY[key]
    d = ImageDraw.Draw(sheet)
    d.rectangle((ox + 2, 66, ox + PANEL_W - 2, PANEL_H + 68), fill="#fbf7ee", outline="#b9a98a", width=2)
    d.text((ox + PANEL_PAD, 78), LABELS[key], fill="#2b2118", font=FONT_B)
    d.text((ox + PANEL_PAD, 104), f"{key}  -  {len(recipes[key])} detail parts", fill="#6a5b46", font=FONT_S)

    cx = ox + PANEL_W // 2
    ground = 470
    d.line((ox + 40, ground, ox + PANEL_W - 40, ground), fill="#b9a98a", width=2)
    # Box body: legs, torso, head (matches NpcFactory blocky caricature).
    d.rectangle((cx - 46, 360, cx - 12, ground), fill=leg_c, outline="#2b2118", width=2)
    d.rectangle((cx + 12, 360, cx + 46, ground), fill=leg_c, outline="#2b2118", width=2)
    d.rectangle((cx - 56, TORSO_CY - 66, cx + 56, TORSO_CY + 66), fill=torso_c, outline="#2b2118", width=2)
    d.rectangle((cx - 42, HEAD_CY - 42, cx + 42, HEAD_CY + 42), fill=head_c, outline="#2b2118", width=2)

    # Detail pieces at their X/Y offsets relative to the anchor part.
    for (name, attach, shape, size, offset, color) in recipes[key]:
        anchor_cy = HEAD_CY if attach == "Head" else TORSO_CY
        px = cx + offset[0] * SCALE
        py = anchor_cy - offset[1] * SCALE
        w = max(10, size[0] * SCALE)
        h = max(8, size[1] * SCALE)
        fill = palette.get(color, "#999999")
        shape_draw(d, px, py, w, h, shape, fill, "#2b2118")
        d.text((px - 22, py - 6), name[:7], fill="#2b2118" if color in ("kertas", "kunyit", "padi") else "#f3e9d2",
               font=FONT_S)

    # Legend.
    ly = 500
    d.text((ox + PANEL_PAD, ly), "Recipe parts:", fill="#2b2118", font=FONT)
    ly += 24
    for (name, attach, shape, size, offset, color) in recipes[key]:
        fill = palette.get(color, "#999999")
        d.rectangle((ox + PANEL_PAD, ly + 1, ox + PANEL_PAD + 14, ly + 15), fill=fill, outline="#2b2118", width=1)
        d.text((ox + PANEL_PAD + 20, ly),
               f"{name} [{shape}] {attach} @({offset[0]:g},{offset[1]:g},{offset[2]:g})",
               fill="#3a3228", font=FONT_S)
        ly += 18

out = RENDER / "contact_sheet.png"
sheet.save(out)
print(f"wrote {out} ({sheet.width}x{sheet.height}) from {SOURCE.name}")
print(f"palette tokens: {len(palette)}; recipes: " + ", ".join(f"{k}={len(v)}" for k, v in recipes.items()))
