# Sintesis: audit ChatGPT × Master Plan × referensi (2026-11-14)

Bahan: `Juragan_Desa_Audit_dan_Checklist_Agent_dengan_Gambar.pdf` (teks di `.md` sebelahnya, 2 gambar
lampiran diperiksa langsung), 10 foto/gambar referensi di folder ini, `realistic tutorials.txt`,
`MASTER_PLAN.md`, `BUGS.md`, `GATE1.md`, `DECISIONS.md`, `ART.md`, `RESEARCH_VISUAL_TIPS.md`, dan kode.
Tidak ada kode yang diubah. Status memakai kata Master Plan §7.

## 0. Fakta penting dulu

- **Screenshot audit = build HEAD (`29023ed`).** Capture Studio hari ini (sesi Play yang sedang
  terbuka) identik dengan Gambar 2 di PDF: posisi, `RP 90,788`, pohon, kios biru, pagar. Jadi kritik
  outsider berlaku untuk build sekarang, bukan build lama. Ini juga satu-satunya pandangan manusia atas
  world-look pass (`RESEARCH_VISUAL_TIPS.md` §2 menulis "not seen by a human").
- **Label masih menumpuk setelah fix BUG-008.** Di frame yang sama: "BAR…AG…TE…" dan "SI DESADESA PT"
  bertumpuk di belakang kios. BUG-008 tercatat fixed `LUNE-ONLY` tanpa screenshot sesudah fix.
  → BUG-008 sebaiknya dibuka lagi (major).
- **Arah seni yang diputuskan tidak berubah; kodenya yang melenceng.** D11/`ART.md`: cat tangan +
  kontur tinta, "no default Roblox plastic look", tekstur painted. Pass tips dari video "realistic"
  memakai `Enum.Material.Grass` untuk kanopi pohon dan semak (`Flora.luau:151,192`,
  `Details.luau:194`) serta WoodPlanks/Slate untuk props. Itulah tekstur "berbulu" yang disebut audit
  sebagai visual noise dan gaya yang tidak menyatu. Audit benar tentang gejalanya tanpa tahu D11 ada.

## 1. Tujuh tindakan berurutan (rekomendasi)

| # | Tindakan | Track | Menutup / memengaruhi |
|---|---|---|---|
| 1 | Buka lagi BUG-008 (label menumpuk di build HEAD). Ambil screenshot sebelum/sesudah saat memperbaiki. | C + H | G2, G4b, Q1 |
| 2 | Kembalikan world-look ke D11: kanopi/semak/props pakai warna palet polos (SmoothPlastic) dan simpan tekstur painted untuk nanti. Kurangi foreground (pohon kiri di spawn). Pertimbangkan perf: 30 fps di max pada Xiaomi 12 Lite, 27 Highlight, ±160 part baru. | C | G4, G6 |
| 3 | **Tujuan berikutnya setelah tutorial.** Kartu panduan hilang setelah langkah "buy" dan Tugas Harian tersembunyi di HP > Tugas. Tampilkan satu objective aktif di HUD (tugas harian berikutnya / syarat rank berikutnya, "Rp 640 / 1.000 menuju Petani"). MVP §0 mensyaratkan "always a clear next goal". | D (+B) | MVP Progression, G7 |
| 4 | **Hierarki HUD**: uang besar; karung dan objective di bawahnya; Sus dan Nama Baik jadi chip berikon dengan penjelasan saat pertama muncul. Seed bar hanya menampilkan bibit yang dimiliki (bukan semua x0), dan diberi ikon. Banner cabai: warna peluang (kunyit/daun, bukan merah) + sisa waktu (`cabaiEventDuration` sudah ada). | D | G4, G4b |
| 5 | **Beat sheet** (track B): padi tutorial ±20 dtk (sekarang 60 dtk → G5 tidak mungkin lulus), Bagus/Super yang dijamin, raid NPC tetangga sebelum menit 7. Ini jawaban untuk "identitas lokal masuk ke mekanisme": satirenya sudah ada, hanya tidak terlihat di 10 menit pertama. | B + F | G3, G5 |
| 6 | **Desainer: buat Open Cloud key (D-G1).** Semua slot ikon/tekstur masih `0` (35 di `Visuals.luau`), sehingga "image icons everywhere" dan G4 tertahan di sini. Ini pembuka terbesar yang hanya bisa dilakukan desainer. | designer → G | G4 |
| 7 | **Feedback aksi + audio**: hanya 3 suara terpasang (musik desa, musik pasar, ambience). Semua UI/sting masih `0`, jadi hampir semua aksi masih tanpa suara. `Feel/` baru berisi CameraFeel (FOV). | A + E | G4 "no silent action" |

