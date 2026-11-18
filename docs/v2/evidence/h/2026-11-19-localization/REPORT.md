# Localization pass — Track H, 2026-11-19

Build: `track/c-world-look` after `d3b1ea0`, Rojo serving `localhost:34872`. Studio instance
`447c176b-1d7b-4b9c-a794-45912fea4b63`, cloud dev place `Development-Juragan-Desa` (placeId
`132087524375529`, universeId `10776530981`).

**Play Solo only. The place was never saved or published. `profile:Save()` was never called. Play was
stopped and Studio returned to Edit.**

## 1. Keys appended to `src/shared/Strings.luau` (append-only, no reorder)

| Key | id | en |
|---|---|---|
| `cash_label` | `Rp %s` | `Rp %s` |
| `gain_label` | `+Rp %s` | `+Rp %s` |
| `price_label` | `Rp %s` | `Rp %s` |
| `admin_button` | `Admin` | `Admin` |
| `tag_juragan` | `Juragan` | `Juragan` |
| `tag_ordal` | `Ordal` | `Ordal` |
| `plot_empty` | `Lahan Kosong` | `Empty Plot` |
| `plot_owned` | `Lahan %s` | `%s's Plot` |

Numbers are formatted by `Strings.get` (`.` for id, `,` for en), so the two currency templates
keep the existing thousands-separator behaviour without hardcoding "Rp ".

## 2. Hardcoded text routed through Strings

| File | Before | After |
|---|---|---|
| `src/client/UI/Hud.luau` | `"Rp " .. formatNumber(cash)` | `t("cash_label", cash)` |
| `src/client/UI/Tiles.luau` | `"Rp " .. formatNumber(price)` | `t("price_label", price)` |
| `src/client/UI/Admin.luau` | `btn.Text = "Admin"` | `t("admin_button")` |
| `src/client/Feel/ActionFeel.luau` | `"+Rp " .. tostring(earned)` | `Strings.get(lang, "gain_label", earned)` |
| `src/client/Chat/Tags.luau` | `"Juragan"` / `"Ordal"` | `Strings.get(lang, "tag_juragan" / "tag_ordal")` |
| `src/server/Farm/PlotService.luau` | `"Lahan Kosong"` / `"Lahan " .. DisplayName` | `Strings.get(...)` with the new keys |

`ActionFeel.start(lang)` and `Tags.mount(lang)` now take the locale resolved once in `Main.client`,
so every client controller reads the same locale. The plot sign follows the owner's `LocaleId`,
mirroring the existing `DebtCollector.language()` pattern (default `id` for an unclaimed sign).

Glyph-only labels (`""`, `"-"`, `"<"`, `"X"`, `"[L]"`, `"|||| 4G [===]"`) are symbolic, not words;
they are explicitly allowlisted by the integrity spec rather than translated.

## 3. Spec extension — `tests/specs/strings_integrity_spec.luau`

Added a source scanner that flags any word-like string literal assigned to a `*Text` property
anywhere under `src/` (excluding `Strings.luau` itself). Glyphs with no ASCII letters and the four
documented symbolic labels are exempt; every other hit generates a `[BUG]` case naming the exact
literal and file, plus a summary case asserting zero stragglers. A self-test feeds synthetic sources
to the scanner to prove it catches `"Selamat pagi"` / `PlaceholderText = "Nama"` while ignoring empty,
glyph and numeric labels. Current run: **zero stragglers found**; the self-test passes.

## 4. Proof

- `lune run tests/run.luau`: **1750 passing** (was 1732; +8 new key-format cases, +8 new key-reference
  cases, +2 scanner cases). `selene src`: 0 errors, 3 pre-existing warnings in untouched files, 0 parse errors.
- **Studio client VM:** the live HUD cash label rendered `Rp 35,857` — the value comes from
  `cash_label` and the comma separator confirms the en-us Studio client resolved to `en` by design
  (`Strings.langFor`); the `Tags` module loaded with `mount` present. No new Output errors.
- **Studio server VM:** all 9 unclaimed plot signs rendered `Lahan Kosong` from the `plot_empty` key;
  all 8 new keys returned their expected id/en values from the live `Shared.Strings` module.
  Console contained only the normal server-start / ProfileStore lines and an unrelated Assistant
  plugin version warning.
- **Status:** text wiring `SEEN-IN-STUDIO` (this report); key integrity + scanner `LUNE-ONLY`
  (`strings_integrity_spec.luau`, `plot_failure_spec.luau`).
