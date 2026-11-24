"""Build `rumah_pakrt`, the village head's house, for Juragan Desa in Blender.

Run from the repository root:

    blender --background --factory-startup --python assets/rumah_pakrt/build_rumah_pakrt.py

Writes, next to this script:
    rumah_pakrt.blend          editable source (textures linked, not packed)
    rumah_pakrt.fbx            Roblox import file (textures embedded)
    textures/*.png             generated textures (own work, no third-party source)

Concept: the GPT illustration approved by @miralami on 2026-11-24, a modest two-storey kampung
house that a slightly corrupt Pak RT has upgraded: gold-capped columns, glossy tiled terrace, worn
sofa, envelope on the table, gold-tipped fence with the gate open, red-plate government MPV with
aid-project cement sacks, satellite dish, CCTV, flag, and a humble lesehan hangout for villagers.

Scale (src/server/World/MapSpec.luau): this house is the village scale reference. Lot 48 x 34,
ridge 32.6, door 7 x 10.5, avatar 7.25 studs. 1 Blender unit = 1 stud, ground z = 0, lot centred
on the origin, front (street) facing Blender +Y = Roblox -Z after export.

Gameplay: `RumahPakRT_Meja` is the terrace table at the size of MapSpec's pakrt anchor (5 x 2.4 x
3) for the BribePrompt. Player text is never baked into textures (Strings.luau rule).
"""

import math
import os
import re

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
TEX_DIR = os.path.join(HERE, "textures")
NAME = "RumahPakRT"
VISUALS = os.path.join(HERE, "..", "..", "src", "shared", "Config", "Visuals.luau")


def load_palette():
    """Read the project palette (ART.md §3) from Visuals.luau."""
    with open(VISUALS, encoding="utf-8") as fh:
        text = fh.read()
    start = text.index("Visuals.palette = {")
    block = text[start : text.index("}", start)]
    return {
        key: np.array([int(hexv[i : i + 2], 16) / 255.0 for i in (0, 2, 4)])
        for key, hexv in re.findall(r"(\w+)\s*=\s*\"([0-9a-fA-F]{6})\"", block)
    }


P = load_palette()

# ---------------------------------------------------------------------------------------------
# Dimensions (studs). Avatar 7.25, door 7 x 10.5 (MapSpec).
# ---------------------------------------------------------------------------------------------
# Lot 56 x 50 (Willy, 2026-11-24: "halaman rumahnya diperluas" to match the concept's deep front
# yard). The house keeps its MapSpec size; only the yard grows, mostly toward the street.
LOT_X = 31.1  # half width; pillar caps reach 32 (lot widened with the house, 2026-11-24)
LOT_Y0, LOT_Y1 = -18.0, 32.0  # back and street edges before the lot is centred on the origin
T = 0.8  # wall thickness (Greybox WALL)
FLOOR = 1.5  # house floor and terrace top
HX, HY0, HY1 = 15.0, -15.0, 1.0  # ground floor (30 wide; Willy: "kurang lebar"): x half width, back and front wall faces
TERRACE_Y = 7.5  # terrace front edge
EAVE_LO = 14.5  # lower (skirt) roof eave
INNER_Z = 18.0  # where the skirt roof meets the upper storey
UX, UY0, UY1 = 11.0, -11.0, -1.0  # upper storey (22 wide): x half width, back and front wall faces
UP_TOP = 27.4
EAVE_HI, RIDGE = 26.5, 32.6
DOOR_X, DOOR_W, DOOR_H = -1.5, 7.0, 10.5
FENCE_Y = LOT_Y1 - 0.4

BMS = {}


def bm_for(mat):
    if mat not in BMS:
        bm = bmesh.new()
        bm.loops.layers.uv.verify()
        bm.faces.layers.int.new("fixed")
        BMS[mat] = bm
    return BMS[mat]


def _faces(res):
    faces = set()
    for v in res["verts"]:
        faces.update(v.link_faces)
    return list(faces)


