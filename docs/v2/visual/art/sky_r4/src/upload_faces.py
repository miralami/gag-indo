#!/usr/bin/env python3
"""Upload the 18 sky_r4 Sky cube faces through Open Cloud.

The API key is read from ROBLOX_API_KEY and never printed, logged or written to
disk. Every ID written to upload_manifest.json comes from a completed operation;
no ID is invented. Option A is uploaded first, then B, then C, so a Studio face
check can gate the rest. Resume-safe: faces already in the manifest are skipped.

Basis: docs/v2/visual/art/sky_r3/src/upload_faces.py (same route and polling).
"""

from __future__ import annotations

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
OPTIONS = ("a", "b", "c")
FACE_NAMES = ("SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp")
SOURCES = {
    "a": ("spiaggia_di_mondello", "Andreas Mischok"),
    "b": ("umhlanga_sunrise", "Greg Zaal"),
    "c": ("overcast_soil_puresky", "Jarod Guest, Sergej Majboroda"),
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


def post(path: Path, name: str, key: str) -> tuple[int, Any]:
    request_json = json.dumps(
        {
            "assetType": "Image",
            "displayName": name,
            "description": "Juragan Desa round-4 CC0 HDRI Sky cube face CANDIDATE; not shipped by default.",
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
    by_key = {(item["option"], item["face"]): item for item in existing}

    for option in OPTIONS:
        source, author = SOURCES[option]
        for face in FACE_NAMES:
            if (option, face) in by_key:
                print(f"skip {option}/{face}: already uploaded")
                continue
            path = FACES / option / f"{face}.png"
            code, body = post(path, f"r4_{option}_{face}", key)
            print(f"post {option}/{face}: HTTP {code}")
            if code not in (200, 201) or not isinstance(body, dict):
                print(f"stop: upload failed with HTTP {code}: {str(body)[:200]}")
                return
            op_id = body.get("operationId") or body.get("id")
            if not op_id:
                print("stop: no operation id in POST response")
                return
            poll_code, result = wait(str(op_id), key)
            if poll_code != 200 or not isinstance(result, dict) or not result.get("done"):
                print(f"stop: operation failed or timed out with HTTP {poll_code}: {str(result)[:200]}")
                return
            if result.get("error"):
                print(f"stop: operation error: {str(result.get('error'))[:200]}")
                return
            response = result.get("response") or {}
            asset_id = response.get("assetId")
            if not asset_id:
                print("stop: completed operation had no assetId")
                return
            by_key[(option, face)] = {
                "option": option,
                "face": face,
                "file": f"docs/v2/visual/art/sky_r4/faces/{option}/{face}.png",
                "asset_id": str(asset_id),
                "asset_type": response.get("assetType", "Image"),
                "moderation_state": response.get("moderationState"),
                "operation_id": str(op_id),
                "source": f"Poly Haven {source} CC0 HDRI -> deterministic cubemap",
                "licence": f"CC0 1.0 ({author})",
                "upload_route": "ROBLOX_API_KEY",
            }
            ordered = [by_key[k] for k in ((o, f) for o in OPTIONS for f in FACE_NAMES) if k in by_key]
            UPLOADS.write_text(json.dumps(ordered, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            print(f"uploaded {option}/{face}: {asset_id}")

    print("done:", len(by_key), "faces")


if __name__ == "__main__":
    main()
