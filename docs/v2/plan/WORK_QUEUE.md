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

- [x] 1. **Prove the phone emulation or downgrade it.** `SEEN-IN-STUDIO` — proven active; no
  downgrade. Desktop 1365x768/touch=false vs iPhone 14 749x389/touch=true vs Galaxy A06
  705x338/touch=true, portrait 388x761 during Play; `Game.StarterGui.ScreenOrientation` is
  LandscapeSensor. Evidence `docs/v2/evidence/h/2026-11-19-phone-emulation/`.
  - Why: the G3 and G5 phone halves were closed at a 749×389 viewport, but that is aspect 1.93.
    iPhone 14 is 2.16 in landscape and 0.46 in portrait, and the Studio pane alone gives 749×388,
    so the device sim may never have applied.
  - Prove it applied: compare `Camera.ViewportSize`, `UserInputService.TouchEnabled`, the
    `GuiService` insets and the `screen_capture` size against a desktop baseline.
  - Try portrait and one more device (a small Android).
  - If it can't be proven, downgrade G3 and G5 phone to `UNVERIFIED` in `GATE1.md` and
    `MASTER_PLAN.md`, and say why in the evidence.
- [x] 2. **CI green.** `SEEN-IN-STUDIO` — `gh run list` shows prior failure `44458499132` was the
  Packages mapping-spec test, fixed by `47c0802`; runs `44472087680` and `44473085751` are success.
  Bumped `actions/checkout@v4`→`@v5` (confirmed on Node 24 via its action.yml) to clear the Node 20
  deprecation warning. YAML parses; `lune` 1929 / `selene` 0/0/0. Evidence
  `docs/v2/evidence/h/2026-11-19-ci-round2/`.
- [x] 3. **Re-audit round-1 `SEEN-IN-STUDIO` claims.** Audited all 48 evidence `REPORT.md` + the
  five `SEEN-IN-STUDIO` gate rows (G3/G5/Q2/Q3/Q4). No downgrade: each has a Rojo-synced report
  with a behaviour method; the one hand-injected pass (`gate1-studio`) was already superseded by
  `gate1-sweep`, its two bad observations recorded non-reproduced. 15 older reports name build +
  method but omit the literal Rojo marker — wording gap only, all backed by newer synced re-runs.
  Recorded in `docs/testing/CODE_AUDIT.md`.

### B. G4 art candidates (opt-in, designer yes required)

- [x] 4. **Icon set.** `SEEN-IN-STUDIO` — 27 agent-made 256x256 transparent icons (12 crops, 5
  tiers, 2 currency, 8 phone apps) generated deterministically by
  `docs/v2/visual/art/icons/src/generate_icons.py` with contact sheet, uploaded via Studio MCP
  Open Cloud (`assetType=Image`, all `moderationState=Approved`, real IDs recorded immediately in
  `ASSET_MANIFEST.md`), and wired behind an off-by-default `icons` LookDev candidate. `IconMap`
  entry `id` stays 0 so letters are the default; IDs live in `IconMap.candidateIds`. Live Edit-VM
  round-trip: crop_padi 0→114251482326552, tier_sultan 0→124401414397944, phone
  0→135874869613602, `disable()` restored all to 0. No agent visually graded the art (no image
  input this session) — CANDIDATES awaiting designer yes/no, never approved. Evidence
  `docs/v2/evidence/h/2026-11-19-icons-candidates/`; gallery `docs/v2/visual/CANDIDATES.md`.
  `lune` 1933 / `selene` 0/0/0.
  - Make every `IconMap.luau` slot (crops, tools, tiers, currency, phone apps) in the
    `ICONS.md` style.
  - Keep the sources under `docs/v2/visual/art/icons/src/` and render to PNG at the size
    `ICONS.md` asks for.
  - Upload through Open Cloud, record the IDs, then wire them into `IconMap` behind a
    `LookDev` candidate flag. Letters stay the default.
- [x] 5. **Hero textures (6–8)** per `TEXTURES.md`: tileable, uploaded and recorded. Apply them in
  a `LookDev` material preset. `SEEN-IN-STUDIO` — 7 deterministic 512x512 tileable RGBA textures
  (`docs/v2/visual/art/textures/src/generate_textures.py` + contact sheet), uploaded via Studio MCP
  Open Cloud (all `moderationState=Approved`, real IDs in `ASSET_MANIFEST.md`), wired behind an
  off-by-default `textures` LookDev candidate (`TextureMap.candidateIds`, `Visuals.textures` slots
  stay 0). Live Play-VM round-trip: 7 slots 0→IDs→0, 10 MeshParts got real `rbxassetid://`
  ColorMaps then all removed; `SurfaceAppearance` is MeshPart-only so the adapter targets the
  imported v2 `prop_*`/`kit_*` MeshParts. No agent visually graded the art — CANDIDATES awaiting
  designer yes/no. Evidence `docs/v2/evidence/h/2026-11-19-textures-candidates/`; gallery
  `docs/v2/visual/CANDIDATES.md`. `lune` 1939 / `selene` 0/0/0.
- [x] 6. **Caricature NPC models** from `npcs.md` and `NpcArchetypes` (Pak RT, Tengkulak, Polisi,
  debt collector). `SEEN-IN-STUDIO` — 19 procedural caricature detail parts (6 Pak RT, 5
  Tengkulak, 4 Polisi, 4 debt collector) in `src/shared/NpcModelCandidates.luau` (pure data, no
  asset IDs), attached by `src/client/World/LookDevNpcs.luau` to the live box NPCs only while the
  off-by-default `npcs` LookDev candidate is enabled. Fictional caricatures per `npcs.md`; Polisi
  badge is a plain fictional disc. Approach changed to procedural primitives: subagent transport
  was down (`ECONNREFUSED`) and place saves are forbidden, so this stays source-controlled in Rojo.
  Live Play-VM round-trip: 15 parts on the 3 tagged NPCs (`pakrt=6|tengkulak=5|polisi=4`), all
  removed on disable; no `DebtCollector` in this place (its recipe proven by source + spec). Render
  is a schematic parsed from the recipe source, not a Studio screenshot (captures can't be saved
  this session). No agent visually graded the art — CANDIDATES awaiting designer yes/no. Evidence
  `docs/v2/evidence/h/2026-11-19-npc-candidates/`; gallery `docs/v2/visual/CANDIDATES.md`.
  `lune` 1944 / `selene` 0/0/0.
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
