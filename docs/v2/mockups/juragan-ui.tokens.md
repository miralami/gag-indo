# Juragan Desa UI mockups — tokens

**Status:** `UNVERIFIED` — these are design mockups, not screenshots of the game. No Luau was changed.
Copy the values into `src/shared/Config/Visuals.luau` (which feeds `src/client/UI/Theme.luau`) by
hand, after Gate 1 (Master Plan §4).

## Files (all in `docs/v2/mockups/`)

| Screen | PNG | Source | Size |
|---|---|---|---|
| Phone home (HP Juragan) | `phone-home.png` | Canva design `DAHa659hGaM` | 1080×1080 |
| Phone · Kebun | `phone-kebun.png` | Canva design `DAHa65OSbuY` | 1080×1920 |
| Phone · BayarLater | `phone-pinjol.png` | Canva design `DAHa6x31tZk` | 1080×1080 |
| Phone · Tugas | `phone-tugas.png` | `src/screens.html#phone-tugas` | 1080×1920 |
| Phone · Curang | `phone-curang.png` | `src/screens.html#phone-curang` | 1080×1920 |
| Phone · Dekorasi | `phone-dekor.png` | `src/screens.html#phone-dekor` | 1080×1920 |
| Phone · Lapor | `phone-lapor.png` | `src/screens.html#phone-lapor` | 1080×1920 |
| HUD | `hud.png` | `src/screens.html#hud` | 1688×780 |
| Toko Bibit | `toko-bibit.png` | `src/screens.html#toko-bibit` | 1688×780 |
| Papan (leaderboard) | `papan.png` | `src/screens.html#papan` | 1688×780 |
| Minigame (Mencangkul) | `minigame.png` | `src/screens.html#minigame` | 1688×780 |
| Razia overlay | `razia.png` | `src/screens.html#razia` | 1688×780 |

The three Canva screens are AI-generated raster images. Canva has no SVG export for them, and its
credit quota ran out after three jobs, so the other nine screens are hand-authored HTML that uses
exactly the tokens below. Re-render them with `docs/v2/mockups/src/render.ps1` (headless Edge).
Portrait screens are 360×640 pt at 3×; landscape screens are 844×390 pt at 2×.

## Color

The HTML mockups use the current palette unchanged. The Canva colors were sampled from the PNGs.
They drift warmer and more saturated than the palette, so treat them as candidates, not
replacements.

| Token (`Visuals.palette`) | Current | Canva sample | Used for |
|---|---|---|---|
| `kertas` | `#f3e9d2` | `#fbeccc` / `#faf0dd` | page and card fill |
| `tinta` | `#2b2118` | `#442510` (dominant dark) | outline, shadow, text |
| `tinta_lembut` | `#5b4a38` | `#695540` | muted text, locked items |
| `senja` | `#f6c97a` | `#f3d69b` (chips) | highlight row, tip card |
| `padi` | `#9bb25a` | `#8ea239` (Toko Bibit icon), `#99af71` (section tab) | progress, shop header |
| `daun` | `#6f8a3f` | `#768d2c` (Kebun icon), `#798955` (Kebun header) | Kebun, Siram, Klaim |
| `genteng` | `#a8452f` | `#c2502a` (BayarLater icon) | Curi, BayarLater |
| `merah` | `#a83226` | `#ba381f` (Curang), `#cf3a22` (loan header), `#bd301c` (warning) | Curang, close X, Sus |
| `bambu` | `#b98a5a` | `#c39875` (Kebun buttons) | neutral button |
| `kunyit` | `#c99a2e` | `#e4a530` (Tugas), `#ebaa32` (Pinjam buttons) | money, primary buy |
| `indigo` | `#3b4f6b` | `#244960` (Dekorasi) | Dekorasi header |
| `malam` | `#1f4e6b` | `#284f67` (Lapor) | Lapor, HP button |

Text on a colored fill follows `Theme.contrastText`: ink on `daun`, `padi`, `kunyit`, `senja`,
`bambu`; paper on `genteng`, `merah`, `indigo`, `malam`, `tinta`.

## Type (`Visuals.type`, `Visuals.fonts`)

| Token | px | Font | Seen as |
|---|---|---|---|
| `display` | 28 | Luckiest Guy | minigame title; Razia title is 40 (one-off) |
| — | 22 | Luckiest Guy | phone nav title, modal header (not a token yet; candidate `title = 22`) |
| `heading` | 18 | Luckiest Guy / Nunito 800 | section headers, card titles |
| `body` | 13 | Nunito 800–900 | rows, buttons |
| `small` | 11 | Nunito 800 | chips, hints, counts |

## Size, spacing, shape

| Token | Value | Seen as |
|---|---|---|
| `space.xs` | 4 | button vertical padding |
| `space.sm` | 8 | gap in rows, button horizontal padding |
| `space.md` | 12 | card padding, gap between cards, page margin |
| `space.lg` | 16 | modal inner padding |
| `space.xl` / `xxl` | 24 / 32 | unused in these screens |
| `radius.card` | 14 | cards, modals |
| `radius.button` | 10 | buttons, nav buttons |
| `radius.chip` | 8 | chips, icon tiles |
| `outline` | 2 | ink border on every sticker |
| `shadow` | 4 | hard offset, x = y = 4, no blur, ink at 12% transparency |
| `touch` | 44 | minimum button and nav-button size |
| — | 24 | phone status bar height (candidate) |
| — | 56 | phone nav bar height (candidate) |
| — | 32 | icon tile (candidate `icon = 32`) |
| — | 64–76 × 64 | HUD seed slot |
| — | 72 × 56 | HUD right-column action button |
| — | 12 / 16 | progress bar height (normal / Sus meter) |

## Notes for review

- The Canva home and BayarLater came out square although the brief asked for 9:16.
- Canva home: the Sus chip shows an "Rp" coin icon, which is wrong (Sus uses `?` in `Visuals.icons`).
- On the dark Razia background the 2 px ink outline disappears; that overlay may need a paper outline.
- The 11 px `small` size is the game's own token; the design hook flagged it as below 12 px. It is
  left unchanged here and is worth checking on a real phone.
- Admin and Evidence panels are dev tools and were not mocked.
