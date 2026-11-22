# Cara kerja bareng di Juragan Desa

Tim: **@miralami** (pemilik, designer, satu-satunya yang menyetujui merge ke `main`), **Willy** (kode
dan umum), **Ragun** (desain, 3D, map). Masing-masing bekerja dengan agen AI (opencode untuk
@miralami, Claude Code untuk Willy dan Ragun). Aturan untuk agen ada di `AGENTS.md` bagian
"Team and authority"; Claude Code membacanya otomatis lewat `CLAUDE.md`.

## Aturan merge

- `main` adalah branch kerja utama sejak 22 Nov 2026. Hanya @miralami (dan agen opencode miliknya)
  yang push langsung ke `main`. Willy dan Ragun selalu lewat Pull Request.
- `CODEOWNERS` menunjuk @miralami untuk semua file, dan `main` mewajibkan review dari code owner.
  Artinya PR hanya bisa di-merge setelah @miralami menyetujuinya.
- CI (workflow **Tests**, job `unit`) harus hijau: `lune run tests/run.luau` dan `selene src`.
- Branch `track/*` adalah branch lama agen dan tidak dipakai lagi. Jangan push ke sana.

## Branch

- Willy: `willy/<topik>`, contoh `willy/fix-bribe-cooldown`.
- Ragun: `ragun/<topik>`, contoh `ragun/pasar-stall-model`.
- Satu topik per branch, PR kecil lebih cepat direview.
- `main` bergerak cepat karena opencode push terus. `git pull origin main` sebelum mulai, dan
  rebase ke `main` terbaru sebelum buka PR.

## Pembagian area

| Area | Pemilik utama | Folder |
|---|---|---|
| Gameplay, server, client, data, remotes | Willy | `src/server`, `src/client`, `src/shared` (selain visual) |
| Tes, tooling, CI | Willy | `tests/`, `tools/`, `.github/workflows/` |
| Model 3D, Blender, aset, map, terrain | Ragun | `assets/`, `docs/v2/visual/art/` |
| Teks pemain | Willy (Ragun cek bahasa) | `src/shared/Strings.luau` |
| Kandidat visual (LookDev), world dressing | opencode, review oleh @miralami | `src/server/World/LookDev*`, `docs/v2/visual/` |
| Keputusan desain, verdict visual | @miralami | `docs/v2/visual/CANDIDATES.md`, `DECISIONS.md` |

Dua orang jangan mengubah file yang sama di waktu yang sama. Kalau harus, bilang dulu di chat.
Fitur gameplay baru belum boleh dimulai sebelum Gate 1 lolos (`docs/v2/plan/MASTER_PLAN.md` §4);
tugas pertama yang cocok untuk Willy ada di `docs/testing/BUGS.md` dan `docs/testing/GATE1.md`.

## Setup

1. Pasang [Rokit](https://github.com/rojo-rbx/rokit), lalu jalankan `rokit install` di root repo.
   Ini memasang rojo, lune, selene, stylua dan luau-lsp dengan versi yang dikunci di `rokit.toml`.
2. Kalau butuh paket Wally di `Packages/`, jalankan `wally install` (tes dan CI tidak memerlukannya).
3. Jalankan `lune run tests/run.luau` sekali untuk memastikan semua lolos.
4. Pasang plugin Rojo di Studio, lalu `rojo serve` dan connect.

## Studio dan place

- Semua script diedit lewat Rojo di repo, **bukan** di Studio. Perubahan script di Studio akan
  tertimpa sync berikutnya.
- Untuk ngoding dan tes, pakai **salinan place pribadi** (File → Save to Roblox As, ke akun atau
  slot sendiri). Jangan sync Rojo ke place utama lewat Team Create, karena dua sync bisa saling
  timpa.
- Place utama (terrain, map, `ServerStorage.LookDevAssets`) hanya disimpan dan di-publish oleh
  @miralami. Ragun mengirim model dan perubahan map lewat PR (file model di `assets/`) atau lewat
  `.rbxm` yang diserahkan ke @miralami.
- File `.rbxl`/`.rbxlx` tidak pernah di-commit (sudah di `.gitignore`).

## Aset dan rahasia

- Upload aset sebaiknya ke Roblox Group game ini, supaya ID-nya bisa dipakai semua orang.
- Setiap asset ID baru dicatat di `docs/v2/visual/art/ASSET_MANIFEST.md`. Jangan mengarang ID.
- Tiap orang memakai Open Cloud key sendiri di env var `ROBLOX_API_KEY`. Jangan pernah
  menaruh key di file, log, atau commit.

## Review visual

Perubahan yang mengubah tampilan dilampiri screenshot Studio di PR. Keputusan apakah tampilan
dipakai tetap di @miralami, lewat sheet review HTML seperti biasa.

## Arah proyek

Arah dan keputusan desain dipegang @miralami. File arah (`docs/v2/plan/MASTER_PLAN.md`,
`WORK_QUEUE.md`, `DECISIONS.md`, verdict di `docs/v2/visual/CANDIDATES.md`, `AGENTS.md`) hanya diubah
oleh @miralami. Kalau menurutmu arahnya perlu diubah, tulis usulannya di deskripsi PR atau di chat.
Agen AI kalian sudah diberi aturan yang sama, jadi cukup minta tugas ke agen seperti biasa.
