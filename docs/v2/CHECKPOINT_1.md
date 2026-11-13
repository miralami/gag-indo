# CHECKPOINT 1 — M4 selesai

Tanggal: 2026-11-12
Lingkup: FASE A (`A1`–`A4`) dari `HANDOFF_ROADMAP.md`.

## Daftar langkah

| Langkah | Status | Catatan |
|---|---|---|
| A1 Leaderboard | selesai | Logika murni + service diperkuat + UI client baru |
| A2 Monetisasi | selesai (id tetap `0`) | Item §3.7 ditambahkan; efek server berjalan; harga/ID menunggu D9 |
| A3 Analytics | selesai | Satu modul, funnel + ekonomi + event kustom, `docs/v2/ANALYTICS.md` |
| A4 Tes alur pinjol penuh | selesai | Eskalasi berurutan, kolektor, penyitaan berulang, rejoin |

Semua langkah A1–A4 selesai. Tidak ada langkah yang dilewati. Yang tidak bisa diputuskan
tanpa desainer dicatat di bagian "Keputusan dibutuhkan".

## File diubah dan dibuat

### Dibuat
- `src/shared/Leaderboard.luau` — logika papan (sanitasi nilai, urutan, tie-break, top-N) tanpa state.
- `src/client/UI/Leaderboard.luau` — panel ringkas 3 papan + papan `SurfaceGui` opsional di part ber-tag `LeaderboardBoard`.
- `src/server/Economy/DebtCollector.luau` — kolektor greybox di plot (part + billboard), bisa diganti art pass.
- `tests/specs/analytics_spec.luau` — 20 tes wrapper analytics.
- `tests/specs/leaderboard_spec.luau` — 34 tes logika + service papan.
- `tests/specs/passes_spec.luau` — tes pass/produk baru.
- `docs/v2/ANALYTICS.md` — kontrak event, tabel sku ekonomi, funnel, apa yang tidak dikirim.

### Diubah
- `src/server/Social/LeaderboardService.luau` — pcall + retry terbatas, throttle tulis, cache nama, validasi payload, tidak menerima nilai klien.
- `src/client/Main.client.luau` — mount `UI/Leaderboard`.
- `src/shared/Config/Products.luau` — pass `gudangBesar`, `autoPanen`; produk `restockToko`, `rupiahKecil/Sedang/Besar` (semua id `0`).
- `src/server/Monetization/Receipts.luau` — `applyGrant` menangani `restock` dan `cash`; id `0` tidak pernah menyentuh Roblox.
- `src/server/Monetization/Passes.luau` — `publishEffects` untuk atribut pass baru.
- `src/server/Economy/ShopService.luau` — `restockNow` (roll baru, bukan siklus gratis).
- `src/shared/ShopStock.luau` — `roll(cycle, userId, musim, nonce)` dengan nonce tersimpan.
- `src/server/Farm/WorkerService.luau` — `wageFor`/`active` sadar pass Auto-Panen.
- `src/server/Economy/StorageService.luau` — kapasitas membaca `Pass_GudangBesar`.
- `src/shared/Config/Game.luau` — `gudangBaseCapacity = 40`, `gudangPassCapacity = 120`.
- `src/server/Analytics/Analytics.luau` — ditulis ulang (budget, `once`, ekonomi, funnel, pcall).
- `src/server/Economy/EconomyService.luau` — semua mutasi kas lewat satu titik + log ekonomi (`options.sku`).
- `src/server/Economy/DebtService.luau` — alur pinjol penuh + `bindRaid`/`bindCollector` + `onLoaded`.
- `src/server/Main.server.luau` — mengikat `RaidService.isBusy` dan kolektor ke `DebtService`.
- Instrumentasi A3: `FarmService`, `ToolService`, `QuestService`, `OnboardingService`, `BribeService`, `CheatService`, `RaidService`, `EvidenceService`, `Cosmetics`, `AdminService`, `BadgeService`.
- `src/shared/Strings.luau` — string pinjol/kolektor baru.
- `src/shared/Remotes.luau` — remote yang dipakai alur baru (tidak mengubah kontrak lama).
- Tes: `tests/lib/Env.luau`, `tests/lib/Fakes.luau` (fake `AnalyticsService` + recorder), `tests/run.luau`, `debt_spec`, `receipts_spec`, `shop_spec`, `worker_spec`, `economy_spec`, `config_spec`, `seasons_spec`.

## Ringkasan perubahan

