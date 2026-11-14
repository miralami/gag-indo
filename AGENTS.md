# Agent rules for this repository

Read `docs/v2/MASTER_PLAN.md` first. It governs what may be built, in what order, and how work is
proven. These rules sit on top of it and never override it.

## Orchestration

- Default to orchestrating: the main session plans, dispatches, reconciles, verifies and commits.
  Implementation work goes to subagents (`fixer`, `explorer`, `librarian`, `oracle`, `designer`)
  unless the dispatch costs more than the work or the work needs a tool a subagent does not have.
- Independent lanes go out in parallel in one message; parallel writers must never share a file.
  Every dispatch names its scope, the files it may touch, and who validates the result.
- **Roblox Studio MCP is main-session only.** Subagents have `blender` and `github` and no Studio
  tools (verified 2026-11-14). Anything that starts a play session, runs `execute_luau` or captures a
  screenshot stays in the main session.
- Claims are not evidence: read the diff or the file a lane produced before believing its summary.

## Rules that bite

- `lune run tests/run.luau` must pass before every commit; currently 502 tests.
- Status words are exactly `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`. A claim without a
  file under `docs/v2/evidence/` is not `SEEN-IN-STUDIO`.
- Never invent asset IDs, product IDs, prices or UserIds. Never publish, never save
  `JuraganDesa.rbxl` unless the task is track C.
- `docs/testing/BUGS.md` is the defect list; `docs/testing/GATE1.md` is the gate checklist; both are
  read before starting work. Bugs outrank features.
- No gameplay feature starts before Gate 1 passes (`MASTER_PLAN.md` §4).
- Player-facing text lives in `src/shared/Strings.luau` with `id` and `en` variants; `Strings.langFor`
  keys off the client locale, so an en-us Studio client shows English by design.
