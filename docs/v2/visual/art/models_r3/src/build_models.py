#!/usr/bin/env python3
"""Deterministic low-poly OBJ generator for models_r3 DESIGNER_BUILD candidates.

Stdlib only. No random: every vertex is a literal or a closed-form function of
its arguments, so re-running produces byte-identical files. All geometry is
original (no third-party mesh data, no brand/IP marks). V-D4: tropical only,
no conifers. Budgets from VISUAL_MASTER_PLAN section 6 / V-L3.5: kit pieces
<= 2000 triangles, landmarks <= 8000 triangles.

Run from anywhere:
    python docs/v2/visual/art/models_r3/src/build_models.py
Regenerates generated/<family>/<name>.obj plus a per-family materials.mtl,
then self-verifies every emitted OBJ (face indices in range, triangle counts
within budget, no spaces in filenames).
"""

import math
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # models_r3
OUT = os.path.join(ROOT, "generated")
KIT_BUDGET = 2000
LANDMARK_BUDGET = 8000

# Flat palette; main session remaps to Roblox materials/colours later.
PALETTE = {
    "timber": (0.45, 0.30, 0.18), "dark_timber": (0.28, 0.18, 0.11),
    "seng": (0.55, 0.57, 0.58), "bamboo": (0.62, 0.70, 0.30),
    "leaf": (0.20, 0.52, 0.22), "leaf_light": (0.34, 0.64, 0.28),
    "mango": (0.16, 0.45, 0.18), "stone": (0.55, 0.55, 0.52),
    "water": (0.30, 0.55, 0.62), "cloth": (0.72, 0.30, 0.22),
    "skin": (0.78, 0.58, 0.40), "hat": (0.78, 0.68, 0.38),
    "metal": (0.42, 0.44, 0.46), "soil": (0.40, 0.30, 0.20),
}


class Mesh:
    def __init__(self, name, kind="kit"):
        self.name = name
        self.kind = kind
        self.v = []
        self.f = []
        self.parts = []  # (part_name, start_face, mat_name)

    def vert(self, x, y, z):
        self.v.append((round(x, 4), round(y, 4), round(z, 4)))
        return len(self.v)

    def tri(self, a, b, c):
        self.f.append((a, b, c))

    def quad(self, a, b, c, d):
        self.tri(a, b, c)
        self.tri(a, c, d)

    def begin(self, name, mat):
        self.parts.append([name, len(self.f), mat])

    def tris(self):
        return len(self.f)


