# Delegation prompt — paste this into the other AI agent

```
Kamu mengerjakan repo Roblox "Juragan Desa" (Rojo + Luau + Lune).

SETUP (wajib, urut)
1. git fetch origin && git checkout track/c-world-look && git pull origin track/c-world-look
   (jangan kerja di main: main di remote ketinggalan 69 commit)
2. Baca AGENTS.md, lalu "Progress tracker" di docs/v2/MASTER_PLAN.md baris atas.
   Itu sumber kebenaran: apa yang selesai, apa berikutnya, di mana buktinya.
3. Baca docs/testing/BUGS.md dan docs/testing/GATE1.md sebelum mulai. Bug lebih penting dari fitur.
4. Jalankan `lune run tests/run.luau`. Harus hijau (614 lulus saat ini) sebelum dan sesudah kerja.
5. Dunia dibangun saat runtime dari src/ lewat Rojo (`rojo serve`, plugin Rojo di Studio).
   JuraganDesa.rbxl di-gitignore dan tidak ikut git. Setelah pull, WAJIB `rojo serve` dan
   Connect di Studio, lalu Play; kalau tidak, Studio tampak "tidak berubah".

ATURAN
- Status hanya: SEEN-IN-STUDIO, LUNE-ONLY, UNVERIFIED, BLOCKED. Klaim tanpa file di
  docs/v2/evidence/ bukan SEEN-IN-STUDIO.
- Jangan karang asset ID, product ID, harga, UserId. Jangan publish. Jangan simpan JuraganDesa.rbxl.
- ROBLOX_API_KEY hanya dari env, jangan dicetak/di-log/di-commit. Catat tiap ID upload di
  docs/v2/art/ASSET_MANIFEST.md.
- Teks pemain di src/shared/Strings.luau dengan varian id dan en.
- Belum ada fitur gameplay baru sebelum Gate 1 lulus (MASTER_PLAN §4).
- Commit tiap pekerjaan selesai, per topik, tanpa baris atribusi, dan centang tracker di commit
  yang sama (status + path bukti + "Last updated"). Jangan push kecuali diminta.

TUGAS (urut)
1. G: set ikon pertama via Open Cloud (tanaman, mata uang, app phone). Ganti ikon huruf.
   Buka blokir G4. Catat ID di ASSET_MANIFEST.md.
2. D: uji halaman app Phone di ukuran iPhone 14 dengan tap asli; simpan bukti di docs/v2/evidence/d/.
3. C: sisa dunia — foto teras sawah + sungai, setel 3 preset musim, finalisasi spawn dan golden-hour.
4. Rapikan tracker: bagian "Next up" masih menyebut A+E padahal sudah [x].

LAPOR
Per tugas: file yang disentuh, jumlah tes, status word, path bukti, dan hal yang BLOCKED.
Baca diff sendiri sebelum bilang selesai; ringkasan bukan bukti.
```

## Catatan untuk Sena

- "Pull tidak berubah" karena `track/c-world-look` belum pernah di-push. Remote hanya punya `main`,
  yang tertinggal 69 commit dari branch ini.
- Studio tidak ikut git: tempatnya `JuraganDesa.rbxl` (gitignored). Perubahan masuk lewat `rojo serve`
  (`dev.bat`) + plugin Rojo Connect, lalu Play.
