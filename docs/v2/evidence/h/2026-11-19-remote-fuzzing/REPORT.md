# Remote fuzzing — WORK_QUEUE round-2 item 15

**Status:** `LUNE-ONLY`
**Date:** 2026-11-19
**Branch:** `track/c-world-look` (HEAD at time of writing: item 14 `01660e2`)
**Spec:** `tests/specs/remote_fuzz_spec.luau` (3 cases), registered in `tests/run.luau`

## What was done

A Lune spec feeds deterministic malformed payloads at every client→server remote handler
that can be connected under the Env harness, and asserts two invariants: no error escapes a
handler, and no malformed payload changes a player's save data or attributes.

All handler-owning server services are required and started in one Env world. Leaf
infrastructure (PlayerData, Notify, RateLimit, Analytics, LiveConfig, Admins, Village,
PlotService, HttpService, MarketplaceService signals) is mocked; every `start()` is wrapped
in `pcall` so a mock gap in one service cannot hide the sweep of the others. `task.spawn`
is replaced with a no-op so the `while true do task.wait() end` loops some services own do
not hang the harness.

## Coverage

- **29 / 29** handler-owning services started; **0** failed starts.
- **25 / 25** client→server remote handlers connected and fuzzed, across 25 distinct remotes:
  `Admin_Command`, `Bribe_RT`, `Cheat_Apply`, `Cosmetic_Buy`, `Cosmetic_Equip`, `Debt_Borrow`,
  `Debt_Repay`, `Evidence_Record`, `Evidence_Report`, `Farm_Auto`, `Farm_Complete`,
  `Farm_SelectSeed`, `Harness_Command`, `Item_Use`, `Market_Sell`, `Quest_ClaimDaily`,
  `Quest_ClaimTask`, `Raid_Choose`, `Shop_BuySeed`, `State_Request`, `Storage_Deposit`,
  `Storage_Withdraw`, `Tool_Buy`, `Water_Neighbor`, `Worker_Hire`.
  (Coverage floor asserted non-vacuously: ≥20 handlers, ≥18 distinct remotes.)
- The three guard-only remotes (`Trade_Request`, `Trade_Respond`, `Event_Claim`) are owned by
  `RemoteGuards`, are not in `Remotes.NAMES`, and are already swept by
  `remote_audit_spec.luau`; they are rate-limit-and-ignore handlers that never touch state.

## Payloads (19 deterministic argument lists)

No args; `nil`; `true`; `false`; NaN (`0/0`); `+inf`; `-inf`; `-1`; a 10 000-character string;
empty string; empty table; a 100-level deep table; a self-referential/cyclic table; and
mixed-arity combinations (`{"", NaN}`, `{huge, inf}`, `{cyclic, {}}`, `{}, {}, {}, {}`,
`{NaN, -inf, huge, cyclic}`, `{true, false, nil, {}}`). No global `math.random` state is used.

A seeded, plausible-valid id (e.g. `"padi"`) is deliberately excluded so the state-invariance
assertion is not confused by a legitimately accepted action; reachable valid inputs are already
covered by the failure specs.

## Invariants asserted

1. `pcall(remote.OnServerEvent:Fire(player, unpack(args)))` succeeds for every connected
   C→S remote × every payload — no handler throws.
2. A canonical, cycle-safe, key-sorted snapshot of the player's save data and of the player's
   attributes is unchanged before/after each payload on the typed-argument remotes. No-arg
   action remotes (`Worker_Hire`, `Storage_Deposit/Withdraw`, `State_Request`,
   `Quest_ClaimDaily`, `Bribe_RT`, `Admin_Command`, `Harness_Command`) are still swept by
   invariant 1 but are exempt from the state assertion because they are designed to act.

Before the state snapshots, every loaded service's `ensure()`/`sync()` normalizer is driven to
a fixed point. Three apparent state changes observed before this step were traced to expected
first-touch schema settlement, **not defects**:

- `Debt_Borrow` (inf payload passes the integer guard, then hits the limit check) —
  `DebtService.ensure` adds `debt.stage`/`debt.lastInterestAt`.
- `Quest_ClaimTask` (huge-string id) — `QuestService.ensure` performs the daily rollover and
  fills quest defaults.
- `Cosmetic_Equip` with no id — `nil`/`""` is a legal unequip that clears `equipped.cosmetic`
  and re-syncs attributes.

No real state-corruption defect was found; no `BUGS.md` entry was added.

## Validation

- `lune run tests/run` — **1983 passing** (was 1980; +3 cases), exit code 0, no FAIL lines.
- `selene src` — **0 errors, 0 warnings, 0 parse errors**, exit code 0.
- `selene tests/specs/remote_fuzz_spec.luau` reports the repo's usual `@lune/fs` stdlib note
  (identical to `remote_audit_spec`) and style warnings only; the gate is `selene src`.

No source file was changed. No place was saved or published.
