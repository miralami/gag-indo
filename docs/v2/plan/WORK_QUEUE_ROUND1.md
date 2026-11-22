# Work queue round 1 — ARCHIVE (closed 2026-11-19 at a618f02; live queue is WORK_QUEUE.md)

The agent works this list top to bottom without stopping (see `AGENTS.md` "Long-run mode").
Tick an item in the same commit as its work. If an item is blocked on the designer, mark it
`BLOCKED — <reason>` and move to the next one. Add new agent-doable items at the bottom.

Started 2026-11-19 from `f6941be` (1700 tests passing).

## Queue

- [x] 1. **Q5 ten-player half, Lune side.** Multi-player simulation spec: 10 fake players run
  plant/harvest/sell/buy/raid/debt at the same time, interleaved, on the real services with
  Fakes. Assert no shared-state leak between players, no stuck raid or minigame state, no
  negative or NaN cash, no duplicated items. Fix each bug found and add a regression spec.
  Status `LUNE-ONLY`; the live multi-client half stays `BLOCKED` on the designer.
  Done 2026-11-19: `tests/specs/multiplayer_sim_spec.luau` (9 passing cases) drives the real
  EconomyService/MarketService/DebtService, RaidService and FarmService with 10 Fakes players
  across interleaved grants/buys/sells/loans, raids/choices and plant/harvest; asserts per-player
  cash/items/tiles/debt/raid isolation, no NaN/negative cash, no duplicated seeds and no stuck
  raid or minigame state. No isolation defect found, so no production fix was needed. Suite 1709.
- [x] 2. **Security pass.** Check every RemoteEvent/RemoteFunction handler in `src/server` for
  argument type and range validation, rate limits, and server authority over cash and items.
  Write a failure-path spec for each exploit vector, then fix it. Record results in
  `docs/testing/CODE_AUDIT.md`.
  Done 2026-11-19: re-read all 48 handler connections under `src/server`; all C->S remotes already
  validated/rate-limited/guarded with a failure-path spec. Closed the one gap with
  `tests/specs/state_request_failure_spec.luau` (payload ignored, unloaded player safe, flood
  rate-limited); no production fix needed. Full re-pass recorded in `docs/testing/CODE_AUDIT.md`.
  Suite 1712.
- [x] 3. **Data pass.** Check ProfileStore session locking, the migrate → SaveSanitize order, and
  DataStore errors at load and at save. Specs for each failure path, then fixes.
  Done 2026-11-19: `tests/specs/data_pass_failure_spec.luau` (7 passing cases) drives the real
  PlayerData with a fake ProfileStore (no DataStore/real profile touched): Studio store key +
  Cancel on leave/timeout, Reconcile→migrate→sanitize order before loaded callbacks, nil-profile
  kick, OnSessionEnd kick + profile clear, leave-mid-load EndSession, saveAndConfirm receipt/error/
  timeout, and pcall-isolated beforeRelease callbacks. All paths correct, no production fix needed.
  Suite 1719.
- [x] 4. **Studio checks of `LUNE-ONLY` items.** Turn each into `SEEN-IN-STUDIO` with evidence:
  - force each FidelityTier and read the settings it applied;
  - TierScale particle and wind consumers;
  - crop stages bibit/tumbuh/siap;
  - Cabai event start, banner and countdown;
  - debt-collector cutscene hooks;
  - NPC archetype fields on the live NPCs;
  - 9.5-stud headroom raycast in all six hubs;
  - the three season presets.
  Where a check needs a Studio-only harness hook, follow the gated `RaidTrigger` pattern and add a
  gate spec.
  Done 2026-11-19: all eight sub-checks `SEEN-IN-STUDIO` via Studio MCP `execute_luau` on the real
  Rojo-synced modules (pure/config in Edit mode; Cabai + headroom in a Play Solo Server VM with the
  real built 1706-part World). FidelityTier tiers 0.4/0.7/1.0 particleRate and 25/50/80 sway;
  TierScale bursts 8/14/20 and wind sway weights; crop bibit/tumbuh/siap config + selection; Cabai
  timed ×3 banner with 300 s countdown, forced-on banner no countdown, forced-off clear; debt
  collector summoned/dismissed hook events + unsubscribe; all NPC archetype fields; 9.5-stud
  headroom clear in all six hubs (zero offenders, raycasts pass); three season presets. No defect
  found, so no production fix and no new gated hook needed. Evidence
  `docs/v2/evidence/h/2026-11-19-studio-checks/` (`REPORT.md`, `results.json`). Suite 1719.
- [x] 5. **Retire `Greybox.luau` to a test-only fallback.** Prove the live world doesn't depend on
  it: specs pass, and a Studio play shows the same hubs with no Output errors.
  Done 2026-11-19: `tests/specs/greybox_retirement_spec.luau` (6 cases) proves `Map.isDesignerWorld()`
  is true on `VillageWorld` or `PlotAnchor`, `Village.build()` calls `Greybox.build()` only with no
  designer world, and all six hubs / 5 prompts / 3 NPCs bind from tags alone (rebind safe). Studio
  Edit mode: injected designer world, `Village.build()` created 0 Greybox parts (279→279). Play Solo
  Server VM: destroyed the 1706-part Greybox world, injected a designer world, rebuilt — no Greybox
  geometry regenerated, six hubs + 5 prompts + 3 NPCs bound, console identical (0 new Output errors).
  `SEEN-IN-STUDIO`, evidence `docs/v2/evidence/h/2026-11-19-greybox-retirement/`. Suite 1725.
  Note: the code path is retired; the actual place still needs the designer's real village (Track C),
  which this run does not save. Safe default to keep the fallback until then — "Decisions for designer".
- [x] 6. **Performance pass.** Count instances per hub, find connection leaks (Heartbeat and
  RenderStepped handlers with no cleanup) and per-frame allocations in hot paths. Fix them and
  record before/after numbers.
  Done 2026-11-19: instance counts per hub recorded (1706 parts / 3289 descendants total; no
  regression). Two connection leaks fixed: `Wind.stop()` (heartbeat + WindShake tag-removed) and
  `CameraFeel.stop()` (heartbeat + CharacterAdded/CharacterRemoving), both idempotent and
  restart-safe. One hot-path allocation fixed: Wind resolved FidelityRuntime once at start instead
  of rebuilding a pcall closure + require on every 20 Hz tick (1→0 closures/resolutions per tick),
  while still reading settings() each tick so tier changes land. `tests/specs/perf_hotpath_spec.luau`
  (7 cases, `LUNE-ONLY`) proves once-per-start resolution, disconnect-on-stop and restart; Studio
  client VM confirms both modules load with `stop` present, 0 new Output errors. Evidence
  `docs/v2/evidence/h/2026-11-19-performance/`. Suite 1732; selene 0 errors / 3 warnings.