def box(mat, x0, x1, y0, y1, z0, z1):
    c = Vector(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    s = (abs(x1 - x0), abs(y1 - y0), abs(z1 - z0))
    return _faces(bmesh.ops.create_cube(bm_for(mat), size=1.0, matrix=Matrix.Translation(c) @ Matrix.Diagonal((*s, 1.0))))


def obox(mat, centre, size, yaw=0.0):
    m = Matrix.Translation(Vector(centre)) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Diagonal((*size, 1.0))
    return _faces(bmesh.ops.create_cube(bm_for(mat), size=1.0, matrix=m))


def beam(mat, p0, p1, w, h):
    p0, p1 = Vector(p0), Vector(p1)
    d = p1 - p0
    x = d / d.length
    ref = Vector((0, 0, 1)) if abs(x.z) < 0.99 else Vector((0, 1, 0))
    y = ref.cross(x).normalized()
    z = x.cross(y)
    rot = Matrix((x, y, z)).transposed().to_4x4()
    m = Matrix.Translation((p0 + p1) / 2) @ rot @ Matrix.Diagonal((d.length, w, h, 1.0))
    return _faces(bmesh.ops.create_cube(bm_for(mat), size=1.0, matrix=m))


def cylinder(mat, centre, radius, depth, segments=12, r_top=None, rot=None):
    m = Matrix.Translation(Vector(centre)) @ (rot if rot is not None else Matrix.Identity(4))
    res = bmesh.ops.create_cone(
        bm_for(mat),
        cap_ends=True,
        cap_tris=False,
        segments=segments,
        radius1=radius,
        radius2=radius if r_top is None else r_top,
        depth=depth,
        matrix=m,
    )
    return _faces(res)


def sphere(mat, centre, radius, segs=(10, 6)):
    res = bmesh.ops.create_uvsphere(bm_for(mat), u_segments=segs[0], v_segments=segs[1], radius=radius, matrix=Matrix.Translation(Vector(centre)))
    return _faces(res)


# Palette swatch atlas for small props, the car and the flag (UVs set at creation).
SWATCHES = [
    "kertas", "tinta", "tinta_lembut", "senja",
    "padi", "daun", "genteng", "merah",
    "bambu", "kunyit", "indigo", "malam",
    "ungu", "kaca", "perak", "badan",
]  # fmt: skip


def swatch_rgb(token):
    derived = {
        "kaca": mix(P["tinta"], P["indigo"], 0.5),  # car glass
        "perak": mix(P["kertas"], P["indigo"], 0.3),  # chrome, aluminium, dish
        "badan": mix(P["tinta"], P["indigo"], 0.25),  # dark grey car paint
    }
    return derived.get(token, P.get(token))


def swatch_uv(token):
    i = SWATCHES.index(token)
    return ((i % 4 + 0.5) / 4, 1 - (i // 4 + 0.5) / 4)


def paint(token, faces, obj="Warna"):
    bm = bm_for(obj)
    uvl = bm.loops.layers.uv.active
    fixed = bm.faces.layers.int["fixed"]
    uv = swatch_uv(token)
    for f in faces:
        for loop in f.loops:
            loop[uvl].uv = uv
        f[fixed] = 1


def sbox(token, x0, x1, y0, y1, z0, z1, obj="Warna"):
    paint(token, box(obj, x0, x1, y0, y1, z0, z1), obj)


# ---------------------------------------------------------------------------------------------
# Walls with openings. A wall is described by the plane of its outer face; openings are
# (u0, u1, z0, z1) along the wall.
# ---------------------------------------------------------------------------------------------
def wall(axis, plane, sign, u0, u1, z0, z1, openings, top_fn=None):
    """Plaster wall from u0..u1, thickness T inward from `plane`. top_fn(u) may lower the top."""
    us = {u0, u1, *[o[0] for o in openings], *[o[1] for o in openings]}
    if top_fn is not None:  # extra cuts so the top can step down under a sloping roof
        us |= {float(k) for k in range(math.ceil(u0), math.floor(u1) + 1)}
    us = sorted(us)
    zs = sorted({z0, z1, *[o[2] for o in openings], *[o[3] for o in openings]})
    a, b = sorted((plane, plane - sign * T))
    for i in range(len(us) - 1):
        for j in range(len(zs) - 1):
            p, q, c, d = us[i], us[i + 1], zs[j], zs[j + 1]
            mu, mz = (p + q) / 2, (c + d) / 2
            if any(o[0] < mu < o[1] and o[2] < mz < o[3] for o in openings):
                continue
            if top_fn is not None:
                d = min(d, top_fn(p), top_fn(q))
                if d <= c:
                    continue
            if axis == "x":
                box("Plester", p, q, a, b, c, d)
            else:
                box("Plester", a, b, p, q, c, d)


def lbox(mat, axis, plane, sign, u0, u1, n0, n1, z0, z1):
    """Box in wall-local coordinates: n is the distance out of the outer face."""
    a, b = sorted((plane + sign * n0, plane + sign * n1))
    if axis == "x":
        return box(mat, u0, u1, a, b, z0, z1)
    return box(mat, a, b, u0, u1, z0, z1)


def window(axis, plane, sign, uc, w, z0, z1, bars=2):
    h = w / 2
    f = 0.35
    lbox("Kaca", axis, plane, sign, uc - h, uc + h, -0.55, -0.4, z0, z1)
    for k in range(1, bars):
        u = uc - h + k * w / bars
        lbox("Kayu", axis, plane, sign, u - 0.12, u + 0.12, -0.4, -0.2, z0, z1)
    lbox("Kayu", axis, plane, sign, uc - h, uc + h, -0.4, -0.2, z1 - 1.6, z1 - 1.4)  # transom
    lbox("Kayu", axis, plane, sign, uc - h, uc - h + f, -T, 0.15, z0, z1)
    lbox("Kayu", axis, plane, sign, uc + h - f, uc + h, -T, 0.15, z0, z1)
    lbox("Kayu", axis, plane, sign, uc - h + f, uc + h - f, -T, 0.15, z1 - f, z1)
    lbox("Kayu", axis, plane, sign, uc - h + f, uc + h - f, -T, 0.05, z0, z0 + 0.2)
    lbox("Plester", axis, plane, sign, uc - h - 0.4, uc + h + 0.4, 0.0, 0.45, z0 - 0.4, z0)  # sill


def door(axis, plane, sign, uc, w, z0, h_):
    h = w / 2
    f = 0.4
    z1 = z0 + h_
    lbox("Kayu", axis, plane, sign, uc - h, uc - h + f, -T, 0.15, z0, z1)
    lbox("Kayu", axis, plane, sign, uc + h - f, uc + h, -T, 0.15, z0, z1)
    lbox("Kayu", axis, plane, sign, uc - h + f, uc + h - f, -T, 0.15, z1 - f, z1)
    for a, b in ((uc - h + f, uc - 0.04), (uc + 0.04, uc + h - f)):
        lbox("Kayu", axis, plane, sign, a, b, -0.55, -0.3, z0, z1 - f)
        lbox("Kayu", axis, plane, sign, a + 0.4, b - 0.4, -0.3, -0.2, z0 + 0.8, z0 + 4.6)
        lbox("Kayu", axis, plane, sign, a + 0.4, b - 0.4, -0.3, -0.2, z0 + 5.4, z1 - f - 0.8)
    for s in (-1, 1):  # gold handles: Pak RT's touch
        lbox("Emas", axis, plane, sign, uc + s * 0.5 - 0.12, uc + s * 0.5 + 0.12, -0.3, -0.05, z0 + 4.4, z0 + 5.6)


# ---------------------------------------------------------------------------------------------
# Roofs
# ---------------------------------------------------------------------------------------------
def solid(mat, top_pts, faces, thick):
    """Close a roof surface into a solid by dropping a copy `thick` studs and stitching the rim."""
    bm = bm_for(mat)
    top = [bm.verts.new(p) for p in top_pts]
    bot = [bm.verts.new(Vector(p) - Vector((0, 0, thick))) for p in top_pts]
    edges = {}
    for f in faces:
        bm.faces.new([top[i] for i in f])
        bm.faces.new([bot[i] for i in reversed(f)])
        for k in range(len(f)):
            e = (f[k], f[(k + 1) % len(f)])
            key = tuple(sorted(e))
            edges[key] = None if key in edges else e
    for e in edges.values():
        if e is not None:
            a, b = e
            bm.faces.new((top[b], top[a], bot[a], bot[b]))


def hip_roof(mat, x0, x1, y0, y1, z_eave, z_ridge, thick=0.45):
    """Hip roof over a rectangle; ridge runs along the longer side."""
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    hx, hy = (x1 - x0) / 2, (y1 - y0) / 2
    if hx >= hy:
        r0, r1 = (cx - (hx - hy), cy, z_ridge), (cx + (hx - hy), cy, z_ridge)
    else:
        r0, r1 = (cx, cy - (hy - hx), z_ridge), (cx, cy + (hy - hx), z_ridge)
    pts = [(x0, y0, z_eave), (x1, y0, z_eave), (x1, y1, z_eave), (x0, y1, z_eave), r0, r1]
    if hx >= hy:
        faces = [(3, 2, 5, 4), (1, 0, 4, 5), (2, 1, 5), (0, 3, 4)]
    else:
        faces = [(0, 3, 5, 4), (2, 1, 4, 5), (3, 2, 5), (1, 0, 4)]
    solid(mat, pts, faces, thick)
    return pts


def ring_roof(mat, outer, inner, z_out, z_in, thick=0.4):
    """Skirt roof from an outer eave rectangle up to an inner rectangle (the upper storey)."""
    ox0, ox1, oy0, oy1 = outer
    ix0, ix1, iy0, iy1 = inner
    pts = [
        (ox0, oy0, z_out), (ox1, oy0, z_out), (ox1, oy1, z_out), (ox0, oy1, z_out),
        (ix0, iy0, z_in), (ix1, iy0, z_in), (ix1, iy1, z_in), (ix0, iy1, z_in),
    ]  # fmt: skip
    faces = [(0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]  # counter-clockwise from above
    solid(mat, pts, faces, thick)
    return pts


def ridge_cap(p0, p1, w=0.7, h=0.55, lift=0.18):
    up = Vector((0, 0, lift))
    beam("Genteng", Vector(p0) + up, Vector(p1) + up, w, h)


# ---------------------------------------------------------------------------------------------
# Geometry
# ---------------------------------------------------------------------------------------------
def roof_lo(x, y):
    """Top of the skirt roof at (x, y): the lowest of the four slopes (hip geometry)."""
    ox0, ox1, oy0, oy1 = -HX - 1.5, HX + 1.5, HY0 - 1.5, TERRACE_Y
    zs = []
    for d_out, d_in in ((x - ox0, -UX - ox0), (ox1 - x, ox1 - UX), (y - oy0, UY0 - oy0), (oy1 - y, oy1 - UY1)):
        zs.append(EAVE_LO + (INNER_Z - EAVE_LO) * max(0.0, d_out) / d_in)
    return min(zs)


def build_house():
    # plinth, terrace and steps (glossy keramik on top, plaster plinth)
    box("Plester", -HX - 0.4, HX + 0.4, HY0 - 0.4, HY1, 0.0, FLOOR)
    box("Keramik", -HX - 0.4, HX + 0.4, HY1, TERRACE_Y, 0.0, FLOOR)
    box("Keramik", -4.5, 4.5, TERRACE_Y, TERRACE_Y + 1.0, 0.0, FLOOR * 2 / 3)
    box("Keramik", -4.5, 4.5, TERRACE_Y + 1.0, TERRACE_Y + 2.0, 0.0, FLOOR / 3)
    box("Keramik", -4.0, 4.0, TERRACE_Y + 9.0, FENCE_Y, 0.0, 0.25)  # path from the forecourt to the gate

    # ground floor walls; each wall stops just under the skirt roof above it
    def under(axis, plane):
        return lambda u: (roof_lo(u, plane) if axis == "x" else roof_lo(plane, u)) - 0.42

    win_g = (FLOOR + 3.2, FLOOR + 9.2)
    front_open = [
        (DOOR_X - DOOR_W / 2, DOOR_X + DOOR_W / 2, FLOOR, FLOOR + DOOR_H),
        (-12.0, -7.4, *win_g),
        (4.5, 11.5, *win_g),
    ]
    wall("x", HY1, 1, -HX, HX, FLOOR, 18.0, front_open, under("x", HY1 - 0.4))
    wall("x", HY0, -1, -HX, HX, FLOOR, 18.0, [(-11.0, -7.0, *win_g), (-2.0, 2.0, *win_g), (7.0, 11.0, *win_g)], under("x", HY0 + 0.4))
    for sx in (-1, 1):
        opens = [(-9.0, -5.0, *win_g)] if sx < 0 else []
        wall("y", sx * HX, sx, HY0 + T, HY1 - T, FLOOR, 18.0, opens, under("y", sx * (HX - 0.4)))
    door("x", HY1, 1, DOOR_X, DOOR_W, FLOOR, DOOR_H)
    window("x", HY1, 1, -9.7, 4.6, *win_g, bars=2)
    window("x", HY1, 1, 8.0, 7.0, *win_g, bars=3)
    window("x", HY0, -1, -9.0, 4.0, *win_g)
    window("x", HY0, -1, 0.0, 4.0, *win_g)
    window("x", HY0, -1, 9.0, 4.0, *win_g)
    window("y", -HX, -1, -7.0, 4.0, *win_g)

    # upper storey
    win_u = (19.0, 23.6)
    wall("x", UY1, 1, -UX, UX, 15.0, UP_TOP, [(-8.5, -4.5, *win_u), (-2.0, 2.0, *win_u), (4.5, 8.5, *win_u)])
    wall("x", UY0, -1, -UX, UX, 15.0, UP_TOP, [(-6.0, -2.0, *win_u), (2.0, 6.0, *win_u)])
    for sx in (-1, 1):
        wall("y", sx * UX, sx, UY0 + T, UY1 - T, 15.0, UP_TOP, [(-8.0, -4.0, *win_u)])
    window("x", UY1, 1, -6.5, 4.0, *win_u)
    window("x", UY1, 1, 0.0, 4.0, *win_u)
    window("x", UY1, 1, 6.5, 4.0, *win_u)
    window("x", UY0, -1, -4.0, 4.0, *win_u)
    window("x", UY0, -1, 4.0, 4.0, *win_u)
    for sx in (-1, 1):
        window("y", sx * UX, sx, -6.0, 4.0, *win_u)

    # roofs: skirt roof over the ground floor and terrace, hip roof on the upper storey
    outer = (-HX - 1.5, HX + 1.5, HY0 - 1.5, TERRACE_Y)
    inner = (-UX, UX, UY0, UY1)
    lo = ring_roof("Genteng", outer, inner, EAVE_LO, INNER_Z)
    for k in range(4):
        ridge_cap(lo[k], lo[k + 4], w=0.6, h=0.45, lift=0.15)
    hi = hip_roof("Genteng", -UX - 1.5, UX + 1.5, UY0 - 1.5, UY1 + 1.5, EAVE_HI, RIDGE)
    ridge_cap(hi[4], hi[5])
    for r, es in ((hi[4], (hi[0], hi[3])), (hi[5], (hi[1], hi[2]))):
        for e in es:
            ridge_cap(r, e, w=0.6, h=0.45, lift=0.15)
    # fascia boards
    for (x0, x1, y0, y1, z) in ((outer[0], outer[1], outer[2], outer[3], EAVE_LO), (-UX - 1.5, UX + 1.5, UY0 - 1.5, UY1 + 1.5, EAVE_HI)):
        zc = z - 0.25
        for yy in (y0, y1):
            beam("Kayu", (x0 - 0.1, yy, zc), (x1 + 0.1, yy, zc), 0.15, 0.6)
        for xx in (x0, x1):
            beam("Kayu", (xx, y0 - 0.1, zc), (xx, y1 + 0.1, zc), 0.15, 0.6)

    # terrace columns: plain plaster with gold caps and bases (the only gold on the house)
    col_y = TERRACE_Y - 1.2
    col_top = roof_lo(0, col_y) - 0.45
    for cx in (-9.0, 13.0):
        box("Plester", cx - 1.2, cx + 1.2, col_y - 1.2, col_y + 1.2, FLOOR, FLOOR + 1.6)
        cylinder("Emas", (cx, col_y, FLOOR + 1.85), 1.15, 0.5, segments=16)
        cylinder("Plester", (cx, col_y, (FLOOR + 2.1 + col_top - 0.9) / 2), 0.85, col_top - 0.9 - (FLOOR + 2.1), segments=16)
        cylinder("Emas", (cx, col_y, col_top - 0.65), 1.0, 0.5, segments=16)
        box("Emas", cx - 1.25, cx + 1.25, col_y - 1.25, col_y + 1.25, col_top - 0.4, col_top)

    # wall lamps beside the door and the left window
    for lx in (3.2, -13.2):
        sbox("tinta", lx - 0.35, lx + 0.35, HY1, HY1 + 0.5, 9.0, 10.4)
        sbox("senja", lx - 0.25, lx + 0.25, HY1 + 0.2, HY1 + 0.55, 9.2, 10.0)

    # satellite dish on the skirt roof, CCTV under the upper eave
    dx, dy = 14.0, -7.0
    base = roof_lo(dx, dy)
    paint("perak", cylinder("Warna", (dx, dy, (base + 29.0) / 2), 0.15, 29.0 - base + 0.2, segments=8))
    tilt = Matrix.Rotation(math.radians(-40), 4, "X")
    paint("perak", cylinder("Warna", (dx, dy + 0.6, 29.6), 0.3, 0.9, segments=16, r_top=2.4, rot=tilt))
    paint("tinta", beam("Warna", (dx, dy + 0.9, 29.7), (dx, dy + 2.4, 30.9), 0.12, 0.12))
    paint("tinta", box("Warna", dx - 0.25, dx + 0.25, dy + 2.3, dy + 2.8, 30.7, 31.2))
    cx_, cy_ = UX - 0.7, UY1 + 0.2
    paint("kertas", beam("Warna", (cx_, cy_ - 0.2, 25.6), (cx_, cy_ + 1.3, 25.1), 0.6, 0.6))
    paint("tinta", box("Warna", cx_ - 0.22, cx_ + 0.22, cy_ + 1.3, cy_ + 1.42, 24.9, 25.3))
    paint("tinta", box("Warna", cx_ - 0.1, cx_ + 0.1, cy_ - 0.2, cy_, 25.6, 26.0))


def build_terrace_furniture():
    sy0, sy1 = HY1 + 0.3, HY1 + 2.9
    sx0, sx1 = 3.4, 10.4
    seat = FLOOR + 2.0
    # an ordinary fabric sofa, a little worn: base, seat cushions, back, arms, short legs
    box("Sofa", sx0, sx1, sy0, sy1, FLOOR + 0.5, seat - 0.6)
    for k in range(3):
        a = sx0 + 0.9 + k * (sx1 - sx0 - 1.8) / 3
        b = a + (sx1 - sx0 - 1.8) / 3 - 0.08
        box("Sofa", a, b, sy0 + 0.9, sy1 - 0.05, seat - 0.6, seat)
        box("Sofa", a, b, sy0, sy0 + 1.0, seat - 0.6, seat + 2.4)
    for xa, xb in ((sx0, sx0 + 0.9), (sx1 - 0.9, sx1)):
        box("Sofa", xa, xb, sy0, sy1, seat - 0.6, seat + 0.9)
    for lx in (sx0 + 0.3, sx1 - 0.3):
        for ly in (sy0 + 0.3, sy1 - 0.3):
            sbox("tinta_lembut", lx - 0.18, lx + 0.18, ly - 0.18, ly + 0.18, FLOOR, FLOOR + 0.5)

    # the terrace table: MapSpec pakrt anchor size, 5 wide x 2.4 tall x 3 deep
    tx, ty = 6.9, sy1 + 1.75
    top = FLOOR + 2.4
    box("Meja", tx - 2.5, tx + 2.5, ty - 1.5, ty + 1.5, top - 0.3, top)
    for lx in (tx - 2.2, tx + 2.2):
        for ly in (ty - 1.2, ty + 1.2):
            box("Meja", lx - 0.2, lx + 0.2, ly - 0.2, ly + 0.2, FLOOR, top - 0.3)
    box("Meja", tx - 2.2, tx + 2.2, ty - 1.2, ty + 1.2, FLOOR + 0.5, FLOOR + 0.7)  # low shelf
    # a fat brown envelope (bigger than life so it reads on a phone) and a glass of tea
    paint("bambu", obox("Warna", (tx - 0.4, ty, top + 0.22), (2.4, 1.4, 0.44), 0.2))
    paint("tinta_lembut", obox("Warna", (tx - 0.4 + 0.15, ty - 0.08, top + 0.45), (2.2, 0.5, 0.04), 0.2))
    glass = cylinder("Warna", (tx + 1.6, ty + 0.3, top + 0.45), 0.28, 0.9, segments=12, r_top=0.33)
    paint("genteng", glass)


def build_fence():
    """Waist-high dark iron fence on plaster pillars with gold tips; main gate wide open."""
    gaps = [(-5.5, 5.5), (16.5, 28.5)]  # main gate, carport entrance
    left = list(np.linspace(-LOT_X, -5.5, 4))
    pillars = [*left, 5.5, 16.5, 28.5, LOT_X]

    def bars(x0, x1, y):
        box("Plester", x0, x1, y - 0.5, y + 0.5, 0.0, 1.4)  # low plaster base
        box("Besi", x0, x1, y - 0.15, y + 0.15, 4.4, 4.7)
        n = max(1, int((x1 - x0) / 0.9))
        for k in range(n):
            x = x0 + (k + 0.5) * (x1 - x0) / n
            box("Besi", x - 0.14, x + 0.14, y - 0.14, y + 0.14, 1.4, 4.9)
            cylinder("Emas", (x, FENCE_Y if y == FENCE_Y else y, 5.15), 0.22, 0.5, segments=4, r_top=0.0)

    for a, b in zip(pillars[:-1], pillars[1:]):
        if any(g0 <= (a + b) / 2 <= g1 for g0, g1 in gaps):
            continue
        bars(a + 0.7, b - 0.7, FENCE_Y)
    for px in pillars:
        box("Plester", px - 0.75, px + 0.75, FENCE_Y - 0.75, FENCE_Y + 0.75, 0.0, 5.6)
        box("Emas", px - 0.9, px + 0.9, FENCE_Y - 0.9, FENCE_Y + 0.9, 5.6, 6.0)
        cylinder("Emas", (px, FENCE_Y, 6.4), 0.85, 0.8, segments=4, r_top=0.0, rot=Matrix.Rotation(math.pi / 4, 4, "Z"))
    # side returns
    for sx in (-1, 1):
        x = sx * LOT_X
        ys = list(np.linspace(-2.0, FENCE_Y, 4))
        for a, b in zip(ys[:-1], ys[1:]):
            box("Plester", x - 0.5, x + 0.5, a + 0.75, b - 0.75, 0.0, 1.4)
            box("Besi", x - 0.15, x + 0.15, a + 0.75, b - 0.75, 4.4, 4.7)
            n = max(1, int((b - a - 1.5) / 0.9))
            for k in range(n):
                y = a + 0.75 + (k + 0.5) * (b - a - 1.5) / n
                box("Besi", x - 0.14, x + 0.14, y - 0.14, y + 0.14, 1.4, 4.9)
        for y in ys[:-1]:
            box("Plester", x - 0.75, x + 0.75, y - 0.75, y + 0.75, 0.0, 5.6)
            box("Emas", x - 0.9, x + 0.9, y - 0.9, y + 0.9, 5.6, 6.0)

    # clipped hedges just inside the front fence, seen through the bars as in the concept
    for a, b in zip(pillars[:-1], pillars[1:]):
        if any(g0 <= (a + b) / 2 <= g1 for g0, g1 in gaps):
            continue
        box("Daun", a + 0.9, b - 0.9, FENCE_Y - 2.4, FENCE_Y - 0.9, 0.1, 2.0)

    # gate leaves swung open into the yard
    for hinge, sgn in ((-4.8, 1), (4.8, -1)):
        yaw = sgn * math.radians(-70)
        d = Vector((math.cos(yaw), math.sin(yaw), 0)) * sgn
        length = 4.6
        mid = Vector((hinge, FENCE_Y - 0.3, 0)) + d * (length / 2)
        ang = math.atan2(d.y, d.x)
        obox("Besi", (mid.x, mid.y, 1.2), (length, 0.3, 0.3), ang)
        obox("Besi", (mid.x, mid.y, 4.55), (length, 0.3, 0.3), ang)
        for k in range(6):
            p = Vector((hinge, FENCE_Y - 0.3, 0)) + d * (0.35 + k * (length - 0.7) / 5)
            obox("Besi", (p.x, p.y, 2.9), (0.28, 0.28, 3.6), ang)
            cylinder("Emas", (p.x, p.y, 4.95), 0.2, 0.5, segments=4, r_top=0.0)


def build_carport():
    x0, x1, y0, y1 = HX + 1.0, LOT_X - 0.4, -9.0, 14.0
    box("Keramik", x0, x1, y0, FENCE_Y, 0.0, 0.25)
    z_in, z_out = 13.4, 12.2  # lean-to sloping away from the house
    for px in (x0 + 0.4, x1 - 0.4):
        for py in (y0 + 0.4, y1 - 0.4):
            if px < HX + 2 and py < HY1:
                continue  # the house wall carries this corner
            z_top = z_in + (z_out - z_in) * (px - x0) / (x1 - x0) - 0.35
            box("Besi", px - 0.3, px + 0.3, py - 0.3, py + 0.3, 0.25, z_top)
    beam("Seng", (x0, (y0 + y1) / 2, z_in), (x1 + 0.3, (y0 + y1) / 2, z_out), y1 - y0 + 0.6, 0.25)
    for py in (y0 + 0.4, y1 - 0.4):
        beam("Besi", (x0, py, z_in - 0.45), (x1, py, z_out - 0.45), 0.4, 0.4)

    # the red-plate government MPV, nose to the street
    # an older MPV (about 4.5 m at avatar scale), nose to the street, on the carport floor
    cx, cy, z0 = HX + 1.0 + 5.2, 2.6, 0.25
    body = "Mobil"
    L, W = 18.5, 7.2
    yb, yf = cy - L / 2, cy + L / 2

    def cbox(tok, x0, x1, y0, y1, za, zb):
        paint(tok, box(body, x0, x1, y0, y1, z0 + za, z0 + zb), body)

    wheel_rot = Matrix.Rotation(math.pi / 2, 4, "Y")
    for wy in (yb + 3.6, yf - 3.8):
        for sx in (-1, 1):
            paint("tinta", cylinder(body, (cx + sx * (W / 2 - 0.4), wy, z0 + 1.45), 1.45, 1.0, segments=14, rot=wheel_rot), body)
            paint("perak", cylinder(body, (cx + sx * (W / 2 - 0.05), wy, z0 + 1.45), 0.75, 0.2, segments=10, rot=wheel_rot), body)
    cbox("badan", cx - W / 2, cx + W / 2, yb, yf, 1.6, 4.8)  # lower body
    cbox("badan", cx - W / 2 + 0.3, cx + W / 2 - 0.3, yb + 0.4, yf - 5.6, 4.8, 8.2)  # cabin
    cbox("kaca", cx - W / 2 + 0.25, cx + W / 2 - 0.25, yb + 1.2, yf - 6.4, 5.4, 7.6)  # side glass
    cbox("kaca", cx - W / 2 + 0.6, cx + W / 2 - 0.6, yb + 0.35, yb + 0.45, 5.4, 7.6)  # rear glass
    paint("kaca", beam(body, (cx, yf - 5.7, z0 + 8.1), (cx, yf - 3.8, z0 + 5.0), W - 0.9, 0.2), body)  # windscreen
    cbox("badan", cx - W / 2 + 0.3, cx + W / 2 - 0.3, yb + 0.4, yf - 5.6, 8.2, 8.5)  # roof
    for sx in (-1, 1):
        cbox("senja", cx + sx * 2.6 - 0.7, cx + sx * 2.6 + 0.7, yf, yf + 0.1, 3.8, 4.4)  # headlights
        cbox("merah", cx + sx * 3.0 - 0.4, cx + sx * 3.0 + 0.4, yb - 0.1, yb, 3.9, 4.7)  # tail lights
    cbox("tinta", cx - 1.8, cx + 1.8, yf, yf + 0.08, 2.9, 3.7)  # plain grille, no badge
    cbox("tinta", cx - W / 2 - 0.1, cx + W / 2 + 0.1, yf - 0.2, yf + 0.3, 1.6, 2.1)  # bumpers
    cbox("tinta", cx - W / 2 - 0.1, cx + W / 2 + 0.1, yb - 0.3, yb + 0.2, 1.6, 2.1)
    # red government plates, a little oversized so they read on a phone
    cbox("merah", cx - 1.7, cx + 1.7, yf + 0.3, yf + 0.42, 1.95, 2.85)
    cbox("merah", cx - 1.7, cx + 1.7, yb - 0.42, yb - 0.3, 1.95, 2.85)

    # village-aid cement sacks stacked beside the car, long side along the wall
    rng = np.random.default_rng(3)
    for layer in range(4):
        for k in range(3 - layer // 2):
            sx = HX + 1.0 + 10.2 + rng.uniform(-0.1, 0.1)
            sy = -6.6 + k * 2.75 + (layer % 2) * 0.6
            paint("kertas", obox("Warna", (sx, sy, 0.25 + 0.45 + layer * 0.9), (1.7, 2.6, 0.9), rng.uniform(-0.1, 0.1)))


def build_lesehan():
    """Villagers' hangout in the left side yard: a tikar on a low platform under a tarp."""
    x0, x1, y0, y1 = -LOT_X + 1.4, -HX - 2.4, 2.0, 14.0
    z = 1.1
    box("Kayu", x0, x1, y0, y1, 0.0, z)
    box("Tikar", x0 + 0.4, x1 - 0.4, y0 + 0.4, y1 - 0.4, z, z + 0.06)
    zt = z + 0.06
    hi, lo = 11.5, 10.0  # tarp slopes toward the street
    for px in (x0 - 0.3, x1 + 0.3):
        for py in (y0 - 0.6, y1 + 0.6):
            zp = hi + (lo - hi) * (py - (y0 - 0.6)) / (y1 - y0 + 1.2)
            cylinder("Bambu", (px, py, zp / 2), 0.3, zp, segments=8)
    beam("Terpal", ((x0 + x1) / 2, y0 - 1.2, hi + 0.1), ((x0 + x1) / 2, y1 + 1.4, lo - 0.05), x1 - x0 + 2.0, 0.12)
    # things on the mat
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    paint("merah", cylinder("Warna", (cx - 2.6, cy + 2.4, zt + 1.0), 0.55, 2.0, segments=12))  # thermos
    paint("perak", cylinder("Warna", (cx - 2.6, cy + 2.4, zt + 2.15), 0.4, 0.3, segments=12))
    for gx, gy in ((cx - 1.2, cy + 2.8), (cx + 0.2, cy + 3.1), (cx - 0.4, cy + 1.6)):
        paint("tinta", cylinder("Warna", (gx, gy, zt + 0.4), 0.26, 0.8, segments=10, r_top=0.3))
    paint("kertas", cylinder("Warna", (cx + 2.2, cy + 2.2, zt + 0.08), 1.1, 0.16, segments=14))  # plate
    rng = np.random.default_rng(11)
    for k in range(7):  # gorengan
        a = k * 0.9
        paint("kunyit", obox("Warna", (cx + 2.2 + 0.55 * math.cos(a), cy + 2.2 + 0.55 * math.sin(a), zt + 0.3), (0.7, 0.4, 0.3), rng.uniform(0, 3)))
    box("Catur", cx - 1.6, cx + 1.6, cy - 2.4, cy + 0.8, zt, zt + 0.25)  # chess board
    for k in range(8):
        tok = "kertas" if k < 4 else "tinta"
        px = cx - 1.2 + (k % 4) * 0.8
        py = cy - 2.0 if k < 4 else cy + 0.4
        paint(tok, cylinder("Warna", (px, py, zt + 0.6), 0.2, 0.7, segments=8, r_top=0.12))
    paint("genteng", cylinder("Warna", (cx + 2.4, cy - 2.0, zt + 0.12), 0.6, 0.24, segments=12, r_top=0.7))  # ashtray
    # sandals left at the edge of the mat
    for k, tok in enumerate(("tinta", "tinta", "malam", "malam")):
        sx = cx - 2.0 + k * 1.1 + (0.2 if k % 2 else 0)
        paint(tok, obox("Warna", (sx, y1 + 1.7, 0.2), (0.8, 2.0, 0.2), rng.uniform(-0.3, 0.3)))


def build_yard():
    """Lawn over the whole lot, a wide glossy forecourt from the terrace to the carport, potted
    plants by the steps. The deep front yard is what the approved concept shows."""
    box("Rumput", -LOT_X, LOT_X, LOT_Y0, FENCE_Y, 0.0, 0.1)
    box("Keramik", -HX - 0.4, HX + 1.0, TERRACE_Y, TERRACE_Y + 9.0, 0.0, 0.25)  # forecourt
    for px in (-6.2, 6.2):
        cylinder("Genteng", (px, TERRACE_Y + 3.4, 0.85), 1.0, 1.5, segments=10, r_top=1.25)
        rng = np.random.default_rng(int(px * 10) + 100)
        base = Vector((px, TERRACE_Y + 3.4, 1.5))
        for k in range(9):  # leaf blades fanning out of the pot, not a ball
            a = k * 2 * math.pi / 9 + rng.uniform(-0.2, 0.2)
            tip = base + Vector((math.cos(a) * 1.9, math.sin(a) * 1.9, rng.uniform(2.2, 3.6)))
            beam("Daun", base, tip, 0.7, 0.12)


def build_flag():
    x, y = -13.5, TERRACE_Y + 12.5
    paint("kertas", box("Warna", x - 0.7, x + 0.7, y - 0.7, y + 0.7, 0.0, 0.6))
    paint("perak", cylinder("Warna", (x, y, 11.6), 0.16, 22.0, segments=8))
    paint("kunyit", sphere("Warna", (x, y, 22.75), 0.35))
    paint("merah", box("Warna", x + 0.2, x + 5.6, y - 0.05, y + 0.05, 19.8, 21.6))
    paint("kertas", box("Warna", x + 0.2, x + 5.6, y - 0.05, y + 0.05, 18.0, 19.8))


def build_aspal():
    """The gag: smooth asphalt only in front of this lot, ending at its edges (optional piece)."""
    box("Aspal", -LOT_X - 0.9, LOT_X + 0.9, LOT_Y1, LOT_Y1 + 12.0, 0.0, 0.15)


# ---------------------------------------------------------------------------------------------
# UVs: one 0..1 projection per object (free faces only).
# ---------------------------------------------------------------------------------------------
def compute_uvs(bm):
    bm.normal_update()
    uv = bm.loops.layers.uv.verify()
    fixed = bm.faces.layers.int["fixed"]
    free = [f for f in bm.faces if not f[fixed]]
    if not free:
        return 1.0
    cos = [v.co for f in free for v in f.verts]
    cx = (min(c.x for c in cos) + max(c.x for c in cos)) / 2
    cy = (min(c.y for c in cos) + max(c.y for c in cos)) / 2
    zmin = min(c.z for c in cos)
    raw, span = [], 0.0
    for f in free:
        n = f.normal
        for loop in f.loops:
            co = loop.vert.co
            if abs(n.z) > 0.95:
                u, v, centred = co.x - cx, co.y - cy, True
            elif abs(n.z) < 0.05:
                u = (co.y - cy) if abs(n.x) > abs(n.y) else (co.x - cx)
                v, centred = co.z - zmin, False
            else:
                eave = n.cross(Vector((0, 0, 1))).normalized()
                u = (co - Vector((cx, cy, 0))).dot(eave)
                v, centred = (co.z - zmin) / math.sqrt(max(1e-6, 1 - n.z * n.z)), False
            raw.append((loop, u, v, centred))
            span = max(span, 2 * abs(u), (2 * abs(v)) if centred else v)
    size = span * 1.02 + 1e-6
    for loop, u, v, centred in raw:
        loop[uv].uv = (min(1.0, max(0.0, u / size + 0.5)), min(1.0, max(0.0, v / size + (0.5 if centred else 0.0))))
    return size


# ---------------------------------------------------------------------------------------------
# Procedural textures (numpy): rows = v from the bottom, sRGB. Average colour = palette swatch.
# ---------------------------------------------------------------------------------------------
def vnoise(w, h, cx, cy, seed):
    r = np.random.default_rng(seed).random((cy + 2, cx + 2))
    tx = np.linspace(0, cx, w, endpoint=False)
    ty = np.linspace(0, cy, h, endpoint=False)
    ix, iy = tx.astype(int), ty.astype(int)
    fx, fy = tx - ix, ty - iy
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = r[iy][:, ix], r[iy][:, ix + 1]
    c, d = r[iy + 1][:, ix], r[iy + 1][:, ix + 1]
    fx, fy = fx[None, :], fy[:, None]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(w, h, cx, cy, octaves, seed):
    total, amp, norm = 0.0, 1.0, 0.0
    for o in range(octaves):
        total = total + amp * vnoise(w, h, cx * 2**o, cy * 2**o, seed + o)
        norm += amp
        amp *= 0.5
    return total / norm


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def grid(res, size):
    pps = res / size
    v, u = np.mgrid[0:res, 0:res].astype(np.float64)
    return u / pps, v / pps


def hash2(a, b, seed):
    table = np.random.default_rng(seed).random((97, 89))
    return table[np.mod(a, 97).astype(int), np.mod(b, 89).astype(int)]


def colour(rgb, shade):
    shade = shade / max(1e-6, float(np.mean(shade)))
    return np.stack([shade * rgb[0], shade * rgb[1], shade * rgb[2]], axis=-1)


def mix(a, b, t):
    t = np.asarray(t)[..., None] if np.ndim(t) else t
    return a * (1 - t) + b * t


def tex_plester(res, size):
    u, v = grid(res, size)
    shade = (0.9 + 0.12 * fbm(res, res, 24, 24, 4, 41)) * (0.92 + 0.1 * fbm(res, res, 5, 5, 3, 42))
    base = colour(P["kertas"], shade)
    dirt = (1 - smoothstep(0.0, 2.0, v)) * (0.5 + 0.5 * fbm(res, res, 30, 8, 3, 44)) * 0.4
    return mix(base, P["tinta_lembut"], dirt)


def tex_genteng(res, size):
    u, v = grid(res, size)
    tw, th = 1.7, 1.4  # tiles scaled with the 7.25-stud avatar
    col, row = np.floor(u / tw), np.floor(v / th)
    fu, fv = (u / tw) % 1, (v / th) % 1
    prof = 0.5 + 0.5 * np.sin(np.pi * fu) ** 0.6
    shade = prof * (1 - 0.6 * smoothstep(0.72, 0.97, fv)) * (1 + 0.18 * (fv < 0.08))
    shade *= np.where((fu < 0.05) | (fu > 0.95), 0.5, 1.0)
    shade *= (0.86 + 0.22 * hash2(col, row, 11)) * (0.82 + 0.25 * fbm(res, res, 6, 6, 4, 21))
    base = colour(P["genteng"], shade)
    moss = smoothstep(0.64, 0.8, fbm(res, res, 10, 10, 3, 31)) * 0.25
    return mix(base, P["tinta_lembut"], moss)


def tex_kayu(res, size):
    u, v = grid(res, size)
    grain = vnoise(res, res, int(size * 6), 3, 81)
    shade = (0.86 + 0.14 * (0.5 + 0.5 * np.sin(u * 24 + grain * 8))) * (0.85 + 0.2 * fbm(res, res, 8, 8, 4, 82))
    return colour(P["tinta_lembut"], shade)


def tex_kaca(res, size):
    u, v = grid(res, size)
    streak = smoothstep(0.55, 0.6, (0.5 + 0.5 * np.sin((u + v) * 1.6)))
    shade = 0.75 + 0.35 * (v / size) + 0.5 * streak
    return colour(P["indigo"], shade)


def tex_keramik(res, size):
    u, v = grid(res, size)
    t = 2.4  # 60 cm tiles at avatar scale
    tu, tv = np.floor(u / t), np.floor(v / t)
    fu, fv = (u / t) % 1, (v / t) % 1
    shade = (0.93 + 0.1 * hash2(tu, tv, 61)) * (0.94 + 0.08 * fbm(res, res, 10, 10, 3, 62))
    shine = 0.12 * smoothstep(0.6, 0.95, np.sin((u - v) * 0.35) * 0.5 + 0.5)  # glossy reflection
    base = colour(mix(P["kertas"], P["bambu"], 0.12), shade) + shine[..., None]
    grout = ((fu < 0.015) | (fu > 0.985) | (fv < 0.015) | (fv > 0.985))[..., None]
    return np.where(grout, mix(P["kertas"], P["tinta_lembut"], 0.4), base)


def tex_emas(res, size):
    u, v = grid(res, size)
    shade = (0.85 + 0.3 * smoothstep(0.3, 0.9, fbm(res, res, 6, 20, 3, 71))) * (0.92 + 0.1 * fbm(res, res, 16, 16, 3, 72))
    base = colour(P["kunyit"], shade)
    chip = smoothstep(0.78, 0.84, fbm(res, res, 18, 18, 4, 73))  # paint chipped to the plaster
    return mix(base, P["kertas"], chip * 0.8)


def tex_besi(res, size):
    shade = (0.9 + 0.12 * fbm(res, res, 20, 20, 4, 91)) * (0.95 + 0.06 * vnoise(res, res, 4, 30, 92))
    base = colour(mix(P["tinta"], P["indigo"], 0.15), shade)
    rust = smoothstep(0.75, 0.85, fbm(res, res, 14, 14, 4, 93)) * 0.4
    return mix(base, P["genteng"], rust)


def tex_seng(res, size):
    u, v = grid(res, size)
    wave = 0.5 + 0.5 * np.sin(u * 2 * math.pi / 0.7)
    shade = (0.75 + 0.25 * wave) * (0.9 + 0.12 * fbm(res, res, 8, 8, 4, 101))
    base = colour(mix(P["kertas"], P["indigo"], 0.35), shade)
    rust = smoothstep(0.62, 0.8, fbm(res, res, 12, 12, 4, 102)) * 0.45
    return mix(base, P["genteng"], rust)


def tex_terpal(res, size):
    u, v = grid(res, size)
    wrinkle = 0.5 + 0.5 * np.sin(u * 1.7 + 2.5 * fbm(res, res, 6, 6, 3, 111))
    shade = (0.85 + 0.2 * wrinkle) * (0.9 + 0.12 * fbm(res, res, 12, 12, 3, 112))
    base = colour(P["malam"], shade)
    hem = ((u % size) < 0.25) | ((u % size) > size - 0.25)
    return np.where(hem[..., None], P["kertas"] * 0.85, base)


def tex_tikar(res, size):
    u, v = grid(res, size)
    s = 0.35  # pandan strips
    a, b = np.floor((u + v) / s), np.floor((u - v) / s)
    over = ((a + b) % 2 == 0)
    fa, fb = ((u + v) / s) % 1, ((u - v) / s) % 1
    ridge = np.where(over, 0.75 + 0.35 * np.sin(np.pi * fa), 0.75 + 0.35 * np.sin(np.pi * fb))
    shade = ridge * (0.9 + 0.12 * fbm(res, res, 10, 10, 3, 121))
    base = colour(mix(P["bambu"], P["kunyit"], 0.25), shade)
    border = (np.minimum(u, size - u) < 0.5) | (np.minimum(v, size - v) < 0.5)
    return np.where(border[..., None], P["merah"] * 0.9, base)


def tex_bambu(res, size):
    u, v = grid(res, size)
    shade = (0.88 + 0.12 * vnoise(res, res, int(size * 6), 3, 131)) * (0.88 + 0.16 * fbm(res, res, 8, 8, 3, 132))
    shade = np.where((v % 2.2) < 0.1, shade * 0.72, shade)
    return colour(P["bambu"], shade)


def tex_sofa(res, size):
    u, v = grid(res, size)
    weave = 0.96 + 0.04 * np.sin(u * 60) * np.sin(v * 60)
    shade = weave * (0.88 + 0.16 * fbm(res, res, 12, 12, 4, 141))
    base = colour(P["merah"], shade)
    worn = smoothstep(0.62, 0.85, fbm(res, res, 6, 6, 3, 142)) * 0.3  # faded seat patches
    return mix(base, P["kertas"], worn)


def tex_catur(res, size):
    u, v = grid(res, size)
    sq = size / 8.6
    dark = ((np.floor(u / sq) + np.floor(v / sq)) % 2 == 1)[..., None]
    return np.where(dark, P["tinta_lembut"], mix(P["kertas"], P["bambu"], 0.3))


def tex_aspal(res, size):
    u, v = grid(res, size)
    shade = (0.85 + 0.25 * fbm(res, res, 40, 40, 4, 151)) * (0.95 + 0.08 * fbm(res, res, 5, 5, 2, 152))
    base = colour(mix(P["tinta"], P["indigo"], 0.3), shade)
    dash = (np.abs(v - size / 2) < 0.3) & ((u % 8.0) < 4.0)
    return np.where(dash[..., None], P["kertas"], base)


def tex_rumput(res, size):
    """Short mown lawn: green blades as fine streaks, a few darker clumps, palette greens only."""
    u, v = grid(res, size)
    blades = vnoise(res, res, int(size * 10), int(size * 3), 171)
    clumps = fbm(res, res, 12, 12, 4, 172)
    shade = (0.85 + 0.2 * blades) * (0.85 + 0.25 * clumps)
    return colour(mix(P["daun"], P["padi"], 0.35), shade)


def tex_daun(res, size):
    """Leafy foliage for hedges and potted plants: overlapping leaf blobs, daun with padi tips."""
    u, v = grid(res, size)
    leaves = fbm(res, res, int(size * 3), int(size * 3), 4, 181)
    tips = smoothstep(0.6, 0.75, fbm(res, res, int(size * 5), int(size * 5), 3, 182))
    shade = 0.7 + 0.5 * leaves
    return mix(colour(P["daun"], shade), P["padi"], tips * 0.5)


def tex_warna(res, size):
    canvas = np.zeros((res, res, 3))
    cell = res // 4
    for i, token in enumerate(SWATCHES):
        r, c = i // 4, i % 4
        canvas[r * cell : (r + 1) * cell, c * cell : (c + 1) * cell] = swatch_rgb(token)
    grain = 0.96 + 0.08 * fbm(res, res, 16, 16, 3, 161)
    return np.flipud(canvas * grain[..., None])


MATERIALS = {
    # name: (texture fn, resolution, roughness)
    "Plester": (tex_plester, 1024, 0.9),
    "Genteng": (tex_genteng, 1024, 0.75),
    "Kayu": (tex_kayu, 512, 0.75),
    "Kaca": (tex_kaca, 256, 0.15),
    "Keramik": (tex_keramik, 1024, 0.2),
    "Emas": (tex_emas, 256, 0.35),
    "Besi": (tex_besi, 512, 0.5),
    "Seng": (tex_seng, 512, 0.45),
    "Terpal": (tex_terpal, 256, 0.8),
    "Tikar": (tex_tikar, 512, 0.9),
    "Bambu": (tex_bambu, 256, 0.75),
    "Sofa": (tex_sofa, 256, 0.95),
    "Catur": (tex_catur, 128, 0.6),
    "Aspal": (tex_aspal, 1024, 0.9),
    "Rumput": (tex_rumput, 1024, 0.95),
    "Daun": (tex_daun, 512, 0.8),
    "Warna": (tex_warna, 256, 0.6),
}
# objects that reuse another object's texture (one image, one upload in Roblox)
SHARED = {"Meja": "Kayu", "Mobil": "Warna"}


def save_texture(name, arr):
    os.makedirs(TEX_DIR, exist_ok=True)
    h, w, _ = arr.shape
    img = bpy.data.images.new(f"{NAME}_{name}", w, h, alpha=False)
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(arr, 0.0, 1.0)
    img.pixels.foreach_set(rgba.ravel())
    path = os.path.join(TEX_DIR, f"rumah_pakrt_{name.lower()}.png")
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    img.filepath = path
    return img


def make_material(name, img, rough):
    mat = bpy.data.materials.new(f"{NAME}_{name}")
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.location = (-400, 200)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = rough
    return mat


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0

    build_house()
    build_terrace_furniture()
    build_fence()
    build_carport()
    build_lesehan()
    build_yard()
    build_flag()
    build_aspal()

    # The layout above is authored with the carport at +X. Seen from the street (looking -Y) +X
    # is on the viewer's left, but the approved concept has the lesehan on the left and the
    # carport on the right, so mirror X once here, then centre the lot on the origin.
    shift = Vector((0.0, -(LOT_Y0 + LOT_Y1) / 2, 0.0))
    for bm in BMS.values():
        bmesh.ops.scale(bm, vec=(-1.0, 1.0, 1.0), verts=bm.verts)
        bmesh.ops.reverse_faces(bm, faces=bm.faces[:])
        bmesh.ops.translate(bm, vec=shift, verts=bm.verts)

    report, mats = {}, {}
    coll = bpy.data.collections.new(NAME)
    scene.collection.children.link(coll)
    for name, bm in BMS.items():
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        size = compute_uvs(bm)
        tex_name = SHARED.get(name, name)
        if tex_name not in mats:
            fn, res, rough = MATERIALS[tex_name]
            mats[tex_name] = make_material(tex_name, save_texture(tex_name, fn(res, size)), rough)
        mesh = bpy.data.meshes.new(f"{NAME}_{name}")
        bm.to_mesh(mesh)
        bm.free()
        centre = sum((v.co for v in mesh.vertices), Vector()) / len(mesh.vertices)
        mesh.transform(Matrix.Translation(-centre))
        mesh.materials.append(mats[tex_name])
        obj = bpy.data.objects.new(f"{NAME}_{name}", mesh)
        obj.location = centre
        coll.objects.link(obj)
        report[name] = len(mesh.polygons)

    blend_path = os.path.join(HERE, "rumah_pakrt.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.file.make_paths_relative()
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(HERE, "rumah_pakrt.fbx"),
        use_selection=False,
        object_types={"MESH"},
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_UNITS",
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        add_leaf_bones=False,
        bake_anim=False,
        path_mode="COPY",
        embed_textures=True,
    )

    def bbox(objs):
        mins, maxs = Vector((1e9,) * 3), Vector((-1e9,) * 3)
        for obj in objs:
            for corner in obj.bound_box:
                w = obj.matrix_world @ Vector(corner)
                mins, maxs = Vector(map(min, mins, w)), Vector(map(max, maxs, w))
        return tuple(round(a, 2) for a in mins), tuple(round(a, 2) for a in maxs)

    print("PAKRT_TRIS", report, "total", sum(report.values()))
    print("PAKRT_BBOX_ALL", bbox(coll.objects))
    print("PAKRT_BBOX_NO_ASPAL", bbox([o for o in coll.objects if not o.name.endswith("Aspal")]))
    print("PAKRT_MEJA", bbox([coll.objects[f"{NAME}_Meja"]]))


main()
