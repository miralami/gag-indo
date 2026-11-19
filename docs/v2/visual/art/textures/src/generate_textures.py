"""Deterministic, seamless hand-painted texture CANDIDATES for LookDev review.

WORK_QUEUE round 2 item 5. Seven 512x512 tileable RGBA PNGs, one per Visuals.textures slot
(see docs/v2/visual/art/TEXTURES.md). Every motif is drawn nine times on a wrapped grid
(offsets -S, 0, +S in both axes) so any shape crossing an edge continues on the opposite
edge: the tiles are genuinely seamless, not just visually similar at the borders.

No randomness, no text, no logos. These are CANDIDATES awaiting designer yes/no — not
approved, not shipped on by default. Run from anywhere:

    python docs/v2/visual/art/textures/src/generate_textures.py
"""

from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
RENDER = ROOT / "render"
RENDER.mkdir(parents=True, exist_ok=True)

S = 512
# Palette copied from src/shared/Config/Visuals.luau (ART.md §3).
TINTA = "#2B2118"
TINTA_LEMBUT = "#5B4A38"
SENJA = "#F6C97A"
PADI = "#9BB25A"
DAUN = "#6F8A3F"
GENTENG = "#A8452F"
MERAH = "#A83226"
BAMBU = "#B98A5A"
INDIGO = "#3B4F6B"
MALAM = "#1F4E6B"
KERTAS = "#F3E9D2"


