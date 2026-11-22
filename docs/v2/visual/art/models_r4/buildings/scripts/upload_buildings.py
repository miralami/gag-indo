"""Upload the four decimated buildings_r4 GLBs via the verified ROBLOX_API_KEY route.

Run from the repository root:
  python docs/v2/visual/art/models_r4/buildings/scripts/upload_buildings.py

The key is read from the environment only. It is never printed, logged or written to
disk. Every ID in upload_manifest.json comes from a completed Open Cloud operation.
"""
import json
import os
import time
from pathlib import Path
from typing import Any

import requests

ROOT = Path(__file__).resolve().parent.parent
UPLOADS = ROOT / "upload_manifest.json"
ASSETS_URL = "https://apis.roblox.com/assets/v1/assets"
OPERATION_URL = "https://apis.roblox.com/assets/v1/operations/{id}"
CREATOR_USER_ID = "172146044"  # existing r3 upload route; not invented here
HEADERS = {"User-Agent": "JuraganDesa-asset-pipeline/1.0"}
SLOTS = [
    ("buildings_r4/rumah", "export/buildings_r4/rumah_r4.glb"),
    ("buildings_r4/kandang", "export/buildings_r4/kandang_r4.glb"),
    ("buildings_r4/gudang", "export/buildings_r4/gudang_r4.glb"),
    ("buildings_r4/warung", "export/buildings_r4/warung_r4.glb"),
]


def sanitize(text: str, key: str) -> str:
    return text.replace(key, "[REDACTED]")[:500]


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
            "description": "Juragan Desa round-4 LookDev CANDIDATE: real CC0 textured building, not shipped by default.",
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
    for _ in range(120):
        response = requests.get(
            OPERATION_URL.format(id=operation_id),
            headers={**HEADERS, "x-api-key": key},
            timeout=60,
        )
        if response.status_code != 200:
            return response.status_code, sanitize(response.text, key)
        body = response.json()
        if body.get("done") is True or body.get("error"):
            return 200, body
        time.sleep(2)
    return 408, {"error": "operation polling timed out"}


def main() -> None:
    key = api_key()
    sources = {item["slot"]: item for item in json.loads((ROOT / "source_verification.json").read_text(encoding="utf-8"))["models"]}
    existing = json.loads(UPLOADS.read_text(encoding="utf-8")) if UPLOADS.exists() else []
    rows = {item["slot"]: item for item in existing}
    for slot, rel in SLOTS:
        if slot in rows:
            print(f"skip {slot}: already uploaded")
            continue
        path = ROOT / rel
        if not path.is_file():
            raise SystemExit(f"missing file for {slot}: {rel}")
        code, body = post_asset(path, "r4_" + slot.replace("/", "_"), key)
        print(f"post {slot}: HTTP {code}")
        if code not in (200, 201) or not isinstance(body, dict):
            raise SystemExit(f"upload failed with HTTP {code}: {str(body)[:200]}")
        operation_id = body.get("operationId") or body.get("id")
        if not operation_id:
            raise SystemExit("POST response had no operation id")
        poll_code, result = wait_operation(str(operation_id), key)
        if poll_code != 200 or not isinstance(result, dict) or not result.get("done") or result.get("error"):
            raise SystemExit(f"operation not completed: HTTP {poll_code}: {str(result)[:200]}")
        response = result.get("response") or {}
        asset_id = response.get("assetId")
        if not asset_id:
            raise SystemExit("completed operation had no assetId")
        source = sources[slot.split("/")[-1]]
        rows[slot] = {
            "slot": slot,
            "file": "docs/v2/visual/art/models_r4/buildings/" + rel,
            "family": "buildings_r4",
            "asset_id": str(asset_id),
            "asset_type": response.get("assetType", "Model"),
            "moderation_state": response.get("moderationState"),
            "operation_id": str(operation_id),
            "source_type": "CC0_DOWNLOAD_DECIMATED",
            "source_page": source["page"],
            "direct": source["direct"],
            "author": source["author"],
            "licence": source["licence"],
            "sha256": source["sha256"],
            "upload_route": "ROBLOX_API_KEY",
        }
        UPLOADS.write_text(
            json.dumps([rows[s] for s, _ in SLOTS if s in rows], indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        print(f"uploaded {slot}: {asset_id}")


if __name__ == "__main__":
    main()
