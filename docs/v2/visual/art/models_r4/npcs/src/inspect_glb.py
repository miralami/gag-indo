"""Inspect downloaded GLBs: real textures / vertex colours, triangles, bounds, rigs."""

import json
import pathlib
import struct
import sys

RAW = pathlib.Path(__file__).resolve().parent.parent / "raw" / "npcs_r4"


def load(path):
    data = path.read_bytes()
    magic, version, total = struct.unpack_from("<4sII", data, 0)
    assert magic == b"glTF" and version == 2 and total == len(data), path
    offset = 12
    chunks = {}
    while offset < total:
        length, kind = struct.unpack_from("<I4s", data, offset)
        offset += 8
        chunks[kind] = data[offset : offset + length]
        offset += length
    return json.loads(chunks[b"JSON"]), len(chunks.get(b"BIN\0", b""))


def describe(path):
    gltf, bin_len = load(path)
    prims = []
    for mesh in gltf.get("meshes", []):
        for prim in mesh.get("primitives", []):
            attrs = sorted(prim.get("attributes", {}))
            indices = gltf["accessors"][prim["indices"]]["count"] if "indices" in prim else 0
            prims.append({"attrs": attrs, "tris": indices // 3, "material": prim.get("material")})
    materials = []
    for material in gltf.get("materials", []):
        pbr = material.get("pbrMetallicRoughness", {})
        materials.append(
            {
                "name": material.get("name"),
                "baseColorTexture": "baseColorTexture" in pbr,
                "otherTexture": any(k.endswith("Texture") for k in pbr),
                "baseColorFactor": pbr.get("baseColorFactor"),
            }
        )
    positions = [
        (gltf["accessors"][prim["attributes"]["POSITION"]].get("min"), gltf["accessors"][prim["attributes"]["POSITION"]].get("max"))
        for mesh in gltf.get("meshes", [])
        for prim in mesh["primitives"]
        if "POSITION" in prim.get("attributes", {})
    ]
    mins = [min(v[0][axis] for v in positions if v[0]) for axis in range(3)] if positions else []
    maxs = [max(v[1][axis] for v in positions if v[1]) for axis in range(3)] if positions else []
    return {
        "file": path.name,
        "triangles": sum(p["tris"] for p in prims),
        "primitives": len(prims),
        "vertexColor": any("COLOR_0" in p["attrs"] for p in prims),
        "uv": any("TEXCOORD_0" in p["attrs"] for p in prims),
        "textures": len(gltf.get("textures", [])),
        "images": len(gltf.get("images", [])),
        "materials": materials,
        "bounds": {"min": mins, "max": maxs, "size": [maxs[i] - mins[i] for i in range(3)] if mins else []},
        "skins": len(gltf.get("skins", [])),
        "animations": len(gltf.get("animations", [])),
        "nodes": len(gltf.get("nodes", [])),
        "binBytes": bin_len,
    }


for name in sys.argv[1:] or [p.name for p in sorted(RAW.glob("*.glb"))]:
    print(json.dumps(describe(RAW / name), ensure_ascii=False))
