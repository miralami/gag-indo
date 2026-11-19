"""Build a review contact sheet from the downloaded Poly Haven 1K maps.

This is a review aid only. No agent grades the textures; the designer/vision
observer decides. Draw order: one row per surface, columns diff / nor / rough.
"""

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SHEET = ROOT / "render" / "contact_sheet.png"
CELL = 224
LABEL = 22


def main() -> None:
    records = json.loads((ROOT / "download_manifest.json").read_text(encoding="utf-8"))
    by_code: dict[str, dict[str, str]] = {}
    for record in records:
        by_code.setdefault(record["code"], {})[record["map"]] = record["file"]

    rows = len(by_code)
    sheet = Image.new("RGB", (CELL * 3, (CELL + LABEL) * rows), (28, 28, 28))
    draw = ImageDraw.Draw(sheet)
    for row, (code, maps) in enumerate(by_code.items()):
        for col, key in enumerate(("diff", "nor", "rough")):
            path = ROOT / maps[key]
            image = Image.open(path).convert("RGB").resize((CELL, CELL))
            sheet.paste(image, (col * CELL, row * (CELL + LABEL)))
            draw.text((col * CELL + 4, row * (CELL + LABEL) + CELL + 4), f"{code} {key}", fill=(235, 235, 235))

    SHEET.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(SHEET)
    print(f"wrote {SHEET} ({sheet.width}x{sheet.height}, {rows} surfaces)")


if __name__ == "__main__":
    main()
