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
        bm = bmesh.new()
        bm.loops.layers.uv.verify()
        bm.faces.layers.int.new("fixed")  # 1 = UVs set at creation, compute_uvs leaves them alone
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
    res = bmesh.ops.create_cube(bm_for(mat), size=1.0, matrix=Matrix.Translation(c) @ Matrix.Diagonal((*s, 1.0)))
    return _faces(res)


def obox(mat, centre, size, yaw=0.0):
    """Box with its own yaw (radians about Z)."""
    m = Matrix.Translation(Vector(centre)) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Diagonal((*size, 1.0))
    return _faces(bmesh.ops.create_cube(bm_for(mat), size=1.0, matrix=m))


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
    return _faces(bmesh.ops.create_cube(bm_for(mat), size=1.0, matrix=m))


def cylinder(mat, centre, radius, depth, segments=10, r_top=None):
    res = bmesh.ops.create_cone(
        bm_for(mat),
        cap_ends=True,
        cap_tris=False,
        segments=segments,
        radius1=radius,
        radius2=radius if r_top is None else r_top,
        depth=depth,
        matrix=Matrix.Translation(Vector(centre)),
    )
    return _faces(res)


def sphere(mat, centre, radius):
    res = bmesh.ops.create_uvsphere(bm_for(mat), u_segments=10, v_segments=6, radius=radius, matrix=Matrix.Translation(Vector(centre)))
    return _faces(res)


# --- small props: "Warna" is a palette swatch atlas, "Cetak" a print atlas (calendar, whiteboard,
# TV picture, gaple cards). Their faces get UVs here, at creation, instead of in compute_uvs.
SWATCHES = [
    "kertas", "tinta", "tinta_lembut", "senja",
    "padi", "daun", "genteng", "merah",
    "bambu", "kunyit", "indigo", "malam",
    "ungu", "galon", "perak", "layar",
]  # fmt: skip


def swatch_rgb(token):
    derived = {
        "galon": mix(P["malam"], P["kertas"], 0.55),  # water gallon plastic
        "perak": mix(P["kertas"], P["indigo"], 0.3),  # aluminium, chrome
        "layar": mix(P["tinta"], P["indigo"], 0.4),  # dark screen glass
    }
    return derived.get(token, P.get(token))