- [x] 7. **Localization pass.** All player text goes through `Strings.luau` with `id` and `en`;
  nothing is hardcoded in the UI. Extend `strings_integrity_spec` to catch stragglers.
  Done 2026-11-19: appended 8 keys (cash/gain/price labels, Admin button, Juragan/Ordal chat tags,
  plot empty/owned signs) and routed every hardcoded player-facing literal through Strings: Hud,
  Tiles, Admin, ActionFeel, Tags and the PlotService world sign. `ActionFeel.start(lang)` /
  `Tags.mount(lang)` now receive the locale resolved once in Main.client; plot signs follow the
  owner's LocaleId like DebtCollector. `strings_integrity_spec` gained a src-wide scanner that flags
  word-like literals assigned to `*Text` (glyphs allowlisted), a self-test proving it catches
  stragglers, and currently reports zero. `plot_failure_spec` asserts the key-derived sign text.
  `SEEN-IN-STUDIO` (live HUD `Rp 35,857` in the en-us client, 9 plot signs `Lahan Kosong`, all 8
  keys resolve, 0 new Output errors); evidence `docs/v2/evidence/h/2026-11-19-localization/`.
  Suite 1750; selene 0 errors / 3 warnings.
- [x] 8. **Code health.** Split modules over ~600 lines where the split is clean, and clear the 4
  selene warnings where safe. Lock behaviour with specs before refactoring.
  Done 2026-11-19: cleared the 3 remaining selene unused-variable warnings by deleting confirmed dead
  code (`tryAddHudButton` in Admin — wiring it would change UI behaviour, so it was removed instead;
  `stripTop` in MapSpec; `hubWall` in Greybox). Extracted Phone's three generic view helpers
  (`clearChildren`, `sectionLabel`, `scrollPage`) into a new `src/client/UI/PhoneWidgets.luau` with
  local aliases in Phone so every call site is unchanged; restored the `Icons` require Phone still
  needs for app-grid tiles. `tests/specs/code_health_spec.luau` (5 cases) locks helper behaviour before
  the move and asserts no inline definitions remain. No other >600-line file was split — the rest are
  tightly coupled stateful controllers where a split adds risk without benefit; vendored ProfileStore
  is off-limits. `SEEN-IN-STUDIO` load/no-regression (Phone + PhoneWidgets load all functions, 0 probe
  errors, 0 new Output errors); evidence `docs/v2/evidence/h/2026-11-19-code-health/`. Suite 1754;
  selene 0 errors / 0 warnings / 0 parse errors."
- [~] 9. **Look-dev candidates for designer review.** Behind an opt-in toggle that is off by
  default. No asset IDs: procedural parts and Roblox textured materials only, in the
  cartoonish-realism style. Two candidates:
  - an alternative material and lighting preset for the plaza hub;
  - a police NPC walk-in prototype that uses the existing police model and pathing, timed to the
    walkin shot.
  Record each as "candidate, awaiting designer yes". Never tick these as done.
  **BLOCKED — both candidates prepared and awaiting designer yes (per item rule this checkbox stays
  open; do not redo).** Done 2026-11-19: pure shared registry/gate `src/shared/LookDev.luau` with
  both candidates and their plans; thin reversible appliers `src/client/World/LookDevPlaza.luau`
  (built-in-material swaps + alternate midday grade on the Pasar model, remembers originals) and
  `src/server/World/LookDevWalkin.luau` (reuses `Village.police[1]` + `walkTo()` to the cutscene
  road anchor over the real 1.8 s walkin shot, teleports home on disable). Both registered by
  isolated `pcall(require, ...)` in the Main bootstraps. Toggle is OFF by default, Studio-only,
  in-memory only, one candidate active at a time, never persisted; no asset IDs (spec-enforced),
  cartoonish-realism. `tests/specs/lookdev_candidates_spec.luau` (15 cases) locks gate/plans/no-IDs/
  wiring. `SEEN-IN-STUDIO` load + gate + live reversible toggle (ClockTime 17.2→11.4→restored) in
  both client and server Play Solo VMs, 0 probe errors, 0 new Output errors; evidence
  `docs/v2/evidence/h/2026-11-19-lookdev-candidates/`. Suite 1769; selene 0 errors / 0 warnings /
  0 parse errors. Final visual approval is the designer's "yes" — see Decisions for designer.
- [x] 10. **Bug hunt by reading.** Go through `src/server` one folder at a time, then `src/client`,
  reading every line. Log each defect in `BUGS.md` with a severity, then fix it with a regression
  spec. Bugs found here outrank the items below.
  Done 2026-11-19: whole-tree defect-pattern scan of `src/server`/`src/client`/`src/shared` + full
  reads of all high-risk money/data/net/live/logic modules (subagent recon twice failed
  `ECONNREFUSED`, so done in main session). Two defects found, fixed, mutation-proven, logged in
  `BUGS.md`: **BUG-014 (major)** `Produce.snapshot` had no `type(stack) == "table"` guard (unlike its
  siblings) and crashed `State_Snapshot` on a damaged dynamic-key stack — skip corrupt stacks /
  non-table `traits`; 2 cases in `tests/specs/produce_spec.luau`. **BUG-015 (minor)** `EconomyService`
  Nama Baik bonus read `MarketConfig.namaBaikMaxBonus` but clamped with a hardcoded ±0.05, so a tuned
  config was silently capped — derive bounds from `maxBonus`; `tests/specs/economy_config_spec.luau`.
  Both mutation-checked (old code fails the new spec). Suite 1772; selene 0 errors / 0 warnings /
  0 parse errors. Evidence `docs/v2/evidence/h/2026-11-19-bug-hunt-reading/`. `LUNE-ONLY`.
