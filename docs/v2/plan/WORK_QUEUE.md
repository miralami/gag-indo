# Work queue — long-run mode

The agent works this list top to bottom without stopping (see `AGENTS.md` "Long-run mode").
Tick an item in the same commit as its work. If an item is blocked on the designer, mark it
`BLOCKED — <reason>` and move to the next one. Add new agent-doable items at the bottom.

Started 2026-11-19 from `f6941be` (1700 tests passing).

## Queue

- [ ] 1. **Q5 ten-player half, Lune side.** Multi-player simulation spec: 10 fake players run
  plant/harvest/sell/buy/raid/debt at the same time, interleaved, on the real services with
  Fakes. Assert no shared-state leak between players, no stuck raid or minigame state, no
  negative or NaN cash, no duplicated items. Fix each bug found and add a regression spec.
  Status `LUNE-ONLY`; the live multi-client half stays `BLOCKED` on the designer.
- [ ] 2. **Security pass.** Check every RemoteEvent/RemoteFunction handler in `src/server` for
  argument type and range validation, rate limits, and server authority over cash and items.
  Write a failure-path spec for each exploit vector, then fix it. Record results in
  `docs/testing/CODE_AUDIT.md`.
- [ ] 3. **Data pass.** Check ProfileStore session locking, the migrate → SaveSanitize order, and
  DataStore errors at load and at save. Specs for each failure path, then fixes.
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
- [ ] 10. **Refill.** Read every `[ ]` and `[~]` item in `MASTER_PLAN.md`. Append each one an
  agent can do without the designer here, and continue.

## Decisions for designer

Choices the agent made with a safe, reversible default. The designer confirms or overrides them.

- (none yet)

## Blocked on designer

- Phone-size (iPhone 14) replays: G3, G5, G4b, BUG-008/009; fps for G6.
- Q5 live multi-client run (Studio Test tab, Local Server).
- G7 five real players, Q6 published-place persistence, Q7 real-device touch.
- Final art: icons, textures and sounds (G4, track G).
