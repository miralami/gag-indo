"""Upload the item 22 r3 icon candidates through Open Cloud.

The API key is read from ROBLOX_API_KEY and never printed, logged or written to
disk. Every ID written to upload_manifest.json is taken from a completed
operation; the script does not invent or guess IDs.
"""

import argparse
import json
import os
import time
from pathlib import Path
from typing import Any

import requests

ROOT = Path(__file__).resolve().parent.parent
RENDERS = ROOT / "render_r3"
UPLOADS = RENDERS / "upload_manifest.json"
ASSETS_URL = "https://apis.roblox.com/assets/v1/assets"
OPERATION_URL = "https://apis.roblox.com/assets/v1/operations/{id}"
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


def post_asset(path: Path, display_name: str, key: str) -> tuple[int, Any]:
    request_json = json.dumps(
        {
            "assetType": "Image",
            "displayName": display_name,
            "description": "Juragan Desa round-3 original icon CANDIDATE; not shipped by default.",
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
    parser.add_argument("--limit", type=int, default=0)
    args = parser.parse_args()

    pngs = sorted(p for p in RENDERS.glob("*.png") if not p.name.startswith("contact_"))
    if args.limit:
        pngs = pngs[: args.limit]
    key = api_key()
    existing: list[dict[str, Any]] = []
    if UPLOADS.exists():
        existing = json.loads(UPLOADS.read_text(encoding="utf-8"))
    by_slot = {item["slot"]: item for item in existing}

    for path in pngs:
        slot = path.stem
        if slot in by_slot:
            print(f"skip {slot}: already uploaded")
            continue
        code, body = post_asset(path, f"r3_icon_{slot}", key)
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
            print(f"stop: operation failed or timed out with HTTP {poll_code}")
            break
        response = result.get("response") or {}
        asset_id = response.get("assetId")
        if not asset_id:
            print("stop: completed operation had no assetId")
            break
        by_slot[slot] = {
            "slot": slot,
            "file": f"docs/v2/visual/art/icons/render_r3/{path.name}",
            "asset_id": str(asset_id),
            "asset_type": response.get("assetType", "Image"),
            "moderation_state": response.get("moderationState"),
            "operation_id": str(op_id),
            "source": "agent-generated (round-2 base + r3 redraw)",
            "licence": "original artwork, no third-party licence",
            "upload_route": "ROBLOX_API_KEY",
        }
        UPLOADS.write_text(
            json.dumps([by_slot[p.stem] for p in sorted(RENDERS.glob("*.png")) if not p.name.startswith("contact_") and p.stem in by_slot], indent=2, ensure_ascii=False)
            + "\n",
            encoding="utf-8",
        )
        print(f"uploaded {slot}: {asset_id}")


if __name__ == "__main__":
    main()
