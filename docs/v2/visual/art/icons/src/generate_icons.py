"""Deterministic hand-painted-style icon candidates for LookDev review.

WORK_QUEUE round 2 item 4. Every icon is a 256x256 transparent RGBA PNG with a
bold 'tinta' ink contour and a warm top-left highlight, no text inside the icon.
Slots mirror src/shared/IconMap.luau (12 crops, 5 tiers, 2 currency, 8 phone
apps = 27). These are CANDIDATES awaiting designer yes/no; they are not approved
and are not shipped on by default. Run from anywhere:

    python docs/v2/visual/art/icons/src/generate_icons.py
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
RENDER = ROOT / "render"
RENDER.mkdir(parents=True, exist_ok=True)

INK = "#2B1E16"
SOFT = "#5A4636"
BAMBU = "#6E8B3D"
DAUN = "#4F7A3A"
KUNYIT = "#E3A324"
PADI = "#D9A441"
GENTENG = "#B14A2E"
MERAH = "#C5362B"
INDIGO = "#3B4A7A"
MALAM = "#232B4D"
UNGU = "#6B3F8C"
KERTAS = "#EFE3C8"
HI = (255, 255, 255, 55)


def mix(hex_color, other=(255, 244, 210), f=0.30):
    c = tuple(int(hex_color[i:i + 2], 16) for i in (1, 3, 5))
    return tuple(round(c[j] * (1 - f) + other[j] * f) for j in range(3)) + (255,)


def new():
    return Image.new("RGBA", (256, 256), (0, 0, 0, 0))


def ell(d, box, fill, w=6):
    d.ellipse(box, fill=fill, outline=INK, width=w)


def poly(d, pts, fill, w=6):
    d.polygon(pts, fill=fill)
    d.line(list(pts) + [pts[0]], fill=INK, width=w, joint="curve")


def rrect(d, box, r, fill, w=6):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=INK, width=w)


def line(d, pts, color=INK, w=8):
    d.line(pts, fill=color, width=w, joint="curve")


def shine(d, box):
    d.ellipse(box, fill=HI)


def badge(d, fill, corner=None, border=None):
    rrect(d, (40, 40, 216, 216), 22, fill, 6)
    if border:
        d.rounded_rectangle((54, 54, 202, 202), radius=14, outline=border, width=6)
    if corner:
        for cx, cy in ((58, 58), (198, 58), (58, 198), (198, 198)):
            poly(d, [(cx - 14, cy), (cx, cy - 14), (cx + 14, cy), (cx, cy + 14)], corner, 4)
    shine(d, (58, 56, 116, 100))


def coin_stack(d, n=3, color=KUNYIT):
    for i in range(n):
        y = 168 - i * 26
        ell(d, (56, y - 26, 200, y + 26), color, 6)
        ell(d, (74, y - 18, 182, y + 18), mix(color), 3)
    shine(d, (80, 100, 130, 128))


# --- crops -------------------------------------------------------------------

def crop_padi(d):
    line(d, [(128, 214), (128, 90)], BAMBU, 10)
    for i, x in enumerate((62, 90, 128, 166, 194)):
        line(d, [(128, 210), (x, 70 + (i % 2) * 14)], BAMBU, 7)
        for k in range(4):
            gy = 82 + k * 22 + (i % 2) * 10
            ell(d, (x - 12, gy, x + 12, gy + 26), PADI, 4)
    rrect(d, (104, 188, 152, 212), 8, GENTENG, 5)


def crop_singkong(d):
    poly(d, [(92, 52), (150, 60), (168, 172), (126, 220), (86, 176)], mix("#B98A5E"), 6)
    ell(d, (92, 48, 150, 84), KERTAS, 6)
    ell(d, (108, 58, 138, 78), "#D9C49B", 3)
    poly(d, [(128, 60), (168, 28), (196, 44), (150, 82)], DAUN, 6)
    line(d, [(128, 60), (188, 40)], BAMBU, 4)
    shine(d, (100, 92, 122, 150))


def crop_jagung(d):
    poly(d, [(96, 60), (160, 60), (176, 176), (128, 216), (80, 176)], DAUN, 6)
    ell(d, (92, 50, 164, 178), PADI, 6)
    for gy in range(72, 166, 20):
        line(d, [(98, gy), (158, gy)], "#B8872E", 3)
    for gx in (112, 132, 152):
        line(d, [(gx, 62), (gx, 170)], "#B8872E", 3)
    shine(d, (104, 62, 132, 96))


def crop_bawang(d):
    for x, c in ((96, UNGU), (158, "#9B7B8E")):
        ell(d, (x - 34, 96, x + 34, 190), c, 6)
        poly(d, [(x - 10, 100), (x, 58), (x + 10, 100)], c, 6)
        for k in (-16, 0, 16):
            line(d, [(x + k, 188), (x + k, 214)], SOFT, 4)
        d.arc((x - 30, 108, x + 30, 178), 200, 340, fill=mix(c), width=4)
    shine(d, (74, 112, 100, 140))


def crop_cabai(d):
    for pts, c in (([(78, 74), (108, 70), (120, 150), (96, 206), (72, 176)], MERAH),
                   ([(142, 66), (176, 78), (188, 168), (162, 208), (136, 154)], GENTENG)):
        poly(d, pts, c, 6)
        line(d, [pts[0], (pts[0][0] - 6, pts[0][1] - 26)], DAUN, 7)
        shine(d, (pts[0][0] + 4, pts[0][1] + 8, pts[0][0] + 20, pts[0][1] + 40))


def crop_tembakau(d):
    for pts, c in (([(74, 82), (108, 60), (116, 176), (78, 196)], DAUN),
                   ([(112, 56), (150, 48), (158, 190), (118, 182)], BAMBU),
                   ([(150, 64), (188, 90), (176, 196), (146, 178)], "#8A7A3E")):
        poly(d, pts, c, 6)
        line(d, [(pts[0][0] + 16, pts[0][1] + 8), (pts[2][0] - 6, pts[2][1] - 8)], SOFT, 4)
    rrect(d, (92, 118, 166, 142), 8, GENTENG, 5)
    shine(d, (118, 68, 142, 110))


def crop_kopi(d):
    line(d, [(64, 196), (192, 84)], SOFT, 10)
    for x, y in ((84, 160), (128, 128), (166, 100)):
        ell(d, (x - 30, y - 20, x + 8, y + 12), DAUN, 5)
        ell(d, (x + 2, y + 2, x + 34, y + 30), DAUN, 5)
    for x, y in ((120, 158), (150, 136), (136, 178)):
        ell(d, (x - 12, y - 12, x + 12, y + 12), MERAH, 5)
        ell(d, (x - 4, y - 6, x + 2, y), HI, 0)
    shine(d, (74, 152, 96, 172))


def crop_tebu(d):
    for x, c in ((92, BAMBU), (140, "#A8B34A")):
        rrect(d, (x - 18, 66, x + 18, 214), 10, c, 6)
        for gy in (104, 142, 180):
            line(d, [(x - 16, gy), (x + 16, gy)], SOFT, 4)
    poly(d, [(132, 78), (196, 42), (210, 78), (150, 112)], DAUN, 6)
    shine(d, (80, 74, 96, 140))


def crop_kakao(d):
    ell(d, (74, 54, 182, 214), GENTENG, 6)
    for k in range(5):
        x = 92 + k * 20
        d.arc((x - 10, 62, x + 10, 206), 250, 290, fill=INK, width=5)
        d.arc((x - 10, 62, x + 10, 206), 70, 110, fill=INK, width=5)
    line(d, [(128, 56), (128, 32)], SOFT, 9)
    shine(d, (90, 74, 118, 116))


def crop_cengkeh(d):
    for x, y, a in ((92, 150, -1), (128, 174, 1), (164, 142, -1), (110, 108, 1), (152, 96, -1)):
        line(d, [(x, y + 26), (x + a * 12, y - 12)], SOFT, 7)
        ell(d, (x + a * 4 - 12, y - 34, x + a * 4 + 12, y - 8), "#7A5A3A", 5)
        ell(d, (x + a * 4 - 6, y - 30, x + a * 4 + 2, y - 20), HI, 0)


def crop_durian(d):
    ell(d, (66, 62, 190, 208), DAUN, 6)
    import math
    for i in range(12):
        a = 2 * math.pi * i / 12
        cx, cy = 128 + 62 * math.cos(a), 135 + 72 * math.sin(a)
        pts = [(cx - 10, cy), (cx, cy - 18), (cx + 10, cy)]
        poly(d, pts, BAMBU, 4)
    line(d, [(128, 66), (128, 38)], SOFT, 9)
    shine(d, (88, 82, 118, 120))


def crop_sawit(d):
    for cy in (110, 142, 174):
        row = 5 if cy != 174 else 4
        for i in range(row):
            x = 128 + (i - (row - 1) / 2) * 30 + (14 if cy == 142 else 0)
            ell(d, (x - 16, cy - 16, x + 16, cy + 16), GENTENG if i % 2 else MERAH, 4)
    poly(d, [(128, 92), (90, 56), (118, 52), (136, 88)], DAUN, 5)
    shine(d, (72, 96, 96, 116))


# --- tiers -------------------------------------------------------------------

def tier_biasa(d):
    badge(d, KERTAS)


def tier_bagus(d):
    badge(d, KERTAS, corner=DAUN, border=BAMBU)


def tier_super(d):
    badge(d, KERTAS, border=INDIGO)
    d.rounded_rectangle((62, 62, 194, 194), radius=12, outline=INDIGO, width=4)


def tier_langka(d):
    badge(d, "#EFE3EF", corner=UNGU, border=UNGU)
    ell(d, (112, 108, 144, 140), UNGU, 4)


def tier_sultan(d):
    badge(d, KUNYIT, border="#B8872E")
    for x, y in ((72, 72), (184, 72), (72, 184), (184, 184)):
        poly(d, [(x, y - 12), (x + 4, y - 4), (x + 12, y), (x + 4, y + 4),
                 (x, y + 12), (x - 4, y + 4), (x - 12, y), (x - 4, y - 4)], KERTAS, 3)


# --- currency ----------------------------------------------------------------

def currency_rupiah(d):
    coin_stack(d, 3, KUNYIT)


def cash(d):
    for i, y in enumerate((150, 122, 94)):
        c = KERTAS if i % 2 == 0 else BAMBU
        rrect(d, (52, y, 204, y + 46), 8, c, 5)
        ell(d, (118, y + 10, 138, y + 36), mix(c), 3)
    shine(d, (64, 100, 96, 124))


# --- phone apps --------------------------------------------------------------

def phone(d):
    rrect(d, (78, 34, 178, 222), 18, MALAM, 6)
    rrect(d, (86, 58, 170, 198), 8, KERTAS, 4)
    ell(d, (120, 204, 136, 220), BAMBU, 3)


def garden(d):
    poly(d, [(78, 150), (178, 150), (162, 214), (94, 214)], GENTENG, 6)
    line(d, [(128, 150), (128, 78)], DAUN, 8)
    ell(d, (86, 88, 128, 128), DAUN, 5)
    ell(d, (128, 66, 172, 110), BAMBU, 5)


def debt(d):
    coin_stack(d, 2, GENTENG)
    line(d, [(128, 58), (128, 100)], MERAH, 9)
    poly(d, [(110, 86), (146, 86), (128, 118)], MERAH, 5)


def quest(d):
    rrect(d, (70, 50, 186, 214), 12, KERTAS, 6)
    rrect(d, (104, 38, 152, 70), 8, BAMBU, 5)
    line(d, [(94, 132), (116, 156), (164, 104)], DAUN, 10)


def cheat(d):
    poly(d, [(140, 34), (78, 142), (120, 138), (104, 220), (182, 104), (136, 110)], KUNYIT, 6)
    shine(d, (140, 52, 152, 88))


def hat(d):
    ell(d, (46, 148, 210, 200), MALAM, 6)
    poly(d, [(84, 152), (92, 74), (164, 74), (172, 152)], INDIGO, 6)
    rrect(d, (88, 128, 168, 152), 8, MERAH, 5)


def shop(d):
    rrect(d, (56, 128, 200, 212), 8, KERTAS, 6)
    for i in range(4):
        x = 56 + i * 36
        poly(d, [(x, 116), (x + 36, 116), (x + 30, 84), (x + 6, 84)], GENTENG if i % 2 == 0 else KERTAS, 5)
    line(d, [(56, 116), (200, 116)], INK, 6)


def trophy(d):
    rrect(d, (108, 176, 148, 208), 6, SOFT, 5)
    rrect(d, (84, 204, 172, 224), 8, KUNYIT, 6)
    ell(d, (74, 50, 182, 168), KUNYIT, 6)
    d.arc((28, 62, 88, 140), 270, 90, fill=INK, width=8)
    d.arc((168, 62, 228, 140), 90, 270, fill=INK, width=8)
    shine(d, (92, 66, 122, 104))


ICONS = {
    "crop_padi": crop_padi, "crop_singkong": crop_singkong, "crop_jagung": crop_jagung,
    "crop_bawang": crop_bawang, "crop_cabai": crop_cabai, "crop_tembakau": crop_tembakau,
    "crop_kopi": crop_kopi, "crop_tebu": crop_tebu, "crop_kakao": crop_kakao,
    "crop_cengkeh": crop_cengkeh, "crop_durian": crop_durian, "crop_sawit": crop_sawit,
    "tier_biasa": tier_biasa, "tier_bagus": tier_bagus, "tier_super": tier_super,
    "tier_langka": tier_langka, "tier_sultan": tier_sultan,
    "currency_rupiah": currency_rupiah, "cash": cash,
    "phone": phone, "garden": garden, "debt": debt, "quest": quest,
    "cheat": cheat, "hat": hat, "shop": shop, "trophy": trophy,
}


def main():
    assert len(ICONS) == 27, "expected 27 icon slots"
    for slot, fn in ICONS.items():
        im = new()
        fn(ImageDraw.Draw(im))
        im.save(RENDER / f"{slot}.png")

    # Contact sheet: labelled thumbnails, labels BELOW icons only.
    cols, cell, label = 6, 150, 22
    rows = (len(ICONS) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell, rows * (cell + label)), (239, 227, 200, 255))
    sd = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("arial.ttf", 14)
    except OSError:
        font = ImageFont.load_default()
    for i, slot in enumerate(ICONS):
        x, y = (i % cols) * cell, (i // cols) * (cell + label)
        im = Image.open(RENDER / f"{slot}.png").convert("RGBA").resize((cell - 10, cell - 10))
        sheet.alpha_composite(im, (x + 5, y + 5))
        sd.text((x + 6, y + cell), slot, fill=INK, font=font)
    sheet.save(RENDER / "contact_sheet.png")

    # Validity check.
    for slot in ICONS:
        im = Image.open(RENDER / f"{slot}.png")
        assert im.size == (256, 256) and im.mode == "RGBA", slot
        assert im.getchannel("A").getextrema()[1] > 0, f"empty alpha: {slot}"
    print(f"wrote {len(ICONS)} icons + contact_sheet.png to {RENDER}")


if __name__ == "__main__":
    main()
