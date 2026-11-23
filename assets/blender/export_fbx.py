"""
Export koleksi EXPORT_* dari pasar_gelap_blockout.blend ke FBX dengan setting standar.

Cara pakai:
  1. Buka pasar_gelap_blockout.blend di Blender 5.x.
  2. Buka workspace Scripting, pilih Text Editor, Open file ini, lalu Run Script.
     Atau dari terminal (folder repo):
       blender -b assets/blender/pasar_gelap_blockout.blend -P assets/blender/export_fbx.py

  Hasil ditulis ke assets/blender/export/<nama>.fbx, dengan tekstur di dalam file.
  Ubah daftar COLLECTIONS di bawah kalau mau mengekspor sebagian saja.

Setting dikunci di sini supaya setiap export sama:
  - Scale 1.0, Apply Unit aktif, Apply Scale = FBX All
  - Forward -Z, Up Y
  - Hanya objek yang dipilih (isi koleksi, termasuk sub-koleksi)
  - Mesh saja, modifier diterapkan, tanpa armature dan leaf bones
  - Smoothing per face, tekstur di-embed di dalam FBX (embed_textures, sama seperti
    alun_alun_full.fbx dari Ragun, yang menyimpan PNG di dalam file)

Tekstur: gambar di .blend ini disimpan di dalam file (packed), path aslinya F:\\... tidak ada
di mesin ini. Skrip menulis gambar packed ke assets/blender/textures/ (pola Ragun: textures/
di samping hasil export, dikomit bersama FBX), lalu FBX meng-embed PNG itu. Path gambar di
.blend dikembalikan seperti semula; .blend tidak disimpan.

Skala: FBX keluar 1 unit = 1 m. Koreksi ke stud Roblox (1/0.28) dilakukan di Studio,
sesuai catatan di docs/v2/visual/art/ASSET_MANIFEST.md. Jangan ubah GLOBAL_SCALE tanpa
persetujuan owner.

Pusat kit: koleksi di CENTER_AT_ORIGIN digeser sementara supaya pusat bounding box-nya
ada di (0, 0), lalu dikembalikan. Di .blend, kit Jalan berada di x 288 sampai 388 m, jadi
tanpa ini kit muncul jauh dari titik asal saat diimpor.
"""

import os

import bpy
from mathutils import Vector

# Koleksi yang diekspor. Nama harus persis sama dengan di Outliner.
COLLECTIONS = [
    "EXPORT_Pasar",
    "EXPORT_TengkulakGelap",
    "EXPORT_Lahan",
    "EXPORT_Jalan",
]

# Koleksi yang dipusatkan ke (0, 0) hanya saat export, lalu dikembalikan.
CENTER_AT_ORIGIN = ["EXPORT_Jalan"]

GLOBAL_SCALE = 1.0  # jangan diubah tanpa persetujuan owner (lihat docstring)

# Folder keluaran. Default: export/ di samping file .blend.
# Untuk tes, isi dengan folder lain, misalnya OUT_DIR_OVERRIDE = r"C:\Users\Sena\AppData\Local\Temp\fbxtest"
OUT_DIR_OVERRIDE = None


def out_dir():
    if OUT_DIR_OVERRIDE:
        return OUT_DIR_OVERRIDE
    if not bpy.data.filepath:
        raise RuntimeError("Simpan file .blend dulu, supaya folder export bisa ditentukan.")
    return bpy.path.abspath("//export")


def mesh_objects_in(collection):
    """Semua objek mesh di koleksi, termasuk sub-koleksi."""
    return [o for o in collection.all_objects if o.type == "MESH"]


def texture_dir():
    """Folder PNG sumber, sejajar dengan pola Ragun (assets/<area>/textures/). Dikomit bersama FBX."""
    if not bpy.data.filepath:
        raise RuntimeError("Simpan file .blend dulu, supaya folder textures bisa ditentukan.")
    return bpy.path.abspath("//textures")


