# Code Audit (pure Lune)

Per-task audit log for the T1-T16 workhorse backlog on `track/c-world-look`. Status: `LUNE-ONLY` unless noted. No invented findings.

## T1 — Single source of truth for world values
- **Findings:** `HEADROOM`/`SPAWN`/`GOLDEN_HOUR`/`SEASON_PRESETS` values were duplicated as literals/comments in `src/server/World/Greybox.luau` (headroom `9.5`, spawn comment `0,0.5,28`) and `src/shared/Config/Seasons.luau` had `musimOrder` literal `{"hujan","kemarau","pancaroba"}`, golden-hour comment `16.0–17.0`, and `clockTime = 17.0` literal; `Landscape.luau`, `Map.luau`, `client/World/Sky.luau`, `server/Season/SeasonService.luau` had no offending literals.
- **Fixes:** Removed literal headroom/spawn mentions from Greybox comments; made `Config/Seasons` source `musimOrder` and golden-hour max clock from `MapSpec` (robust lookup for Env/Roblox contexts); added `tests/specs/world_constants_spec.luau` asserting MapSpec owns values and target modules contain no duplicate literals.
- **Studio checks needed:** Verify season sky/clock behavior and client season loading still work in Studio (shared world constants are now sourced from `src/shared/Config/WorldConstants.luau`, and shared modules must not require server code).

## T2 — Remote audit / validation / rate limits
- **Findings:** All `RemoteEvent` names in `src/shared/Remotes.luau` accounted for. Client->server gameplay handlers already apply `RateLimit.allow`, type/range/enum checks, and player/data/ownership guards in reviewed services (`Economy/EconomyService`, `Economy/ShopService`, `Economy/DebtService`, `Farm/FarmService`, `Farm/StorageService`, `Farm/ToolService`, `Farm/WorkerService`, `Law/BribeService`, `Law/CheatService`, `Law/EvidenceService`, `Law/RaidService`, `Live/AdminService`, `Monetization/Cosmetics`, `Monetization/Items`, `Net/State`, `Progression/NeighborService`, `Progression/QuestService`). Gap: `Trade_Request`, `Trade_Respond`, `Event_Claim` existed as client->server remotes with no server handler (unowned/unused), leaving no explicit rate-limit/payload-ignore contract.
- **Fixes:** Added `src/server/Net/RemoteGuards.luau` to rate-limit (2/s burst) and ignore payloads for unowned remotes (`Trade_Request`, `Trade_Respond`, `Event_Claim`) without mutating state; wired `RemoteGuards.start()` in `src/server/Main.server.luau`. Added `tests/specs/remote_audit_spec.luau` covering guarded payload ignoring, rate-limit behavior, and crop-id validation contract. No behavior changes to existing gameplay handlers (spec-proven gaps only).
- **Studio checks needed:** Confirm no client flows rely on immediate responses for trade/event remotes (none implemented server-side); verify admin/quest/cosmetic/raid remotes still behave correctly in live Studio sessions.

