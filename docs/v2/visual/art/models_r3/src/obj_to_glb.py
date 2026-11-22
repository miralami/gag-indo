#!/usr/bin/env python3
"""Deterministic stdlib-only OBJ -> binary glTF 2.0 converter for models_r3.

Run from anywhere:
    python docs/v2/visual/art/models_r3/src/obj_to_glb.py
    python docs/v2/visual/art/models_r3/src/obj_to_glb.py --check

Reads generated/<family>/*.obj and their MTL files; writes
export/<family>/*.glb. --check verifies existing outputs without writing.
Flat normals are computed per triangle; UVs are omitted (the OBJs have no vt).
"""

import argparse
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GENERATED = ROOT / "generated"
EXPORT = ROOT / "export"
FAMILIES = ("buildings_r3", "vegetation_r3", "props_r3", "npcs_r3")

FLOAT = 5126
UINT = 5125
ARRAY_BUFFER = 34962
ELEMENT_ARRAY_BUFFER = 34963
TRIANGLES = 4


def pad(data, fill):
    return data + fill * ((-len(data)) % 4)


def append_aligned(parts, data, offset):
    while offset % 4:
        parts.append(b"\0")
        offset += 1
    start = offset
    parts.append(data)
    return start, offset + len(data)


def parse_mtl(path):
    materials = {}
    name = None
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        head, _, rest = line.partition(" ")
        rest = rest.strip()
        if head == "newmtl":
            name = rest
        elif head == "Kd" and name:
            values = tuple(float(v) for v in rest.split()[:3])
            if len(values) != 3 or not all(math.isfinite(v) for v in values):
                raise ValueError(f"bad Kd in {path}: {line}")
            materials[name] = values
    return materials


def parse_obj(path):
    verts = []
    faces = []
    name = None
    mtllib = None
    current = None
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        head, _, rest = line.partition(" ")
        rest = rest.strip()
        if head == "mtllib":
            mtllib = rest
        elif head == "o":
            name = rest
        elif head == "v":
            values = tuple(float(v) for v in rest.split()[:3])
            if len(values) != 3 or not all(math.isfinite(v) for v in values):
                raise ValueError(f"bad vertex in {path}: {line}")
            verts.append(values)
        elif head == "usemtl":
            current = rest
        elif head == "f":
            indices = []
            for token in rest.split():
                raw_index = int(token.split("/")[0])
                index = len(verts) + raw_index + 1 if raw_index < 0 else raw_index
                if index < 1 or index > len(verts):
                    raise ValueError(f"vertex index out of range in {path}: {line}")
                indices.append(index - 1)
            if len(indices) != 3:
                raise ValueError(f"non-triangle face in {path}: {line}")
            if current is None:
                raise ValueError(f"face without usemtl in {path}: {line}")
            faces.append((indices, current))
    if not name or not mtllib:
        raise ValueError(f"missing o/mtllib in {path}")
    materials = parse_mtl(path.parent / mtllib)
    missing = sorted({mat for _, mat in faces} - materials.keys())
    if missing:
        raise ValueError(f"{path}: materials without Kd: {', '.join(missing)}")
    return name, verts, faces, materials


def face_normal(p0, p1, p2):
    u = (p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2])
    v = (p2[0] - p0[0], p2[1] - p0[1], p2[2] - p0[2])
    n = (u[1] * v[2] - u[2] * v[1],
         u[2] * v[0] - u[0] * v[2],
         u[0] * v[1] - u[1] * v[0])
    length = math.sqrt(sum(c * c for c in n))
    if not math.isfinite(length) or length == 0.0:
        return (0.0, 1.0, 0.0)
    return tuple(c / length for c in n)