- **A1** — `Leaderboard.luau` memvalidasi angka (NaN/inf/negatif ditolak atau di-clamp sesuai papan), urutan deterministik dengan tie-break UserId, ambil top-N. Service: tulis di-throttle, gagal DataStore tidak mematikan game, nama di-cache, payload dari server saja. UI client memvalidasi payload sebelum render dan memakai `Theme` + `Strings`.
- **A2** — Pass Gudang Besar menaikkan kapasitas (40 → 120), Auto-Panen membuat buruh gratis/permanen, Restock Toko melakukan roll baru dengan nonce tersimpan (tidak bisa diulang dengan receipt sama), Rupiah pack masuk lewat `EconomyService.addCash(..., earned=false)` supaya tidak menaikkan rank/leaderboard. `grant` tetap berupa kunci data, bukan fungsi.
- **A3** — Satu wrapper `Analytics` dengan `track/once/economy/onboarding/funnel`, budget global 60 detik (`120 + 20 × #Players`), semua panggilan dibungkus pcall, `once` per pemain per event, field kustom literal, tanpa data pribadi. Ekonomi dilog di `EconomyService.addCash/trySpend/transfer` dengan `sku`; saldo yang dicatat adalah `data.cash` setelah commit. Memakai API Roblox asli (`LogEconomyEvent`, `LogOnboardingFunnelStepEvent`, `LogFunnelStepEvent`), bukan hanya `LogCustomEvent`.
- **A4** — Pinjam diblokir saat raid. Tahap telat berjalan berurutan (bisa melompat beberapa tahap setelah offline): peringatan → spam HP → aib publik + kolektor + Nama Baik → penyitaan gudang tiap tick sampai lunas. Setelah lunas pinjaman hilang dan kolektor pergi. Utang + bunga tersimpan setelah rejoin; kolektor dipanggil ulang saat rejoin bila masih telat.

## Hasil tes

```
lune run tests/run.luau
All 458 tests passed
```

Baseline handoff: 386 tes. Sekarang 458 (+72), tidak ada tes yang dihapus atau dilemahkan.

## Belum diverifikasi (tidak bisa diuji lewat Lune)

- **DataStore nyata** untuk leaderboard: retry, throttle, dan budget sebenarnya hanya terbukti di Studio dengan DataStore aktif.
- **`ProcessReceipt` Roblox**: id masih `0`, jadi alur pembelian nyata belum pernah dipanggil. Idempotensi receipt diuji lewat fake, bukan lewat Roblox.
- **Game pass / atribut pass nyata**: `publishEffects` diuji dengan fake attribute; perilaku `MarketplaceService` nyata belum.
- **`AnalyticsService` nyata**: API asli tidak tersedia di Lune; yang diuji adalah wrapper + fake. Rate limit dan retensi event Roblox belum terlihat.
- **Tampilan** `UI/Leaderboard` dan papan `SurfaceGui`: belum dijalankan di Studio (ukuran, layout HP, teks meluber).
- **Kolektor greybox** (`DebtCollector`): bentuk/posisi di plot belum dilihat di Studio.
- **Eskalasi pinjol lintas sesi**: diuji dengan `onLoaded`/`tick` langsung; loop `task.spawn` tidak bisa dijalankan di fake `Env`.

## Keputusan dibutuhkan

1. **D9 — ID dan harga pass/produk.** Semua masih `0`, jadi tombol disembunyikan. Butuh: id Game Pass `gudangBesar`/`autoPanen`, id Developer Product `restockToko`, `rupiahKecil/Sedang/Besar`, plus harga Rupiah. Rekomendasi: buat di Creator Dashboard, isi `Products.luau`, jangan ubah kode lain.
2. **Isi Rupiah pack.** `cash` sengaja `0` (keputusan balance). Opsi: (a) tetapkan sekarang, (b) biarkan `0` sampai B2 balance pass. Rekomendasi: (b), lalu isi sekali di `Config/`.
3. **Kapasitas Gudang Besar.** Dipakai 120 vs base 40 (3×). Ini angka usulan, bukan dari desainer. Opsi: 80/120/160. Rekomendasi: 120, ditinjau di B2.
4. **Harga & perilaku Auto-Panen.** Saat ini: buruh gratis + permanen selama pass aktif, dan menyewa saat sudah punya pass adalah sukses tanpa efek. Opsi: gratis total vs diskon upah vs batas jumlah buruh. Rekomendasi: gratis total (paling mudah dibaca pemain).
5. **Restock Toko.** Saat ini roll baru dengan nonce tersimpan, jadi satu pembelian = satu stok baru. Opsi: roll baru vs isi ulang ke stok maksimum. Rekomendasi: roll baru (mencegah pembelian berulang untuk menumpuk item langka).
6. **Tampilan kolektor.** Greybox part + billboard. Butuh art pass (W5) atau aset NPC. Rekomendasi: ganti di art pass, jangan tambah model sekarang.

## Saran commit (jangan di-commit tanpa diminta)

- `feat(leaderboard): logika papan, service, dan UI` — `src/shared/Leaderboard.luau`, `src/server/Social/`, `src/client/UI/Leaderboard.luau`, `src/client/Main.client.luau`, `tests/specs/leaderboard_spec.luau`.
- `feat(monetization): pass gudang/auto-panen, restock, rupiah pack` — `Config/Products.luau`, `Config/Game.luau`, `Receipts.luau`, `Passes.luau`, `ShopService.luau`, `ShopStock.luau`, `WorkerService.luau`, `StorageService.luau`, `tests/specs/passes_spec.luau`, `receipts_spec.luau`, `shop_spec.luau`, `worker_spec.luau`.
- `feat(analytics): wrapper event, ekonomi, funnel + dokumen` — `server/Analytics/Analytics.luau`, instrumentasi service, `docs/v2/ANALYTICS.md`, `tests/specs/analytics_spec.luau`, `tests/lib/*`.
- `feat(debt): alur pinjol penuh + kolektor` — `server/Economy/DebtService.luau`, `DebtCollector.luau`, `Main.server.luau`, `Strings.luau`, `tests/specs/debt_spec.luau`.
