# Work queue — round 2 (long-run mode)

The agent works this list top to bottom without stopping (see `AGENTS.md`, "Long-run mode").
Round 1 is archived in `WORK_QUEUE_ROUND1.md`.

- Tick an item in the same commit as its work.
- If an item is blocked on the designer, mark it `BLOCKED — <reason>` and move on.
- Add new agent-doable items before the refill item.

Started 2026-11-19 from `a618f02`: 1929 tests pass, selene is clean, and CI is fixed (the
`Packages/` mapping spec now skips gitignored generated dirs).

**Art rule for this round.** Everything the agent makes (icons, textures, models, sounds, props)
is a candidate: shipped behind the existing `LookDev` opt-in, off by default, recorded in
`docs/v2/visual/CANDIDATES.md` with a render or screenshot, and never ticked as approved. Only the
designer says yes. Uploads follow `TOOLS.md`:
- flat images and audio go through Open Cloud (`ROBLOX_API_KEY`, never printed);
- meshes go through Studio (the Importer, or the Studio MCP mesh tools).

Every resulting ID goes into `ASSET_MANIFEST.md` the moment it exists. Never invent an ID, and
never publish.

## Queue

### A. Fix what round 1 got wrong

- [ ] 1. **Prove the phone emulation or downgrade it.**
  - Why: the G3 and G5 phone halves were closed at a 749×389 viewport, but that is aspect 1.93.
    iPhone 14 is 2.16 in landscape and 0.46 in portrait, and the Studio pane alone gives 749×388,
    so the device sim may never have applied.
  - Prove it applied: compare `Camera.ViewportSize`, `UserInputService.TouchEnabled`, the
    `GuiService` insets and the `screen_capture` size against a desktop baseline.
  - Try portrait and one more device (a small Android).
  - If it can't be proven, downgrade G3 and G5 phone to `UNVERIFIED` in `GATE1.md` and
    `MASTER_PLAN.md`, and say why in the evidence.
- [ ] 2. **CI green.** After the push, read the GitHub Actions run (`gh run list` / `gh run view`)
  and fix it until it passes. Update the deprecated Node 20 action only to a version you confirm
  exists.
- [ ] 3. **Re-audit round-1 `SEEN-IN-STUDIO` claims.**
  - Every evidence file must name a Rojo-synced build and its method.
  - Downgrade any claim based on hand-injected or stale sources, or on structure alone where the
    row needs behaviour.
  - Record the audit in `docs/testing/CODE_AUDIT.md`.

### B. G4 art candidates (opt-in, designer yes required)

- [ ] 4. **Icon set.**
  - Make every `IconMap.luau` slot (crops, tools, tiers, currency, phone apps) in the
    `ICONS.md` style.
  - Keep the sources under `docs/v2/visual/art/icons/src/` and render to PNG at the size
    `ICONS.md` asks for.
  - Upload through Open Cloud, record the IDs, then wire them into `IconMap` behind a
    `LookDev` candidate flag. Letters stay the default.
- [ ] 5. **Hero textures (6–8)** per `TEXTURES.md`: tileable, uploaded and recorded. Apply them in
  a `LookDev` material preset.
- [ ] 6. **Caricature NPC models** from `npcs.md` and `NpcArchetypes` (Pak RT, Tengkulak, Polisi,
  debt collector).
  - Build them in Blender (subagents have `blender`) or with the Studio MCP mesh tools, at R15
    scale, as rigid meshes or a simple rig.
  - Import through Studio and swap them for the box NPCs behind `LookDev`.
- [ ] 7. **Crop growth-stage models** (bibit / tumbuh / siap) for every crop in config, low-poly,
  behind `LookDev`.
- [ ] 8. **Hub props**: warung counter, pasar stall, pos polisi desk, Pak RT table, lanterns and
  signs. Use procedural parts with textured materials, or meshes. Keep within the per-hub
  instance budget.
- [ ] 9. **Sound candidates.**
  - For each action in the audio event list, search the Creator Store (Studio MCP `search_asset`)
    for free sounds whose licence allows use.
  - Record each existing ID, its licence and its source in `ASSET_MANIFEST.md`.
  - Wire them behind `LookDev` through SoundGroups, following the round-1 audio policy.
- [ ] 10. **Candidate gallery.** `docs/v2/visual/CANDIDATES.md` gets one row per candidate: a
  render or screenshot, the toggle to view it, its cost (instances and fps), and a yes/no column
  for the designer.