- [x] 11. **Spec coverage gaps.** List each service and client controller that has no failure-path
  spec (nil player, a player who left, damaged data, a missing remote) and write one for each.
  Done 2026-11-19: mapped every `src/server`/`src/client` module to its specs and inspected the
  failure-case names (full list + N/A justifications in
  `docs/v2/evidence/h/2026-11-19-spec-coverage/COVERAGE.md`). Gaps closed: **FirstSession** (only
  happy-path specs → `first_session_failure_spec.luau`, 6 cases: nil player, player left, missing
  story/tutorial/flags, null stats, unusable ToolService), **client/State** (never spec'd; only
  `shared/State` was → `client_state_failure_spec.luau`, 6 cases: malformed snapshot/patch ignored,
  valid snapshot/patch applied, idempotent listener disconnect), **RankService** (damaged-save
  recovery → `rank_failure_spec.luau`, 4 cases: NaN/non-number Nama Baik, NaN attribute mirror,
  damaged cooldowns table). A truthy non-table `story` crash was judged defensive-only (SaveSanitize
  repairs it) and not logged as a bug. Suite 1788; selene 0 errors / 0 warnings / 0 parse errors.
  `LUNE-ONLY`.
- [x] 12. **Player leaves mid-state.** For every state a player can be in (each raid state, debt
  collector, minigame, phone open, cutscene, selling), check that the server cleans up on
  PlayerRemoving: no orphan tasks, NPCs, attributes or locks. Specs first, then a Studio check.
  Done 2026-11-19: inventoried every `PlayerRemoving` handler (incl. `onBeforeRelease` hooks) and
  mapped prior coverage (full table in `docs/v2/evidence/h/2026-11-19-player-leave-cleanup/REPORT.md`).
  Six handlers had no spec → `tests/specs/player_leave_cleanup_spec.luau` (10 cases): debt collector
  NPC dismissal, IsAdmin attribute clear, leaderboard final flush, harness gate close, evidence
  offers/tokens drop, Net/State release hook. Raid/farm/plot/ratelimit/data-pass leave paths were
  already spec'd and verified; no game source changes (cleanup was already correct). Suite 1798;
  selene 0/0/0; `LUNE-ONLY` specs. Studio helper smoke `SEEN-IN-STUDIO` (clean boot, real
  `resolveOnLeave`/`Gate.close`/`tokenCount` exercised in Server datamodel); the actual
  leave-transition check is `BLOCKED — Studio MCP cannot fire the engine PlayerRemoving signal and
  has no local-server/team-test tool to spawn a departing second player (Play Solo has one local
  player).` Place not saved.
- [x] 13. **Respawn and rejoin.** Audit CharacterAdded and respawn handlers for duplicate
  connections, and check that UI is rebuilt correctly after a reset. Specs, plus a Studio reset
  loop of 10 resets with no growth in connection count.
  Done 2026-11-19: audited every `CharacterAdded`/respawn connection — each is bound once per
  session (`PlayerData.onLoaded` or idempotent `start()`), never per respawn; `CameraFeel` uses a
  generation counter, `RaidOverlay` clears per-cutscene death connections. No production fix needed.
  `tests/specs/respawn_rejoin_spec.luau` (5 cases) locks: FarmService/Cosmetics connect once across
  10 respawns with exactly one teleport/hat per reset, CameraFeel keeps one connection per signal
  across 10 cycles, `Theme.screenGui` is `ResetOnSpawn=false` (phone page rebuild already in
  `lazy_pages_spec`). Suite 1803; selene 0/0/0; `LUNE-ONLY` specs. Studio 10-reset loop
  `SEEN-IN-STUDIO`: all 10 resets spawned a fresh character at the same plot position, Client
  PlayerGui stayed at 11 ScreenGuis with none `ResetOnSpawn=true`, clean boot — evidence
  `docs/v2/evidence/h/2026-11-19-respawn-rejoin/REPORT.md`. Exact engine connection count is not
  introspectable via Studio MCP (separate `require` VM, no signal API); invariants locked by specs.
  Place not saved.

- [x] 14. **Purchases.** Check receipt handling (no product IDs invented): a duplicate
  PurchaseId, the player leaving mid-grant, a failed save after grant, unknown products, game pass
  checks that error. Each case gets a spec that proves idempotency.
  Done 2026-11-19: `tests/specs/purchase_idempotency_spec.luau` (5 cases, `LUNE-ONLY`) drives the
  REAL `PlayerData` + `Receipts` against a fake ProfileStore (synthetic ids 111/777, shipped config
  stays at 0): duplicate PurchaseId grants/notifies once; leave mid-grant returns NotProcessedYet
  and a rejoin retry grants once; failed save is re-confirmed on retry with no double grant;
  unknown and placeholder-0 products are never acknowledged; an erroring game-pass check grants
  nothing across retries. Suite 1808; selene 0/0/0. Found and fixed **BUG-016** (major, money bug):
  the dedup early-return acknowledged a replayed PurchaseId without re-confirming a save, so a
  failed save followed by a retry could acknowledge a purchase that was never durably saved. Fix:
  re-run `saveAndConfirm` on the dedup path before acknowledging; no re-grant/re-notify.
  Mutation-checked. Evidence `docs/v2/evidence/h/2026-11-19-purchases/REPORT.md`.
- [x] 15. **Cross-server and leaderboard failures.** Cover OrderedDataStore, MessagingService and
  MemoryStore errors with backoff and last-good fallback, plus budget-limit handling. Specs.
  Done 2026-11-19: `tests/specs/cross_server_failure_spec.luau` (9 cases, `LUNE-ONLY`). LiveConfig
  DataStore/MessagingService failure paths (read/write/publish/subscribe errors never throw, malformed
  messages sanitized, local changes survive failed writes); OrderedDataStore retry cap/backoff/throttle
  under a failed burst; Analytics budget already covered by `analytics_spec`. **MemoryStore N/A** —
  no usage in `src/`, none invented. Suite 1817; selene 0/0/0. Found and fixed **BUG-017** (major):
  `LiveConfig` trusted `updatedAt` but never ordered by it, so a stale MessagingService message or
  eventually-consistent DataStore read rolled newer live config back across all servers, and a corrupt
  `updatedAt` (NaN/±inf/negative) could freeze all future updates. Fix: finite non-negative `updatedAt`
  in `sanitize()` + `isStale()` guard in `subscribe()` and `load()`; legacy patches without a timestamp
  still apply. Mutation-checked. Evidence
  `docs/v2/evidence/h/2026-11-19-cross-server-failures/REPORT.md`.