### T2 remote table
| Remote | Direction | Handler / owner | Guards (type/range/rate/ownership) |
| --- | --- | --- | --- |
| `Farm_SelectSeed` | C->S | `Farm/FarmService` | rate 8/s, string crop id in `Crops.list` |
| `Farm_Complete` | C->S | `Farm/FarmService` | rate 4/s, finite number score, pending attempt + timing window, server re-check in finish |
| `Farm_Auto` | C->S | `Farm/FarmService` | rate `GameConfig.autoRatePerSecond`, pending/action/tile/crop match, enum action |
| `Shop_BuySeed` | C->S | `Economy/ShopService` | rate 2/s, player data, string crop, integer amount 1..99, stock/rank/cash checks |
| `Storage_Deposit` | C->S | `Farm/StorageService` | rate 3/s, player data, no payload; refuses hot/empty/full by state |
| `Storage_Withdraw` | C->S | `Farm/StorageService` | rate 3/s, player data, no payload |
| `Tool_Buy` | C->S | `Farm/ToolService` | rate 1/s, player data, string line id, config/rank/cash checks |
| `Worker_Hire` | C->S | `Farm/WorkerService` | rate 2/s, player data, no payload, shift/cash checks |
| `Market_Sell` | C->S | `Economy/EconomyService` | rate 1/s, player data, crop/channel enum, produce/proximity checks |
| `Cheat_Apply` | C->S | `Law/CheatService` | rate 1/s, string cheat id, typed tile/target bounds, service/state checks |
| `Bribe_RT` | C->S | `Law/BribeService` | rate 1/s, player data, proximity/cooldown/cash checks |
| `Raid_Choose` | C->S | `Law/RaidService` | rate 1/s, string enum choice, choosing-state/player-data guards |
| `Evidence_Record` | C->S | `Law/EvidenceService` | rate 2/s, string event id, offer/expiry ownership checks |
| `Evidence_Report` | C->S | `Law/EvidenceService` | rate 1/s, string token id, owner/expiry/proximity/cooldown checks |
| `State_Request` | C->S | `Net/State` | rate 1/s, snapshot only for loaded player |
| `Water_Neighbor` | C->S | `Progression/NeighborService` | rate 1/s, numeric target, not-self, neighbor/proximity/data checks |
| `Quest_ClaimDaily` | C->S | `Progression/QuestService` | rate 2/s (`CLAIM_RATE`), player data, claim-once/day checks |
| `Quest_ClaimTask` | C->S | `Progression/QuestService` | rate 2/s, string task id, task/progress/definition checks |
| `Debt_Borrow` | C->S | `Economy/DebtService` | rate 2/s, finite integer amount, rank/raid/active-loan checks |
| `Debt_Repay` | C->S | `Economy/DebtService` | rate 2/s, finite integer amount, active-loan checks |
| `Item_Use` | C->S | `Monetization/Items` | rate 1/s, string item id, inventory/cooldown/state checks |
| `Cosmetic_Buy` | C->S | `Monetization/Cosmetics` | rate 2/s, string item id, config/ownership/cash checks |
| `Cosmetic_Equip` | C->S | `Monetization/Cosmetics` | rate 4/s, nil/empty unequip or string owned item id |
| `Admin_Command` | C->S | `Live/AdminService` | rate 4/s, admin allowlist, payload/action whitelist, per-action typed validation/clamps |
| `Trade_Request` | C->S | `Net/RemoteGuards` | rate 2/s, payload ignored, no state mutation (unowned) |
| `Trade_Respond` | C->S | `Net/RemoteGuards` | rate 2/s, payload ignored, no state mutation (unowned) |
| `Event_Claim` | C->S | `Net/RemoteGuards` | rate 2/s, payload ignored, no state mutation (unowned) |
| `State_Snapshot` | S->C | `Net/State` | server-owned snapshot; client request rate-limited |
| `State_Patch` | S->C | `Net/State` | server-owned coalesced patches |
| `Notify` | S->C | `Net/Notify` | server-owned UI notifications |
| `Sus_Update` | S->C | `Law/SusService` | server-owned sus state |
| `Minigame_Start` | S->C | `Farm/FarmService` | server-owned attempt start |
| `Raid_Start` | S->C | `Law/RaidService` | server-owned raid state |
| `Raid_End` | S->C | `Law/RaidService` | server-owned raid state |
| `Jail_State` | S->C | `Law/RaidService` | server-owned jail timer |
| `Evidence_Offer` | S->C | `Law/EvidenceService` | server-issued token offer |
| `Evidence_Token` | S->C | `Law/EvidenceService` | server-issued token |
| `Evidence_Remove` | S->C | `Law/EvidenceService` | server-issued removal |
| `Profile_Loaded` | S->C | `Data/PlayerData` | server-owned load signal |
| `Leaderboard_Data` | S->C | `Social/LeaderboardService` | server-owned board payload |
| `Admin_Result` | S->C | `Live/AdminService` | reply to admin caller only |
| `Harness_Result` | S->C | `Testing/Harness` | Studio/test harness reply |

## T3 — Farm failure-path specs/fixes
- **Findings:** Existing farm coverage (harness/storage/worker/tool/seedfloor specs) left several failure paths unpinned: invalid/malformed `Farm_*` remote payloads and `FarmService.commitAttempt` args, harvest refusals at sack/gudang capacity boundaries, `harvestToStorage` invalid/not-ready/full states, `applyOplosan`/`confiscateHotTiles` invalid-state guards, `stealWater` no-op cases, and nil-data publish/tick/buy handling. Spec run exposed a crash gap: `StorageService.publish(player, nil)`/capacity assumed `data` and called gudang setup unguarded.
- **Fixes:** Added `tests/specs/farm_failure_spec.luau` (registered in `tests/run.luau`) covering FarmService invalid remote/attempt inputs, sack-full harvest refusal, storage harvest edge cases, oplosan/confiscation/steal-water guards, and Storage/Worker/Tool nil-data/rate-limit failure paths (modeling gudang capacity floor/pass behavior correctly). Hardened `src/server/Farm/StorageService.luau` (`publish`/`capacity`/`used` nil-safe, preserve capacity-floor semantics) so publish and capacity reads cannot crash on missing data.
- **Studio checks needed:** In Studio, verify plant/harvest flows still refuse full sack correctly, oplosan/confiscate visuals/state clear as before, and gudang deposit/withdraw UI counts remain correct after nil-safe publish changes.

## BLOCKED
- `BUG-004` — was pending designer decision D-G3 at the time of this audit; **resolved 2026-11-19**: D-G3 option A (free 1 `padi` seed floor) implemented in `FarmService.checkSeedFloor` and verified in Studio (`docs/v2/evidence/h/2026-11-19-gate1-studio/`), bug closed. No longer blocked.

## T1 follow-up: shared config required server code (found in review)

- `src/shared/Config/Seasons.luau` located `MapSpec` through ServerScriptService and a relative string
  require. `client/World/Sky.luau` loads Seasons, and the client cannot see server code, so the client
  would have errored at load (`LUNE-ONLY`, not run in Studio).
