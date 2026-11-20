"""Bake the source's flat PBR material colours into COLOR_0 vertex colours.

The 'Pleasant peasant' source has 16 authored baseColorFactor colours but no
image texture. The conversion keeps every source triangle and adds vertex
colours, so the exported model is genuinely vertex-coloured and not a grey
placeholder. No geometry is generated.
"""

import json
import pathlib
import struct

from decimate_glb import read_glb, write_glb

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "raw" / "npcs_r4" / "petani_caping.glb"
TARGET = ROOT / "export" / "npcs_r4" / "petani_caping.glb"


def main():
    gltf, binary = read_glb(SOURCE)
    binary = bytearray(binary)
    count = 0
    for mesh in gltf.get("meshes", []):
        for prim in mesh.get("primitives", []):
            material = gltf["materials"][prim["material"]]
            colour = material["pbrMetallicRoughness"]["baseColorFactor"]
            position = gltf["accessors"][prim["attributes"]["POSITION"]]["count"]
            payload = struct.pack("<" + "f" * 4 * position, *(colour * position))
            offset = len(binary)
            binary.extend(payload)
            while len(binary) % 4:
                binary.append(0)
            gltf["bufferViews"].append({"buffer": 0, "byteOffset": offset, "byteLength": len(payload)})
            gltf["accessors"].append(
                {
                    "bufferView": len(gltf["bufferViews"]) - 1,
                    "componentType": 5126,
                    "count": position,
                    "type": "VEC4",
                }
            )
            prim["attributes"]["COLOR_0"] = len(gltf["accessors"]) - 1
            count += 1
    gltf["asset"] = {
        "version": "2.0",
        "generator": "npcs_r4 material-to-vertex-colour bake (stdlib)",
    }
    write_glb(gltf, bytes(binary), TARGET)
    print(f"baked {count} primitives into COLOR_0: {TARGET}")


if __name__ == "__main__":
    main()
