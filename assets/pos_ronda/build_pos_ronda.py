"""Build the `pos_ronda` night-watch post for Juragan Desa in Blender.

Run from the repository root:

    blender --background --factory-startup --python assets/pos_ronda/build_pos_ronda.py

Writes, next to this script:
    pos_ronda.blend           editable source (textures linked, not packed)
    pos_ronda.fbx             Roblox import file (textures embedded)
    textures/*.png            generated textures (own work, no third-party source)

Units: 1 Blender unit = 1 Roblox stud. Ground is z = 0, the footprint is centred on the origin,
and the open front faces Blender +Y, which the FBX exporter (forward -Z, up Y) turns into Roblox
-Z, the LookVector of an identity CFrame. One object per material, so every Roblox MeshPart gets
one texture. Every colour comes from the project palette in src/shared/Config/Visuals.luau.

The sign board is blank on purpose: `PosRonda_PapanNama` is its front panel, for a SurfaceGui
showing Strings.jail_title ("POS RONDA" / "GUARD POST"). Player text never goes into a texture.
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
NAME = "PosRonda"
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

# Material -> palette token (ART.md §3). Dominant hues: daun roof, malam posts, kertas walls.
#   Seng, Hijau   daun            Tiang     malam             Plester, Plafon  kertas
#   Roster        kertas + tinta holes      Beton    tinta_lembut..kertas
#   Kayu          tinta_lembut    Bambu     bambu             PapanNama tinta_lembut
#   Lampu         senja

# ---------------------------------------------------------------------------------------------
# Dimensions (studs). Avatar is about 5.5 studs tall.
# ---------------------------------------------------------------------------------------------
PX, PY = 13.0, 8.0  # platform half width / half depth
FLOOR = 1.2  # platform top
WALL_TOP = 10.1
CEIL = 10.1  # underside of the ceiling boards
EAVE_X, EAVE_Y0, EAVE_Y1 = 14.5, -9.1, 9.6  # roof eave rectangle (x half, back y, front y)
EAVE_Z = 10.9
RIDGE_Z = 13.0
POST = 1.0  # post width
BASE = 1.4  # post footing width
BASE_TOP = FLOOR + 2.0

BMS = {}


def bm_for(mat):
    if mat not in BMS:
        BMS[mat] = bmesh.new()
    return BMS[mat]


def box(mat, x0, x1, y0, y1, z0, z1):
    c = Vector(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    s = (abs(x1 - x0), abs(y1 - y0), abs(z1 - z0))
    bmesh.ops.create_cube(bm_for(mat), size=1.0, matrix=Matrix.Translation(c) @ Matrix.Diagonal((*s, 1.0)))


def beam(mat, p0, p1, w, h):
    """Box from p0 to p1; w is the horizontal width, h the thickness perpendicular to both."""
    p0, p1 = Vector(p0), Vector(p1)
    d = p1 - p0
    x = d / d.length
    ref = Vector((0, 0, 1)) if abs(x.z) < 0.99 else Vector((0, 1, 0))
    y = ref.cross(x).normalized()
    z = x.cross(y)
    rot = Matrix((x, y, z)).transposed().to_4x4()
    m = Matrix.Translation((p0 + p1) / 2) @ rot @ Matrix.Diagonal((d.length, w, h, 1.0))
    bmesh.ops.create_cube(bm_for(mat), size=1.0, matrix=m)


def cylinder(mat, centre, radius, depth, segments=10, r_top=None):
    bmesh.ops.create_cone(
        bm_for(mat),
        cap_ends=True,
        cap_tris=False,
        segments=segments,
        radius1=radius,
        radius2=radius if r_top is None else r_top,
        depth=depth,
        matrix=Matrix.Translation(Vector(centre)),
    )


def sphere(mat, centre, radius):
    bmesh.ops.create_uvsphere(bm_for(mat), u_segments=10, v_segments=6, radius=radius, matrix=Matrix.Translation(Vector(centre)))


def post(x, y, z_top, footing=True):
    if footing:
        box("Plester", x - BASE / 2, x + BASE / 2, y - BASE / 2, y + BASE / 2, FLOOR, BASE_TOP)
    z0 = BASE_TOP if footing else FLOOR
    box("Tiang", x - POST / 2, x + POST / 2, y - POST / 2, y + POST / 2, z0, z_top)


def roof_z(y):
    """Top of the front roof slope at depth y (front half only)."""
    ridge_y = (EAVE_Y0 + EAVE_Y1) / 2
    return EAVE_Z + (EAVE_Y1 - y) / (EAVE_Y1 - ridge_y) * (RIDGE_Z - EAVE_Z)


def build_geometry():
    # --- platform and steps (beton)
    box("Beton", -PX, PX, -PY, PY, 0.0, FLOOR)
    box("Beton", -4.5, 4.5, PY, PY + 1.0, 0.0, FLOOR * 2 / 3)
    box("Beton", -4.5, 4.5, PY + 1.0, PY + 2.0, 0.0, FLOOR / 3)

    # --- back wall with two bands of ventilation blocks (roster)
    wy0, wy1 = -PY + 0.4, -PY + 1.0
    wx = PX - 0.4
    band = (7.0, 8.4)
    gaps = [(-9.0, -1.2), (1.2, 9.0)]
    box("Plester", -wx, wx, wy0, wy1, FLOOR, band[0])
    box("Plester", -wx, wx, wy0, wy1, band[1], WALL_TOP)
    edges = [-wx] + [e for g in gaps for e in g] + [wx]
    for a, b in zip(edges[0::2], edges[1::2]):
        box("Plester", a, b, wy0, wy1, band[0], band[1])
    for a, b in gaps:
        box("Roster", a, b, wy0 + 0.1, wy1 - 0.1, band[0], band[1])

    # --- side walls: plaster to 7, timber slat screen above
    side_end = 2.0
    for sx in (-1, 1):
        x0, x1 = sorted((sx * (PX - 1.0), sx * (PX - 0.4)))
        box("Plester", x0, x1, wy1, side_end, FLOOR, 7.0)
        xm = (x0 + x1) / 2
        box("Bambu", x0 + 0.1, x1 - 0.1, wy1, side_end, 7.0, 7.25)
        box("Bambu", x0 + 0.1, x1 - 0.1, wy1, side_end, WALL_TOP - 0.25, WALL_TOP)
        y = wy1 + 0.35
        while y < side_end - 0.3:
            box("Bambu", xm - 0.12, xm + 0.12, y, y + 0.28, 7.25, WALL_TOP - 0.25)
            y += 0.6

    # --- posts (malam blue) on white concrete footings
    front_y = PY - 1.0
    for x in (-(PX - 0.9), -5.6, 5.6, PX - 0.9):
        post(x, front_y, CEIL)
    for sx in (-1, 1):
        post(sx * (PX - 0.7), side_end + 0.3, CEIL)
        post(sx * (PX - 0.7), wy0 + 0.2, CEIL, footing=False)

    # --- ceiling boards (plafon), ring beam and green fascia (lisplang)
    box("Plafon", -EAVE_X + 0.2, EAVE_X - 0.2, EAVE_Y0 + 0.2, EAVE_Y1 - 0.2, CEIL, CEIL + 0.2)
    box("Kayu", -PX + 0.3, PX - 0.3, front_y - 0.35, front_y + 0.35, CEIL - 0.6, CEIL)
    fz0, fz1 = CEIL - 0.1, EAVE_Z - 0.02
    box("Hijau", -EAVE_X, EAVE_X, EAVE_Y1 - 0.3, EAVE_Y1, fz0, fz1)
    box("Hijau", -EAVE_X, EAVE_X, EAVE_Y0, EAVE_Y0 + 0.3, fz0, fz1)
    for sx in (-1, 1):
        x0, x1 = sorted((sx * EAVE_X, sx * (EAVE_X - 0.3)))
        box("Hijau", x0, x1, EAVE_Y0 + 0.3, EAVE_Y1 - 0.3, fz0, fz1)

    # --- low hip roof in corrugated steel (seng), closed solid
    ridge_y = (EAVE_Y0 + EAVE_Y1) / 2
    ridge_half = EAVE_X - (EAVE_Y1 - EAVE_Y0) / 2
    t = 0.25
    bm = bm_for("Seng")
    ov = 0.25  # sheets overhang the fascia
    pts = [
        (-EAVE_X - ov, EAVE_Y0 - ov, EAVE_Z),
        (EAVE_X + ov, EAVE_Y0 - ov, EAVE_Z),
        (EAVE_X + ov, EAVE_Y1 + ov, EAVE_Z),
        (-EAVE_X - ov, EAVE_Y1 + ov, EAVE_Z),
        (-ridge_half, ridge_y, RIDGE_Z),
        (ridge_half, ridge_y, RIDGE_Z),
    ]
    top = [bm.verts.new(p) for p in pts]
    bot = [bm.verts.new(Vector(p) - Vector((0, 0, t))) for p in pts]
    e0, e1, e2, e3, r0, r1 = range(6)
    for f in ((e3, e2, r1, r0), (e1, e0, r0, r1), (e2, e1, r1), (e0, e3, r0)):
        bm.faces.new([top[i] for i in f])
        bm.faces.new([bot[i] for i in reversed(f)])
    for a, b in ((e0, e1), (e1, e2), (e2, e3), (e3, e0)):
        bm.faces.new((top[b], top[a], bot[a], bot[b]))
    lift = Vector((0, 0, 0.12))
    beam("Hijau", Vector(pts[r0]) + lift - Vector((0.3, 0, 0)), Vector(pts[r1]) + lift + Vector((0.3, 0, 0)), 0.6, 0.3)
    for r, es in ((pts[r0], (pts[e0], pts[e3])), (pts[r1], (pts[e1], pts[e2]))):
        for e in es:
            beam("Hijau", Vector(r) + lift, Vector(e) + lift, 0.5, 0.25)

    # --- sign board on the front slope, blank face for a SurfaceGui (Strings.jail_title)
    sy1 = 4.6  # front face of the board
    sy0 = sy1 - 0.5
    sz0, sz1 = roof_z(sy0) - 0.2, roof_z(sy0) + 3.6
    # timber frame around a plank panel; the panel is the SurfaceGui target, its front face is
    # recessed 0.1 behind the frame
    box("Kayu", -7.2, 7.2, sy0, sy1, sz0, sz0 + 0.4)
    box("Kayu", -7.2, 7.2, sy0, sy1, sz1 - 0.35, sz1)
    box("Kayu", -7.2, -6.8, sy0, sy1, sz0 + 0.4, sz1 - 0.35)
    box("Kayu", 6.8, 7.2, sy0, sy1, sz0 + 0.4, sz1 - 0.35)
    box("PapanNama", -6.8, 6.8, sy0, sy1 - 0.1, sz0 + 0.4, sz1 - 0.35)
    for sx in (-1, 1):
        x = sx * 5.5
        box("Kayu", x - 0.25, x + 0.25, sy0 - 0.6, sy0, roof_z(sy0 - 0.6) - 0.3, sz1 - 0.3)
        beam("Kayu", (x, sy0 - 0.3, sz1 - 1.0), (x, sy0 - 2.6, roof_z(sy0 - 2.6) - 0.1), 0.3, 0.3)

    # --- furniture: bench with backrest, table and chair, notice board, hanging lamp
    seat = FLOOR + 1.9
    bx0, bx1, by0, by1 = -6.5, -0.5, wy1 + 0.4, wy1 + 1.8
    box("Kayu", bx0, bx1, by0, by1, seat - 0.3, seat)
    for lx in (bx0 + 0.3, bx1 - 0.3):
        box("Kayu", lx - 0.18, lx + 0.18, by0 + 0.1, by0 + 0.45, FLOOR, seat - 0.3)
        box("Kayu", lx - 0.18, lx + 0.18, by1 - 0.45, by1 - 0.1, FLOOR, seat - 0.3)
        box("Kayu", lx - 0.18, lx + 0.18, by0 - 0.05, by0 + 0.25, seat, seat + 2.4)
    for z in (seat + 0.8, seat + 1.6):
        box("Kayu", bx0, bx1, by0 - 0.05, by0 + 0.2, z, z + 0.6)
    # a cardboard box under the bench end, like the reference
    box("Bambu", bx1 + 0.4, bx1 + 1.6, by0 + 0.4, by0 + 1.4, FLOOR, FLOOR + 1.0)

    top_z = FLOOR + 3.0
    tx0, tx1, ty0, ty1 = 3.0, 8.0, -2.0, 0.8
    box("Kayu", tx0, tx1, ty0, ty1, top_z - 0.25, top_z)
    for lx in (tx0 + 0.3, tx1 - 0.3):
        for ly in (ty0 + 0.3, ty1 - 0.3):
            box("Kayu", lx - 0.2, lx + 0.2, ly - 0.2, ly + 0.2, FLOOR, top_z - 0.25)
    box("Kayu", tx0 + 0.3, tx1 - 0.3, ty0 + 0.15, ty0 + 0.35, top_z - 0.9, top_z - 0.25)
    cx0, cx1, cy0, cy1, cseat = 4.6, 6.2, ty0 - 2.2, ty0 - 0.6, FLOOR + 1.8
    box("Bambu", cx0, cx1, cy0, cy1, cseat - 0.2, cseat)
    for lx in (cx0 + 0.15, cx1 - 0.15):
        for ly in (cy0 + 0.15, cy1 - 0.15):
            box("Bambu", lx - 0.12, lx + 0.12, ly - 0.12, ly + 0.12, FLOOR, cseat - 0.2)
        box("Bambu", lx - 0.12, lx + 0.12, cy0 + 0.03, cy0 + 0.27, cseat, cseat + 2.2)
    box("Bambu", cx0, cx1, cy0, cy0 + 0.3, cseat + 1.4, cseat + 2.1)

    nx = -(PX - 1.0)  # inner face of the left side wall
    box("Kayu", nx, nx + 0.15, -5.4, -1.0, 3.8, 7.0)
    box("Bambu", nx + 0.15, nx + 0.22, -5.1, -1.3, 4.1, 6.7)
    for y0, z0, w, h in ((-4.8, 5.2, 1.0, 1.3), (-3.5, 4.6, 0.9, 1.6), (-2.3, 5.0, 0.8, 1.2), (-3.3, 6.4, 0.7, 0.2)):
        box("Plester", nx + 0.22, nx + 0.26, y0, y0 + w, z0, z0 + h)

    lamp_y = 2.5
    box("Kayu", -0.04, 0.04, lamp_y - 0.04, lamp_y + 0.04, CEIL - 1.0, CEIL)
    cylinder("Kayu", (0, lamp_y, CEIL - 1.15), 0.55, 0.3, segments=12, r_top=0.15)
    sphere("Lampu", (0, lamp_y, CEIL - 1.5), 0.3)

    # --- kentongan (bamboo slit drum) hanging on the right inner front post
    kx, ky = 5.6 + POST / 2 + 0.45, front_y
    box("Kayu", kx - 0.03, kx + 0.03, ky - 0.03, ky + 0.03, 7.9, 8.6)
    cylinder("Bambu", (kx, ky, 6.6), 0.38, 2.6, segments=10)
    box("Kayu", kx - 0.1, kx + 0.1, ky + 0.3, ky + 0.42, 5.9, 7.3)


# ---------------------------------------------------------------------------------------------
# UVs: one 0..1 projection per object with uniform texel density. Vertical faces map
# (along-wall, z), horizontal faces (x, y), sloped faces (along-eave, distance up the slope).
# ---------------------------------------------------------------------------------------------
def compute_uvs(bm):
    bm.normal_update()
    uv = bm.loops.layers.uv.verify()
    cos = [v.co for v in bm.verts]
    cx = (min(c.x for c in cos) + max(c.x for c in cos)) / 2
    cy = (min(c.y for c in cos) + max(c.y for c in cos)) / 2
    zmin = min(c.z for c in cos)
    raw, span = [], 0.0
    for f in bm.faces:
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
        uu = u / size + 0.5
        vv = v / size + (0.5 if centred else 0.0)
        loop[uv].uv = (min(1.0, max(0.0, uu)), min(1.0, max(0.0, vv)))
    return size


# ---------------------------------------------------------------------------------------------
# Procedural textures (numpy): rows = v from the bottom, cols = u, sRGB 0..1. Each texture's
# average colour is its palette swatch.
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


def tex_seng(res, size):
    u, v = grid(res, size)
    wave = 0.5 + 0.5 * np.sin(u * 2 * math.pi / 0.55)  # corrugations run down the slope
    shade = (0.72 + 0.28 * wave) * (0.9 + 0.12 * fbm(res, res, 8, 8, 4, 11))
    sheet = (v % 4.0) < 0.08  # sheet overlaps
    shade = np.where(sheet, shade * 0.75, shade)
    base = colour(P["daun"], shade)
    rust = smoothstep(0.66, 0.8, fbm(res, res, 12, 12, 4, 12)) * 0.35
    return mix(base, P["tinta_lembut"], rust)


def tex_hijau(res, size):
    shade = (0.92 + 0.08 * vnoise(res, res, int(size * 4), 4, 21)) * (0.9 + 0.12 * fbm(res, res, 10, 10, 4, 22))
    return colour(P["daun"], shade)


def tex_tiang(res, size):
    shade = (0.93 + 0.07 * vnoise(res, res, 4, int(size * 5), 31)) * (0.9 + 0.12 * fbm(res, res, 10, 10, 4, 32))
    base = colour(P["malam"], shade)
    chip = smoothstep(0.8, 0.86, fbm(res, res, 16, 16, 4, 33))
    return mix(base, P["kertas"], chip * 0.7)


def tex_plester(res, size):
    u, v = grid(res, size)
    shade = (0.9 + 0.12 * fbm(res, res, 24, 24, 4, 41)) * (0.92 + 0.1 * fbm(res, res, 5, 5, 3, 42))
    base = colour(P["kertas"], shade)
    # rain streaks and splash dirt near the floor
    streak = smoothstep(0.7, 0.95, vnoise(res, res, int(size * 3), 2, 43)) * 0.07
    dirt = (1 - smoothstep(0.0, 1.6, v)) * (0.5 + 0.5 * fbm(res, res, 30, 8, 3, 44)) * 0.45
    return mix(base, P["tinta_lembut"], np.clip(streak + dirt, 0, 1))


def tex_plafon(res, size):
    u, v = grid(res, size)
    fv = (v / 1.2) % 1
    shade = np.where((fv < 0.04), 0.7, 1.0) * (0.92 + 0.1 * fbm(res, res, 6, 20, 3, 51))
    return colour(P["kertas"], shade)


def tex_roster(res, size):
    u, v = grid(res, size)
    cell = 1.2
    fu, fv = (u / cell) % 1 - 0.5, (v / cell) % 1 - 0.5
    r = np.sqrt(fu * fu + fv * fv)
    ang = np.arctan2(fv, fu)
    petal = r < 0.18 + 0.16 * np.abs(np.cos(2 * ang))  # four-petal flower hole
    hub = r < 0.07
    frame = (np.abs(fu) > 0.45) | (np.abs(fv) > 0.45)
    shade = (0.9 + 0.12 * fbm(res, res, 16, 16, 3, 61)) * np.where(frame, 0.85, 1.0)
    block = colour(P["kertas"], shade)
    hole = (petal & ~hub)[..., None]
    return np.where(hole, P["tinta"], block)


def tex_beton(res, size):
    u, v = grid(res, size)
    shade = (0.88 + 0.15 * fbm(res, res, 20, 20, 5, 71)) * (0.9 + 0.12 * fbm(res, res, 4, 4, 3, 72))
    base = colour(mix(P["tinta_lembut"], P["kertas"], 0.78), shade)
    joints = ((u % 4.0) < 0.05) | ((v % 4.0) < 0.05)
    return np.where(joints[..., None], mix(P["tinta_lembut"], P["kertas"], 0.3), base)


def tex_kayu(res, size):
    u, v = grid(res, size)
    grain = vnoise(res, res, int(size * 8), 3, 81)
    shade = (0.86 + 0.14 * (0.5 + 0.5 * np.sin(u * 30 + grain * 8))) * (0.85 + 0.2 * fbm(res, res, 8, 8, 4, 82))
    return colour(P["tinta_lembut"], shade)


def tex_bambu(res, size):
    u, v = grid(res, size)
    grain = vnoise(res, res, int(size * 6), 3, 91)
    shade = (0.88 + 0.12 * (0.5 + 0.5 * np.sin(u * 24 + grain * 6))) * (0.88 + 0.16 * fbm(res, res, 8, 8, 3, 92))
    node = ((v % 1.3) < 0.06)  # bamboo nodes on the kentongan and slats
    shade = np.where(node, shade * 0.75, shade)
    return colour(P["bambu"], shade)


def tex_papan_nama(res, size):
    u, v = grid(res, size)
    fv = (v / 0.7) % 1
    plank = np.floor(v / 0.7)
    grain = vnoise(res, res, int(size * 6), 4, 101)
    shade = (0.85 + 0.15 * (0.5 + 0.5 * np.sin(v * 28 + grain * 7))) * (0.85 + 0.25 * hash2(plank, plank * 7, 102))
    shade = np.where(fv < 0.05, shade * 0.5, shade)
    # weathered timber like the reference sign: tinta_lembut warmed toward bambu
    return colour(mix(P["tinta_lembut"], P["bambu"], 0.35), shade)


def tex_lampu(res, size):
    return np.ones((res, res, 3)) * P["senja"]


MATERIALS = {
    # name: (texture fn, resolution, roughness)
    "Seng": (tex_seng, 1024, 0.45),
    "Hijau": (tex_hijau, 256, 0.6),
    "Tiang": (tex_tiang, 512, 0.6),
    "Plester": (tex_plester, 512, 0.9),
    "Plafon": (tex_plafon, 512, 0.9),
    "Roster": (tex_roster, 512, 0.9),
    "Beton": (tex_beton, 512, 0.85),
    "Kayu": (tex_kayu, 512, 0.75),
    "Bambu": (tex_bambu, 512, 0.75),
    "PapanNama": (tex_papan_nama, 512, 0.75),
    "Lampu": (tex_lampu, 64, 0.4),
}


def save_texture(name, arr):
    os.makedirs(TEX_DIR, exist_ok=True)
    h, w, _ = arr.shape
    img = bpy.data.images.new(f"{NAME}_{name}", w, h, alpha=False)
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(arr, 0.0, 1.0)
    img.pixels.foreach_set(rgba.ravel())
    path = os.path.join(TEX_DIR, f"pos_ronda_{name.lower()}.png")
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

    build_geometry()

    allv = [v.co for bm in BMS.values() for v in bm.verts]
    off = Vector(
        (
            -(min(c.x for c in allv) + max(c.x for c in allv)) / 2,
            -(min(c.y for c in allv) + max(c.y for c in allv)) / 2,
            -min(c.z for c in allv),
        )
    )

    report = {}
    coll = bpy.data.collections.new(NAME)
    scene.collection.children.link(coll)
    for name, bm in BMS.items():
        bmesh.ops.translate(bm, vec=off, verts=bm.verts)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        size = compute_uvs(bm)
        fn, res, rough = MATERIALS[name]
        mat = make_material(name, save_texture(name, fn(res, size)), rough)
        mesh = bpy.data.meshes.new(f"{NAME}_{name}")
        bm.to_mesh(mesh)
        bm.free()
        centre = sum((v.co for v in mesh.vertices), Vector()) / len(mesh.vertices)
        mesh.transform(Matrix.Translation(-centre))
        mesh.materials.append(mat)
        obj = bpy.data.objects.new(f"{NAME}_{name}", mesh)
        obj.location = centre
        coll.objects.link(obj)
        report[name] = len(mesh.polygons)

    blend_path = os.path.join(HERE, "pos_ronda.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.file.make_paths_relative()
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(HERE, "pos_ronda.fbx"),
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

    mins, maxs = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for obj in coll.objects:
        for corner in obj.bound_box:
            w = obj.matrix_world @ Vector(corner)
            mins, maxs = Vector(map(min, mins, w)), Vector(map(max, maxs, w))
    print("POS_RONDA_TRIS", report, "total", sum(report.values()))
    print("POS_RONDA_SIZE", tuple(round(maxs[i] - mins[i], 2) for i in range(3)))


main()
