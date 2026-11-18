# Bug hunt by reading — Track H, 2026-11-19

WORK_QUEUE item 10. Read-through of `src/server` (folder by folder), then `src/client`, then the pure
`src/shared` modules they depend on. Subagent recon was attempted twice and both attempts failed
with `ECONNREFUSED`, so the entire pass was done in the main session. Method: whole-tree defect-pattern
scans (`table.remove` in numeric loops, bare `pcall`, undeclared global writes, `GetAttribute(...).x`
nil derefs, `math.clamp` with hardcoded bounds mirroring a config value, `or {}`/NaN guards,
division-by-variable, TODO/FIXME markers) followed by full reads of every flagged file and of all
high-risk modules (Economy/Debt/Market/Shop, PlayerData/SaveSanitize, Net/State/RateLimit/RemoteGuards,
Live/LiveConfig, Social/LeaderboardService, Analytics, Season, Monetization/Receipts/Passes/Items,
Law/RaidService/SusService, all pure shared builders and configs, and the client State/TierScale and
UI trim loops). Status words for the two findings are `LUNE-ONLY`; no Studio session was needed to
prove them.

## Defects found and fixed

### BUG-014 (major) — `Produce.snapshot` crashed on a damaged stack

`src/shared/Produce.luau` `snapshot()` indexed `stack.crop` and ran `table.clone(stack.traits)` on
every sack value with **no** `type(stack) == "table"` guard — unlike its siblings `count`,
`removeHot`, `removeClean`, which all guard. But `produce` and `gudang.stacks` are dynamic-key tables
that `SaveSanitize.sanitize` deliberately does NOT repair (only fixed keys in known nested tables),
so one damaged non-table value — or a non-table `traits` field — throws inside
`StateSchema.snapshot` / `State.section("gudang")` and breaks `State_Snapshot:FireClient` for that
player on every load/touch. Fix: skip non-table stacks and default a non-table `traits` to `{}`;
valid stacks copy byte-for-byte unchanged. Regression `tests/specs/produce_spec.luau` adds two cases
(non-table stacks, bad traits). **Mutation-checked:** restoring the old `snapshot` makes both cases
fail with `pcall` returning false; the fixed code passes.

### BUG-015 (minor) — Nama Baik price bonus ignored a tuned config

`src/server/Economy/EconomyService.luau` read `MarketConfig.namaBaikMaxBonus` to scale the Pasar
price bonus but clamped with a hardcoded `math.clamp(..., -0.05, 0.05)`. With the shipped 5% config
the behaviour was correct, but tuning `namaBaikMaxBonus` to anything else was silently capped at 5%
so the config knob did nothing. Fix: derive both bounds from `maxBonus`
(`math.clamp(..., -maxBonus, maxBonus)`), so shipped behaviour is unchanged and only a tuned config
changes payouts. Regression `tests/specs/economy_config_spec.luau` drives the real `sellAll` with a
10% config and expects +10%. **Mutation-checked:** the old clamp fails the spec (`expected 69, got
68` — +5% instead of +10%); the fixed code passes.

Both are logged in `docs/testing/BUGS.md` with severity and regression reference.

## Files reviewed with no defect found

Full reads: `Inventory`, `ShopStock`, `Leaderboard`, `NextGoal`, `State` (shared + server + client),
`Produce` (all other functions), `RemoteGuards`, `RateLimit`, `Receipts`, `Passes`, `Items`,
`LeaderboardService`, `SeasonService`, `LiveConfig`, `SusService`, `RaidService` (fine/jail),
`DebtService` (all), `MarketService`, `EconomyService` (all other functions), `SaveSanitize`,
`TierScale`, `Seasons` validators. Pattern-scanned with flagged regions read: `FarmService`,
`WorkerService`, `RarityService`, `PlotService`, `AdminService`, `EvidenceService`, `Harness`,
`Gate`, `RaidTrigger`, `CutsceneHooks`, `Village`, `NpcFactory`, all `Config/*`, `MapSpec`, `Greybox`,
`Flora`, `Decor`, `Landscape`, `Props`, `Analytics` was also fully read.

Two suspicious patterns were examined and deliberately NOT reported: `EconomyService.transfer` lacks
the `isFiniteNumber(data.cash)` guard that `trySpend` has, but `addCash`/`SaveSanitize` guarantee
finite cash on load and `math.clamp(x, 0, negativeCash)` already yields 0, so there is no reachable
bug; the single `ipairs` use (`CameraFeel`) is over a dense local list. No other real defect found.

## Proof

- `lune run tests/run.luau`: **1772 passing** (was 1769; +2 BUG-014 cases, +1 BUG-015 case).
- `selene src`: **0 errors / 0 warnings / 0 parse errors**.
- Mutation checks above prove both regression specs genuinely fail against the pre-fix code.
- **Status:** both fixes and their regressions `LUNE-ONLY` (this report + spec files). Fixes are
  pure/bounded and change no behaviour with shipped config values; no Studio check required.
