"""Deterministic GLB decimation for buildings_r4 (no Blender MCP in this session).

Run from the repository root:
  python docs/v2/visual/art/models_r4/buildings/scripts/decimate.py

Pinned tool: @gltf-transform/cli@4.5.1 (meshoptimizer simplify). Each source is welded,
simplified at the highest deterministic ratio that reaches the <=7800-triangle working
target (budget: <=8000/landmark in SOURCING_BUILDINGS_VEG.md), textures resized to 1K,
and the stilt-house door node scaled 1.12x in Y so a 22-stud target keeps door >=7.
"""
import hashlib
import json
import os
import shutil
import struct
import subprocess
from pathlib import Path

from inspect_glb import inspect

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
RAW = ROOT / "raw" / "buildings_r4"
EXPORT = ROOT / "export" / "buildings_r4"
TMP = ROOT / "tmp"
for folder in (EXPORT, TMP):
    folder.mkdir(parents=True, exist_ok=True)

NPX = "npx.cmd" if os.name == "nt" else "npx"
CLI = "@gltf-transform/cli@4.5.1"
BUDGET = 8000
WORKING_TARGET = 7800
DOOR_SCALE = 1.12

SPECS = [
    {"slot": "rumah", "raw": "stilt-house-light.glb", "out": "rumah_r4.glb", "scale_door": True},
    {"slot": "kandang", "raw": "chicken-coop.glb", "out": "kandang_r4.glb", "scale_door": False},
    {"slot": "gudang", "raw": "garden-shed.glb", "out": "gudang_r4.glb", "scale_door": False},
    {"slot": "warung", "raw": "market-stall-light.glb", "out": "warung_r4.glb", "scale_door": False},
]


def run_cli(*args: str) -> None:
    command = [NPX, "--yes", CLI, *args]
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    if result.returncode != 0:
        raise SystemExit(f"CLI failed: {' '.join(command)}\n{result.stdout}\n{result.stderr}")
    for line in (result.stdout + result.stderr).splitlines():
        if line.startswith("info:") or line.startswith("error:"):
            print("  " + line)


def count_triangles(path: Path) -> int:
    return inspect(path)["triangles"]


def scale_door_y(path: Path, factor: float) -> None:
    data = path.read_bytes()
    magic, version, _ = struct.unpack_from("<III", data, 0)
    if magic != 0x46546C67 or version != 2:
        raise SystemExit(f"bad GLB header: {path}")
    json_length, json_kind = struct.unpack_from("<II", data, 12)
    if json_kind != 0x4E4F534A:
        raise SystemExit("first chunk is not JSON")
    gltf = json.loads(data[20 : 20 + json_length])
    offset = 20 + json_length
    chunks = []
    while offset < len(data):
        length, kind = struct.unpack_from("<II", data, offset)
        chunks.append((kind, data[offset + 8 : offset + 8 + length]))
        offset += 8 + length
    changed = 0
    for node in gltf.get("nodes", []):
        if "door" not in node.get("name", "").lower():
            continue
        scale = node.get("scale", [1, 1, 1])
        node["scale"] = [scale[0], scale[1] * factor, scale[2]]
        changed += 1
    if changed == 0:
        raise SystemExit(f"no door node found in {path}")
    json_bytes = json.dumps(gltf, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    json_bytes += b" " * ((4 - len(json_bytes) % 4) % 4)
    out = bytearray(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(json_bytes) + sum(8 + len(c) for _, c in chunks)))
    out += struct.pack("<II", len(json_bytes), 0x4E4F534A)
    out += json_bytes
    for kind, body in chunks:
        padded = body + b"\0" * ((4 - len(body) % 4) % 4)
        out += struct.pack("<II", len(padded), kind)
        out += padded
    path.write_bytes(out)


report = {"tool": CLI, "budget": BUDGET, "working_target": WORKING_TARGET, "door_scale_y": DOOR_SCALE, "models": []}

for spec in SPECS:
    source = RAW / spec["raw"]
    welded = TMP / f"{spec['slot']}_weld.glb"
    simplified = TMP / f"{spec['slot']}_simplify.glb"
    final = EXPORT / spec["out"]
    print(f"[{spec['slot']}] source {source.name}")
    raw_stats = inspect(source)
    if raw_stats["images"] == 0:
        raise SystemExit(f"source has no embedded textures: {source}")
    run_cli("weld", str(source), str(welded))

    ratio = min(1.0, round(WORKING_TARGET / max(1, raw_stats["triangles"]) * 1.0, 2))
    attempts = []
    while ratio >= 0.15:
        run_cli("simplify", str(welded), str(simplified), "--ratio", f"{ratio:.2f}", "--error", "0.05")
        triangles = count_triangles(simplified)
        attempts.append({"ratio": round(ratio, 2), "triangles": triangles})
        print(f"  ratio {ratio:.2f} -> {triangles} tris")
        if triangles <= WORKING_TARGET:
            break
        ratio = round(ratio - 0.05, 2)
    else:
        raise SystemExit(f"{spec['slot']}: could not reach {WORKING_TARGET} triangles")

    run_cli("resize", str(simplified), str(final), "--width", "1024", "--height", "1024")
    if spec["scale_door"]:
        scale_door_y(final, DOOR_SCALE)

    stats = inspect(final)
    if stats["triangles"] > BUDGET:
        raise SystemExit(f"{spec['slot']}: {stats['triangles']} tris exceeds {BUDGET}")
    if stats["images"] == 0 or not any(m["baseColorTexture"] is not None for m in stats["materials"]):
        raise SystemExit(f"{spec['slot']}: no textured material survived decimation")
    payload = final.read_bytes()
    report["models"].append(
        {
            "slot": spec["slot"],
            "source": f"raw/buildings_r4/{spec['raw']}",
            "export": f"export/buildings_r4/{spec['out']}",
            "raw_triangles": raw_stats["triangles"],
            "attempts": attempts,
            "final_triangles": stats["triangles"],
            "images": stats["images"],
            "textures": stats["textures"],
            "textured_materials": sum(1 for m in stats["materials"] if m["baseColorTexture"] is not None),
            "bounds_min": stats["bounds_min"],
            "bounds_max": stats["bounds_max"],
            "door_height": (
                round(stats["door_bounds_max"][1] - stats["door_bounds_min"][1], 4)
                if stats["door_bounds_min"]
                else None
            ),
            "bytes": len(payload),
            "sha256": hashlib.sha256(payload).hexdigest(),
        }
    )

(ROOT / "decimation_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print("wrote decimation_report.json")
