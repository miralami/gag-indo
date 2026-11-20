#!/usr/bin/env python3
"""One A/B/C contact sheet: six faces per option plus the CC0 source text."""

from __future__ import annotations

import pathlib

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[1]
FACES = ROOT / "faces"
OUT = ROOT / "contact_sheet.png"

ORDER = ["SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"]
OPTIONS = {
    "a": (
        "A - Spiaggia di Mondello (clear coastal afternoon)",
        "CC0 1.0 Universal - Andreas Mischok - polyhaven.com/a/spiaggia_di_mondello",
        "No true tropical HDRI exists on Poly Haven; closest CC0 coastal afternoon, no city skyline.",
    ),
    "b": (
        "B - Umhlanga Sunrise (golden hour)",
        "CC0 1.0 Universal - Greg Zaal - polyhaven.com/a/umhlanga_sunrise",
        "Warm sun over a sandy beach; no city skyline.",
    ),
    "c": (
        "C - Overcast Soil Pure Sky (light overcast)",
        "CC0 1.0 Universal - Jarod Guest, Sergej Majboroda",
        "polyhaven.com/a/overcast_soil_puresky - pure sky, no city skyline.",
    ),
}

COL_W = 560
GAP = 16
TOP = 92
BIG = 480
SMALL = 76
SMALL_GAP = 6
LIC_Y = TOP + BIG + 118
HEIGHT = LIC_Y + 96
WIDTH = 3 * COL_W + 4 * GAP


def font(size: int):
    for path in ("C:/Windows/Fonts/segoeui.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            pass
    return ImageFont.load_default()


def main() -> None:
    sheet = Image.new("RGB", (WIDTH, HEIGHT), (18, 22, 26))
    draw = ImageDraw.Draw(sheet)
    title_font = font(22)
    text_font = font(14)
    tiny_font = font(12)

    for index, (key, (title, licence, note)) in enumerate(OPTIONS.items()):
        x0 = GAP + index * (COL_W + GAP)
        draw.text((x0 + 8, 12), title, fill=(236, 240, 244), font=title_font)
        draw.text((x0 + 8, 46), "Roblox Sky faces - 1024x1024 each - CC0", fill=(160, 180, 196), font=tiny_font)

        front = Image.open(FACES / key / "SkyboxFt.png").convert("RGB")
        sheet.paste(front.resize((BIG, BIG), Image.Resampling.LANCZOS), (x0 + (COL_W - BIG) // 2, TOP))

        sy = TOP + BIG + 12
        for i, name in enumerate(ORDER):
            face = Image.open(FACES / key / f"{name}.png").convert("RGB")
            sx = x0 + 10 + i * (SMALL + SMALL_GAP)
            sheet.paste(face.resize((SMALL, SMALL), Image.Resampling.LANCZOS), (sx, sy))
            draw.text((sx + 2, sy + SMALL + 2), name.replace("Skybox", ""), fill=(188, 204, 214), font=tiny_font)

        draw.text((x0 + 10, LIC_Y), licence, fill=(232, 205, 120), font=text_font)
        draw.text((x0 + 10, LIC_Y + 26), note, fill=(170, 192, 204), font=text_font)
        draw.text((x0 + 10, LIC_Y + 52), "CC0 1.0: creativecommons.org/publicdomain/zero/1.0/", fill=(150, 174, 188), font=tiny_font)

    sheet.save(OUT, format="PNG", compress_level=9, optimize=False)
    print("wrote", OUT, sheet.size)


if __name__ == "__main__":
    main()
