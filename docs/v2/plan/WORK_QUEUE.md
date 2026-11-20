# Work queue round 3: visual first (long-run mode)

Live since 2026-11-19 (`e6da076`). Rounds 1 and 2 are archived in `WORK_QUEUE_ROUND1.md` and
`WORK_QUEUE_ROUND2.md`.

**Why this round exists.** The game works and is well tested, but it doesn't look finished next
to comparable Indonesian village games. Visuals are now the priority. They are not a gameplay
feature, so they may run before Gate 1 (`VISUAL_MASTER_PLAN.md`, "How this fits Gate 1").

**Decisions in force** (`DECISIONS.md`): V-D3 is now *replace all*; D18 sets how each asset type
is sourced; D19 is the day cycle.
Also in force:
- D14: aim realistic, land believable.
- V-D1: no outline on world geometry.
- V-D2: the clock moves slowly, with golden hour at spawn.
- V-D3: judge each prop separately.
- V-D4: tropical trees, no pines.
- V-D5: mixed reference board.
- V-D6: mixed animation route.
- D15: the asset ladder.
- D16: StreamingEnabled stays off.
- D17: crops showcase cap.

**Asset ladder (D15), per model, in order:**
1. **Free assets.** Creator Store models whose licence allows use (Studio MCP `search_asset` /
   `insert_asset`), and CC0 models from Poly Haven, Poly Pizza or CC0 Sketchfab (Blender MCP
   `search_assets` / `import_asset`). Strip every Script, LocalScript and ModuleScript on insert.
2. **Auto-generated.** Studio MCP `generate_mesh` / `generate_procedural_model`, or Blender MCP
   `generate_3d` (it may cost a credit, so log each use).
3. **The designer builds it.** Add the model to the queue's "Designer builds" list with a short
   brief and a reference photo, then move on.
4. **Roblox parts/CSG modelling** in Studio, only when 1–3 failed.

**Rules for every asset:**
- Record the source, licence, author and the real ID in `ASSET_MANIFEST.md`. Never invent an
  ID.
- Keep within the per-hub instance and triangle budgets (`VISUAL_MASTER_PLAN.md` §6).
- Ship it as a `LookDev` candidate, off by default, with a row in `CANDIDATES.md`.
- **Visual judgement needs eyes.** A model that can't read screenshots must not decide that
  something looks good. Integrate it, make it toggleable, save the Studio camera position for the
  review shot in the candidate row, and leave the yes/no to a review pass (the designer, or a
  session that can see screenshots).

## Queue

### 0. Before the visuals (small, do first)
- [x] 0a. **Q6 live capture for admins.** The Q6 run sheet makes the designer copy numbers by hand
  from the HUD, because `Persistence` only works in Studio. Add an admin-only (`Admins.isAdmin`)
  server command that also works in a published place and prints the same `Q6_BEFORE_JSON` and
  `Q6_RESULT_JSON` lines to the server console (F9). Rate-limit it, make it read-only, and give it
  a gate spec. Update `Q6_PUBLISHED_PLACE.md` §C to use it. This is test tooling, not a gameplay
  feature. Done 2026-11-20: admin-only, read-only, rate-limited `q6Capture`/`q6Compare` actions in
  `AdminService`, pure `Q6AdminGate` + `Q6Admin` (UserId-keyed before, pasted-JSON override), 10-case
  `q6_admin_spec` (published `IsStudio=false`), `Q6_PUBLISHED_PLACE.md` §C updated. LUNE-ONLY; the
  published-place run itself stays `BLOCKED` on the designer (D-G2), but the tooling is usable there.

### A. Foundation (V0)
- [x] 1. **Reference board (V0.3).** Put 15–20 images under `docs/v2/visual/art/reference/`, each
  with a source link and licence: Indonesian village at senja, sawah terraces, pasar, warung at
  night, rain on seng, rumah panggung, kelapa and pisang, bambu fences. The designer adds 3–5.
  Build `reference/README.md` as a grid with captions. Done 2026-11-20: 15 real JPEGs (14 free-licence
  Pexels, 1 public-domain Wikimedia) with per-file source, licence and author in
  `reference/README.md`; two 429-blocked Wikimedia CC0 shots were replaced by verified Pexels images.
  Designer still adds 3–5 of their own under V-D5; no visual verdict claimed by an agent.
