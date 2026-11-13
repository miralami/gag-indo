# FTUE & Retention Audit Report — Juragan Desa v2

Tanggal: 2026-11-12  
Status: VERIFIED (Walkthrough 5 menit pertama lancar, loop retensi D1-D7 terpasang dan tervalidasi).

---

## 1. Walkthrough 5 Menit Pertama (FTUE)

Alur terpandu sesi pertama pemain baru (`Onboarding.steps`):

| Waktu | Target / Langkah | Aksi Pemain | Indikator Sukses / Feedback |
|---|---|---|---|
| **0:00 - 0:30** | **Step 1: Plant** | Spawn di plot sendiri, bibit padi otomatis terseleksi di hotbar, tap ubin kosong pertama. | Minigame Mencangkul (3 tap swinging needle), ubin berubah status jadi `growing` (timer 60s). Kartu panduan HUD aktif. |
| **0:30 - 1:30** | **Step 2: Harvest** | Menunggu pertumbuhan padi matang. Mengetuk ubin matang (`ready`). | Minigame Babat (sweet-spot gauge), hasil panen masuk ke karung (`Produce`), kartu panduan berlanjut ke Pasar. |
| **1:30 - 2:45** | **Step 3: Sell** | Berjalan menuju area Desa (Pasar), mendekati NPC Tengkulak Pasar. | Interaksi ProximityPrompt / tombol Jual di Pasar. Uang tunai masuk (`Cash`), toast terjual muncul, notifikasi step selesai. |
| **2:45 - 3:45** | **Step 4: Buy** | Menuju Toko Bibit (NPC Mbak Sri) atau buka shelf toko di HUD. | Membeli bibit Padi/Singkong, uang terpotong, bibit masuk bag. Toast: *"Panen perdana selesai! Selamat jadi Juragan Desa."* Kartu tutorial selesai dan disembunyikan. |
| **3:45 - 5:00** | **Discovery (HP Juragan)**| Pemain mengetuk tombol HP di pojok kanan atas untuk mengeksplorasi App Grid. | Membuka App Grid HP: melihat status Gudang, Pinjol (BayarLater), Tugas Harian, dan Toko Dekorasi. |

---

## 2. Friction Points & Perbaikan yang Telah Dilakukan

1. **Ukuran Tombol Mobile (<44px)**:
   - *Friction*: Tombol awal pada layar sempit rawan salah sentuh (fat-finger).
   - *Solusi (W2)*: Seluruh tombol interaktif utama (toko, navigasi HP, close dialog, minigame) diperbesar menjadi minimal 44px tinggi/lebar sesuai standar ergonomi mobile.
2. **Navigasi Tab HP Horizontal Terlalu Padat**:
   - *Friction*: 6 tab teks horizontal pada v1 sulit dibaca dan terpotong di layar HP berorientasi vertikal atau sempit.
   - *Solusi (W2)*: Dirombak menjadi Beranda Grid Aplikasi (Home Grid) dengan icon kartu besar dan tombol Back `<` 44px.
3. **Penyembunyian Menu Curang Selama Onboarding**:
   - Sesuai prinsip desain GDD §4.4, tutorial tidak pernah menyuruh pemain berbuat curang. Menu curang dan Tengkulak Gelap dibiarkan menjadi kejutan organik (emergent gameplay) yang ditemukan pemain setelah memahami loop bertani jujur.

---

## 3. Audit Mekanisme Retensi (D1 — D7)

1. **Quest Harian (Daily Tasks)**:
   - 3 tugas di-roll deterministik per pemain setiap hari (berdasarkan calendar day integer).
   - Variasi tugas: Panen X tanaman, Simpan di gudang, Siram tanaman tetangga, Jual hasil panen.
   - Memberikan insentif harian Rp 150 - Rp 300 + Nama Baik.
2. **Login Streak (7 Hari Beruntun)**:
   - Kalender berulang 7 hari dengan hadiah bertahap:
     - Hari 1: Rp 100
     - Hari 2: 3x Bibit Singkong
     - Hari 3: 2x Amplop Sogokan
     - Hari 4: Rp 250
     - Hari 5: 3x Bibit Jagung
     - Hari 6: 1x Jaminan Kilat (Bailout Penjara)
     - Hari 7: Rp 500
   - Mengabaikan 1 hari mereset streak ke hari 1, mendorong D1-D7 retention.
3. **Pinjol (Dana Kilat Desa) Engagement Loop**:
   - Memberikan modal instan di awal, tetapi memaksa pemain tetap aktif selama 10 menit berikutnya agar tidak terkena penalti debt collector.
4. **Papan Peringkat Desa (Leaderboard)**:
   - Kategori Pendapatan Tertinggi (`topEarned`), Juragan Terkaya (`topCash`), dan Korban Razia Terbanyak (`topRaids`).
   - Mendorong kompetisi sosial antar pemain di desa.
