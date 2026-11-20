"""Upload the five real CC BY textured GLBs as Roblox Model assets (item 31, vegetation_r4).

Mirrors docs/v2/visual/art/models_r3/src/upload_models.py. ROBLOX_API_KEY is read
from the environment and never printed, logged or written to disk. Every ID in
upload_manifest.json comes from a completed Open Cloud operation; none is invented.
"""

import argparse
import json
import os
import time
from pathlib import Path
from typing import Any

import requests

ROOT = Path(__file__).resolve().parent.parent
UPLOADS = ROOT / "upload_manifest.json"
SOURCES = ROOT / "sources.json"
ASSETS_URL = "https://apis.roblox.com/assets/v1/assets"
OPERATION_URL = "https://apis.roblox.com/assets/v1/operations/{id}"
CREATOR_USER_ID = "172146044"
HEADERS = {"User-Agent": "JuraganDesa-asset-pipeline/1.0"}
SLOT_FILE = {
    "kelapa": "raw/vegetation_r4/kelapa.glb",
    "pisang": "raw/vegetation_r4/pisang.glb",
    "bambu": "raw/vegetation_r4/bambu.glb",
    "mangga": "raw/vegetation_r4/mangga.glb",
    "shrubs": "raw/vegetation_r4/shrubs.glb",
}


def sanitize(text: str, key: str | None) -> str:
    if key:
        text = text.replace(key, "[REDACTED]")
    return text[:500]


def api_key() -> str:
    key = os.environ.get("ROBLOX_API_KEY")
    if not key:
        raise RuntimeError("ROBLOX_API_KEY is not set")
    return key


def post_asset(path: Path, display_name: str, key: str) -> tuple[int, Any]:
    request_json = json.dumps(
        {
            "assetType": "Model",
            "displayName": display_name,
            "description": "Juragan Desa round-4 LookDev model CANDIDATE (vegetation_r4); not shipped by default.",
            "creationContext": {"creator": {"userId": CREATOR_USER_ID}},
        }
    )
    with path.open("rb") as handle:
        response = requests.post(
            ASSETS_URL,
            headers={**HEADERS, "x-api-key": key},
            files={"request": (None, request_json, "application/json"), "fileContent": (path.name, handle)},
            timeout=240,
        )
    if response.status_code in (200, 201):
        try:
            return response.status_code, response.json()
        except ValueError:
            pass
    return response.status_code, sanitize(response.text, key)


def wait_operation(operation_id: str, key: str) -> tuple[int, Any]:
    url = OPERATION_URL.format(id=operation_id)
    for _ in range(180):
        response = requests.get(url, headers={**HEADERS, "x-api-key": key}, timeout=90)
        if response.status_code != 200:
            return response.status_code, sanitize(response.text, key)
        body = response.json()
        if body.get("done") is True or body.get("error"):
            return 200, body
        time.sleep(2)
    return 408, {"error": "operation polling timed out"}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--slot", help="upload only one slot (route check)")
    args = parser.parse_args()

    files = list(SLOT_FILE.items())
    if args.slot:
        files = [item for item in files if item[0] == args.slot]
    if args.limit:
        files = files[: args.limit]
    key = api_key()
    sources = {s["slot"]: s for s in json.loads(SOURCES.read_text(encoding="utf-8"))}
    existing = json.loads(UPLOADS.read_text(encoding="utf-8")) if UPLOADS.exists() else []
    by_slot = {item["slot"]: item for item in existing}

    for slot, rel in files:
        if slot in by_slot:
            print(f"skip {slot}: already uploaded")
            continue
        path = ROOT / rel
        if not path.is_file():
            print(f"stop: missing file for {slot}: {rel}")
            break
        code, body = post_asset(path, "r4_" + slot, key)
        print(f"post {slot}: HTTP {code}")
        if code not in (200, 201) or not isinstance(body, dict):
            print(f"stop: upload failed with HTTP {code}: {str(body)[:200]}")
            break
        op_id = body.get("operationId") or body.get("id")
        if not op_id:
            print("stop: no operation id in POST response")
            break
        poll_code, result = wait_operation(str(op_id), key)
        if poll_code != 200 or not isinstance(result, dict) or not result.get("done"):
            print(f"stop: operation failed or timed out with HTTP {poll_code}: {str(result)[:200]}")
            break
        response = result.get("response") or {}
        asset_id = response.get("assetId")
        if not asset_id:
            print("stop: completed operation had no assetId")
            break
        src = sources[slot]
        by_slot[slot] = {
            "slot": slot,
            "file": "docs/v2/visual/art/models_r4/vegetation/" + rel,
            "family": "vegetation_r4",
            "asset_id": str(asset_id),
            "asset_type": response.get("assetType", "Model"),
            "moderation_state": response.get("moderationState"),
            "operation_id": str(op_id),
            "source_page": src["page"],
            "source_glb": src["glb_url"],
            "author": src["creator"],
            "licence": "CC BY 3.0 (Creative Commons Attribution)",
            "licence_url": src["licence_url"],
            "attribution": f'"{src["title"].split(" - Free 3D Model")[0]}" by {src["creator"]}, CC BY 3.0, via Poly Pizza ({src["page"]})',
            "tris": src["glb"]["tris"],
            "source_type": "CC_BY_DOWNLOAD",
            "upload_route": "ROBLOX_API_KEY",
        }
        UPLOADS.write_text(
            json.dumps([by_slot[s] for s in SLOT_FILE if s in by_slot], indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        print(f"uploaded {slot}: {asset_id}")


if __name__ == "__main__":
    main()