- [x] 2. **Look-dev corner (V0.4).** A 60×60-stud corner with a warung, a road bend and a sawah
  edge, built in a separate Studio Folder toggled by `LookDev`. Apply V-D1 (remove the world
  outline here first) and V-D2 (golden hour). Save the camera positions for three review shots.
  Done 2026-11-20: `src/shared/LookDevCorner.luau` (21-part pure recipe) + thin client adapter build
  `Workspace.LookDevCorner` behind `LookDev:enable("corner")`, off by default; V-D1 (0 Highlights)
  and V-D2 (`Lighting.ClockTime` → 16.5) locked by a 6-case spec. Three absolute review cameras are
  saved in `docs/v2/visual/art/corner/README.md`; live Studio verification is in
  `docs/v2/evidence/h/2026-11-20-lookdev-corner/REPORT.md`. 2056 passing, LUNE-ONLY + toggle
  SEEN-IN-STUDIO; `screen_capture` timed out, so the visual yes/no stays pending.
- [x] 3. **Prop audit (V-D3).** List the ten low-poly props in a table with the verdict: keep +
  retexture, or replace. For each one to replace, name a candidate found with the asset ladder.
  Done 2026-11-20: `docs/v2/visual/art/PROP_AUDIT.md` lists all ten with current representation,
  `hubprops` LookDev coverage and a **replace** verdict each, plus a verified step-(1) ladder candidate
  (Poly Haven / explicit-CC0 Sketchfab) or a concrete step-(2)/(3) fallback where no free upgrade exists
  (`sumur`, `hut`). Licence caveats (`gerobak`, `motor` platform field, `wall` download size) flagged;
  no ID invented, no model ingested, no visual verdict claimed.

### B. Asset sourcing, ladder order

> Section G (items 21–24) supersedes the blocked classifications for items 4–9 and 11: those
> assets are now integrated off by default with real IDs and blank verdicts. The rows below are kept
> as the original sourcing record. Only animations (item 9) has no integrated candidate yet.

- [ ] 4. **BLOCKED — buildings:** rumah panggung, warung, pos polisi, rumah Pak RT, pasar stalls,
  gubuk sawah. Verified CC BY / CC0 ladder candidates (with exact licence, author, decimate notes and
  fallbacks) are recorded in `docs/v2/visual/art/SOURCING_BUILDINGS_VEG.md`. Ingestion needs real
  Open Cloud IDs, the shared Studio Importer session (D-G2) and a designer/vision verdict; no agent
  grades these as "good" from a text summary. No model downloaded or ID invented.
- [ ] 5. **BLOCKED — vegetation (V-D4):** kelapa, pisang, bambu clumps, shrubs, padi at three stages,
  dense grass. Candidates in `SOURCING_BUILDINGS_VEG.md` (Poly Haven CC0 + CC BY Sketchfab; padi
  three-stage needs step-2 generation). Same visual/session gate as item 4.
- [ ] 6. **BLOCKED — props:** fences (bambu), lanterns, crates, karung, sepeda, gerobak, jemuran,
  signs, motor. The ten already-imported props were audited under item 3 (`PROP_AUDIT.md`, replace
  verdict + ladder candidates); the wider set dressing still needs the visual verdict and Studio
  Importer session. No visual result claimed.
- [ ] 7. **BLOCKED — textures (D18):** nine CC0 PBR sets (cobblestone, dirt, tanah sawah, pematang,
  river, bambu, genteng, seng, wood) with exact Poly Haven codes and authors are recorded in
  `docs/v2/visual/art/SOURCING_TEXTURES_NPC_ANIM.md`. Download → MaterialVariant → Open Cloud upload
  → designer verdict still outstanding; round-2 agent-drawn textures remain rejected.
- [ ] 8. **BLOCKED — NPCs/characters:** CC0 rigged base (Quaternius `Farmer`, `SWAT`), peci hat, and
  Creator Store routes for caping recorded in `SOURCING_TEXTURES_NPC_ANIM.md`. Needs real IDs, R15
  validation, Studio Importer and the visual verdict. No model inserted.
- [ ] 9. **BLOCKED — animations (V-D6):** Creator Store search terms for R15 walk/idle and authored /
  `generate_animation` routes for cangkul and panen are recorded in `SOURCING_TEXTURES_NPC_ANIM.md`
  (Quaternius QAL-v1.0 licence conflict flagged). Needs the shared Studio session / designer builds.

