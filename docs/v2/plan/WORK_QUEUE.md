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
- [ ] 4. **Studio checks of `LUNE-ONLY` items.** Turn each into `SEEN-IN-STUDIO` with evidence:
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
- [ ] 5. **Retire `Greybox.luau` to a test-only fallback.** Prove the live world doesn't depend on
  it: specs pass, and a Studio play shows the same hubs with no Output errors.
- [ ] 6. **Performance pass.** Count instances per hub, find connection leaks (Heartbeat and
  RenderStepped handlers with no cleanup) and per-frame allocations in hot paths. Fix them and
  record before/after numbers.
- [ ] 7. **Localization pass.** All player text goes through `Strings.luau` with `id` and `en`;
  nothing is hardcoded in the UI. Extend `strings_integrity_spec` to catch stragglers.
- [ ] 8. **Code health.** Split modules over ~600 lines where the split is clean, and clear the 4
  selene warnings where safe. Lock behaviour with specs before refactoring.
- [ ] 9. **Look-dev candidates for designer review.** Behind an opt-in toggle that is off by
  default. No asset IDs: procedural parts and Roblox textured materials only, in the
  cartoonish-realism style. Two candidates:
  - an alternative material and lighting preset for the plaza hub;
  - a police NPC walk-in prototype that uses the existing police model and pathing, timed to the
    walkin shot.
  Record each as "candidate, awaiting designer yes". Never tick these as done.
- [ ] 10. **Bug hunt by reading.** Go through `src/server` one folder at a time, then `src/client`,
  reading every line. Log each defect in `BUGS.md` with a severity, then fix it with a regression
  spec. Bugs found here outrank the items below.
- [ ] 11. **Spec coverage gaps.** List each service and client controller that has no failure-path
  spec (nil player, a player who left, damaged data, a missing remote) and write one for each.
- [ ] 12. **Player leaves mid-state.** For every state a player can be in (each raid state, debt
  collector, minigame, phone open, cutscene, selling), check that the server cleans up on
  PlayerRemoving: no orphan tasks, NPCs, attributes or locks. Specs first, then a Studio check.
- [ ] 13. **Respawn and rejoin.** Audit CharacterAdded and respawn handlers for duplicate
  connections, and check that UI is rebuilt correctly after a reset. Specs, plus a Studio reset
  loop of 10 resets with no growth in connection count.
- [ ] 14. **Purchases.** Check receipt handling (no product IDs invented): a duplicate
  PurchaseId, the player leaving mid-grant, a failed save after grant, unknown products, game pass
  checks that error. Each case gets a spec that proves idempotency.
- [ ] 15. **Cross-server and leaderboard failures.** Cover OrderedDataStore, MessagingService and
  MemoryStore errors with backoff and last-good fallback, plus budget-limit handling. Specs.
- [ ] 16. **Admin and season tools.** Every admin command validates who calls it and what it
  receives; non-admins are refused; no admin path can grant unbounded cash or items. Specs.
- [ ] 17. **Analytics audit against `ANALYTICS.md`.** Every documented event fires from the right
  trigger, funnel steps are in order and fire once, and payloads have bounded size. Spec each
  event; list any missing event in "Decisions for designer".
- [ ] 18. **NPC pathing robustness.** Police and debt-collector walk-to-plot for every plot: add
  stuck detection, a timeout and a teleport fallback. Specs, plus a Studio run to each plot.
- [ ] 19. **UI fit at 749×388.** For every screen and app page, probe AbsolutePosition and
  AbsoluteSize in Studio. Nothing may be off-screen or overlap the safe-area insets. Fix by
  layout, not by shrinking text below the minimum.
- [ ] 20. **Touch target and text size audit.** A spec walks every UI builder: buttons at least
  44×44 and text at the minimum size or above. Fix the stragglers.
- [ ] 21. **Gamepad and keyboard.** Every screen can be closed with B or Escape, selection never
  gets stuck in a hidden frame, and there is a default selection on open. Specs where the logic
  is pure, plus a Studio pass with `GuiService.SelectedObject`.
- [ ] 22. **Audio hygiene.** Every Sound is in a SoundGroup with a set volume, is cleaned up after
  play, and no loop leaks after a state change. Specs plus a Studio count of Sounds before and
  after a full beat-sheet run.
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

- (none yet)

## Blocked on designer

- Phone-size (iPhone 14) replays: G3, G5, G4b, BUG-008/009; fps for G6.
- Q5 live multi-client run (Studio Test tab, Local Server).
- G7 five real players, Q6 published-place persistence, Q7 real-device touch.
- Final art: icons, textures and sounds (G4, track G).
