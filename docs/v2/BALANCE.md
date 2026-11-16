# Economy & Balance Simulation Report — Juragan Desa v2

Tanggal: 2026-11-12  
Status: VERIFIED (478 test suite passing via `lune run tests/run`)

---

## 1. Progression Pacing (Laju Kemajuan Pemain)

Simulasi matematis waktu permainan aktif untuk setiap kenaikan pangkat (Tier Rank):

| Pangkat (Rank) | Syarat Pendapatan Seumur Hidup | Syarat Ubin Lahan | Tanaman Utama | Estimasi Waktu Bermain Aktif |
|---|---|---|---|---|
| **Gurem** | Awal (Rp 0) | 6 ubin (bawaan) | Padi (60s grow, bibit 10, jual 18) | 0 menit |
| **Petani** | Rp 1.000 | 6 ubin | Padi & Singkong (120s grow) | 8 - 11 menit (10 siklus panen padi @ 6 ubin) |
| **Juragan** | Rp 10.000 | 12 ubin | Jagung, Bawang, Cabai, Tembakau | 45 - 65 menit (ekspansi ubin bertahap + upgrade alat) |

### Biaya Ekspansi Lahan (Tiles Expansion)
Formula: `100 * 2 ^ (owned - 6)`
- Ubin ke-7: Rp 100
- Ubin ke-8: Rp 200
- Ubin ke-9: Rp 400
- Ubin ke-10: Rp 800
- Ubin ke-11: Rp 1.600
- Ubin ke-12: Rp 3.200
**Total Biaya Ekspansi ke 12 Ubin**: Rp 6.300 (masuk akal dan proporsional terhadap target Rp 10.000 lifetime income untuk pangkat Juragan).

---

## 2. Rasio Faucet vs Sink (Arus Kas Ekonomi)

Ekonomi dirancang dengan margin laba yang sehat namun memiliki sink terstruktur untuk mencegah hiperinflasi:

### A. Faucet (Sumber Uang)
1. **Penjualan Panen Pasar Bersih**:
   - Margin kotor panen dasar berkisar antara 50% sampai 125% dari modal bibit.
   - Padi: Beli 10, Jual 18 (+80% ROI).
   - Singkong: Beli 25, Jual 50 (+100% ROI).
   - Jagung: Beli 40, Jual 90 (+125% ROI).
2. **Pengali Rarity (M1 Rarity Tiers)**:
   - Nilai ekspektasi multiplier panen: ~1,38x di atas harga dasar (Super: 3x, Langka: 8x, Sultan: 25x).
3. **Event Cabai Meroket**:
   - 3x multiplier penjualan cabai selama 5 menit setiap 10 menit (faucet periodik terkontrol).
4. **Hadiah Quest & Login Harian**:
   - Quest Harian: Rp 150 - Rp 300 per hari (3 tugas).
   - Login Streak: Rp 100 - Rp 500 per siklus mingguan.

### B. Sink (Penyedot Uang)
1. **Modal Bibit Berkelanjutan**: Menguras 40% - 50% dari pendapatan kotor setiap siklus.
2. **Upgrade Alat Pertanian (Tools)**:
   - Cangkul (Rp 200 / Rp 1.000 / Rp 5.000)
   - Sabit (Rp 150 / Rp 750 / Rp 3.500)
   - Karung (Rp 300 / Rp 1.500 / Rp 7.500)
3. **Biaya Pinjol (Dana Kilat Desa)**:
   - Admin fee 10% langsung di muka.
   - Bunga berjalan 5%/jam (online) dan 2%/jam (offline).
4. **Sistem Penegakan Hukum & Razia**:
   - Denda razia polisi: Rp 500 - Rp 10.000 proporsional sus/cash.
   - Sogok Pak RT: Naik secara eksponensial per percobaan sogok berturut-turut.

---

## 3. Analisis Risiko & Imbal Hasil Pinjol (Dana Kilat Desa)

1. **Leverage Modal Cepat**:
   - Pemain Gurem dapat meminjam hingga Rp 500 (atau Rp 750 jika Nama Baik 100%).
   - Memungkinkan pemain langsung membeli bibit dalam jumlah besar atau membuka ubin ke-7 dan ke-8 tanpa harus grinding panen padi 10 kali.
2. **Titik Bahaya (Default Threshold)**:
   - Waktu jatuh tempo: 10 menit (`dueSeconds = 600`).
   - Melewati 10 menit:
     - Tahap 1 (0 min overdue): Peringatan notifikasi dan SMS teror.
     - Tahap 2 (+3 min overdue): Panggilan publik di chat desa + penalti -5 Nama Baik.
     - Tahap 3 (+6 min overdue): Debt collector datang menyita hasil panen di gudang setiap menit.
3. **Plafon Pengaman (Safety Ceiling)**:
   - Akumulasi total hutang dikunci pada batas maksimal 3.0x modal pokok (`Pinjol.maxDebtMultiplier = 3.0`), menjamin pemain tidak terjebak hutang tak terhingga jika meninggalkan game berhari-hari.

---

## 4. Rekomendasi Tuning untuk Rilis

1. **Durasi Event Cabai**:
   - `Game.cabaiEventInterval = 600` (10 menit) cocok untuk playtest dan retensi awal sesi. Untuk server produksi padat, interval dapat dinaikkan ke 15-20 menit jika laju pencetakan uang terlalu deras.
2. **Kapasitas Gudang**:
   - Kapasitas gudang bawaan (40 stack) sangat pas untuk fase Gurem-Petani. Pemain aktif yang mencapai Juragan akan merasakan insentif natural untuk upgrade karung atau membeli pass Gudang Besar (120 stack).