- [ ] 9b. **BLOCKED — icons, improve (D18).** Keep the round-2 set as the base; redraw `tier_biasa`
  (it's an empty box) and `debt` (unclear). Polish the rest for more depth and readability at 48 px.
  Make it a new candidate revision with before/after contact sheets. Blocked 2026-11-20: the 27 base
  IDs in `IconMap.candidateIds` are real approved Open Cloud assets; a revision needs new uploads
  through that same route, and this session has no upload path and no image-input/vision review. The
  before/after contact sheets and yes/no stay with the designer (base verdict in `CANDIDATES.md` is
  "yes, improve"); no ID invented and no image graded here.

### C. Light and atmosphere (L1)

> Section G item 25 delivered the code half of item 10b and item 24 delivered item 11's sky; both
> rows below are kept as the original record. Their remaining half is a designer/vision verdict,
> not an agent-closable task.

- [x] 10a. **Day-cycle phase table (V-D2, D19), pure half.** Done 2026-11-20: `src/shared/World/DayCycle.luau`
  holds the eight `DAY_CYCLE.md` phases over a 24-minute day with golden-hour spawn, a readable night,
  gap/midnight blending and a Rendah light budget. `clockAt`/`segmentAt`/`presetFor`/`phaseInfo`/
  `isNight` layer a fresh grade over the season/weather preset without mutating it. 15-case
  `day_cycle_spec`; 2050 passing, LUNE-ONLY. `Strings.luau` gained the 8 phase labels and
  `setting_adzan`, but no sound/search code consumes them yet.
- [ ] 10b. **BLOCKED — day-cycle live wiring (V-D2, D19), remaining half.** Wire `presetFor` into
  `client/World/Sky.luau` (Future lighting, Atmosphere, warm ColorCorrection, Bloom kept low,
  SunRays) and the 20–40 s phase tweens; add the time-of-day sound beds (ayam, bedug, kentongan,
  jangkrik, soft adzan) with a player setting to turn adzan on or off, muted during satire moments.
  Night needs lanterns that actually emit light. Check each FidelityTier at Rendah in Studio; this
  half needs the vision observer / designer for any visual verdict. Blocked 2026-11-20: no licensed
  real sound IDs for the five time-of-day beds exist in `Config/Audio.luau` and none may be invented;
  `setting_adzan` exists only as a `Strings.luau` label and `DayCycle.ADZAN_SETTING_KEY`, with no
  settings UI or persistence to wire; the clock/lighting grade needs a designer/vision verdict and
  Studio is stale (Rojo not running), so the Rendah-tier check cannot be trusted in this session.
  Pure half 10a is done and spec-locked; no live default was changed.
- [ ] 11. **BLOCKED — sky and fog:** a tropical skybox, a distant ridge silhouette, and haze depth.
  Blocked 2026-11-20: the skybox needs a licensed real image/HDRI and a real Open Cloud ID (D15/D18),
  none of which exists in the repo or is obtainable in this session; the ridge and haze grade also
  need a designer/vision yes/no. No skybox ID invented and no visual claimed.

### D. The frame (V1)
- [ ] 12. **BLOCKED — spawn view.** Combine A–C on the spawn view only. Save the camera position,
  then check the instance count and fps proxy against the budget. Leave the five screenshot tests
  to the review pass. Blocked 2026-11-20 (re-checked in item 34): round 4 added textured
  `buildings_r4`/`vegetation_r4`/`props_r4`/`npcs_r4` (real CC0/CC BY models replacing the grey r3
  placeholders), `textures_r4` base-material overrides and three `sky_r4_a/b/c` HDRIs, all off by
  default with blank verdicts and factual observer descriptions in
  `h/2026-11-20-review-round4/REVIEW_ROUND4.html`. There is still no *approved* look to combine, so
  the spawn camera and five shot tests stay with the designer/vision review, the fps proxy needs
  designer hardware, and animations (item 9) remain outstanding. The r3 `corner` candidate was
  rejected by the designer; `REVIEW_ROUND3.md` / `REVIEW_ROUND4.md` are inputs, not approvals.
- [x] 13. **Review pass handoff.** Write `docs/v2/visual/REVIEW_ROUND3.md` listing every
  candidate with its toggle and camera position, in the order to review. The designer, or a
  session that can see screenshots, fills in the verdicts. Done 2026-11-20: handoff doc lists all
  nine LookDev candidates with exact `enable`/`disable` commands, the three saved `corner` cameras,
  the blocked asset lanes and the designer/hardware actions; verdict cells are blank and prior
  designer verdicts are carried verbatim from `CANDIDATES.md`. No visual graded, no screenshot
  claimed.

### E. Moments (V2), after the frame is approved
- [ ] 14. **BLOCKED — harvest, reveal and sale VFX (M2–M4):** particles, a pop scale, a cash fly,
  a sound sync. Behind tiers. Blocked 2026-11-20 (re-checked in item 34): neither section G nor
  round 4 added VFX or particle-texture assets (r4 covered textures, sky and models only), the V2
  gate (VISUAL_MASTER_PLAN §V2) still requires L7.1 particle textures, and this section is
  explicitly "after the frame is approved", which item 12 is not.
- [ ] 15. **BLOCKED — raid moment (M5) lights and the police walk-in,** using the round-1
  `police_walkin` candidate if it was approved. Blocked 2026-11-20 (re-checked in item 34): that
  candidate's verdict is still pending in `CANDIDATES.md`, the frame is not approved, and the raid
  lights (L1.3) plus the V2 clip need real assets and designer hardware. Section G added an off-by-
  default `day_cycle` lamp layer; round 4 added a police model inside `npcs_r4`, but it is an
  anchored, unrigged review dummy with a blank verdict and no animation. Still no approved moment
  package and no V2 clip. No visual claimed.

### E2. Text
- [x] 19. **Indonesian text review** (moved from round 2 item 24). Read every `id` string for
  natural, non-translated-sounding Indonesian, in the `humanizer-indonesia` style. Put the
  proposed edits in a table under "Decisions for designer" and don't change `Strings.luau`.

### F. Close
- [ ] 16. **BLOCKED — budget and soak** with all approved visuals on, at each tier. Blocked
  2026-11-20 (re-checked in item 34): the registry grew from 17 to 25 off-by-default candidates in
  round 4 (8 new r4 candidates), but every verdict is still blank, so there are no approved visuals
  to turn on; the tier/fps measurement also needs the designer's phone emulator and multi-client
  session. The 2026-11-19 soak evidence in
  `docs/v2/evidence/h/2026-11-19-regression-replay/` predates the visual candidates and cannot stand
  for this gate.
- [x] 17. **Regression replay**: G3 beat sheet, G5 timings and a full-session `output.log`.
  Carried forward 2026-11-20: `docs/v2/evidence/h/2026-11-19-regression-replay/` holds the fresh
  synced-code replay (HEAD `350c48f`) with all nine G3 steps, forced raid, G5 timings, the Q2
  `g3-g5-q2-output.log` and the 30-min Q5 soak. Every later commit is round-3 docs, a pure module or
  an off-by-default LookDev candidate; no gameplay default changed, so no new-regression claim is
  made. A replay after approved visual integration belongs to item 16.
- [x] 18. **Refill** from `VISUAL_MASTER_PLAN.md` V1–V3, `CANDIDATES.md` and `BUGS.md`. Repeat
  until nothing is left. Done 2026-11-20: scanned the V1–V3 gates and V-L backlog
  (`VISUAL_MASTER_PLAN.md:334–358`), `CANDIDATES.md`, `BUGS.md` and `GATE1.md`. No agent-closable work
  remains: every blocker/major bug is fixed or closed, every open Gate 1 row needs a designer,
  hardware, real asset IDs or a vision verdict, and every remaining V-L item either needs those or is
  already queued. Items 11, 12, 14, 15 and 16 are marked `BLOCKED` with reasons; round 3 is
  exhausted.

### G. Unblock pass (added 2026-11-20 after the round-3 review)

Most of B and C were marked blocked for reasons that don't apply. **Rule for this section: a missing
visual verdict never blocks integration.** Integrate every asset off by default behind `LookDev`,
record the review camera, leave the verdict cell blank, and move on. The verdict is the review
pass's job, not a precondition. If Rojo is not running, start it (`rojo serve`) instead of calling
Studio stale. A licence that is not CC0 / CC BY (with attribution recorded) is still a hard stop.

- [x] 20. **Upload route check.** Try the `ROBLOX_API_KEY` env var against Open Cloud
  `POST /assets/v1/assets` with the first real texture from item 21 (not a test file). If it works,
  that is the upload route for this section. If it fails with a scope/permission error, record the
  exact HTTP status (never the key) and mark only the *upload* steps below "needs Studio
  `open_cloud_invoke` session"; do every download, packing, Luau and spec step anyway, so the
  Studio session only has to upload and paste IDs.
  Done 2026-11-20: the first real 1K texture POST returned HTTP 200 with a real asset ID; the route
  is recorded in `docs/v2/visual/art/textures_r3/upload_route_check.json`. Every later upload used
  the same env-key route. The key was never printed, logged or committed.
- [x] 21. **Textures (item 7).** Download the nine CC0 Poly Haven sets listed in
  `SOURCING_TEXTURES_NPC_ANIM.md` at 1K (Poly Haven public API), keep colour / normal / roughness,
  upload, record every ID in `ASSET_MANIFEST.md`, and wire them as `MaterialVariant`s in a new
  LookDev candidate `textures_r3`, off by default. Add its row to `CANDIDATES.md` with a contact
  sheet, verdict blank.
  Done 2026-11-20: nine CC0 1K PBR sets (27 maps) downloaded and MD5-verified, uploaded via Open
  Cloud, IDs in `textures_r3/upload_manifest.json`; `TextureMapR3.luau`, `LookDevTexturesR3.luau`,
  registry/spec/CANDIDATES/camera added. Verdict blank.
- [x] 22. **Icon revision (item 9b).** Redraw `tier_biasa` and `debt`, polish the rest, render
  before/after contact sheets, upload, record IDs, add candidate `icons_r3`. Verdict blank.
  Done 2026-11-20: 27 deterministic r3 PNGs with before/after sheets; all 27 uploaded as Images,
  IDs in `icons/render_r3/upload_manifest.json`; `IconMapR3.luau`, `LookDevIconsR3.luau`, spec and
  CANDIDATES row added. Verdict blank.
- [x] 23. **Models (items 4, 5, 6, 8).** CC0 first (Poly Haven, Quaternius, Kenney, Poly Pizza),
  CC BY only with the attribution in the manifest. Decimate to the budget in
  `SOURCING_BUILDINGS_VEG.md` (Blender MCP if available, otherwise a script), export FBX, upload as
  `Model`, record IDs, and add one LookDev candidate per family (`buildings_r3`, `vegetation_r3`,
  `props_r3`, `npcs_r3`) placed in the 60×60 `corner`. Tropical only (V-D4). Anything no free source
  covers goes to "Designer builds" with a brief.
  Done 2026-11-20: four real CC0 GLBs plus 16 original low-poly GLBs (stdlib `obj_to_glb.py`, 2960
  tris, deterministic and verified) uploaded as `Model` assets; 20 IDs in
  `models_r3/upload_manifest.json`; four server-side family appliers (client `LoadAsset` is blocked),
  `ModelMapR3.luau`, `INTEGRATION.md`, spec and four CANDIDATES rows added. Verdicts blank.
- [x] 24. **Sky (item 11).** One CC0 Poly Haven tropical/overcast HDRI → six cube faces by script
  → upload → `Sky` in a LookDev candidate `sky_r3`, plus the ridge silhouette and haze values in
  `Atmosphere`. Verdict blank.
  Done 2026-11-20: CC0 Poly Haven `fish_hoek_beach` HDRI (Greg Zaal, Rico Cilliers) converted
  deterministically to six 1024×1024 cube faces; six real Image IDs in
  `sky_r3/upload_manifest.json`; `SkyMapR3.luau`, `LookDevSkyR3.luau`, spec, CANDIDATES row and saved
  camera added. Verdict blank.
- [x] 25. **Day-cycle live wiring, code half (item 10b).** Wire `DayCycle.presetFor` into
  `client/World/Sky.luau` behind LookDev `day_cycle` (off by default), with the 20–40 s tweens and
  lamps that emit light at night within the Rendah budget. Add the adzan setting as a saved player
  setting (default on, low volume) with a spec on a mock profile, and the five sound-bed slots with
  `nil` IDs, so they stay silent until the designer supplies licensed IDs. Never invent a sound ID.
  Done 2026-11-20 (code half): `DayCycleLive.luau`, `AdzanSetting.luau`, `LookDevDayCycle.luau`,
  five `id = 0` silent beds, spec, README and registry/CANDIDATES wiring added. No sound ID invented.
  The in-Studio Rendah-tier verdict remains a designer/vision action.
- [x] 26. **Review handoff.** Add every new candidate from 21–25 to `REVIEW_ROUND3.md` with its
  toggle and camera, in review order.
  Done 2026-11-20: section-G order, Server-datamodel rule, all seven new master-table rows, the
  consolidated saved-camera list and updated designer actions are in `REVIEW_ROUND3.md`. Verdicts
  blank.
- [x] 27. **Refill.** Re-check items 12, 14, 15 and 16 against what 20–26 produced; un-block any
  that now have their inputs, and repeat until nothing agent-closable is left.
  Done 2026-11-20: all four re-checked. None is agent-closable — item 12 needs the designer/vision
  look and fps hardware; items 14–16 need frame approval, licensed VFX IDs and designer hardware.
  Their BLOCKED reasons were updated to reflect the section-G inputs; no further agent-closable work
  is left in the queue.

### H. Round 4 — fix, then source real free assets (added 2026-11-20 after the Studio review)

**Designer verdicts, 2026-11-20** (recorded in `CANDIDATES.md`; shots in
`docs/v2/evidence/h/2026-11-20-review-round3/REVIEW_ROUND3.html`):
- **yes:** `icons_r3` (ship) and `day_cycle` (keep, tune the 16:00 look, test night).
- **no:** `corner` and the four model families. They are tiny, untextured and grey, and the script-built
  placeholders are not acceptable.
- **retest:** `textures_r3` and `sky_r3`.

The designer's direction: lean much harder on **free online sources** for textures, HDRIs and models.
The textures and HDRI in round 3 were already the right kind of source (CC0 Poly Haven). They failed
because of how they were applied, not where they came from.

**Toggle syntax:** `LookDev.enable("id")` / `LookDev.disable()` with a dot. The colon form fails with
"unknown candidate". The docs and specs were corrected on 2026-11-20.

**Free sources, in order of preference (licence is still a hard stop, so record it per asset):**

| Kind | Sources (CC0 unless noted) | Notes |
|---|---|---|
| PBR textures | Poly Haven, ambientCG, ShareTextures, cgbookcase | Download at 1K for mobile (2K only for hero surfaces). Keep colour, normal and roughness. ambientCG has a public API (`/api/v2/full_json`). |
| HDRI / sky | Poly Haven HDRIs, ambientCG HDRIs | Pick tropical or village skies with no city skyline. |
| Models | Creator Store (licence allows use), Quaternius, Kenney, Poly Pizza (check each model: some are CC BY), Poly Haven models, Sketchfab with the "downloadable + CC0/CC BY" filter | Models must be **textured** (texture or vertex colour). CC BY needs the attribution recorded. |
| Characters | Quaternius rigged packs, Kenney characters, Creator Store R15 rigs | R15-compatible or re-rigged to R15. |

- [x] 28. **Fix the seven round-3 bugs** (`h/2026-11-20-review-round3/REPORT.md`), each with a
  regression spec:
  - `sky_r3`: set the real `Sky.SkyboxBk/Dn/Ft/Lf/Rt/Up` properties and give `Atmosphere.Decay` a Color3.
  - `LookDevModelsR3`: anchor every BasePart and set `CanCollide` to a sensible value.
  - Normalise model scale to a target size: add a `targetHeight` per slot in `ModelMapR3` and scale
    with `Model:ScaleTo`.
  - Rotate Z-up imports to Y-up (`farmer_cc0`, `polisi_cc0`).
  - Move the staging area from (500,500) onto real terrain near spawn, with the review cameras updated.
  - Review tooling: add a `LookDevReview` helper, so one `execute_luau` or command-bar call requires
    the applier modules for its datamodel before calling `LookDev.enable`.
  Done 2026-11-20: all seven fixed with regression coverage in
  `tests/specs/review_round3_bugfix_spec.luau` — real `Sky.SkyboxBk/Dn/Ft/Lf/Rt/Up` + Color3
  `Atmosphere.Decay`, anchored non-colliding `ScaleTo` model parts, Z→Y rotation for `farmer_cc0`/
  `polisi_cc0`, staging moved to real `MapSpec` terrain at `{-14,0,-12}` with cameras updated, and a
  pcall-guarded `LookDevReview` helper (incl. three throwing-root cases) so one call requires the
  applier for either datamodel. LUNE-ONLY; one sky face verified in a fresh Play Client VM.
- [x] 29. **`textures_r4`: coverage, not just sourcing.**
  - Apply the CC0 sets as `MaterialService` **base-material overrides** (MaterialVariants with
    `BaseMaterial` set, plus `MaterialService:SetBaseMaterialOverride`). Every Grass / Ground / Mud /
    Cobblestone / Wood / Brick / Slate / CorrugatedMetal surface, Terrain included, should change, not
    only MeshParts matched by name.
  - Add ambientCG / ShareTextures sets where Poly Haven has no good match: rice-paddy mud, laterite red
    dirt, woven bamboo (*bilik*), clay roof tile, weathered plaster wall, dry grass.
  - Tune `StudsPerTile` per surface.
  - Off by default. Contact sheet plus the saved spawn camera.
  Done 2026-11-20: twelve CC0 base-material override sets (36 Image IDs) from Poly Haven and
  ambientCG (rice-paddy mud, laterite, *bilik* bamboo, clay tile, weathered plaster, dry grass
  included), applied via `TextureMapR4` / `LookDevTexturesR4` MaterialVariants with `BaseMaterial`
  and `SetBaseMaterialOverride` across Grass/Ground/Mud/Cobblestone/Wood/Brick/Slate/CorrugatedMetal
  including Terrain, per-surface `StudsPerTile`, off by default, contact sheet and saved spawn camera
  `docs/v2/visual/art/textures_r4/`. Verdict blank.
- [x] 30. **`sky_r4`: three HDRI options for an A/B/C pick.**
  - Take three CC0 HDRIs from Poly Haven / ambientCG: clear tropical afternoon, golden hour, light
    overcast.
  - Convert each from equirect to six faces using Roblox's face orientation (verify one face in Studio
    before the others).
  - Upload the faces, register them as `sky_r4_a/b/c` (off by default), and make one contact sheet with
    the three side by side.
  - Keep the ridge silhouette and haze. `CelestialBodiesShown` stays on, so the day cycle still moves
    the sun.
  Done 2026-11-20: three CC0 HDRIs (Poly Haven) converted deterministically to 18 cube faces with
  Roblox face orientation; one face (`sky_r4_a`) verified in a fresh Play Client VM (real
  `Sky.Skybox*` IDs, `Atmosphere.Decay` Color3, `CelestialBodiesShown=true`, 12-part ridge). Registered
  as `sky_r4_a/b/c`, off by default, with a contact sheet in `docs/v2/visual/art/sky_r4/`. Verdicts
  blank; factual observer descriptions in `h/2026-11-20-review-round4/REVIEW_ROUND4.html`.