## 2. Audit benar, dan sudah ada di Master Plan (konfirmasi independen)

| Kritik audit | Di plan | Catatan |
|---|---|---|
| Rapikan fondasi sebelum menambah fitur | §2 aturan 2, §8 | Sama persis. Abaikan dorongan fitur baru. |
| Satu siklus tanam–panen–jual harus memuaskan | MVP §0, track A | |
| Onboarding 3–5 menit dengan reward cepat | Beat sheet §4 | Beat sheet lebih ambisius; pakai beat sheet. |
| Feedback tanam/siram/panen/jual + ambience | Track A, E | Belum dikerjakan; lihat tindakan 7. |
| Uji mobile, low graphics, server-authority, DataStore | Quality bar Q2–Q7, TECH | |
| Bukti screenshot sebelum/sesudah, DoD | §7 | Audit hampir menyalin prosedur kita. |

## 3. Audit benar, dan merupakan temuan baru / kurang ditekankan

| Temuan | Bukti di kode | Usulan |
|---|---|---|
| Gaya visual campur, noise tekstur | `Enum.Material.Grass` di bola kanopi/semak | Tindakan 2. |
| Tidak ada objective setelah tutorial | `Onboarding.steps` cuma 4; `Hud.luau:232` menyembunyikan kartu | Tindakan 3. |
| Seed bar terbaca seperti "inventory nol" | `Hud.luau:269` membuat tombol untuk semua crop yang terbuka, teks saja | Audit sendiri salah membacanya sebagai daftar panen; itu bukti UX-nya gagal. |
| "Sus" tidak jelas | `hud_sus` sama di id/en, tidak ada penjelasan | Pertahankan katanya (satire), tambah tooltip/onboarding. |
| Event harga berwarna "bahaya", tanpa durasi | `Hud.luau:144` `Theme.merah` | Tindakan 4. |
| Spawn menghadap batang pohon | Capture hari ini | Atur arah spawn/kamera, sebelum menambah dekor. |
| Bahasa campur | Desainer selalu melihat EN karena Studio en-us (BUG-007); D6 "ID-first + pemilih bahasa" **belum ada di kode** (`Main.client.luau:22` hanya `langFor`) | Implementasi D6: default `id` + pemilih bahasa, atau setidaknya override admin agar desainer melihat versi ID. |
| Golden hour tidak terbaca | `clockTime` 16.0–16.9 sudah benar, tapi layar tetap terlihat siang biru | Tuning warna/atmosfer, bukan jam. |
| Ekonomi tanpa keputusan | Profit/menit per petak naik lurus: padi 8, singkong 9, jagung 12,5, bawang 15, cabai 20, tembakau 33, kopi 40 … sawit 96 | Di dalam satu rank, crop terbaru selalu menang, kecuali saat event cabai x3 (±60/mnt). Rarity, izin, stok toko dan main aktif vs idle mengubah angkanya sedikit. **Masuk Phase 2** (simulasi balance), bukan Gate 1. |

## 4. Audit salah, kurang info, atau harus menunggu gate

