"""Build the `rumah_desa` village house for Juragan Desa in Blender.

Run from the repository root:

    blender --background --factory-startup --python assets/rumah_desa/build_rumah_desa.py

Writes, next to this script:
    rumah_desa.blend          editable source (textures linked, not packed)
    rumah_desa.fbx            Roblox import file (textures embedded)
    textures/*.png            generated textures (own work, no third-party source)

Units: 1 Blender unit = 1 Roblox stud. Ground is z = 0, the footprint is centred on the origin,
and the front door faces Blender +Y, which the FBX exporter (forward -Z, up Y) turns into Roblox
-Z, the LookVector of an identity CFrame. One object per material, so every Roblox MeshPart gets
one texture.
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
NAME = "RumahDesa"
VISUALS = os.path.join(HERE, "..", "..", "src", "shared", "Config", "Visuals.luau")


def load_palette():
    """Read the project palette (ART.md §3) from Visuals.luau so the house never drifts from it."""
    with open(VISUALS, encoding="utf-8") as fh:
        text = fh.read()
    block = text[text.index("Visuals.palette = {") : text.index("}", text.index("Visuals.palette = {"))]
    pal = {}
    for key, hexv in re.findall(r"(\w+)\s*=\s*\"([0-9a-fA-F]{6})\"", block):
        pal[key] = np.array([int(hexv[i : i + 2], 16) / 255.0 for i in (0, 2, 4)])
    return pal


P = load_palette()

# Material -> palette token (ART.md §3). Three dominant hues: genteng, bambu/kertas, daun.
#   Genteng  genteng        Wuwung   genteng (darker)   Plester  kertas
#   Papan    bambu          Kayu     tinta_lembut       Hijau    daun (worn to bambu)
#   Batu     tinta_lembut..kertas   Tegel  merah + genteng   Kaca  indigo   Lampu  senja
# Dirt, moss and grout use tinta_lembut; nothing uses a colour outside the palette.

# ---------------------------------------------------------------------------------------------
# Dimensions (studs). Avatar is about 5.5 studs tall.
# ---------------------------------------------------------------------------------------------
BODY_X = 11.0  # half width of the walls (outer face)
BODY_Y = 8.0  # half depth of the walls (outer face)
WALL_T = 0.6
FLOOR_Z = 1.4  # top of the stone plinth, bottom of the walls
SPLIT_Z = 5.4  # plaster below, timber planks above
WALL_TOP = 12.3
PORCH_Y = 14.6  # front edge of the porch plinth
EAVE_Z = 11.4  # main roof eave (top surface)
OVERHANG = 1.6
RIDGE_Z = 19.4
ROOF_T = 0.45
PORCH_ROOF_TOP = 10.8  # porch roof centreline where it meets the front wall
PORCH_ROOF_END = 15.2  # porch roof front edge (y)
PORCH_SLOPE = math.tan(math.radians(20))

BMS = {}


def bm_for(mat):
    if mat not in BMS:
        BMS[mat] = bmesh.new()
    return BMS[mat]


def box(mat, x0, x1, y0, y1, z0, z1):
    c = Vector(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    s = (abs(x1 - x0), abs(y1 - y0), abs(z1 - z0))
    m = Matrix.Translation(c) @ Matrix.Diagonal((s[0], s[1], s[2], 1.0))
    bmesh.ops.create_cube(bm_for(mat), size=1.0, matrix=m)


def beam(mat, p0, p1, w, h):
    """Box from p0 to p1; w is the horizontal width, h the thickness perpendicular to both."""
    p0, p1 = Vector(p0), Vector(p1)
    d = p1 - p0
    length = d.length
    x = d / length
    ref = Vector((0, 0, 1)) if abs(x.z) < 0.99 else Vector((0, 1, 0))
    y = ref.cross(x).normalized()
    z = x.cross(y)
    rot = Matrix((x, y, z)).transposed().to_4x4()
    m = Matrix.Translation((p0 + p1) / 2) @ rot @ Matrix.Diagonal((length, w, h, 1.0))
    bmesh.ops.create_cube(bm_for(mat), size=1.0, matrix=m)


def frustum(mat, centre, r_bottom, r_top, depth, segments=4, spin=math.pi / 4):
    m = Matrix.Translation(Vector(centre)) @ Matrix.Rotation(spin, 4, "Z")
    bmesh.ops.create_cone(
        bm_for(mat),
        cap_ends=True,
        cap_tris=False,
        segments=segments,
        radius1=r_bottom,
        radius2=r_top,
        depth=depth,
        matrix=m,
    )


def sphere(mat, centre, radius):
    m = Matrix.Translation(Vector(centre))
    bmesh.ops.create_uvsphere(bm_for(mat), u_segments=10, v_segments=6, radius=radius, matrix=m)


# Walls are described in a local frame: u runs along the wall, n is the distance out of the outer
# face (negative = inside the wall), z is height.
WALLS = {
    "front": {"axis": "x", "plane": BODY_Y, "sign": 1, "u": (-BODY_X, BODY_X)},
    "back": {"axis": "x", "plane": -BODY_Y, "sign": -1, "u": (-BODY_X, BODY_X)},
    "right": {"axis": "y", "plane": BODY_X, "sign": 1, "u": (-BODY_Y + WALL_T, BODY_Y - WALL_T)},
    "left": {"axis": "y", "plane": -BODY_X, "sign": -1, "u": (-BODY_Y + WALL_T, BODY_Y - WALL_T)},
}


def lbox(wall, mat, u0, u1, n0, n1, z0, z1):
    p, s = wall["plane"], wall["sign"]
    a, b = p + s * n0, p + s * n1
    if wall["axis"] == "x":
        box(mat, u0, u1, min(a, b), max(a, b), z0, z1)
    else:
        box(mat, min(a, b), max(a, b), u0, u1, z0, z1)


def wall_cells(wall, openings):
    u0, u1 = wall["u"]
    us = sorted({u0, u1, *[o[0] for o in openings], *[o[1] for o in openings]})
    zs = sorted({FLOOR_Z, WALL_TOP, SPLIT_Z, *[o[2] for o in openings], *[o[3] for o in openings]})
    for i in range(len(us) - 1):
        for j in range(len(zs) - 1):
            a, b, c, d = us[i], us[i + 1], zs[j], zs[j + 1]
            mu, mz = (a + b) / 2, (c + d) / 2
            if any(o[0] < mu < o[1] and o[2] < mz < o[3] for o in openings):
                continue
            mat = "Plester" if mz < SPLIT_Z else "Papan"
            lbox(wall, mat, a, b, -WALL_T, 0.0, c, d)


def subtract(span, holes):
    segs = [span]
    for h0, h1 in holes:
        nxt = []
        for a, b in segs:
            if h1 <= a or h0 >= b:
                nxt.append((a, b))
                continue
            if h0 > a:
                nxt.append((a, h0))
            if h1 < b:
                nxt.append((h1, b))
        segs = nxt
    return [s for s in segs if s[1] - s[0] > 0.05]


def window(wall, uc, w, z0, z1):
    h = w / 2
    f = 0.3  # frame board width
    # glass and glazing bars, recessed into the wall
    lbox(wall, "Kaca", uc - h, uc + h, -0.42, -0.3, z0, z1)
    lbox(wall, "Hijau", uc - 0.08, uc + 0.08, -0.3, -0.15, z0 + f, z1 - f)
    lbox(wall, "Hijau", uc - h + f, uc + h - f, -0.3, -0.15, z1 - 1.1, z1 - 0.95)
    # frame inside the opening
    lbox(wall, "Hijau", uc - h, uc - h + f, -WALL_T, 0.12, z0, z1)
    lbox(wall, "Hijau", uc + h - f, uc + h, -WALL_T, 0.12, z0, z1)
    lbox(wall, "Hijau", uc - h + f, uc + h - f, -WALL_T, 0.12, z1 - f, z1)
    lbox(wall, "Hijau", uc - h + f, uc + h - f, -WALL_T, 0.05, z0, z0 + 0.15)
    # architrave, sill, head
    lbox(wall, "Hijau", uc - h - f, uc - h, 0.0, 0.12, z0, z1 + f)
    lbox(wall, "Hijau", uc + h, uc + h + f, 0.0, 0.12, z0, z1 + f)
    lbox(wall, "Hijau", uc - h, uc + h, 0.0, 0.12, z1, z1 + f)
    lbox(wall, "Hijau", uc - h - f - 0.2, uc + h + f + 0.2, 0.0, 0.38, z0 - 0.3, z0)
    # louvred shutters (krepyak), opened flat against the wall
    for side in (-1, 1):
        a = uc + side * (h + f)
        b = a + side * h
        s0, s1 = min(a, b), max(a, b)
        lbox(wall, "Hijau", s0, s1, 0.0, 0.12, z0, z1)
        z = z0 + 0.35
        while z + 0.22 < z1 - 0.3:
            lbox(wall, "Hijau", s0 + 0.22, s1 - 0.22, 0.12, 0.22, z, z + 0.2)
            z += 0.38


def door(wall, uc, w, z1):
    h = w / 2
    f = 0.3
    lbox(wall, "Hijau", uc - h, uc - h + f, -WALL_T, 0.12, FLOOR_Z, z1)
    lbox(wall, "Hijau", uc + h - f, uc + h, -WALL_T, 0.12, FLOOR_Z, z1)
    lbox(wall, "Hijau", uc - h + f, uc + h - f, -WALL_T, 0.12, z1 - f, z1)
    lbox(wall, "Hijau", uc - h - f, uc - h, 0.0, 0.12, FLOOR_Z + 0.1, z1 + f)
    lbox(wall, "Hijau", uc + h, uc + h + f, 0.0, 0.12, FLOOR_Z + 0.1, z1 + f)
    lbox(wall, "Hijau", uc - h, uc + h, 0.0, 0.12, z1, z1 + f)
    # two timber leaves (pintu kupu tarung) with raised panels
    for a, b in ((uc - h + f, uc - 0.03), (uc + 0.03, uc + h - f)):
        lbox(wall, "Kayu", a, b, -0.38, -0.18, FLOOR_Z + 0.1, z1 - f)
        lbox(wall, "Kayu", a + 0.3, b - 0.3, -0.18, -0.1, FLOOR_Z + 0.8, FLOOR_Z + 3.6)
        lbox(wall, "Kayu", a + 0.3, b - 0.3, -0.18, -0.1, FLOOR_Z + 4.2, z1 - f - 0.6)
    lbox(wall, "Hijau", uc - 0.35, uc - 0.12, -0.18, 0.0, FLOOR_Z + 3.7, FLOOR_Z + 4.1)
    lbox(wall, "Hijau", uc + 0.12, uc + 0.35, -0.18, 0.0, FLOOR_Z + 3.7, FLOOR_Z + 4.1)


def porch_z(y):
    """Centreline height of the porch roof slab at depth y."""
    return PORCH_ROOF_TOP - (y - BODY_Y) * PORCH_SLOPE


def build_geometry():
    # --- stone plinth, porch floor and steps
    box("Batu", -BODY_X - 0.6, BODY_X + 0.6, -BODY_Y - 0.6, PORCH_Y, 0.0, FLOOR_Z)
    box("Tegel", -BODY_X - 0.5, BODY_X + 0.5, BODY_Y, PORCH_Y - 0.1, FLOOR_Z, FLOOR_Z + 0.1)
    box("Batu", -2.8, 2.8, PORCH_Y, PORCH_Y + 0.9, 0.0, 0.95)
    box("Batu", -2.8, 2.8, PORCH_Y + 0.9, PORCH_Y + 1.8, 0.0, 0.47)

    # --- walls with openings (u0, u1, z0, z1)
    win_h = (SPLIT_Z, SPLIT_Z + 4.0)
    door_w, door_top = 4.6, 9.9
    front_windows = [-6.6, 6.6]
    back_windows = [-5.5, 5.5]
    side_windows = [0.0]
    win_w = 3.0

    def openings(centres):
        return [(c - win_w / 2, c + win_w / 2, win_h[0], win_h[1]) for c in centres]

    wall_cells(WALLS["front"], openings(front_windows) + [(-door_w / 2, door_w / 2, FLOOR_Z, door_top)])
    wall_cells(WALLS["back"], openings(back_windows))
    wall_cells(WALLS["right"], openings(side_windows))
    wall_cells(WALLS["left"], openings(side_windows))

    for c in front_windows:
        window(WALLS["front"], c, win_w, *win_h)
    for c in back_windows:
        window(WALLS["back"], c, win_w, *win_h)
    for key in ("right", "left"):
        for c in side_windows:
            window(WALLS[key], c, win_w, *win_h)
    door(WALLS["front"], 0.0, door_w, door_top)

    # --- timber trim: split band, ring beam, corner boards
    margin = win_w / 2 + 0.3 + win_w / 2 + 0.05  # window plus shutters
    band = {
        "front": [(c - margin, c + margin) for c in front_windows] + [(-door_w / 2 - 0.35, door_w / 2 + 0.35)],
        "back": [(c - margin, c + margin) for c in back_windows],
        "right": [(c - margin, c + margin) for c in side_windows],
        "left": [(c - margin, c + margin) for c in side_windows],
    }
    for key, wall in WALLS.items():
        u0, u1 = wall["u"]
        if wall["axis"] == "y":
            u0, u1 = -BODY_Y, BODY_Y
        for a, b in subtract((u0, u1), band[key]):
            lbox(wall, "Kayu", a, b, 0.0, 0.1, SPLIT_Z - 0.3, SPLIT_Z)
        r0, r1 = (-BODY_X - 0.15, BODY_X + 0.15) if wall["axis"] == "x" else (-BODY_Y, BODY_Y)
        lbox(wall, "Kayu", r0, r1, 0.0, 0.15, WALL_TOP - 0.4, WALL_TOP)
    for sx in (-1, 1):
        for sy in (-1, 1):
            xs = sorted((sx * (BODY_X - 0.4), sx * (BODY_X + 0.12)))
            ys = sorted((sy * (BODY_Y - 0.4), sy * (BODY_Y + 0.12)))
            box("Kayu", xs[0], xs[1], ys[0], ys[1], FLOOR_Z, WALL_TOP - 0.4)

    # --- main hip roof (limasan), closed solid
    ex, ey = BODY_X + OVERHANG, BODY_Y + OVERHANG
    ridge_half = ex - ey
    bm = bm_for("Genteng")
    top = [
        bm.verts.new((-ex, -ey, EAVE_Z)),
        bm.verts.new((ex, -ey, EAVE_Z)),
        bm.verts.new((ex, ey, EAVE_Z)),
        bm.verts.new((-ex, ey, EAVE_Z)),
        bm.verts.new((-ridge_half, 0, RIDGE_Z)),
        bm.verts.new((ridge_half, 0, RIDGE_Z)),
    ]
    bot = [bm.verts.new(v.co - Vector((0, 0, ROOF_T))) for v in top]
    e0, e1, e2, e3, r0, r1 = range(6)
    roof_faces = [(e3, e2, r1, r0), (e1, e0, r0, r1), (e2, e1, r1), (e0, e3, r0)]
    for f in roof_faces:
        bm.faces.new([top[i] for i in f])
        bm.faces.new([bot[i] for i in reversed(f)])
    for a, b in ((e0, e1), (e1, e2), (e2, e3), (e3, e0)):
        bm.faces.new((top[b], top[a], bot[a], bot[b]))

    # --- ridge and hip caps (wuwungan) with end crowns
    lift = Vector((0, 0, 0.2))
    beam("Wuwung", Vector((-ridge_half - 0.4, 0, RIDGE_Z)) + lift, Vector((ridge_half + 0.4, 0, RIDGE_Z)) + lift, 0.75, 0.6)
    for r, es in ((top[r0].co, (top[e0].co, top[e3].co)), (top[r1].co, (top[e1].co, top[e2].co))):
        for e in es:
            beam("Wuwung", r + lift, e + lift * 0.6, 0.55, 0.45)
    for sx in (-1, 1):
        x = sx * (ridge_half + 0.2)
        box("Wuwung", x - 0.35, x + 0.35, -0.35, 0.35, RIDGE_Z + 0.4, RIDGE_Z + 1.2)
        frustum("Wuwung", (x, 0, RIDGE_Z + 1.6), 0.45, 0.08, 0.8)

    # --- fascia boards (lisplang) on the main eaves
    fz = EAVE_Z - ROOF_T / 2
    for sy in (-1, 1):
        beam("Hijau", (-ex - 0.1, sy * (ey + 0.07), fz), (ex + 0.1, sy * (ey + 0.07), fz), 0.14, 0.6)
    for sx in (-1, 1):
        beam("Hijau", (sx * (ex + 0.07), -ey - 0.1, fz), (sx * (ex + 0.07), ey + 0.1, fz), 0.14, 0.6)

    # --- porch roof (emperan): slab, rafters, beam, posts on stone footings
    beam("Genteng", (0, BODY_Y, porch_z(BODY_Y)), (0, PORCH_ROOF_END, porch_z(PORCH_ROOF_END)), 2 * ex, 0.3)
    beam("Hijau", (-ex - 0.1, PORCH_ROOF_END + 0.07, porch_z(PORCH_ROOF_END) - 0.1), (ex + 0.1, PORCH_ROOF_END + 0.07, porch_z(PORCH_ROOF_END) - 0.1), 0.14, 0.5)
    rafter_drop = 0.16 + 0.125
    x = -ex + 0.6
    while x <= ex - 0.5:
        beam("Kayu", (x, BODY_Y, porch_z(BODY_Y) - rafter_drop), (x, PORCH_ROOF_END - 0.1, porch_z(PORCH_ROOF_END - 0.1) - rafter_drop), 0.22, 0.25)
        x += 2.0
    post_y = PORCH_Y - 0.6
    beam_top = porch_z(post_y) - rafter_drop - 0.125
    box("Kayu", -ex + 0.4, ex - 0.4, post_y - 0.25, post_y + 0.25, beam_top - 0.5, beam_top)
    lbox(WALLS["front"], "Kayu", -ex + 0.4, ex - 0.4, 0.0, 0.3, porch_z(BODY_Y) - 0.9, porch_z(BODY_Y) - 0.3)
    for px in (-BODY_X + 0.1, -3.4, 3.4, BODY_X - 0.1):
        frustum("Batu", (px, post_y, FLOOR_Z + 0.35), 0.62, 0.42, 0.5)
        box("Kayu", px - 0.23, px + 0.23, post_y - 0.23, post_y + 0.23, FLOOR_Z + 0.6, beam_top - 0.5)

    # --- porch bench (lincak) under the left window
    bx0, bx1, by0, by1, seat = -9.0, -4.4, 9.0, 10.5, FLOOR_Z + 1.9
    box("Kayu", bx0, bx1, by0, by1, seat - 0.25, seat)
    for lx in (bx0 + 0.3, bx1 - 0.3):
        for ly in (by0 + 0.25, by1 - 0.25):
            box("Kayu", lx - 0.15, lx + 0.15, ly - 0.15, ly + 0.15, FLOOR_Z + 0.1, seat - 0.25)
    box("Kayu", bx0 + 0.3, bx1 - 0.3, by0 + 0.6, by1 - 0.6, FLOOR_Z + 0.6, FLOOR_Z + 0.8)

    # --- porch bulb (lampu teras): add a warm PointLight to RumahDesa_Lampu in Studio
    ly = BODY_Y + 2.4
    cord_top = porch_z(ly) - rafter_drop - 0.12
    box("Kaca", -0.05, 0.05, ly - 0.05, ly + 0.05, cord_top - 0.6, cord_top)
    box("Kaca", -0.14, 0.14, ly - 0.14, ly + 0.14, cord_top - 0.85, cord_top - 0.6)
    sphere("Lampu", (0, ly, cord_top - 1.1), 0.28)


# ---------------------------------------------------------------------------------------------
# UVs: one 0..1 projection per object, texel density uniform. Vertical faces map (along-wall, z),
# horizontal faces map (x, y), sloped faces map (along-eave, distance up the slope).
# ---------------------------------------------------------------------------------------------
def compute_uvs(bm):
    bm.normal_update()
    uv = bm.loops.layers.uv.verify()
    cos = [v.co for v in bm.verts]
    cx = (min(c.x for c in cos) + max(c.x for c in cos)) / 2
    cy = (min(c.y for c in cos) + max(c.y for c in cos)) / 2
    zmin = min(c.z for c in cos)
    raw = []
    span = 0.0
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
# Procedural textures (numpy). Arrays are (rows = v from bottom, cols = u), sRGB 0..1.
# ---------------------------------------------------------------------------------------------
def vnoise(w, h, cx, cy, seed):
    r = np.random.default_rng(seed).random((cy + 2, cx + 2))
    tx = np.linspace(0, cx, w, endpoint=False)
    ty = np.linspace(0, cy, h, endpoint=False)
    ix, iy = tx.astype(int), ty.astype(int)
    fx, fy = tx - ix, ty - iy
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a = r[iy][:, ix]
    b = r[iy][:, ix + 1]
    c = r[iy + 1][:, ix]
    d = r[iy + 1][:, ix + 1]
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
    pps = res / size  # pixels per stud
    v, u = np.mgrid[0:res, 0:res].astype(np.float64)
    return u / pps, v / pps


def hash2(a, b, seed):
    table = np.random.default_rng(seed).random((97, 89))
    return table[np.mod(a, 97).astype(int), np.mod(b, 89).astype(int)]


def colour(rgb, shade):
    """Paint rgb modulated by shade; shade is normalised so the average pixel is the swatch."""
    shade = shade / max(1e-6, float(np.mean(shade)))
    return np.stack([shade * rgb[0], shade * rgb[1], shade * rgb[2]], axis=-1)


def mix(a, b, t):
    t = np.asarray(t)[..., None] if np.ndim(t) else t
    return a * (1 - t) + b * t


def tex_genteng(res, size):
    u, v = grid(res, size)
    tw, th = 1.3, 1.1
    col, row = np.floor(u / tw), np.floor(v / th)
    fu, fv = (u / tw) % 1, (v / th) % 1
    # rounded pan of each tile: bright crown, dark channels between tiles
    prof = 0.5 + 0.5 * np.sin(np.pi * fu) ** 0.6
    # shadow cast by the tile row above, bright lip on the row's lower edge
    shade = prof * (1 - 0.6 * smoothstep(0.72, 0.97, fv)) * (1 + 0.18 * (fv < 0.08))
    shade *= np.where((fu < 0.05) | (fu > 0.95), 0.5, 1.0)
    var = hash2(col, row, 11)
    shade *= 0.86 + 0.22 * var
    grime = fbm(res, res, 6, 6, 4, 21)
    shade *= 0.82 + 0.25 * grime
    base = colour(P["genteng"], shade)
    moss = smoothstep(0.62, 0.8, fbm(res, res, 10, 10, 3, 31)) * 0.3
    base = mix(base, P["tinta_lembut"], moss)
    base[..., 1] += (hash2(col, row, 12) - 0.5) * 0.05
    return base


def tex_wuwung(res, size):
    u, v = grid(res, size)
    seg = (u / 1.3) % 1
    shade = np.where((seg < 0.05), 0.65, 1.0) * (0.85 + 0.25 * fbm(res, res, 8, 8, 4, 41))
    return colour(P["genteng"] * 0.82, shade)


def tex_plester(res, size):
    u, v = grid(res, size)
    n = fbm(res, res, 24, 24, 4, 51)
    blot = fbm(res, res, 5, 5, 3, 52)
    shade = (0.9 + 0.12 * n) * (0.92 + 0.1 * blot)
    base = colour(P["kertas"], shade)
    dirt = (1 - smoothstep(0.0, 1.4, v)) * (0.55 + 0.45 * fbm(res, res, 30, 8, 3, 53))
    return mix(base, P["tinta_lembut"], 0.45 * dirt)


def tex_papan(res, size):
    u, v = grid(res, size)
    pw = 0.9
    plank, fu = np.floor(u / pw), (u / pw) % 1
    grain = vnoise(res, res, int(size * 6), int(size / 3) + 2, 61)
    lines = 0.5 + 0.5 * np.sin((u * 26 + grain * 6) * 1.0)
    shade = 0.82 + 0.12 * lines
    shade *= 0.8 + 0.3 * hash2(plank, plank * 3, 62)
    shade *= np.where((fu < 0.06) | (fu > 0.97), 0.45, 1.0)
    shade *= 0.88 + 0.16 * fbm(res, res, 6, 6, 3, 63)
    return colour(P["bambu"], shade)


def tex_kayu(res, size):
    u, v = grid(res, size)
    grain = vnoise(res, res, int(size * 8), 3, 71)
    shade = 0.86 + 0.14 * (0.5 + 0.5 * np.sin(u * 30 + grain * 8))
    shade *= 0.85 + 0.2 * fbm(res, res, 8, 8, 4, 72)
    return colour(P["tinta_lembut"], shade)


def tex_hijau(res, size):
    u, v = grid(res, size)
    brush = vnoise(res, res, 4, int(size * 5), 81)
    shade = (0.92 + 0.08 * brush) * (0.9 + 0.14 * fbm(res, res, 10, 10, 4, 82))
    paint = colour(P["daun"], shade)
    wear = smoothstep(0.8, 0.86, fbm(res, res, 14, 14, 4, 83))
    return mix(paint, colour(P["bambu"], shade), wear)


def tex_batu(res, size):
    pps = res / size
    g = max(4, int(pps * 0.9))
    h = w = res
    rng = np.random.default_rng(91)
    nx, ny = w // g + 3, h // g + 3
    jit = rng.random((ny, nx, 2))
    tone = rng.random((ny, nx))
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float64)
    cx, cy = (xs // g).astype(int), (ys // g).astype(int)
    d1 = np.full((h, w), 1e9)
    d2 = np.full((h, w), 1e9)
    t1 = np.zeros((h, w))
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            gx, gy = cx + ox, cy + oy
            jx, jy = jit[gy + 1, gx + 1, 0], jit[gy + 1, gx + 1, 1]
            px, py = (gx + jx) * g, (gy + jy) * g
            d = np.sqrt(((xs - px) * 0.75) ** 2 + (ys - py) ** 2)
            closer = d < d1
            d2 = np.where(closer, d1, np.minimum(d2, d))
            t1 = np.where(closer, tone[gy + 1, gx + 1], t1)
            d1 = np.where(closer, d, d1)
    edge = smoothstep(0.0, g * 0.12, d2 - d1)
    speck = fbm(res, res, int(size * 4), int(size * 4), 2, 92)
    stone_shade = (0.85 + 0.2 * speck) * (0.85 + 0.15 * smoothstep(0, g * 0.5, d2 - d1))
    stone_shade = stone_shade / float(np.mean(stone_shade))
    # river stones: each one a different blend of tinta_lembut and kertas
    stone = mix(P["tinta_lembut"], P["kertas"], 0.15 + 0.45 * t1) * stone_shade[..., None]
    mortar = mix(P["kertas"], P["tinta_lembut"], 0.25) * (0.9 + 0.1 * speck[..., None])
    return mix(mortar, stone, edge)


def tex_tegel(res, size):
    u, v = grid(res, size)
    t = 1.6
    tu, tv = np.floor(u / t), np.floor(v / t)
    fu, fv = (u / t) % 1, (v / t) % 1
    checker = ((tu + tv) % 2)[..., None]
    base = P["merah"] * checker + (P["genteng"] * 0.85) * (1 - checker)
    shade = (0.9 + 0.15 * hash2(tu, tv, 101)) * (0.88 + 0.16 * fbm(res, res, 12, 12, 3, 102))
    base = base * (shade / float(np.mean(shade)))[..., None]
    grout = ((fu < 0.02) | (fu > 0.98) | (fv < 0.02) | (fv > 0.98))[..., None]
    return np.where(grout, P["tinta_lembut"], base)


def tex_kaca(res, size):
    u, v = grid(res, size)
    streak = smoothstep(0.55, 0.6, (0.5 + 0.5 * np.sin((u + v) * 2.2)))
    shade = 0.75 + 0.35 * (v / size) + 0.5 * streak
    return colour(P["indigo"], shade)


def tex_lampu(res, size):
    return np.ones((res, res, 3)) * P["senja"]


MATERIALS = {
    # name: (texture fn, resolution, roughness)
    "Genteng": (tex_genteng, 1024, 0.75),
    "Wuwung": (tex_wuwung, 256, 0.8),
    "Plester": (tex_plester, 512, 0.9),
    "Papan": (tex_papan, 512, 0.8),
    "Kayu": (tex_kayu, 512, 0.75),
    "Hijau": (tex_hijau, 512, 0.6),
    "Batu": (tex_batu, 512, 0.9),
    "Tegel": (tex_tegel, 512, 0.5),
    "Kaca": (tex_kaca, 256, 0.15),
    "Lampu": (tex_lampu, 64, 0.4),
}


def save_texture(name, arr):
    os.makedirs(TEX_DIR, exist_ok=True)
    h, w, _ = arr.shape
    img = bpy.data.images.new(f"{NAME}_{name}", w, h, alpha=False)
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(arr, 0.0, 1.0)
    img.pixels.foreach_set(rgba.ravel())
    path = os.path.join(TEX_DIR, f"rumah_desa_{name.lower()}.png")
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    img.filepath = path
    return img


def make_material(name, img, rough):
    mat = bpy.data.materials.new(f"{NAME}_{name}")
    try:
        mat.use_nodes = True
    except AttributeError:
        pass
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
    bpy.context.preferences.filepaths.save_version = 0  # no rumah_desa.blend1 backup
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0

    build_geometry()

    # centre the footprint on the origin, ground at z = 0
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
        img = save_texture(name, fn(res, size))
        mat = make_material(name, img, rough)

        mesh = bpy.data.meshes.new(f"{NAME}_{name}")
        bm.to_mesh(mesh)
        bm.free()
        centre = sum((v.co for v in mesh.vertices), Vector()) / len(mesh.vertices)
        mesh.transform(Matrix.Translation(-centre))
        mesh.materials.append(mat)
        obj = bpy.data.objects.new(f"{NAME}_{name}", mesh)
        obj.location = centre
        coll.objects.link(obj)
        report[name] = {"tris": len(mesh.polygons), "uv_size_studs": round(size, 2), "texture": res}

    blend_path = os.path.join(HERE, "rumah_desa.blend")
    fbx_path = os.path.join(HERE, "rumah_desa.fbx")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.file.make_paths_relative()
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.export_scene.fbx(
        filepath=fbx_path,
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

    deps = bpy.context.evaluated_depsgraph_get()
    mins = Vector((1e9, 1e9, 1e9))
    maxs = Vector((-1e9, -1e9, -1e9))
    for obj in coll.objects:
        for corner in obj.bound_box:
            w = obj.matrix_world @ Vector(corner)
            mins = Vector(map(min, mins, w))
            maxs = Vector(map(max, maxs, w))
    del deps
    total = sum(r["tris"] for r in report.values())
    print("RUMAH_DESA_REPORT", report)
    print("RUMAH_DESA_TOTAL_TRIS", total)
    print("RUMAH_DESA_BBOX", tuple(round(a, 2) for a in mins), tuple(round(a, 2) for a in maxs))


main()
