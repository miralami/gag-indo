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
import tempfile

import bpy
import numpy as np
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


# ---------------------------------------------------------------------------
# Tekstur master (seragam antar model), untuk koleksi yang materialnya procedural.
# Pola: assets/master_textures/ berisi PNG dari Ragun (alun_alun dan kantor_polisi).
# Koleksi di MASTER_COLLECTIONS diekspor dari salinan sementara: UV dibuat otomatis,
# setiap material diganti dengan material master (gambar x warna dari color ramp),
# lalu salinan dibuang. Objek asli dan .blend tidak berubah.
# ---------------------------------------------------------------------------

MASTER_COLLECTIONS = ["EXPORT_TengkulakGelap", "EXPORT_Lahan", "EXPORT_Jalan"]
MASTER_DIR = "//../master_textures"
MASTER_DEFAULT = "plaster"
TEMP_COLL_NAME = "_FBX_TEMP_EXPORT"

# (kata dalam nama material, nama file master). Urutan penting: aturan pertama yang cocok dipakai.
MASTER_RULES = [
    ("water", "water"), ("canal", "water"),
    ("tile", "tegel"), ("brick", "tegel"),
    ("grout", "concrete"), ("concrete", "concrete"), ("slab", "concrete"), ("pole", "concrete"),
    ("stone", "stone"), ("rock", "stone"),
    ("path", "dirt"), ("paddy", "soil"), ("soil", "soil"), ("rut", "dirt"), ("dirt", "dirt"),
    ("earth", "dirt"), ("alley", "dirt"),
    ("moss", "mossstone"),
    ("trunk", "wood_dark"), ("wooddark", "wood_dark"), ("woodcrate", "wood_light"),
    ("wood", "wood"), ("bamboo", "wood_light"), ("fence", "wood_light"), ("straw", "wood_light"),
    ("grass", "grass"), ("leaf", "grass"), ("palm", "grass"), ("banana", "grass"),
    ("bush", "grass"), ("shrub", "grass"), ("tuft", "grass"), ("flower", "grass"),
    ("plain", "grass"), ("rice", "grass"), ("corn", "grass"), ("cassava", "grass"),
    ("potato", "grass"), ("onion", "grass"), ("chili", "grass"),
]


def master_name_for(mat_name):
    low = mat_name.lower().replace("_", "")
    for key, master in MASTER_RULES:
        if key in low:
            return master
    return MASTER_DEFAULT


def ramp_tint(mat):
    """Rata-rata warna stop color ramp di material; dipakai sebagai pengali warna."""
    if not mat.use_nodes:
        return (1.0, 1.0, 1.0)
    cols = []
    for n in mat.node_tree.nodes:
        if n.type == "VALTORGB":
            cols += [tuple(e.color[:3]) for e in n.color_ramp.elements]
    if not cols:
        return (1.0, 1.0, 1.0)
    return tuple(sum(c[i] for c in cols) / len(cols) for i in range(3))


_master_cache = {}
_master_mat_cache = {}


def master_image(name):
    if name not in _master_cache:
        path = bpy.path.abspath(os.path.join(MASTER_DIR, name + ".png"))
        if not os.path.exists(path):
            raise RuntimeError(f"Master texture tidak ada: {path}")
        img = bpy.data.images.load(path, check_existing=True)
        img.pack()  # FBX hanya meng-embed gambar yang di-pack
        _master_cache[name] = img
    return _master_cache[name]


_tint_cache = {}


def tinted_image(tex_name, tint):
    """Master texture dikali warna material, disimpan sebagai gambar baru yang di-pack.

    Warna dikalikan ke piksel, bukan lewat node, karena exporter FBX hanya meng-embed
    gambar yang tersambung langsung ke Base Color.
    """
    key = (tex_name, tuple(round(t, 2) for t in tint))
    if key in _tint_cache:
        return _tint_cache[key]
    master = master_image(tex_name)
    w, h = master.size
    arr = np.empty(w * h * 4, dtype=np.float32)
    master.pixels.foreach_get(arr)
    arr = arr.reshape(-1, 4)
    arr[:, 0:3] *= np.array(tint, dtype=np.float32)
    arr = np.clip(arr, 0.0, 1.0)
    label = f"{tex_name}_{int(key[1][0]*255):03d}{int(key[1][1]*255):03d}{int(key[1][2]*255):03d}"
    img = bpy.data.images.new(label, w, h, alpha=True)
    img.pixels.foreach_set(arr.ravel())
    tmp = os.path.join(tempfile.gettempdir(), "fbx_tint")
    os.makedirs(tmp, exist_ok=True)
    img.filepath_raw = os.path.join(tmp, label + ".png")
    img.file_format = "PNG"
    img.save()
    img.pack()
    _tint_cache[key] = img
    return img