- Fix: `GOLDEN_HOUR` and `SEASON_PRESETS` now live in `src/shared/Config/WorldConstants.luau`; MapSpec
  re-exports them and Seasons requires WorldConstants directly. Spec added in `world_constants_spec`.
- Studio later: confirm the client loads Sky with no errors in Output.
- Rule for later tasks: modules under `src/shared` must never require anything under `src/server`.

## T4 — Economy: money invariants (Shop, Economy, Market)
- **Findings:** `EconomyService.sellAll` removed the produce from the sack before `addCash` ran. A non-finite payout (`count = math.huge`) was refused by `addCash`, so the sack was erased and no cash was paid. Nothing capped a single payout or cash balance.
- **Fixes:** `EconomyService.MAX_CASH = 1e12` is an explicit ceiling, applied in `addCash` and to every Pasar and Gelap sale. Non-finite payouts are refused before produce is removed. Stacks with a non-finite or non-positive count are skipped.
- **Specs:** `tests/specs/economy_money_spec.luau` covers two back-to-back `buySeed` calls (no overspend, cash never negative), a double sell (pays once, sack empty), integer payouts across rarity tiers, Cabai event, Ordal pass and Nama Baik, a huge stack staying under the cap, and an infinite stack keeping its produce.
- **Note:** The sale path has no season multiplier, so the season part of the payout rule is not testable yet. Add a spec when one exists.

## T4 — Debt: persistence, clock and invariants
- **Findings:** None. Interest, due date and the stage survive save and reload. A clock that rewinds gives zero interest. An overdue loan is escalated once on rejoin, not on every rejoin. A 60-step borrow/repay/tick chain keeps cash and owed non-negative, owed under 3x principal, and owed zero once the loan is inactive.
- **Specs:** `tests/specs/debt_persistence_spec.luau` (save/reload via a deep-copied fixture, rewind, rejoin, invariant chain).

## T4 — Produce count and gudang seizure guards
- **Findings:** `Produce.count` only checked `type == number`, so a NaN count poisoned the total. `seizeGudang` accepted an infinite count and seized the whole debt from one corrupt stack. `removeClean` and `removeHot` could delete corrupt stacks and report them as removed.
- **Fixes:** `Produce.validCount` accepts only finite numbers above zero. `count`, `removeClean`, `removeHot` and `seizeGudang` use it. Corrupt stacks are kept, not erased, and count or pay nothing.
- **Specs:** `tests/specs/produce_guard_spec.luau` (NaN, infinite, negative and non-number counts in count, removal and seizure).

## WORK_QUEUE item 2 — full remote-handler security re-pass (2026-11-19, `LUNE-ONLY`)

- **Scope:** re-read every `OnServerEvent` / `OnServerInvoke` handler under `src/server` (48 connection sites across ShopService, AdminService, WorkerService, StorageService, PlotService, RaidService, PlayerData, EvidenceService, BribeService, ToolService, EconomyService, CheatService, FirstSession, DebtService, FarmService, NeighborService, Cosmetics, Items, QuestService, RateLimit, Harness, Passes, RemoteGuards, Village, State, LeaderboardService) and cross-checked each C->S remote against the T2 table above and its behavioural failure-path spec.
- **Result:** every C->S remote is either handled with type/range validation + a rate limit in its owning service, or explicitly guarded by `RemoteGuards`. Server authority over cash/items holds: money and inventory mutate only inside EconomyService/DebtService/ShopService/etc after player/data/ownership checks; no client payload writes cash or an item id directly. No new exploitable gap was found, so no production fix was needed.
- **Coverage map (exploit vector -> spec):** cash/item bounds `economy_money_spec`, `economy_failure_spec`, `debt_failure_spec`, `debt_persistence_spec`; shop/tool/seed args `shop_failure_spec`, `tool_items_failure_spec`; farm/minigame/tile `farm_failure_spec`, `plot_failure_spec`, `seedfloor_spec`; raid choice `raid_failure_spec`, `raid_trigger_spec`; bribe/cheat/evidence `bribe_failure_spec`, `cheat_failure_spec`, `evidence_failure_spec`; admin/season `season_admin_failure_spec`, `security_spec`; cosmetics/items/quests/neighbor/storage/worker `cosmetics_leaderboard_failure_spec`, `tool_items_failure_spec`, `quest_failure_spec`, `warung_neighbor_failure_spec`, `storage_failure_spec`, `worker_failure_spec`; unowned remotes `remote_audit_spec`.
- **Gap found and closed:** `State_Request` had only the static rate-limit assertion in `remote_audit_spec`, no behavioural failure-path spec. Added `tests/specs/state_request_failure_spec.luau` (registered in `tests/run.luau`): a malicious oversized/NaN payload is ignored and only the caller's own snapshot is sent; an unloaded player's request sends nothing and never errors; a 20-call flood is rate-limited to one snapshot per second. No State module change needed — the handler was already correct.
- **Verification:** `lune run tests/run.luau` 1712 passing; `selene src` 0 errors / 4 pre-existing warnings (item 8).
