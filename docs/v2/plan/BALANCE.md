# Economy & Balance Simulation Report — Juragan Desa v2

Tanggal: 2026-11-19  
Status: **LUNE-ONLY** — snapshot regenerate dari `src/shared/Config/*.luau` pada tanggal ini,
divalidasi oleh `lune run tests/run.luau` (1930 passed). Bukan hasil playtest; angka di bawah
adalah nilai konfigurasi aktual, bukan rekomendasi. Source of truth tetap file `Config/*.luau`,
bukan dokumen ini.

---

## 1. Progression Pacing (Laju Kemajuan Pemain)

Tiga pangkat saja yang aktif (`Game.rankOrder`):

| Pangkat (Rank) | Syarat kenaikan | Ubin | Tanaman utama |
|---|---|---|---|
| **Gurem** | awal (cash 50, bibit padi 5) | 6 (bawaan) | padi, singkong |
| **Petani** | `lifetimeEarned` 1.000 | 6+ | jagung, bawang, cabai, tembakau, kopi |
| **Juragan** | `lifetimeEarned` 10.000 **dan** `tilesOwned` 12 | 12+ | tebu, kakao, cengkeh, durian, sawit |

Syarat ada di `Game.rankRequirements`. `maxTiles` 12 tanpa pass, 16 dengan Extra Plot pass;
semua 16 model plot tetap dibangun (`tilesBuilt = 16`) apapun pass-nya.

### Biaya Ekspansi Lahan

Formula: `Game.tilePrice(owned) = 100 * 2 ^ max(0, owned - 6)`.

| Ubin ke- | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|
| Harga | 100 | 200 | 400 | 800 | 1.600 | 3.200 |

Total ekspansi ke 12 ubin: **Rp 6.300** (target lifetime Juragan Rp 10.000).

---

## 2. Daftar Tanaman (`Config/Crops.luau`, 12 komoditas)

ROI = `(sellPrice - seedCost) / seedCost`.

| Tanaman | Bibit | Tumbuh | Jual | ROI | Rank | Rumpun | Regrow / max panen | Izin |
|---|---|---|---|---|---|---|---|---|
| padi | 10 | 60 s | 18 | +80% | gurem | palawija | — | — |
| singkong | 16 | 90 s | 30 | +87,5% | gurem | palawija | — | — |
| jagung | 25 | 120 s | 50 | +100% | petani | palawija | — | — |
| bawang | 35 | 150 s | 72 | +105,7% | petani | palawija | — | — |
| cabai | 60 | 240 s | 140 | +133,3% | petani | palawija | — | — |
| tembakau | 80 | 480 s | 200 | +150% | petani | kebun | 240 s / 3 | — |
| kopi | 110 | 600 s | 280 | +154,5% | petani | kebun | 300 s / 4 | — |
| tebu | 150 | 720 s | 380 | +153,3% | juragan | perkebunan | 360 s / 3 | ya |
| kakao | 180 | 780 s | 460 | +155,6% | juragan | kebun | 390 s / 3 | — |
| cengkeh | 220 | 840 s | 560 | +154,5% | juragan | kebun | 420 s / 3 | — |
| durian | 300 | 900 s | 900 | +200% | juragan | kebun | 450 s / 3 | — |
| sawit | 420 | 1.200 s | 1.300 | +209,5% | juragan | perkebunan | 600 s / 4 | ya |

ROI dasar 80%–209,5% (bukan 50%–125% seperti dokumen lama — nilai lama sudah kedaluwarsa).
`permit = true` masih dibaca tetapi belum ditegakkan (menunggu Balai Desa).

### Rarity (`Config/Tiers.luau`) dan Sifat (`Config/Traits.luau`)

| Tier | chance | multiplier | rare? |
|---|---|---|---|
| biasa | 0,70 | 1× | — |
| bagus | 0,20 | 1,5× | — |
| super | 0,075 | 3× | ya |
| langka | 0,02 | 8× | ya |
| sultan | 0,005 | 25× | ya |

Multiplier nilai ekspektasi ≈ **1,51×** dari harga dasar. `Game.rarityQualityBoost = 1`
(satu poin kualitas minigame ≈ menggandakan bobot tier rare).

