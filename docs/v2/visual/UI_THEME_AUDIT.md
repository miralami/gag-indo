# UI theme audit — WORK_QUEUE item 123

> 2026-11-22. LUNE-ONLY static source audit. No Studio run, no visual verdict, no redesign.
> Status word: `LUNE-ONLY` (Master Plan §7). Guard: `tests/specs/theme_bypass_spec.luau`.

Scope: `src/client/UI/**` — 16 `.luau` files. Theme sources: `src/shared/Config/Visuals.luau:9-23`
(13 palette hex tokens), `:106-111` (type 28/18/13/11), `:122-126` (radius card 14 / button 10 /
chip 8), `:135-138` (fonts); `src/client/UI/Theme.luau:14-16` (`Color3.fromHex(Visuals.palette[name])`),
`:44-45` (token-driven `Enum.Font[...]`), `:93-100` (`Theme.corner`, the only `UICorner` constructor).

## CHECK THEME_BYPASS — baseline and result

**Verdict: PASS on the audited invariant. Baseline: 0 exact-colour theme-token duplicates in
`src/client/UI/**`. After: 0.**
No duplicate was found, so no fix was needed and no colour code was changed. The count was already
0 before this audit: the "after lower than before" condition was satisfied historically, and no
reduction is claimed here. `THEME_BYPASS` asserts the invariant (0 after, 0 baseline) and locks the
radius literal set so a later redesign cannot happen silently. Remaining occurrences (non-token
radii, token-equal radii and out-of-scope colours) are listed in tables (b)–(d) below.

`Color3.fromRGB` in `src/client/UI/**`: **0**. Hardcoded `Enum.Font.<name>` in `src/client/UI/**`:
**0**. Direct `Instance.new("UICorner")` calls: **1**, `src/client/UI/Theme.luau:94`, inside
`Theme.corner` — the single constructor. Token-driven colour/font uses: `Theme.luau:15`,
`Theme.luau:44-45`, `Icons.luau:74` (`Color3.fromHex(Visuals.palette[token] ...)`).

## (a) Exact theme-token colour duplicates — none

| File:line | Value | Verdict |
|---|---|---|
| — | — | None found. Baseline 0, after 0; no fix applied. |

## (b) Non-token corner-radius literals — designer decision, not changed

All pass through `Theme.corner`; they bypass the **radius token set**, not the constructor.

| File:line | Value | Token comparison | Status |
|---|---|---|---|
| `src/client/UI/Theme.luau:285` | `3` | not 14/10/8 (rarity tier accent) | designer decision — not changed |
| `src/client/UI/Phone.luau:89` | `26` | not 14/10/8 (device bezel) | designer decision — not changed |
| `src/client/UI/Phone.luau:104` | `2` | not 14/10/8 (speaker slit) | designer decision — not changed |
| `src/client/UI/Phone.luau:115` | `18` | not 14/10/8 (device screen) | designer decision — not changed |
| `src/client/UI/Phone.luau:252` | `3` | not 14/10/8 (home bar pill) | designer decision — not changed |
| `src/client/UI/Phone.luau:1342` | `6` | not 14/10/8 (lit-screen toggle) | designer decision — not changed |

Count: **6**. `THEME_BYPASS` locks this exact six plus the full numeric-radius multiset.

## (c) Token-equal corner literals — not bypasses

| File:line | Value | Matching token | Verdict |
|---|---|---|---|
| `src/client/UI/Minigame.luau:137` | `10` | `Visuals.radius.button` | not a bypass |
| `src/client/UI/Phone.luau:388` | `14` | `Visuals.radius.card` | not a bypass |
| `src/client/UI/Phone.luau:492` | `8` | `Visuals.radius.chip` | not a bypass |
| `src/client/UI/Phone.luau:741` | `8` | `Visuals.radius.chip` | not a bypass |
| `src/client/UI/Phone.luau:890` | `8` | `Visuals.radius.chip` | not a bypass |
| `src/client/UI/Phone.luau:1329` | `10` | `Visuals.radius.button` | not a bypass |
| `src/client/Minigames/Babat.luau:22` | `8` | `Visuals.radius.chip` (outside audited UI dir) | not a bypass |
| `src/client/Minigames/Mencangkul.luau:23` | `8` | `Visuals.radius.chip` (outside audited UI dir) | not a bypass |

## (d) Out-of-scope literals noted — no change

`src/client/Feel/ActionFeel.luau` holds world/VFX and feel colours, not UI theme tokens.
None equals an exact `Visuals.palette` RGB triple.

| File:line | Value | Note |
|---|---|---|
| `src/client/Feel/ActionFeel.luau:211` | `Color3.fromRGB(110, 75, 45)` | soil particle burst, out of scope |
| `src/client/Feel/ActionFeel.luau:304` | `Color3.fromRGB(255, 215, 0)` | Sultan harvest burst, out of scope |
| `src/client/Feel/ActionFeel.luau:305` | `Color3.fromRGB(190, 110, 255)` | Langka harvest burst, out of scope |
| `src/client/Feel/ActionFeel.luau:306` | `Color3.fromRGB(80, 160, 255)` | Super harvest burst, out of scope |
| `src/client/Feel/ActionFeel.luau:307` | `Color3.fromRGB(120, 210, 80)` | default harvest burst, out of scope |
| `src/client/Feel/ActionFeel.luau:401` | `Color3.fromRGB(255, 215, 0)` | cash-fly label, out of scope |
| `src/client/Feel/ActionFeel.luau:403` | `Enum.Font.GothamBold` | cash-fly label font, out of scope |
| `src/client/Feel/ActionFeel.luau:407` | `Color3.fromRGB(30, 20, 10)` | cash-fly stroke, out of scope |
| `src/client/UI/Hud.luau:422-423` | `Color3.new(0, 0, 0)` | `Lerp` dimmer, not a colour token |

`src/client/World/**` also has `Color3.fromRGB` literals for sky, water and LookDev world colours;
they are world presentation, outside the UI theme scope. The spec gates these Feel literals only
against becoming an exact palette-colour duplicate; it does not change or count them as UI bypasses.

## Decisions for designer

The six radius literals in table (b) are the only design-owned items: `Theme.luau:285` = 3,
`Phone.luau:89` = 26, `:104` = 2, `:115` = 18, `:252` = 3, `:1342` = 6. Safest reversible default:
leave them as intentional special-case radii. If they should become named `Visuals.radius` tokens,
that is a separate designer decision and requires updating this audit and the `THEME_BYPASS` multiset
in the same change. Main session: add this list to WORK_QUEUE "Decisions for designer" if a ruling is
wanted (this item's writer does not edit WORK_QUEUE.md).
