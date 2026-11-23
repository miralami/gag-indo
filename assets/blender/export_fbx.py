"""
Export koleksi EXPORT_* dari pasar_gelap_blockout.blend ke FBX dengan setting standar.

Cara pakai:
  1. Buka pasar_gelap_blockout.blend di Blender 5.x.
  2. Buka workspace Scripting, pilih Text Editor, Open file ini, lalu Run Script.
     Atau dari terminal (folder repo):
       blender -b assets/blender/pasar_gelap_blockout.blend -P assets/blender/export_fbx.py

  Hasil ditulis ke assets/blender/export/<nama>.fbx (satu file per koleksi).
  Ubah daftar COLLECTIONS di bawah kalau mau mengekspor sebagian saja.

Setting dikunci di sini supaya setiap export sama:
  - Scale 1.0, Apply Unit aktif, Apply Scale = FBX All
  - Forward -Z, Up Y
  - Hanya objek yang dipilih (isi koleksi, termasuk sub-koleksi)
  - Mesh saja, modifier diterapkan, tanpa armature dan leaf bones
  - Smoothing per face, tekstur tidak di-embed, path mode COPY

Skala: FBX keluar 1 unit = 1 m. Koreksi ke stud Roblox (1/0.28) dilakukan di Studio,
sesuai catatan di docs/v2/visual/art/ASSET_MANIFEST.md. Jangan ubah GLOBAL_SCALE tanpa
persetujuan owner.
"""

import os

import bpy

# Koleksi yang diekspor. Nama harus persis sama dengan di Outliner.
COLLECTIONS = [
    "EXPORT_Pasar",
    "EXPORT_TengkulakGelap",
    "EXPORT_Lahan",
    "EXPORT_Jalan",
]

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

    path = os.path.join(folder, f"{name.replace('EXPORT_', '')}.fbx")
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
        embed_textures=False,
    )
    size = os.path.getsize(path) if os.path.exists(path) else 0
    print(f"[OK] {name}: {selected} objek -> {path} ({size / 1024:.0f} KB)")
    return size > 0


def main():
    folder = out_dir()
    os.makedirs(folder, exist_ok=True)
    print(f"Folder export: {folder}")
    results = {name: export_collection(name, folder) for name in COLLECTIONS}
    gagal = [n for n, ok in results.items() if not ok]
    if gagal:
        print("Belum berhasil:", ", ".join(gagal))
    else:
        print("Semua koleksi berhasil diekspor.")


main()
