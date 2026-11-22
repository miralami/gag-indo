"""Upload the generated R7 villager clothing templates as Image assets via Open Cloud.

The four records below are exactly ModelMapNpcsR7.pendingUpload. The API key is
read from ROBLOX_API_KEY and never printed, logged or written to disk. Every ID
in upload_manifest.json comes from a completed operation. Do not run locally
without the main session's approval, and only after the designer re-review. No
visual verdict claimed.
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
ASSETS_URL = "https://apis.roblox.com/assets/v1/assets"
OPERATION_URL = "https://apis.roblox.com/assets/v1/operations/{id}"
# The only creator id used in this repo's recorded uploads; never invent another.
CREATOR_USER_ID = "172146044"
HEADERS = {"User-Agent": "JuraganDesa-asset-pipeline/1.0"}
RECORDS = [
    {"file": "templates/shirt_pak_rt.png", "code": "shirt_pak_rt", "role": "pak_rt", "kind": "shirt", "size": "585x559"},
    {"file": "templates/shirt_polisi.png", "code": "shirt_polisi", "role": "polisi", "kind": "shirt", "size": "585x559"},
    {"file": "templates/pants_polisi.png", "code": "pants_polisi", "role": "polisi", "kind": "pants", "size": "585x559"},
    {"file": "templates/shirt_petani.png", "code": "shirt_petani", "role": "petani", "kind": "shirt", "size": "585x559"},
]


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
            "assetType": "Image",
            "displayName": display_name,
            "description": "Juragan Desa round-7 R7 villager classic-clothing template; no visual verdict claimed.",
            "creationContext": {"creator": {"userId": CREATOR_USER_ID}},
        }
    )
    with path.open("rb") as handle:
        response = requests.post(
            ASSETS_URL,
            headers={**HEADERS, "x-api-key": key},
            files={"request": (None, request_json, "application/json"), "fileContent": (path.name, handle)},
            timeout=120,
        )
    if response.status_code in (200, 201):
        try:
            return response.status_code, response.json()
        except ValueError:
            pass
    return response.status_code, sanitize(response.text, key)


def wait_operation(operation_id: str, key: str) -> tuple[int, Any]:
    url = OPERATION_URL.format(id=operation_id)
    for _ in range(90):
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
    parser.add_argument("--limit", type=int, default=0, help="upload only the first N files")
    args = parser.parse_args()

    records = RECORDS[: args.limit] if args.limit else RECORDS
    key = api_key()
    if UPLOADS.exists():
        existing = json.loads(UPLOADS.read_text(encoding="utf-8"))
        by_file = {item["file"]: item for item in existing}
    else:
        by_file = {}

    for record in records:
        if record["file"] in by_file:
            print(f"skip {record['file']}: already uploaded")
            continue
        path = ROOT / record["file"]
        display = f"r7_npc_{record['code']}"
        code, body = post_asset(path, display, key)
        print(f"post {path.name}: HTTP {code}")
        if code not in (200, 201):
            print(f"stop: upload failed with HTTP {code}")
            break
        op_id = (body.get("operationId") or body.get("id")) if isinstance(body, dict) else None
        if not op_id:
            print("stop: no operation id in POST response")
            break
        poll_code, result = wait_operation(str(op_id), key)
        print(f"poll {path.name}: HTTP {poll_code}")
        if poll_code != 200 or not isinstance(result, dict) or result.get("done") is not True or result.get("error"):
            print(f"stop: operation failed or timed out with HTTP {poll_code}")
            break
        response = result.get("response") or {}
        asset_id = response.get("assetId")
        if not asset_id:
            print("stop: completed operation had no assetId")
            break
        moderation = response.get("moderationResult") or {}
        row = {
            **record,
            "asset_id": str(asset_id),
            "asset_type": response.get("assetType") or "Image",
            "moderation_state": moderation.get("moderationState") or response.get("moderationState"),
            "operation_id": str(op_id),
            "upload_route": "ROBLOX_API_KEY",
        }
        by_file[record["file"]] = row
        UPLOADS.write_text(
            json.dumps([by_file[r["file"]] for r in RECORDS if r["file"] in by_file], indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"uploaded {path.name}: {asset_id}")


if __name__ == "__main__":
    main()
