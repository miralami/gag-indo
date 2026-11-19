"""Upload the item 23 model candidates through Open Cloud as Model assets.

The API key is read from ROBLOX_API_KEY and never printed, logged or written to
disk. Every ID written to upload_manifest.json comes from a completed operation;
no ID is invented. Prefer the real CC0 GLBs and the deterministic designer-build
GLBs exported by obj_to_glb.py. Source .obj files are NOT uploaded directly:
Open Cloud's Model type accepts .fbx/.gltf/.glb/.rbxm/.rbxmx.
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
            "assetType": "Model",
            "displayName": display_name,
            "description": "Juragan Desa round-3 LookDev model CANDIDATE; not shipped by default.",
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


def candidate_files() -> list[tuple[str, Path, str]]:
    """Return (slot, relative path, source type) for every uploadable model."""
    out: list[tuple[str, Path, str]] = []
    raw_specs = {
        "vegetation_r3/kelapa_cc0": ("raw/vegetation_r3/palm_quaternius.ply.glb", "CC0_DOWNLOAD"),
        "vegetation_r3/bambu_cc0": ("raw/vegetation_r3/bamboo_quaternius.ply.glb", "CC0_DOWNLOAD"),
        "npcs_r3/farmer_cc0": ("raw/npcs_r3/farmer_quaternius.ply.glb", "CC0_DOWNLOAD"),
        "npcs_r3/polisi_cc0": ("raw/npcs_r3/swat_quaternius.ply.glb", "CC0_DOWNLOAD"),
    }
    for slot, (rel, source) in raw_specs.items():
        out.append((slot, Path(rel), source))
    generated = {
        "buildings_r3/rumah": "generated/buildings_r3/rumah_panggung.obj",
        "buildings_r3/kandang": "generated/buildings_r3/kandang_ayam.obj",
        "buildings_r3/gudang": "generated/buildings_r3/gudang_sawmill.obj",
        "vegetation_r3/kelapa_alt": "generated/vegetation_r3/palm_tropical.obj",
        "vegetation_r3/pisang": "generated/vegetation_r3/banana_tropical.obj",
        "vegetation_r3/mangga": "generated/vegetation_r3/mango_tropical.obj",
        "vegetation_r3/shrubs": "generated/vegetation_r3/shrubs_tropical.obj",
        "props_r3/cart": "generated/props_r3/cart_gerobak.obj",
        "props_r3/well": "generated/props_r3/well_sumur.obj",
        "props_r3/stall": "generated/props_r3/market_stall.obj",
        "props_r3/fence": "generated/props_r3/fencing_bambu.obj",
        "props_r3/tools": "generated/props_r3/tools_set.obj",
        "npcs_r3/villager_a": "generated/npcs_r3/npc_petani_caping.obj",
        "npcs_r3/villager_b": "generated/npcs_r3/npc_pedagang.obj",
        "npcs_r3/villager_c": "generated/npcs_r3/npc_petani_wanita.obj",
        "npcs_r3/villager_d": "generated/npcs_r3/npc_tukang_peci.obj",
    }
    for slot, rel in generated.items():
        glb = Path(rel).with_suffix(".glb")
        out.append((slot, Path("export") / glb.relative_to("generated"), "AGENT_GENERATED"))
    return out


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--slot", help="upload only one slot (route check)")
    args = parser.parse_args()

    files = candidate_files()
    if args.slot:
        files = [item for item in files if item[0] == args.slot]
    if args.limit:
        files = files[: args.limit]
    key = api_key()
    existing: list[dict[str, Any]] = []
    if UPLOADS.exists():
        existing = json.loads(UPLOADS.read_text(encoding="utf-8"))
    by_slot = {item["slot"]: item for item in existing}

    for slot, rel, source in files:
        if slot in by_slot:
            print(f"skip {slot}: already uploaded")
            continue
        path = ROOT / rel
        if not path.is_file():
            print(f"stop: missing file for {slot}: {rel} (run obj_to_glb.py first)")
            break
        code, body = post_asset(path, "r3_" + slot.replace("/", "_"), key)
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
            "file": "docs/v2/visual/art/models_r3/" + rel.as_posix(),
            "family": slot.split("/")[0],
            "asset_id": str(asset_id),
            "asset_type": response.get("assetType", "Model"),
            "moderation_state": response.get("moderationState"),
            "operation_id": str(op_id),
            "source_type": source,
            "upload_route": "ROBLOX_API_KEY",
        }
        UPLOADS.write_text(
            json.dumps([by_slot[s] for s, _, _ in candidate_files() if s in by_slot], indent=2, ensure_ascii=False)
            + "\n",
            encoding="utf-8",
        )
        print(f"uploaded {slot}: {asset_id}")


if __name__ == "__main__":
    main()
