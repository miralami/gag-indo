# Item 28 — Docs refresh (2026-11-19)

Status: **LUNE-ONLY** (documentation only; no `src/` game code touched, no Studio play needed).
Branch `track/c-world-look`.

All values written below were read directly from current code at commit time, not from the old
snapshots. Where a number is a count, it was computed by loading the module under `lune`.

## What changed

### `docs/v2/plan/TECH.md`
- Header status now records the Track C follow-ons; refresh date 2026-11-19.
- §7 Tests: current commands (`lune run tests/run.luau`, `--timing`, `selene src`), the CI context,
  the harness timing contract, and two tables — the original M0–M2 specs plus a new table of
  Track C / follow-on specs (fidelity, cutscene, lazy pages, raid trigger, fps sampler,
  save reconcile, audio/nav wiring, strings/touch audit, dead code, harness timing). Noted the
  `Env.luau` memoisation (31.7 s → 4.8 s).
- §10 Acceptance: unit tests **379 → 1930 passed**, runner command corrected, `selene src` added
  as the static-analysis gate (with `luau-lsp analyze` retained for types), and a CI row.
- §11: the stale "cutscene needs Studio assets" gap replaced with the current sequencer/anchor/
  non-closable-overlay state; framing still flagged as a designer judgement.
- New **§12 Track C follow-on modules**: concise, API-accurate descriptions of `FidelityTier`,
  `FpsSampler`, `CutsceneSequencer`, `LazyPages`, `RaidTrigger`, `SaveSanitize`, plus the harness
  `raid`/`raidState` hooks and the deliberately-kept helpers from the designer decisions list.

### `docs/testing/HARNESS.md`
- Refresh note in the header (no harness step was re-run; prior `SEEN-IN-STUDIO` claims unchanged).
- §1 actions table gained `raid` `{ viral, force }` and `raidState`, with the gate / no-save-mutation
  explanation, matching the live `handlers` table in `src/server/Testing/Harness.luau`.

### `docs/README.md`
- Build-side map: `BALANCE.md` / `LOCALIZATION.md` snapshot date **2026-11-12 → 2026-11-19**,
  with the new counts (333 keys, 1930 tests).

### `docs/v2/plan/BALANCE.md` — regenerated, dated 2026-11-19
Rewritten from `Config/*.luau`. Status `LUNE-ONLY` (was a misleading "VERIFIED (478 tests)").
Corrected stale numbers: only **3 ranks** (`Game.rankOrder`) with the real requirements; **12 crops**
with actual seed/grow/sell/ROI/family/regrow/permit values (the old doc listed 3 crops with wrong
prices); **5 rarity tiers** with the true expected multiplier ≈ **1.51×** (old doc said ~1.38×);
traits, cabai event, market pressure/floor/ceiling, tools, pinjol limits/interest/caps, quest and
login rewards, law/fines, and fidelity/perf thresholds. Every figure cites its config source.

### `docs/v2/plan/LOCALIZATION.md` — regenerated, dated 2026-11-19
Rewritten from `Strings.luau`. Status `LUNE-ONLY` (old "PASS" claim reframed). Exact count
**333 keys, 0 empty `id`, 0 empty `en`** (computed by loading the module under `lune`), with a
prefix breakdown that sums to 333 and a note that item 25 removed 22 dead keys. Documented
`langFor` / `formatNumber` / `@key` recursion and the en-us Studio behaviour. Corrected the
testing section: the checker is `strings_integrity_spec.luau` (the old `visuals_spec.luau` no longer
exists), and the checks are non-empty id/en, matching placeholders, no whitespace/TODO, all
referenced keys present, no hardcoded `.Text`, plus the 11 px text minimum; the emoji check from
the old doc is no longer in the suite and was removed from the claim.

## Out of scope (left untouched on purpose)
Stale counts/commands in historical evidence reports, `v2/archive/` (never a rule source), and
signed run sheets are records of what was true at the time and were not edited. `docs/testing/README.md`
still uses the short `lune run tests/run` form, which remains valid; item 28 named only TECH/HARNESS/
the README map and the two snapshots.

## Validation
- `lune run tests/run.luau` — **All 1930 tests passed**, exit 0.
- `selene src` — **0 errors / 0 warnings / 0 parse errors**.
- Counts verified by loading `Strings.luau` under `lune` (333 keys) and reading `Config/*.luau`
  directly; the modified files are Markdown, so no new code path was introduced.
