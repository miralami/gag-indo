"""Upload the seven props_r4 LookDev GLBs through Open Cloud as Model assets.

Same route as docs/v2/visual/art/models_r3/src/upload_models.py. The key is read
from ROBLOX_API_KEY, never printed, logged or written. Every ID in the manifest
comes from a completed operation; no ID is invented. Re-running skips slots that
are already present in upload_manifest.json.
"""

from __future__ import annotations

import argparse
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
CREATOR_USER_ID = "172146044"
HEADERS = {"User-Agent": "JuraganDesa-asset-pipeline/1.0"}
SLOTS = ["gerobak", "sumur", "lapak", "pagar_bambu", "alat_tani", "karung", "jemuran"]


def sanitize(text: str, key: str) -> str:
    return text.replace(key, "[REDACTED]")[:500]


def api_key() -> str:
    key = os.environ.get("ROBLOX_API_KEY")
    if not key:
        raise RuntimeError("ROBLOX_API_KEY is not set")
    return key


def post_asset(path: Path, display_name: str, key: str) -> tuple[int, Any]:
    request_json = json.dumps({
        "assetType": "Model",
        "displayName": display_name,
        "description": "Juragan Desa round-4 props_r4 LookDev model CANDIDATE; not shipped by default.",
        "creationContext": {"creator": {"userId": CREATOR_USER_ID}},
    })
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
        response = requests.get(OPERATION_URL.format(id=operation_id), headers={**HEADERS, "x-api-key": key}, timeout=60)
        if response.status_code != 200:
            return response.status_code, sanitize(response.text, key)
        body = response.json()
        if body.get("done") is True or body.get("error"):
            return 200, body
        time.sleep(2)
    return 408, {"error": "operation polling timed out"}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--slot", help="upload only one slot (route check / retry)")
    args = parser.parse_args()
    slots = [args.slot] if args.slot else SLOTS
    key = api_key()
    existing: list[dict[str, Any]] = json.loads(UPLOADS.read_text(encoding="utf-8")) if UPLOADS.exists() else []
    by_slot = {row["slot"]: row for row in existing}

    for slot in slots:
        if slot in by_slot:
            print(f"skip {slot}: already uploaded")
            continue
        path = ROOT / "export" / f"{slot}.glb"
        if not path.is_file():
            print(f"stop: missing {path} (run prepare_props.py first)")
            break
        code, body = post_asset(path, "r4_props_" + slot, key)
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
        by_slot[slot] = {
            "slot": slot,
            "file": f"docs/v2/visual/art/models_r4/props/export/{slot}.glb",
            "family": "props_r4",
            "asset_id": str(asset_id),
            "asset_type": response.get("assetType", "Model"),
            "moderation_state": response.get("moderationState"),
            "operation_id": str(op_id),
            "upload_route": "ROBLOX_API_KEY",
        }
        UPLOADS.write_text(json.dumps([by_slot[s] for s in SLOTS if s in by_slot], indent=2) + "\n", encoding="utf-8")
        print(f"uploaded {slot}: {asset_id}")


if __name__ == "__main__":
    main()
