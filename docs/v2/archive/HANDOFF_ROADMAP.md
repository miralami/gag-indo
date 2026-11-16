# Prompt untuk opencode: roadmap M4 sampai v2.3 (dengan checkpoint)

Tempel semua isi di bawah garis ini ke opencode (jalankan dari root repo). Terpisah dari
`archive/HANDOFF_ART_PASS.md`; lihat "Batas file" bila keduanya dijalankan berdekatan.

---

Kamu melanjutkan game Roblox "Juragan Desa" (Luau, Rojo, repo ini). Tugasmu: **mengerjakan sisa roadmap `docs/v2/plan/PLAN.md` secara berurutan, tanpa berhenti di tiap langkah, dan berhenti hanya di CHECKPOINT** yang ditandai di bawah. Hasilmu di-review dan diverifikasi oleh reviewer lain (Claude) pada tiap checkpoint, jadi laporan harus jujur dan bisa diperiksa.

## Baca dulu (wajib, urut)
1. `docs/v2/plan/PLAN.md` — seluruh dokumen, terutama §3.5 sampai §3.8, §4, §5, §6, §7, §8.
2. `docs/v2/plan/DECISIONS.md` — D2, D3 (launch setelah **keempat rilis** selesai), D4, D5, D6, D7, D9 (terbuka), D10.
3. `docs/v2/plan/TECH.md` — konvensi server, state, remote, tes.
4. `docs/v1/` (GDD v1) bila PLAN merujuknya (mis. §7.3 Kepala Desa).

## Kondisi sekarang
- M0 sampai M3 dan sebagian M4 sudah di-commit (pinjol, quest harian, login streak, badge). 386 tes lulus (`lune run tests/run.luau`).
- `src/server/Social/LeaderboardService.luau` ada tapi belum di-commit; terhubung di `Main.server.luau`; remote `Leaderboard_Data` ada; **belum ada UI client**; `tests/specs/leaderboard_spec.luau` baru tes dasar.
- `Config/Products.luau` dan `Config/Cosmetics.luau`: semua id `0` ("belum dikonfigurasi", UI menyembunyikan tombol). Item PLAN §3.7 yang belum ada: pass Gudang Besar, Auto-Panen; produk Restock Toko, Rupiah packs.
- `src/server/Analytics/Analytics.luau` hanya pembungkus tipis `LogCustomEvent`.
- Art pass dikerjakan terpisah (`archive/HANDOFF_ART_PASS.md`). Working tree berisi pekerjaan lain yang belum di-commit.

## Cara kerja (penting)
- **Kerjakan langkah berurutan tanpa menunggu persetujuan**, sampai bertemu `CHECKPOINT`. Di checkpoint: jalankan tes, tulis laporan `docs/v2/CHECKPOINT_<n>.md`, lalu **berhenti**.
- **Bila terhalang keputusan desainer** (harga, alur cerita, nama, aturan desain), jangan menebak dan jangan berhenti: catat di bagian "Keputusan dibutuhkan" pada laporan checkpoint, lewati bagian itu, dan lanjutkan langkah berikutnya yang tidak terhalang.
- **Jangan mengarang**: id produk, harga, UserId, data akun nyata, atau aturan kebijakan Roblox. Untuk kebijakan (perdagangan item berbayar, item acak berbayar, PolicyService) tulis "perlu diverifikasi ke dokumentasi Roblox terbaru" dan, bila bisa, cari sumber primernya.
- Lebih baik **mengurangi cakupan** daripada melaporkan sesuatu selesai padahal tidak.

---

# FASE A — Selesaikan M4 (uang dan kebiasaan)

**A1 Leaderboard.** Review `LeaderboardService`: kegagalan DataStore (pcall, retry terbatas), throttle tulis (budget DataStore), cache nama, tidak ada nilai dari klien. Perkuat `leaderboard_spec` (urutan top-N, tie-break, nilai negatif/NaN, store mati, board kosong). Buat `src/client/UI/Leaderboard.luau` (papan di Balai Desa + panel ringkas, tiga papan: richest, sultan, raids) memakai API `Theme` yang ada, validasi payload `Leaderboard_Data` di client, teks dari `Strings.luau`.

