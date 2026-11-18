# Spec coverage gaps — Track H, 2026-11-19

WORK_QUEUE item 11. Method: enumerated every `.luau` under `src/server` and `src/client`, then
mapped each module to the specs that `require` it (`tests/specs/*.luau`) and inspected the
`describe`/`it` names of every spec that touched it. A module counts as **covered** when at
least one spec exercises one of the four failure modes in the item: nil player, a player who
left, damaged data, or a missing/malformed remote. Pure builders, config tables, world
construction and GUI-only renderers have no such failure state and are marked N/A with the
reason. All coverage is `LUNE-ONLY`; no Studio step was needed.

## Gaps found and closed this item

| Module | Gap | New spec |
|---|---|---|
| `server/Progression/FirstSession` | Had only happy-path beat-sheet specs. No case for nil player, a player who left with no loaded data, a missing story/tutorial/flags table, null stats, or a ToolService with no `growSeconds`. | `tests/specs/first_session_failure_spec.luau` (6 cases) |
| `client/State` | Never spec'd at all. `state_spec.luau` only exercises `shared/State` (the server-side builder), not the client store that consumes snapshots/patches from remotes. | `tests/specs/client_state_failure_spec.luau` (6 cases) |
| `server/Progression/RankService` | `rank_spec.luau` covered promotion and cap accounting but not a damaged saved Nama Baik (NaN / non-number) or a damaged `cooldowns` table. | `tests/specs/rank_failure_spec.luau` (4 cases) |

A truthy non-table `story` was observed to crash `FirstSession.tick` (`data.story.flags`), but
`SaveSanitize` repairs `story`/`flags` to tables on load (`NESTED.story`, template-key repair),
so it is not reachable from a loaded player. Consistent with item 10's handling of defensive-only
concerns, it was **not** logged as a bug; the spec tests the module's actual guard cases
(missing story / missing flags).

## Server services — already covered

| Module | Failure-path spec(s) |
|---|---|
| Analytics/Analytics | `analytics_spec` (nil player, empty name, throwing AnalyticsService) |
| Data/PlayerData | `data_pass_failure_spec`, `save_reconcile_spec`, `playerdata_spec` |
| Data/SaveSanitize | `save_reconcile_spec` (wrong-typed/NaN fields, non-table save) |
| Economy/DebtCollector | `debt_collector_failure_spec` |
| Economy/DebtService | `debt_failure_spec` (incl. NaN inputs) |
| Economy/EconomyService | `economy_failure_spec`, `economy_money_spec`, `economy_config_spec` |
| Economy/MarketService | `economy_failure_spec` (NaN/inf sale counts), `market_spec` (unknown crop, bad count) |
| Economy/ShopService | `shop_failure_spec` |
| Events/CabaiEvent | `events_badges_passes_failure_spec` |
| Farm/FarmService | `farm_failure_spec`, `plot_failure_spec`, `harness_spec` (malformed attempt, player leaves) |
| Farm/PlotService | `plot_failure_spec` |
| Farm/RarityService | `rarity_spec` (nil/broken quality, out-of-range roll, always a tier) |
| Farm/StorageService | `storage_failure_spec`, `farm_failure_spec` |
| Farm/ToolService | `tool_items_failure_spec`, `farm_failure_spec` |
| Farm/TraitService | `traits_spec` (nil context) |
| Farm/WorkerService | `worker_failure_spec` |
| Law/BribeService | `bribe_failure_spec` |
| Law/CheatService | `cheat_failure_spec` |
| Law/EvidenceService | `evidence_failure_spec` (cheater left the game) |
| Law/RaidService | `raid_failure_spec` |
| Law/SusService | `sus_almanak_failure_spec` |
| Live/Admins | `security_spec` (non-admin denial, allowlist) |
| Live/AdminService | `season_admin_failure_spec` |
| Live/LiveConfig | `liveconfig_spec`, `season_admin_failure_spec` (malformed document) |
| Monetization/Cosmetics | `cosmetics_leaderboard_failure_spec` |
| Monetization/Items | `tool_items_failure_spec` |
| Monetization/Passes | `events_badges_passes_failure_spec` |
| Monetization/Receipts | `onboarding_receipts_failure_spec` (failed save → no acknowledge) |
| Net/RateLimit | `ratelimit_spec` (player leaves → bucket forgotten), `security_spec` |
| Net/RemoteGuards | `remote_audit_spec` (missing remote → no listener installed) |
| Net/State | `state_request_failure_spec` (unloaded player, malicious payload, flood) |
| Npc/CutsceneHooks | `debt_collector_failure_spec`, `npc_framework_spec` (throwing listener contained) |
| Progression/AlmanakService | `sus_almanak_failure_spec` |
| Progression/BadgeService | `events_badges_passes_failure_spec` |
| Progression/NeighborService | `warung_neighbor_failure_spec` |
| Progression/OnboardingService | `onboarding_receipts_failure_spec`, `onboarding_spec` |
| Progression/QuestService | `quest_failure_spec` |
| Season/SeasonService | `season_admin_failure_spec`, `seasons_spec` |
| Social/LeaderboardService | `cosmetics_leaderboard_failure_spec`, `leaderboard_spec` |
| Testing/Gate | `harness_spec` (Studio admin only, published server refuses) |
| Testing/RaidTrigger | `raid_trigger_spec` |
| World/WarungService | `warung_neighbor_failure_spec` |
| World/Village, Map | `greybox_retirement_spec` |

