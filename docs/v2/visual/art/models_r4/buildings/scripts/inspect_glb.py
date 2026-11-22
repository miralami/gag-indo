"""Inspect a GLB without third-party libraries: geometry, textures and bounds."""
import json
import struct
import sys
from pathlib import Path

import numpy as np


def load_glb(path: Path):
    data = path.read_bytes()
    if data[:4] != b"glTF":
        raise SystemExit(f"not a GLB: {path}")
    magic, version, total = struct.unpack_from("<III", data, 0)
    if magic != 0x46546C67:
        raise SystemExit("bad GLB magic")
    offset = 12
    chunks = {}
    while offset < min(total, len(data)):
        length, kind = struct.unpack_from("<II", data, offset)
        body = data[offset + 8 : offset + 8 + length]
        chunks[kind] = body
        offset += 8 + length
    return json.loads(chunks[0x4E4F534A]), chunks.get(0x004E4942, b"")


def trs_matrix(node):
    if "matrix" in node:
        return np.array(node["matrix"], dtype=float).reshape(4, 4).T
    t = node.get("translation", [0, 0, 0])
    r = node.get("rotation", [0, 0, 0, 1])
    s = node.get("scale", [1, 1, 1])
    x, y, z, w = r
    rot = np.array(
        [
            [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w), 0],
            [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w), 0],
            [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y), 0],
            [0, 0, 0, 1],
        ],
        dtype=float,
    )
    mat = np.eye(4)
    mat[:3, :3] = rot[:3, :3] @ np.diag(s)
    mat[:3, 3] = t
    return mat


def accessor_bounds(gltf, index):
    accessor = gltf["accessors"][index]
    if "min" in accessor and "max" in accessor:
        return np.array(accessor["min"], dtype=float), np.array(accessor["max"], dtype=float)
    return None, None


def transformed_bounds(gltf, mesh_index, world):
    low = np.array([np.inf] * 3)
    high = np.array([-np.inf] * 3)
    for prim in gltf["meshes"][mesh_index]["primitives"]:
        mn, mx = accessor_bounds(gltf, prim["attributes"]["POSITION"])
        if mn is None:
            continue
        for corner in range(8):
            point = np.array(
                [mn[0] if corner & 1 else mx[0], mn[1] if corner & 2 else mx[1], mn[2] if corner & 4 else mx[2], 1]
            )
            p = world @ point
            low = np.minimum(low, p[:3])
            high = np.maximum(high, p[:3])
    return low, high


def inspect(path: Path):
    gltf, _ = load_glb(path)
    tris = 0
    for mesh in gltf.get("meshes", []):
        for prim in mesh["primitives"]:
            count = gltf["accessors"][prim["indices"]]["count"] if "indices" in prim else gltf["accessors"][prim["attributes"]["POSITION"]]["count"]
            tris += count // 3
    low = np.array([np.inf] * 3)
    high = np.array([-np.inf] * 3)
    door_low = np.array([np.inf] * 3)
    door_high = np.array([-np.inf] * 3)
    nodes = []

    def walk(index, parent):
        node = gltf["nodes"][index]
        world = parent @ trs_matrix(node)
        entry = {"name": node.get("name", ""), "mesh": node.get("mesh")}
        if "mesh" in node:
            l, h = transformed_bounds(gltf, node["mesh"], world)
            if np.isfinite(l).all():
                low[:] = np.minimum(low, l)
                high[:] = np.maximum(high, h)
                if "door" in entry["name"].lower():
                    door_low[:] = np.minimum(door_low, l)
                    door_high[:] = np.maximum(door_high, h)
        nodes.append({**entry, "translation": [round(float(v), 4) for v in world[:3, 3]]})
        for child in node.get("children", []):
            walk(child, world)

    scene = gltf.get("scene", 0)
    for root in gltf["scenes"][scene].get("nodes", []):
        walk(root, np.eye(4))

    material_textures = []
    for material in gltf.get("materials", []):
        pbr = material.get("pbrMetallicRoughness", {})
        material_textures.append(
            {
                "name": material.get("name"),
                "baseColorTexture": pbr.get("baseColorTexture", {}).get("index"),
                "metallicRoughnessTexture": pbr.get("metallicRoughnessTexture", {}).get("index"),
                "normalTexture": material.get("normalTexture", {}).get("index"),
            }
        )
    has_color0 = any("COLOR_0" in p.get("attributes", {}) for m in gltf.get("meshes", []) for p in m["primitives"])
    out = {
        "file": path.name,
        "triangles": tris,
        "meshes": len(gltf.get("meshes", [])),
        "primitives": sum(len(m["primitives"]) for m in gltf.get("meshes", [])),
        "images": len(gltf.get("images", [])),
        "image_mime_types": sorted({image.get("mimeType", "") for image in gltf.get("images", [])}),
        "textures": len(gltf.get("textures", [])),
        "materials": material_textures[:20],
        "COLOR_0": has_color0,
        "extensions_used": gltf.get("extensionsUsed", []),
        "bounds_min": [round(float(v), 4) for v in low],
        "bounds_max": [round(float(v), 4) for v in high],
        "door_bounds_min": [round(float(v), 4) for v in door_low] if np.isfinite(door_low).all() else None,
        "door_bounds_max": [round(float(v), 4) for v in door_high] if np.isfinite(door_high).all() else None,
        "node_count": len(nodes),
        "door_nodes": [n for n in nodes if "door" in n["name"].lower()][:20],
    }
    return out


if __name__ == "__main__":
    for name in sys.argv[1:]:
        print(json.dumps(inspect(Path(name)), indent=2, ensure_ascii=False))
