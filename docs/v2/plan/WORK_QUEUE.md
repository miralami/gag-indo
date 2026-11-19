# Work queue — long-run mode

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
- [ ] 9. **Look-dev candidates for designer review.** Behind an opt-in toggle that is off by
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
- [ ] 23. **Lighting × FidelityTier per hub.** In Studio, force each tier in each of the six hubs
  and record the applied settings and instance counts. Check that no tier switch leaves an effect
  stuck on.
- [ ] 24. **Strict types.** Migrate the pure modules (`src/shared/Config/*`, `Feel/*` pure logic,
  `Testing/*` policy) to `--!strict` where it is clean. Fix the type errors and don't change
  behaviour.
- [ ] 25. **Dead code and dead strings.** Remove unused modules, functions and `Strings` keys,
  and leave Rojo mappings for files that no longer exist out of `default.project.json`. Prove it
  with specs and a clean Studio play.
- [ ] 26. **Test-suite health.** Run the suite 3 times and fix any flaky spec. Add per-spec timing
  output and speed up anything over 2 s.
- [ ] 27. **CI.** If none exists, add a GitHub Actions workflow that runs `lune run
  tests/run.luau` and `selene src` on push to `track/*` and `main`, pinned via rokit or aftman.
- [ ] 28. **Docs refresh.** Bring `TECH.md` (new modules: FidelityTier, CutsceneSequencer,
  LazyPages, RaidTrigger, FpsSampler, SaveSanitize), `HARNESS.md` (new hooks) and the
  `docs/README.md` map up to date. Regenerate the `BALANCE.md` and `LOCALIZATION.md` snapshots
  from the current code and date them.
- [ ] 29. **Regression replay after all changes.** On synced code in Studio, redo the G3
  beat sheet, the G5 timings (3 runs), a full-session `output.log` for Q2, and a 30-minute Q5
  soak with the memory series. All must still pass. File every regression as a bug and fix it.
- [ ] 30. **Gate 1 status sheet.** Rewrite the evidence column of every GATE1.md row so it is
  current, and list exactly what the designer must do to close each row that is still open.
- [ ] 31. **Refill.** Read every `[ ]` and `[~]` item in `MASTER_PLAN.md`, `GATE1.md` and
  `BUGS.md`. Append each one an agent can do without the designer here, plus a second
  bug-hunt-by-reading round over files changed since item 10, and continue. Repeat the refill
  until a full round adds nothing.

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

## Blocked on designer

- Item 9 final visual approval — both look-dev candidates ("plaza_lighting" and "police_walkin")
  are `BLOCKED` on the designer's yes; they are opt-in only and the checkbox stays open.
- Phone-size (iPhone 14) replays: G3, G5, G4b, BUG-008/009; fps for G6.
- Q5 live multi-client run (Studio Test tab, Local Server).
- G7 five real players, Q6 published-place persistence, Q7 real-device touch.
- Final art: icons, textures and sounds (G4, track G).
