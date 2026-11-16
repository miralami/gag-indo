# Art Checkpoint 2 Report

## Status
- W3: selesai sebagian. Palette rarity Langka dan data token visual tiap tier ditambahkan; reveal runtime dan crop stage models belum dikerjakan.
- W4: dilewati. Greybox/Props, terrain, kontur dunia, dan SurfaceAppearance hook belum diubah.
- W5: dilewati. NPC design cards, silhouette/accessories, expressions, dan contour belum diubah.
- Tes: `lune run tests/run` — 480 lulus (sebelumnya 479).

## File berubah
- `docs/v2/visual/ART.md`
- `src/shared/Config/Visuals.luau`
- `tests/specs/visuals_spec.luau`
- `docs/v2/visual/ART_CHECKPOINT_2.md`

## Ringkasan
- Menetapkan aksen `ungu` `#7652a8` untuk Langka sesuai visual/ART.md.
- Menambahkan `Visuals.rarity` untuk lima tier, lengkap token palet, bingkai, dan efek.
- Menambahkan tes bahwa setiap tier memiliki data visual valid.

## Belum diverifikasi
- Tampilan reveal, crop stage models, dunia dan NPC belum diuji di Studio.
- FPS/jumlah instance tidak diukur; tidak ada geometri yang dibuat.

## Keputusan dibutuhkan
- Tidak ada keputusan baru untuk pekerjaan yang selesai. Desain visual runtime tetap perlu review di Studio.

## Saran commit
- Kelompokkan palette + rarity tokens + tes dalam satu commit; jangan commit otomatis.