| Klaim audit | Kenyataan |
|---|---|
| Format "Rp 90.788" disarankan | Sudah begitu untuk `id`; layar EN karena locale Studio. |
| Objective/tutorial mungkin tidak ada | Ada (4 langkah); di screenshot sudah selesai. Masalahnya yang terjadi *setelah* tutorial. |
| Identitas lokal masih sekadar dekorasi | Mekanik lokal = satire (Sus, razia, amplop, BayarLater, debt collector). Masalahnya: tidak terlihat di sesi pertama (Master Plan §1). |
| Gotong royong, koperasi, pasar mingguan, proyek desa, festival panen | Bagus, tapi itu Phase 2/3. Tetap ditahan sampai gate-nya lulus. |
| "Stylized low-poly" sebagai art direction | Jangan diam-diam mengganti D11. Gambar konsep audit (desa low-poly cerah) sebenarnya dekat dengan D11 minus kontur. Pilih sadar, lihat §5. |
| Arahan tema "wholesome" (gotong royong, harvest festival) | Bertentangan dengan pilar "the satire is the product". Ambil hal yang wholesome sebagai latar, satire tetap inti. |

## 5. Keputusan untuk desainer

> **Sudah diputuskan 2026-11-14:** desainer memilih **cartoonish realism**: bentuk chunky dan
> stylized, material bertekstur Roblox (acuannya Warung). Usulan "flat SmoothPlastic" di bawah sudah
> dicoba di Studio dan ditolak. Kritik audit soal noise dijawab lewat komposisi, variasi warna, dan
> kepadatan, bukan dengan mencabut tekstur. Lihat D11 di `DECISIONS.md`.

1. **D11 dipertahankan atau direvisi?** Opsi A: tetap cat tangan + kontur (kerjanya lebih banyak:
   tekstur painted dan ikon perlu key D-G1). Opsi B: flat stylized low-poly tanpa tekstur dan kontur
   hanya untuk interaktif (lebih murah, lebih ringan di HP, tetap kohesif). Rekomendasi: **B sebagai
   langkah sekarang, A sebagai lapisan nanti.** Keduanya membuang material Grass/WoodPlanks.
2. **Wilayah inspirasi.** Foto referensi menunjuk ke **Jawa**: balai desa joglo, genteng, warung
   anyaman bambu + seng, saung di sawah, caping, irigasi beton. Usul: Jawa (Tengah/DIY) sebagai
   jangkar arsitektur, vegetasi, dan soundscape gamelan (sudah dipakai).
3. **Bahasa default** untuk pemain non-`id` (D6 belum terimplementasi).
4. **Open Cloud key** (D-G1): kapan dibuat.

## 6. Cara memakai referensi

- **Foto nyata** (pasar becek, warung bambu, balai desa joglo, sawah + saung, irigasi, warung kopi
  gorengan): ambil *bentuk dan kepadatan* (atap genteng menjorok, payung pasar, keranjang hijau,
  spanduk tulisan tangan, motor parkir, kabel). Ini yang membuat "Indonesia" terbaca, bukan label.
  Pasar = payung + keranjang plastik warna-warni + karung; warung = anyaman + renteng kemasan + bangku
  kayu.
- **Referensi game**: ambil tekniknya, jangan tampilannya. Tekniknya: kartu "tugas saat ini" dan
  "Plants 32/50" sebagai hierarki HUD, kartu alat kontekstual di kanan bawah, efek tumbuh besar, papan
  jual/beli fisik di dunia dengan ikon. Gambar Roblox-garden tampaknya mockup AI (ada salah ketik), jadi
  jadikan acuan arah, bukan target persis. Jangan menyalin game tertentu.
- **Video tutorial "realistic"**: teknik yang tetap berguna: lapisan vegetasi, 60/30/10, variasi
  rotasi/skala, kontras bayangan, ambience. Yang tidak cocok untuk D11: tekstur realistis.
  `RESEARCH_VISUAL_TIPS.md` sudah memisahkan ini, tapi implementasinya masih memakai material bertekstur.
