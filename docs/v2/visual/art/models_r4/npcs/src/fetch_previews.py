"""Download source preview images for the npcs_r4 shortlist (read-only source pages)."""

import pathlib
import re
import sys

import requests

ROOT = pathlib.Path(__file__).resolve().parent
CACHE = ROOT / "page_cache"
PREVIEWS = ROOT.parent / "raw" / "npcs_r4" / "previews"
PREVIEWS.mkdir(parents=True, exist_ok=True)

for slug in sys.argv[1:]:
    cache = CACHE / ("https___poly_pizza_m_" + slug + ".html")
    html = cache.read_text(encoding="utf-8") if cache.is_file() else requests.get(
        "https://poly.pizza/m/" + slug, timeout=30
    ).text
    title = re.search(r"<title[^>]*>([^<]+?)\s*-\s*Free 3D Model", html)
    poster = re.search(r"poster=(https[^&\"']+\.jpg)", html)
    image = poster.group(1) if poster else None
    if not image:
        image_match = re.search(r'property="og:image" content="([^"]+\.jpg)"', html)
        image = image_match.group(1) if image_match else None
    if not image:
        print("NO PREVIEW", slug)
        continue
    response = requests.get(image, timeout=30)
    label = (title.group(1) if title else slug).replace(" ", "_").replace("/", "_")
    path = PREVIEWS / (slug + "_" + label + ".jpg")
    path.write_bytes(response.content)
    print(slug, response.status_code, len(response.content), path.name)
