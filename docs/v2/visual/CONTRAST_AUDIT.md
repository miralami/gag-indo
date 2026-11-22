# CONTRAST_AUDIT — UI text contrast (WORK_QUEUE item 125)

> Audited 2026-11-22. Static source audit; **no visual verdict** (no Roblox Studio session, no
> screenshot). CHECK id `CONTRAST`.

## Method

Lune/source proxy: every `TextLabel` / `TextButton` call site in `src/client/UI/**` was read and its
`TextColor3` token paired with the nearest **opaque** authored `BackgroundColor3` token (walking
`Parent` frames; `Theme.button` defaults to `Theme.panelLight` = `bambu`, `Theme.card` to
`Theme.panel` = `kertas`). Where the label has its own `TextStrokeColor3`, the stroke token is used
instead of the background, matching the item's "(or the stroke)" clause.

Contrast uses the WCAG relative-luminance algorithm already implemented in
`src/client/UI/Theme.luau:53-73`, computed from the palette hex in
`src/shared/Config/Visuals.luau:9-23`:

```
L = 0.2126 R + 0.7152 G + 0.0722 B   (each channel linearised: c/12.92 if c<=0.03928 else ((c+0.055)/1.055)^2.4)
ratio = (max(L1,L2)+0.05)/(min(L1,L2)+0.05)
```

Thresholds: **4.5:1** for normal text, **3:1** for text **>=24 px**. None of the audited failing
sites is >=24 px, so every FAIL below uses 4.5:1. This is a token-pair proxy, not a live-instance
measurement: transparent/gradient/dynamic `Color3` values cannot be scored from source and are
listed as not scored, never as PASS.

## Token pairs found in UI call sites

`ratio` is the computed WCAG ratio. `verdict` uses the threshold above. `resolution` is `-`
(no action needed), `fixed`, `stroke-backed` (ink outline supplies the contrast) or
`designer decision` (see below).

| Text token | Background token | Ratio | Verdict | Resolution | Sites (file:line) |
|---|---|---:|---|---|---|
| kertas | kertas | 1.00 | FAIL | stroke-backed | Phone.luau:400 (app tile label, `TextStrokeColor3 = Theme.ink` -> 13.05 vs stroke) |
| kunyit | kertas | 2.14 | FAIL | fixed | Admin.luau:338 |
| kertas | bambu | 2.54 | FAIL | stroke-backed | Hud.luau:365 (`TextStrokeColor3 = Theme.ink` -> 13.05) |
| tinta_lembut | bambu | 2.76 | FAIL | fixed | Leaderboard.luau:163 (inactive tab) |
| merah | padi | 2.83 | FAIL | fixed | Hud.luau:273 |
| daun | kertas | 3.23 | FAIL | fixed | Phone.luau:1031 |
| kertas | padi | 1.95 | FAIL | stroke-backed | Hud.luau:356 (`TextStrokeColor3 = Theme.ink` -> 13.05) |
| senja | merah | 4.30 | FAIL | fixed | RaidOverlay.luau:61 |
| genteng | kertas | 4.89 | PASS | - | Hud.luau:57-63 (`susColor` mid band) |
| tinta | bambu | 5.13 | PASS | - | RaidOverlay.luau:180,188; Leaderboard.luau:162-163 (inactive tab after fix) |
| merah | kertas | 5.52 | PASS | - | Admin.luau:224; Evidence.luau:124; Hud.luau:461; Leaderboard.luau:58,198; Minigame.luau:60; PhoneWidgets.luau:40; RaidOverlay.luau:103,133; Phone.luau:986,997,1009 |
| kertas | merah | 5.52 | PASS | - | RaidOverlay.luau:53,219 |
| tinta | kunyit | 6.11 | PASS | - | Hud.luau:202; Leaderboard.luau:163 (active tab) |
| tinta | padi | 6.68 | PASS | - | Hud.luau:184,284; Phone.luau:207 |
| tinta_lembut | kertas | 7.01 | PASS | - | Admin.luau:129,232; Evidence.luau:133; Hud.luau:470; Leaderboard.luau:96; Minigame.luau:69; Phone.luau:478,618,647,861,1126 (and 1009 dynamic inkSoft); RaidOverlay.luau:121 |
| kertas | malam | 7.37 | PASS | - | Phone.luau:145,157,190,1350; Evidence.luau:138-143 (button `Theme.contrastText(Theme.malam)`) |
| tinta | kertas | 13.05 | PASS | - | Hud.luau:151,202; Phone.luau:453,504,662,748,898,954,1109,1113; RaidOverlay.luau:111,184,192; Theme.luau:291 (rarity chip) |
| kertas | tinta | 13.05 | PASS | stroke-backed | Hud.luau:366,418; Phone.luau:406 (ink `TextStrokeColor3` / outline) |

Not scored (no token-driven opaque background in UI source): `Tiles.luau:163,166,169` — those
`TextLabel`s are created in `src/server/World/Greybox.luau` / `Props.luau` as world billboards, not
by a UI token call site. `Theme.toast` (`Theme.luau:356`) and `Icons.make` (`Icons.luau:82`) use
runtime `Theme.contrastText`; every token they can receive is covered by a PASS row above.

## Fixes applied (exact theme-token swaps, no new colours)

| File:line | Before | After | Ratio before -> after |
|---|---|---|---|
| `src/client/UI/Admin.luau:338` | `Theme.accent` (kunyit) | `Theme.text` (tinta) | 2.14 -> 13.05 |
| `src/client/UI/Leaderboard.luau:163` | inactive tab `Theme.muted` (tinta_lembut) | `Theme.text` (tinta) | 2.76 -> 5.13 |
| `src/client/UI/Hud.luau:273` | `Theme.merah` | `Theme.text` (tinta) | 2.83 -> 6.68 |
| `src/client/UI/Phone.luau:1031` | `Theme.daun` | `Theme.text` (tinta) | 3.23 -> 13.05 |
| `src/client/UI/RaidOverlay.luau:61` | `Theme.senja` | `Theme.paper` (kertas) | 4.30 -> 5.52 |

Every swap keeps the same call site, the same theme module and an existing palette token. No colour,
font, size or layout was introduced.

## Counts

- Before: 18 scored token pairs, 8 FAIL pairs (5 plain, 3 stroke-backed).
- After: 18 scored token pairs, 3 FAIL pairs — all 3 stroke-backed (`Theme.ink` outline supplies
  13.05:1). Plain FAILs: 5 -> 0; FAIL rows: 8 -> 3.
- All 18 pairs are unique; the spec checks every table row's computed ratio.

## Decisions for designer

- `kertas` on `kertas` at `Phone.luau:400`, `kertas` on `bambu` at `Hud.luau:365` and `kertas` on
  `padi` at `Hud.luau:356` remain token FAILs by background, but each call site authors a `Theme.ink`
  `TextStrokeColor3` with `TextStrokeTransparency = 0` (Phone:407, Hud:418). Against the stroke the
  ratio is 13.05:1, so the text passes under the item's "or the stroke" clause. Changing the text
  token would fight the sticker-outline art direction; left unchanged as stroke-backed.
- `Tiles.luau:163,166,169` (world billboard labels) have no token-driven background in UI source;
  scoring them needs live instances and a vision pass. Not changed, not graded.
- No plain FAIL was left unchanged: a better-contrast existing token was available for all five.
