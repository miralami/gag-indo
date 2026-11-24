"""Render review shots of rumah_pakrt.blend (does not save the .blend).

    blender --background assets/rumah_pakrt/rumah_pakrt.blend --python assets/rumah_pakrt/render_preview.py

Adds a ground plane, sun, sky and a 5.3-stud figure (default Roblox R15 avatar) for scale, then writes
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

    bpy.ops.mesh.primitive_plane_add(size=400, location=(0, 0, 0))
    ground = bpy.context.active_object
    ground.data.materials.append(flat_material("ground", srgb("6f8a3f")))
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 31, 0.02))
    path = bpy.context.active_object
    path.scale = (200, 12, 1)  # dirt village road; the asphalt piece sits on it
    path.data.materials.append(flat_material("path", srgb("b98a5a")))

    # avatar-sized figure: 5.3 studs, a default Roblox R15 character (the game does not rescale
    # characters; MapSpec's 7.25 is an old assumption)
    fig = flat_material("figure", (0.15, 0.35, 0.8), 0.6)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.9, depth=3.9, location=(3.0, 27.0, 1.95))
    bpy.context.active_object.data.materials.append(fig)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.7, location=(3.0, 27.0, 4.6))
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
shoot(scene, "rumah_pakrt_front", (-6, 88, 9), (0, -4, 12), lens=30)
shoot(scene, "rumah_pakrt_34", (66, 74, 40), (0, -2, 6))
shoot(scene, "rumah_pakrt_teras", (-4, 16, 9), (-7, -4, 3.5), lens=26)
shoot(scene, "rumah_pakrt_lesehan", (8, 22, 11), (23, 1, 1.5), lens=26)
shoot(scene, "rumah_pakrt_carport", (-10, 32, 9), (-23, -4, 4), lens=26)
shoot(scene, "rumah_pakrt_back", (-62, -66, 34), (0, 0, 8))
print("RENDER_ENGINE", scene.render.engine)