Sifat: `oplosan` (hot — ditolak Pasar, dibeli Tengkulak Gelap, disita razia), `basah` (hujan,
35%), `kering` (El Niño, 35%), `organik` (tanpa pupuk, 30%), `bersertifikat` (stempel Balai
Desa, 100%).

### Harga Cabai Meroket (`Game`)

`cabaiEventFirstDelay` 240 s, `cabaiEventInterval` 600 s, `cabaiEventDuration` 300 s,
`cabaiEventMultiplier` 3 — event 3× selama 5 menit tiap 10 menit, mulai 4 menit setelah server
start. Nilai sengaja pendek untuk Studio; naikkan sebelum publish.

---

## 3. Rasio Faucet vs Sink (Arus Kas)

### Faucet
- Penjualan panen (ROI per tanaman di tabel atas), dimodifikasi rarity ± market.
- Nama Baik ±5% di Pasar (`Market.namaBaikMaxBonus = 0,05`, baseline 50 → 1,0).
- Event cabai 3× (lihat atas).
- Quest harian: 3 tugas, reward 80–150 cash + 1–3 Nama Baik per tugas (`Config/Quests`).
- Login streak 7 hari: 100 cash, 5 padi, 250 cash, amplopPremium, 4 cabai, 600 cash,
  jaminanKilat (hari 1–7; reward cash total Rp 950 + item).

### Sink
- Pasar supply & demand (`Config/Market`): `pressurePerItem 0,003`, decay 600 s, floor 0,60×,
  ceiling HET 1,25×. Tengkulak Gelap mengabaikan batas ini.
- Alat permanen (`Config/Tools`): cangkul bambu 60 / baja 350; gembor 150 / sprinkler 600;
  karung besar 200 / gerobak 800; traktor 1.500 (placeholder row planting).
- Ekspansi lahan (tabel §1).
- Buruh tani (`Config/Worker`): sewa 150 / 300 s, upah 2 per item, 20 s/pass, maks 5 item/pass.
- Pinjol & razia (§4).

---

## 4. Analisis Risiko & Imbal Hasil Pinjol (`Config/Pinjol`)

- Limit dasar per pangkat: gurem 500, petani 1.500, juragan 5.000, tuanTanah 15.000,
  sultan 50.000. `calcLimit` diskalakan Nama Baik 0,5×–1,5× (baseline 50).
- Biaya admin 10% di muka; bunga 5%/jam online, 2%/jam offline.
- Plafon keras: total hutang ≤ 3× pokok (`maxDebtMultiplier = 3,0`).
- Jatuh tempo `dueSeconds = 600` (10 menit). Tahap keterlambatan: notifikasi (0 s),
  panggilan publik + Nama Baik −5 (180 s), debt collector menyita hasil gudang (360 s).

### Razia & hukum (`Config/Law`)
- `susMax` 100; gosip 30, surat panggilan 60, razia acak mulai 80 (10% per tick 20 s,
  cooldown 180 s, auto-denda setelah 20 s).
- Denda razia 20% cash (min 50, max 5.000); amplop suap 10%, sukses 75%, gagal ×1,5; penjara 45 s.
- Suap Pak RT: dasar 100, ×1,5 per pengulangan dalam jendela 600 s, cooldown 180 s,
  Nama Baik −10.
- Nama Baik mulai 50 (maks 100): tertangkap −10, viral −20, lapor +2 (maks 10/hari).

---

## 5. Fidelity / performa (`src/client/Feel/FidelityTier.luau`)

Tiga tingkat visual: Rendah / Sedang / Tinggi (default start `Sedang`, auto `Otomatis`).
Ambang frame-time: turun jika rata-rata > 1/45 s, naik jika < 1/57 s; cooldown turun 2 s,
sustain naik 10 s, cooldown naik 30 s, jendela 30 frame, minimal 10 sampel. Perubahan
ditahan saat "moment" (cutscene) aktif. `FpsSampler` (window 60, min 20 sampel) mengabaikan
frame-time > 2 s agar tab-out tidak merusak rata-rata. Setting ini adalah starting point
untuk tuning performa, bukan hasil benchmark perangkat.
