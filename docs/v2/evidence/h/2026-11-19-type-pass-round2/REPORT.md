# Type pass, round 2 — WORK_QUEUE item 20

**Status:** `LUNE-ONLY`
**Date:** 2026-11-19
**Branch:** `track/c-world-look` (HEAD at time of writing: item 19 `66c12a6`)

## Tool setup (the part that matters)

`rokit.toml` pins `luau-lsp = "JohnnyMorganz/luau-lsp@1.70.1"`. A bare
`luau-lsp analyze src` is not meaningful here: without definitions it emits ~3000 lines of
`Unknown global 'game'` / `Unknown type 'BasePart'` noise. The working invocation is:

```powershell
$defs = (Resolve-Path ".luau/globalTypes.d.luau").Path
luau-lsp analyze --no-strict-dm-types --definitions "global=$defs" --sourcemap sourcemap.json src
```

The definitions path must be **absolute** — `--definitions global=@.luau/globalTypes.d.luau`
logs "Failed to read definitions file" and silently drops all Roblox types. The sourcemap
resolves the Rojo `game/...` require graph, which removes most `Unknown require` errors.

Baseline on the committed tree: **507 diagnostics** (diagnostic headers, multi-line messages
counted once).

## What changed

### 1. Twelve pure modules moved to `--!strict`

All 19 `src/` modules with no mode directive and no Roblox globals were probed in-tree by
prepending `--!strict` to each, running the full analysis, comparing per-file diagnostic
counts to baseline, and restoring from git. Six modules gained real strict errors
(`Shared/State` +200, `Shared/Produce` +110, `Shared/IconMap` +64, `CutsceneHooks` +14,
`AudioPolicy` +12, `PhoneLayout` +3) and were **not** kept. `Shared/Leaderboard` was also
skipped: it has 5 pre-existing errors, so a clean strict claim could not be made.

The remaining 12 were kept with **zero new diagnostics**:

- `src/client/UI/Navigation.luau`
- `src/client/UI/PhoneWidgets.luau`
- `src/server/Data/SaveSanitize.luau`
- `src/server/World/Ground.luau`
- `src/server/World/WarungService.luau`
- `src/shared/CropModelCandidates.luau`
- `src/shared/HubPropCandidates.luau`
- `src/shared/Inventory.luau`
- `src/shared/NextGoal.luau`
- `src/shared/Strings.luau`
- `src/shared/TextureMap.luau`
- `src/shared/SoundMap.luau`

No source line beyond the directive changed in those files.

### 2. Two genuine type errors fixed with compile-time-only assertions

- `src/server/Analytics/Analytics.luau:182` — `onboarding(player, step: number?, ...)` guards
  with `finite(step)` but LSP loses the narrowing inside the `send()` closure, producing 19
  (cycle-repeated) `Expected 'number', got 'number?'` errors. Bound
  `local stepNumber = step :: number` after the guard and used that in the closure.
- `src/server/Farm/FarmService.luau:159-160` — `BasePart:GetAttribute` returns `any?`, so
  `os.time() - PlantedAt` and `GrowSeconds / 3` produced 14 (cycle-repeated) `Expected
  'number', got 'unknown?'` errors. `refreshTile` always writes finite numeric attributes,
  so `:: number` assertions restore the type without changing runtime behaviour.

Both assertions are erased at runtime; every existing test still passes.

## Result

**507 → 474 diagnostics (−33):** Analytics 19 → 0, FarmService 21 → 7. No new diagnostics
appeared in any module from the strict additions.

Remaining diagnostics are documented limitations, **not** new bugs and **not** hand-edited:

| Count | Source | Why it stays |
|---|---|---|
| 378 | `src/server/Packages/ProfileStore.luau` | Vendored third-party library; never hand-edit. |
| 68 | Economy/Rank/FirstSession/ToolService cycle | A 4-module runtime require cycle is intentional and tested. Luau requires `export` syntax in *all* modules of a cycle to type it; introducing that is a type-only refactor with real regression risk, out of scope for a no-behaviour-change pass. |
| 7 | FarmService weak-key `setmetatable` | Same cycle-induced inference failure (`seedFloorGranted` inferred against itself). |
| 6 + 8 + 2 | Wind, Leaderboard, CutsceneSequencer | LSP cannot narrow a state variable assigned through a helper or a function assigned inside `mount()`; item 19 read all three and found no runtime defect. |
| 5 | LookDev candidates | Requires `NpcModelCandidates` / `SoundMap` / `TextureMap` that are generated in Studio, absent from `src/`. |

## Validation

- `lune run tests/run` — **1996 passing**, exit code 0, no FAIL lines (unchanged).
- `selene src` — **0 errors, 0 warnings, 0 parse errors**, exit code 0.

No place was saved or published. No `JuraganDesa.rbxl` saved. No API key printed, logged or
committed. No balance/config change. No vendored file edited.
