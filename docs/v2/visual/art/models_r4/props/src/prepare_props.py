"""Download real, licensed props_r4 models; verify colour data; decimate; export GLB.

Run:  python docs/v2/visual/art/models_r4/props/src/prepare_props.py
Deps (temp-only, never committed): pip install --target <tmp> trimesh numpy pyfqmr

Every source below was page-verified. Poly Pizza GLBs ship material colours but no
COLOR_0 and no images; baking each material's baseColorFactor into COLOR_0 makes the
colour data travel through a Roblox Model import (no geometry is authored here).
Poly Haven GLBs keep their embedded 1K colour texture. No Quaternius, Creator Store,
NC/ND, Free Standard or unknown-licence source is used.
"""

from __future__ import annotations

import hashlib
import json
import os
import struct
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "raw"
EXPORT = ROOT / "export"
sys.path.insert(0, os.environ.get("PROPS_PY_LIBS", ""))
import numpy as np  # noqa: E402
import requests  # noqa: E402
import trimesh  # noqa: E402
from pyfqmr import Simplify  # noqa: E402

CC_BY_TEXT = "Creative Commons Attribution (CC BY 3.0)"
CC_BY_URL = "https://creativecommons.org/licenses/by/3.0/"
CC0_TEXT = "Our assets are all licensed as CC0, which is effectively Public Domain"
CC0_URL = "https://polyhaven.com/license"

SOURCES: dict[str, dict[str, Any]] = {
    "gerobak": {
        "source": "poly_pizza",
        "page": "https://poly.pizza/m/f_LuAcP2_Yh",
        "title": "Street Vendor Cart",
        "author": "Alan Zimmerman",
        "licence": CC_BY_TEXT,
        "licence_url": CC_BY_URL,
        "attribution": '"Street Vendor Cart" by Alan Zimmerman — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/f_LuAcP2_Yh',
        "download": "https://static.poly.pizza/116d5231-487f-438c-8fa7-e98d401737ab.glb",
        "target_faces": 2000,
    },
    "sumur": {
        "source": "poly_pizza",
        "page": "https://poly.pizza/m/1lK9mD0zDZw",
        "title": "Well",
        "author": "Jarlan Perez",
        "licence": CC_BY_TEXT,
        "licence_url": CC_BY_URL,
        "attribution": '"Well" by Jarlan Perez — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/1lK9mD0zDZw',
        "download": "https://static.poly.pizza/516aa94b-f969-4ddd-9dc2-4b414b1b22fc.glb",
        "target_faces": 2000,
    },
    "lapak": {
        "source": "poly_pizza",
        "page": "https://poly.pizza/m/bwgNq3z2SQs",
        "title": "Small stand with Wheels",
        "author": "Peter Simcoe",
        "licence": CC_BY_TEXT,
        "licence_url": CC_BY_URL,
        "attribution": '"Small stand with Wheels" by Peter Simcoe — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/bwgNq3z2SQs',
        "download": "https://static.poly.pizza/f148433a-9ffc-4e52-a3b7-1a79c89e8354.glb",
        "target_faces": 2000,
    },
    "pagar_bambu": {
        "source": "poly_pizza",
        "page": "https://poly.pizza/m/dVwByrifEmj",
        "title": "Bamboo Fence Panel",
        "author": "Jarlan Perez",
        "licence": CC_BY_TEXT,
        "licence_url": CC_BY_URL,
        "attribution": '"Bamboo Fence Panel" by Jarlan Perez — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/dVwByrifEmj',
        "download": "https://static.poly.pizza/023404b1-6974-49a8-9560-23752ee9fb7c.glb",
        "target_faces": 2000,
    },
    "alat_tani": {
        "source": "poly_haven",
        "page": "https://polyhaven.com/a/wooden_axe",
        "title": "Wooden Axe",
        "author": "Ulan Cabanilla (Poly Haven API: All)",
        "licence": CC0_TEXT,
        "licence_url": CC0_URL,
        "attribution": '"Wooden Axe" by Ulan Cabanilla — Poly Haven, CC0 1.0 (https://polyhaven.com/license), source https://polyhaven.com/a/wooden_axe',
        "asset_id": "wooden_axe",
        "target_faces": 2000,
    },
    "karung": {
        "source": "poly_haven",
        "page": "https://polyhaven.com/a/cement_bag",
        "title": "Cement Bag",
        "author": "PierreB3D (Poly Haven API: All)",
        "licence": CC0_TEXT,
        "licence_url": CC0_URL,
        "attribution": '"Cement Bag" by PierreB3D — Poly Haven, CC0 1.0 (https://polyhaven.com/license), source https://polyhaven.com/a/cement_bag',
        "asset_id": "cement_bag",
        "target_faces": 2000,
    },
    "jemuran": {
        "source": "grab3d",
        "page": "https://grab3d.com/models/props/clothesline/",
        "licence_page": "https://grab3d.com/dl/clothesline/LICENSE.txt",
        "title": "Clothesline (light, 1K PBR)",
        "author": "Grab3D (manifest extras.generator: Created by grab3d)",
        "licence": "CC0 1.0 Universal (CC0 1.0) Public Domain Dedication",
        "licence_text": "To the extent possible under law, Grab3D has waived all copyright and related or neighboring rights to the 3D models, textures and images in this package. This work is published from: Germany.",
        "licence_url": "https://creativecommons.org/publicdomain/zero/1.0/legalcode",
        "attribution": '"Clothesline" by Grab3D — CC0 1.0 Universal, no attribution required (https://creativecommons.org/publicdomain/zero/1.0/legalcode), source https://grab3d.com/models/props/clothesline/, licence text https://grab3d.com/dl/clothesline/LICENSE.txt',
        "download": "https://grab3d.com/dl/clothesline/clothesline-light.glb",
        "target_faces": 2000,
    },
}


