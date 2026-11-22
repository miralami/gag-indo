# Cross-server and leaderboard failures — Track H, 2026-11-19

WORK_QUEUE item 15: prove cross-server / leaderboard failure handling with backoff, last-good
fallback and budget-limit coverage. All results here are `LUNE-ONLY` (no live multi-server or
Open Cloud test is available through Studio MCP — see Limits).

## Scope actually covered

- **OrderedDataStore** (leaderboard): already locked by `tests/specs/leaderboard_spec.luau` and
  `tests/specs/cosmetics_leaderboard_failure_spec.luau` — bounded `MAX_ATTEMPTS = 3` retry,
  exponential backoff (`task.wait` between tries), `WRITE_INTERVAL = 30` write throttle, failed
  writes not cached, last-good board kept when a refresh fails. New
  `tests/specs/cross_server_failure_spec.luau` adds one case proving a **failed write burst stays
  inside the retry cap and per-player throttle**: 3 attempts on the first burst, no extra calls in
  the same throttle window, 3 more after `env:advance(40)`.
- **AnalyticsService budget** (the platform-side budget-limit handling): already locked by
  `tests/specs/analytics_spec.luau` (`budgetFor(0)=120`, `budgetFor(10)=320`, events dropped past
  the minute budget, budget reopens after a minute). Not duplicated.
- **MessagingService + LiveConfig DataStore**: the genuine gap. New spec drives the real
  `LiveConfig` through fresh fake DataStore/MessagingService services (no real API calls).
- **MemoryStore**: **N/A** — a repo-wide search finds no MemoryStore usage anywhere in `src/`.
  There is no MemoryStore code path to exercise, and none was invented for this item.

## New spec — `tests/specs/cross_server_failure_spec.luau` (9 cases, `LUNE-ONLY`)

LiveConfig failure paths (8 cases): DataStore read error keeps shipped defaults; DataStore write
error keeps the local change and a later write still lands; MessagingService publish error never
throws and the local change applies; subscribe error never throws and local updates still work;
malformed/missing messages are sanitized and never wipe the last good config; a stale message does
not roll back a newer one; a corrupt (`NaN`/`±inf`/negative) `updatedAt` cannot freeze the config;
a stale DataStore poll cannot roll back a newer config.

The harness makes `task.spawn` synchronous, so LiveConfig's infinite 60 s poll loop is stopped by a
`__STOP_POLL_LOOP__` sentinel in fake `task.wait`; the helper treats only that sentinel as expected
and lets any real error fail the case.

## BUG-017 — real cross-server bug found and fixed

`src/server/Live/LiveConfig.luau` stored `updatedAt` but never used it to order cross-server state.
MessagingService does not guarantee delivery order and DataStore reads can be eventually consistent,
so a stale publish or read arriving late replaced a server's newer season/anomaly/weather/price
config with older settings — across every connected server. `sanitize()` also accepted any number
as `updatedAt`, so a single corrupt value (`math.huge`) could freeze all future updates forever.

Fix: `sanitize()` keeps `updatedAt` only when finite and non-negative; `isStale(patch)` rejects a
message/read whose finite `updatedAt` is older than `current.updatedAt` in both `subscribe()` and
`load()`; un-ordered patches (no usable timestamp) remain accepted for legacy compatibility. No
shipped config value or default changes.

Proof: before the fix the two stale cases failed (`expected "kemarau", got "hujan"`); after the fix
all pass. Mutation check — removing only the finite guard makes the corrupt-timestamp case fail
(`1 FAILED, 1816 passed`). Recorded as `BUG-017` in `docs/testing/BUGS.md`.

## Proof

- `lune run tests/run.luau`: **1817 passing** (was 1808; +9 new cases).
- `selene src`: 0 errors / 0 warnings / 0 parse errors.
- Files: new `tests/specs/cross_server_failure_spec.luau` (registered in `tests/run.luau`),
  `src/server/Live/LiveConfig.luau` (BUG-017 fix), `docs/testing/BUGS.md` (BUG-017 entry).

## Limits

- No live two-server / multi-client test is available: Studio MCP has no local-server or team-test
  tool, so real cross-server message ordering and Open Cloud DataStore failures are not
  reproducible here. The ordering and failure invariants are locked with fake services instead.
- MemoryStore N/A (no usage in `src/`).
