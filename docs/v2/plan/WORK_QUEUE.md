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
- [x] 7. **Crop growth-stage models** (bibit / tumbuh / siap) for every crop in config, low-poly,
  behind `LookDev`. `SEEN-IN-STUDIO` — 12 crop archetypes x 3 stages = 36 low-poly models in
  `src/shared/CropModelCandidates.luau` (pure data, `partsFor(cropId, stage)`, no asset IDs), shown
  in a floating in-world showcase by `src/client/World/LookDevCrops.luau` only while the
  off-by-default `crops` LookDev candidate is enabled and all destroyed on disable. Uses the
  `ART.md §3` palette; shipping `FarmService` crop visuals untouched. Approach is pure-data
  primitives (not imported meshes): subagent transport down, place saves forbidden. `LookDev.luau`
  gains a sixth pure-data `crops` candidate (`idsSource` pointer, `cropCount=12`, `stageCount=3`,
  no numeric IDs). Restricted Studio MCP `execute_luau` VM cannot resolve `Enum.PartType` shapes,
  so shape resolution is under `pcall` with a default-Block fallback (real LocalScript VM resolves
  Cylinder/Sphere/Wedge). Live Play-VM round-trip: 36 models / 339 parts (303 recipe + 36 soil),
  all removed on disable. Render dumped from the same `partsFor()` via Lune, so it cannot drift;
  not a Studio screenshot. No agent visually graded the art — CANDIDATES awaiting designer yes/no.
  Evidence `docs/v2/evidence/h/2026-11-19-crop-candidates/`; gallery `docs/v2/visual/CANDIDATES.md`.
  `lune` 1950 / `selene` 0/0/0.
- [x] 8. **Hub props**: warung counter, pasar stall, pos polisi desk, Pak RT table, lanterns and
  signs. Use procedural parts with textured materials, or meshes. Keep within the per-hub
  instance budget. `SEEN-IN-STUDIO` — pure-data primitive-part recipes in
  `src/shared/HubPropCandidates.luau` (`partsFor(hubKey)` for pasar/warung/polisi/pakrt plus shared
  lantern + accent sign; no asset IDs), attached to each hub's anchor part by
  `src/client/World/LookDevHubProps.luau` only while the off-by-default `hubprops` candidate is
  enabled and all destroyed on disable; shipping `Greybox` hub props untouched. `LookDev.luau` gains
  a seventh pure-data `hubprops` candidate (`idsSource` pointer, `hubCount=4`, no numeric IDs).
  Uses `ART.md §3` palette; sign board uses each hub's own accent. Within budget: 11/11/11/10 parts
  per hub (MAP_SPEC 8–12), spec-locked at `<= 12`. Approach is source-controlled primitives (not
  imported meshes): subagent transport down, place saves forbidden. Restricted Studio MCP
  `execute_luau` VM cannot resolve Enum shape/material members, so those lookups are under `pcall`
  with safe defaults (real LocalScript VM resolves them). Live Play-VM round-trip: 43 parts
  (pakrt=10, pasar=11, polisi=11, warung=11) appeared and all were removed on disable. Render dumped
  from the same `partsFor()` via Lune, so it cannot drift; not a Studio screenshot. No agent visually
  graded the art — CANDIDATES awaiting designer yes/no. Evidence
  `docs/v2/evidence/h/2026-11-19-hubprops-candidates/`; gallery `docs/v2/visual/CANDIDATES.md`.
  `lune` 1956 / `selene` 0/0/0.
- [x] 9. **Sound candidates.**
  - For each action in the audio event list, search the Creator Store (Studio MCP `search_asset`)
    for free sounds whose licence allows use.
  - Record each existing ID, its licence and its source in `ASSET_MANIFEST.md`.
  - Wire them behind `LookDev` through SoundGroups, following the round-1 audio policy.
  `SEEN-IN-STUDIO` — searched free Creator Store Audio for the audio event list (`Config/Audio.sounds`);
  round 1 had 17 licensed IDs, the only empty slots were the sawah/hutan music beds. Two free beds
  chosen and verified loading in a Play VM (`IsLoaded=true`, lengths read): `music_sawah` 9042889348
  ("Close Your Eyes - 60 - No Melody", APMOfficial, 58.59 s) and `music_hutan` 9048807207
  ("Cavernous Wonders 60 A", APMOfficial, 60.97 s). Both recorded with licence/source in
  `docs/v2/visual/art/ASSET_MANIFEST.md`. IDs live only in `src/shared/SoundMap.luau` (pure data +
  `assetUrl`/`playable` helpers); the ID-free `src/client/World/LookDevSounds.luau` creates Sounds
  into the round-1 `JD_music` SoundGroup and drives loop state through `AudioPolicy` only while the
  off-by-default eighth `sounds` candidate is enabled, destroying them on disable; shipping config
  slots stay `id=0`. Live Play-VM round-trip: 2 loaded Sounds in `JD_music` (1 active loop via policy,
  1 pooled), all destroyed on disable. No agent graded the sound — CANDIDATES awaiting designer
  yes/no. Evidence `docs/v2/evidence/h/2026-11-19-sound-candidates/`; gallery
  `docs/v2/visual/CANDIDATES.md`. `lune` 1964 / `selene` 0/0/0.