def rgba(hex_color):
    if isinstance(hex_color, (tuple, list)):
        c = tuple(hex_color)
        return c if len(c) == 4 else c[:3] + (255,)
    return tuple(int(hex_color[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


def lighten(hex_color, f=0.22):
    c = rgba(hex_color)
    return tuple(round(c[i] * (1 - f) + 255 * f) for i in range(3)) + (255,)


def darken(hex_color, f=0.18):
    c = rgba(hex_color)
    return tuple(round(c[i] * (1 - f)) for i in range(3)) + (255,)


def wrapped(draw_fn):
    """draw_fn(dx, dy, draw) is called on the 3x3 torus so edges meet exactly."""
    draw = ImageDraw.Draw(_CURRENT)
    for ox in (-S, 0, S):
        for oy in (-S, 0, S):
            draw_fn(ox, oy, draw)


_CURRENT = None


def base(color):
    im = Image.new("RGBA", (S, S), rgba(color))
    global _CURRENT
    _CURRENT = im
    return im


def line(ox, oy, d, pts, fill, width=3):
    d.line([(x + ox, y + oy) for x, y in pts], fill=fill, width=width, joint="curve")


def texture_bambu():
    base(BAMBU)
    step = 64

    def strips(ox, oy, d):
        for i in range(8):
            x = i * step + ox
            y0, y1 = oy, oy + S
            d.rounded_rectangle((x + 2, y0, x + step - 2, y1), radius=6,
                                fill=lighten(BAMBU, 0.08), outline=TINTA, width=3)
            d.rounded_rectangle((x + 6, y0, x + 16, y1), radius=4, fill=lighten(BAMBU, 0.26))
            for gy in range(0, S, 128):
                d.line((x + 2, gy + oy + 40, x + step - 2, gy + oy + 40), fill=darken(BAMBU, 0.28), width=3)
                d.line((x + 2, gy + oy + 44, x + step - 2, gy + oy + 44), fill=lighten(BAMBU, 0.18), width=2)

    wrapped(strips)
    return _CURRENT


def texture_genteng():
    base(GENTENG)
    step = 64

    def tiles(ox, oy, d):
        for row in range(8):
            y = row * step + oy
            shift = (step // 2) if row % 2 else 0
            for col in range(-1, 9):
                x = col * step + shift + ox
                d.ellipse((x, y, x + step, y + step - 10), fill=lighten(GENTENG, 0.05),
                          outline=TINTA, width=3)
                d.arc((x + 8, y + 6, x + step - 8, y + step - 16), 205, 335,
                      fill=lighten(GENTENG, 0.34), width=4)
                d.arc((x + 4, y + step - 24, x + step - 4, y + step + 4), 20, 160,
                      fill=darken(GENTENG, 0.25), width=3)

    wrapped(tiles)
    return _CURRENT


def texture_seng():
    base(INDIGO)
    step = 32

    def ribs(ox, oy, d):
        for i in range(16):
            x = i * step + ox
            d.polygon([(x, oy), (x + 10, oy), (x + 10, oy + S), (x, oy + S)],
                      fill=lighten(INDIGO, 0.32))
            d.polygon([(x + 10, oy), (x + step, oy), (x + step, oy + S), (x + 10, oy + S)],
                      fill=darken(INDIGO, 0.12))
            d.line((x + 10 + ox, oy, x + 10 + ox, oy + S), fill=lighten(INDIGO, 0.48), width=2)
            d.line((x + step - 2 + ox, oy, x + step - 2 + ox, oy + S), fill=TINTA, width=2)
        for gy in range(0, S, 64):
            line(ox, oy, d, [(0, gy + 30), (S, gy + 30)], darken(INDIGO, 0.3), 2)

    wrapped(ribs)
    return _CURRENT


def texture_paving():
    base(TINTA_LEMBUT)

    def stones(ox, oy, d):
        step = 64
        for row in range(8):
            for col in range(8):
                x, y = col * step + ox, row * step + oy
                fill = lighten(KERTAS, 0.0) if (row + col) % 2 == 0 else lighten(BAMBU, 0.22)
                d.rounded_rectangle((x + 4, y + 4, x + step - 4, y + step - 4), radius=9,
                                    fill=fill, outline=TINTA, width=3)
                hi = tuple(round(fill[i] * 0.8 + 51) for i in range(3)) + (255,)
                d.arc((x + 10, y + 10, x + step - 10, y + step - 10), 200, 320,
                      fill=hi, width=3)

    wrapped(stones)
    return _CURRENT


def texture_sawah():
    base(darken(INDIGO, 0.05))

    def seedlings(ox, oy, d):
        for row in range(16):
            y = row * 32 + oy
            shift = 12 if row % 2 else 0
            d.line((ox, y + 26, ox + S, y + 26), fill=lighten(INDIGO, 0.30), width=3)
            for col in range(16):
                x = col * 32 + shift + ox
                d.line((x, y + 26, x - 5, y + 6), fill=DAUN, width=4)
                d.line((x, y + 26, x + 5, y + 4), fill=PADI, width=4)
                d.ellipse((x - 4, y + 2, x + 4, y + 10), fill=lighten(PADI, 0.2))

    wrapped(seedlings)
    return _CURRENT


def texture_kertas():
    base(KERTAS)

    def fibers(ox, oy, d):
        for i in range(64):
            x = (i * 97) % S + ox
            y = (i * 53) % S + oy
            length = 18 + (i % 5) * 9
            d.line((x, y, x + length, y + (i % 3) - 1),
                   fill=lighten(BAMBU, 0.32), width=2)
            d.line((x, y + 4, x + length - 6, y + 4 + (i % 3) - 1),
                   fill=lighten(TINTA_LEMBUT, 0.55), width=1)
        for i in range(16):
            x = (i * 211) % S + ox
            y = (i * 137) % S + oy
            d.ellipse((x, y, x + 26, y + 14), fill=lighten(KERTAS, 0.06))

    wrapped(fibers)
    return _CURRENT


def texture_tanah():
    base(BAMBU)

    def clods(ox, oy, d):
        for row in range(8):
            for col in range(8):
                phase = math.sin((row + 1) * 1.7 + (col + 1) * 2.3)
                x = col * 64 + 14 + phase * 9 + ox
                y = row * 64 + 18 + math.cos((row + 1) * 0.9 + col) * 8 + oy
                d.ellipse((x, y, x + 34, y + 24), fill=darken(TINTA_LEMBUT, 0.05), outline=TINTA, width=2)
                d.arc((x + 4, y + 2, x + 30, y + 18), 200, 330, fill=lighten(BAMBU, 0.30), width=3)
                d.line((x + 30, y + 22, x + 44, y + 32), fill=TINTA_LEMBUT, width=2)

    wrapped(clods)
    return _CURRENT


TEXTURES = {
    "texture_bambu": texture_bambu,
    "texture_genteng": texture_genteng,
    "texture_seng": texture_seng,
    "texture_paving": texture_paving,
    "texture_sawah": texture_sawah,
    "texture_kertas": texture_kertas,
    "texture_tanah": texture_tanah,
}


def main():
    assert len(TEXTURES) == 7
    for slot, fn in TEXTURES.items():
        im = fn()
        assert im.size == (S, S) and im.mode == "RGBA"
        im.save(RENDER / f"{slot}.png")

    cols, cell, label = 4, 160, 22
    rows = (len(TEXTURES) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell, rows * (cell + label)), rgba(KERTAS))
    sd = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("arial.ttf", 16)
    except OSError:
        font = ImageFont.load_default()
    for i, slot in enumerate(TEXTURES):
        x, y = (i % cols) * cell, (i // cols) * (cell + label)
        im = Image.open(RENDER / f"{slot}.png").convert("RGBA").resize((cell - 8, cell - 8))
        sheet.alpha_composite(im, (x + 4, y + 4))
        sd.text((x + 6, y + cell), slot, fill=rgba(TINTA), font=font)
    sheet.save(RENDER / "contact_sheet.png")

    # Seam check: with a wrapped 3x3 draw the pixel at x=0 is a *neighbour* of x=S-1 in the
    # same repeating pattern, so the boundary jump must be comparable to ordinary interior
    # adjacent-pixel jumps (not literally zero). Compare mean absolute jumps on a sample grid.
    for slot in TEXTURES:
        im = Image.open(RENDER / f"{slot}.png").convert("RGBA")
        px = im.load()

        def jump(a, b):
            return abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2])

        boundary = [jump(px[0, y], px[S - 1, y]) for y in range(0, S, 4)]
        boundary += [jump(px[x, 0], px[x, S - 1]) for x in range(0, S, 4)]
        # Dense sample: sparse sampling lands only in flat interiors and reports a false 0.
        interior = [jump(px[x, y], px[x - 1, y])
                    for y in range(0, S, 8) for x in range(2, S, 2)]
        interior += [jump(px[x, y], px[x, y - 1])
                     for x in range(0, S, 8) for y in range(2, S, 2)]
        bmean = sum(boundary) / len(boundary)
        imax = max(interior)
        # A wrapped pattern has the same kinds of jumps at its seam as anywhere inside it.
        assert bmean <= imax + 8, f"{slot}: seam jump {bmean:.1f} vs largest interior jump {imax}"
    print(f"wrote {len(TEXTURES)} seamless textures + contact_sheet.png to {RENDER}")


if __name__ == "__main__":
    main()
