"""Build a labelled contact sheet of source previews for the npcs_r4 lane."""

import pathlib

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent / "raw" / "npcs_r4" / "previews"
OUT = ROOT.parent / "source_previews_contact.jpg"
files = sorted(ROOT.glob("*.jpg"))
cell = 280
cols = 4
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (cols * cell, rows * (cell + 28)), (245, 245, 245))
draw = ImageDraw.Draw(sheet)
for index, path in enumerate(files):
    image = Image.open(path).convert("RGB")
    image.thumbnail((cell - 8, cell - 8))
    x, y = (index % cols) * cell, (index // cols) * (cell + 28)
    sheet.paste(image, (x + (cell - image.width) // 2, y + (cell - image.height) // 2))
    draw.text((x + 4, y + cell), path.stem[:38], fill=(10, 10, 10))
sheet.save(OUT, quality=86)
print(OUT, sheet.size, len(files))
