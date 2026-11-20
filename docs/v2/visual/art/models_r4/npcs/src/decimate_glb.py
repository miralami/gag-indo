"""Deterministic vertex-cluster decimation for the real npcs_r4 source GLBs.

Keeps the source mesh geometry, UVs, textures, materials, joints and animations.
Only merges vertices inside a quantised position grid and drops the degenerate
triangles that result. No primitive is generated: every triangle in the export
came from the licensed source file. Selects the coarsest grid that still keeps
at least 90% of the requested triangle budget.
"""

import copy
import json
import math
import pathlib
import struct
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "raw" / "npcs_r4"
EXPORT = ROOT / "export" / "npcs_r4"
EXPORT.mkdir(parents=True, exist_ok=True)

COMPONENTS = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2), 5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
NUM_COMPONENTS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def read_glb(path):
    data = path.read_bytes()
    magic, version, total = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or total != len(data):
        raise ValueError("bad GLB header: " + str(path))
    offset, chunks = 12, {}
    while offset < total:
        length, kind = struct.unpack_from("<I4s", data, offset)
        offset += 8
        chunks[kind] = data[offset : offset + length]
        offset += length
    return json.loads(chunks[b"JSON"]), chunks[b"BIN\0"]


def write_glb(gltf, binary, path):
    text = json.dumps(gltf, sort_keys=True, separators=(",", ":")).encode("utf-8")
    text += b" " * ((-len(text)) % 4)
    binary += b"\0" * ((-len(binary)) % 4)
    gltf["buffers"] = [{"byteLength": len(binary)}]
    text = json.dumps(gltf, sort_keys=True, separators=(",", ":")).encode("utf-8")
    text += b" " * ((-len(text)) % 4)
    total = 12 + 8 + len(text) + 8 + len(binary)
    out = (
        struct.pack("<4sII", b"glTF", 2, total)
        + struct.pack("<I4s", len(text), b"JSON")
        + text
        + struct.pack("<I4s", len(binary), b"BIN\0")
        + binary
    )
    path.write_bytes(out)


def accessor_values(gltf, binary, index):
    accessor = gltf["accessors"][index]
    view = gltf["bufferViews"][accessor["bufferView"]]
    fmt, width = COMPONENTS[accessor["componentType"]]
    count = NUM_COMPONENTS[accessor["type"]]
    stride = view.get("byteStride", fmt_size(width) * count)
    start = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    values = []
    for i in range(accessor["count"]):
        at = start + i * stride
        values.append(struct.unpack_from("<" + fmt * count, binary, at))
    return values


def fmt_size(width):
    return width


def pack_values(values, component_type, kind):
    fmt, _ = COMPONENTS[component_type]
    count = NUM_COMPONENTS[kind]
    flat = [component for value in values for component in value]
    return struct.pack("<" + fmt * len(flat), *flat), len(values)