def swatch_uv(token):
    i = SWATCHES.index(token)
    return ((i % 4 + 0.5) / 4, 1 - (i // 4 + 0.5) / 4)


def _fix(bm, faces, fn):
    uvl = bm.loops.layers.uv.active
    fixed = bm.faces.layers.int["fixed"]
    for f in faces:
        f.normal_update()
        for loop in f.loops:
            loop[uvl].uv = fn(f, loop)
        f[fixed] = 1


def paint(token, faces, obj="Warna"):
    uv = swatch_uv(token)
    _fix(bm_for(obj), faces, lambda f, l: uv)


def sbox(token, x0, x1, y0, y1, z0, z1, obj="Warna"):
    paint(token, box(obj, x0, x1, y0, y1, z0, z1), obj)


# Print atlas regions, pixels in a 1024 canvas with a top-left origin: (x0, y0, x1, y1).
CETAK = 1024
R_BOARD = (0, 0, 1024, 512)
R_CAL = (0, 512, 384, 1024)
R_SCREEN = (384, 512, 768, 800)
R_CARD = [(384 + 64 * i, 896, 448 + 64 * i, 1024) for i in range(6)]
R_BACK = (768, 896, 832, 1024)


def decal(faces, region, normal, right, up, obj="Cetak"):
    """Map `region` onto the face pointing along `normal` (seen with `right`/`up` as the image
    axes); every other face samples the region's border pixel."""
    x0, y0, x1, y1 = region
    u0, u1 = x0 / CETAK, x1 / CETAK
    vb, vt = 1 - y1 / CETAK, 1 - y0 / CETAK
    edge = (u0 + 1.5 / CETAK, vb + 1.5 / CETAK)
    normal, right, up = Vector(normal), Vector(right), Vector(up)
    front = [f for f in faces if (f.normal_update() or True) and f.normal.dot(normal) > 0.9]
    cos = [v.co for f in front for v in f.verts]
    rs, us = [c.dot(right) for c in cos], [c.dot(up) for c in cos]
    rmin, rmax, umin, umax = min(rs), max(rs), min(us), max(us)

    def fn(f, loop):
        if f not in front:
            return edge
        a = (loop.vert.co.dot(right) - rmin) / (rmax - rmin)
        b = (loop.vert.co.dot(up) - umin) / (umax - umin)
        return (u0 + a * (u1 - u0), vb + b * (vt - vb))

    _fix(bm_for(obj), faces, fn)


def post(x, y, z_top, footing=True):
    if footing:
        box("Plester", x - BASE / 2, x + BASE / 2, y - BASE / 2, y + BASE / 2, FLOOR, BASE_TOP)
    z0 = BASE_TOP if footing else FLOOR
    box("Tiang", x - POST / 2, x + POST / 2, y - POST / 2, y + POST / 2, z0, z_top)


def build_props(table_top, table):
    """Lived-in clutter: CRT TV, water dispenser, gaple cards, Hijri calendar, night-watch
    roster on a whiteboard, ceiling fan."""
    wall_in = -PY + 1.0  # inner face of the back wall (faces +Y)
    side_in = PX - 1.0  # inner face of the right side wall (faces -X)

    # --- CRT TV on a low cabinet in the back-right corner, facing the open front
    cab = (8.8, 11.6, wall_in + 0.1, wall_in + 2.3)
    cab_top = FLOOR + 2.4
    box("Kayu", cab[0], cab[1], cab[2], cab[3], FLOOR, cab_top)
    sbox("tinta", cab[0] + 0.2, cab[1] - 0.2, cab[3], cab[3] + 0.04, FLOOR + 0.3, FLOOR + 1.1)  # open shelf
    tv = (9.0, 11.4, wall_in + 0.3, wall_in + 2.1)
    tz0, tz1 = cab_top, cab_top + 2.0
    sbox("layar", tv[0], tv[1], tv[2], tv[3], tz0, tz1)  # casing
    sbox("layar", tv[0] + 0.5, tv[1] - 0.5, wall_in + 0.05, tv[2], tz0 + 0.3, tz1 - 0.4)  # tube hump
    decal(box("Cetak", tv[0] + 0.15, tv[0] + 1.75, tv[3], tv[3] + 0.05, tz0 + 0.45, tz1 - 0.35), R_SCREEN, (0, 1, 0), (-1, 0, 0), (0, 0, 1))
    for kz in (tz1 - 0.6, tz1 - 1.05):
        sbox("perak", tv[1] - 0.45, tv[1] - 0.2, tv[3], tv[3] + 0.12, kz - 0.12, kz + 0.12)  # knobs
    sbox("tinta", tv[1] - 0.5, tv[1] - 0.15, tv[3], tv[3] + 0.02, tz0 + 0.2, tz0 + 0.75)  # speaker
    ax, ay = (tv[0] + tv[1]) / 2, (tv[2] + tv[3]) / 2
    sbox("perak", ax - 0.25, ax + 0.25, ay - 0.2, ay + 0.2, tz1, tz1 + 0.15)
    for tip in ((ax - 0.9, ay - 0.1, tz1 + 1.25), (ax + 0.8, ay + 0.15, tz1 + 1.3)):
        paint("perak", beam("Warna", (ax, ay, tz1 + 0.1), tip, 0.05, 0.05))

    # --- water dispenser with an upside-down galon, back-left corner
    dx0, dx1, dy0, dy1 = -11.7, -10.4, wall_in + 0.15, wall_in + 1.45
    dz1 = FLOOR + 3.4
    sbox("kertas", dx0, dx1, dy0, dy1, FLOOR, dz1)
    sbox("tinta", dx0 + 0.25, dx1 - 0.25, dy1, dy1 + 0.04, FLOOR + 1.3, FLOOR + 2.5)  # tap recess
    sbox("perak", dx0 + 0.25, dx1 - 0.25, dy1, dy1 + 0.3, FLOOR + 1.3, FLOOR + 1.4)  # drip tray
    sbox("merah", dx0 + 0.35, dx0 + 0.55, dy1, dy1 + 0.22, FLOOR + 2.15, FLOOR + 2.35)  # hot
    sbox("malam", dx1 - 0.55, dx1 - 0.35, dy1, dy1 + 0.22, FLOOR + 2.15, FLOOR + 2.35)  # cold
    gx, gy = (dx0 + dx1) / 2, (dy0 + dy1) / 2
    paint("galon", cylinder("Warna", (gx, gy, dz1 + 0.1), 0.3, 0.2, segments=10))
    paint("galon", cylinder("Warna", (gx, gy, dz1 + 0.25), 0.55, 0.1, segments=12, r_top=0.62))
    paint("galon", cylinder("Warna", (gx, gy, dz1 + 1.1), 0.62, 1.6, segments=12))
    paint("galon", cylinder("Warna", (gx, gy, dz1 + 2.0), 0.62, 0.2, segments=12, r_top=0.45))

    # --- gaple (domino) cards scattered over the table, plus a squared-up pile
    x0, x1, y0, y1 = table
    rng = np.random.default_rng(7)
    cz = table_top
    placed = []  # (x, y, layer)
    for i in range(16):
        cx, cy = rng.uniform(x0 + 0.6, x1 - 1.4), rng.uniform(y0 + 0.6, y1 - 0.6)
        yaw = rng.uniform(0, math.pi)
        rot = Matrix.Rotation(yaw, 3, "Z")
        # a card that overlaps earlier ones lies one card-thickness above the highest of them
        under = [layer for (px, py, layer) in placed if math.hypot(px - cx, py - cy) < 1.02]
        layer = max(under) + 1 if under else 0
        placed.append((cx, cy, layer))
        z = cz + 0.015 + layer * 0.031
        faces = obox("Cetak", (cx, cy, z), (0.45, 0.9, 0.03), yaw)
        region = R_CARD[i % 6] if rng.random() < 0.7 else R_BACK
        decal(faces, region, (0, 0, 1), rot @ Vector((1, 0, 0)), rot @ Vector((0, 1, 0)))
    pile = obox("Cetak", (x1 - 0.7, y1 - 0.8, cz + 0.13), (0.45, 0.9, 0.26), 0.15)
    rot = Matrix.Rotation(0.15, 3, "Z")
    decal(pile, R_BACK, (0, 0, 1), rot @ Vector((1, 0, 0)), rot @ Vector((0, 1, 0)))
    placed.append((x1 - 0.7, y1 - 0.8, 0))

    def free_spot(radius):
        """The point on the table top farthest from every card and earlier prop."""
        best, best_d = None, -1.0
        for sx in np.linspace(x0 + radius + 0.05, x1 - radius - 0.05, 24):
            for sy in np.linspace(y0 + radius + 0.05, y1 - radius - 0.05, 14):
                d = min(math.hypot(px - sx, py - sy) for (px, py, _) in placed)
                if d > best_d:
                    best, best_d = (float(sx), float(sy)), d
        placed.append((*best, 0))
        return best

    # --- glass of black coffee (kopi hitam) on a saucer, spoon left in
    gx, gy = free_spot(0.4)
    paint("kertas", cylinder("Warna", (gx, gy, cz + 0.025), 0.38, 0.05, segments=14, r_top=0.4))  # lepek
    glass = cylinder("Warna", (gx, gy, cz + 0.05 + 0.26), 0.17, 0.52, segments=12, r_top=0.21)
    for f in glass:
        f.normal_update()
    paint("tinta", [f for f in glass if f.normal.z < 0.9])  # coffee seen through the glass
    paint("tinta_lembut", [f for f in glass if f.normal.z >= 0.9])  # coffee surface
    paint("perak", beam("Warna", (gx + 0.05, gy, cz + 0.4), (gx + 0.3, gy + 0.08, cz + 0.85), 0.06, 0.03))

    # --- clay ashtray (asbak) with ash, butts and one cigarette still burning on the rim
    ax, ay = free_spot(0.45)
    tray = cylinder("Warna", (ax, ay, cz + 0.08), 0.36, 0.16, segments=14, r_top=0.42)
    for f in tray:
        f.normal_update()
    paint("genteng", [f for f in tray if f.normal.z < 0.9])
    paint("tinta_lembut", [f for f in tray if f.normal.z >= 0.9])  # ash bed
    for k, (ang, ln) in enumerate(((0.4, 0.22), (2.1, 0.18), (3.9, 0.2))):
        d = Vector((math.cos(ang), math.sin(ang), 0))
        p0 = Vector((ax, ay, cz + 0.19)) + d * 0.05
        paint("kertas", beam("Warna", p0, p0 + d * ln * 0.6, 0.06, 0.06))  # stubbed-out butt
        paint("bambu", beam("Warna", p0 + d * ln * 0.6, p0 + d * ln, 0.065, 0.065))  # filter
    d = Vector((math.cos(5.2), math.sin(5.2), 0))
    rim = Vector((ax, ay, cz + 0.2)) + d * 0.4
    paint("bambu", beam("Warna", rim + d * 0.05, rim - d * 0.08, 0.07, 0.07))  # filter on the rim
    paint("kertas", beam("Warna", rim - d * 0.08, rim - d * 0.42 + Vector((0, 0, -0.02)), 0.065, 0.065))
    paint("merah", beam("Warna", rim - d * 0.42 + Vector((0, 0, -0.02)), rim - d * 0.47 + Vector((0, 0, -0.025)), 0.066, 0.066))

    # --- Hijri wall calendar on the right side wall (faces -X)
    decal(box("Cetak", side_in - 0.05, side_in, -3.6, -2.1, 4.5, 6.5), R_CAL, (-1, 0, 0), (0, -1, 0), (0, 0, 1))
    sbox("tinta", side_in - 0.08, side_in, -2.9, -2.8, 6.5, 6.75)  # nail and string

    # --- whiteboard with the night-watch roster (jadwal piket ronda) on the back wall (faces +Y)
    bx0, bx1, bz0, bz1 = 2.2, 6.8, 4.4, 6.6
    sbox("perak", bx0 - 0.12, bx1 + 0.12, wall_in, wall_in + 0.12, bz0 - 0.12, bz1 + 0.12)
    decal(box("Cetak", bx0, bx1, wall_in + 0.12, wall_in + 0.16, bz0, bz1), R_BOARD, (0, 1, 0), (-1, 0, 0), (0, 0, 1))
    sbox("perak", bx0 + 0.4, bx1 - 0.4, wall_in + 0.12, wall_in + 0.4, bz0 - 0.22, bz0 - 0.12)  # tray
    sbox("malam", bx1 - 1.3, bx1 - 0.8, wall_in + 0.2, wall_in + 0.32, bz0 - 0.12, bz0 - 0.02)  # marker

    # --- ceiling fan; the blades are their own MeshPart (PosRonda_KipasBaling) so Studio can spin
    # them about their pivot, which is the fan axis
    fx, fy = 0.0, -1.5
    paint("perak", cylinder("Warna", (fx, fy, CEIL - 0.1), 0.35, 0.2, segments=12))
    sbox("perak", fx - 0.07, fx + 0.07, fy - 0.07, fy + 0.07, CEIL - 1.0, CEIL - 0.2)
    paint("kertas", cylinder("Warna", (fx, fy, CEIL - 1.2), 0.55, 0.45, segments=14, r_top=0.42))
    paint("perak", cylinder("Warna", (fx, fy, CEIL - 1.5), 0.22, 0.15, segments=10))
    for k in range(4):
        a = k * math.pi / 2
        d = Vector((math.cos(a), math.sin(a), 0))
        root = Vector((fx, fy, CEIL - 1.25))
        paint("perak", beam("KipasBaling", root + d * 0.3, root + d * 0.9, 0.18, 0.08), "KipasBaling")
        paint("bambu", beam("KipasBaling", root + d * 0.8, root + d * 2.7, 0.55, 0.06), "KipasBaling")


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

    build_props(top_z, (tx0, tx1, ty0, ty1))

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


def tex_warna(res, size):
    """4 x 4 swatch atlas (SWATCHES), each cell one flat palette colour with a little grain."""
    canvas = np.zeros((res, res, 3))
    cell = res // 4
    grain = 0.96 + 0.08 * fbm(res, res, 16, 16, 3, 121)
    for i, token in enumerate(SWATCHES):
        r, c = i // 4, i % 4
        canvas[r * cell : (r + 1) * cell, c * cell : (c + 1) * cell] = swatch_rgb(token)
    return np.flipud(canvas * grain[..., None])


# ---- print atlas: tiny raster drawing helpers on a top-left canvas ----------------------------
DIGITS = {
    "0": ("111", "101", "101", "101", "111"),
    "1": ("010", "110", "010", "010", "111"),
    "2": ("111", "001", "111", "100", "111"),
    "3": ("111", "001", "111", "001", "111"),
    "4": ("101", "101", "111", "001", "001"),
    "5": ("111", "100", "111", "001", "111"),
    "6": ("111", "100", "111", "101", "111"),
    "7": ("111", "001", "001", "001", "001"),
    "8": ("111", "101", "111", "101", "111"),
    "9": ("111", "101", "111", "001", "111"),
}


def rect(c, x0, y0, x1, y1, rgb):
    c[int(y0) : int(y1), int(x0) : int(x1)] = rgb


def disc(c, cx, cy, r, rgb):
    y0, y1 = int(max(0, cy - r - 1)), int(min(c.shape[0], cy + r + 2))
    x0, x1 = int(max(0, cx - r - 1)), int(min(c.shape[1], cx + r + 2))
    if y1 <= y0 or x1 <= x0:
        return
    yy, xx = np.mgrid[y0:y1, x0:x1]
    m = (xx - cx) ** 2 + (yy - cy) ** 2 <= r * r
    c[y0:y1, x0:x1][m] = rgb


def ring(c, cx, cy, r, w, rgb):
    y0, y1 = int(max(0, cy - r - 1)), int(min(c.shape[0], cy + r + 2))
    x0, x1 = int(max(0, cx - r - 1)), int(min(c.shape[1], cx + r + 2))
    if y1 <= y0 or x1 <= x0:
        return
    yy, xx = np.mgrid[y0:y1, x0:x1]
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    c[y0:y1, x0:x1][(d <= r) & (d >= r - w)] = rgb


def line(c, x0, y0, x1, y1, w, rgb):
    n = int(max(abs(x1 - x0), abs(y1 - y0)) / max(1.0, w * 0.4)) + 1
    for t in np.linspace(0, 1, n):
        disc(c, x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, w / 2, rgb)


def number(c, x, y, text, px, rgb):
    for k, ch in enumerate(text):
        for r, row in enumerate(DIGITS[ch]):
            for q, bit in enumerate(row):
                if bit == "1":
                    rect(c, x + k * 4 * px + q * px, y + r * px, x + k * 4 * px + (q + 1) * px, y + (r + 1) * px, rgb)


def scribble(c, x, y, w, h, rgb, rng, width=3):
    """Illegible handwriting: one marker stroke that wobbles like a word."""
    xs = np.linspace(x, x + w, max(8, int(w / 5)))
    phase, freq = rng.uniform(0, 6), rng.uniform(0.18, 0.3)
    ys = y + h / 2 + (h / 2) * np.sin(xs * freq + phase) * (0.5 + 0.5 * np.sin(xs * 0.05 + phase))
    for a in range(len(xs) - 1):
        line(c, xs[a], ys[a], xs[a + 1], ys[a + 1], width, rgb)


def draw_board(c, rng):
    x0, y0, x1, y1 = R_BOARD
    rect(c, x0, y0, x1, y1, P["kertas"])
    ink, red, green = P["malam"], P["merah"], P["daun"]
    # title: crescent moon and star, then a long red heading stroke
    disc(c, 190, 62, 30, ink)
    disc(c, 204, 52, 27, P["kertas"])
    disc(c, 236, 40, 6, P["kunyit"])
    scribble(c, 270, 40, 330, 40, red, rng, width=6)
    scribble(c, 620, 44, 180, 36, red, rng, width=6)
    # table: header row + seven nights
    gx = [60, 250, 600, 900, 964]
    gy = [120 + 46 * k for k in range(9)]
    for gxx in gx:
        line(c, gxx, gy[0], gxx, gy[-1], 4, ink)
    for gyy in gy:
        line(c, gx[0], gyy, gx[-1], gyy, 4, ink)
    for k in range(3):
        scribble(c, gx[k] + 25, gy[0] + 10, gx[k + 1] - gx[k] - 60, 24, red, rng, width=4)
    for r in range(7):
        top = gy[r + 1] + 11
        scribble(c, gx[0] + 20, top, 120 + rng.uniform(-20, 30), 22, P["tinta"], rng)
        scribble(c, gx[1] + 20, top, 140 + rng.uniform(0, 70), 22, ink, rng)
        scribble(c, gx[1] + 200, top, 100 + rng.uniform(0, 60), 22, ink, rng)
        scribble(c, gx[2] + 20, top, 120 + rng.uniform(0, 90), 22, ink, rng)
        if r < 4:  # nights already done get a tick
            cx, cy = gx[3] + 32, gy[r + 1] + 23
            line(c, cx - 14, cy, cx - 4, cy + 10, 5, green)
            line(c, cx - 4, cy + 10, cx + 16, cy - 12, 5, green)
    # border so the panel edges read as the frame
    for w in range(6):
        c[y0 + w, x0:x1] = c[y1 - 1 - w, x0:x1] = swatch_rgb("perak")
        c[y0:y1, x0 + w] = c[y0:y1, x1 - 1 - w] = swatch_rgb("perak")


def draw_calendar(c):
    x0, y0, x1, y1 = R_CAL
    paper = P["kertas"]
    rect(c, x0, y0, x1, y1, paper)
    rect(c, x0, y0, x1, y0 + 18, P["merah"])  # binding strip
    disc(c, x0 + 192, y0 + 9, 5, P["tinta"])
    # header: green panel, gold crescent and mosque, Hijri year 1448
    hy0, hy1 = y0 + 18, y0 + 190
    rect(c, x0, hy0, x1, hy1, P["daun"])
    gold = P["kunyit"]
    disc(c, x0 + 80, hy0 + 70, 40, gold)
    disc(c, x0 + 96, hy0 + 60, 37, P["daun"])
    disc(c, x0 + 250, hy0 + 108, 46, gold)  # dome
    rect(c, x0 + 204, hy0 + 108, x0 + 296, hy0 + 160, gold)
    rect(c, x0 + 236, hy0 + 128, x0 + 264, hy0 + 160, P["daun"])  # door
    for mx in (x0 + 180, x0 + 308):
        rect(c, mx, hy0 + 70, mx + 14, hy0 + 160, gold)  # minarets
        disc(c, mx + 7, hy0 + 66, 9, gold)
    line(c, x0 + 250, hy0 + 40, x0 + 250, hy0 + 64, 4, gold)
    number(c, x0 + 40, hy0 + 128, "1448", 6, P["kertas"])
    # month grid: November 2026 starts on a Sunday; Sundays red, Fridays green, today ringed
    gx0, gy0, cw, ch = x0 + 12, hy1 + 22, (x1 - x0 - 24) / 7, 60
    for col in range(7):
        tone = P["merah"] if col == 0 else P["daun"] if col == 5 else P["tinta_lembut"]
        rect(c, gx0 + col * cw + 3, hy1 + 6, gx0 + (col + 1) * cw - 3, hy1 + 16, tone)
    for day in range(1, 31):
        col, row = (day - 1) % 7, (day - 1) // 7
        tone = P["merah"] if col == 0 else P["daun"] if col == 5 else P["tinta"]
        cx, cy = gx0 + col * cw, gy0 + row * ch
        number(c, cx + 6, cy + 8, str(day), 4, tone)
        hijri = 20 + day if day <= 10 else day - 10  # 21 Jumada I .. 20 Jumada II 1448
        number(c, cx + cw - 4 - 4 * 2 * len(str(hijri)), cy + 42, str(hijri), 2, P["daun"])
        if day == 23:
            ring(c, cx + cw / 2 - 2, cy + 25, 27, 4, P["merah"])


def draw_screen(c):
    x0, y0, x1, y1 = R_SCREEN
    w, h = x1 - x0, y1 - y0
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    t = yy / h
    img = mix(P["malam"], P["indigo"], t)  # evening sky
    hill = yy > h * (0.62 - 0.1 * np.sin(xx / w * math.pi * 1.6))
    img = np.where(hill[..., None], mix(P["daun"], P["tinta"], 0.45), img)
    moon = (xx - w * 0.72) ** 2 + (yy - h * 0.3) ** 2 < (h * 0.09) ** 2
    img = np.where(moon[..., None], P["senja"], img)
    scan = 1 - 0.18 * ((yy % 4) < 1)
    nx, ny = (xx / w - 0.5) * 2, (yy / h - 0.5) * 2
    vignette = np.clip(1 - 0.55 * (nx**4 + ny**4), 0.15, 1)
    glare = 0.25 * smoothstep(0.75, 0.0, np.abs((xx / w + yy / h) - 0.7) * 4)
    img = img * (scan * vignette)[..., None] * 0.8 + glare[..., None]
    c[y0:y1, x0:x1] = img
    bezel = (np.abs(nx) > 0.94) | (np.abs(ny) > 0.92)
    c[y0:y1, x0:x1][bezel] = swatch_rgb("layar")


PIPS = {
    0: [],
    1: [(0.5, 0.5)],
    2: [(0.27, 0.27), (0.73, 0.73)],
    3: [(0.27, 0.27), (0.5, 0.5), (0.73, 0.73)],
    4: [(0.27, 0.27), (0.73, 0.27), (0.27, 0.73), (0.73, 0.73)],
    5: [(0.27, 0.27), (0.73, 0.27), (0.5, 0.5), (0.27, 0.73), (0.73, 0.73)],
    6: [(0.27, 0.22), (0.73, 0.22), (0.27, 0.5), (0.73, 0.5), (0.27, 0.78), (0.73, 0.78)],
}


def draw_cards(c):
    for (x0, y0, x1, y1), (a, b) in zip(R_CARD, ((6, 6), (3, 5), (1, 4), (2, 2), (0, 6), (5, 1))):
        rect(c, x0, y0, x1, y1, P["kertas"])
        w = x1 - x0
        line(c, x0 + 8, y0 + w, x1 - 8, y0 + w, 3, P["tinta_lembut"])
        for half, n in ((0, a), (1, b)):
            for px, py in PIPS[n]:
                tone = P["merah"] if n in (1, 4) else P["tinta"]
                disc(c, x0 + px * w, y0 + half * w + py * w, 6, tone)
    x0, y0, x1, y1 = R_BACK
    back = c[y0:y1, x0:x1]  # draw in a view so the lattice cannot spill onto the faces
    w, h = x1 - x0, y1 - y0
    rect(back, 0, 0, w, h, P["merah"])
    for k in range(-4, 8):
        line(back, k * 16, 0, k * 16 + 60, h, 2, P["kertas"])
    for side in ((0, 0, w, 4), (0, h - 4, w, h), (0, 0, 4, h), (w - 4, 0, w, h)):
        rect(back, *side, P["kertas"])


def tex_cetak(res, size):
    c = np.zeros((CETAK, CETAK, 3)) + P["tinta"]
    rng = np.random.default_rng(131)
    draw_board(c, rng)
    draw_calendar(c)
    draw_screen(c)
    draw_cards(c)
    return np.flipud(c)


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
    "Warna": (tex_warna, 256, 0.6),
    "Cetak": (tex_cetak, 1024, 0.5),
}
# objects that reuse another object's texture (same image, so one upload in Roblox)
SHARED = {"KipasBaling": "Warna"}


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
    mats = {}
    coll = bpy.data.collections.new(NAME)
    scene.collection.children.link(coll)
    for name, bm in BMS.items():
        bmesh.ops.translate(bm, vec=off, verts=bm.verts)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        size = compute_uvs(bm)
        tex_name = SHARED.get(name, name)
        if tex_name not in mats:
            fn, res, rough = MATERIALS[tex_name]
            mats[tex_name] = make_material(tex_name, save_texture(tex_name, fn(res, size)), rough)
        mat = mats[tex_name]
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