**A2 Monetisasi tanpa mengarang.** Tambahkan item §3.7 yang belum ada ke `Products.luau` (id tetap `0`). Implementasikan efek tiap item di server mengikuti pola `Receipts.luau`/Passes (`grant` berupa kunci data, bukan fungsi): Gudang Besar (kapasitas gudang), Auto-Panen (buruh tanpa upah), Restock Toko (refresh toko), Rupiah packs (lewat API publik `EconomyService`). Tes wajib: receipt yang sama dua kali memberi hadiah **sekali**, receipt gagal tidak mengembalikan `PurchaseGranted`, pemain keluar di tengah pembelian, id `0` tidak pernah memanggil Roblox. Pagar: tidak ada yang membeli kekebalan raid, tidak menghapus kasus VIRAL, tidak ada acak berbayar.

**A3 Analytics.** Pakai skill `roblox-analytics` bila ada. Event: funnel onboarding per langkah, ekonomi (sumber/penggunaan uang), pinjaman diambil/dilunasi/disita, raid, pembelian, panen per tier. Satu modul, hormati rate limit, tidak ada data pribadi, tidak ganda untuk satu aksi, tidak error saat `AnalyticsService` gagal. Tulis `docs/v2/plan/ANALYTICS.md` (event, kapan dikirim, pertanyaan yang dijawab).

**A4 Tes alur pinjol penuh** (kriteria selesai M4): pinjam, telat, spam HP, kolektor di plot, pesan "kontak", penyitaan gudang sampai lunas. Periksa: bunga maksimum 3x pokok, satu pinjaman sekaligus, tidak boleh pinjam saat raid, utang tersimpan setelah rejoin. Bug kecil perbaiki; yang mengubah desain, catat sebagai keputusan.

### >>> CHECKPOINT 1 — M4 selesai
Tulis `docs/v2/archive/CHECKPOINT_1.md`. Berhenti.

---

# FASE B — Persiapan M5 (launch readiness)

**B1 Audit keamanan.** Skill `roblox-security` dan `roblox-networking` bila ada. Audit semua remote di `Remotes.luau`: tipe/rentang argumen, rate limit, otoritas server, admin hanya allowlist (`Live/Admins.luau`). Output `docs/v2/qa/SECURITY_AUDIT.md` (temuan kritis/tinggi/sedang, file:baris, skenario eksploit, perbaikan). Perbaiki kritis dan tinggi dengan tes.

**B2 Balance pass.** Simulasi ekonomi sebagai tes/skrip Lune: pemain tipikal selama N hari (laju tumbuh, harga, pinjol, quest). Laporkan waktu menuju rank, titik macet, apakah pinjol sehat. Output `docs/v2/plan/BALANCE.md`. **Usulkan** angka; jangan ubah angka produksi.

**B3 Performa.** Skill `roblox-performance` bila ada. Audit loop server/klien yang berat, jumlah instance, kebocoran koneksi, beban remote, DataStore budget. Output `docs/v2/qa/PERF_AUDIT.md` dengan temuan berperingkat; perbaiki yang aman dan tes-able.

**B4 FTUE dan retensi.** Skill `roblox-game-design` dan `roblox-player-psychology` bila ada. Audit sesi pertama (panen berpemandu, 10 menit pertama di HP), jam login streak/quest, dan pola gelap (manipulatif). Output `docs/v2/qa/FTUE_AUDIT.md` dengan rekomendasi; perbaiki yang kecil dan jelas.

**B5 Lokalisasi.** Skill `roblox-localization` bila ada. Pastikan semua teks pemain lewat `Strings.luau` (ID dan EN), tidak ada string hardcode di UI, teks EN menjelaskan referensi (bukan terjemahan harfiah), dan ada pemilih bahasa (D6). Daftar string janggal di dokumen.

**B6 Dokumen launch.** `docs/v2/plan/LAUNCH.md`: draf jawaban kuesioner maturity (semua target fiktif, D7), spesifikasi aset toko (ikon, 3 thumbnail, klip raid 30 detik), checklist §3.8 beserta statusnya, dan hasil skill `roblox-publish-checklist` bila ada. Skill `roblox-growth-design` untuk judul, deskripsi, dan strategi thumbnail.

### >>> CHECKPOINT 2 — M5 siap, tinggal playtest/publish manual
Tulis `docs/v2/archive/CHECKPOINT_2.md`. Berhenti.

---

# FASE C — v2.1 Pesta Demokrasi (PLAN §4)

Fitur terbesar dan paling bergantung keputusan desain. Urutan: spesifikasi dulu, lalu bagian yang tidak terhalang.

**C1 Spesifikasi.** `docs/v2/V21_SPEC.md` untuk empat bagian (§4.1 story, §4.2 Kepala Desa, §4.3 viral ticker, §4.4 cheat tersembunyi): model data (schema/migrasi), remote baru + validasi, aturan server, kasus tepi, daftar tes, dan **pertanyaan terbuka untuk desainer** (nama informan per D4, alur 5 Babak, aturan korupsi dan pemakzulan, ambang penimbunan). Sertakan draf kerangka 5 Babak (ID dan EN, EN menjelaskan referensi) sebagai usulan.

