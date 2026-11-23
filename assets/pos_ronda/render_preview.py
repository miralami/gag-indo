"""Render review shots of pos_ronda.blend (does not save the .blend).

    blender --background assets/pos_ronda/pos_ronda.blend --python assets/pos_ronda/render_preview.py

Adds a ground plane, sun, sky and a 5.5-stud avatar-sized figure for scale, then writes
preview/*.jpg next to this script.
"""

import math
import os

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "preview")


def srgb(hexv):
    """Palette hex (ART.md §3) to the linear colour a Base Color socket expects."""
    out = []
    for i in (0, 2, 4):
        c = int(hexv[i : i + 2], 16) / 255.0
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return tuple(out)


def flat_material(name, rgb, rough=0.9):
    mat = bpy.data.materials.new(name)
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    return mat


def setup():
    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT", "CYCLES"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 800
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 88
    # Standard view transform so the palette hex values read as they are, not tone-mapped
    scene.view_settings.view_transform = "Standard"

    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, 0))
    ground = bpy.context.active_object
    ground.data.materials.append(flat_material("ground", srgb("6f8a3f")))
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 22, 0.02))
    path = bpy.context.active_object
    path.scale = (6, 30, 1)
    path.data.materials.append(flat_material("path", srgb("b98a5a")))

    # avatar-sized figure (5.5 studs) beside the steps
    fig = flat_material("figure", (0.15, 0.35, 0.8), 0.6)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.9, depth=4.0, location=(3.0, 13.5, 2.0))
    bpy.context.active_object.data.materials.append(fig)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.75, location=(3.0, 13.5, 4.75))
    bpy.context.active_object.data.materials.append(fig)

    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 2.2
    sun.angle = math.radians(3)
    sun_obj = bpy.data.objects.new("sun", sun)
    sun_obj.rotation_euler = (math.radians(50), 0, math.radians(-35))
    scene.collection.objects.link(sun_obj)

    world = bpy.data.worlds.new("sky")
    scene.world = world
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (0.55, 0.72, 0.92, 1.0)
    bg.inputs["Strength"].default_value = 0.6
    return scene


def shoot(scene, name, loc, target, lens=35):
    cam_data = bpy.data.cameras.new(name)
    cam_data.lens = lens
    cam = bpy.data.objects.new(name, cam_data)
    scene.collection.objects.link(cam)
    cam.location = loc
    d = Vector(target) - Vector(loc)
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    os.makedirs(OUT, exist_ok=True)
    scene.render.filepath = os.path.join(OUT, f"{name}.jpg")
    bpy.ops.render.render(write_still=True)


scene = setup()
shoot(scene, "pos_ronda_front", (0, 40, 7), (0, 0, 6.5), lens=30)
shoot(scene, "pos_ronda_34", (28, 30, 15), (0, 0, 6))
shoot(scene, "pos_ronda_inside", (-3, 13, 5.5), (2, -6, 5), lens=24)
shoot(scene, "pos_ronda_back", (-28, -30, 16), (0, 0, 6))
shoot(scene, "pos_ronda_props", (-2, 5, 6.2), (7, -6, 4.6), lens=22)
shoot(scene, "pos_ronda_meja", (5.2, 3.2, 8.2), (5.3, -1.0, 4.2), lens=30)
shoot(scene, "pos_ronda_dinding", (-6, 5, 5.5), (-12, -6, 4.5), lens=24)
print("RENDER_ENGINE", scene.render.engine)
