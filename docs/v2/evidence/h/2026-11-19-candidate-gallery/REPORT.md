# Round 2 item 10 — candidate gallery drift-lock

Date 2026-11-19. Branch `track/c-world-look`. Status `LUNE-ONLY`.

## Target

`docs/v2/visual/CANDIDATES.md` gets one row per candidate: a render or screenshot, the toggle to
view it, its cost (instances and fps), and a yes/no column for the designer.

## What exists

The gallery was maintained as each round-2 candidate landed, so the item's content was already in
place. It now has one row for each of the eight LookDev candidates in registry order:

`plaza_lighting`, `police_walkin`, `icons`, `textures`, `npcs`, `crops`, `hubprops`, `sounds`.

Each row has all six columns — Candidate / What it is / Toggle / Render (or screenshot) / Cost
(instances / fps) / Designer yes/no. The toggle names the exact `LookDev:enable("<id>")`, every
render path resolves to a real file or evidence directory on disk, and every cost cell states the
fps impact. The gallery also carries per-asset tables for the 27 icons and 7 textures, each with a
blank designer yes/no column. **Every designer yes/no cell is blank** — agents never decide.

## Drift-lock spec

`tests/specs/candidate_gallery_spec.luau` (4 cases) parses the markdown tables and asserts:

1. the main table has the six required columns;
2. there is exactly one row per `LookDev.IDS` entry and no extra candidate rows;
3. each row's toggle names its candidate, its render path exists on disk, and its cost states fps;
4. all three tables with a "Designer yes/no" column have blank cells in every row.

It is registered in `tests/run.luau`.

## Mutation check

| Injected fault | Result |
|---|---|
| Fill one main-table designer yes/no cell with `yes` | 1 FAILED, 1967 passed — blank-cell case fails |
| Delete the `sounds` candidate row | 1 FAILED, 1967 passed — one-row-per-candidate case fails |
| Restore the original file | All 1968 tests passed |

## Validation

`lune run tests/run.luau`: **All 1968 tests passed** (up from 1964). `selene src`: 0 errors /
0 warnings / 0 parse errors.

Status is `LUNE-ONLY`: the gallery's structure is fully provable in Lune and mutation-checked, but
the renders are review artifacts for the designer and no agent visually graded them. Designer
yes/no stays blank and is tracked under WORK_QUEUE "Blocked on designer".