**C2 Viral ticker (§4.3).** Spesifikasi sudah jelas: lintas server via `MessagingService`, hanya template (nama pemain boleh, teks bebas tidak), throttle, tidak crash bila MessagingService gagal. Server + klien + tes. Peristiwa: raid VIRAL, pemakzulan, panen Sultan.

**C3 Fondasi Kepala Desa (§4.2) — hanya logika.** Model data dan aturan server dengan tes (Dana Desa, Proyek Desa, korupsi/proyek mangkrak, serangan fajar, gate Nama Baik, pemakzulan saat raid). **Tanpa UI.** Di balik flag LiveConfig agar mati secara default. Berhenti di bagian yang butuh keputusan desain dan catat di checkpoint.

### >>> CHECKPOINT 3 — v2.1: spesifikasi + ticker + fondasi Kades
Tulis `docs/v2/CHECKPOINT_3.md`. Berhenti. Story chapters, UI Kades, dan cheat tersembunyi menunggu keputusan desainer.

---

# FASE D — Rencana v2.2 dan v2.3 (hanya dokumen)

**D1** `docs/v2/V22_SPEC.md` (Tetangga: trading, maling, keamanan, uang tutup mulut, housing) dan **D2** `docs/v2/V23_SPEC.md` (Ternak & Musim: livestock, empang, pengolahan, event musiman, Peti Bibit). Tiap dokumen: model data, remote, aturan, risiko eksploit (trading/duplikasi), tes, urutan kerja, dan estimasi relatif. **Verifikasi kebijakan Roblox terbaru** (perdagangan item berbayar, item acak berbayar, PolicyService) dari sumber resmi dan kutip tautannya. **Jangan menulis kode** untuk fase ini.

### >>> CHECKPOINT 4 — selesai. Tulis `docs/v2/CHECKPOINT_4.md` dan berhenti.

---

## Format `CHECKPOINT_<n>.md`
- Daftar langkah: selesai / sebagian / dilewati (beserta alasannya).
- File diubah dan dibuat (daftar).
- Ringkasan perubahan (butir singkat).
- Hasil `lune run tests/run.luau` (salin baris ringkasnya; jumlah tes dibanding sebelumnya).
- **Belum diverifikasi** (hal yang tidak bisa diuji lewat Lune: DataStore nyata, `ProcessReceipt`, MessagingService, tampilan) dan asumsi.
- **Keputusan dibutuhkan** dari desainer (daftar bernomor, tiap butir dengan opsi dan rekomendasimu).
- Saran commit: pengelompokan file per topik (jangan commit sendiri).

## Batas file (agar tidak bentrok dengan art pass)
Art pass menyentuh `src/client/UI/*` (termasuk `Theme.luau`), `src/client/Minigames/*`, `src/server/World/*`, `Config/Visuals.luau`. Untuk UI baru di roadmap ini, buat **file baru** (mis. `UI/Leaderboard.luau`) dan pakai API `Theme` yang sekarang (`Theme.new/label/button/card/screenGui`); jangan mengubah `Theme.luau`.

## Aturan keras
- Server selalu otoritatif; tidak ada nilai dari klien yang dipercaya. Remote baru didaftarkan di `Remotes.luau` dan divalidasi di server. Jangan ubah kontrak remote lama tanpa alasan tertulis.
- **Jangan revert atau timpa perubahan yang belum di-commit.** Jalankan `git status` dulu; sentuh hanya file langkahmu.
- **Jangan commit** kecuali diminta. Bila diminta: tanpa baris atribusi/"Co-authored-by".
- Teks pemain lewat `Strings.luau` (ID dulu, ada EN). Semua target fiktif (D7). Pagar monetisasi PLAN §3.7 berlaku.
- Logika baru wajib punya tes di `tests/specs/`. Jangan menghapus atau melemahkan tes yang ada.
- Data pemain tersimpan: perubahan schema harus lewat migrasi (`PlayerData.migrate`) dengan tes, dan tidak boleh merusak save lama.

## Verifikasi (jalankan sebelum tiap checkpoint)
```bash
lune run tests/run.luau        # harus "All N tests passed"; jumlah boleh naik, tidak boleh ada yang gagal
```
Hal yang tidak bisa diuji di Lune harus ditandai jelas **belum diverifikasi di Studio/Roblox**; jangan mengklaim sudah berfungsi.