def md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def save(url: str, path: Path) -> Path:
    if path.is_file():
        return path
    path.parent.mkdir(parents=True, exist_ok=True)
    resp = requests.get(url, timeout=120)
    resp.raise_for_status()
    path.write_bytes(resp.content)
    return path


def world_parts(path: Path) -> list[trimesh.Trimesh]:
    """Node transforms baked into each mesh; per-part material and UVs stay intact."""
    scene = trimesh.load(path, force="scene")
    parts = []
    for node in scene.graph.nodes_geometry:
        matrix, geom_name = scene.graph[node]
        part = scene.geometry[geom_name].copy()
        part.apply_transform(matrix)
        parts.append(part)
    if not parts:
        raise RuntimeError(f"no geometry in {path}")
    return parts


def base_colours(part: trimesh.Trimesh) -> np.ndarray:
    mat = part.visual.material
    mats = mat if isinstance(mat, (list, tuple)) else [mat]
    for m in mats:
        factor = getattr(m, "baseColorFactor", None)
        if factor is not None and len(factor) >= 3:
            colour = np.asarray(factor[:3], dtype=float)
            # trimesh keeps glTF factors in 0..255; glTF COLOR_0 needs 0..1.
            if colour.max() > 1.0:
                colour = colour / 255.0
            return colour
    raise RuntimeError(f"no baseColorFactor in {part.visual.material!r}")


def face_shares(parts: list[trimesh.Trimesh], target: int) -> list[int]:
    faces = [len(p.faces) for p in parts]
    total = sum(faces)
    if total <= target:
        return faces
    return [max(4, round(n * target / total)) for n in faces]


def simplify(mesh: trimesh.Trimesh, target: int) -> trimesh.Trimesh:
    if len(mesh.faces) <= target:
        return mesh
    simplifier = Simplify()
    simplifier.setMesh(np.asarray(mesh.vertices, dtype=np.float32), np.asarray(mesh.faces, dtype=np.int32))
    # preserve_border=False: several sources are open sheets (fence, laundry) and
    # pyfqmr cannot collapse an open border, which would leave the source unmerged.
    simplifier.simplify_mesh(target_count=target, preserve_border=False, verbose=False)
    vertices, faces, _normals = simplifier.getMesh()
    result = trimesh.Trimesh(vertices=vertices, faces=faces, process=False)
    return result


def nearest_uvs(simplified: trimesh.Trimesh, original: trimesh.Trimesh) -> np.ndarray:
    """Quadric collapse drops UVs: copy the nearest original vertex's UV."""
    uv = np.asarray(original.visual.uv, dtype=float)
    if uv.ndim != 2 or uv.shape[0] != len(original.vertices):
        raise RuntimeError("source mesh has no per-vertex UVs")
    src = np.asarray(original.vertices, dtype=float)
    dst = np.asarray(simplified.vertices, dtype=float)
    out = np.empty((len(dst), 2), dtype=float)
    for i, point in enumerate(dst):
        out[i] = uv[np.argmin(np.sum((src - point) ** 2, axis=1))]
    return out


def bake_vertex_colours(mesh: trimesh.Trimesh, colour: np.ndarray) -> trimesh.Trimesh:
    verts = np.asarray(mesh.vertices, dtype=float)
    rgba = np.tile(np.append(colour, 1.0), (len(verts), 1))
    mesh.visual = trimesh.visual.ColorVisuals(mesh=mesh, vertex_colors=rgba)
    return mesh