def box(m, cx, cy, cz, sx, sy, sz, mat, name="box"):
    m.begin(name, mat)
    hx, hy, hz = sx / 2.0, sy / 2.0, sz / 2.0
    b = [m.vert(cx + dx * hx, cy + dy * hy, cz + dz * hz)
         for dx, dy, dz in ((-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
                            (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1))]
    m.quad(b[0], b[3], b[2], b[1])  # bottom
    m.quad(b[4], b[5], b[6], b[7])  # top
    m.quad(b[0], b[1], b[5], b[4])
    m.quad(b[1], b[2], b[6], b[5])
    m.quad(b[2], b[3], b[7], b[6])
    m.quad(b[3], b[0], b[4], b[7])


def cyl(m, cx, cy, cz, r, h, seg, mat, name="cyl", cap=True):
    m.begin(name, mat)
    lo = [m.vert(cx + r * math.cos(2*math.pi*i/seg), cy,
                 cz + r * math.sin(2*math.pi*i/seg)) for i in range(seg)]
    hi = [m.vert(cx + r * math.cos(2*math.pi*i/seg), cy + h,
                 cz + r * math.sin(2*math.pi*i/seg)) for i in range(seg)]
    for i in range(seg):
        j = (i + 1) % seg
        m.quad(lo[i], lo[j], hi[j], hi[i])
    if cap:
        cl = m.vert(cx, cy, cz)
        ch = m.vert(cx, cy + h, cz)
        for i in range(seg):
            j = (i + 1) % seg
            m.tri(cl, lo[j], lo[i])
            m.tri(ch, hi[i], hi[j])


def cone(m, cx, cy, cz, r, h, seg, mat, name="cone", cap=True):
    m.begin(name, mat)
    ring = [m.vert(cx + r*math.cos(2*math.pi*i/seg), cy,
                   cz + r*math.sin(2*math.pi*i/seg)) for i in range(seg)]
    apex = m.vert(cx, cy + h, cz)
    for i in range(seg):
        j = (i+1) % seg
        m.tri(ring[i], ring[j], apex)
    if cap:
        c = m.vert(cx, cy, cz)
        for i in range(seg):
            j = (i+1) % seg
            m.tri(c, ring[j], ring[i])


def blob(m, cx, cy, cz, rx, ry, rz, mat, name="blob", seg=8, rings=3):
    """Low-poly ellipsoid (no conifer silhouette)."""
    m.begin(name, mat)
    grid = []
    for k in range(rings + 1):
        phi = math.pi * k / rings
        row = []
        for i in range(seg):
            th = 2*math.pi*i/seg
            row.append(m.vert(cx + rx*math.sin(phi)*math.cos(th),
                              cy + ry*math.cos(phi),
                              cz + rz*math.sin(phi)*math.sin(th)))
        grid.append(row)
    for k in range(rings):
        for i in range(seg):
            j = (i+1) % seg
            a, b = grid[k][i], grid[k][j]
            c, d = grid[k+1][j], grid[k+1][i]
            if k == 0:
                m.tri(a, c, d)
            elif k == rings-1:
                m.tri(a, b, c)
            else:
                m.quad(a, b, c, d)


def gable_roof(m, cx, cy, cz, sx, sz, rise, overhang, mat, name="roof"):
    """Two-slope roof; cy is eave height. Ridge runs along X."""
    m.begin(name, mat)
    hx = sx/2.0 + overhang
    hz = sz/2.0 + overhang
    y0, y1 = cy, cy + rise
    a = m.vert(cx-hx, y0, cz-hz)
    b = m.vert(cx+hx, y0, cz-hz)
    c = m.vert(cx+hx, y1, cz)
    d = m.vert(cx-hx, y1, cz)
    e = m.vert(cx-hx, y0, cz+hz)
    f = m.vert(cx+hx, y0, cz+hz)
    m.quad(a, b, c, d)
    m.quad(d, c, f, e)
    # gable ends
    m.tri(a, b, m.vert(cx, y1, cz-hz))
    m.tri(f, e, m.vert(cx, y1, cz+hz))


def frond(m, ox, oy, oz, ang, length, droop, width, mat, name="frond"):
    """Tapered drooping leaf strip radiating at ang (radians) in XZ."""
    m.begin(name, mat)
    dx, dz = math.cos(ang), math.sin(ang)
    px, pz = -dz, dx
    prev_l = prev_r = None
    for i in range(5):
        t = i / 4.0
        cx = ox + dx*length*t
        cy = oy + 0.5*length*t - droop*t*t
        cz = oz + dz*length*t
        w = width * (1.0 - t) * (0.4 + 0.6*math.sin(math.pi*t))
        l = m.vert(cx + px*w, cy, cz + pz*w)
        r = m.vert(cx - px*w, cy, cz - pz*w)
        if prev_l is not None:
            m.quad(prev_l, prev_r, r, l)
        prev_l, prev_r = l, r


def leaf(m, ox, oy, oz, ang, length, width, mat, name="leaf"):
    """Pointed lanceolate leaf: two triangles, slight upward curl."""
    m.begin(name, mat)
    dx, dz = math.cos(ang), math.sin(ang)
    px, pz = -dz, dx
    base = m.vert(ox, oy, oz)
    mid = m.vert(ox + dx*length*0.55, oy + 0.18*length, oz + dz*length*0.55)
    l = m.vert(ox + dx*length*0.45 + px*width, oy + 0.05*length,
               oz + dz*length*0.45 + pz*width)
    r = m.vert(ox + dx*length*0.45 - px*width, oy + 0.05*length,
               oz + dz*length*0.45 - pz*width)
    tip = m.vert(ox + dx*length, oy - 0.05*length, oz + dz*length)
    m.tri(base, l, mid)
    m.tri(base, mid, r)
    m.tri(l, tip, mid)
    m.tri(mid, tip, r)


def ring_wall(m, cx, cy, cz, r_out, r_in, h, seg, mat, name="ring"):
    m.begin(name, mat)
    layers = []
    for (r, yy) in ((r_out, cy), (r_out, cy+h), (r_in, cy+h), (r_in, cy)):
        layers.append([m.vert(cx + r*math.cos(2*math.pi*i/seg), yy,
                              cz + r*math.sin(2*math.pi*i/seg)) for i in range(seg)])
    for i in range(seg):
        j = (i+1) % seg
        m.quad(layers[0][i], layers[0][j], layers[1][j], layers[1][i])
        m.quad(layers[1][i], layers[1][j], layers[2][j], layers[2][i])
        m.quad(layers[2][i], layers[2][j], layers[3][j], layers[3][i])
        m.quad(layers[3][i], layers[3][j], layers[0][j], layers[0][i])


def human(m, cx, cz, hat_mat, cloth_mat, silhouette, name):
    """Stylised villager, ~300 tris. silhouette tunes hat/accessory."""
    m.name = name
    # legs
    box(m, cx-0.22, 0.45, cz, 0.28, 0.9, 0.30, "dark_timber", "leg_l")
    box(m, cx+0.22, 0.45, cz, 0.28, 0.9, 0.30, "dark_timber", "leg_r")
    # torso (tapered via two stacked boxes)
    box(m, cx, 1.35, cz, 0.86, 0.75, 0.46, cloth_mat, "torso")
    box(m, cx, 0.93, cz, 0.74, 0.18, 0.42, "cloth", "waist")
    # arms
    box(m, cx-0.58, 1.35, cz, 0.22, 0.78, 0.24, cloth_mat, "arm_l")
    box(m, cx+0.58, 1.35, cz, 0.22, 0.78, 0.24, cloth_mat, "arm_r")
    # hands + head
    box(m, cx-0.58, 0.90, cz, 0.20, 0.16, 0.22, "skin", "hand_l")
    box(m, cx+0.58, 0.90, cz, 0.20, 0.16, 0.22, "skin", "hand_r")
    blob(m, cx, 1.98, cz, 0.30, 0.34, 0.28, "skin", "head", seg=8, rings=3)
    if silhouette == "caping":
        cone(m, cx, 2.24, cz, 0.72, 0.34, 10, "hat", "caping")
    elif silhouette == "peci":
        cyl(m, cx, 2.26, cz, 0.30, 0.20, 10, "hat", "peci")
        box(m, cx, 2.22, cz+0.24, 0.42, 0.05, 0.12, "dark_timber", "peci_brim")
    elif silhouette == "kerudung":
        blob(m, cx, 2.02, cz-0.06, 0.34, 0.40, 0.32, "cloth", "kerudung", seg=8, rings=3)
        box(m, cx, 1.74, cz+0.24, 0.44, 0.22, 0.10, "cloth", "scarf")
    else:  # pedagang
        box(m, cx, 2.30, cz, 0.62, 0.10, 0.42, "cloth", "headcloth")
        box(m, cx, 1.28, cz+0.25, 0.60, 0.52, 0.06, "seng", "apron")
    if silhouette == "caping":
        box(m, cx+0.78, 1.55, cz+0.10, 0.10, 1.5, 0.10, "timber", "hoe_handle")
        box(m, cx+0.78, 2.28, cz+0.10, 0.38, 0.12, 0.10, "metal", "hoe_blade")
    if silhouette == "kerudung":
        ring_wall(m, cx-0.72, 0.55, cz, 0.30, 0.24, 0.26, 8, "bamboo", "basket")
    if silhouette == "peci":
        box(m, cx-0.50, 0.92, cz+0.20, 0.16, 0.22, 0.12, "metal", "tool_belt")


# ---------------- build functions ----------------
def bld_buildings():
    out = []
    m = Mesh("rumah_panggung", "landmark")
    # stilts + floor
    for x in (-2.4, 2.4):
        for z in (-1.6, 1.6):
            cyl(m, x, 0, z, 0.16, 1.5, 6, "timber", "stilt")
    box(m, 0, 1.5, 0, 5.4, 0.24, 3.8, "timber", "floor")
    box(m, 0, 2.45, 0, 4.8, 1.8, 3.2, "bamboo", "walls")
    box(m, 0, 2.35, 1.66, 1.0, 1.5, 0.08, "dark_timber", "door")
    gable_roof(m, 0, 3.35, 0, 5.4, 3.8, 1.5, 0.5, "seng", "roof")
    for i in range(5):
        box(m, -2.0 + i, 0.75, 2.5, 0.9, 0.12, 0.5, "timber", "step")
    out.append(m)

    m = Mesh("kandang_ayam", "kit")
    for x in (-1.0, 1.0):
        for z in (-0.7, 0.7):
            cyl(m, x, 0, z, 0.10, 0.9, 6, "timber", "leg")
    box(m, 0, 0.9, 0, 2.4, 0.14, 1.7, "timber", "floor")
    for i in range(5):
        box(m, -1.0 + i*0.5, 1.35, 0.85, 0.08, 0.8, 0.06, "bamboo", "slat_f")
        box(m, -1.0 + i*0.5, 1.35, -0.85, 0.08, 0.8, 0.06, "bamboo", "slat_b")
    gable_roof(m, 0, 1.75, 0, 2.6, 1.9, 0.7, 0.25, "seng", "roof")
    for i in range(3):
        box(m, 1.35, 0.35 + i*0.32, 0.7, 0.5, 0.08, 0.12, "timber", "ladder")
    out.append(m)

    m = Mesh("gudang_sawmill", "landmark")
    box(m, 0, 0.15, 0, 7.0, 0.30, 4.5, "stone", "slab")
    for x in (-3.2, -1.1, 1.1, 3.2):
        box(m, x, 1.9, -2.0, 0.20, 3.4, 0.20, "timber", "post_b")
        box(m, x, 1.9, 2.0, 0.20, 3.4, 0.20, "timber", "post_f")
    box(m, 0, 1.9, -2.1, 6.8, 3.4, 0.12, "timber", "back_wall")
    gable_roof(m, 0, 3.6, 0, 7.0, 4.5, 1.7, 0.5, "seng", "roof")
    for i in range(3):
        box(m, -2.0 + i*2.0, 0.55, 1.9, 1.4, 1.0, 0.5, "timber", "log_pile")
    out.append(m)
    return out


def bld_vegetation():
    out = []
    m = Mesh("palm_tropical", "landmark")
    for i in range(6):
        x = 0.12*math.sin(i*1.7)
        z = 0.12*math.cos(i*1.7)
        cyl(m, x, i*1.2, z, 0.30 - i*0.025, 1.25, 8, "timber", "trunk_seg")
    for i in range(8):
        frond(m, 0, 7.5, 0, 2*math.pi*i/8, 3.6, 1.6, 0.42, "leaf", "frond")
    for i in range(3):
        blob(m, 0.2*(i-1), 7.25, 0.2*(i-1), 0.22, 0.22, 0.22, "mango", "coconut", seg=6, rings=2)
    out.append(m)

    m = Mesh("banana_tropical", "kit")
    cyl(m, 0, 0, 0, 0.26, 2.8, 8, "leaf_light", "pseudostem")
    for i in range(6):
        leaf(m, 0, 2.7, 0, 2*math.pi*i/6, 2.4, 0.42, "leaf", "leaf")
    for i in range(2):
        leaf(m, 0, 1.9, 0, 1.0 + i*2.2, 1.5, 0.30, "leaf_light", "leaf_low")
    blob(m, 0, 2.35, 0.35, 0.22, 0.32, 0.18, "hat", "bunch", seg=6, rings=2)
    out.append(m)

    m = Mesh("mango_tropical", "landmark")
    cyl(m, 0, 0, 0, 0.42, 3.2, 8, "timber", "trunk")
    cyl(m, 0.55, 2.6, 0.1, 0.20, 1.4, 6, "timber", "branch")
    cyl(m, -0.55, 2.9, -0.1, 0.20, 1.3, 6, "timber", "branch")
    blob(m, 0, 4.4, 0, 2.1, 1.5, 1.9, "mango", "canopy_a", seg=8, rings=3)
    blob(m, 1.5, 4.0, 0.4, 1.3, 1.1, 1.3, "leaf", "canopy_b", seg=8, rings=3)
    blob(m, -1.4, 4.1, -0.4, 1.2, 1.0, 1.2, "leaf_light", "canopy_c", seg=8, rings=3)
    out.append(m)

    m = Mesh("shrubs_tropical", "kit")
    blob(m, 0, 0.55, 0, 0.9, 0.7, 0.8, "leaf", "shrub_a", seg=8, rings=3)
    blob(m, 1.1, 0.45, 0.3, 0.6, 0.5, 0.6, "leaf_light", "shrub_b", seg=8, rings=3)
    blob(m, -0.9, 0.40, -0.2, 0.55, 0.45, 0.55, "mango", "shrub_c", seg=8, rings=3)
    out.append(m)
    return out


def bld_props():
    out = []
    m = Mesh("cart_gerobak", "kit")
    box(m, 0, 1.0, 0, 2.6, 0.18, 1.5, "timber", "bed")
    for x in (-1.25, 1.25):
        cyl(m, x, 0.45, 0, 0.5, 0.16, 10, "dark_timber", "wheel")
        box(m, x, 1.25, -0.7, 0.12, 0.5, 0.12, "timber", "side")
    for x in (-1.0, 1.0):
        box(m, x, 1.0, -1.5, 0.10, 0.10, 1.6, "timber", "shaft")
    for x in (-1.1, 1.1):
        for z in (-0.6, 0.6):
            cyl(m, x, 1.1, z, 0.06, 1.1, 6, "bamboo", "canopy_post")
    gable_roof(m, 0, 2.2, 0, 2.6, 1.5, 0.5, 0.25, "cloth", "awning")
    out.append(m)

    m = Mesh("well_sumur", "landmark")
    ring_wall(m, 0, 0, 0, 1.0, 0.75, 1.0, 12, "stone", "well_ring")
    cyl(m, 0, 1.0, 0, 0.92, 0.14, 12, "water", "water")
    for x in (-0.95, 0.95):
        cyl(m, x, 1.0, 0, 0.09, 2.2, 6, "timber", "frame_post")
    gable_roof(m, 0, 3.2, 0, 2.4, 1.4, 0.7, 0.3, "seng", "roof")
    cyl(m, 0, 2.7, 0, 0.14, 0.3, 8, "timber", "pulley")
    box(m, 0, 1.9, 0, 0.02, 0.9, 0.02, "dark_timber", "rope")
    ring_wall(m, 0, 1.2, 0, 0.30, 0.24, 0.35, 8, "metal", "bucket")
    out.append(m)

    m = Mesh("market_stall", "landmark")
    for x in (-1.4, 1.4):
        for z in (-0.9, 0.9):
            cyl(m, x, 0, z, 0.09, 2.6, 6, "bamboo", "post")
    box(m, 0, 1.1, 0, 3.2, 0.16, 2.0, "timber", "counter")
    box(m, 0, 2.3, -0.85, 3.0, 0.7, 0.10, "timber", "shelf")
    gable_roof(m, 0, 2.6, 0, 3.2, 2.0, 0.8, 0.4, "seng", "awning")
    for i in range(3):
        box(m, -0.9 + i*0.9, 1.32, 0.2, 0.5, 0.25, 0.4, "cloth", "goods")
    out.append(m)

    m = Mesh("fencing_bambu", "kit")
    for x in (-2.0, 0, 2.0):
        cyl(m, x, 0, 0, 0.10, 1.5, 6, "bamboo", "fence_post")
    for y in (0.5, 1.05):
        for x0, x1 in ((-2.0, 0), (0, 2.0)):
            seg = 6
            for i in range(seg):
                t0, t1 = i/seg, (i+1)/seg
                a = m.vert(x0 + (x1-x0)*t0, y, -0.05)
                b = m.vert(x0 + (x1-x0)*t1, y, -0.05)
                c = m.vert(x0 + (x1-x0)*t1, y, 0.05)
                d = m.vert(x0 + (x1-x0)*t0, y, 0.05)
                m.quad(a, b, c, d)
    out.append(m)

    m = Mesh("tools_set", "kit")
    box(m, -0.7, 0.95, 0, 0.08, 1.9, 0.08, "timber", "hoe_handle")
    box(m, -0.7, 1.9, 0, 0.42, 0.12, 0.10, "metal", "hoe_blade")
    box(m, 0.2, 0.95, 0, 0.07, 1.8, 0.07, "timber", "sickle_handle")
    for i in range(4):
        a = m.vert(0.2 + 0.10*i, 1.85 - 0.05*i, 0)
        b = m.vert(0.2 + 0.12*i, 1.85 - 0.05*i, 0.14)
        c = m.vert(0.2 + 0.12*(i+1), 1.85 - 0.05*(i+1), 0.14)
        d = m.vert(0.2 + 0.10*(i+1), 1.85 - 0.05*(i+1), 0)
        m.quad(a, b, c, d)
    ring_wall(m, 1.0, 0, 0, 0.32, 0.26, 0.42, 8, "metal", "pail")
    out.append(m)
    return out


def bld_npcs():
    specs = [
        ("npc_petani_caping", "caping", "cloth"),
        ("npc_pedagang", "pedagang", "cloth"),
        ("npc_petani_wanita", "kerudung", "cloth"),
        ("npc_tukang_peci", "peci", "cloth"),
    ]
    out = []
    for name, sil, cloth in specs:
        m = Mesh(name, "kit")
        human(m, 0, 0, "hat", cloth, sil, name)
        out.append(m)
    return out


FAMILIES = {
    "buildings_r3": bld_buildings,
    "vegetation_r3": bld_vegetation,
    "props_r3": bld_props,
    "npcs_r3": bld_npcs,
}


def write_family(fam, meshes):
    d = os.path.join(OUT, fam)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "materials.mtl"), "w", encoding="utf-8") as mf:
        mf.write("# models_r3 generated palette — stdlib deterministic\n")
        for k, (r, g, b) in sorted(PALETTE.items()):
            mf.write(f"newmtl {k}\nKd {r:.3f} {g:.3f} {b:.3f}\n\n")
    for m in meshes:
        budget = LANDMARK_BUDGET if m.kind == "landmark" else KIT_BUDGET
        if m.tris() > budget:
            raise ValueError(f"{m.name}: {m.tris()} tris > {budget} budget")
        if " " in m.name:
            raise ValueError(f"{m.name}: filename contains space")
        p = os.path.join(d, m.name + ".obj")
        lines = [f"# {m.name} — DESIGNER_BUILD, deterministic, tropical (V-D4)",
                 f"# kind={m.kind} tris={m.tris()} budget={budget}",
                 "mtllib materials.mtl", f"o {m.name}"]
        for x, y, z in m.v:
            lines.append(f"v {x} {y} {z}")
        for part_name, start, mat in m.parts:
            lines.append(f"g {part_name}")
            lines.append(f"usemtl {mat}")
            # end index = next part's start or end of list
            idx = next((pn[1] for pn in m.parts if pn[1] > start), len(m.f))
            for a, b, c in m.f[start:idx]:
                lines.append(f"f {a} {b} {c}")
        with open(p, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")


def verify():
    """Self-check: every emitted OBJ parses and stays within budget."""
    checked = 0
    for fam in FAMILIES:
        d = os.path.join(OUT, fam)
        for fn in sorted(os.listdir(d)):
            if not fn.endswith(".obj"):
                continue
            if " " in fn:
                raise AssertionError(f"space in filename: {fn}")
            txt = open(os.path.join(d, fn), encoding="utf-8").read().splitlines()
            nv = 0
            tris = 0
            for line in txt:
                if line.startswith("v "):
                    nv += 1
                elif line.startswith("f "):
                    toks = line.split()[1:]
                    if len(toks) != 3:
                        raise AssertionError(f"{fn}: non-triangle face")
                    for t in toks:
                        vi = int(t.split("/")[0])
                        if not (1 <= vi <= nv):
                            raise AssertionError(f"{fn}: face refs vertex {vi} > {nv}")
                    tris += 1
            if tris == 0:
                raise AssertionError(f"{fn}: no faces")
            checked += 1
            print(f"OK {fam}/{fn}: {nv}v {tris}t")
    print(f"VERIFIED {checked} OBJ files")


def main():
    os.makedirs(OUT, exist_ok=True)
    for fam, fn in FAMILIES.items():
        meshes = fn()
        write_family(fam, meshes)
        print(f"generated {fam}: {len(meshes)} models")
    verify()


if __name__ == "__main__":
    sys.exit(main())
