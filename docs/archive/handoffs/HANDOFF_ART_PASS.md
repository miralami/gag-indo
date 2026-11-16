# Prompt untuk opencode: art pass Juragan Desa (semua workstream)

Tempel semua isi di bawah garis ini ke opencode (jalankan dari root repo).

---

Kamu melanjutkan game Roblox "Juragan Desa" (Luau, Rojo, repo ini). Tugasmu: **menerapkan art bible ke seluruh game**, bukan hanya UI: UI kit, tanaman dan rarity, dunia 3D, NPC, VFX, dan tekstur. Hasil kerjamu di-review dan diverifikasi oleh reviewer lain (Claude) di tiap CHECKPOINT. **Kerjakan berurutan tanpa menunggu persetujuan dan berhenti hanya di checkpoint.** Bila terhalang keputusan desainer, jangan menebak dan jangan berhenti: catat di laporan checkpoint ("Keputusan dibutuhkan"), lewati bagian itu, lanjutkan yang tidak terhalang.

## Baca dulu (wajib, urut)
1. `docs/v2/ART.md` — art bible. Sumber kebenaran: palet, garis, rarity, tipografi, lighting.
2. `docs/v2/DECISIONS.md` — D1 (revisi UI), D5 (pinjol = "BayarLater"), D7 (NPC plesetan), D11 (arah art).
3. `docs/v2/mockups/index.html` dan `docs/v2/art/moodboard.html` — buka di browser.
4. `docs/v2/PLAN.md` §3.1 sampai §3.2 — gaya per permukaan, tanaman dan rarity.
5. Kode terkait tiap workstream (disebut di bawah).

## Kondisi sekarang
- **Lighting sudah selesai** (`Seasons.luau`, `Sky.luau`). Jangan diubah. `Lighting.Technology = Future` diset manual di Studio.
- **UI:** `src/client/UI/Theme.luau` masih v1 (panel gelap, FredokaOne, sudut membulat, tanpa outline). Emoji masih dipakai (`Hud.luau`). ±33 `Color3.fromRGB` hardcoded di `Hud`, `Phone`, `RaidOverlay`, `Admin`, `Tiles`, `Minigames/*`.
- **Dunia:** `src/server/World/Greybox.luau` (409 baris) menyusun bangunan dari Part kotak dengan material default Roblox. `Map.luau` sudah mendukung CollectionService tag, tapi peta Studio belum ada. `Props.luau` kecil (57 baris).
- **NPC:** `NpcFactory.luau` membangun NPC dari kode tanpa gaya.
- **Tanaman:** logika rarity sudah ada (`Config/Tiers.luau`: biasa, bagus, super, langka, sultan; `Traits`, `Crops`: 12 tanaman). Belum ada visual per tier, ikon, atau efek reveal.
- **Aset gambar:** tidak ada sama sekali. Semua `rbxassetid` bernilai 0. Kamu **tidak bisa** membuat gambar/tekstur; yang bisa: kode, struktur, placeholder prosedural, dan spesifikasi untuk dibuatkan.

## Prinsip
- Semua yang butuh gambar dibuat **berjalan tanpa aset** (id `0` = fallback prosedural yang sudah on-palette), lalu aset asli tinggal diisi id-nya. Jangan menunggu aset.
- Hanya warna dari palet ART.md §3. Warna baru ditambahkan ke ART.md dulu, bukan hardcode.
- Satu sumber konfigurasi visual di `src/shared/Config/` (mis. `Visuals.luau`), bukan angka tersebar.
- Logika murni yang baru wajib punya tes di `tests/specs/`.

## Workstream (kerjakan urut; berhenti hanya di CHECKPOINT)

### W1 — UI kit (Theme + Icons)
- Ganti palet `Theme.luau` ke token ART.md; **jangan hapus field lama** (`panel, panelLight, accent, text, muted, green, red, blue`) dan jangan ubah signature `Theme.new/label/button/card/screenGui/toast`. Petakan ke warna baru; kontras teks minimal 4.5:1.
- Komponen stiker: outline tinta 2px + bayangan offset keras 4px kanan-bawah, tanpa blur.
- Skala tipe 28/18/13/11 (tidak ada teks fungsional < 11), spasi 4/8/12/16/24/32, tombol >= 44px.
- Font: uji kandidat ART.md §8 (display `LuckiestGuy`/`Bungee`, body `Merriweather`/`Nunito`); satu konstanta yang mudah diganti; catat pilihannya di laporan.
- `src/client/UI/Icons.luau`: nama ikon -> asset id (semua `0`), fallback tampilan teks/bentuk sederhana (bukan emoji). Ini pengganti semua emoji.
- Selesai bila: game tetap jalan dengan semua layar lama, tidak ada emoji baru, tes lulus.

