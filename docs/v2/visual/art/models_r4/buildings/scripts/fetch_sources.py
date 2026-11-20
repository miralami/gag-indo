"""Download the four verified CC0 GLBs and record source/licence checks.

Run from the repository root:
  python docs/v2/visual/art/models_r4/buildings/scripts/fetch_sources.py

No credential is used or printed. Every hash is computed from the downloaded bytes.
"""
import hashlib
import html
import json
import re
from datetime import datetime, timezone
from pathlib import Path

import requests

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
RAW = ROOT / "raw" / "buildings_r4"
RAW.mkdir(parents=True, exist_ok=True)
HEADERS = {"User-Agent": "JuraganDesa-asset-pipeline/1.0"}
LICENCE_QUOTE = (
    "The short version: every model on Grab3D is dedicated to the public domain under "
    "CC0 1.0 Universal. Use it for anything, commercial or not. No attribution, no account, no fees."
)
LICENCE_KEY = "every model on Grab3D is dedicated to the public domain under CC0 1.0 Universal"
ORIGIN_QUOTE = (
    "Every model goes one of two ways. We don’t label each model with its route. "
    "Instead, it carries a quality tier that tells you what you get."
)

sources = json.loads((HERE / "sources.json").read_text(encoding="utf-8"))
verification = {
    "fetched_utc": datetime.now(timezone.utc).isoformat(),
    "licence_page": sources[0]["licence_page"],
    "licence_quote": LICENCE_QUOTE,
    "origin_page": "https://grab3d.com/how-we-make-models/",
    "origin_quote": ORIGIN_QUOTE,
    "models": [],
}

def plain(markup: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", markup))).strip()


licence = requests.get(verification["licence_page"], headers=HEADERS, timeout=60)
licence.raise_for_status()
licence_plain = plain(licence.text)
if LICENCE_KEY not in licence_plain:
    raise SystemExit("licence quote not found on source page")
origin = requests.get(verification["origin_page"], headers=HEADERS, timeout=60)
origin.raise_for_status()
if ORIGIN_QUOTE not in plain(origin.text):
    raise SystemExit("origin quote not found on source page")

for source in sources:
    page = requests.get(source["page"], headers=HEADERS, timeout=60)
    page.raise_for_status()
    if source["page_claim"] not in plain(page.text):
        raise SystemExit(f"page claim not found: {source['page']}")
    response = requests.get(source["direct"], headers=HEADERS, timeout=180)
    response.raise_for_status()
    if response.content[:4] != b"glTF":
        raise SystemExit(f"not a GLB: {source['direct']}")
    path = RAW / source["file"]
    path.write_bytes(response.content)
    verification["models"].append(
        {
            "slot": source["slot"],
            "name": source["name"],
            "page": source["page"],
            "kit": source["kit"],
            "direct": source["direct"],
            "file": f"raw/buildings_r4/{source['file']}",
            "author": source["author"],
            "licence": source["licence"],
            "page_claim": source["page_claim"],
            "page_http": page.status_code,
            "glb_http": response.status_code,
            "bytes": len(response.content),
            "md5": hashlib.md5(response.content).hexdigest(),
            "sha256": hashlib.sha256(response.content).hexdigest(),
        }
    )
    print(f"{source['slot']}: HTTP {response.status_code}, {len(response.content)} bytes, {path.name}")

(ROOT / "source_verification.json").write_text(
    json.dumps(verification, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
)
