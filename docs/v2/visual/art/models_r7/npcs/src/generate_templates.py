"""Draw four 585x559 classic-clothing templates + a 2x2 contact sheet.

WORK_QUEUE item 56. Pure code, deterministic, no upload, no Studio, no visual
grade. Run from the repo root:

    python docs/v2/visual/art/models_r7/npcs/src/generate_templates.py

Requires Pillow. The PNGs are source Images for main session to upload and wire
into Shared.ModelMapNpcsR7; no asset ID is invented here.
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
TEMPLATES = ROOT / "templates"
SHEET = ROOT / "COSTUMES_SHEET.png"
W, H = 585, 559
SIZE = (W, H)

# UV rectangles measured from Roblox's Classic-Clothing-Templates.zip (same as R6).
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
SLEEVES = RIGHT_LIMB_LONG + RIGHT_CAPS + LEFT_LIMB_LONG + LEFT_CAPS

SOGAN = "#5C3A1E"
CREAM = "#E8D9B5"
INDIGO = "#2B3A55"
POLISI = "#6B4A2B"
SEAM = "#4E3520"
BELT = "#151515"
GOLD = "#C8A24A"
PETANI = "#5C7A4E"


def rgb(hex_colour: str) -> tuple[int, int, int]:
    value = hex_colour.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))


def rgba(hex_colour: str, alpha: int = 255) -> tuple[int, int, int, int]:
    return (*rgb(hex_colour), alpha)


def rect(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], colour: str) -> None:
    x, y, w, h = box
    draw.rectangle((x, y, x + w - 1, y + h - 1), fill=colour)


def base_canvas(colour: str) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGB", SIZE, colour)  # no default white in UV gaps
    draw = ImageDraw.Draw(image)
    for region in REGIONS:
        rect(draw, region, colour)
    return image, draw


def parang_panel(image: Image.Image, box: tuple[int, int, int, int], phase: float = 0.0) -> None:
    """Parang batik: 45-degree diagonal bands with an S-shaped sine edge.

    Drawn on a transparent local layer then clipped to the UV panel, so bands
    never bleed into neighbouring faces. Three colours: cream field, sogan-brown
    bands and indigo edge accents.
    """
    x, y, w, h = box
    rect(ImageDraw.Draw(image), box, CREAM)
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    step, period, amplitude, band = 34, 54, 7, 13
    for k in range(-h - step, w + h + step, step):
        upper, lower = [], []
        for t in range(-8, w + 9, 3):
            curve = amplitude * math.sin(2 * math.pi * t / period + k * 0.055 + phase)
            uy = t + k + curve
            upper.append((t, uy))
            lower.append((t, uy + band))
        draw.polygon(upper + list(reversed(lower)), fill=rgba(SOGAN))
        draw.line(upper, fill=rgba(INDIGO), width=2)
        draw.line(lower, fill=rgba(CREAM), width=1)
    image.paste(layer, (x, y), layer.getchannel("A"))


def batik_shirt() -> Image.Image:
    image, _ = base_canvas(CREAM)
    # Motif fills the whole torso and both sleeves, not just one face.
    for index, panel in enumerate(list(TORSO.values()) + SLEEVES):
        parang_panel(image, panel, phase=index * 0.35)
    return image


def polisi_shirt() -> Image.Image:
    image, draw = base_canvas(POLISI)
    front_x, front_y, front_w, front_h = TORSO["front"]

    # Placket + buttons.
    draw.rectangle((front_x + front_w // 2 - 4, front_y, front_x + front_w // 2 + 3, front_y + front_h - 1), fill=SEAM)
    for by in range(front_y + 12, front_y + front_h - 8, 22):
        draw.ellipse((front_x + front_w // 2 - 2, by - 2, front_x + front_w // 2 + 2, by + 2), fill=GOLD)

    # Two chest pockets with flaps.
    for px in (front_x + 10, front_x + front_w - 52):
        draw.rectangle((px, front_y + 60, px + 42, front_y + 100), outline=SEAM, width=2)
        draw.rectangle((px - 2, front_y + 52, px + 44, front_y + 68), fill=SEAM)

    # Front face is mirrored when worn: template-right renders on viewer-left
    # (wearer right), template-left on viewer-right (wearer left).
    # Name tag on the wearer's right chest, badge on the wearer's left chest.
    nx = front_x + front_w - 59  # mirror of front_x + 12 across the front panel
    draw.rectangle((nx, front_y + 20, nx + 46, front_y + 34), fill=CREAM, outline=SEAM, width=2)
    bx = front_x + 12  # mirror of front_x + front_w - 34
    draw.polygon(
        [(bx + 22, front_y + 18), (bx, front_y + 24), (bx + 2, front_y + 40),
         (bx + 11, front_y + 50), (bx + 20, front_y + 40), (bx + 22, front_y + 24)],
        fill=GOLD, outline=SEAM,
    )

    # Epaulettes across the shoulder top and the top corners of the front/back.
    up_x, up_y, up_w, up_h = TORSO["up"]
    draw.rectangle((up_x + 8, up_y + 10, up_x + up_w - 9, up_y + 28), fill=SEAM)
    for name in ("front", "back"):
        tx, ty, tw, _ = TORSO[name]
        draw.rectangle((tx + 4, ty + 2, tx + 40, ty + 14), fill=SEAM)
        draw.rectangle((tx + tw - 40, ty + 2, tx + tw - 4, ty + 14), fill=SEAM)
    return image


def polisi_pants() -> Image.Image:
    image, draw = base_canvas(POLISI)
    up_x, up_y, up_w, up_h = TORSO["up"]
    draw.rectangle((up_x, up_y, up_x + up_w - 1, up_y + up_h - 1), fill=BELT)
    for name in ("front", "back", "left", "right"):
        x, y, w, _ = TORSO[name]
        draw.rectangle((x, y, x + w - 1, y + 12), fill=BELT)
    fx, fy, fw, _ = TORSO["front"]
    draw.rectangle((fx + fw // 2 - 13, fy, fx + fw // 2 + 12, fy + 12), fill=GOLD, outline=BELT, width=2)
    draw.rectangle((fx + fw // 2 - 7, fy + 3, fx + fw // 2 + 6, fy + 9), fill=BELT)
    return image


def petani_shirt() -> Image.Image:
    image, draw = base_canvas(PETANI)
    for x, y, w, h in list(TORSO.values()) + SLEEVES:
        for stripe in range(y + 14, y + h - 10, 34):
            draw.rectangle((x, stripe, x + w - 1, stripe + 6), fill=CREAM)
    fx, fy, _, fh = TORSO["front"]
    draw.polygon([(fx + 42, fy + 2), (fx + 64, fy + 30), (fx + 86, fy + 2)], fill=CREAM)
    draw.rectangle((fx + 54, fy + 30, fx + 74, fy + min(54, fh - 1)), fill=CREAM)
    return image


def label_font(size: int) -> ImageFont.ImageFont:
    for candidate in (
        "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ):
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default(size=size)


def contact_sheet(items: list[tuple[str, Path]]) -> None:
    cell_w, cell_h = 620, 650
    sheet = Image.new("RGB", (cell_w * 2, cell_h * 2), "#202020")
    draw = ImageDraw.Draw(sheet)
    font = label_font(28)
    for index, (label, path) in enumerate(items):
        col, row = index % 2, index // 2
        x0, y0 = col * cell_w, row * cell_h
        draw.rectangle((x0 + 10, y0 + 10, x0 + cell_w - 10, y0 + 58), fill="#101010")
        draw.text((x0 + 24, y0 + 17), label, font=font, fill="#FFFFFF")
        with Image.open(path) as source:
            thumb = source.convert("RGB")
        thumb.thumbnail((cell_w - 40, cell_h - 84))
        sheet.paste(thumb, (x0 + (cell_w - thumb.width) // 2, y0 + 68))
    sheet.save(SHEET, format="PNG")


def main() -> None:
    TEMPLATES.mkdir(parents=True, exist_ok=True)
    makers = {
        "shirt_pak_rt": batik_shirt,
        "shirt_polisi": polisi_shirt,
        "pants_polisi": polisi_pants,
        "shirt_petani": petani_shirt,
    }
    paths: dict[str, Path] = {}
    for code, maker in makers.items():
        path = TEMPLATES / f"{code}.png"
        image = maker()
        assert image.size == SIZE, f"{path.name} is {image.size}, expected {SIZE}"
        image.save(path, format="PNG")
        paths[code] = path
    contact_sheet([
        ("Pak RT batik", paths["shirt_pak_rt"]),
        ("Polisi shirt", paths["shirt_polisi"]),
        ("Polisi pants", paths["pants_polisi"]),
        ("Petani shirt", paths["shirt_petani"]),
    ])
    print(f"wrote {len(paths)} templates and {SHEET.name}")


if __name__ == "__main__":
    main()