### W2 — Layar UI (per layar, satu laporan per layar)
- **HUD + Toko Bibit** (`Hud.luau`): HUD lebih playful dan tidak terlalu bersih; Toko Bibit sedikit lebih Roblox-ish (bukan v1 polos, bukan generik). Hapus emoji.
- **HP** (`Phone.luau`): home berbentuk grid aplikasi seperti HP asli; chat digeser sedikit ke playful; pinjol = BayarLater. Hanya tampilan, jangan ubah logika/remote.
- **Surat Panggilan / Raid** (`RaidOverlay.luau`, `Evidence.luau`): poles ke kit baru, mockup sudah dianggap bagus.
- **Layar lain** (`Tiles`, `Minigame`, `Minigames/*`, `Admin`): ganti `Color3` hardcoded ke token Theme.
- Selesai bila: tidak ada `Color3.fromRGB` di luar `Theme.luau` kecuali dengan alasan tertulis.

### >>> CHECKPOINT 1 — UI selesai (W1, W2). Tulis `docs/archive/handoffs/ART_CHECKPOINT_1.md`, berhenti.

### W3 — Tanaman dan rarity (visual)
- `Config/Visuals.luau`: tabel tampilan per tier sesuai ART.md §7 (bingkai, efek, warna). Tambahkan hex ungu untuk Langka ke ART.md §3 dulu.
- Chip/bingkai rarity sebagai komponen Theme dipakai di inventori, panen, almanak, toko.
- **Rarity reveal** saat panen (bingkai muncul, glow, partikel, stinger memakai sound registry yang sudah ada). Biasa tanpa fanfare; Sultan paling heboh.
- Model dunia tanaman per tahap (bibit, tumbuh, siap) dibuat **prosedural dari Part** dengan siluet jelas dan warna palet, sebagai placeholder sampai ada model asli. Titik integrasi: `FarmService`/tile client (`UI/Tiles.luau`, `World/*`).
- Selesai bila: satu sesi panen menampilkan perbedaan tier yang jelas; tes untuk tabel Visuals (setiap tier punya entri, warna valid).

### W4 — Dunia 3D (sementara menunggu peta Studio)
- Rework `Greybox.luau` dan `Props.luau` ke ART.md §5: palet, warna aksen per hub (Pasar merah, Balai Desa kunyit, Pos Polisi malam, Warung genteng+seng, sawah padi), siluet atap yang diekspresikan.
- Kontur objek penting: `Highlight` outline atau inverted hull warna tinta, ketebalan turun menurut jarak (hanya objek dalam ±60 stud). Latar tanpa garis.
- Set dressing di sekitar hub (kabel, motor, jemuran, karung, galon) dengan **instancing/model bersama**, bukan Part unik per instance. Ruang antar hub dibiarkan lapang.
- Terrain: sawah terasering dan sungai memakai Terrain (`FillBlock`/`FillBall`), warna dari palet.
- `SurfaceAppearance` hook: modul kecil yang memakai tekstur bila id ada, fallback ke Color+Material saat id `0` (lihat W6).
- **Pertahankan kontrak tag** `Map.luau` (`PasarPrompt`, `PlotAnchor`+`Index`, `NpcSpawn`+`Npc`, `WeatherZone`) supaya peta Studio nanti bisa menggantikan Greybox tanpa ubah logika.
- Selesai bila: tidak ada tampilan "plastik halus" default; fps tidak turun (catat jumlah instance sebelum/sesudah).

### W5 — NPC
- Buat kartu desain per NPC berulang di `docs/v2/art/npcs.md`: siluet, satu fitur berlebihan, satu aksesori khas, tiga warna dari palet, suara. Parodi sesuai D7 (persona akurat, nama dan wajah diubah).
- `NpcFactory.luau`: proporsi karikatur (kepala besar via skala R15, `HeadScale`), aksesori dari Part, outline selalu aktif, 3-4 state wajah (netral, marah, sombong, panik) bila memungkinkan tanpa gambar.
- Pemain tetap R15 asli, jangan diubah.
- Selesai bila: tiap NPC bisa dikenali dari siluet saja.

