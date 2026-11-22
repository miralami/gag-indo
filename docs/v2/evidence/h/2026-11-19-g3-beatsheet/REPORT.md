# H — G3 full beat sheet, desktop — 2026-11-19

Track H, Gate 1 G3: "The harness plays the full beat sheet with zero Output errors or warnings."
This is the **desktop half** at desktop viewport; the phone-size half stays the designer's task.
Fresh profile, Rojo-synced code, Output saved to `output.log`. No designer identity recorded.

## Setup

- Branch `track/c-world-look`, HEAD `90b4d9c`, Rojo on `localhost:34872`, Edit datamodel synced
  before Play. Fresh profile via VERIFY-TEMP `store.Mock` (in-memory ProfileStore), reverted before
  commit. Play Solo, desktop size.

## Run — one coherent pass, all 9 steps `ok=true`

Driver: `Harness_Command` / `Harness_Result` remotes, paced 0.35 s apart to stay under the harness's
documented 4 commands/s/player rate limit.

| # | Step | Observed state after |
|---|---|---|
| 1 | `enable` | `Harness on.` |
| 2 | `status` | cash 50, sack 0, padi 5, tiles 0 |
| 3 | `plant` tile 1 padi | padi 5→4, tiles 0→1 |
| 4 | `ready` | tile ripened (no cash/seed change) |
| 5 | `harvest` tile 1 | sack 0→1, tiles 1→0 |
| 6 | `sell` pasar | cash 50→77, sack 1→0 |
| 7 | `buy` padi ×2 | cash 77→57, padi 4→6 |
| 8 | `quest` (daily) | cash 57→157, padi 6 |
| 9 | `status` final | cash 157, sack 0, padi 6, tiles 0, tutorialStep 5, rank `gurem` |

Wall-clock markers `[G3] … wall=HH:MM:SS` for every step are in `output.log` (02:29:48→02:29:52).

**First attempt:** an unpaced burst dropped the `quest` command to the 4/s rate limit (no reply in
9 s), so that pass showed steps 1–6 and 8–9 only. Re-running with 0.35 s pacing passed all nine;
a standalone `quest` re-check also returned `ok` (cash 57→157). The rate limit is documented
harness behaviour (`HARNESS.md` §1), not a defect.

## Output

`output.log`: **zero game-code errors, zero game-code warnings**. Non-game lines are the external
BUG-003 asset line ×3 (proven external by a blank-place test, accepted under D-G4), two Assistant
plugin version warnings, and normal `AnalyticsService` event notices.

## Verdict

Full §4 beat sheet played through in one pass at desktop size — `SEEN-IN-STUDIO` (this file,
`output.log`, `results.json`). Phone-size replay (`G3` half, `G4b` text check) remains the
designer's task: the Studio MCP cannot change `Camera.ViewportSize`/device orientation, so the
iPhone 14 half cannot be driven here. Machine-readable readings in `results.json`.