def build_glb(path):
    name, verts, faces, materials = parse_obj(path)
    grouped = {}
    for indices, mat in faces:
        grouped.setdefault(mat, []).append(indices)
    mat_names = sorted(grouped)

    bin_parts = []
    views = []
    accessors = []
    primitives = []
    gltf_materials = []
    offset = 0

    for mat_index, mat_name in enumerate(mat_names):
        positions = []
        normals = []
        indices = []
        for tri in grouped[mat_name]:
            points = [verts[i] for i in tri]
            normal = face_normal(*points)
            base = len(positions) // 3
            for point in points:
                positions.extend(point)
                normals.extend(normal)
            indices.extend((base, base + 1, base + 2))

        pos_start, offset = append_aligned(
            bin_parts, struct.pack(f"<{len(positions)}f", *positions), offset)
        norm_start, offset = append_aligned(
            bin_parts, struct.pack(f"<{len(normals)}f", *normals), offset)
        idx_start, offset = append_aligned(
            bin_parts, struct.pack(f"<{len(indices)}I", *indices), offset)

        pos_view = len(views)
        views.append({"buffer": 0, "byteOffset": pos_start,
                      "byteLength": len(positions) * 4, "target": ARRAY_BUFFER})
        norm_view = len(views)
        views.append({"buffer": 0, "byteOffset": norm_start,
                      "byteLength": len(normals) * 4, "target": ARRAY_BUFFER})
        idx_view = len(views)
        views.append({"buffer": 0, "byteOffset": idx_start,
                      "byteLength": len(indices) * 4,
                      "target": ELEMENT_ARRAY_BUFFER})

        vertex_count = len(positions) // 3
        pos_acc = len(accessors)
        accessors.append({
            "bufferView": pos_view, "componentType": FLOAT, "count": vertex_count,
            "type": "VEC3",
            "min": [min(positions[i::3]) for i in range(3)],
            "max": [max(positions[i::3]) for i in range(3)],
        })
        norm_acc = len(accessors)
        accessors.append({"bufferView": norm_view, "componentType": FLOAT,
                          "count": vertex_count, "type": "VEC3"})
        idx_acc = len(accessors)
        accessors.append({"bufferView": idx_view, "componentType": UINT,
                          "count": len(indices), "type": "SCALAR",
                          "min": [0], "max": [vertex_count - 1]})

        primitives.append({
            "attributes": {"POSITION": pos_acc, "NORMAL": norm_acc},
            "indices": idx_acc, "material": mat_index, "mode": TRIANGLES,
        })
        kd = materials[mat_name]
        gltf_materials.append({
            "name": mat_name,
            "pbrMetallicRoughness": {
                "baseColorFactor": [kd[0], kd[1], kd[2], 1.0],
                "metallicFactor": 0.0,
                "roughnessFactor": 1.0,
            },
        })

    bin_data = pad(b"".join(bin_parts), b"\0")
    gltf = {
        "asset": {"version": "2.0", "generator": "obj_to_glb.py (stdlib)"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0, "name": name}],
        "meshes": [{"name": name, "primitives": primitives}],
        "materials": gltf_materials,
        "buffers": [{"byteLength": len(bin_data)}],
        "bufferViews": views,
        "accessors": accessors,
    }
    json_data = pad(json.dumps(gltf, sort_keys=True, separators=(",", ":")).encode("utf-8"), b" ")
    total = 12 + 8 + len(json_data) + 8 + len(bin_data)
    glb = (
        struct.pack("<4sII", b"glTF", 2, total)
        + struct.pack("<I4s", len(json_data), b"JSON") + json_data
        + struct.pack("<I4s", len(bin_data), b"BIN\0") + bin_data
    )
    return glb, len(faces)


def build_all():
    entries = []
    for family in FAMILIES:
        source = GENERATED / family
        for path in sorted(source.glob("*.obj")):
            rel = Path("export") / family / (path.stem + ".glb")
            if any(" " in part for part in rel.parts):
                raise ValueError(f"space in output path: {rel}")
            data, triangles = build_glb(path)
            entries.append((rel, data, triangles))
    if len(entries) != 16:
        raise ValueError(f"expected 16 OBJs, found {len(entries)}")
    return entries