### C. Performance with candidates on

- [ ] 11. **Budget check.** Count instances, parts and triangles per hub with all candidates on
  and off, at each FidelityTier. Rendah must stay within budget; trim the candidates if it
  doesn't.
- [ ] 12. **30-minute soak with all candidates on**: memory series, connection count, no growth.
- [ ] 13. **StreamingEnabled readiness audit.** Find client paths that assume parts exist
  (`WaitForChild` without a timeout, direct indexing). Fix them with specs. Don't flip the
  setting; propose it under "Decisions for designer".

### D. Hardening, round 2

- [ ] 14. **Mutation testing.** For 25 key service functions (economy, inventory, raid, debt,
  receipts, save), inject one fault each: flip a comparison or drop a guard. Confirm that a spec
  fails each time, and add a spec wherever none does. Revert every fault.
- [ ] 15. **Remote fuzzing.** A Lune spec feeds every remote handler random payloads: wrong types,
  NaN and inf, huge strings, deep or cyclic tables, nil. No error may escape and no state may
  change.
- [ ] 16. **Save fuzzing.** Run 1000 random damaged save tables through migrate and SaveSanitize.
  Invariants: finite non-negative counts, known keys kept, no throw.
- [ ] 17. **Long economy sim.** One player, 8 hours of sim time, optimal and idle strategies.
  Check for overflow, runaway cash and dead ends. Write a report for the designer; balance
  changes go only under "Decisions for designer".
- [ ] 18. **Client error boundary.** One failing UI or feel module must not kill
  `Main.client.luau`: wrap each mount, log once, keep the others running. Spec it with a module
  that is forced to throw.
- [ ] 19. **Bug hunt by reading, round 3.** Read every `src/` file changed in round 1
  (`8f965dc..a618f02`, 68 files) line by line. File and fix with specs.
- [ ] 20. **Type pass, round 2.** Run luau-lsp analyze, if rokit has it, over `src/`. Fix the real
  errors and move more pure modules to `--!strict` without changing behaviour.

### E. Get the designer through Gate 1 fast (docs and scripts only)

- [ ] 21. **`docs/testing/DESIGNER_GATE1.md`.** One page, one numbered checklist per open row
  (G4b, G6, G7, Q5, Q6, Q7): exact clicks, what to look at, and where to drop the evidence. Keep
  it short and in plain words.
- [ ] 22. **Q5 multi-client script.** A gated harness script that, once the designer starts Local
  Server with N players, runs the §2–§4 loop on every client, collects desync and stuck-state
  checks, and writes one results table. Lune-test the parts that can be tested.
- [ ] 23. **Q6 published-place plan.** Exact steps for a private test place, plus a gated
  save/leave/rejoin compare script for the designer to run.
- [ ] 24. **Indonesian text review.** Read every `id` string for natural, non-translated-sounding
  Indonesian, in the `humanizer-indonesia` style. Put the proposed edits in a table under
  "Decisions for designer" and don't change `Strings.luau`.
- [ ] 25. **Post-Gate-1 backlog.** Break the v2.1 features in `PLAN.md` into ready tickets, each
  with specs-first acceptance tests and the files it touches. This is docs only; no feature code
  before Gate 1.
- [ ] 26. **`LAUNCH.md` refresh** from the current build: store copy draft, rating questionnaire
  answers and checklist status. Mark it as a draft.

### F. Close the round

- [ ] 27. **Regression replay** on synced code: G3 beat sheet, G5 three runs, full-session
  `output.log`, and a 30-minute soak, with candidates off (shipping state) and then on.
- [ ] 28. **Gate 1 status sheet refresh** in `GATE1.md` and the tracker.
- [ ] 29. **Refill.** Read every `[ ]` and `[~]` item in `MASTER_PLAN.md`, `GATE1.md`, `BUGS.md`,
  `VISUAL_MASTER_PLAN.md` and `CANDIDATES.md`. Append each one an agent can do here, plus another
  bug hunt over files changed in this round, and continue. Repeat until a full round adds
  nothing.

## Decisions for designer

- (none yet)

## Blocked on designer

- Yes or no on every candidate in `CANDIDATES.md`, and on the round-1 `plaza_lighting` and
  `police_walkin` candidates.
- G6 real-device fps, G7 five players, Q5 live multi-client run, Q6 published place, Q7
  real-device touch.