## Client controllers — already covered

| Module | Failure-path spec(s) |
|---|---|
| Feel/ActionFeel | `feel_spec` |
| Feel/CameraFeel | `camerafeel_spec`, `perf_hotpath_spec` |
| Feel/CutsceneSequencer / CutsceneState | `cutscene_sequencer_spec` |
| Feel/FidelityRuntime | `fidelity_runtime_spec`, `hook_moment_spec` |
| Feel/FidelityTier | `fidelity_tier_spec`, `tier_consumers_spec` |
| Feel/FpsSampler | `fps_sampler_spec` |
| Feel/MomentGuard | `hook_moment_spec` |
| Feel/PerfSwitches | `perf_switches_spec` |
| Feel/TierScale | `tier_consumers_spec` |
| UI/LazyPages | `lazy_pages_spec` |
| UI/PhoneWidgets | `code_health_spec` |
| World/Sky | `sky_spec` |
| World/Wind | `flora_spec`, `perf_hotpath_spec` |

## N/A — no player/data/remote failure state

- `server/Main.server`, `client/Main.client` — bootstraps; require a full DataModel. Their
  failure isolation is the `pcall(require, ...)` pattern, locked by `lookdev_candidates_spec`.
- `server/Net/Notify` — thin `FireClient`/`FireAllClients` wrapper. Its remote is created with
  the `Remotes` module at load; remote existence is audited by `remote_audit_spec`. Every service
  that calls it is covered by its own failure spec via `Fakes.notify`.
- `server/World/{Decor,Details,Flora,Ground,Landscape,LookDevWalkin,MapSpec,NpcFactory,Props}`
  and `client/World/LookDevPlaza` — world construction / look-dev appliers; structural specs
  exist (`decor_spec`, `details_spec`, `flora_spec`, `landscape_spec`, `npcfactory_spec`,
  `greybox_spec`, `lookdev_candidates_spec`) and there is no player/data/remote failure path.
- `client/Audio`, `Chat/Tags`, `UI/{Admin,Evidence,Hud,Icons,Leaderboard,Minigame,Phone,
  RaidOverlay,Theme,Tiles}`, `Minigames/{Babat,Mencangkul}` — GUI/sound renderers. Every remote
  they connect is a C→S/S→C event created by `shared/Remotes` (existence + guard audited by
  `remote_audit_spec`) and every payload is server-validated before it reaches them; they do not
  mutate save data or own a failure state. `Phone`'s extracted helpers are covered by
  `code_health_spec`, minigame cancellation by `minigame_cancel_spec`.

## Proof

- Added 3 spec files (+16 cases) and registered them in `tests/run.luau`.
- `lune run tests/run.luau`: **1788 passing** (was 1772).
- `selene src`: 0 errors / 0 warnings / 0 parse errors.
- Status: all three new specs and this coverage list are `LUNE-ONLY`.
