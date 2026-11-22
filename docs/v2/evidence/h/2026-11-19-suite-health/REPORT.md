# Item 26 — Test-suite health (2026-11-19)

Status: **LUNE-ONLY** (harness + test-only changes; no `src/` game code touched, no Studio play
needed). Branch `track/c-world-look`.

## 1. Flakiness — none found

Ran `lune run tests/run.luau` three times back-to-back before making any change. All three exited 0
with **All 1927 tests passed**, and the three full outputs were byte-identical (same SHA-256), so
there is no ordering or state flakiness. After the harness changes, repeated the three-run check:
all three exited 0 at 1930 passed (1927 + 3 new timing-contract cases) with byte-identical
PASS/FAIL bodies. No flaky spec to fix.

## 2. Per-spec timing output — added

- `tests/lib/Test.luau`: `Test:run` now records wall-clock seconds per case (`caseSeconds[case]`),
  per suite (`suiteSeconds[suite]`) and total (`totalSeconds`) on the `Test` object, keyed by the
  case/suite table so the runner can attribute them. The `PASS`/`FAIL` log strings and the return
  values (`passed, failed, failures`) are unchanged.
- `tests/run.luau`: times each spec's `register()` call separately (that is where static file
  scanning happens), attributes each spec's suites back to it, and prints a compact timing report
  above the pass/fail summary: total registration + case time, the 12 slowest **specs** (with a
  per-spec `reg=` / `cases=` split) and the 12 slowest **cases**. Anything at or above a 2 s
  threshold is marked `<== SLOW`. `lune run tests/run --timing [filter]` prints the full per-spec
  table; the first non-flag argument is still the name filter, so existing filtered usage is intact.
- `tests/specs/harness_timing_spec.luau` (registered in `run.luau`): 3 cases characterize the new
  contract — pass/fail/failure return values and log text are unchanged, every executed case/suite
  and the total get a non-negative duration, and a filtered run only times the cases it executed.

## 3. Speed-up — 31.7 s to 4.8 s (~6.6×)

Timing found no single spec or case over 2 s, but one case was a 14× outlier:
`Money invariants (T5 prep) > payouts stay integer...` at **1.236 s**. Root cause: `Env.new()`
re-walked the entire `src/` tree on every construction (`fs.readDir` + `fs.isDir` per directory,
hundreds of calls), and that case builds 48 environments in its nested loops. Module sources were
also re-read from disk on every `require`.

`tests/lib/Env.luau` now memoizes the immutable directory listing (`dirEntries`/`dirIsDir`) and
module source text (`fileSource`) at module scope. The `src/` tree is static for a test run and no
spec writes into it (verified — all "write" references are fake DataStore logic). Each `Env.new()`
still builds a fresh Instance tree and compiles fresh chunks in its own module cache, so isolation
between environments is unchanged; only redundant filesystem I/O is removed.

Measured (same machine, full suite):

| | before | after directory cache | after source cache |
|---|---|---|---|
| total (registration + cases) | 31.734 s | 6.258 s | 4.778 s |
| slowest case | 1.236 s | 0.324 s | 0.213 s |

Slowest case after: 0.213 s; slowest spec 0.429 s — nothing within an order of magnitude of 2 s.

## Validation

- `lune run tests/run.luau` — **All 1930 tests passed** (1927 + 3 new), exit 0, ×3 with identical
  PASS/FAIL bodies.
- Filter smoke: `lune run tests/run --timing economy` → 70 passed; `lune run tests/run "harness
  timing"` → 3 passed.
- `selene src` — **0 errors / 0 warnings / 0 parse errors** (no game code changed).
- `selene tests/lib/Test.luau tests/lib/Env.luau tests/run.luau tests/specs/harness_timing_spec.luau`
  — 0 parse errors; only the pre-existing selene-vs-Lune `require` diagnostic and style warnings
  that already exist across `tests/`.