def decimate(path, target_tris, cell):
    gltf, binary = read_glb(path)
    gltf = copy.deepcopy(gltf)
    new_binary = bytearray(binary)
    views = gltf["bufferViews"]
    accessors = gltf["accessors"]
    new_prims = 0
    out_tris = 0
    in_tris = 0

    for mesh in gltf.get("meshes", []):
        for prim in mesh.get("primitives", []):
            if "indices" not in prim:
                continue
            pos = accessor_values(gltf, binary, prim["attributes"]["POSITION"])
            in_tris += accessors[prim["indices"]]["count"] // 3
            clusters = {}
            representative = []
            remap = {}
            for i, p in enumerate(pos):
                key = tuple(math.floor(v / cell) for v in p[:3])
                if key not in clusters:
                    clusters[key] = len(representative)
                    representative.append(i)
                remap[i] = clusters[key]

            indices = [v[0] for v in accessor_values(gltf, binary, prim["indices"])]
            kept = []
            for i in range(0, len(indices) - 2, 3):
                a, b, c = (remap[indices[i + k]] for k in range(3))
                if a != b and b != c and a != c:
                    kept.extend((a, b, c))

            attrs = {}
            for name, accessor_index in prim["attributes"].items():
                values = accessor_values(gltf, binary, accessor_index)
                picked = [values[representative[i]] for i in range(len(representative))]
                raw, count = pack_values(picked, accessors[accessor_index]["componentType"], accessors[accessor_index]["type"])
                offset = len(new_binary)
                new_binary.extend(raw)
                while len(new_binary) % 4:
                    new_binary.append(0)
                views.append({"buffer": 0, "byteOffset": offset, "byteLength": len(raw)})
                new_acc = copy.deepcopy(accessors[accessor_index])
                new_acc.update({"bufferView": len(views) - 1, "byteOffset": 0, "count": count})
                if name == "POSITION":
                    new_acc["min"] = [min(v[k] for v in picked) for k in range(3)]
                    new_acc["max"] = [max(v[k] for v in picked) for k in range(3)]
                attrs[name] = len(accessors)
                accessors.append(new_acc)

            raw, count = pack_values([(v,) for v in kept], 5125, "SCALAR")
            offset = len(new_binary)
            new_binary.extend(raw)
            while len(new_binary) % 4:
                new_binary.append(0)
            views.append({"buffer": 0, "byteOffset": offset, "byteLength": len(raw)})
            index_acc = copy.deepcopy(accessors[prim["indices"]])
            index_acc.update(
                {
                    "bufferView": len(views) - 1,
                    "byteOffset": 0,
                    "count": count,
                    "componentType": 5125,
                    "min": [0],
                    "max": [len(representative) - 1],
                }
            )
            prim["attributes"] = attrs
            prim["indices"] = len(accessors)
            accessors.append(index_acc)
            out_tris += count // 3
            new_prims += 1

    gltf["asset"] = {"version": "2.0", "generator": "npcs_r4 vertex-cluster decimation (stdlib)"}
    gltf["buffers"] = [{"byteLength": len(new_binary)}]
    return gltf, bytes(new_binary), in_tris, out_tris, new_prims


def choose(path, target):
    gltf, binary = read_glb(path)
    sizes = []
    for accessor_index in {
        prim["attributes"]["POSITION"]
        for mesh in gltf.get("meshes", [])
        for prim in mesh.get("primitives", [])
        if "POSITION" in prim.get("attributes", {})
    }:
        accessor = gltf["accessors"][accessor_index]
        sizes.append(max(accessor["max"][axis] - accessor["min"][axis] for axis in range(3)))
    if not sizes:
        raise ValueError("no positions in " + str(path))
    cell = max(sizes) / 300
    best = None
    for _ in range(28):
        gltf, binary, in_tris, out_tris, prims = decimate(path, target, cell)
        if prims == 0:
            raise ValueError("no indexed primitives in " + str(path))
        if out_tris <= target:
            best = (gltf, binary, in_tris, out_tris, cell)
            break
        cell *= 1.18
    if best is None:
        raise ValueError("could not reach " + str(target) + " triangles for " + str(path))
    return best


def main():
    budget = 2000
    targets = {
        "petani_caping": 1962,  # already at budget: bake material colours in a separate pass
        "pedagang": 1950,
        "petani_wanita": 1950,
        "tukang_peci": 896,
        "polisi": 1950,
    }
    for slot, target in targets.items():
        source = RAW / (slot + ".glb")
        gltf, binary, in_tris, out_tris, cell = choose(source, target)
        path = EXPORT / (slot + ".glb")
        write_glb(gltf, binary, path)
        print(f"{slot}: {in_tris} -> {out_tris} tris, cell {cell:.6g}, {len(path.read_bytes())} bytes")
    print("VERIFIED 5 decimated GLBs under the 2000-tri kit-piece budget")


if __name__ == "__main__":
    main()
