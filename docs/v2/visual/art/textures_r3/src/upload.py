"""Upload the item 21 Poly Haven texture maps through Open Cloud.

The API key is read from ROBLOX_API_KEY and never printed, logged or written to disk.
Every ID written to upload_manifest.json is taken from a completed operation; the
script does not invent or guess IDs. The first call is the item 20 route check and
uses a real texture, not a probe file.
"""

import argparse
import json
import os
import time
from pathlib import Path
from typing import Any

import requests

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "download_manifest.json"
UPLOADS = ROOT / "upload_manifest.json"
ROUTE = ROOT / "upload_route_check.json"
ASSETS_URL = "https://apis.roblox.com/assets/v1/assets"
OPERATION_URL = "https://apis.roblox.com/assets/v1/operations/{id}"
# The only creator id used in this repo's recorded uploads; never invent another.
CREATOR_USER_ID = "172146044"
HEADERS = {"User-Agent": "JuraganDesa-asset-pipeline/1.0"}


def sanitize(text: str, key: str | None) -> str:
    if key:
        text = text.replace(key, "[REDACTED]")
    return text[:500]


def api_key() -> str:
    key = os.environ.get("ROBLOX_API_KEY")
    if not key:
        raise RuntimeError("ROBLOX_API_KEY is not set")
    return key


def post_asset(path: Path, display_name: str, asset_type: str, key: str) -> tuple[int, Any]:
    request_json = json.dumps(
        {
            "assetType": asset_type,
            "displayName": display_name,
            "description": "Juragan Desa round-3 CC0 texture LookDev candidate; not shipped by default.",
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
    parser.add_argument("--limit", type=int, default=0, help="upload only the first N files (route check)")
    parser.add_argument("--asset-type", default="Decal", choices=["Decal", "Image"])
    args = parser.parse_args()

    records = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if args.limit:
        records = records[: args.limit]
    key = api_key()
    uploaded: list[dict[str, Any]] = []
    existing: list[dict[str, Any]] = []
    if UPLOADS.exists():
        existing = json.loads(UPLOADS.read_text(encoding="utf-8"))
        by_file = {item["file"]: item for item in existing}
    else:
        by_file = {}

    first = True
    for record in records:
        if record["file"] in by_file:
            print(f"skip {record['file']}: already uploaded")
            continue
        path = ROOT / record["file"]
        display = f"r3_{record['code']}_{record['map']}_1k"
        code, body = post_asset(path, display, args.asset_type, key)
        if first:
            ROUTE.write_text(
                json.dumps(
                    {
                        "route": "ROBLOX_API_KEY env var -> Open Cloud POST /assets/v1/assets",
                        "real_file": record["file"],
                        "asset_type": args.asset_type,
                        "post_status": code,
                        "post_body_excerpt": body if isinstance(body, str) else None,
                    },
                    indent=2,
                )
                + "\n",
                encoding="utf-8",
            )
            first = False
        print(f"post {path.name}: HTTP {code}")
        if code != 200 and code != 201:
            print(f"stop: upload failed with HTTP {code}")
            break
        op_id = body.get("operationId") or body.get("id") if isinstance(body, dict) else None
        if not op_id:
            print(f"stop: no operation id in POST response (HTTP {code})")
            break
        poll_code, result = wait_operation(str(op_id), key)
        print(f"poll {path.name}: HTTP {poll_code}")
        if poll_code != 200 or not isinstance(result, dict) or not result.get("done"):
            print(f"stop: operation failed or timed out with HTTP {poll_code}")
            break
        response = result.get("response") or {}
        asset_id = response.get("assetId")
        if not asset_id:
            print("stop: completed operation had no assetId")
            break
        row = {
            **record,
            "asset_id": str(asset_id),
            "asset_type": response.get("assetType", args.asset_type),
            "moderation_state": response.get("moderationState"),
            "operation_id": str(op_id),
            "upload_route": "ROBLOX_API_KEY",
        }
        uploaded.append(row)
        by_file[record["file"]] = row
        UPLOADS.write_text(
            json.dumps([by_file[r["file"]] for r in records if r["file"] in by_file], indent=2, ensure_ascii=False)
            + "\n",
            encoding="utf-8",
        )
        print(f"uploaded {path.name}: {asset_id}")


if __name__ == "__main__":
    main()