def unpack_images_to_textures():
    """Tulis gambar packed ke texture_dir() dan arahkan path-nya ke sana sementara.

    Mengembalikan daftar (gambar, path lama) untuk dikembalikan setelah export.
    """
    folder = texture_dir()
    os.makedirs(folder, exist_ok=True)
    changed = []
    for im in bpy.data.images:
        if im.packed_file is None or im.users == 0:
            continue
        base = os.path.basename(im.filepath.replace("\\", "/")) or im.name
        if not os.path.splitext(base)[1]:
            base += ".png"
        dst = os.path.join(folder, base)
        with open(dst, "wb") as f:
            f.write(im.packed_file.data)
        changed.append((im, im.filepath))
        im.filepath = dst
    print(f"Tekstur packed ditulis ke {folder}: {len(changed)} gambar")
    return changed


def restore_images(changed):
    for im, old in changed:
        im.filepath = old


def offset_collection(coll):
    """Geser objek teratas koleksi supaya pusat bounding box XY ada di (0, 0).

    Mengembalikan daftar (objek, lokasi lama) untuk dikembalikan setelah export.
    """
    objs = mesh_objects_in(coll)
    if not objs:
        return []
    corners = []
    for o in objs:
        for v in o.bound_box:
            corners.append(o.matrix_world @ Vector(v))
    cx = (min(c.x for c in corners) + max(c.x for c in corners)) / 2
    cy = (min(c.y for c in corners) + max(c.y for c in corners)) / 2

    members = set(coll.all_objects)
    moved = []
    for o in coll.all_objects:
        if o.parent is not None and o.parent in members:
            continue  # ikut parent-nya
        moved.append((o, o.location.copy()))
        o.location.x -= cx
        o.location.y -= cy
    print(f"Pusat '{coll.name}' digeser ({-cx:.2f}, {-cy:.2f}) sementara")
    return moved


def restore_locations(moved):
    for o, loc in moved:
        o.location = loc


def export_collection(name, folder):
    coll = bpy.data.collections.get(name)
    if coll is None:
        print(f"[SKIP] koleksi '{name}' tidak ada")
        return False

    objs = mesh_objects_in(coll)
    if not objs:
        print(f"[SKIP] koleksi '{name}' tidak punya objek mesh")
        return False

    # Pilih hanya objek di koleksi ini.
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    selected = 0
    for o in objs:
        if o.hide_viewport or o.hide_get():
            continue
        o.select_set(True)
        selected += 1
    if selected == 0:
        print(f"[SKIP] '{name}': semua objek tersembunyi, tampilkan dulu di Outliner")
        return False
    bpy.context.view_layer.objects.active = next(o for o in objs if o.select_get())

    moved = offset_collection(coll) if name in CENTER_AT_ORIGIN else []
    path = os.path.join(folder, f"{name.replace('EXPORT_', '')}.fbx")
    try:
        bpy.ops.export_scene.fbx(
            filepath=path,
            use_selection=True,
            object_types={"MESH"},
            global_scale=GLOBAL_SCALE,
            apply_unit_scale=True,
            apply_scale_options="FBX_SCALE_ALL",
            axis_forward="-Z",
            axis_up="Y",
            use_mesh_modifiers=True,
            use_armature_deform_only=False,
            add_leaf_bones=False,
            bake_anim=False,
            mesh_smooth_type="FACE",
            path_mode="COPY",
            embed_textures=True,
        )
    finally:
        restore_locations(moved)
    size = os.path.getsize(path) if os.path.exists(path) else 0
    print(f"[OK] {name}: {selected} objek -> {path} ({size / 1024:.0f} KB)")
    return size > 0


def main():
    folder = out_dir()
    os.makedirs(folder, exist_ok=True)
    print(f"Folder export: {folder}")
    changed = unpack_images_to_textures()
    try:
        results = {name: export_collection(name, folder) for name in COLLECTIONS}
    finally:
        restore_images(changed)
    gagal = [n for n, ok in results.items() if not ok]
    if gagal:
        print("Belum berhasil:", ", ".join(gagal))
    else:
        print("Semua koleksi berhasil diekspor.")


main()
