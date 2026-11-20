#!/usr/bin/env python3
"""Verify the 18 r4 faces and record deterministic hashes.

Run after make_cube_faces.py. Re-runs the generator in-process and asserts
every PNG is byte-identical, so the pipeline is reproducible.
"""

from __future__ import annotations

import hashlib
import json
import pathlib

import numpy as np
from PIL import Image

import make_cube_faces as gen

FACES = gen.FACES_DIR
ORDER = ["SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"]


def snapshot() -> dict[str, bytes]:
    return {f"{key}/{name}": (FACES / key / f"{name}.png").read_bytes() for key in gen.SOURCES for name in ORDER}


def describe(key: str, name: str, raw: bytes) -> dict[str, object]:
    path = FACES / key / f"{name}.png"
    with Image.open(path) as img:
        img.verify()
    with Image.open(path) as img:
        assert img.mode == "RGB" and img.size == (1024, 1024)
        std = float(np.asarray(img, dtype=np.float64).std())
    assert std > 0
    return {
        "face": name,
        "file": f"docs/v2/visual/art/sky_r4/faces/{key}/{name}.png",
        "md5": hashlib.md5(raw).hexdigest(),
        "sha256": hashlib.sha256(raw).hexdigest(),
        "bytes": len(raw),
        "std": round(std, 3),
    }


def main() -> None:
    first = snapshot()
    gen.main()  # deterministic re-run
    second = snapshot()
    assert first == second, "generator is not deterministic"
    rows = [describe(key, name, second[f"{key}/{name}"]) for key in gen.SOURCES for name in ORDER]
    manifest = {"deterministic": True, "face_size": 1024, "count": len(rows), "faces": rows}
    (FACES / "faces_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print("verified", len(rows), "faces; byte-identical on re-run; min std", min(r["std"] for r in rows))
    print("wrote", FACES / "faces_manifest.json")


if __name__ == "__main__":
    main()
