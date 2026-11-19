# Bug hunt by reading, round 3 — damaged dynamic tile fields

**Status:** `LUNE-ONLY`
**Date:** 2026-11-19
**Branch:** `track/c-world-look` (HEAD at time of writing: item 18 `4ea6791`)
**Bug:** `BUG-019` in `docs/testing/BUGS.md`
**Spec:** `tests/specs/farm_failure_spec.luau` (3 cases appended to the existing T3 spec)

## Scope

WORK_QUEUE item 19 asked for a line-by-line read of every `src/` file changed in round 1
(`git diff --name-only 8f965dc..a618f02 -- src/`, 68 files). Subagent transport
(`ECONNREFUSED`) was unavailable, so the audit ran directly in the main session.

Triage:
- `luau-lsp analyze --no-strict-dm-types src` (no Roblox definitions provided) emitted ~3000
  lines, almost entirely `Unknown global 'game'` / missing-definitions noise. Filtering for
  genuine diagnostics surfaced `LeaderboardUI.render` (a function assigned inside `mount()` —
  a type-narrowing artefact, not a runtime defect) and `CutsceneSequencer` state comparisons
  (LSP cannot narrow the assigning branch — not a runtime defect). Neither is a bug.
- Targeted reads of the money/data/networking files (`DebtCollector`, `Main.server`,
  `MarketService`, `server/Net/State`, `Testing/Gate`, `NpcWalk`, `Quests.rollDailyTasks`)
  found no new reachable defect.
- One real defect class was found: raw arithmetic on numeric fields under `data.tiles`.

## The bug (BUG-019)

`SaveSanitize` deliberately skips tables with dynamic string keys — `items`, `produce`, `tiles`,
`almanak` — because it cannot know which keys are legitimate (`docs` comment at
`src/server/Data/SaveSanitize.luau:8,14-15`). `data.tiles` looks like
`{ t1 = { crop, plantedAt, growSeconds, quality, hot, harvests }, ... }`.

`FarmService` read these fields directly:

```lua
local readyAt = entry.plantedAt + entry.growSeconds   -- refreshTile, prompt, finish,
local quality = (entry.quality + harvestQuality) / 2  -- readyTiles, harvestToStorage,
local harvests = (entry.harvests or 0) + 1            -- applyOplosan, stealWater, onLoaded
```

A partially written save can leave any of them as a string, a table, NaN, ±inf, or a boolean.
With such a tile, a veteran could not join (`refreshAll` at load), and several farm actions
threw `attempt to perform arithmetic on a string/nil value` instead of degrading.

## The fix

`src/server/Farm/FarmService.luau`:

- `finiteOr(value, fallback)` — returns `value` only when it is a finite number; otherwise the
  fallback. Finite negatives are preserved (matches `SaveSanitize`'s "negative numbers are
  left alone" rule, needed by debt/cash code).
- `tileReadyAt(entry)` — repairs `entry.plantedAt` and `entry.growSeconds` in place to finite
  numbers (0 fallback), then returns their sum. A 0 repair makes the crop immediately
  harvestable, so the tile self-heals on the next refresh instead of staying stuck forever.
- All eight ready-time reads now call `tileReadyAt(entry)`.
- `doHarvest` repairs `entry.quality` (fallback 0.5) before averaging with the minigame score;
  `harvests` uses `finiteOr(entry.harvests, 0) + 1`.

Healthy tiles take the identical arithmetic path — no behaviour change for valid saves.

## Spec and mutation check

Three cases appended to `tests/specs/farm_failure_spec.luau`, each looping over
`{ "oops", {}, 0/0, math.huge, -math.huge, true, -3 }` and reusing the existing `makeFarmEnv()`
harness (real `FarmService`, mocked PlayerData/Economy/Plot/etc.):

1. `refresh` survives damaged `plantedAt`/`growSeconds` and repairs them to finite values in place.
2. `readyTiles` and `harvestToStorage` survive damaged `growSeconds`.
3. A `commitAttempt(..., "harvest")` with damaged `quality`/`plantedAt` succeeds and records a
   finite harvest quality in the economy mock (no NaN/inf leak).

Mutation check: replacing `tileReadyAt` with the old direct addition and `quality` with the raw
`entry.quality` made all three cases FAIL. The mutation was reverted; the final run is green.

## Validation

- `lune run tests/run` — **1996 passing** (was 1993; +3 cases), exit code 0, no FAIL lines.
- `selene src` — **0 errors, 0 warnings, 0 parse errors**, exit code 0.

No place was saved or published. No `JuraganDesa.rbxl` saved. No API key printed, logged or
committed. No balance/config change.
