"""Build `proyek_mangkrak`, the abandoned village construction project, for Juragan Desa.

Run from the repository root:

    blender --background --factory-startup --python assets/proyek_mangkrak/build_proyek_mangkrak.py

Writes, next to this script:
    proyek_mangkrak.blend      editable source (textures linked, not packed)
    proyek_mangkrak.fbx        Roblox import file (textures embedded)
    textures/*.png             generated textures (own work, no third-party source)

Concept: the GPT illustration Willy generated on 2026-11-24 (prompt in the README), plus the tower
crane the illustration left out; the crane is the landmark players see from far away. A village
project opened with ceremony, paid for, then abandoned: a concrete skeleton with rebar sticking
out of half-built columns, nature taking it back, a blank project board, the ceremony stage left
behind, an empty pallet where the cement used to be (it is in Pak RT's carport).

Size: MapSpec "proyek" footprint 68 x 60. Scale against a default R15 avatar (about 5.3 studs):
ground storey 12, column tops up to about 27, crane jib at 38. 1 Blender unit = 1 stud, ground
z = 0, site centred on the origin, front (road side) facing Blender +Y = Roblox -Z after export.
No text anywhere (Strings.luau rule); `ProyekMangkrak_PapanProyek` is the blank board panel for a
SurfaceGui if the designer wants the project name or the budget on it.
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
NAME = "ProyekMangkrak"
VISUALS = os.path.join(HERE, "..", "..", "src", "shared", "Config", "Visuals.luau")


def load_palette():
    with open(VISUALS, encoding="utf-8") as fh:
        text = fh.read()
    start = text.index("Visuals.palette = {")
    block = text[start : text.index("}", start)]
    return {
        key: np.array([int(hexv[i : i + 2], 16) / 255.0 for i in (0, 2, 4)])
        for key, hexv in re.findall(r"(\w+)\s*=\s*\"([0-9a-fA-F]{6})\"", block)
    }


P = load_palette()
RNG = np.random.default_rng(2611)

# ---------------------------------------------------------------------------------------------
# Dimensions (studs)
# ---------------------------------------------------------------------------------------------
SX, SY = 34.0, 30.0  # site half width / half depth (68 x 60)
GRID_X = (-18.0, -6.0, 6.0, 18.0)  # skeleton column grid
GRID_Y = (-20.0, -9.0, 2.0)
COL = 1.6  # column width
GF_SLAB = 0.5  # ground slab top
BEAM_Z0, SLAB_Z0, SLAB_Z1 = 11.0, 12.4, 13.0  # beams under the first-floor slab
CRANE = (-23.8, -16.0)  # mast centre
MAST_TOP = 38.0
JIB_LEN, CJIB_LEN = 34.0, 10.0

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


def cube(mat, m):
    return _faces(bmesh.ops.create_cube(bm_for(mat), size=1.0, matrix=m))


def box(mat, x0, x1, y0, y1, z0, z1):
    c = Vector(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    return cube(mat, Matrix.Translation(c) @ Matrix.Diagonal((abs(x1 - x0), abs(y1 - y0), abs(z1 - z0), 1.0)))


def mbox(mat, M, x0, x1, y0, y1, z0, z1):
    """Box given in a local frame M (4x4)."""
    c = Vector(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    return cube(mat, M @ Matrix.Translation(c) @ Matrix.Diagonal((abs(x1 - x0), abs(y1 - y0), abs(z1 - z0), 1.0)))


def beam(mat, p0, p1, w, h):
    p0, p1 = Vector(p0), Vector(p1)
    d = p1 - p0
    x = d / d.length
    ref = Vector((0, 0, 1)) if abs(x.z) < 0.99 else Vector((0, 1, 0))
    y = ref.cross(x).normalized()
    z = x.cross(y)
    rot = Matrix((x, y, z)).transposed().to_4x4()
    return cube(mat, Matrix.Translation((p0 + p1) / 2) @ rot @ Matrix.Diagonal((d.length, w, h, 1.0)))


def cylinder(mat, centre, radius, depth, segments=12, r_top=None, rot=None):
    m = Matrix.Translation(Vector(centre)) @ (rot if rot is not None else Matrix.Identity(4))
    res = bmesh.ops.create_cone(
        bm_for(mat), cap_ends=True, cap_tris=False, segments=segments,
        radius1=radius, radius2=radius if r_top is None else r_top, depth=depth, matrix=m,
    )  # fmt: skip
    return _faces(res)


SWATCHES = [
    "kertas", "tinta", "tinta_lembut", "senja",
    "padi", "daun", "genteng", "merah",
    "bambu", "kunyit", "indigo", "malam",
    "genangan", "karat", "perak", "batang",
]  # fmt: skip


def swatch_rgb(token):
    derived = {
        "karat": mix(P["genteng"], P["kunyit"], 0.45),  # rusty orange (cement mixer)
        "genangan": mix(P["malam"], P["tinta"], 0.55),  # muddy puddle water
        "perak": mix(P["kertas"], P["indigo"], 0.3),
        "batang": mix(P["padi"], P["tinta_lembut"], 0.35),  # banana trunk
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


# ---------------------------------------------------------------------------------------------
# Geometry
# ---------------------------------------------------------------------------------------------
def build_ground():
    box("Tanah", -SX, SX, -SY, SY, 0.0, 0.1)
    x0, x1 = GRID_X[0] - 0.8, GRID_X[-1] + 0.8
    y0, y1 = GRID_Y[0] - 0.8, GRID_Y[-1] + 0.8
    box("Beton", x0, x1, y0, y1, 0.0, GF_SLAB)
    for px, py, w, d in ((-6.0, 12.0, 5.0, 3.0), (14.0, 8.0, 3.5, 2.2), (-14.0, -14.0, 4.0, 3.0)):
        paint("genangan", box("Warna", px - w / 2, px + w / 2, py - d / 2, py + d / 2, 0.1, 0.16))  # puddles


def rebar(x, y, z):
    for sx in (-1, 1):
        for sy in (-1, 1):
            px, py = x + sx * (COL / 2 - 0.35), y + sy * (COL / 2 - 0.35)
            h = RNG.uniform(2.2, 4.0)
            lean = Vector((RNG.uniform(-0.4, 0.4), RNG.uniform(-0.4, 0.4), 0))
            beam("Besi", (px, py, z - 0.1), Vector((px, py, z + h * 0.6)), 0.18, 0.18)
            beam("Besi", Vector((px, py, z + h * 0.6)), Vector((px, py, z + h)) + lean, 0.16, 0.16)


def vine(x, y, z0, z1, face):
    """A climbing vine strip on one face of a column, with leaf tufts."""
    nx, ny = face
    off = COL / 2 + 0.08
    cx, cy = x + nx * off, y + ny * off
    w = 0.7
    if nx:
        box("Daun", cx - 0.08, cx + 0.08, cy - w / 2, cy + w / 2, z0, z1)
    else:
        box("Daun", cx - w / 2, cx + w / 2, cy - 0.08, cy + 0.08, z0, z1)
    z = z0 + 0.8
    while z < z1 - 0.5:
        a = RNG.uniform(0, math.pi)
        p = Vector((cx, cy, z))
        tip = p + Vector((nx * 0.9 + math.cos(a) * 0.5, ny * 0.9 + math.sin(a) * 0.5, RNG.uniform(-0.3, 0.6)))
        beam("Daun", p, tip, 0.55, 0.08)
        z += RNG.uniform(1.0, 1.8)


def build_skeleton():
    # ground-storey columns and the beams + slab of the first floor
    for x in GRID_X:
        for y in GRID_Y:
            box("Beton", x - COL / 2, x + COL / 2, y - COL / 2, y + COL / 2, GF_SLAB, BEAM_Z0)
    for y in GRID_Y:
        box("Beton", GRID_X[0] - 0.7, GRID_X[-1] + 0.7, y - 0.6, y + 0.6, BEAM_Z0, SLAB_Z0)
    for x in GRID_X:
        box("Beton", x - 0.6, x + 0.6, GRID_Y[0] - 0.7, GRID_Y[-1] + 0.7, BEAM_Z0, SLAB_Z0)
    x0, x1 = GRID_X[0] - 0.8, GRID_X[-1] + 0.8
    y0, y1 = GRID_Y[0] - 0.8, GRID_Y[-1] + 0.8
    # the back-right bay was never poured: only its beams are there
    box("Beton", x0, GRID_X[2], y0, y1, SLAB_Z0, SLAB_Z1)
    box("Beton", GRID_X[2], x1, GRID_Y[1], y1, SLAB_Z0, SLAB_Z1)
    for px, py, w, d in ((-10.0, -4.0, 4.0, 2.5), (2.0, -14.0, 3.0, 2.0), (12.0, -3.0, 2.5, 1.6)):
        paint("genangan", box("Warna", px - w / 2, px + w / 2, py - d / 2, py + d / 2, SLAB_Z1, SLAB_Z1 + 0.05))

    # upper columns: stopped at different heights, rebar sticking out; two never started
    skip = {(GRID_X[3], GRID_Y[0]), (GRID_X[2], GRID_Y[0])}  # over the unpoured bay
    tops = {}
    for x in GRID_X:
        for y in GRID_Y:
            if (x, y) in skip:
                rebar(x, y, SLAB_Z1) if (x, y) == (GRID_X[2], GRID_Y[0]) else None
                continue
            top = SLAB_Z1 + RNG.choice([3.0, 5.5, 8.0, 10.5, 12.0])
            tops[(x, y)] = top
            box("Beton", x - COL / 2, x + COL / 2, y - COL / 2, y + COL / 2, SLAB_Z1, top)
            rebar(x, y, top)
    # rebar left standing out of the edge of the unpoured bay
    for x in (GRID_X[2] + 3.0, GRID_X[2] + 6.0, GRID_X[2] + 9.0):
        beam("Besi", (x, GRID_Y[1] - 0.6, SLAB_Z0 + 0.3), (x + RNG.uniform(-0.3, 0.3), GRID_Y[1] - 3.2, SLAB_Z0 + 0.1), 0.16, 0.16)

    # vines on some columns, and hanging from the slab edge
    for (x, y), face in (((GRID_X[0], GRID_Y[2]), (0, 1)), ((GRID_X[1], GRID_Y[2]), (0, 1)), ((GRID_X[3], GRID_Y[2]), (1, 0)), ((GRID_X[0], GRID_Y[1]), (-1, 0))):
        vine(x, y, GF_SLAB, BEAM_Z0 - RNG.uniform(0.0, 3.0), face)
    for (x, y), face in (((GRID_X[1], GRID_Y[2]), (0, 1)), ((GRID_X[2], GRID_Y[1]), (1, 0))):
        if (x, y) in tops:
            vine(x, y, SLAB_Z1, tops[(x, y)] - 0.5, face)
    for x in np.linspace(GRID_X[0] + 2, GRID_X[-1] - 2, 9):
        drop = RNG.uniform(1.5, 5.0)
        box("Daun", x - 0.35, x + 0.35, GRID_Y[2] + 0.75, GRID_Y[2] + 0.95, SLAB_Z0 - drop, SLAB_Z1)

    # a banana tree has grown up through the slab
    bx, by = -1.0, -6.0
    paint("batang", cylinder("Warna", (bx, by, SLAB_Z1 + 3.5), 0.65, 7.0, segments=10, r_top=0.45))
    top = Vector((bx, by, SLAB_Z1 + 7.0))
    for k in range(7):
        a = k * 2 * math.pi / 7 + RNG.uniform(-0.15, 0.15)
        d = Vector((math.cos(a), math.sin(a), 0))
        mid = top + d * 2.6 + Vector((0, 0, 1.6))
        tip = mid + d * 3.0 + Vector((0, 0, -1.4))
        beam("Daun", top, mid, 1.9, 0.14)
        beam("Daun", mid, tip, 1.7, 0.14)


def build_crane():
    """Faded yellow tower crane: lattice mast, jib over the slab, counter-jib, hook hanging low."""
    cx, cy = CRANE
    box("Beton", cx - 3.0, cx + 3.0, cy - 3.0, cy + 3.0, 0.0, 1.5)  # footing
    h = 1.1  # half mast width
    corners = [(cx - h, cy - h), (cx + h, cy - h), (cx + h, cy + h), (cx - h, cy + h)]
    for px, py in corners:
        box("Crane", px - 0.2, px + 0.2, py - 0.2, py + 0.2, 1.5, MAST_TOP)
    z, step, flip = 1.5, 3.0, 1
    while z + step <= MAST_TOP + 0.01:
        for k in range(4):
            (ax, ay), (bx, by) = corners[k], corners[(k + 1) % 4]
            beam("Crane", (ax, ay, z + step), (bx, by, z + step), 0.18, 0.18)
            if flip > 0:
                beam("Crane", (ax, ay, z), (bx, by, z + step), 0.16, 0.16)
            else:
                beam("Crane", (bx, by, z), (ax, ay, z + step), 0.16, 0.16)
        z += step
        flip = -flip
    zj = MAST_TOP
    box("Crane", cx - h - 0.3, cx + h + 0.3, cy - h - 0.3, cy + h + 0.3, zj - 0.4, zj + 0.4)  # slewing ring
    # operator cab, windows dark
    box("Crane", cx + h, cx + h + 2.4, cy - 1.4, cy + 1.4, zj - 3.0, zj - 0.4)
    paint("tinta", box("Warna", cx + h + 2.4, cx + h + 2.5, cy - 1.1, cy + 1.1, zj - 2.6, zj - 1.2))

    # jib (+X) and counter-jib (-X): two bottom chords, one top chord, zigzag diagonals
    def truss(x0, x1, top_h, seg):
        for side in (-1, 1):
            beam("Crane", (x0, cy + side * 0.9, zj), (x1, cy + side * 0.9, zj), 0.25, 0.25)
        beam("Crane", (x0, cy, zj + top_h), (x1, cy, zj + top_h), 0.25, 0.25)
        n = max(1, int(abs(x1 - x0) / seg))
        for k in range(n):
            xa = x0 + (x1 - x0) * k / n
            xb = x0 + (x1 - x0) * (k + 1) / n
            for side in (-1, 1):
                beam("Crane", (xa, cy + side * 0.9, zj), (xb, cy, zj + top_h), 0.14, 0.14)
            beam("Crane", (xb, cy - 0.9, zj), (xb, cy + 0.9, zj), 0.14, 0.14)

    truss(cx + h, cx + JIB_LEN, 1.8, 2.5)
    truss(cx - h, cx - CJIB_LEN, 1.2, 2.5)
    box("Beton", cx - CJIB_LEN - 0.2, cx - CJIB_LEN + 3.2, cy - 1.6, cy + 1.6, zj - 3.2, zj - 0.2)  # counterweights
    for k in range(3):
        x = cx - CJIB_LEN + 0.2 + k * 1.0
        paint("tinta_lembut", box("Warna", x, x + 0.05, cy - 1.62, cy + 1.62, zj - 3.2, zj - 0.2))
    # apex and tie bars
    apex = Vector((cx, cy, zj + 7.5))
    for px, py in corners:
        beam("Crane", (px, py, zj + 0.4), apex, 0.25, 0.25)
    for end in (Vector((cx + JIB_LEN * 0.65, cy, zj + 1.8)), Vector((cx - CJIB_LEN + 1.0, cy, zj + 1.2))):
        beam("Besi", apex, end, 0.12, 0.12)
    # trolley, frayed rope and a hook hanging low over the slab
    tx = cx + JIB_LEN * 0.6
    box("Crane", tx - 0.8, tx + 0.8, cy - 1.1, cy + 1.1, zj - 0.7, zj - 0.1)
    hook_z = SLAB_Z1 + 6.0
    beam("Besi", (tx - 0.25, cy, zj - 0.7), (tx - 0.25 + 0.4, cy + 0.3, hook_z + 1.2), 0.1, 0.1)
    beam("Besi", (tx + 0.25, cy, zj - 0.7), (tx + 0.25 + 0.4, cy + 0.3, hook_z + 1.2), 0.1, 0.1)
    hb = Vector((tx + 0.4, cy + 0.3, hook_z))
    paint("kunyit", box("Warna", hb.x - 0.6, hb.x + 0.6, hb.y - 0.4, hb.y + 0.4, hb.z, hb.z + 1.2))
    paint("tinta", beam("Warna", hb + Vector((0, 0, 0)), hb + Vector((0, 0, -1.0)), 0.22, 0.22))
    paint("tinta", beam("Warna", hb + Vector((0, 0, -1.0)), hb + Vector((0.6, 0, -1.4)), 0.22, 0.22))
    paint("tinta", beam("Warna", hb + Vector((0.6, 0, -1.4)), hb + Vector((0.8, 0, -0.9)), 0.22, 0.22))


def panel(M, w, h, t=0.15):
    mbox("Seng", M, -w / 2, w / 2, -t / 2, t / 2, 0.0, h)


def build_fence():
    """Rusty zinc fence on timber rails; panels standing, leaning, fallen or missing."""
    H, W = 5.2, 2.4  # low enough that players see into the site from the road
    sides = [
        ((-SX + 0.5, -SY + 0.5), (SX - 0.5, -SY + 0.5)),  # back
        ((SX - 0.5, -SY + 0.5), (SX - 0.5, SY - 0.5)),  # right
        ((SX - 0.5, SY - 0.5), (-SX + 0.5, SY - 0.5)),  # front (road)
        ((-SX + 0.5, SY - 0.5), (-SX + 0.5, -SY + 0.5)),  # left
    ]
    for si, (a, b) in enumerate(sides):
        a, b = Vector((*a, 0)), Vector((*b, 0))
        d = (b - a).normalized()
        yaw = math.atan2(d.y, d.x)
        out = Vector((d.y, -d.x, 0))  # outward normal (perimeter runs counter-clockwise from above)
        length = (b - a).length
        n = int(length / W)
        # posts and rails behind the panels
        for k in range(0, n + 1, 2):
            p = a + d * (k * W) - out * 0.3
            box("Kayu", p.x - 0.22, p.x + 0.22, p.y - 0.22, p.y + 0.22, 0.0, H - 0.6)
        for z in (1.4, H - 1.2):
            p0, p1 = a - out * 0.3 + Vector((0, 0, z)), b - out * 0.3 + Vector((0, 0, z))
            beam("Kayu", p0, p1, 0.2, 0.3)
        for k in range(n):
            centre = a + d * ((k + 0.5) * W)
            along = (k + 0.5) * W
            if si == 2 and abs((centre.x)) < 4.5:  # the way in from the road: two panels flat
                M = Matrix.Translation(centre - out * (0.3 + 0.8 * (k % 2)) + Vector((0, 0, 0.12 + 0.16 * (k % 2)))) @ Matrix.Rotation(yaw + RNG.uniform(-0.25, 0.25), 4, "Z") @ Matrix.Rotation(math.radians(-88), 4, "X")  # fell into the site
                panel(M, W, H)
                continue
            r = RNG.random()
            if r < 0.06 and along > 3:
                continue  # missing panel
            tilt = RNG.uniform(-3, 1) if r < 0.78 else -RNG.uniform(18, 32)  # negative = leaning into the site
            M = Matrix.Translation(centre - out * 0.2 + Vector((0, 0, 0.1))) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(math.radians(tilt), 4, "X")
            panel(M, W - 0.05, H - RNG.uniform(0, 0.8))


def plastic_chair(M):
    """White plastic chair in its own frame (seat 1.8 up, back toward -Y)."""
    faces = []
    faces += mbox("Warna", M, -0.9, 0.9, -0.9, 0.9, 1.7, 1.9)
    faces += mbox("Warna", M, -0.9, 0.9, -1.0, -0.8, 1.9, 3.8)
    for sx in (-1, 1):
        for sy in (-1, 1):
            faces += mbox("Warna", M, sx * 0.8 - 0.1, sx * 0.8 + 0.1, sy * 0.8 - 0.1, sy * 0.8 + 0.1, 0.0, 1.7)
        faces += mbox("Warna", M, sx * 0.95 - 0.08, sx * 0.95 + 0.08, -0.8, 0.8, 2.4, 2.55)  # arms
    paint("kertas", faces)


def build_stage():
    """Leftover opening-ceremony stage: low platform, red cloth, bunting, chairs knocked over."""
    x0, x1, y0, y1 = -29.0, -18.0, 9.0, 17.0
    box("Kayu", x0, x1, y0, y1, 0.0, 1.2)
    paint("merah", box("Warna", x0 + 0.2, x1 - 0.2, y0 + 0.2, y1 - 0.2, 1.2, 1.26))
    for px in (x0 + 0.3, x1 - 0.3):
        for py, ht in ((y0 + 0.3, 8.0), (y1 - 0.3, 7.0)):
            box("Kayu", px - 0.2, px + 0.2, py - 0.2, py + 0.2, 1.2, ht)
    # sagging red-and-white bunting along the front, and a torn piece hanging down
    xs = np.linspace(x0 + 0.3, x1 - 0.3, 9)
    for k in range(len(xs) - 1):
        za = 6.8 - 0.9 * math.sin(math.pi * k / (len(xs) - 1))
        zb = 6.8 - 0.9 * math.sin(math.pi * (k + 1) / (len(xs) - 1))
        paint("merah" if k % 2 == 0 else "kertas", beam("Warna", (xs[k], y1 - 0.3, za), (xs[k + 1], y1 - 0.3, zb), 0.12, 0.9))
    for px in (x0 + 0.3, x1 - 0.3):  # drapes at the corners
        paint("kertas", box("Warna", px - 0.5, px + 0.5, y1 - 0.45, y1 - 0.35, 3.0, 7.2))
    paint("merah", beam("Warna", (x1 - 2.0, y1 - 0.3, 6.4), (x1 - 2.4, y1 + 0.3, 3.4), 0.5, 0.06))  # torn strip
    # two plastic chairs knocked over on the stage
    plastic_chair(Matrix.Translation((x0 + 3.0, y0 + 3.5, 1.26 + 1.0)) @ Matrix.Rotation(0.5, 4, "Z") @ Matrix.Rotation(math.radians(-90), 4, "X"))
    plastic_chair(Matrix.Translation((x0 + 7.0, y0 + 4.0, 1.26 + 0.9)) @ Matrix.Rotation(-0.9, 4, "Z") @ Matrix.Rotation(math.radians(90), 4, "Y"))


def build_props():
    # project information board: blank (SurfaceGui target), a corner peeling off
    bx, by = 10.0, 22.0
    for px in (bx - 5.6, bx + 5.6):
        box("Kayu", px - 0.3, px + 0.3, by - 0.3, by + 0.3, 0.0, 10.4)
    box("Kayu", bx - 6.6, bx + 6.6, by - 0.35, by - 0.15, 3.6, 10.4)  # frame back
    box("PapanProyek", bx - 6.2, bx + 6.2, by - 0.15, by + 0.05, 4.0, 10.0)
    M = Matrix.Translation((bx + 5.4, by + 0.15, 9.2)) @ Matrix.Rotation(math.radians(35), 4, "X") @ Matrix.Rotation(math.radians(20), 4, "Y")
    paint("kertas", mbox("Warna", M, -0.8, 0.8, -0.03, 0.03, -0.8, 0.8))

    # empty pallet where the aid cement was; one torn sack left
    px, py = -10.0, 10.0
    for k in range(5):
        x = px - 2.6 + k * 1.3
        box("Kayu", x - 0.45, x + 0.45, py - 1.8, py + 1.8, 0.45, 0.65)
    for y in (py - 1.5, py, py + 1.5):
        box("Kayu", px - 3.1, px + 3.1, y - 0.3, y + 0.3, 0.1, 0.45)
    M = Matrix.Translation((px + 0.8, py - 0.3, 0.65)) @ Matrix.Rotation(0.4, 4, "Z")
    paint("kertas", mbox("Warna", M, -1.3, 1.3, -0.85, 0.85, 0.0, 0.5))
    paint("kertas", mbox("Warna", M @ Matrix.Rotation(-0.35, 4, "Y"), 1.0, 1.9, -0.6, 0.6, 0.0, 0.08))  # torn flap
    paint("tinta_lembut", mbox("Warna", M, -1.1, -0.3, -0.86, -0.84, 0.05, 0.45))  # spilt grey

    # rusty cement mixer
    mx, my = -2.0, 11.0
    tilt = Matrix.Rotation(math.radians(55), 4, "Y")
    paint("karat", cylinder("Warna", (mx, my, 3.2), 1.6, 2.6, segments=14, r_top=0.8, rot=tilt))
    paint("tinta", box("Warna", mx - 2.2, mx + 2.2, my - 0.2, my + 0.2, 1.2, 1.6))
    for sx in (-1, 1):
        paint("tinta", beam("Warna", (mx + sx * 1.6, my, 1.4), (mx + sx * 0.6, my, 3.6), 0.25, 0.25))
    wheel = Matrix.Rotation(math.pi / 2, 4, "X")
    for sy in (-1, 1):
        paint("tinta", cylinder("Warna", (mx - 1.2, my + sy * 1.2, 0.8), 0.8, 0.35, segments=12, rot=wheel))
    paint("tinta", beam("Warna", (mx + 2.2, my, 1.4), (mx + 4.0, my, 0.2), 0.25, 0.25))  # tow bar

    # wheelbarrow tipped over
    M = Matrix.Translation((4.5, 12.0, 0.0)) @ Matrix.Rotation(0.7, 4, "Z")
    paint("genteng", mbox("Warna", M @ Matrix.Translation((0, 0, 1.0)) @ Matrix.Rotation(math.radians(160), 4, "X"), -1.1, 1.1, -1.5, 1.5, -0.5, 0.5))
    paint("tinta", cylinder("Warna", (M @ Vector((0, 2.2, 0.6)))[:], 0.6, 0.3, segments=10, rot=Matrix.Rotation(math.radians(40), 4, "Z") @ Matrix.Rotation(math.pi / 2, 4, "Y")))
    for sx in (-1, 1):
        paint("tinta", beam("Warna", M @ Vector((sx * 0.7, 2.0, 0.6)), M @ Vector((sx * 0.9, -2.6, 0.3)), 0.18, 0.18))

    # brick pile, half grown over
    for layer in range(3):
        for k in range(5 - layer):
            for j in range(2):
                x = 12.0 + k * 1.05 + layer * 0.5 + RNG.uniform(-0.05, 0.05)
                y = 6.0 + j * 0.55
                paint("genteng", box("Warna", x - 0.5, x + 0.5, y - 0.25, y + 0.25, 0.1 + layer * 0.45, 0.55 + layer * 0.45))
    for k in range(4):
        x = 11.0 + k * 1.6
        paint("genteng", box("Warna", x - 0.5, x + 0.5, 7.6 - 0.25, 7.6 + 0.25, 0.1, 0.55))

    # watchman hut by the road, empty plastic chair and a coffee glass
    hx0, hx1, hy0, hy1 = 22.0, 30.0, 8.0, 15.0
    box("Kayu", hx0, hx1, hy0, hy1, 0.0, 0.6)
    box("Kayu", hx0, hx1, hy0, hy0 + 0.3, 0.6, 7.0)
    for x in (hx0, hx1 - 0.3):
        box("Kayu", x, x + 0.3, hy0 + 0.3, hy1, 0.6, 7.0)
    for x in (hx0, hx1 - 0.3):
        box("Kayu", x, x + 0.3, hy1 - 0.3, hy1, 0.6, 7.0)
    beam("Seng", ((hx0 + hx1) / 2, hy0 - 0.6, 7.8), ((hx0 + hx1) / 2, hy1 + 0.9, 6.6), hx1 - hx0 + 1.0, 0.18)
    plastic_chair(Matrix.Translation((hx0 + 3.0, hy0 + 3.0, 0.6)) @ Matrix.Rotation(0.3, 4, "Z"))
    box("Kayu", hx0 + 5.0, hx0 + 7.0, hy0 + 1.0, hy0 + 2.6, 0.6, 2.8)  # little table
    paint("tinta", cylinder("Warna", (hx0 + 6.0, hy0 + 1.8, 3.15), 0.25, 0.7, segments=10, r_top=0.3))


def build_weeds():
    """Tall weeds and grass tufts: blades fanning from a base, never balls."""
    spots = []
    for _ in range(46):
        x, y = RNG.uniform(-SX + 2, SX - 2), RNG.uniform(-SY + 2, SY - 2)
        if abs(x - CRANE[0]) < 3.5 and abs(y - CRANE[1]) < 3.5:
            continue
        spots.append((x, y, 0.1))
    for _ in range(10):  # on the slab too
        spots.append((RNG.uniform(-17, 5), RNG.uniform(-19, 2), SLAB_Z1))
    for x, y, z in spots:
        base = Vector((x, y, z))
        for k in range(5):
            a = RNG.uniform(0, 2 * math.pi)
            tip = base + Vector((math.cos(a) * RNG.uniform(0.6, 1.2), math.sin(a) * RNG.uniform(0.6, 1.2), RNG.uniform(1.6, 3.4)))
            beam("Daun", base, tip, 0.4, 0.08)


# ---------------------------------------------------------------------------------------------
# UVs and textures
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


def colour(rgb, shade):
    shade = shade / max(1e-6, float(np.mean(shade)))
    return np.stack([shade * rgb[0], shade * rgb[1], shade * rgb[2]], axis=-1)


def mix(a, b, t):
    t = np.asarray(t)[..., None] if np.ndim(t) else t
    return a * (1 - t) + b * t


def tex_beton(res, size):
    u, v = grid(res, size)
    shade = (0.88 + 0.16 * fbm(res, res, 30, 30, 5, 11)) * (0.9 + 0.12 * fbm(res, res, 5, 5, 3, 12))
    base = colour(mix(P["kertas"], P["tinta_lembut"], 0.22), shade)
    form = ((v % 1.2) < 0.04)  # formwork board lines
    base = np.where(form[..., None], base * 0.85, base)
    streak = smoothstep(0.6, 0.9, vnoise(res, res, int(size * 2.5), 3, 13)) * 0.35  # rain streaks
    moss = smoothstep(0.66, 0.82, fbm(res, res, 10, 10, 4, 14)) * 0.35
    base = mix(base, P["tinta_lembut"], streak)
    return mix(base, mix(P["daun"], P["tinta_lembut"], 0.4), moss)


def tex_besi(res, size):
    shade = 0.85 + 0.25 * fbm(res, res, 20, 20, 4, 21)
    return colour(mix(P["genteng"], P["tinta"], 0.45), shade)


def tex_crane(res, size):
    u, v = grid(res, size)
    shade = (0.88 + 0.15 * fbm(res, res, 16, 16, 4, 31)) * (0.92 + 0.08 * vnoise(res, res, 6, 30, 32))
    base = mix(colour(P["kunyit"], shade), P["kertas"], 0.18)  # sun-faded yellow
    rust = smoothstep(0.62, 0.8, fbm(res, res, 14, 40, 4, 33)) * 0.55
    return mix(base, P["genteng"] * 0.85, rust)


def tex_seng(res, size):
    u, v = grid(res, size)
    wave = 0.5 + 0.5 * np.sin(u * 2 * math.pi / 0.6)
    shade = (0.75 + 0.25 * wave) * (0.9 + 0.12 * fbm(res, res, 8, 8, 4, 41))
    base = colour(mix(P["kertas"], P["indigo"], 0.3), shade)
    rust = smoothstep(0.5, 0.78, fbm(res, res, 10, 24, 4, 42)) * 0.6  # rusted, streaky
    return mix(base, mix(mix(P["genteng"], P["bambu"], 0.5), P["tinta_lembut"], 0.35), rust)


def tex_kayu(res, size):
    u, v = grid(res, size)
    grain = vnoise(res, res, int(size * 6), 3, 51)
    shade = (0.86 + 0.14 * (0.5 + 0.5 * np.sin(u * 24 + grain * 8))) * (0.85 + 0.2 * fbm(res, res, 8, 8, 4, 52))
    return mix(colour(P["bambu"], shade), P["tinta_lembut"], 0.3)  # weathered grey-brown


def tex_papan(res, size):
    """Blank project board: faded, water-stained, no text."""
    u, v = grid(res, size)
    shade = 0.92 + 0.1 * fbm(res, res, 12, 12, 4, 61)
    base = colour(P["kertas"], shade)
    stain = smoothstep(0.65, 0.9, vnoise(res, res, int(size * 2), 4, 62)) * 0.18
    return mix(base, P["tinta_lembut"], stain)


def tex_tanah(res, size):
    u, v = grid(res, size)
    earth = colour(mix(P["bambu"], P["tinta_lembut"], 0.35), 0.85 + 0.25 * fbm(res, res, 40, 40, 4, 71))
    grass = colour(mix(P["daun"], P["padi"], 0.4), 0.85 + 0.25 * fbm(res, res, 60, 60, 3, 72))
    cover = smoothstep(0.42, 0.55, fbm(res, res, 8, 8, 4, 73))  # weeds took most of the site
    return mix(earth, grass, cover)


def tex_daun(res, size):
    u, v = grid(res, size)
    leaves = fbm(res, res, int(size * 3), int(size * 3), 4, 81)
    tips = smoothstep(0.6, 0.75, fbm(res, res, int(size * 5), int(size * 5), 3, 82))
    return mix(colour(P["daun"], 0.7 + 0.5 * leaves), P["padi"], tips * 0.5)


def tex_warna(res, size):
    canvas = np.zeros((res, res, 3))
    cell = res // 4
    for i, token in enumerate(SWATCHES):
        r, c = i // 4, i % 4
        canvas[r * cell : (r + 1) * cell, c * cell : (c + 1) * cell] = swatch_rgb(token)
    grain = 0.95 + 0.1 * fbm(res, res, 16, 16, 3, 91)
    return np.flipud(canvas * grain[..., None])


MATERIALS = {
    "Beton": (tex_beton, 1024, 0.9),
    "Besi": (tex_besi, 256, 0.6),
    "Crane": (tex_crane, 512, 0.55),
    "Seng": (tex_seng, 1024, 0.5),
    "Kayu": (tex_kayu, 512, 0.8),
    "PapanProyek": (tex_papan, 512, 0.8),
    "Tanah": (tex_tanah, 1024, 0.95),
    "Daun": (tex_daun, 512, 0.8),
    "Warna": (tex_warna, 256, 0.6),
}


def save_texture(name, arr):
    os.makedirs(TEX_DIR, exist_ok=True)
    h, w, _ = arr.shape
    img = bpy.data.images.new(f"{NAME}_{name}", w, h, alpha=False)
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(arr, 0.0, 1.0)
    img.pixels.foreach_set(rgba.ravel())
    path = os.path.join(TEX_DIR, f"proyek_mangkrak_{name.lower()}.png")
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

    build_ground()
    build_skeleton()
    build_crane()
    build_fence()
    build_stage()
    build_props()
    build_weeds()

    # Authored with the stage at -X. Seen from the road (looking -Y) the concept has the stage on
    # the left and the watchman hut on the right, so mirror X once.
    for bm in BMS.values():
        bmesh.ops.scale(bm, vec=(-1.0, 1.0, 1.0), verts=bm.verts)
        bmesh.ops.reverse_faces(bm, faces=bm.faces[:])

    report = {}
    coll = bpy.data.collections.new(NAME)
    scene.collection.children.link(coll)
    for name, bm in BMS.items():
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

    blend_path = os.path.join(HERE, "proyek_mangkrak.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.file.make_paths_relative()
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(HERE, "proyek_mangkrak.fbx"),
        use_selection=False, object_types={"MESH"}, apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="-Z", axis_up="Y",
        mesh_smooth_type="FACE", add_leaf_bones=False, bake_anim=False,
        path_mode="COPY", embed_textures=True,
    )  # fmt: skip

    mins, maxs = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for obj in coll.objects:
        for corner in obj.bound_box:
            w = obj.matrix_world @ Vector(corner)
            mins, maxs = Vector(map(min, mins, w)), Vector(map(max, maxs, w))
    print("PROYEK_TRIS", report, "total", sum(report.values()))
    print("PROYEK_BBOX", tuple(round(a, 2) for a in mins), tuple(round(a, 2) for a in maxs))


main()
