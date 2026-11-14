# Juragan Desa UI mockups — tokens

**Status:** `UNVERIFIED` — design mockups, not screenshots of the game. No Luau was changed. Copy
values into `src/shared/Config/Visuals.luau` (which feeds `src/client/UI/Theme.luau`) by hand after
Gate 1 (Master Plan §4).

## Files (`docs/v2/mockups/`)

Pass 2 (2026-11-15) rebuilt every screen in one HTML source after an audit and critique: one
visual language, one drawn SVG icon set, and the missing states. Source:
`src/screens.html` (open without a hash for the gallery); re-render with `src/render.ps1`
(headless Edge). Portrait 360×640 pt at 3× (1080×1920); landscape 844×390 pt at 2× (1688×780).

| Screen | PNG | What it shows |
|---|---|---|
| HP home | `phone-home.png` | Sus meter with raid mark, Nama Baik, Pangkat, 8 apps with badges |
| Kebun · Karung | `phone-kebun.png` | bag with today's market price per crop, Gudang |
| Kebun · Alat & Buruh | `phone-kebun-alat.png` | tool upgrade with effect, maxed tool, farm hand |
| BayarLater | `phone-pinjol.png` | satire kept; every Pinjam shows the repay total and interest |
| Tugas | `phone-tugas.png` | streak with day-7 reward preview, claimable task first |
| Curang | `phone-curang.png` | Siram primary; Curi is hold-to-confirm with its Sus cost; cooldown |
| Dekorasi | `phone-dekor.png` | worn / owned / buy / locked states; rarity by icon + frame, not colour alone |
| Lapor | `phone-lapor.png` | record, evidence with report outcome, usable items (matches `Phone.luau`) |
| HUD | `hud.png` | money, Sus meter, event, bag, crop slots, locked slot with rank, actions |
| HUD · bag full | `hud-penuh.png` | full-bag state with the two ways out |
| Toko Bibit | `toko-bibit.png` | buy one / all, not-enough-money, sold out with restock, rank locks |
| Papan | `papan.png` | 44 px tabs, top 3, gap marker, own row, distance to next rank |
| Minigame | `minigame.png` | striped target zone (not colour only), Auto moved away from TAP |
| Razia | `razia.png` | each choice states its outcome; labelled countdown; no skip button |
| Razia · result | `razia-hasil.png` | outcome, deltas, and why Sus rose |

The three first-pass Canva images are kept for reference in `canva/` (`DAHa659hGaM`,
`DAHa65OSbuY`, `DAHa6x31tZk`). Canva offered no SVG export and its credits ran out.

## Color

| Token (`Visuals.palette`) | Current | Mockup | Note |
|---|---|---|---|
| `kertas` | `#f3e9d2` | same | page, cards |
| `tinta` | `#2b2118` | same | contour, shadow, text |
| `tinta_lembut` | `#5b4a38` | same | muted text, disabled border |
| `senja` | `#f6c97a` | same | selected tab, highlight |
| `padi` | `#9bb25a` | same | shop, progress, Pakai |
| `daun` | `#6f8a3f` | **`#7c9846` (proposed)** | ink on `#6f8a3f` is 4.04:1 and fails AA at 13 px; `#7c9846` gives 4.83:1 |
| `genteng` | `#a8452f` | same | BayarLater |
| `merah` | `#a83226` | same | Sus, Curang, close, badges |
| `bambu` | `#b98a5a` | same | neutral button |
| `kunyit` | `#c99a2e` | same | money, primary buy |
| `indigo` | `#3b4f6b` | same | Dekorasi |
| `malam` | `#1f4e6b` | same | HP, Lapor |
| — | — | `kertas_2 #e9dcbd` (candidate) | dock, disabled fill, icon wells |
| — | — | `kertas_3 #fbf4e3` (candidate) | inner tiles, highlighted card |

Text on a colour follows `Theme.contrastText` (ink on padi, daun, kunyit, senja, bambu; paper on
genteng, merah, indigo, malam, tinta). On the dark Razia screen the sticker contour flips to
`kertas` with a `merah` shadow, because an ink contour on ink is invisible.

## Type (`Visuals.type`, `Visuals.fonts`)

| Token | px | Font | Seen as |
|---|---|---|---|
| `display` | 28 | Luckiest Guy | minigame title, raid result; raid headline 40 (one-off) |
| — | 22 | Luckiest Guy | phone nav and panel titles (candidate `title = 22`) |
| `heading` | 18 | Nunito 800 | section headers, key numbers |
| `body` | 13 | Nunito 800–900 | rows, buttons |
| `small` | 11 | Nunito 800 | sublabels, hints, counts |

## Size, spacing, shape

| Token | Value | Seen as |
|---|---|---|
| `space.xs / sm / md / lg` | 4 / 8 / 12 / 16 | button padding / row gap / card padding and gap / panel padding |
| `radius.card / button / chip` | 14 / 10 / 8 | cards and panels / buttons / chips, icon wells, tiles |
| `outline` | 2 | contour on every sticker and tile |
| `shadow` | 4 | hard offset, no blur; only on top-level stickers, never on tiles inside a panel |
| `touch` | 44 | every control, including tabs and Semua buttons (were 36 and 28) |
| — | 24 / 56 / 68 | phone status bar / nav bar / bottom dock (candidates) |
| — | 64 | home app icon; 36 icon well; 24 inline icon |
| — | 76×68 | HUD crop slot; 84×56–64 HUD action buttons |
| — | 12 / 16 | progress bar / Sus meter; 3 px threshold mark |

## Patterns introduced

- **Bottom dock** on every phone app (Beranda, Tutup) so leaving is in thumb reach; top bar keeps
  only Back.
- **Consequence sublabel** under any action that costs Sus, money or reputation.
- **Hold-to-confirm** for harmful actions (Curi); helpful action takes the primary slot.
- **Threshold mark** on the Sus meter at the raid level (80 in the mockup; take the real value from
  config).
- **Tile vs sticker:** items inside a panel get the outline only; the shadow stays on the panel.

## Copy and data to confirm (mockup values, not from config)

- "Karung" replaces "Isi Tas" for the crop bag so HUD and phone agree; "Isi Tas" now names the
  usable-items list on Lapor, as `Phone.luau` does. New strings: raid outcome sublabels, Sus
  explanation, day-7 reward line, "Kurang Rp N", BayarLater repay lines.
- Prices, interest (30%), raid threshold (80), Sus deltas and player names are placeholders. Check
  them against `src/shared/Config/` before building.

## Detector notes

`impeccable detect` after pass 2: the hard-offset shadow (87, advisory) and 11 px text are the
game's own tokens; status/nav "cramped padding" is a verified false positive (ignored for this file
in `.impeccable/config.json`); remaining "nested cards" are outline-only tiles inside panels (shop
grid, raid deltas), kept on purpose; one low-contrast hit is text over the scenery backdrop measured
against the gallery colour.
