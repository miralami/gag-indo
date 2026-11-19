"""Download the nine Poly Haven CC0 PBR sets for WORK_QUEUE item 21 at 1K.

Every file is fetched from Poly Haven's public API/CDN, checked against the API's
MD5, and recorded with source, licence and author. No Open Cloud ID is invented
here; upload is a separate step (item 20/21).
"""

import hashlib
import json
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "raw"
API = "https://api.polyhaven.com/files/{code}"
HEADERS = {"User-Agent": "JuraganDesa-asset-pipeline/1.0"}

# (poly haven code, surface role, author) — copied from SOURCING_TEXTURES_NPC_ANIM.md.
SETS = [
    ("cobblestone_floor_01", "cobblestone", "Rob Tuytel"),
    ("stony_dirt_path", "dirt_path", "eye-candy.xyz"),
    ("brown_mud_03", "tanah_sawah", "Rob Tuytel"),
    ("farm_furrows", "pematang", "Amal Kumar"),
    ("river_small_rocks", "river_bank", "Rob Tuytel, Rico Cilliers"),
    ("bamboo_wall", "bambu", "Amal Kumar"),
    ("clay_roof_tiles_02", "genteng", "Amal Kumar"),
    ("corrugated_iron", "seng", "Dimitrios Savva, Jenelle van Heerden"),
    ("wood_planks", "wood", "Amal Kumar"),
]
MAPS = [("Diffuse", "diff"), ("nor_gl", "nor"), ("Rough", "rough")]


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    records = []
    for code, surface, author in SETS:
        meta = requests.get(API.format(code=code), headers=HEADERS, timeout=30)
        meta.raise_for_status()
        data = meta.json()
        out_dir = RAW / code
        out_dir.mkdir(parents=True, exist_ok=True)
        for api_name, short in MAPS:
            if api_name not in data:
                raise RuntimeError(f"{code}: missing map {api_name}")
            variants = data[api_name].get("1k") or data[api_name].get("1K")
            if not variants:
                raise RuntimeError(f"{code}/{api_name}: no 1K variant")
            ext = "jpg" if "jpg" in variants else "png"
            info = variants[ext]
            response = requests.get(info["url"], headers=HEADERS, timeout=120)
            response.raise_for_status()
            digest = hashlib.md5(response.content).hexdigest()
            if digest != info["md5"]:
                raise RuntimeError(f"{code}/{api_name}: MD5 mismatch")
            filename = f"{code}_{short}_1k.{ext}"
            (out_dir / filename).write_bytes(response.content)
            records.append(
                {
                    "code": code,
                    "surface": surface,
                    "map": short,
                    "file": f"raw/{code}/{filename}",
                    "source": f"https://polyhaven.com/a/{code}",
                    "url": info["url"],
                    "licence": "CC0",
                    "author": author,
                    "md5": digest,
                    "bytes": info["size"],
                }
            )
        print(f"downloaded {code}: 3 maps, md5 verified")
    (ROOT / "download_manifest.json").write_text(
        json.dumps(records, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"total {len(records)} files recorded")


if __name__ == "__main__":
    main()
