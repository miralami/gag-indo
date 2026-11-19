# Localization Audit Report — Juragan Desa v2

Tanggal: 2026-11-19  
Status: **LUNE-ONLY** — snapshot regenerate dari `src/shared/Strings.luau` pada tanggal ini,
divalidasi oleh `lune run tests/run.luau` (1930 passed). Bukan hasil playtest di perangkat.
Source of truth tetap `Strings.luau`; angka di bawah dihitung langsung dari tabel tersebut.

---

## 1. Arsitektur Lokalisasi

- **Pusat string**: `src/shared/Strings.luau` adalah single source of truth untuk seluruh teks
  player-facing. Server mengirim **key**, client memilih bahasa.
- **Bahasa utama**: Indonesia (`id`); bahasa Inggris (`en`) disediakan berdampingan.
- **Deteksi otomatis**: `Strings.langFor(localeId)` mengembalikan `id` hanya jika dua karakter
  pertama locale (lower-case) adalah `id`; selain itu (termasuk `en-us`, `en-gb`, `es-es`, `ja-jp`)
  mengembalikan `en`. Dipanggil client saat inisialisasi. Studio ber-locale `en-us` memang
  menampilkan bahasa Inggris — ini sesuai desain, bukan bug.
- **Format angka**: `Strings.formatNumber(n, lang)` — pemisah ribuan titik untuk `id`
  (`12.500`), koma untuk `en` (`12,500`).
- **Parameter rekursif**: argumen diawali `@` (mis. `@crop_padi`, `@rank_petani`) di-resolve
  sebagai key lain oleh `Strings.get`. Argumen angka diformat dengan `formatNumber`. Template
  memakai `string.format` (`%s`, `%d`); bila format gagal, template dikembalikan apa adanya.
- **Key tidak dikenal**: `Strings.get` mengembalikan key itu sendiri (fallback tanpa crash).

---

## 2. Cakupan Kunci (333 entri, 100% berisi `id` dan `en`)

Jumlah per awalan key (dihitung dari `Strings.raw`):

| Awalan | Entri | Awalan | Entri | Awalan | Entri |
|---|---|---|---|---|---|
| `n_` (notifikasi) | 100 | `crop_` | 12 | `tool_` | 11 |
| `phone_` | 49 | `mg_` (minigame) | 9 | `lb_` (leaderboard) | 9 |
| `admin_` | 21 | `hud_` | 8 | `item_` | 7 |
| `raid_` | 17 | `warung_` | 6 | `shop_` | 6 |
| `prompt_` | 15 | `tutorial_` | 5 | `pass_` | 5 |
| `trait_` | 5 | `task_` | 5 | `tier_` | 5 |
| `goal_` | 4 | `cheat_` | 3 | `rank_` | 3 |
| `cosmetic_` | 3 | `season_` | 3 | `jail_` | 3 |
| `almanak_` | 3 | `plot_` | 2 | `event_` | 2 |
| `tile_` | 2 | `tag_` | 2 | + 8 awalan satuan | 8 |

**Total: 333 key — 0 `id` kosong, 0 `en` kosong.** Item 25 (dead-code sweep) menghapus 22 key
yang tidak lagi dipakai; ini adalah jumlah setelah pembersihan itu.

---

## 3. Hasil Pengujian Otomatis

Verifikasi otomatis di `tests/specs/strings_integrity_spec.luau` (nama lama `visuals_spec.luau`
sudah tidak ada) dan `tests/specs/ui_touch_text_audit_spec.luau`:

- setiap key memiliki field `id` dan `en` non-kosong — **PASS**;
- placeholder (`%s`, `%d`, `{name}`) cocok antara `id` dan `en` — **PASS**;
- tidak ada whitespace di awal/akhir atau sisa `TODO`/`TBD`/`XXX` — **PASS**;
- setiap literal key yang dikirim lewat `Notify.send` / `Notify.broadcast`, dibaca lewat
  `Strings.get` atau helper client `t(...)`, atau dipakai sebagai argumen `@key`, benar-benar
  ada di tabel (termasuk prefix konkatenasi `@crop_` .. id) — **PASS**;
- tidak ada literal teks word-like yang ditulis langsung ke properti `*.Text` di `src/`
  (kecuali glyph yang didokumentasikan) — **PASS**;
- tidak ada teks UI yang dirender di bawah minimum 11 px — **PASS** (`ui_touch_text_audit_spec`).

Semua teks player-facing di modul client (`Hud`, `Phone`, `Tiles`, `RaidOverlay`, `Minigame`,
`Evidence`, `Leaderboard`, dll.) memanggil `t(key)` yang bersumber dari `Strings.get(lang, key)`.
Catatan: cek ini adalah statis/Lune; tampilan aktual di perangkat dengan locale tertentu tetap
perlu diverifikasi di Studio (lihat `BUGS.md` / `GATE1.md`).