- [x] 16. **Admin and season tools.** Every admin command validates who calls it and what it
  receives; non-admins are refused; no admin path can grant unbounded cash or items. Specs.
  Done 2026-11-19: `tests/specs/admin_authority_spec.luau` (4 cases, `LUNE-ONLY`) wires the REAL
  `Admins` + `LiveConfig` + `AdminService` (existing `season_admin_failure_spec` only tested them
  mocked): non-allowlisted player refused for all 5 privileged actions on a published server;
  forging the `IsAdmin` attribute grants nothing; allowlisted designer changes the real config and
  grants cash with `earned=false`/`sku=admin_grant`; Studio's everyone-is-admin still enforces every
  payload bound. Payload bounds, rate limit, grant caps and reply isolation already covered by
  `season_admin_failure_spec`. No source bug; no game source changed. Suite 1821; selene 0/0/0.
  Evidence `docs/v2/evidence/h/2026-11-19-admin-authority/REPORT.md`.
- [x] 17. **Analytics audit against `ANALYTICS.md`.** Every documented event fires from the right
  trigger, funnel steps are in order and fire once, and payloads have bounded size. Spec each
  event; list any missing event in "Decisions for designer".
  Done 2026-11-19: `tests/specs/analytics_audit_spec.luau` (24 cases, `LUNE-ONLY`). Static audit:
  `AnalyticsService` has a single owner (`src/server/Analytics/Analytics.luau`); all 16 documented
  §2 custom events have call sites in their owning services; economy + onboarding funnel emissions
  exist; `ShopPurchase` is intentionally unwired and `first_harvest` is an example with no call site.
  Behavioural: real `OnboardingService` + `Analytics` log steps 1..N in order exactly once then
  `finished` (duplicate/out-of-order actions log nothing); real `EconomyService` logs Source/Sink
  with the post-mutation balance and skips refused mutations. Bounded payloads already locked by
  `analytics_spec` (3-field cap). No source bug; no game source changed. Studio dashboard check is
  still `belum diverifikasi di Studio` (ANALYTICS.md §7). Suite 1845; selene 0/0/0. Evidence
  `docs/v2/evidence/h/2026-11-19-analytics-audit/REPORT.md`.
