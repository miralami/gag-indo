# Q5 multi-client script — WORK_QUEUE item 22

**Status:** `LUNE-ONLY` for the shipped script; the live ten-player run is `BLOCKED` on a human at
Studio's Test tab.
**Date:** 2026-11-19
**Branch:** `track/c-world-look` (HEAD at time of writing: item 21 `d263465`)
**Spec:** `tests/specs/multiclient_spec.luau` (12 cases)

## Why a script, and why the live half is still blocked

Gate 1 Q5 is "no leak, no desync and no stuck state" over a thirty-minute soak and a ten-player
session. The soak half is `SEEN-IN-STUDIO` (`h/2026-11-14-soak/`). The ten-player half was attempted
on 2026-11-19 (`h/2026-11-19-q5-multiclient/REPORT.md`): this Studio MCP bridge exposes no tool to
open a Local Server, add test clients or run Team Test, and Roblox has no scriptable API to create
clients from inside a place. That is a tool-capability block, not a game defect.

This item delivers the other half that *can* be built here: a gated server script that, once a
human opens N clients, runs the `HARNESS.md` §2–§4 loop on every player and writes one results
table. The designer steps are in `docs/testing/HARNESS.md` §12.

## What shipped

| File | Role |
|---|---|
| `src/server/Testing/MultiClientCheck.luau` | Pure comparator + formatter. No game APIs, so Lune drives every branch. |
| `src/server/Testing/MultiClient.luau` | Studio-only server driver: loops `Players:GetPlayers()`, calls `Harness.dispatch`, collects one results table, prints a summary + `Q5_MULTICLIENT_JSON=` line, stores `MC.lastResults`. |
| `src/server/Testing/Harness.luau` | One new gated seam, `Harness.dispatch(player, action, value)`. `snapshot` and `handlers` stay private. |
| `tests/specs/multiclient_spec.luau` | 12 cases over digest, stuck, desync and line formatting. |
| `docs/testing/HARNESS.md` §12 | The exact click-by-click designer run. |

The driver's loop is `status → plant(tile 1, padi) → ready → harvest(tile 1) → sell(pasar) →
buy(padi, 2) → quest → save → status`. `save` is recorded but marked **non-critical** (persistence
is Q6, and it needs API services), so a refusal there never marks a player stuck. The trailing
`status` is the authoritative end snapshot. Every action goes through `Harness.dispatch`, which
re-checks the same Gate (Studio + flag + admin) as the client remote and calls the same real
handlers — the driver mints nothing and re-implements no gameplay rule.

## Comparator rules

- **stuck** — a player with no save snapshot, or a critical step whose real handler returned an
  error / threw. The action and message are named in the result. A server script cannot observe a
  client whose *network* stalls or a broken client UI; a human still watches for that (HARNESS §12
  step 6).
- **desync** — a snapshot field that differs between players after the identical loop from
  identical fresh saves. The allowlist is explicit and locked by a spec:
  `cash, lifetimeEarned, rank, seeds, tilesOwned, tiles, sack, gudang, tutorialStep, quests`.
- **excluded on purpose** — `name`/`userId`/`position` (identity and where a character stands),
  `shop` (`ShopStock.roll` is seeded by `player.UserId`, so two players legitimately have different
  shelves and a `buy` refusal can be expected — check `shop` before calling cash/seeds a bug), and
  `tutorialId` (a UI hint; `tutorialStep` is the state). These exclusions match the careful verdict
  table in HARNESS §11.
- `digest` sorts table keys, so a result never depends on Lua iteration order. NaN/±inf print as
  `nan`/`inf`/`-inf` rather than being hidden.
- `lines` produces the PASS/FAIL summary and one line per `STUCK`, `DESYNC` and `OK`, all
  Lune-tested for exact wording.

## Validation

- **Mutation check** — replacing `ok = #stuck == 0 and #desync == 0` with `ok = true` and disabling
  the critical-step stuck check made 4 cases FAIL (`reports a desync field`, `marks a player stuck
  on a critical failure`, `marks a player with no snapshot stuck`, `formats PASS/OK/STUCK/DESYNC
  lines`). Mutation reverted; final run green.
- `lune run tests/run` — **2008 passing** (was 1996; +12 cases), exit 0, no FAIL lines.
- `selene src` — **0 errors, 0 warnings, 0 parse errors**.
- `luau-lsp analyze` with the absolute `.luau/globalTypes.d.luau` definitions and `sourcemap.json` —
  **474 diagnostics, unchanged** from item 20 (no new diagnostics in either new module).
- `stylua --check` — clean on both new source modules and the new spec. Harness.luau has a
  pre-existing `goto` handler at line 234 that stylua cannot parse; it was not reformatted.

## What is still open

- The **live ten-player run** itself: needs a human to open a Local Server with 10 test clients,
  run HARNESS §12, and save `results.json` + `output.log` under
  `docs/v2/evidence/h/<date>-q5-multiclient-closed/`. Then flip Q5 in `GATE1.md`.
- The **"client stopped replying"** dimension is not machine-observable from a server script;
  the designer must watch the clients and note it in the report.

No place was saved or published. No `JuraganDesa.rbxl` saved. No API key printed, logged or
committed. No gameplay rule or balance setting changed.