def check_glb(data, expected_triangles, rel):
    if len(data) < 20:
        raise ValueError(f"{rel}: too short")
    magic, version, total = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or total != len(data):
        raise ValueError(f"{rel}: bad GLB header")

    pos = 12
    chunks = []
    while pos < total:
        length, kind = struct.unpack_from("<I4s", data, pos)
        pos += 8
        if length % 4 or pos + length > total:
            raise ValueError(f"{rel}: bad chunk length")
        chunks.append((kind, data[pos:pos + length]))
        pos += length
    if pos != total or [kind for kind, _ in chunks] != [b"JSON", b"BIN\0"]:
        raise ValueError(f"{rel}: expected exactly JSON then BIN chunks")

    gltf = json.loads(chunks[0][1].decode("utf-8"))
    binary = chunks[1][1]
    if gltf["asset"]["version"] != "2.0":
        raise ValueError(f"{rel}: not glTF 2.0")
    if len(gltf["buffers"]) != 1 or gltf["buffers"][0]["byteLength"] != len(binary):
        raise ValueError(f"{rel}: BIN length mismatch")
    if gltf["scene"] != 0 or gltf["scenes"][0]["nodes"] != [0] or gltf["nodes"][0]["mesh"] != 0:
        raise ValueError(f"{rel}: bad scene/node")

    triangles = 0
    primitives = gltf["meshes"][0]["primitives"]
    for prim in primitives:
        if prim["mode"] != TRIANGLES or "material" not in prim:
            raise ValueError(f"{rel}: bad primitive")
        color = gltf["materials"][prim["material"]]["pbrMetallicRoughness"]["baseColorFactor"]
        if len(color) != 4 or color[3] != 1.0:
            raise ValueError(f"{rel}: bad baseColorFactor")
        idx_acc = gltf["accessors"][prim["indices"]]
        pos_acc = gltf["accessors"][prim["attributes"]["POSITION"]]
        norm_acc = gltf["accessors"][prim["attributes"]["NORMAL"]]
        if idx_acc["componentType"] != UINT or idx_acc["type"] != "SCALAR" or idx_acc["count"] % 3:
            raise ValueError(f"{rel}: bad indices accessor")
        if pos_acc["componentType"] != FLOAT or pos_acc["type"] != "VEC3":
            raise ValueError(f"{rel}: bad position accessor")
        if norm_acc["componentType"] != FLOAT or norm_acc["type"] != "VEC3":
            raise ValueError(f"{rel}: bad normal accessor")
        if norm_acc["count"] != pos_acc["count"] or len(pos_acc["min"]) != 3 or len(pos_acc["max"]) != 3:
            raise ValueError(f"{rel}: bad accessor bounds")
        if idx_acc["min"] != [0] or idx_acc["max"] != [pos_acc["count"] - 1]:
            raise ValueError(f"{rel}: index bounds mismatch")
        expected_sizes = (
            (pos_acc["bufferView"], pos_acc["count"] * 12),
            (norm_acc["bufferView"], norm_acc["count"] * 12),
            (idx_acc["bufferView"], idx_acc["count"] * 4),
        )
        for view_index, size in expected_sizes:
            view = gltf["bufferViews"][view_index]
            if view["buffer"] != 0 or view["byteOffset"] % 4 or view["byteLength"] != size:
                raise ValueError(f"{rel}: bad bufferView")
            if view["byteOffset"] + view["byteLength"] > len(binary):
                raise ValueError(f"{rel}: bufferView outside BIN")
        triangles += idx_acc["count"] // 3
    if triangles != expected_triangles:
        raise ValueError(f"{rel}: {triangles} triangles, expected {expected_triangles}")
    for part in rel.parts:
        if " " in part:
            raise ValueError(f"{rel}: space in filename")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true",
                        help="verify existing GLBs without writing")
    args = parser.parse_args()

    first = build_all()
    second = build_all()
    for (rel_a, data_a, tris_a), (rel_b, data_b, tris_b) in zip(first, second):
        if (rel_a, tris_a) != (rel_b, tris_b) or data_a != data_b:
            raise ValueError(f"nondeterministic output: {rel_a}")

    total_tris = 0
    for rel, data, triangles in first:
        check_glb(data, triangles, rel)
        target = ROOT / rel
        if args.check:
            if not target.is_file():
                raise FileNotFoundError(target)
            if target.read_bytes() != data:
                raise ValueError(f"on-disk bytes differ: {rel}")
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            if target.read_bytes() != data:
                raise ValueError(f"write mismatch: {rel}")
        total_tris += triangles
        print(f"{rel.as_posix()}  {triangles} tris  {len(data)} bytes")
    mode = "checked" if args.check else "written"
    print(f"VERIFIED 16 GLB files ({mode}, {total_tris} tris, two identical builds, no spaces)")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        raise SystemExit(f"ERROR: {exc}") from exc