- [x] 10. **Candidate gallery.** `docs/v2/visual/CANDIDATES.md` gets one row per candidate: a
  render or screenshot, the toggle to view it, its cost (instances and fps), and a yes/no column
  for the designer.
  `LUNE-ONLY` — gallery maintained across all eight candidates (plaza_lighting, police_walkin,
  icons, textures, npcs, crops, hubprops, sounds); one row each with the six required columns,
  a matching `LookDev:enable("<id>")` toggle, an on-disk render/screenshot path, an fps cost cell,
  and a blank designer yes/no cell. Per-asset tables for the 27 icons and 7 textures also have
  blank yes/no. Added `tests/specs/candidate_gallery_spec.luau` (4 cases, registered in
  `tests/run.luau`) locking one-row-per-candidate, required columns, existing render paths and
  blank designer cells; mutation-checked (filled cell and deleted row each fail a case, restore
  passes). Evidence `docs/v2/evidence/h/2026-11-19-candidate-gallery/`. `lune` 1968 / `selene`
  0/0/0. Designers fill the yes/no column; no agent graded any art.

### C. Performance with candidates on

- [x] 11. **Budget check.** Count instances, parts and triangles per hub with all candidates on
  and off, at each FidelityTier. Rendah must stay within budget; trim the candidates if it
  doesn't.
  `SEEN-IN-STUDIO` — live FidelityRuntime forced to Rendah/Sedang/Tinggi at all six MapSpec hubs;
  baseline and all-on instances/parts/triangles counted in a 100-stud census (all-on = baseline +
  sum of the eight disjoint candidate deltas because LookDev is single-active). Worst all-on
  49,208 triangles (9.8% of the ~500k Sedang budget) and 712 parts; baseline alone 230–347 parts,
  13,232–19,780 triangles. Counts are tier-invariant. Triangles pass; the draw-call proxy exceeds
  ~500 only in the all-on stress case and entirely because of the 339-part Studio-only crops
  review showcase — the shipping state (all candidates off) is within budget. Lune recipe counts
  match the live shape histogram exactly (crops 339/27,416, hubprops 43/3,648). Probe cleaned,
  Play stopped, place not saved or published. Evidence
  `docs/v2/evidence/h/2026-11-19-budget-check/` (`REPORT.md`, `results.json`). No lune count change.
  Low-tier showcase trim parked under "Decisions for designer"; no delivered art was changed.
- [x] 12. **30-minute soak with all candidates on**: memory series, connection count, no growth.
  `SEEN-IN-STUDIO` — 1800 s soak with all eight LookDev candidates applied additively (six client
  adapters via `.apply`, `plaza_lighting` on Client + `police_walkin` on Server via `LookDev.enable`,
  all reported `ok`), fresh in-memory mock profile, harness paced at 2 commands/s. Ran to deadline:
  **1801.83 s, 234 cycles, `done=true`**. No memory leak: client 2750.97→2635.36 MB (net −115.6;
  one GC compaction −120.4 at sample 54, then +11.4 MB over 180 cycles decelerating to +3.06 over
  the final 40), server 2760.76→2636.04 MB (net −124.7). No growth/stuck connections: pending
  harness queue always 0, whole-DataModel census 6735→6898 instances / 1706→1840 parts over the
  soak then +2 instances / +0 parts over ~993 s post-soak (plateau), zero crop parts persisted on
  tiles. No desync symptom: cash 50→754, padi 5→0, tilesOwned 6, rank gurem→petani,
  lifetimeEarned 0→1324, tutorialStep 5. Graceful plant/harvest/sell/buy refusals are by design
  (probe buys 1 padi but plants 6), not defects. Zero game-code errors, BUG-003 did not recur.
  Probe cleaned, Play stopped, VERIFY-TEMP edit reverted, place not saved or published, git clean.
  Evidence `docs/v2/evidence/h/2026-11-19-soak-all-candidates/` (`REPORT.md`, `soak.json`,
  `soak-output.log`). No lune count change. Ten-player half remains BLOCKED (no team-test tool).
