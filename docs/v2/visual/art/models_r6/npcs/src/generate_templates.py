"""Draw ten 585x559 classic-clothing templates for R6 villager costumes.

Flat colours only, deterministic patterns. No upload, no Studio, no visual grade.
Run: python docs/v2/visual/art/models_r6/npcs/src/generate_templates.py
"""

import json
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
TEMPLATES = ROOT / "templates"
MANIFEST = ROOT / "download_manifest.json"
W, H = 585, 559
SIZE = f"{W}x{H}"

# UV rectangles measured from Roblox's Classic-Clothing-Templates.zip.
TORSO = {
    "up": (231, 8, 128, 64),
    "front": (231, 74, 128, 128),
    "right": (165, 74, 64, 128),
    "left": (361, 74, 64, 128),
    "back": (427, 74, 128, 128),
    "down": (231, 204, 128, 64),
}
RIGHT_LIMB_LONG = [(19, 355, 64, 128), (85, 355, 64, 128), (151, 355, 64, 128), (217, 355, 64, 128)]
RIGHT_CAPS = [(217, 289, 64, 64), (217, 485, 64, 64)]
LEFT_LIMB_LONG = [(308, 355, 64, 128), (374, 355, 64, 128), (440, 355, 64, 128), (506, 355, 64, 128)]
LEFT_CAPS = [(308, 289, 64, 64), (308, 485, 64, 64)]
REGIONS = list(TORSO.values()) + RIGHT_LIMB_LONG + RIGHT_CAPS + LEFT_LIMB_LONG + LEFT_CAPS
LONG_FACES = RIGHT_LIMB_LONG + LEFT_LIMB_LONG

# role -> kind -> (base, accent). Accent is unused where no pattern is specified.
PALETTE = {
    "polisi": {"shirt": ("#6B4A2F", "#4E3522"), "pants": ("#4A3524", None)},
    "pak_rt": {"shirt": ("#E8D8B0", "#3A2A1A"), "pants": ("#3A2A1A", None)},
    "petani": {"shirt": ("#9AAF9A", "#B4C4B4"), "pants": ("#8A7A55", "#5F5338")},
    "pedagang": {"shirt": ("#3E7C74", "#C9B79A"), "pants": ("#3A4A55", None)},
    "petani_wanita": {"shirt": ("#D98A9A", "#F2BFC9"), "pants": ("#6A4A5A", None)},
}
ROLES = list(PALETTE)


def rect(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], colour: str) -> None:
    x, y, w, h = box
    draw.rectangle((x, y, x + w - 1, y + h - 1), fill=colour)


def panel(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], base: str, accent: str, style: str, rng: random.Random) -> None:
    x, y, w, h = box
    rect(draw, box, base)
    if style == "placket":
        sw = 10
        draw.rectangle((x + w // 2 - sw // 2, y, x + w // 2 + sw // 2 - 1, y + h - 1), fill=accent)
    elif style == "batik":
        for cy in range(y + 12, y + h - 8, 24):
            for cx in range(x + 12, x + w - 8, 24):
                px, py = cx + rng.randint(-3, 3), cy + rng.randint(-3, 3)
                r = rng.choice((2, 3))
                draw.polygon([(px, py - r), (px + r, py), (px, py + r), (px - r, py)], fill=accent)
    elif style == "fade":
        for by in range(y + 16, y + h - 8, 30):
            draw.rectangle((x, by, x + w - 1, by + 7), fill=accent)
    elif style == "cuff":
        draw.rectangle((x, y + h - 14, x + w - 1, y + h - 1), fill=accent)
    elif style == "apron":
        aw, ah = 64, 84
        draw.rectangle((x + (w - aw) // 2, y + 24, x + (w + aw) // 2 - 1, y + 24 + ah - 1), fill=accent)
    elif style == "stripes":
        for sx in range(x + 10, x + w - 8, 18):
            draw.rectangle((sx, y, sx + 5, y + h - 1), fill=accent)


def decorate(draw: ImageDraw.ImageDraw, role: str, kind: str, base: str, accent: str, rng: random.Random) -> None:
    if kind == "shirt":
        if role == "polisi":
            panel(draw, TORSO["front"], base, accent, "placket", rng)
        elif role == "pak_rt":
            for name in ("front", "back"):
                panel(draw, TORSO[name], base, accent, "batik", rng)
        elif role == "petani":
            for box in list(TORSO.values()) + LONG_FACES:
                panel(draw, box, base, accent, "fade", rng)
        elif role == "pedagang":
            panel(draw, TORSO["front"], base, accent, "apron", rng)
        elif role == "petani_wanita":
            for box in list(TORSO.values()) + LONG_FACES:
                panel(draw, box, base, accent, "stripes", rng)
    elif role == "petani":
        for box in LONG_FACES:
            panel(draw, box, base, accent, "cuff", rng)


def make(role: str, kind: str) -> dict[str, str]:
    base, accent = PALETTE[role][kind]
    # Full-canvas base: UV gaps are never default white.
    image = Image.new("RGB", (W, H), base)
    draw = ImageDraw.Draw(image)
    for box in REGIONS:
        rect(draw, box, base)
    decorate(draw, role, kind, base, accent, random.Random(20261120))

    code = f"{kind}_{role}"
    relative = f"templates/{code}.png"
    path = ROOT / relative
    image.save(path, format="PNG")
    with Image.open(path) as written:
        assert written.size == (W, H), f"{path} is {written.size}, expected {SIZE}"
    return {"file": relative, "code": code, "role": role, "kind": kind, "size": SIZE}


def main() -> None:
    TEMPLATES.mkdir(parents=True, exist_ok=True)
    records = [make(role, kind) for role in ROLES for kind in ("shirt", "pants")]
    MANIFEST.write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {len(records)} templates and {MANIFEST.name}")


if __name__ == "__main__":
    main()
