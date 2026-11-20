"""Build labelled review sheets from the downloaded 1K maps.

This is a review aid only. No agent grades the textures; the designer/vision
observer decides. contact_sheet.png shows the colour maps only;
contact_sheet_maps.png shows diff / nor / rough for each surface.
"""

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SHEET = ROOT / "render" / "contact_sheet.png"
MAP_SHEET = ROOT / "render" / "contact_sheet_maps.png"
CELL = 256
LABEL = 38
COLS = 3


def main() -> None:
    records = json.loads((ROOT / "download_manifest.json").read_text(encoding="utf-8"))
    by_code: dict[str, dict] = {}
    for record in records:
        by_code.setdefault(record["code"], {})[record["map"]] = record
    codes = list(by_code)

    rows = (len(codes) + COLS - 1) // COLS
    sheet = Image.new("RGB", (CELL * COLS, (CELL + LABEL) * rows), (28, 28, 28))
    draw = ImageDraw.Draw(sheet)
    for index, code in enumerate(codes):
        record = by_code[code]["diff"]
        col, row = index % COLS, index // COLS
        x, y = col * CELL, row * (CELL + LABEL)
        image = Image.open(ROOT / record["file"]).convert("RGB").resize((CELL, CELL))
        sheet.paste(image, (x, y))
        draw.text((x + 4, y + CELL + 3), f"{record['surface']} / {code}", fill=(240, 240, 240))
        draw.text((x + 4, y + CELL + 18), "1K diffuse - CC0", fill=(170, 190, 170))

    map_rows = len(codes)
    map_sheet = Image.new("RGB", (CELL * 3, (CELL + LABEL) * map_rows), (28, 28, 28))
    map_draw = ImageDraw.Draw(map_sheet)
    for row, code in enumerate(codes):
        for col, key in enumerate(("diff", "nor", "rough")):
            record = by_code[code][key]
            x, y = col * CELL, row * (CELL + LABEL)
            image = Image.open(ROOT / record["file"]).convert("RGB").resize((CELL, CELL))
            map_sheet.paste(image, (x, y))
            map_draw.text((x + 4, y + CELL + 3), f"{record['surface']} / {code}", fill=(240, 240, 240))
            map_draw.text((x + 4, y + CELL + 18), f"{key} - {record['source']}", fill=(170, 190, 170))

    SHEET.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(SHEET)
    map_sheet.save(MAP_SHEET)
    print(f"wrote {SHEET} ({sheet.width}x{sheet.height}, {len(codes)} colour maps)")
    print(f"wrote {MAP_SHEET} ({map_sheet.width}x{map_sheet.height})")


if __name__ == "__main__":
    main()
