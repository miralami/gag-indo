"""Verify the five exported GLBs: real colour source, budget, integrity, up-axis."""

import json
import pathlib

import numpy as np

from decimate_glb import read_glb

ROOT = pathlib.Path(__file__).resolve().parent.parent
EXPORT = ROOT / "export" / "npcs_r4"
SLOTS = ("petani_caping", "pedagang", "petani_wanita", "tukang_peci", "polisi")


def trs_matrix(node):
    if "matrix" in node:
        return np.array(node["matrix"], dtype=float).reshape(4, 4).T
    translation = np.array(node.get("translation", [0, 0, 0]), dtype=float)
    rotation = np.array(node.get("rotation", [0, 0, 0, 1]), dtype=float)
    scale = np.array(node.get("scale", [1, 1, 1]), dtype=float)
    x, y, z, w = rotation
    r = np.array(
        [
            [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
            [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
            [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
        ]
    )
    matrix = np.eye(4)
    matrix[:3, :3] = r @ np.diag(scale)
    matrix[:3, 3] = translation
    return matrix


def world_bounds(gltf):
    nodes = gltf.get("nodes", [])
    children = {i: node.get("children", []) for i, node in enumerate(nodes)}
    roots = set(range(len(nodes))) - {child for kids in children.values() for child in kids}
    world = {}

    def walk(index, parent):
        matrix = parent @ trs_matrix(nodes[index])
        world[index] = matrix
        for child in children[index]:
            walk(child, matrix)

    for root in sorted(roots):
        walk(root, np.eye(4))

    lows, highs = [], []
    for index, node in enumerate(nodes):
        if "mesh" not in node or index not in world:
            continue
        for prim in gltf["meshes"][node["mesh"]].get("primitives", []):
            accessor = gltf["accessors"][prim["attributes"]["POSITION"]]
            low, high = np.array(accessor["min"]), np.array(accessor["max"])
            for corner_x in (low[0], high[0]):
                for corner_y in (low[1], high[1]):
                    for corner_z in (low[2], high[2]):
                        point = world[index] @ np.array([corner_x, corner_y, corner_z, 1.0])
                        lows.append(point[:3])
                        highs.append(point[:3])
    if not lows:
        return None
    low, high = np.min(lows, axis=0), np.max(highs, axis=0)
    return low.tolist(), high.tolist(), (high - low).tolist()


for slot in SLOTS:
    path = EXPORT / (slot + ".glb")
    gltf, binary = read_glb(path)
    prims = [prim for mesh in gltf.get("meshes", []) for prim in mesh.get("primitives", [])]
    tris = sum(gltf["accessors"][prim["indices"]]["count"] // 3 for prim in prims if "indices" in prim)
    textured = bool(gltf.get("images")) or any("COLOR_0" in prim["attributes"] for prim in prims)
    for view in gltf["bufferViews"]:
        assert view["byteOffset"] + view["byteLength"] <= len(binary), slot
    assert tris <= 2000, (slot, tris)
    assert textured, slot
    bounds = world_bounds(gltf)
    print(
        json.dumps(
            {
                "slot": slot,
                "tris": tris,
                "textured": textured,
                "images": len(gltf.get("images", [])),
                "vertexColor": any("COLOR_0" in prim["attributes"] for prim in prims),
                "skins": len(gltf.get("skins", [])),
                "animations": len(gltf.get("animations", [])),
                "worldSize": [round(v, 5) for v in bounds[2]] if bounds else None,
                "flatZUp": bool(bounds and bounds[2][1] < max(bounds[2][0], bounds[2][2]) * 0.6),
            }
        )
    )
print("VERIFIED 5 exported GLBs: textured, <=2000 tris, valid buffer views")