def master_material(src):
    """Material master untuk satu material sumber (dibuat sekali, dipakai ulang)."""
    if src.name in _master_mat_cache:
        return _master_mat_cache[src.name]
    tex_name = master_name_for(src.name)
    tint = ramp_tint(src)
    mat = bpy.data.materials.new("UT_" + src.name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = tinted_image(tex_name, tint)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    bsdf.inputs["Roughness"].default_value = 0.85
    _master_mat_cache[src.name] = mat
    return mat


def unwrap_if_needed(obj):
    if len(obj.data.uv_layers) > 0:
        return
    # Hanya salinan ini yang boleh masuk edit mode; objek lain harus tidak terpilih.
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.01)
    bpy.ops.uv.average_islands_scale()
    bpy.ops.uv.pack_islands(margin=0.01)
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(False)


def make_temp_copies(coll):
    temp = bpy.data.collections.get(TEMP_COLL_NAME)
    if temp is None:
        temp = bpy.data.collections.new(TEMP_COLL_NAME)
        bpy.context.scene.collection.children.link(temp)
    copies = []
    for o in mesh_objects_in(coll):
        if o.hide_viewport or o.hide_get():
            continue
        c = o.copy()
        c.data = o.data.copy()
        c.matrix_world = o.matrix_world.copy()
        temp.objects.link(c)
        copies.append(c)
    return copies


def remove_temp():
    temp = bpy.data.collections.get(TEMP_COLL_NAME)
    if temp is None:
        return
    for o in list(temp.objects):
        data = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        if data is not None and data.users == 0:
            bpy.data.meshes.remove(data)
    bpy.data.collections.remove(temp)
    for m in list(_master_mat_cache.values()):
        if m.users == 0:
            bpy.data.materials.remove(m)
    _master_mat_cache.clear()
    for img in list(_tint_cache.values()) + list(_master_cache.values()):
        if img.users == 0:
            img.unpack(method="REMOVE")
            bpy.data.images.remove(img)
    _tint_cache.clear()
    _master_cache.clear()


def export_master_collection(name, folder):
    coll = bpy.data.collections.get(name)
    if coll is None or not mesh_objects_in(coll):
        print(f"[SKIP] koleksi '{name}' tidak ada atau kosong")
        return False
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    copies = make_temp_copies(coll)
    if not copies:
        print(f"[SKIP] '{name}': semua objek tersembunyi")
        return False
    for c in copies:
        unwrap_if_needed(c)
        for slot in c.material_slots:
            if slot.material is not None:
                slot.material = master_material(slot.material)
    moved = []
    if name in CENTER_AT_ORIGIN:
        corners = [c.matrix_world @ Vector(v) for o in copies for v in o.bound_box]
        cx = (min(p.x for p in corners) + max(p.x for p in corners)) / 2
        cy = (min(p.y for p in corners) + max(p.y for p in corners)) / 2
        for c in copies:
            moved.append((c, c.location.copy()))
            c.location.x -= cx
            c.location.y -= cy
    bpy.ops.object.select_all(action="DESELECT")
    for c in copies:
        c.select_set(True)
    bpy.context.view_layer.objects.active = copies[0]
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
        for c, loc in moved:
            c.location = loc
        remove_temp()
    size = os.path.getsize(path) if os.path.exists(path) else 0
    print(f"[OK] {name}: {len(copies)} objek, master texture -> {path} ({size / 1024:.0f} KB)")
    return size > 0


def main():
    folder = out_dir()
    os.makedirs(folder, exist_ok=True)
    print(f"Folder export: {folder}")
    changed = unpack_images_to_textures()
    try:
        results = {}
        for name in COLLECTIONS:
            if name in MASTER_COLLECTIONS:
                results[name] = export_master_collection(name, folder)
            else:
                results[name] = export_collection(name, folder)
    finally:
        restore_images(changed)
    gagal = [n for n, ok in results.items() if not ok]
    if gagal:
        print("Belum berhasil:", ", ".join(gagal))
    else:
        print("Semua koleksi berhasil diekspor.")


main()
