# Q6 published-place plan and compare script — WORK_QUEUE item 23

**Status:** `LUNE-ONLY` for the plan and script; the live published-place run is `BLOCKED` on the
designer (D-G2, a private place and a real DataStore round trip).
**Date:** 2026-11-19
**Branch:** `track/c-world-look` (HEAD at time of writing: item 22 `cb3d0d9`)
**Spec:** `tests/specs/persistence_check_spec.luau` (8 cases)

## Why a plan and a Studio rehearsal

Gate 1 Q6 is "Persistence verified in a published test place with real DataStores, not only in
Studio" — save, leave, rejoin, compare cash/seeds/tiles. Only Studio DataStores are proven today
(`h/2026-11-14-phase0/`). Publishing a place is the designer's step (D-G2) and this MCP bridge has no
publish tool, so the live half is `BLOCKED` for an agent. What can be delivered here is the exact
run sheet and the comparison logic, with a gated Studio rehearsal so the verdict format is known
before the real run.

## What shipped

| File | Role |
|---|---|
| `docs/testing/Q6_PUBLISHED_PLACE.md` | Full designer run sheet: D-G2, publish-private steps, save → leave → rejoin, a fill-in numbers table, evidence layout. |
| `docs/testing/DESIGNER_GATE1.md` §5 | Cross-links to the run sheet and the script. |
| `src/server/Testing/PersistenceCheck.luau` | Pure before/after comparator + formatter. No game APIs. |
| `src/server/Testing/Persistence.luau` | Studio-gated driver: `capture()` prints `Q6_BEFORE_JSON=`; `compare(jsonOrTable)` prints the verdict + `Q6_RESULT_JSON=`; stores `lastResult`. |
| `tests/specs/persistence_check_spec.luau` | 8 cases over every verdict branch. |

## Design decisions (all tested)

- **The JSON must be pasted back after rejoin.** A leave/rejoin resets module state; requiring the
  designer to paste the captured snapshot keeps the before value from being forged by the same
  process. `compare` accepts either the table or the JSON string (decode failures are caught with
  `pcall`, so a paste typo does not abort the command bar).
- **The script is Studio-gated and cannot run in a published place.** Both functions require
  `RunService:IsStudio()` and the open harness flag. That is intentional: a script that could run in
  the published place would not prove anything a human could not fake, and the harness Gate is
  Studio-only by design. The script is a *rehearsal* of the verdict; the published-place numbers are
  captured by the designer and compared by hand using the run sheet's table.
- **`tiles.ready` is excluded.** It is derived from `os.time()`, so a crop growing at save time may
  be ready after rejoin. A case proves this is not treated as data loss. Crop identity, tile count and
  hot state still must persist.
- **Also excluded:** `name`/`userId`/`position` (identity), `shop` (UserId-seeded, per HARNESS §11),
  and `tutorialId` (a hint; `tutorialStep` is state). The compared field list is explicit and locked
  by a spec.
- **A missing snapshot is a failure.** Two absent saves agreeing on `nil` must not report PASS;
  `missingBefore`/`missingAfter` are set and printed.

## Validation

- **Mutation check (each rule isolated so one could not mask the other):**
  - Removing the `tiles` normalization made `does not treat a growing crop becoming ready as data
    loss` FAIL.
  - Forcing `ok = true` made `catches lost cash/seeds/tiles`, `treats a missing snapshot as a
    failure` and `formats PASS and one line per lost field` FAIL.
  - Both mutations reverted; final run green. (A combined run initially hid the first failure
    because the forced `ok` masked it — hence the isolated re-run.)
- `lune run tests/run` — **2016 passing** (was 2008; +8 cases), exit 0, no FAIL lines.
- `selene src` — **0 errors, 0 warnings, 0 parse errors**.
- `luau-lsp analyze` with the absolute `.luau/globalTypes.d.luau` definitions and `sourcemap.json` —
  **474 diagnostics, unchanged** from item 20 (no new diagnostics in either new module).
- `stylua --check` — clean on both new source modules and the new spec.

## What is still open

- The **real published-place run**: D-G2, publish a private place, do the save → leave → rejoin as a
  real player, fill the table, save `h/<date>-published-persistence/REPORT.md` + `output.log`, and
  flip Q6 in `GATE1.md`. Nothing here claims Q6 passed.

No place was saved or published. No `JuraganDesa.rbxl` saved. No API key printed, logged or
committed. No gameplay rule or balance setting changed.
