"""Upload the five verified npcs_r4 GLBs through Open Cloud as Model assets.

Key from ROBLOX_API_KEY only; never printed, logged or written to disk. Every ID
in upload_manifest.json comes from a completed operation, never invented.
Route copied from docs/v2/visual/art/models_r3/src/upload_models.py.
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
HEADERS = {"User-Agent": "JuraganDesa-npcs-r4-pipeline/1.0"}
SLOTS = ("petani_caping", "pedagang", "petani_wanita", "tukang_peci", "polisi")


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
            "description": "Juragan Desa round-4 npcs_r4 LookDev CANDIDATE; textured source model; not shipped by default.",
            "creationContext": {"creator": {"userId": CREATOR_USER_ID}},
        }
    )
    with path.open("rb") as handle:
        response = requests.post(
            ASSETS_URL,
            headers={**HEADERS, "x-api-key": key},
            files={"request": (None, request_json, "application/json"), "fileContent": (path.name, handle)},
            timeout=180,
        )
    if response.status_code in (200, 201):
        try:
            return response.status_code, response.json()
        except ValueError:
            pass
    return response.status_code, sanitize(response.text, key)


def wait_operation(operation_id: str, key: str) -> tuple[int, Any]:
    url = OPERATION_URL.format(id=operation_id)
    for _ in range(120):
        response = requests.get(url, headers={**HEADERS, "x-api-key": key}, timeout=60)
        if response.status_code != 200:
            return response.status_code, sanitize(response.text, key)
        body = response.json()
        if body.get("done") is True:
            return 200, body
        if body.get("error"):
            return 200, body
        time.sleep(2)
    return 408, {"error": "operation polling timed out"}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--slot", help="upload only one slot (route check)")
    args = parser.parse_args()

    metadata = {row["slot"]: row for row in json.loads(SOURCES.read_text(encoding="utf-8"))}
    files = [(slot, ROOT / "export" / "npcs_r4" / (slot + ".glb")) for slot in SLOTS]
    if args.slot:
        files = [item for item in files if item[0] == args.slot]
    key = api_key()
    existing: list[dict[str, Any]] = []
    if UPLOADS.exists():
        existing = json.loads(UPLOADS.read_text(encoding="utf-8"))
    by_slot = {item["slot"]: item for item in existing}

    for slot, path in files:
        if slot in by_slot:
            print(f"skip {slot}: already uploaded")
            continue
        if not path.is_file():
            print(f"stop: missing export for {slot}: {path}")
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
        meta = metadata[slot]
        by_slot[slot] = {
            "slot": "npcs_r4/" + slot,
            "file": "docs/v2/visual/art/models_r4/npcs/export/npcs_r4/" + slot + ".glb",
            "family": "npcs_r4",
            "asset_id": str(asset_id),
            "asset_type": response.get("assetType", "Model"),
            "moderation_state": response.get("moderationState"),
            "operation_id": str(op_id),
            "source_type": "CC0_DOWNLOAD" if meta["licence"].startswith("CC0") else "CC_BY_DOWNLOAD",
            "source_page": meta["page"],
            "source_title": meta["title"],
            "author": meta["author"],
            "licence": meta["licence"],
            "licence_url": meta["licence_url"],
            "attribution": f'"{meta["title"]}" by {meta["author"]} — {meta["licence"]} ({meta["licence_url"]}); source: {meta["page"]}',
            "upload_route": "ROBLOX_API_KEY",
        }
        UPLOADS.write_text(
            json.dumps([by_slot[s] for s in SLOTS if s in by_slot], indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        print(f"uploaded {slot}: {asset_id}")


if __name__ == "__main__":
    main()