- [x] 13. **StreamingEnabled readiness audit.** Find client paths that assume parts exist
  (`WaitForChild` without a timeout, direct indexing). Fix them with specs. Don't flip the
  setting; propose it under "Decisions for designer".
  `LUNE-ONLY` — audited all 71 `WaitForChild` calls (26 client) and every world-part path.
  **Zero unbounded waits on streamable paths:** all client calls are `ReplicatedStorage.Shared`
  (always replicated) or bounded (`Remotes` 30/10 s, `Terrain` 10 s, `Humanoid` 10 s, `PlayerGui`
  is owner-replicated). World parts are discovered through CollectionService tags that travel
  with streaming (`Tile`, `WindShake`, `NpcSpawn`, `LeaderboardBoard`, `MusicZone`), with
  added/removed signals or re-polling. The only shipping workspace snapshot — `Phone.neighborPlayers()`
  — is nil-guarded, attribute-validated and re-polled, with `GetTagged("Tile")` as its primary
  source. Four LookDev review tools use one-time workspace scans (off by default, dev-only);
  parked with the designer decision, not changed. Added `tests/specs/streaming_readiness_spec.luau`
  (4 cases: no unbounded WFC + non-vacuous floor, classifier self-check, tag-based consumers,
  shipping snapshots supplemental), mutation-checked (an injected unbounded WFC gave
  `1 FAILED, 1971 passed`), probe removed. `lune` 1972 (+4), `selene` 0/0/0. Setting NOT flipped;
  proposal under "Decisions for designer". Evidence
  `docs/v2/evidence/h/2026-11-19-streaming-readiness/` (`REPORT.md`, `results.json`).

### D. Hardening, round 2

- [x] 14. **Mutation testing.** For 25 key service functions (economy, inventory, raid, debt,
  receipts, save), inject one fault each: flip a comparison or drop a guard. Confirm that a spec
  fails each time, and add a spec wherever none does. Revert every fault.
  `LUNE-ONLY` — 25 one-fault mutations (`E01`–`E07`, `I08`–`I12`, `R13`–`R16`, `D17`–`D20`,
  `P21`–`P23`, `S24`–`S25`) applied as exact single-line replacements with byte-for-byte restore
  in `finally`. Pass 1: 15 killed, 7 survived, 3 `MANIFEST_ERROR` (non-unique search strings,
  correctly not applied). Pass 2 with occurrence-indexed replacement: `I10` and `D17` killed,
  `D19` survived. Pass 3: eight new killer cases added to the existing spec files (no duplicated
  fixtures) — zero-value transfer analytics (`E07`), gudang without `stacks` (`I09`), source
  stack key deletion (`I12`), zero-owed repay (`D19`), exact-cash raid fine (`R15`), inactive
  `saveAndConfirm` (`S25`), plus source-invariant locks for the two defence-in-depth guards
  (`R14`/`R16`, behaviourally equivalent through their callers). Re-ran all eight: **8/8 killed,
  exactly one named test failing each time** — no cross-killing. Final **25/25 killed, 0 survived**;
  all faults reverted, `git diff` on the six targets empty. `lune` 1980 (+8), `selene` 0/0/0.
  Evidence `docs/v2/evidence/h/2026-11-19-mutation-testing/` (`REPORT.md`, `results.json`).
