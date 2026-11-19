# Item 25 — Dead code and dead strings (2026-11-19)

Status: **SEEN-IN-STUDIO** (Lune specs + selene + luau-lsp + a clean Edit→Play→Edit Studio run that
produced no game-code errors). Branch `track/c-world-look`.

## Scope

Removed only confirmed-dead code. No modules and no Rojo mappings were dead, so none were removed
(the two apparent orphans are loaded live via `pcall(require, ...)`; all four `$path` mappings resolve).

### Dead `Strings` keys removed (22)

Verified dead by an exact-literal + prefix-aware reverse scan over all of `src/` and `tests/`: a key
is live only if its exact string literal is referenced, or it starts with a real concatenation
prefix. Docs mentions and substring matches (`hud_event_cabai_on/left`, `phone_steal_short`,
`phone_water_short`) were excluded before deletion. Removed from `src/shared/Strings.luau`:

`admin_button`, `admin_event`, `admin_no_access`, `family_kebun`, `family_palawija`,
`family_perkebunan`, `hud_cheat`, `hud_event_cabai`, `hud_harvest_bag`, `hud_namabaik`, `hud_rank`,
`hud_shop_button`, `hud_sus`, `lb_button`, `phone_home`, `phone_namabaik`, `phone_rank`,
`phone_steal`, `phone_sus`, `phone_water`, `raid_jail_btn`, `shop_rank_badge`.

The longer lookalike keys (`hud_event_cabai_on`, `hud_event_cabai_left`, `phone_steal_short`,
`phone_water_short`) are still referenced by HUD/Phone and were kept.

### Dead functions removed (5)

Each exported function whose `Module.fn` appeared only at its definition site in all of `src/` and
`tests/`, with no docs/Studio-probe reference, was removed:

- `Village.getWorld` (`src/server/World/Village.luau`)
- `State.touchAll` (`src/server/Net/State.luau`)
- `Crops.isRegrow` (`src/shared/Config/Crops.luau`)
- `MarketService.pressure` (`src/server/Economy/MarketService.luau`; `multiplier()` is the live accessor)
- `FarmService.hasGrowing` (`src/server/Farm/FarmService.luau`)

Deliberately kept: `NavBridge.debugState` (read-only Studio verification hook),
`PlotService.getNeighbors` (documented in `MAP_SPEC.md`) and `Theme.sticker` (public helper whose
internal `addSticker` is live). `Audio.configured` left as borderline Config API to avoid scope creep.

## Proof

New spec `tests/specs/dead_code_spec.luau` (registered in `tests/run.luau`) proves: all 22 keys absent
from `Strings.raw`; no remaining Strings key is unreferenced (same prefix-aware reverse scan);
all four lookalike keys still defined; all five functions no longer defined; the scanners would catch
a live case (sanity cases); and all four `$path` mappings in `default.project.json` exist on disk.

## Validation

- `lune run tests/run.luau` — **All 1927 tests passed** (1908 before + 19 new).
- `selene src` — **0 errors / 0 warnings / 0 parse errors**.
- `luau-lsp analyze --platform roblox --sourcemap sourcemap.json --defs ".luau/globalTypes.d.luau"
  --ignore "**/Packages/**" src`: same pre-existing error file set as item 24 (Wind, FarmService,
  Leaderboard, Analytics, EconomyService, ToolService, RankService, FirstSession, LookDevWalkin,
  LookDev, CutsceneSequencer). None of the six edited modules appear — **zero new type errors**.
- **Studio clean play** (`Development-Juragan-Desa`, Edit → Play → Edit, 2026-11-19): server started,
  player present, no Lua errors and no references to any removed key/function in Output. One unrelated
  pre-existing warning `ContentId rbxassetid://203785492 failed due to: Asset type does not match
  requested type` (audio asset, not game logic, not in `src/`). Assistant-plugin version warnings are
  harness noise. Studio returned to Edit mode; no place saved, no publish, no `profile:Save()`.
