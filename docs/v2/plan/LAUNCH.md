# Launch Readiness & Store Packaging — Juragan Desa v2

Tanggal: 2026-11-12  
Status: READY FOR PUBLISHING REVIEW

---

## 1. Roblox Experience Questionnaire (Rating & Kepatuhan)

| Kategori Kuesioner | Jawaban Terpilih | Justifikasi / Catatan Kebijakan |
|---|---|---|
| **Age Recommendation** | **9+ (Mild Humor & Simulated Lending)** | Mengandung parodi hukum desa (razia polisi kartun, amplop sogokan) dan simulasi kredit (pinjol) tanpa transaksi uang riil. Bebas kekerasan grafis, darah, atau konten dewasa. |
| **Violence** | None / Mild Cartoon | Tidak ada aksi fisik kekerasan atau senjata api. Penjara direpresentasikan sebagai Pos Ronda santai. |
| **Gambling / Paid Random Items**| None | Tidak ada lootbox berbayar dengan mata uang nyata. Rarity panen diperoleh murni melalui gameplay (minigame & bibit gratis). |
| **Simulated Gambling** | None | Tidak ada mekanik kasino atau judi. |
| **Alcohol / Tobacco Reference** | Mild Reference (Tembakau) | Komoditas pertanian "Tembakau" murni berupa daun mentah tanaman agronomi tanpa visual rokok menyala atau konsumsi. |
| **Monetization Policy** | Compliant | Seluruh GamePass dan Developer Product memberikan manfaat jelas dan terdokumentasi, mematuhi Roblox Commerce & In-Game Purchases policy. |

---

## 2. Spesifikasi Aset Toko (Store Packaging)

### A. Game Icon (512 x 512 px PNG)
- **Komposisi**: Close-up karakter petani tersenyum ceria memakai Caping bambu tradisional, memegang seikat padi emas berkilau.
- **Gaya Visual (visual/ART.md)**: Garis tepi tebal 2px tinta hitam kartun, palet warna cerah (`padi`, `senja`, `genteng`), hard drop shadow 4px, kontras tinggi tanpa gradien fotorealistik.
- **Fokus Mobile**: Siluet terbaca jelas pada ikon kecil berukuran 64x64 px di layar smartphone.

### B. Thumbnail Showcase (1920 x 1080 px PNG — Rasio 16:9)
1. **Thumbnail 1 (Hero / Daya Tarik Utama)**:
   - Pemandangan terasering sawah hijau desa dengan latar Gunung Merapi kartun saat golden hour. Karakter juragan bergaya di depan lumbung padi dengan tulisan plang desa: "DESA MAKMUR".
2. **Thumbnail 2 (Aksi Komedi / Razia Polisi)**:
   - Mobil patroli Polisi Desa dengan lampu rotator kuning kartun tiba di ladang. Banner "BREAKING NEWS: OPERASI SAPU BERSIH!", karakter petani panik mencoba menyembunyikan botol pupuk oplosan.
3. **Thumbnail 3 (Fitur HP / Dana Kilat)**:
   - Tampilan mockup HP Juragan berlayar besar dengan App Grid ("BayarLater", "Gudang", "Tugas"), menampilkan tumpukan gepokan uang rupiah kartun yang melimpah.

---

## 3. Deskripsi Game Toko (Store Copywriting)

### Bahasa Indonesia (Utama)
```markdown
🌾 Selamat datang di JURAGAN DESA! Bangun kerajaan pertanianmu dari petani gurem bermodal cangkul bambu sampai menjadi Juragan Terkaya di desa!

🚜 FITUR UTAMA:
• Tanam 12 komoditas nusantara: Padi, Singkong, Jagung, Bawang, Cabai, Tembakau, Kopi, Tebu, Kakao, Cengkeh, Durian, hingga Sawit!
• Jual hasil panen di Pasar Desa atau cari jalan pintas di Tengkulak Gelap.
• Waspada Operasi Sapu Bersih Polisi Desa! Siapkan amplop atau menginap di Pos Ronda!
• Butuh modal kilat? Ajukan pinjaman di BayarLater (Dana Kilat Desa), tapi jangan sampai dikejar debt collector!
• Beli alat modern, sewa buruh tani otomatis, dan lengkapi kostum tradisionalmu (Caping, Batik, Akik).

👍 Like & Favoritkan game ini untuk update musim dan komoditas baru!

Tags: simulator, farming, indonesia, juragan, tycoon, roleplay, desa, sawah, santai
```

### English (Global)
```markdown
🌾 Welcome to JURAGAN DESA (Village Tycoon)! Rise from a humble peasant with a bamboo hoe to the wealthiest Landlord in the village!

🚜 GAME FEATURES:
• Grow 12 authentic tropical crops: Rice, Cassava, Corn, Chili, Coffee, Cocoa, Durian, and Oil Palm!
• Sell your fresh harvest at the Village Market or take high risks with the Black Market.
• Watch out for Village Police raids! Slip an envelope or spend time at the Guard Post!
• Need fast cash? Apply for a Village Fast Loan, but beware of aggressive debt collectors!
• Upgrade farming tools, hire automated farmhands, and collect traditional Indonesian outfits!

👍 Like & Favorite the experience for new seasonal updates!

Tags: simulator, farming, indonesia, tycoon, crops, village, economy, casual
```

---

## 4. Daftar Periksa Pra-Peluncuran (Pre-Launch Checklist)

- [x] **DataStore Session Lock**: Skema migrasi v3 terverifikasi via unit tests, tidak ada risiko data wipe atau rollback saat reconnect.
- [x] **Pemeriksaan Otoritas Server & Remote**: 23 remote client->server diaudit, type checked, dan dilindungi rate limit token-bucket (`RateLimit.luau`).
- [x] **Zero Emoji Compliance**: Seluruh teks UI dan data `Strings.luau` bersih dari emoji 4-byte UTF-8, digantikan sistem slot icon procedur ASCII chip.
- [x] **Touch Target 44px**: Seluruh tombol interaktif HUD, Toko, dan HP memenuhi standar ergonomi layar sentuh mobile.
- [ ] **Konfigurasi Product & Pass IDs**: Mengganti placeholder ID `0` pada `Products.luau` dan `Passes.luau` dengan ID produk rill yang dibuat di Creator Dashboard.
- [ ] **Konfigurasi Badge IDs**: Mengisi ID badge rill di `Badges.luau`.
- [x] **Kalibrasi Audio**: Sound effects dan ambient area telah diuji, tidak ada audio peaking atau clipping.

---

## 5. Rencana Pemantauan Pasca-Peluncuran (Post-Launch Monitoring)

1. **Target Retensi D1**: Target ambang batas > 35% pada cohort pemain mobile Indonesia.
2. **Crash & Error Rate**: Dibatasi maksimal < 1,0% dari total sesi client (dipantau via Roblox Analytics & Crash logs).
3. **Pemeriksaan Inflasi Ekonomi**:
   - Memantau rasio rata-rata saldo kas per kelompok jam bermain (1 jam, 6 jam, 24 jam).
   - Menjaga rasio Faucet vs Sink agar pemain Juragan tetap memiliki insentif membeli tanah baru dan meng-upgrade gudang.