def glb_info(path: Path) -> dict[str, Any]:
    data = path.read_bytes()
    if data[:4] != b"glTF" or len(data) < 20:
        raise RuntimeError(f"not a GLB: {path}")
    jlen = struct.unpack_from("<I", data, 12)[0]
    j = json.loads(data[20:20 + jlen].decode("utf-8"))
    attrs: set[str] = set()
    for m in j.get("meshes", []):
        for p in m.get("primitives", []):
            attrs.update(p.get("attributes", {}).keys())
    return {
        "bytes": len(data),
        "images": len(j.get("images", [])),
        "textures": len(j.get("textures", [])),
        "attributes": sorted(attrs),
        "meshes": len(j.get("meshes", [])),
    }


def prepare(slot: str, spec: dict[str, Any]) -> dict[str, Any]:
    exported = EXPORT / f"{slot}.glb"
    if spec["source"] == "poly_pizza":
        raw = save(spec["download"], RAW / "poly_pizza" / f"{slot}.glb")
        parts = world_parts(raw)
        faces_before = sum(len(p.faces) for p in parts)
        targets = face_shares(parts, spec["target_faces"])
        out = []
        colours = []
        for part, target in zip(parts, targets):
            colour = base_colours(part)
            colours.append(tuple(round(float(v), 4) for v in colour))
            part = simplify(part, target)
            # Bake each real material colour after decimation (pyfqmr rebuilds vertices).
            out.append(bake_vertex_colours(part, colour))
        final = trimesh.util.concatenate(out)
        final.export(exported)
        colour_kind = "vertex_colour"
        colour_data = sorted(set(colours))
    else:
        if spec["source"] == "grab3d":
            gltf = save(spec["download"], RAW / "grab3d" / f"{slot}.glb")
        else:
            aid = spec["asset_id"]
            base = RAW / "poly_haven" / aid
            files = requests.get(f"https://api.polyhaven.com/files/{aid}", timeout=60).json()
            entry = files["gltf"]["1k"]["gltf"]
            gltf = save(entry["url"], base / f"{aid}_1k.gltf")
            for rel, item in entry["include"].items():
                save(item["url"], base / rel)
        parts = world_parts(gltf)
        faces_before = sum(len(p.faces) for p in parts)
        targets = face_shares(parts, spec["target_faces"])
        scene = trimesh.Scene()
        for part, target in zip(parts, targets):
            original = part
            part = simplify(part, target)
            if part is not original:
                uv = nearest_uvs(part, original)
                mat = original.visual.material
                mats = mat if isinstance(mat, (list, tuple)) else [mat]
                part.visual = trimesh.visual.TextureVisuals(uv=uv, material=mats[0])
            scene.add_geometry(part, node_name=f"{slot}_{len(scene.geometry)}")
        scene.export(exported)
        colour_kind = "embedded_texture"
        colour_data = None

    info = glb_info(exported)
    has_vertex = "COLOR_0" in info["attributes"]
    has_texture = info["images"] > 0 and "TEXCOORD_0" in info["attributes"]
    if not (has_vertex or has_texture):
        raise RuntimeError(f"{slot}: neither vertex colour nor embedded texture survived export: {info}")
    faces_after = sum(len(g.faces) for g in trimesh.load(exported, force="scene").geometry.values())
    return {
        "slot": slot,
        **{k: spec[k] for k in ("source", "page", "title", "author", "licence", "licence_url", "attribution")},
        "download_url": spec.get("download"),
        "licence_page": spec.get("licence_page"),
        "licence_text": spec.get("licence_text"),
        "raw_md5": md5(RAW / (spec["source"] if spec["source"] != "poly_haven" else "poly_haven") / f"{slot}.glb")
        if spec["source"] in ("poly_pizza", "grab3d") else None,
        "export_file": f"docs/v2/visual/art/models_r4/props/export/{slot}.glb",
        "export_md5": md5(exported),
        "source_faces": faces_before,
        "export_faces": faces_after,
        "colour_kind": colour_kind,
        "colour_data": colour_data,
        "glb": info,
        "verified_textured": has_vertex or has_texture,
    }


def main() -> None:
    EXPORT.mkdir(parents=True, exist_ok=True)
    report = []
    for slot, spec in SOURCES.items():
        print(f"prepare {slot} ({spec['source']})")
        report.append(prepare(slot, spec))
    (ROOT / "prepare_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
