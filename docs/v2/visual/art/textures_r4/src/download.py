"""Download 1K CC0 PBR maps for WORK_QUEUE item 29 (textures_r4).

Poly Haven maps are fetched through the public files API and checked against the
API MD5. ambientCG has no per-file MD5 in its API, so those MD5s are computed
locally and labelled as such. No Open Cloud ID is invented here; upload is a
separate step. The API key is never touched by this script.
"""

import hashlib
import io
import json
import zipfile
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "raw"
POLY_API = "https://api.polyhaven.com/files/{code}"
POLY_ASSETS = "https://api.polyhaven.com/assets"
AMBIENT_API = "https://ambientcg.com/api/v2/full_json"
HEADERS = {"User-Agent": "JuraganDesa-asset-pipeline/1.0"}

POLY_LICENCE_TEXT = (
    "Our assets are all licensed as CC0, which is effectively Public Domain "
    "even in jurisdictions that do not support the Public Domain."
)
AMBIENT_LICENCE_TEXT = (
    "All ambientCG assets are provided under the Creative Commons CC0 1.0 "
    "Universal License. This applies to the downloadable asset files and the "
    "material preview renders shown for each asset on the site."
)

# (poly haven code, surface role, author string from api.polyhaven.com/assets).
POLY_SETS = [
    ("withered_grass", "dry_grass", "Charlotte Baglioni"),
    ("red_laterite_soil_stones", "laterite", "Amal Kumar"),
    ("stony_dirt_path", "sand_path", "eye-candy.xyz"),
    ("cobblestone_floor_04", "cobblestone", "Rob Tuytel"),
    ("weathered_planks", "weathered_planks", "Dimitrios Savva (photography), Dario Barresi (processing)"),
    ("worn_brick_wall", "brick", "Amal Kumar"),
    ("blue_plaster_weathered", "plaster", "Amal Kumar"),
    ("clay_roof_tiles_03", "clay_tile", "Amal Kumar"),
    ("worn_corrugated_iron", "corrugated_metal", "Dimitrios Savva (photography), Jenelle van Heerden (processing)"),
    ("bamboo_wall_02", "bilik", "Amal Kumar"),
    ("river_small_rocks", "riverbank", "Rob Tuytel, Rico Cilliers"),
]

# Poly Haven has no true rice-paddy set; ambientCG Ground026 is tagged
# "clay, flat, mud, smooth", which is the wet paddy surface needed here.
AMBIENT_SETS = [("Ground026", "paddy_mud", "ambientCG")]

MAPS = [("Diffuse", "diff"), ("nor_gl", "nor"), ("Rough", "rough")]
AMBIENT_SUFFIXES = [("Color", "diff"), ("NormalGL", "nor"), ("Roughness", "rough")]


def md5(data: bytes) -> str:
    return hashlib.md5(data).hexdigest()


def fetch_poly() -> list[dict]:
    records: list[dict] = []
    authors = requests.get(POLY_ASSETS, params={"t": "textures"}, headers=HEADERS, timeout=60).json()
    for code, surface, author in POLY_SETS:
        listed = authors.get(code, {}).get("authors", {})
        if not listed:
            raise RuntimeError(f"{code}: no author in Poly Haven assets API")
        meta = requests.get(POLY_API.format(code=code), headers=HEADERS, timeout=60)
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
            digest = md5(response.content)
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
                    "source": "Poly Haven",
                    "source_api": POLY_API.format(code=code),
                    "source_page": f"https://polyhaven.com/a/{code}",
                    "url": info["url"],
                    "licence": "CC0",
                    "licence_url": "https://polyhaven.com/license",
                    "licence_text": POLY_LICENCE_TEXT,
                    "author": author,
                    "author_api": ", ".join(listed),
                    "md5": digest,
                    "md5_source": "Poly Haven files API",
                    "bytes": info["size"],
                }
            )
        print(f"downloaded polyhaven {code}: 3 maps, API MD5 verified")
    return records


def fetch_ambient() -> list[dict]:
    records: list[dict] = []
    for code, surface, author in AMBIENT_SETS:
        meta = requests.get(AMBIENT_API, params={"id": code, "include": "downloadData"}, headers=HEADERS, timeout=60)
        meta.raise_for_status()
        found = meta.json().get("foundAssets") or []
        if not found:
            raise RuntimeError(f"{code}: not in ambientCG API")
        asset = found[0]
        zips = asset.get("downloadFolders", {}).get("default", {}).get("downloadFiletypeCategories", {}).get("zip", {}).get("downloads", [])
        zip_info = next((z for z in zips if z.get("attribute") == "1K-JPG"), None)
        if not zip_info:
            raise RuntimeError(f"{code}: no 1K-JPG download")
        response = requests.get(zip_info["downloadLink"], headers=HEADERS, timeout=180)
        response.raise_for_status()
        archive = zipfile.ZipFile(io.BytesIO(response.content))
        names = archive.namelist()
        out_dir = RAW / code
        out_dir.mkdir(parents=True, exist_ok=True)
        for suffix, short in AMBIENT_SUFFIXES:
            member = next((n for n in names if n.endswith(f"_1K-JPG_{suffix}.jpg")), None)
            if not member:
                raise RuntimeError(f"{code}: missing {suffix} in 1K-JPG zip: {names}")
            content = archive.read(member)
            digest = md5(content)
            filename = f"{code}_{short}_1k.jpg"
            (out_dir / filename).write_bytes(content)
            records.append(
                {
                    "code": code,
                    "surface": surface,
                    "map": short,
                    "file": f"raw/{code}/{filename}",
                    "source": "ambientCG",
                    "source_api": f"{AMBIENT_API}?id={code}",
                    "source_page": asset.get("shortLink", f"https://ambientcg.com/a/{code}"),
                    "url": zip_info["downloadLink"],
                    "licence": "CC0",
                    "licence_url": "https://docs.ambientcg.com/license/",
                    "licence_text": AMBIENT_LICENCE_TEXT,
                    "author": author,
                    "author_api": "ambientCG API exposes no per-asset author field",
                    "md5": digest,
                    "md5_source": "computed locally (ambientCG API gives no per-file MD5)",
                    "bytes": len(content),
                }
            )
        print(f"downloaded ambientcg {code}: 3 maps, local MD5 recorded")
    return records


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    records = fetch_poly() + fetch_ambient()
    (ROOT / "download_manifest.json").write_text(
        json.dumps(records, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"total {len(records)} files recorded")


if __name__ == "__main__":
    main()
