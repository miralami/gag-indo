# Save fuzzing — WORK_QUEUE round-2 item 16

**Status:** `LUNE-ONLY`
**Date:** 2026-11-19
**Branch:** `track/c-world-look` (HEAD at time of writing: item 15 `f0b0df3`)
**Spec:** `tests/specs/save_fuzz_spec.luau` (3 cases), registered in `tests/run.luau`
**Bug found:** `BUG-018` (fixed in this item, `docs/testing/BUGS.md`)

## What was done

A Lune spec runs 1000 deterministic randomly-damaged save tables through the real
`PlayerData.migrate` → `PlayerData.sanitize` path and, for a 20-case subset, through the real
fake-ProfileStore load path (`Players.PlayerAdded` → `StartSessionAsync` → `Reconcile` →
`migrate` → `sanitize`). A seeded LCG (seed `0x5EED1234`, no global `math.random`) makes every
case reproducible.

Damage injected per case: 2–7 random top-level template fields replaced with wrong types,
NaN, ±inf, a 5000-char string, an empty table, a 40-key table or a self-referential table;
random nested fields under `cooldowns`/`stats`/`quests`/`worker`/`gudang`/`debt`/`shop`/
`tutorial`/`story`/`prestige` likewise damaged; occasional legacy v1/v2 `harvest`,
`inventory`/`seeds` junk; and ~1-in-9 cases a non-table root (routed to `SaveSanitize` alone,
since `migrate` assumes the table root ProfileStore guarantees).

## Invariants asserted

For a table-root save after migrate + sanitize: no throw; every string template key present
with the right type; every template number finite; every nested template key present with the
right type and finite numbers where the default is numeric; `version == CURRENT_VERSION`;
and a bounded, cycle-aware walk terminates within a 20 000-node / 120-depth budget. For a
non-table root, `SaveSanitize.sanitize` must not throw.

Negative numbers are **not** treated as invariant violations: `SaveSanitize` deliberately
preserves them and cash/debt own their own non-negativity rules. The numeric invariant is
finiteness plus key/type preservation; count fields damaged to NaN/inf are repaired to their
non-negative template defaults, checked via the template walk.

## Defect found and fixed — BUG-018

The first run failed 15/1000 cases, all at `src/server/Data/PlayerData.luau:163`:
`attempt to compare number < table` / `< string`. Root cause: the v2-split migration did raw
comparisons and arithmetic (`hot > 0`, `sack.count`, `sack.qualitySum / sack.count`) on a
legacy `harvest` sack whose fields a partial write had left non-numeric. `migrate` runs before
`sanitize`, so a corrupted sack made the profile throw on load with no repair opportunity —
a veteran could be locked out of the game.

Repro (seed `0x5EED1234`): cases 30, 87, 113, 193, 258, 309, 339, 347, 369, 371, 438, 747
(and 3 more), each `data.version = 1` and
`data.harvest = { padi = { count = <bad>, hotCount = <bad> } }`.

Fix: added `finiteNumber(value)` (coerce via `tonumber`, 0 fallback for nil/NaN/±inf) and used
it for `hotCount`, `count`, `qualitySum`, `hotQualitySum` in the v2 split. Valid-save behaviour
is unchanged — a sack with `hotCount=2, count=10, qualitySum=50` still moves `hotQualitySum`
to `10` and reduces `qualitySum` to `40`, exactly as before. Mutation check: reverting the
coercion makes the fuzz spec fail with the 15 throws again.

The targeted regression case drives `version = 1` sacks with `count`/`hotCount`/`qualitySum`/
`hotQualitySum` set to each of `"many"`, `{}`, NaN, `+inf`, `-inf`, `true` and `-3`, asserting
no throw, all invariants, and finite produce quality sums.

## Validation

- `lune run tests/run` — **1986 passing** (was 1983; +3 cases), exit code 0, no FAIL lines.
- `selene src` — **0 errors, 0 warnings, 0 parse errors**, exit code 0.

No place was saved or published. No `JuraganDesa.rbxl` was saved. No API key was printed,
logged or committed.