- [x] 31. **`*_r4` models: real textured models from the free sources above**, one LookDev family
  each, replacing the round-3 placeholders.
  - Families: `buildings_r4` (rumah panggung, kandang ayam, gudang, warung), `vegetation_r4` (kelapa,
    pisang, bambu, mangga, shrubs, padi three stages), `props_r4` (gerobak, sumur, lapak, pagar bambu,
    alat tani, karung, jemuran), `npcs_r4` (petani caping, pedagang, petani wanita, tukang peci, polisi).
  - Target sizes, with the player at about 5 studs:

    | Model | Size (studs) |
    |---|---|
    | rumah panggung | 18–24 tall, door ≥ 7 |
    | kelapa | 25–35 |
    | pisang | 10–14 |
    | bambu clump | 18–25 |
    | gerobak | about 6 tall |
    | NPC | 5 (R15) |

  - Decimate to `SOURCING_BUILDINGS_VEG.md` budgets.
  - Record the source, licence, author and ID in `ASSET_MANIFEST.md`.
  - Anything no free source covers goes to "Designer builds" with the brief. No more script-built
    primitives.
  Done 2026-11-20: 21 real textured Model IDs (buildings 4, vegetation 5, props 7, npcs 5) from
  CC0/CC BY sources (Grab3D, Poly by Google/Poly Pizza, Poly Haven), decimated to budget, staged on
  real terrain behind four server-side family appliers (`InsertService:LoadAsset` is client-blocked).
  Source, licence, author and ID recorded in `ASSET_MANIFEST.md`; no-ID guard and specs added.
  `mangga` is a Balsa stand-in and `npcs_r4` are unrigged review dummies — both noted. Gaps with no
  compliant free source (true mango, three-stage padi, local headwear, R15 re-rig) are in
  "Designer builds". Verdicts blank.
