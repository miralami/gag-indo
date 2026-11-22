# Code health — Track H, 2026-11-19

Build: `track/c-world-look` after `864e7a2`, Rojo serving `localhost:34872`. Studio instance
`447c176b-1d7b-4b9c-a794-45912fea4b63`, cloud dev place `Development-Juragan-Desa` (placeId
`132087524375529`, universeId `10776530981`).

**Play Solo only. The place was never saved or published. `profile:Save()` was never called. Play was
stopped and Studio returned to Edit.**

## 1. Selene warnings cleared (3 at time of work)

| File | Symbol | Disposition |
|---|---|---|
| `src/client/UI/Admin.luau` | `tryAddHudButton` | Dead code — defined inside `mount` but never called. The Admin panel is opened by the existing toggle wiring; this helper would have injected a second HUD button and changed UI behaviour (a designer choice), so it was deleted rather than wired in. The append-only `admin_button` Strings key from item 7 remains harmless. |
| `src/server/World/MapSpec.luau` | `stripTop` | Dead code — a leftover of an older strip-splitting formula; the current `splitFill`/block code computes the top inline. Deleted. |
| `src/server/World/Greybox.luau` | `hubWall` | Dead code — no call sites after the hub-wall construction was rewritten. Greybox is now a test-only fallback (item 5), so no behaviour depends on it. Deleted. |

`selene src`: **0 errors / 0 warnings / 0 parse errors** (was 0 errors / 3 warnings).

## 2. Clean split: Phone view helpers → `PhoneWidgets.luau`

`src/client/UI/Phone.luau` was 1432 lines. Three genuinely generic, parent-explicit view helpers were
extracted verbatim into a new sibling `src/client/UI/PhoneWidgets.luau`:

- `clearChildren(frame)` — destroy only `GuiObject` children.
- `sectionLabel(parent, text, order, iconName?)` — labelled section row with optional icon.
- `scrollPage(parent, name)` — standard full-size scrolling page with list layout + padding.

Phone keeps local aliases (`local clearChildren = Widgets.clearChildren`, etc.) so every page calls
exactly the same function it did before the move — zero call-site changes. `PhoneWidgets` requires
`Icons` and `Theme` directly; Phone still requires `Icons` for the app-grid tiles at line 391 (the
require was restored after the first extraction attempt removed it). No other module split was
attempted: the remaining >600-line files (Greybox, FarmService, Hud, RaidOverlay, MapSpec) are tightly
coupled stateful controllers where a split would be cosmetic at best and behavioural risk at worst,
and vendored `src/server/Packages/ProfileStore.luau` is explicitly off-limits.

## 3. Characterization specs (behaviour locked before refactoring)

`tests/specs/code_health_spec.luau` (5 cases), registered in `tests/run.luau`, pins the exact output
of each extracted helper (GuiObject-only destruction, label offset/icon shift of 26 px, scrollPage
children/padding) and asserts Phone no longer defines the helpers inline. The mock parent attachment
mirrors Roblox's automatic `Parent` → `_children` behaviour so the label assertions are meaningful.

## 4. Proof

- `lune run tests/run.luau`: **1754 passing** (was 1750; +5 characterization cases, −1 because the
  deleted `admin_button` reference removed one Strings key-reference scan hit). `selene src`:
  0 errors / 0 warnings / 0 parse errors.
- **Studio client VM (Play Solo):** `Phone` loads with `mount`/`setLanguage` functions; `PhoneWidgets`
  loads with `clearChildren`/`sectionLabel`/`scrollPage` functions; 0 probe errors. Console showed only
  the pre-existing Assistant-plugin version warning and unrelated asset-type messages — no new
  game-code errors from the refactor.
- **Status:** refactor load/no-regression `SEEN-IN-STUDIO` (this report); helper behaviour `LUNE-ONLY`
  (`code_health_spec.luau`).
