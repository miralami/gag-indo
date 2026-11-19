#!/usr/bin/env python3
"""Deterministic equirectangular HDRI -> six Roblox Sky cube faces.

Source: Poly Haven `fish_hoek_beach` 2k HDR (CC0). See ../MANIFEST.md.

Dependencies: Python stdlib + numpy + Pillow only.

Run from anywhere:
    python docs/v2/visual/art/sky_r3/src/make_cube_faces.py

Output (1024x1024 RGB PNG each):
    docs/v2/visual/art/sky_r3/faces/SkyboxImage{Back,Bottom,Front,Left,Right,Top}.png
"""

from __future__ import annotations

import pathlib

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source" / "fish_hoek_beach_2k.hdr"
FACES_DIR = ROOT / "faces"

FACE_SIZE = 1024
EXPOSURE = 1.0
GAMMA = 2.2

# name: (normal, image-right, image-up), Roblox handedness: front = -Z.
FACE_BASIS: dict[str, tuple[tuple[float, float, float], ...]] = {
    "SkyboxImageFront": ((0.0, 0.0, -1.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0)),
    "SkyboxImageBack": ((0.0, 0.0, 1.0), (-1.0, 0.0, 0.0), (0.0, 1.0, 0.0)),
    "SkyboxImageRight": ((1.0, 0.0, 0.0), (0.0, 0.0, 1.0), (0.0, 1.0, 0.0)),
    "SkyboxImageLeft": ((-1.0, 0.0, 0.0), (0.0, 0.0, 1.0), (0.0, 1.0, 0.0)),
    "SkyboxImageTop": ((0.0, 1.0, 0.0), (1.0, 0.0, 0.0), (0.0, 0.0, 1.0)),
    "SkyboxImageBottom": ((0.0, -1.0, 0.0), (1.0, 0.0, 0.0), (0.0, 0.0, -1.0)),
}


def read_rgbe(path: pathlib.Path) -> np.ndarray:
    """Decode a Radiance RGBE .hdr file to float32 RGB, shape (height, width, 3)."""
    with path.open("rb") as fh:
        line = fh.readline()
        if not line.startswith((b"#?RADIANCE", b"#?RGBE")):
            raise ValueError(f"not a Radiance HDR file: {path}")
        header_lines = []
        while True:
            line = fh.readline()
            if not line or line in (b"\n", b"\r\n"):
                break
            header_lines.append(line.strip())
        if b"FORMAT=32-bit_rle_rgbe" not in header_lines:
            raise ValueError("expected FORMAT=32-bit_rle_rgbe")
        resolution = fh.readline().split()
        if len(resolution) != 4 or resolution[0] != b"-Y" or resolution[2] != b"+X":
            raise ValueError(f"unsupported HDR orientation: {resolution!r}")
        height, width = int(resolution[1]), int(resolution[3])

        if width < 8 or width > 0x7FFF:
            raw = np.frombuffer(fh.read(height * width * 4), dtype=np.uint8)
            channels = raw.reshape(height, width, 4)
        else:
            channels = np.empty((height, 4, width), dtype=np.uint8)
            for y in range(height):
                marker = fh.read(4)
                if len(marker) != 4 or marker[0] != 2 or marker[1] != 2:
                    raise ValueError(f"bad RLE scanline header at row {y}")
                if (marker[2] << 8) | marker[3] != width:
                    raise ValueError(f"bad RLE scanline width at row {y}")
                for c in range(4):
                    row = channels[y, c]
                    pos = 0
                    while pos < width:
                        code = fh.read(1)[0]
                        if code > 128:
                            run, value = code - 128, fh.read(1)[0]
                            if pos + run > width:
                                raise ValueError(f"RLE run overflow at row {y}")
                            row[pos:pos + run] = value
                            pos += run
                        else:
                            literal = fh.read(code)
                            if len(literal) != code or pos + code > width:
                                raise ValueError(f"RLE literal overflow at row {y}")
                            row[pos:pos + code] = np.frombuffer(literal, dtype=np.uint8)
                            pos += code

    rgbe = channels if width < 8 or width > 0x7FFF else channels.transpose(0, 2, 1)
    exponent = rgbe[..., 3].astype(np.int32) - 136
    rgb = rgbe[..., :3].astype(np.float32) + np.float32(0.5)
    hdr = np.ldexp(rgb, exponent[..., None]).astype(np.float32)
    hdr[rgbe[..., 3] == 0] = np.float32(0.0)
    return hdr


def direction_grid(size: int, normal, right, up) -> np.ndarray:
    """World-space ray directions for one face, shape (size, size, 3)."""
    axis = (np.arange(size, dtype=np.float64) + 0.5) * (2.0 / size) - 1.0
    sx, sy = np.meshgrid(axis, axis[::-1])  # sy=+1 at top row, -1 at bottom row
    n = np.asarray(normal, dtype=np.float64)
    d = n + sx[..., None] * np.asarray(right, dtype=np.float64) + sy[..., None] * np.asarray(up, dtype=np.float64)
    return d / np.linalg.norm(d, axis=-1, keepdims=True)


def sample_equirect(hdr: np.ndarray, directions: np.ndarray) -> np.ndarray:
    """Bilinear HDR sample; longitude wraps, latitude clamps. Output float32 RGB."""
    height, width, _ = hdr.shape
    x = directions[..., 0]
    y = directions[..., 1]
    z = directions[..., 2]
    lon = np.arctan2(x, -z)  # 0 = -Z (front), +pi/2 = +X (right)
    lat = np.arcsin(np.clip(y, -1.0, 1.0))
    u = np.mod(0.5 + lon / (2.0 * np.pi), 1.0)
    v = 0.5 - lat / np.pi  # 0 = zenith row, 1 = nadir row

    fx = u * width - 0.5
    fy = v * height - 0.5
    ix = np.floor(fx).astype(np.int64)
    iy = np.floor(fy).astype(np.int64)
    tx = (fx - ix).astype(np.float32)
    ty = np.clip(fy - iy, 0.0, 1.0).astype(np.float32)
    x0 = np.mod(ix, width)
    x1 = (x0 + 1) % width
    y0 = np.clip(iy, 0, height - 1)
    y1 = np.clip(iy + 1, 0, height - 1)

    top = hdr[y0, x0] * (1.0 - tx[..., None]) + hdr[y0, x1] * tx[..., None]
    bottom = hdr[y1, x0] * (1.0 - tx[..., None]) + hdr[y1, x1] * tx[..., None]
    return (top * (1.0 - ty[..., None]) + bottom * ty[..., None]).astype(np.float32)


def tone_map(rgb: np.ndarray) -> np.ndarray:
    """out = round(255 * (clamp(rgb * 1.0, 0, inf) / (1 + ...)) ** (1 / 2.2))."""
    value = np.clip(rgb * np.float32(EXPOSURE), 0.0, None)
    mapped = value / (1.0 + value)
    return np.rint(np.clip(mapped, 0.0, 1.0) ** (1.0 / GAMMA) * 255.0).astype(np.uint8)


def main() -> None:
    hdr = read_rgbe(SOURCE)
    FACES_DIR.mkdir(parents=True, exist_ok=True)
    for name, (normal, right, up) in FACE_BASIS.items():
        directions = direction_grid(FACE_SIZE, normal, right, up)
        pixels = tone_map(sample_equirect(hdr, directions))
        out = FACES_DIR / f"{name}.png"
        Image.fromarray(pixels, mode="RGB").save(out, format="PNG", compress_level=9, optimize=False)
        print(f"{out.relative_to(ROOT)} std={pixels.astype(np.float64).std():.3f}")


if __name__ == "__main__":
    main()