### >>> CHECKPOINT 2 — tanaman, dunia, NPC (W3 sampai W5). Tulis `docs/archive/handoffs/ART_CHECKPOINT_2.md`, berhenti.

### W6 — Tekstur dan ikon: spesifikasi untuk dibuatkan
Kamu tidak bisa membuat gambar, jadi hasilkan dokumen siap kerja:
- `docs/v2/art/TEXTURES.md`: daftar 6-8 tekstur (bambu, genteng, seng, paving, sawah, kertas, tanah) dengan ukuran, tileable, palet, arah cahaya, dan **prompt generasi** per tekstur.
- `docs/v2/art/ICONS.md`: daftar ikon (12 tanaman, alat, 5 tier, mata uang, ikon UI di `Icons.luau`) dengan ukuran, sudut pandang, arah cahaya (kiri-atas, hangat), kontur tinta, latar transparan, dan prompt generasi.
- Slot id kosong sudah ada di kode (W1, W4); dokumen ini memetakan nama slot ke berkas yang harus dibuat.

### W7 — VFX dan motion
- Partikel hanya warna palet; sparkle berbentuk kecil tangan-gambar (placeholder prosedural bila belum ada tekstur).
- Motion UI: ease-out cepat dengan overshoot kecil (stempel menghantam, badge pop), tidak ada yang > 0.3 dtk.
- Screen shake hanya untuk raid dan reveal Sultan.
- Selesai bila: reveal, raid, dan toast terasa hidup tanpa mengganggu keterbacaan.

### W8 — QA akhir
- Audit checklist ART.md §11 untuk seluruh layar dan dunia, dalam tiga preset musim dan cuaca (ganti dari panel admin).
- Laporkan fps/jumlah instance, apa yang gagal checklist, dan yang butuh keputusan desainer.

### >>> CHECKPOINT 3 — selesai (W6 sampai W8). Tulis `docs/archive/handoffs/ART_CHECKPOINT_3.md`, berhenti.

## Aturan keras
- **Jangan ubah** logika server, remote (`src/shared/Remotes.luau`), save data, ekonomi, atau tes yang sudah ada. Ini perubahan visual. Perluasan data hanya di Config visual baru.
- **Jangan revert atau timpa perubahan yang belum di-commit.** Working tree berisi pekerjaan lain (leaderboard, admin, lighting, dokumen). Jalankan `git status` lebih dulu; sentuh hanya file workstream yang sedang dikerjakan.
- **Jangan commit** kecuali diminta. Bila diminta: tanpa baris atribusi/"Co-authored-by".
- Teks UI dari `src/shared/Strings.luau` (ID dulu, ada EN). Jangan hardcode string baru.
- Mobile-first: terbaca di ±320px. Pakai Scale + `UISizeConstraint`.
- Tidak ada emoji, font default, atau warna di luar palet.
- Rojo hanya sync script. Workspace, Terrain tersimpan, dan `Lighting.Technology` ada di place file.
- Jangan mengerjakan audio, monetisasi, atau fitur gameplay baru.

## Cara verifikasi (sebelum melapor)
```bash
lune run tests/run.luau        # harus "All N tests passed" (sekarang 386; boleh bertambah, tidak boleh ada yang gagal)
```
Tes tidak mencakup visual. Untuk tampilan: `dev.bat` (Rojo + Studio), device emulator HP, screenshot tiap perubahan. Bila Studio tidak bisa dijalankan, tulis jelas bahwa tampilan **belum diuji visual**; jangan mengklaim sudah bagus.

## Format laporan tiap checkpoint (`ART_CHECKPOINT_<n>.md`)
- Workstream: selesai / sebagian / dilewati (alasan).
- File diubah/dibuat (daftar).
- Apa yang berubah, 3 sampai 6 butir.
- Hasil `lune run tests/run.luau` (salin baris ringkasnya).
- Yang belum diverifikasi, asumsi, keputusan (mis. font).
- Keputusan dibutuhkan dari desainer (daftar bernomor, opsi dan rekomendasimu).
- Saran commit: pengelompokan file per topik (jangan commit sendiri).
