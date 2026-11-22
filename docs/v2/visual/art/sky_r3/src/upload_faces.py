"""Upload the six item-24 Sky cube faces through Open Cloud.

The API key is read from ROBLOX_API_KEY and never printed, logged or written to
disk. Every ID written to upload_manifest.json comes from a completed operation;
no ID is invented.
"""

import json
import os
import time
from pathlib import Path
from typing import Any

import requests

ROOT = Path(__file__).resolve().parent.parent
FACES = ROOT / "faces"
UPLOADS = ROOT / "upload_manifest.json"
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


def post(path: Path, name: str, key: str) -> tuple[int, Any]:
    request_json = json.dumps(
        {
            "assetType": "Image",
            "displayName": name,
            "description": "Juragan Desa round-3 CC0 HDRI Sky cube face CANDIDATE; not shipped by default.",
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


def wait(operation_id: str, key: str) -> tuple[int, Any]:
    url = OPERATION_URL.format(id=operation_id)
    for _ in range(90):
        response = requests.get(url, headers={**HEADERS, "x-api-key": key}, timeout=60)
        if response.status_code != 200:
            return response.status_code, sanitize(response.text, key)
        body = response.json()
        if body.get("done") is True or body.get("error"):
            return 200, body
        time.sleep(2)
    return 408, {"error": "operation polling timed out"}


def main() -> None:
    key = api_key()
    existing: list[dict[str, Any]] = []
    if UPLOADS.exists():
        existing = json.loads(UPLOADS.read_text(encoding="utf-8"))
    by_face = {item["face"]: item for item in existing}
    for path in sorted(FACES.glob("SkyboxImage*.png")):
        face = path.stem
        if face in by_face:
            print(f"skip {face}: already uploaded")
            continue
        code, body = post(path, "r3_" + face, key)
        print(f"post {face}: HTTP {code}")
        if code not in (200, 201) or not isinstance(body, dict):
            print(f"stop: upload failed with HTTP {code}: {str(body)[:200]}")
            break
        op_id = body.get("operationId") or body.get("id")
        if not op_id:
            print("stop: no operation id in POST response")
            break
        poll_code, result = wait(str(op_id), key)
        if poll_code != 200 or not isinstance(result, dict) or not result.get("done"):
            print(f"stop: operation failed or timed out with HTTP {poll_code}: {str(result)[:200]}")
            break
        response = result.get("response") or {}
        asset_id = response.get("assetId")
        if not asset_id:
            print("stop: completed operation had no assetId")
            break
        by_face[face] = {
            "face": face,
            "file": "docs/v2/visual/art/sky_r3/faces/" + path.name,
            "asset_id": str(asset_id),
            "asset_type": response.get("assetType", "Image"),
            "moderation_state": response.get("moderationState"),
            "operation_id": str(op_id),
            "source": "Poly Haven fish_hoek_beach CC0 HDRI -> deterministic cubemap",
            "licence": "CC0 1.0 (Greg Zaal, Rico Cilliers)",
            "upload_route": "ROBLOX_API_KEY",
        }
        UPLOADS.write_text(
            json.dumps([by_face[p.stem] for p in sorted(FACES.glob("SkyboxImage*.png")) if p.stem in by_face], indent=2, ensure_ascii=False)
            + "\n",
            encoding="utf-8",
        )
        print(f"uploaded {face}: {asset_id}")


if __name__ == "__main__":
    main()
