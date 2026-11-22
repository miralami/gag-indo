"""Download the page-verified npcs_r4 source GLBs and record exact attribution.

Reads the cached Poly Pizza model pages written by source_scan.py. Every licence
string and author comes from the page's own embedded metadata. No key is used.
"""

import hashlib
import json
import pathlib
import re
import sys

import requests

HERE = pathlib.Path(__file__).resolve().parent
CACHE = HERE / "page_cache"
ROOT = HERE.parent
RAW = ROOT / "raw" / "npcs_r4"
RAW.mkdir(parents=True, exist_ok=True)

# slot -> page slug. All five are page-verified CC0 or CC BY 3.0 and NOT Quaternius.
SOURCES = {
    "petani_caping": "f-ePrCSeNjW",  # Pleasant peasant, Remy Tauziac, CC-BY 3.0
    "pedagang": "kpw4fiF8St",  # Retail Worker, J-Toastie, CC-BY 3.0
    "petani_wanita": "usAZvwbH0Y",  # Woman, Polygonal Mind, CC0 1.0
    "tukang_peci": "IE7rk47BHn",  # Character_Man, prathm, CC0 1.0 (textured, rigged)
    "polisi": "ipEgtSYI8u",  # Male Officer, J-Toastie, CC-BY 3.0
}

LICENCE_LINKS = {
    "CC-BY 3.0": "https://creativecommons.org/licenses/by/3.0/",
    "CC0 1.0": "https://creativecommons.org/publicdomain/zero/1.0/",
}


def page_html(slug):
    cached = CACHE / ("https___poly_pizza_m_" + slug + ".html")
    if cached.is_file():
        return cached.read_text(encoding="utf-8")
    return requests.get("https://poly.pizza/m/" + slug, timeout=30).text


def metadata(slug):
    html = page_html(slug)
    title = re.search(r"<title[^>]*>([^<]+?)\s*-\s*Free 3D Model", html)
    author = re.search(r'"Creator":\{"Username":"([^"]*)"', html)
    licence = re.search(r'"Licence":"([^"]+)"', html)
    resource = re.search(r'"ResourceID":"([^"]+)"', html)
    tris = re.search(r'"Tris":(\d+)', html)
    if not all((title, author, licence, resource)):
        raise RuntimeError("incomplete page metadata for " + slug)
    if licence.group(1) not in LICENCE_LINKS:
        raise RuntimeError("licence is not CC0/CC BY: " + licence.group(1))
    if author.group(1).strip().lower() == "quaternius":
        raise RuntimeError("Quaternius is banned for this lane")
    return {
        "title": title.group(1).strip(),
        "author": author.group(1).strip(),
        "licence": licence.group(1),
        "licence_url": LICENCE_LINKS[licence.group(1)],
        "page": "https://poly.pizza/m/" + slug,
        "direct_url": "https://static.poly.pizza/" + resource.group(1) + ".glb",
        "page_tris": int(tris.group(1)) if tris else -1,
    }


def main():
    rows = []
    for slot, slug in SOURCES.items():
        meta = metadata(slug)
        response = requests.get(meta["direct_url"], timeout=90)
        if response.status_code != 200 or response.content[:4] != b"glTF":
            raise RuntimeError("bad GLB download for " + slot + ": HTTP " + str(response.status_code))
        path = RAW / (slot + ".glb")
        path.write_bytes(response.content)
        row = {
            "slot": slot,
            "file": "docs/v2/visual/art/models_r4/npcs/raw/npcs_r4/" + slot + ".glb",
            "sha256": hashlib.sha256(response.content).hexdigest(),
            "bytes": len(response.content),
            **meta,
        }
        rows.append(row)
        print(slot, row["title"], row["author"], row["licence"], row["bytes"], flush=True)
    out = ROOT / "sources.json"
    out.write_text(json.dumps(rows, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("WROTE", out, file=sys.stderr)


if __name__ == "__main__":
    main()
