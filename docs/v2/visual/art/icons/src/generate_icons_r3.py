"""Round-3 icon revision (WORK_QUEUE round 3 item 22, preparation half).

Keeps the round-2 generator as the untouched base for all 27 slots. Redraws
`tier_biasa` and `debt` with bolder silhouettes and applies one deterministic
post-pass (soft contact shadow) to every slot for depth/readability at 48 px.
Writes only into render_r3/; round-2 render/ originals are never modified.
No asset ID is invented and no visual verdict is claimed here.

    python docs/v2/visual/art/icons/src/generate_icons_r3.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

import generate_icons as base

ROOT = Path(__file__).resolve().parents[1]
R2 = ROOT / "render"
R3 = ROOT / "render_r3"
R3.mkdir(parents=True, exist_ok=True)

INK = base.INK
SOFT = base.SOFT
BAMBU = base.BAMBU
DAUN = base.DAUN
KUNYIT = base.KUNYIT
MERAH = base.MERAH
KERTAS = base.KERTAS

# Round-2 slots, base drawings kept byte-for-byte except the two overrides.
ICONS = dict(base.ICONS)


def tier_biasa(d):
    """Plain tier: a single bold seedling in the neutral badge (was an empty box)."""
    base.badge(d, KERTAS)
    base.line(d, [(128, 178), (128, 104)], BAMBU, 12)
    base.ell(d, (90, 104, 134, 146), DAUN, 6)
    base.ell(d, (122, 96, 166, 138), DAUN, 6)
    base.line(d, [(100, 120), (128, 134)], BAMBU, 5)
    base.line(d, [(156, 112), (128, 130)], BAMBU, 5)
    base.shine(d, (136, 100, 156, 118))


def debt(d):
    """Debt: coin stack locked by a red padlock (was an ambiguous arrow/coins mark)."""
    base.coin_stack(d, 2, KUNYIT)
    d.arc((102, 80, 154, 136), 180, 360, fill=INK, width=11)
    base.line(d, [(105, 104), (105, 132)], INK, 11)
    base.line(d, [(151, 104), (151, 132)], INK, 11)
    base.rrect(d, (96, 122, 160, 186), 12, MERAH, 7)
    base.ell(d, (121, 140, 135, 154), INK, 0)
    base.poly(d, [(125, 152), (131, 152), (134, 167), (122, 167)], INK, 0)
    base.shine(d, (106, 128, 126, 148))


ICONS["tier_biasa"] = tier_biasa
ICONS["debt"] = debt


def polish(im):
    """Soft contact shadow only: uniform, deterministic, no meaning change.

    ponytail: one generic pass instead of 25 hand-tuned edits; add per-slot
    contrast/shade work only if the designer/vision review asks for it.
    """
    alpha = im.getchannel("A")
    soft = alpha.filter(ImageFilter.GaussianBlur(6)).point(lambda v: int(v * 0.42))
    shifted = Image.new("L", im.size, 0)
    shifted.paste(soft, (0, 5))
    shadow = Image.new("RGBA", im.size, (31, 22, 16, 0))
    shadow.putalpha(shifted)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.alpha_composite(shadow)
    out.alpha_composite(im)
    return out


def contact_sheet(paths, dest):
    cols, cell, label = 6, 150, 22
    rows = (len(paths) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell, rows * (cell + label)), (239, 227, 200, 255))
    sd = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("arial.ttf", 14)
    except OSError:
        font = ImageFont.load_default()
    for i, (slot, path) in enumerate(paths):
        x, y = (i % cols) * cell, (i // cols) * (cell + label)
        im = Image.open(path).convert("RGBA").resize((cell - 10, cell - 10))
        sheet.alpha_composite(im, (x + 5, y + 5))
        sd.text((x + 6, y + cell), slot, fill=INK, font=font)
    sheet.save(dest)


def main():
    assert len(ICONS) == 27, "expected 27 icon slots"
    for slot, fn in ICONS.items():
        im = base.new()
        fn(ImageDraw.Draw(im))
        polish(im).save(R3 / f"{slot}.png")

    slots = list(ICONS)
    contact_sheet([(s, R2 / f"{s}.png") for s in slots], R3 / "contact_before.png")
    contact_sheet([(s, R3 / f"{s}.png") for s in slots], R3 / "contact_after.png")

    for slot in slots:
        for folder in (R2, R3):
            im = Image.open(folder / f"{slot}.png")
            assert im.size == (256, 256) and im.mode == "RGBA", (folder, slot)
            assert im.getchannel("A").getextrema()[1] > 0, f"empty alpha: {folder}/{slot}"
    print(f"wrote {len(ICONS)} icons + contact_before.png + contact_after.png to {R3}")


if __name__ == "__main__":
    main()