- [x] 32. **Spawn liveliness brief (designer note 2026-11-20).** Spawn is still plain. Later it should
  feel as busy and lived-in as the reference village games, through props: jemuran, karung stacks,
  sepeda, ayam, gerobak, warung clutter, lanterns, potted plants, bamboo fences and *pematang* edges.
  - Write `docs/v2/visual/SPAWN_DRESSING.md`, covering:
    - the prop clusters around the spawn view;
    - which r4 asset fills each cluster;
    - an instance / triangle budget per fidelity tier;
    - two or three ambient-life ideas: chickens wandering, smoke from the warung, swaying laundry.
  - Plan only: dress spawn after item 31's models pass review.
  Done 2026-11-20: `docs/v2/visual/SPAWN_DRESSING.md` written as planning only — prop clusters around
  the spawn view, the r4 asset mapped to each cluster, an instance/triangle budget per fidelity tier,
  and three ambient-life ideas (wandering ayam, warung smoke, swaying laundry). No spawn was dressed;
  dress only after item 31 passes review.
- [x] 33. **Review handoff.** Write `REVIEW_ROUND4.md` with every new candidate, its dot-syntax toggle,
  its datamodel and its saved camera, in review order. The main session takes the Studio shots and
  builds the HTML review sheet. No agent grades visuals.
  Done 2026-11-20: `docs/v2/visual/REVIEW_ROUND4.md` lists all eight r4 candidates in review order
  with dot toggles, datamodels and saved cameras (verdict cells blank). Studio Play Client/Server VMs
  captured all eight via the vision observer from those cameras; the descriptions, toggles and blank
  verdicts are in `docs/v2/evidence/h/2026-11-20-review-round4/REVIEW_ROUND4.html`, with method and
  commands in the same folder's `REPORT.md`. No screenshot pixels were retained, so the sheet is
  explicitly **not a screenshot claim**; no agent graded any visual. Play stopped, nothing saved or
  published.