- [x] 15. **Remote fuzzing.**
  `LUNE-ONLY` — new `tests/specs/remote_fuzz_spec.luau` (3 cases) loads and starts all 29 handler-owning
  server services under one Env world (task.spawn no-op; leaf infra mocked), then fires 19 deterministic
  malformed payloads (nil, booleans, NaN, +-inf, huge 10k strings, 100-deep and self-referential tables,
  empty table, mixed-arity) at every connected C->S remote. All 25 C->S handler remotes covered (0 failed
  service starts), non-vacuous floor asserted. No error escaped any handler; no malformed payload changed
  save data or attributes after schema normalizers were driven to a fixed point. Three apparent
  "mutations" were traced to expected first-touch schema settlement (DebtService.ensure stage/lastInterestAt,
  QuestService daily rollover, Cosmetic_Equip nil = legal unequip), not defects — no BUGS.md entry.
  `lune` 1983 (+3), `selene src` 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-remote-fuzzing/REPORT.md`.
- [x] 16. **Save fuzzing.**
  `LUNE-ONLY` — new `tests/specs/save_fuzz_spec.luau` (3 cases) drives 1000 seeded damaged saves through the real
  `PlayerData.migrate`→`SaveSanitize` path and 20 through the real fake-ProfileStore load path. Invariants: no throw,
  every template key present with correct type, every template number finite, `version == CURRENT_VERSION`, bounded
  non-cyclic structure; non-table roots tolerated by sanitize. Negative numbers are preserved by design, so the
  numeric invariant is finiteness + key/type preservation, not blanket non-negativity. **Found and fixed BUG-018**:
  the v2-split legacy harvest migration threw `attempt to compare number < table|string` on non-numeric
  `hotCount`/`count`/`qualitySum` before sanitize could repair them (15/1000 seed `0x5EED1234` cases); a new
  `finiteNumber()` coercion fixes it with valid-save behaviour unchanged, and a targeted regression case covers
  strings/tables/NaN/±inf/booleans/negatives. `lune` 1986 (+3), `selene src` 0/0/0.
  Evidence `docs/v2/evidence/h/2026-11-19-save-fuzzing/REPORT.md`.
- [x] 17. **Long economy sim.**
  `LUNE-ONLY` — new `tests/specs/economy_sim_spec.luau` (3 cases) runs one player for 8 h of fake time
  (480 × 60 s) against the real Economy/Market/Debt/Rank/Inventory/Produce/Pinjol code: optimal
  4-tile loop, idle loop, and a broke (0 cash / 0 seeds) loop that must borrow and recover. No overflow,
  no NaN/inf, cash finite within MAX_CASH, lifetime earned monotonic, 0 dead ends in every run; broke
  start borrows 100, loses one cycle, repays fully. Designer report with results under "Decisions for
  designer": no balance change recommended. `lune` 1989 (+3), `selene src` 0/0/0.
  Evidence `docs/v2/evidence/h/2026-11-19-economy-sim/REPORT.md`.
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

- **Item 17 — economy sim: no balance change recommended.** 8 h optimal play: 30,339 gross /
  11,239 net cash, gurem→petani, 0 dead ends; broke start borrows 100, loses one 60 s cycle,
  repays fully and ends within ~1% of the never-broke run; idle play stays flat (50 cash / 5 seeds).
  No config touched. See `docs/v2/evidence/h/2026-11-19-economy-sim/REPORT.md`.

- **Item 11 — cap the Studio-only crops showcase on low tiers.** The all-candidates-on stress view
  exceeds the ~500 draw-call proxy (580–712 parts) solely because the crops candidate is a 339-part
  review grid of all 36 models floating near the player. Proposal: show only the mature `siap`
  stage on Rendah/Sedang (12 models, 144 parts, 13,088 triangles) and keep all 36 models on Tinggi
  for full review; this brings the stress view to ~517 parts (495 at the pasar/spawn view).
  Parked, not applied — implementation would touch `CropModelCandidates.stagesByTier`,
  `LookDevCrops` and a locking spec. See `docs/v2/evidence/h/2026-11-19-budget-check/`.

- **Item 13 — decide whether to enable `StreamingEnabled`.** The shipping client is already
  streaming-safe (all waits bounded or on always-replicated containers; world parts found via
  CollectionService tags), so the remaining question is a designer trade-off: lower initial load /
  memory on low-tier devices versus streaming pop-in and the four LookDev review tools' one-time
  workspace scans (off by default, dev-only). No agent flipped the setting. If enabled, run G6
  real-device fps and the full Q5 multi-client pass before accepting; the LookDev tools may need a
  `DescendantAdded` re-scan. See `docs/v2/evidence/h/2026-11-19-streaming-readiness/`.

## Blocked on designer

- Yes or no on every candidate in `CANDIDATES.md`, and on the round-1 `plaza_lighting` and
  `police_walkin` candidates.
- G6 real-device fps, G7 five players, Q5 live multi-client run, Q6 published place, Q7
  real-device touch.