- [x] 18. **NPC pathing robustness.** Police and debt-collector walk-to-plot for every plot: add
  stuck detection, a timeout and a teleport fallback. Specs, plus a Studio run to each plot.
  Done 2026-11-19: new dependency-free `src/server/World/NpcWalk.luau` walks a host toward a goal
  with stuck detection (~0.6 s), a timeout (2× expected + 3 s floor) and a teleport fallback onto the
  goal, while cancellation/unparenting aborts without teleport. `NpcFactory:walkTo` (police, via
  RaidService) and `DebtCollector.summon` both delegate to it; collector now walks from its spawn
  offset to `plot.spawnCFrame.Position` for every plot. `tests/specs/npc_pathing_robustness_spec.luau`
  (9 cases, `LUNE-ONLY`) locks arrival/stuck/timeout/cancel/unparent/multi-plot/no-pivot and both
  call sites; mutation-checked. Studio (`SEEN-IN-STUDIO`, Server VM): walked a real Part to all ten
  plots with final XZ distance 0.00 each, and the stuck fallback commanded exactly the goal; no
  game-code errors, place not saved, no `profile:Save()`. Caller-level live run limited: no
  `Village.police` bound and the solo player had no assigned plot (wiring locked by spec instead).
  Caught and fixed a native-`vector` type mismatch during the Studio run (`type()` is `"vector"` in
  Studio, not `"table"`/`"userdata"`): `positionOf` now reads fields via `pcall`. Suite 1854;
  selene 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-npc-pathing/`.
- [x] 19. **UI fit at 749×388.** For every screen and app page, probe AbsolutePosition and
  AbsoluteSize in Studio. Nothing may be off-screen or overlap the safe-area insets. Fix by
  layout, not by shrinking text below the minimum.
  Done 2026-11-19 (`SEEN-IN-STUDIO`): Studio device sim `average_windows` at 750×388 → real GUI
  viewport 749×388, safe rect `{0,-58,749,388}`. Probed effectively-visible `AbsolutePosition`/
  `AbsoluteSize` of every screen and app page — HUD (50), Phone home (105), all six lazy pages
  `phone/kebun/pinjol/tugas/cheat/dekor` (84/139/74/90/83/82), Shop and Leaderboard panels (131/60),
  Toasts, Minigame card and RaidOverlay — all with **0 off-screen/inset violations**. Found and fixed
  one genuine layout defect: `AdminPanel` bottom rows clipped ~17–25 px because `refit()` fitted the
  scale to full camera height 388 while the GUI inset leaves only 330 usable; it now subtracts
  `GuiService:GetGuiInset().Y`. In-Studio re-probe: scale 0.4435, panel bottom 324 < 330, 0 violations.
  No text size reduced; place not saved, no `profile:Save()`. Suite 1854; selene 0/0/0. Evidence
  `docs/v2/evidence/h/2026-11-19-ui-fit/` (`REPORT.md`, `results.json`).
- [x] 20. **Touch target and text size audit.** A spec walks every UI builder: buttons at least
  44×44 and text at the minimum size or above. Fix the stragglers.
  Done 2026-11-19 (`LUNE-ONLY`): `tests/specs/ui_touch_text_audit_spec.luau` (5 cases) walks all
  UI source under `src/client/UI`, `Minigames`, `Feel` and `server/World` — no `TextSize`/
  `MinTextSize` literal below `Visuals.type.small` (11), every interactive button meets the
  checked-in `PhoneLayout.meetsTouch` one-axis 44 px rule, grid-sized families checked against
  their cell sizes. Two genuine text stragglers fixed in `Phone.luau`: the app-label constraint
  `MinTextSize` 10→11 and the phone-toggle label `MinTextSize` 9→11 (both allowed text to render
  below the minimum under `TextScaled`). Mutation-checked: reverting either fix fails two cases.
  No button failed the touch audit. Suite 1859; selene 0/0/0.
- [x] 21. **Gamepad and keyboard.** Every screen can be closed with B or Escape, selection never
  gets stuck in a hidden frame, and there is a default selection on open. Specs where the logic
  is pure, plus a Studio pass with `GuiService.SelectedObject`.
  Done 2026-11-19 (`SEEN-IN-STUDIO` for selection, `LUNE-ONLY` for the binding/cancel policy):
  pure `src/client/UI/Navigation.luau` (LIFO stack, cancel skips forced overlays, rescue keeps a
  visible selection or falls back to the top open default or clears; permanent `_byId` registry
  separate from active `_stack` so close→reopen restores the default) + Studio-only
  `src/client/UI/NavBridge.luau` binds B/Escape at High priority (Begin gate, Sink only on close,
  else Pass) and writes/watches `GuiService.SelectedObject`. Registered in Phone, Hud Shop,
  Leaderboard, Admin (unregister on destroy), Minigame and RaidOverlay; started in Main.client
  after all mounts. `navigation_spec` (17 cases) + `nav_wiring_spec` (7 cases); suite 1883;
  selene 0/0/0. Studio pass: 9/9 `GuiService.SelectedObject` checks passed (default on open for
  Leaderboard/Shop/Minigame, newest-open default, close-top falls back, close-all clears,
  close→reopen restores). Found and fixed a real close→reopen defect via this pass, mutation-checked.
  Evidence `docs/v2/evidence/h/2026-11-19-gamepad-nav/` (`REPORT.md`, `results.json`).
  **B/Escape key-press → actual close in Studio is `BLOCKED — Roblox Studio MCP input cannot produce
  a ContextActionService Begin event`** (only `UserInputService.InputBegan` and CAS `Cancel` are
  observable; `VirtualInputManager:SendKeyEvent` lacks capability RobloxScript). The CAS binding is
  pinned by `nav_wiring_spec` and the cancel policy by `navigation_spec`; needs a real keyboard/
  gamepad in a manual Studio session for the final input→Sink link. RaidOverlay decision recorded
  under "Decisions for designer".
- [x] 22. **Audio hygiene.** Every Sound is in a SoundGroup with a set volume, is cleaned up after
  play, and no loop leaks after a state change. Specs plus a Studio count of Sounds before and
  after a full beat-sheet run.
  Done 2026-11-19 (`SEEN-IN-STUDIO`): new pure `src/client/AudioPolicy.luau` (config audit,
  playable ids, per-role loop state, pooled one-shot invariant) + `src/client/Audio.luau` refactor
  that owns the Sound/SoundGroup/Tween objects, creates one grouped+volumed Sound per configured id
  at mount and never allocates again, and drives both looping roles through the policy. Fade tweens
  are cosmetic; each outgoing Stop is authoritative on `task.delay(FADE_SECONDS)`, guarded by a
  per-Sound token invalidated on replay. Two real defects found in validation and fixed: (1) a
  role-generation guard skipped `Stop()` on intermediate outgoing loops and left four ambience beds
  playing in Studio, (2) TweenService does not step at all under this Studio MCP environment
  (Part and Sound tween neither animate nor fire `Completed` while Heartbeat runs), so cleanup could
  not rely on a tween callback. `audio_policy_spec` (13) + `audio_wiring_spec` (12, fake audio
  services + static); suite 1908; selene 0/0/0; both guards mutation-checked. Studio census: 4
  groups / 17 Sounds / 0 ungrouped / 0 bad volumes both before and after a rapid 7-step `Cuaca`
  sequence at 0.12 s gaps, with exactly one music and one ambience loop playing after settle.
  No `MusicZone` parts exist (Track C world not built), so the identical path was driven via the
  real `Cuaca` signal; place not saved/published, no `profile:Save()`, returned to Edit. Evidence
  `docs/v2/evidence/h/2026-11-19-audio-hygiene/` (`REPORT.md`, `results.json`).
- [x] 23. **Lighting × FidelityTier per hub.** In Studio, force each tier in each of the six hubs
  and record the applied settings and instance counts. Check that no tier switch leaves an effect
  stuck on.
  Done 2026-11-19 (`SEEN-IN-STUDIO`): drove the **live** `FidelityRuntime` singleton (via a temporary
  injected LocalScript, because the Studio MCP `execute_luau` tool has a separate ModuleScript cache)
  through all 6 hubs × 3 tiers = 18 combinations, moving the character to each hub centre. Every row
  reported the forced tier via `get()` and the player `FidelityTier` attribute, with the settings
  advancing correctly (Rendah none/off/false/minimal, Sedang key/near/false/half, Tinggi
  all/on/true/full). Lighting descendant census was identical in all 18 rows and after a
  `Rendah→Tinggi→Rendah→Sedang→Tinggi→Rendah` cycle plus clear: 6 effects
  (Atmosphere, BloomEffect, ColorCorrectionEffect, ColorGradingEffect, Sky, SunRaysEffect),
  `DepthOfFieldEffect` count 0; hub-local light counts unchanged across tiers. No tier switch
  creates or destroys a Lighting effect, so none sticks. Finding (designer decision, not a defect):
  the four lighting-related tier settings are reported but have no consumer — Sky alone owns
  Lighting effects from seasons/weather; wiring tier→lighting is V0.4 / designer-blocked. No
  production code changed (verification-only). Place not saved/published, no `profile:Save()`,
  returned to Edit, probe instances destroyed. Evidence
  `docs/v2/evidence/h/2026-11-19-lighting-fidelity/` (`REPORT.md`, `results.json`).
- [x] 24. **Strict types.** Migrate the pure modules (`src/shared/Config/*`, `Feel/*` pure logic,
  `Testing/*` policy) to `--!strict` where it is clean. Fix the type errors and don't change
  behaviour.
  Done 2026-11-19 (`LUNE-ONLY`): added `--!strict` to all 24 `Config/*` modules, 6 pure `Feel/*`
  logic modules (`FidelityTier`, `TierScale`, `FpsSampler`, `CutsceneSequencer`, `CutsceneState`,
  `MomentGuard`) and both `Testing/*` policy modules (`Gate`, `RaidTrigger`) — 32 files. Left the
  engine-facing modules non-strict (`ActionFeel`, `CameraFeel`, `FidelityRuntime`, `PerfSwitches`,
  `Harness` — they touch game services/Instances at load). Fixed the 18 surfaced errors with
  annotation-only changes (type aliases for heterogeneous config rows, `::` casts for
  `table.remove` results, typed callback lists/maps) — all runtime-erased, no behaviour change.
  `luau-lsp analyze` (fresh gitignored sourcemap): 17 distinct errors before and after, i.e. zero
  introduced; the 17 are pre-existing in engine-facing files. `lune` 1908 passed, `selene` 0/0/0.
  Evidence `docs/v2/evidence/h/2026-11-19-strict-types/REPORT.md`.
- [x] 25. **Dead code and dead strings.** Remove unused modules, functions and `Strings` keys,
  and leave Rojo mappings for files that no longer exist out of `default.project.json`. Prove it
  with specs and a clean Studio play. Removed 22 dead `Strings` keys and 5 dead functions; no dead
  modules or stale Rojo mappings existed. Spec `tests/specs/dead_code_spec.luau` proves removal and
  the no-dead-key invariant. `SEEN-IN-STUDIO` (clean Edit→Play→Edit, no game-code errors).
  `lune` 1927 passed, `selene` 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-dead-code/REPORT.md`.
- [x] 26. **Test-suite health.** Run the suite 3 times and fix any flaky spec. Add per-spec timing
  output and speed up anything over 2 s. Three baseline runs identical at 1927 passed — no flaky
  spec. Added per-case/suite/total timing to `tests/lib/Test.luau` and a per-spec report to
  `tests/run.luau` (`--timing` for the full table), plus 3 characterization cases in
  `tests/specs/harness_timing_spec.luau`. Root-caused the slow path to `Env.new()` re-walking `src/`
  on every construction (48× in one case); memoized the static directory listing and module source
  in `tests/lib/Env.luau`: suite **31.7 s → 4.8 s (~6.6×)**, slowest case 1.236 s → 0.213 s, nothing
  over 2 s. `LUNE-ONLY`, `lune` 1930 passed, `selene src` 0/0/0. Evidence
  `docs/v2/evidence/h/2026-11-19-suite-health/REPORT.md`.
- [x] 27. **CI.** If none exists, add a GitHub Actions workflow that runs `lune run
  tests/run.luau` and `selene src` on push to `track/*` and `main`, pinned via rokit or aftman.
  Workflow already existed; scoped push to `main`/`track/*`, added the missing `selene src` step
  and made the lune invocation explicit. Tools pinned via `rokit.toml` (`setup-rokit` installs all
  of them). Local verification: `lune` 1930 passed, `selene src` 0/0/0, YAML parsed. Remote Actions
  run `UNVERIFIED` locally until GitHub executes it. `LUNE-ONLY`. Evidence
  `docs/v2/evidence/h/2026-11-19-ci/REPORT.md`.
- [x] 28. **Docs refresh.** Bring `TECH.md` (new modules: FidelityTier, CutsceneSequencer,
  LazyPages, RaidTrigger, FpsSampler, SaveSanitize), `HARNESS.md` (new hooks) and the
  `docs/README.md` map up to date. Regenerate the `BALANCE.md` and `LOCALIZATION.md` snapshots
  from the current code and date them. `TECH.md`: current commands/1930 count, new specs table,
  new §12 documenting all six modules + harness hooks; §11 cutscene gap updated. `HARNESS.md`:
  `raid`/`raidState` hooks. `README.md` map snapshot date → 2026-11-19. `BALANCE.md`: 3 ranks,
  12 crops, 5 tiers (~1.51×), real pinjol/law/market values from `Config/*.luau`. `LOCALIZATION.md`:
  333 keys (0 empty id/en), correct spec names, dated. `LUNE-ONLY`, `lune` 1930 passed,
  `selene src` 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-docs-refresh/REPORT.md`.
- [x] 29. **Regression replay after all changes.** On synced code in Studio, redo the G3
  beat sheet, the G5 timings (3 runs), a full-session `output.log` for Q2, and a 30-minute Q5
  soak with the memory series. All must still pass. File every regression as a bug and fix it.
  Done 2026-11-19 (`SEEN-IN-STUDIO`, HEAD `350c48f`, placeId 132087524375529, fresh VERIFY-TEMP
  Mock profile reverted before commit): G3 all 9 steps `ok=true`, cash 50→77→57→157, tutorialStep
  1→5, matches baseline; forced raid `raid{viral,force}` → `incoming`/`inRaid`/`busy`, no stuck
  state (items 21/22/23 paths); Q2 full-session Output zero game-code errors/warnings, BUG-003 did
  not recur; G5 three fresh runs first harvest 20/20/20 s (<45 s), Super reveal 48 s (<5 min),
  real grow timers, no `ready` shortcut; Q5 client-half soak 1801.71 s / 234 cycles / `done=true`,
  client memory 2617.57→2586.09 MB (235 samples, flat), server 2617.5→2587.3 MB, no leak/stuck/
  desync, graceful seed-starved refusals same class as baseline, raid gossip 310 s (<420 s). No
  regression found, no bug filed. Evidence `docs/v2/evidence/h/2026-11-19-regression-replay/`
  (`REPORT.md`, `results.json`, `soak.json`, `g3-g5-q2-output.log`, `soak-output.log`). Q5 ten-player
  half stays `BLOCKED` (no multi-client tool). `lune` 1930 passed, `selene` 0/0/0.
- [x] 30. **Gate 1 status sheet.** Rewrite the evidence column of every GATE1.md row so it is
  current, and list exactly what the designer must do to close each row that is still open.
  Done 2026-11-19 (`LUNE-ONLY`): all 16 GATE1.md rows reworked. Every evidence column refreshed to
  cite what exists today — Q2/Q3 gained post-change regression-replay proof
  (`h/2026-11-19-regression-replay/`), G3/G5 gained a second desktop-half confirmation, G4b gained
  the item-19/20 desktop + `LUNE-ONLY` proof, Q8 updated to 1930 passing and all bug specs; statuses
  unchanged (3 `SEEN-IN-STUDIO`, 4 `BLOCKED`, 1 `LUNE-ONLY`, 8 `UNVERIFIED`). Added a new
  "Designer actions to close the open rows" table giving the exact action + evidence path for each
  of the 11 open rows (G2/Q1, G3, G4, G4b, G5, G6, G7, Q5, Q6, Q7, G1-composite). Verified every
  cited evidence directory, spec file and the D-G4 citation exist. `lune` 1930 passed,
  `selene src` 0/0/0.
- [x] 31. **Refill (round 1).** Read every `[ ]` and `[~]` item in `MASTER_PLAN.md`, `GATE1.md` and
  `BUGS.md`. Append each one an agent can do without the designer here, plus a second
  bug-hunt-by-reading round over files changed since item 10, and continue. Repeat the refill
  until a full round adds nothing.
  Done 2026-11-19: scanned all 24 `[ ]`/`[~]` checkboxes (all in MASTER_PLAN.md — GATE1.md and
  BUGS.md use status words, no checkboxes). Second bug-hunt-by-reading over all 53 `src/` files
  changed since item 10 (`de8e5e1..HEAD`) found **no new concrete defects**: every diff is a strict
  annotation, a dead-code removal, or an already-specced BUG-016/017/011/005/012 fix. Subagent
  transport failed `ECONNREFUSED`, so the hunt ran directly in the main session. Key finding overturns
  a stale block: `StudioDeviceSimulatorService:SetDeviceAsync("iphone_14")` in `execute_luau` yields
  a real 749×389 viewport, harness `enable`/`status` replies there (`lastOk=true`), and
  `screen_capture` works — so the "no device emulation" reason that kept the G3/G5 phone halves
  `BLOCKED` is false (item 19 already used `SetDeviceAsync` at 749×388). Those halves are
  agent-doable and are appended as items 32/33. Q5 ten-player half stays `BLOCKED` — no
  team-test/local-server/multi-client tool exists (re-confirmed against the tool catalog). Rows
  still needing the designer: G4 (tracks C/G/E art), G4b (visual text pass), G6 (real-device fps),
  G7 (five humans), Q6 (published place), Q7 (real-device touch). `lune` 1930 passed,
  `selene` 0/0/0.
- [x] 32. **G3 beat sheet at phone size.** With the Studio device sim set to `iphone_14`
  (`SetDeviceAsync("iphone_14")`, real viewport 749×389) in Play Solo, run the harness through the
  full nine-step §4 beat sheet (plant/ready/harvest/sell/buy) as in item 29. Save the phone-size
  `output.log` via `get_console_output` plus a `REPORT.md` and `results.json` under
  `docs/v2/evidence/h/2026-11-19-g3-phone/`, recording the viewport, per-step `ok`, cash/produce
  deltas and zero game-code errors/warnings. Then update the GATE1.md G3 row and MASTER_PLAN G3
  checkbox to mark the phone half `SEEN-IN-STUDIO` (criterion fully closed). Do not save the place
  or call `profile:Save()`.
  Done 2026-11-19 (`SEEN-IN-STUDIO`, HEAD `76d8d4e`): fresh profile via VERIFY-TEMP Mock reverted
  before commit; device set in **Edit before Play** (setting it during Play left a 1×1 viewport).
  Real viewport 749×389, inset 0,58. All nine §4 steps `ok=true`, 9 commands → 9 replies, cash
  50→77→57→157, padi 5→4→6, tutorialStep 1→5, sack 1 at harvest — matches desktop baseline.
  Commands spaced ≥300 ms (harness rate limit 4/s; a back-to-back first attempt had harvest
  rate-limited and sell fail "sack is empty"); first-new reply read to avoid stale-reply race.
  Output: zero game-code errors/warnings, only external Assistant-plugin/BUG-003/AnalyticsService
  noise. Evidence `docs/v2/evidence/h/2026-11-19-g3-phone/` (`REPORT.md`, `results.json`,
  `output.log`). GATE1.md G3 row + designer-actions row and MASTER_PLAN G3 checkbox marked closed;
  counts updated to 4 `SEEN-IN-STUDIO` / 3 `BLOCKED`. `lune` 1930 passed, `selene` 0/0/0.
- [x] 33. **G5 timings at phone size (3 fresh runs).** At the `iphone_14` viewport (749×389), run
  three fresh-profile first sessions via the VERIFY-TEMP Mock store in `PlayerData.luau` (revert the
  line before commit), real grow timers, no `ready` shortcut. Record first-harvest (<45 s), first
  rarity reveal (<5 min) and raid-witnessed (<7 min) timestamps from the harness replies. Save
  `REPORT.md` + `results.json` under `docs/v2/evidence/h/2026-11-19-g5-phone/`, then update the
  GATE1.md G5 row and MASTER_PLAN G5 checkbox to mark the phone half `SEEN-IN-STUDIO` (criterion
  closed). Do not save the place or publish.
  Done 2026-11-19 (`SEEN-IN-STUDIO`, HEAD `db34e01`): device set in Edit before Play (749×389),
  fresh profile via VERIFY-TEMP Mock reverted before commit; every run restarted Play. Timings stamped
  to Output via `print("[G5P] ... wall=...")`, no `ready` shortcut, commands paced ≥300 ms.
  First harvest 22/20/21 s (<45 s) across 3 runs; first Bagus reveal at harvest ~20–22 s and Super
  second harvest 70 s from t0 / 48 s from plant (<5 min); raid gossip `scripted_raid_gossip` at
  11:23:26, 315 s from t0 (<7 min), matching `scriptedRaidDelay=330` s. Zero game-code errors/warnings
  (only external Assistant-plugin/BUG-003/AnalyticsService noise). Evidence
  `docs/v2/evidence/h/2026-11-19-g5-phone/` (`REPORT.md`, `results.json`, `output.log`). GATE1.md G5
  row + designer-actions row and MASTER_PLAN G5 checkbox marked closed; counts now 5
  `SEEN-IN-STUDIO` / 2 `BLOCKED`. Tier guarantee stays `LUNE-ONLY`. `lune` 1930 passed,
  `selene` 0/0/0.
- [x] 34. **Refill (round 2).** Re-scan every `[ ]`/`[~]` item in `MASTER_PLAN.md`, `GATE1.md` and
  `BUGS.md` after items 32/33. Append anything still agent-doable plus a third bug-hunt-by-reading
  round over files changed since item 10. If a full round adds nothing, tick this and stop the
  refill loop without appending another.
  Done 2026-11-19 (**full round added nothing** — refill loop closed). Scanned all 21 remaining
  `[ ]`/`[~]` checkboxes (all in MASTER_PLAN.md; GATE1.md/BUGS.md use status words, no checkboxes):
  every one needs the designer, a physical device / real touch / multiple human clients / art / a
  published place / a human look judgement — none agent-doable. Third bug-hunt-by-reading over the
  53 `src/` files changed since item 10 (`de8e5e1..HEAD`): verified items 32/33 touched **zero**
  source files, so the source set is byte-identical to round 2; reviewed all 568 substantive
  +/- code lines (strict `::` casts/type aliases, dead-code removals, or already-specced fixes —
  BUG-014/015/016/017, items 21/22 NavBridge+AudioPolicy, NpcWalk extraction, text-size and
  GuiService-inset UI-fit tweaks, RaidTrigger cooldown typing) and found **no new concrete defect**.
  No new item appended. With G3/G5 phone halves now closed, all remaining open GATE1 rows are
  designer-only (G4 art, G4b visual text, G6 real-device fps, G7 five humans, Q5 ten-player,
  Q6 published place, Q7 real touch, G1 composite). `lune` 1930 passed, `selene` 0/0/0.

## Decisions for designer

Choices the agent made with a safe, reversible default. The designer confirms or overrides them.

- Item 5 — keep the `Greybox.build()` fallback enabled until the designer builds and saves the real
  village into `JuraganDesa.rbxl` (Track C). The code path is proven Greybox-independent, but the
  current place has no designer world, so disabling the fallback now would leave an empty world.
  Reversible: flip the fallback once the designer place ships.
- Item 9 — two look-dev candidates are prepared behind an OFF-by-default, Studio-only toggle; both
  are "candidate, awaiting designer yes" and neither is approved or applied in normal play. Safest
  reversible default: ship both as opt-in, let the designer view each with the command-bar toggle
  (`require(game.ReplicatedStorage.Shared.LookDev):enable("plaza_lighting")` /
  `:enable("police_walkin")`), then confirm, override or discard each. Both restored with
  `:disable()`. The item stays unticked until the designer chooses. Evidence
  `docs/v2/evidence/h/2026-11-19-lookdev-candidates/`.
- Item 17 — `ANALYTICS.md` §2 lists `first_harvest` as an "(example `once`)" activation event, but
  no gameplay service calls it (only `analytics_spec` uses the name as a sample). Safest reversible
  default: do **not** invent a call site; leave it documented as an example and let the designer
  decide whether to wire `Analytics.once(player, "first_harvest", 1)` after the first successful
  harvest in `FarmService`. Related, no action taken: `ShopPurchase` is intentionally unwired in
  M4 (§4), and `FirstSession` emits an extra undocumented `first_session` funnel (steps 5/7/8/9)
  that the designer may want added to `ANALYTICS.md` §4 or retired. Evidence
  `docs/v2/evidence/h/2026-11-19-analytics-audit/REPORT.md`.
- Item 20 — the touch-target audit uses the repo's own `PhoneLayout.meetsTouch` contract (a 44 px
  axis), matching `phone_layout_spec`, not a new "44×44 on both axes" rule. Safest reversible
  default: the wide, short Admin/HUD/Leaderboard buttons already pass on their width/scale axis,
  and forcing them to 44 px tall would overflow the fixed 690 px AdminPanel and regress the fit
  proved in item 19. If the designer wants strict 44×44, that is a follow-up with a taller panel
  and a re-fit at 749×388. No button failed the audit; only two sub-11 text constraints were fixed.
- Item 21 — RaidOverlay is registered with `closable = false`: it is a forced timed choice with its
  own Skip rule (Skip only becomes available once the cutscene is skippable), so B/Escape must never
  dismiss it. Safest reversible default: keep it non-dismissable but give it a phase-driven default
  selection (Skip while incoming, Fine/Amplop while choosing) with explicit `NavBridge.rescue()`
  on phase changes so selection never sits on a hidden button. Reversible by flipping `closable`
  if the designer wants Escape to abort a raid. Evidence
  `docs/v2/evidence/h/2026-11-19-gamepad-nav/REPORT.md`.
- Item 23 — the four lighting-related fidelity settings (`localLights`, `smallPartShadows`,
  `cameraDoF`, `ambientLife`) are declared in `FidelityTier.SETTINGS`, returned by
  `FidelityRuntime.settings()` and mirrored to the player attribute, but no consumer applies them:
  `Sky.luau` alone owns Lighting post effects and is driven by seasons/weather, not tier. Studio
  proved `cameraDoF = true` on Tinggi creates no `DepthOfFieldEffect` and no hub-local light count
  changes across tiers. Safest reversible default: leave them unwired — tier→lighting is a look
  decision and VISUAL_MASTER_PLAN V0.4 is still designer-blocked; adding an applier now could fight
  Sky's season tweens. Reversible: wire a tier→lighting applier once the designer picks per-tier
  values and approves the look. No production code changed. Evidence
  `docs/v2/evidence/h/2026-11-19-lighting-fidelity/REPORT.md`.
- Item 25 — during dead-code removal, four definition-only symbols were kept rather than deleted
  because they may serve the designer or verification: `NavBridge.debugState` (read-only Studio
  verification hook), `PlotService.getNeighbors` (documented in `MAP_SPEC.md`) and `Theme.sticker`
  (public helper with a live internal `addSticker`) were kept; `Audio.configured` was kept as a
  borderline Config API. Safest reversible default: keep anything with a plausible external/designer
  consumer; each can be removed in a later pass if the designer confirms it is unneeded. Evidence
  `docs/v2/evidence/h/2026-11-19-dead-code/REPORT.md`.

## Blocked on designer

- Item 9 final visual approval — both look-dev candidates ("plaza_lighting" and "police_walkin")
  are `BLOCKED` on the designer's yes; they are opt-in only and the checkbox stays open.
- Phone-size (iPhone 14) replays: G3 and G5 are now closed `SEEN-IN-STUDIO` (items 32/33, real
  749×389 viewport); still open — G4b visual text pass, BUG-008/009 phone screenshots, fps for G6.
- Q5 live multi-client run (Studio Test tab, Local Server).
- G7 five real players, Q6 published-place persistence, Q7 real-device touch.
- Final art: icons, textures and sounds (G4, track G).