- [x] 34. **Refill.** Re-check the blocked items against round 4 output; repeat until nothing
  agent-closable is left.
  Done 2026-11-20: re-checked items 12, 14, 15 and 16. Round-4 textured models/sky/textures do not
  unblock any of them: every verdict is still blank, so there is no approved look to combine or soak;
  item 14 needs L7.1 particle textures r4 did not add; item 15's r4 police model is an unrigged dummy
  and `police_walkin` is still pending; items 12/16 still need designer hardware. Their BLOCKED
  reasons were updated. No further agent-closable work remains.

## Designer builds

Models the ladder couldn't supply, each with a brief and a reference.

- **Review 2026-11-20:** the 16 models in `models_r3/generated/` are *not* designer builds. They are
  script-built primitives (`AGENT_GENERATED`, about 100–300 faces each), uploaded as placeholders
  behind LookDev only. Real versions are still needed for: rumah panggung, kandang ayam, gudang,
  pisang, mangga, shrubs, gerobak, sumur, pasar stall, pagar bambu, tools, and four villagers
  (petani caping, pedagang, petani wanita, tukang peci). The ladder still applies: Creator Store or
  CC0 first, then `generate_mesh` / Blender `generate_3d`, then the designer. Briefs are in
  `models_r3/MANIFEST.md`.

