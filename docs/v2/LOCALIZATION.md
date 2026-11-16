# Localization Audit Report — Juragan Desa v2

Tanggal: 2026-11-12  
Status: PASS (100% key terisi bilingual ID & EN, verified by automated test suite).

---

## 1. Arsitektur Lokalisasi

- **Pusat String**: `src/shared/Strings.luau` adalah single source of truth untuk seluruh teks pemain.
- **Bahasa Utama**: Bahasa Indonesia (`id`) adalah bahasa primer (otentik kultur pedesaan Indonesia).
- **Bahasa Sekunder**: Bahasa Inggris (`en`) disediakan lengkap berdampingan untuk pemain global.
- **Deteksi Otomatis**:
  - `Strings.langFor(LocalizationService.RobloxLocaleId)` memeriksa locale Roblox pemain saat inisialisasi client di `src/client/Main.client.luau`.
  - Locale berawalan `id` (seperti `id-id`) menggunakan kamus `id`.
  - Locale lainnya (seperti `en-us`, `en-gb`, `es-es`, `ja-jp`, dll.) menggunakan kamus `en`.
- **Formatting Angka Lokalisasi**:
  - `Strings.formatNumber(n, lang)` secara otomatis memformat pemisah ribuan:
    - Bahasa Indonesia: Titik (`12.500`)
    - Bahasa Inggris: Koma (`12,500`)
- **Penerjemahan Dinamis Parameter**:
  - Parameter yang diawali tanda `@` (misalnya `@crop_padi`, `@rank_petani`) diterjemahkan secara rekursif oleh `Strings.get(lang, key, ...)`.

---

## 2. Cakupan Namespace Kamus String

| Namespace | Kunci Terdaftar | Cakupan ID | Cakupan EN | Catatan |
|---|---|---|---|---|
| **Crops & Families** | 18 | 100% | 100% | 12 komoditas pertanian + 3 rumpun + halaman almanak |
| **Rarity Tiers** | 5 | 100% | 100% | Biasa, Bagus, Super, Langka, Sultan |
| **Traits** | 5 | 100% | 100% | Oplosan, Basah, Kering, Organik, Bersertifikat |
| **Cosmetics** | 8 | 100% | 100% | Aksesoris (Caping, Batik, Batu Akik, dll) |
| **Ranks** | 5 | 100% | 100% | Gurem, Petani, Juragan, Tuan Tanah, Sultan |
| **Tools & Tiers** | 9 | 100% | 100% | Cangkul, Sabit, Karung & Material (Bambu, Besi, Baja) |
| **Seasons & Weather** | 10 | 100% | 100% | Hujan, Kemarau, Pancaroba, Anomali, Badai |
| **Tutorial (FTUE)** | 7 | 100% | 100% | 4 langkah terpandu + judul kartu + toast sukses |
| **Cheats & Law** | 12 | 100% | 100% | Oplosan, Curi Air, Pasar Gelap, Penjara Pos Ronda |
| **Pinjol (Dana Kilat)**| 18 | 100% | 100% | Limit, hutang, jatuh tempo, penagihan, teror debt collector |
| **Quests & Login** | 14 | 100% | 100% | Tugas harian, progres, klaim, streak 7 hari |
| **HUD & Phone UI** | 42 | 100% | 100% | Tombol navigasi, app grid, saldo, inventaris, toko bibit |
| **Raid Overlay** | 15 | 100% | 100% | Breaking news, viral, opsi denda / amplop sogokan |
| **Minigames** | 6 | 100% | 100% | Mencangkul, Babat Rumput, skor kualitas |
| **Admin Panel** | 8 | 100% | 100% | Tool backend inspeksi & override runtime |
| **Leaderboard** | 6 | 100% | 100% | Tab papan peringkat pendapatan, kekayaan, razia |
| **Toasts / Notifications**| 38 | 100% | 100% | Notifikasi server event (`n_*`) lengkap dwibahasa |
| **Total Kunci** | **> 200** | **100%** | **100%** | Zero Missing Keys |

---

## 3. Hasil Pengujian Otomatis

Verifikasi otomatis di `tests/specs/visuals_spec.luau`:
- `ensures every string key has both non-empty id and en fields`: **PASS**.
- `ensures Strings table contains no 4-byte UTF-8 emoji`: **PASS**.
- Seluruh teks player-facing di file client (`Hud`, `Phone`, `Tiles`, `RaidOverlay`, `Minigame`, `Evidence`, `Leaderboard`) memanggil fungsi `t(key)` yang bersumber dari `Strings.get(lang, key)`. Tidak ditemukan hardcoded text tanpa string key.
