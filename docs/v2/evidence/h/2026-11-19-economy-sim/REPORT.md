# Long economy sim — WORK_QUEUE round-2 item 17

**Status:** `LUNE-ONLY`
**Date:** 2026-11-19
**Branch:** `track/c-world-look` (HEAD at time of writing: item 16 `44c45df`)
**Spec:** `tests/specs/economy_sim_spec.luau` (3 cases), registered in `tests/run.luau`
**Audience:** designer (this is a balance observation report; no balance change was applied)

## Method

One fake player, eight hours of simulated time = **480 cycles × 60 s**, driven by
`env:advance(60)` per cycle under the Env harness. Three runs, all against the real
`EconomyService`, `MarketService`, `DebtService`, `RankService`, `Inventory`, `Produce` and
`Pinjol` config; only leaf side effects (Notify, RateLimit always-allow, State, Analytics,
Village position, Cabai multiplier, Onboarding, FirstSession rank-up) are mocked. `task.spawn`
is a no-op so no real service loop competes with the sim clock.

- **optimal** — owns 4 padi "tiles" (harvest slots): each cycle ensure 4 padi seeds (buy if
  short), plant/consume 4 seeds, add 4 padi harvests, sell everything at the Pasar, tick
  debt and market, and repay a loan once cash comfortably covers it.
- **broke** — same loop but cash 0 and every seed 0 at t=0; borrows the smallest useful Pinjol
  loan when a seed purchase fails, then recovers and repays.
- **idle** — takes no economic action for the full eight hours; only ticks debt and market.

## Results (`[SIM]` lines from `lune run tests/run`)

| Run | Final cash | Lifetime earned | Rank | Peak cash | Min cash | Borrows | Repays | Dead ends | Planting cycles |
|---|---|---|---|---|---|---|---|---|---|
| optimal | 11,239 | 30,339 | petani | 11,239 | 50 | 0 | 0 | 0 | 480 / 480 |
| broke | 11,106 | 30,276 | petani | 11,106 | 0 | 1 | 2 | 0 | 479 / 480 |
| idle | 50 | 0 | gurem | 50 | 50 | 0 | 0 | 0 | n/a |

## Checks

- No NaN or inf in any numeric save field at any cycle (bounded recursive walk over the whole
  save), cash finite and `0 ≤ cash ≤ EconomyService.MAX_CASH` (1e12), lifetime earned finite and
  monotonically non-decreasing.
- No dead end: at the end of every cycle the player still had ≥4 seeds, or enough cash to buy
  4, or no active loan (i.e. Pinjol still available). Zero dead-end cycles in all three runs.
- Broke start borrowed 100 (gurem limit 500, 10% fee), lost exactly one planting cycle while
  waiting for loan cash, then recovered and fully cleared the loan — `debt.active == false` at
  the end, final cash within ~1% of the never-broke run.
- Idle run held cash and seeds byte-for-byte flat (50 / 5) with zero earned — no silent cash
  drift from ticks alone.
- Rank promoted gurem → petani in both active runs (petani needs 1,000 lifetime earned).
  Juragan was not reached: it needs 12 owned tiles, and this sim models harvest slots, not tile
  purchases — a harness scope limit, not a balance finding.

## Decisions for designer

**No balance change recommended.** Eight hours of optimal play yields a healthy ~30k gross /
~11k net with a clean rank step to petani; a broke start recovers via Pinjol in one cycle with
no dead end; idle play neither earns nor leaks cash. The one observable friction — a broke
player loses one 60-second planting cycle while the loan clears — is small and intentional
(Pinjol is meant to hurt). No config value was changed.

## Validation

- `lune run tests/run` — **1989 passing** (was 1986; +3 cases), exit code 0, no FAIL lines.
- `selene src` — clean (repo gate; no source files changed).

No source file was changed. No place was saved or published. No `JuraganDesa.rbxl` saved. No
API key printed, logged or committed.