## Decisions for designer

### Round 3 item 19 — Indonesian copy review (2026-11-20)

Reviewed every `id` entry in `src/shared/Strings.luau` in the `humanizer-indonesia` style. The
strongest lines (the warung rumours, the oplosan/sus notices, most toasts) already sound spoken and
should stay. `Strings.luau` was **not** changed; these are proposals only.

| Key | Current `id` | Proposed `id` | Why |
| --- | --- | --- | --- |
| `shop_restock_in` | `Restock %s` | `Restok %s` | English word in an otherwise Indonesian HUD label; `restok` is the form players actually say. |
| `n_shop_restocked` | `Toko Bibit di-restock!` | `Stok Toko Bibit sudah diisi ulang!` | `di-restock` is mixed affixation and reads translated; an explicit subject sounds natural. |
| `n_shop_sold_out` | `Stok %s habis. Tunggu restock.` | `Stok %s habis. Tunggu restok.` | Same mixed word in a short toast. |
| `admin_perf_decoration` | `Dekorasi terrain` | `Dekorasi medan` | `terrain` is English; the admin panel is internal but the `id` field is still Indonesian. |
| `n_crop_gagal` | `Gagal panen akibat kekeringan El Nino pada %s!` | `Tanaman %s gagal panen karena kekeringan El Niño!` | `%s` is a crop name (`FarmService.luau:460`), so "pada Padi" is awkward; `karena` is more conversational than `akibat`. |
| `n_gudang_deposit` | `%s hasil masuk gudang.` | `%s hasil disimpan di gudang.` | Pairs with `n_gudang_withdraw` (`diambil dari gudang`) instead of a bare "masuk gudang". |
| `n_worker_hired` | `Buruh tani bekerja %s menit. Upah Rp %s + Rp %s/hasil.` | `Buruh tani bekerja %s menit. Upah Rp %s + Rp %s per hasil.` | `/hasil` reads like a code token; `per hasil` is how the rate is said out loud. |
| `n_viral_case` | `Kasusmu viral, amplop tidak bisa.` | `Kasusmu viral, amplop nggak bakal membantu.` | `tidak bisa` is vague and formal; matches the register already used in `n_viral`. |
| `sus_explain` | `Tingkat 'Sus' (kecurigaan warga & polisi desa) naik! Hati-hati dirazia.` | `Tingkat 'Sus' (kecurigaan warga dan polisi desa) naik! Hati-hati kena razia.` | `dirazia` has no actor and sounds like a translation; `dan` reads better in prose than `&`. |
| `bayarlater_offer` | `BayarLater: Butuh modal kilat tanpa jaminan? Buka app BayarLater di HP!` | `BayarLater: Butuh modal kilat tanpa jaminan? Buka aplikasi BayarLater di HP!` | `app` drops the otherwise conversational register. Low-confidence: may be intentional pinjol marketing voice. |
| `n_debt_seized`, `n_debt_shamed` | `Debt collector ...` | `Penagih utang ...` | English term inside otherwise Indonesian satire; `Kolektor` is already used in `debt_collector_tag`. Low-confidence: "debt collector" is widely understood locally. |

One non-`id` finding from the same read: `raid_lower_third.en` ends with the translator note
`(A wink at dramatic Indonesian TV news.)`, which would be shown to English players. Proposed `en`:
`BREAKING NEWS: Village Police are heading for your farm!` (drop the note). No other `id` edit is
recommended at this time.
