# Work queue round 3: visual first (long-run mode)

> **START HERE (standing prompt, so the designer doesn't need to retype it).** If you were only told to "continue" or "read the work queue", this block is your whole instruction:
>
> 1. Read `AGENTS.md`, the tracker at the top of `docs/v2/plan/MASTER_PLAN.md`, `docs/testing/BUGS.md` and `docs/testing/GATE1.md`.
> 2. You are in long-run mode. Take the **first unchecked item** in this file (sections L, O, M and N are the live ones, in that order: **section O comes before the unticked items of M**) and work down. Don't ask questions, don't stop to report.
> 3. Section K's hard rules apply to every scene-affecting item: a tick needs real Studio PASS output saved under `docs/v2/evidence/h/<date>-round<N>/CHECK_<item>.txt`; two failed attempts mean `BLOCKED — <FAIL line>`; never weaken a check; never save the place; never touch NPC outfits, the terrain sculpt or the chosen sky/ground.
> 4. Per item: `lune run tests/run.luau` passes (check the exit code), `selene src` is 0/0/0, stylua only on files you changed, then a topical commit with no attribution lines, the tracker "Last updated" line updated in the same commit, and push to `track/c-world-look`. Stage files by name, never `git add -A`.
> 5. The main session (Claude, with Studio screenshots) does the visual review afterwards. Stop only when every item is ticked or `BLOCKED`, then write the final report: commits, blocked items, decisions list.

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

### I. Round 5 — spawn ground, sky and characters (added 2026-11-20 after the round-4 Studio review)

**Designer verdicts and notes, 2026-11-20** (recorded in `CANDIDATES.md`; shots in
`docs/v2/evidence/h/2026-11-20-review-round4/REVIEW_ROUND4_STUDIO.html` and `STUDIO_REVIEW.md`).

- **Overall:** spawn still feels thin. The textures look wrong. The vegetation is messy and sometimes
  overlaps the ground and the road.
- **Ground:** spawn doesn't need a road. Turn the paths into dirt (*tanah*). Save the road design for
  later, for a level that really has a road.
- **Sky:** look for Indonesian sky references and HDRIs; ours looks different from a real
  Indonesian sky. The default must not be this cloudy. Overcast belongs to a later rain or season
  event, which is not in this round.
- **Buildings:** `buildings_r4` is fine as a temporary placeholder; the designer will refine the final
  models later.
- **Vegetation:** pisang is good. Kelapa is kept for another level, so take it out of spawn. Bambu and
  mangga still need work.
- **Props:** jemuran is good. Keep the karung semen, but put it somewhere it makes sense (by the
  gudang, a toko bangunan or a small renovation spot). The other tools are too small.
- **Characters:** not solid enough. Roblox R15 characters are fine; what matters is that they look
  solid.

- [x] 35. **Fix the `textures_r4` darkening.** Done 2026-11-20. Root cause measured in a live Play/Client
  session: the CC0 `MaterialVariant`s carry only maps, so `SetBaseMaterialOverride` also affects
  Terrain, where the dark stock `GetMaterialColor` multiplier crushed the earth maps towards black.
  `TextureMapR4.terrainTint` now holds bright warm-neutral values for 11 built-in terrain materials;
  the applier captures the exact current colour and restores it on disable (Water excluded). Live
  before/during/after colour reads and the reversal proof are in
  `docs/v2/evidence/h/2026-11-20-textures-r4-fix/REPORT.md`. Still-image after-capture is assigned to
  item 42; this session could not retain a Studio still. Off by default; verdict blank. Tests 2177.
  - Find out why the Ground/Laterite (and other) overrides turn spawn almost black. Check Terrain
    `MaterialColors`, the colour-map brightness and the base-material choice.
  - Bring the ground back to warm, readable brown.
  - Retest with before/after pictures from the saved spawn camera. Off by default; the verdict stays
    blank.
- [x] 36. **Spawn ground: dirt paths, no road (candidate `spawn_ground_r5`, off by default).** Done
  2026-11-20. `Shared.SpawnGroundMapR5` holds tanah colours/materials/heights and pure-XZ exclusion
  rectangles; the server applier hides road/arm/ring/continuation/RoadEdge Parts and overlapping
  MudPatches (exact prior Visible/CanCollide restored), then builds feathered Ground/Mud paths in a
  dedicated Folder, skipping PlotAnchor/hub footprints to stop z-fight. The default `buildRoads`
  stays untouched — `spawn_ground_r5` is the stored alternative behind the flag. Off by default;
  verdict blank. `tests/specs/spawn_ground_r5_spec.luau`.
  - Replace the asphalt and road strips around spawn with dirt paths (Terrain Ground/Mud with a soft
    edge).
  - Fix every place where terrain, plots and paths overlap or z-fight.
  - Keep the current road design saved but unused: move it to a stored asset, or keep it behind a
    flag, documented for a later level. Don't delete it.
- [x] 37. **Vegetation cleanup (`vegetation_r5`).** Done 2026-11-20. `Shared.ModelMapVegetationR5`
  reuses the real round-4 model IDs (no invented IDs) and adds path/plot/hub exclusion rectangles
  with margins; the server applier places pisang clusters and dense 5-stalk bamboo clumps, keeps
  only the existing mango stand-in (Designer-build note in `art/vegetation_r5/MANIFEST.md`), and
  places NO kelapa and NO pines at spawn. Kelapa data is retained only as a disabled "another level"
  group. Off by default; verdict blank. `tests/specs/vegetation_r5_spec.luau`.
  - Remove the pines around spawn (V-D4).
  - Take kelapa out of spawn and keep its asset for another level.
  - Place pisang clusters.
  - Make the bamboo clumps dense, not thin poles.
  - Replace the mango stand-in if a free source has a real one; otherwise add it to "Designer builds".
  - Placement rule: an exclusion zone around paths, plots and building footprints, so no tree overlaps
    them. Add a spec that checks the placement data against the zones.
- [x] 38. **`sky_r5`: an Indonesian sky.** Done 2026-11-20. `Shared.SkyMapR5` reuses the two
  already-uploaded real CC0 HDRI sets from `SkyMapR4` (a = primary bright/humid, b = alternate); the
  newly researched Poly Haven HDRIs are documented in `art/sky_r5/README.md` but NOT uploaded/used.
  The client applier lowers Terrain `Clouds.Cover` to 0.4 (exact prior value restored), builds no
  ridge slabs, and applies the cube top-face seam fix via `SkyboxUp`. Photo/HDRI links with authors
  and licences are in the README; overcast is noted for a future season event only. Off by default;
  verdict blank. `tests/specs/sky_map_r5_spec.luau`.
  - Gather three or four photo references of a typical Indonesian village sky: bright, humid haze,
    scattered cumulus, a high sun, a soft blue horizon. Record the links in `sky_r5/README.md`.
  - Pick two CC0 HDRIs that match (Poly Haven / ambientCG), mostly clear with light cumulus.
  - Fix these sky bugs:
    - Remove the ridge "slabs" from the plaza, or move them out to the real horizon.
    - Lower the Terrain `Clouds.Cover` for this candidate (about 0.3–0.5) so the skybox shows.
    - Fix the cube seam at the top face.
  - The overcast look goes in a note for a future rain or season event and is not built now.
- [x] 39. **Props fix (`props_r5`).** Done 2026-11-20. `Shared.ModelMapPropsR5` reuses the real
  round-4 model IDs with a per-slot scale: jemuran unchanged at 1; gerobak/sumur/lapak/alat_tani
  resized against a 5-stud player; a 4-sack karung stack moved to the gudang front apron (context,
  not loose at spawn). The server applier applies per-slot scale and restores/destroys exactly.
  Off by default; verdict blank. `tests/specs/props_r5_spec.luau`.
  - Keep jemuran.
  - Rescale the tools (cangkul, sabit, gerobak, sumur, lapak) to real size against a 5-stud player,
    or replace any that stay unreadable.
  - Place the karung semen in a fitting context: stacked by the gudang or a small renovation spot.
- [x] 40. **Characters (`npcs_r5`): solid Roblox R15 villagers.** Done 2026-11-20. Five roles built
  from `Instance.new("HumanoidDescription")` + `Players:CreateHumanoidModelFromDescription(..., R15)`
  with warm/navy body colours — solid, upright, grounded (bbox-bottom), Y-rotation only, no
  lying-down imports or animation. Three REAL free Creator Store hat Models loaded from data (caping
  71002247087415/Zephban5961, caping backup 14769019514/RZKU, police cap 126970096704856/Mukamato101),
  each with creator + store URL in `art/models_r5/npcs/MANIFEST.md`. peci/batik/sarong had no reliable
  free source → Designer-build note, body colours only; no ID invented. Off by default; verdict blank.
  `tests/specs/npcs_r5_spec.luau`.
  - Build them from the standard R15 rig with `HumanoidDescription`: body colours, plus clothing and
    accessories (caping, peci, sarung or batik shirt if available).
  - Use free Creator Store or catalog items whose IDs come from a real search. Never invent an ID.
  - Upright and grounded, with an idle pose and no lying-down imports.
  - Five roles: petani, pedagang, petani wanita, tukang peci, polisi.
- [x] 41. **Spawn dressing pass (`spawn_r5`, off by default).** Done 2026-11-20. `Shared.SpawnDressingMapR5`
  is pure data that composes only approved/temporary assets from the R4/R5 source maps — temporary
  buildings_r4 gudang + warung, jemuran, the contextual gudang karung stack, rescaled gerobak/sumur/
  lapak/pagar/alat_tani, approved pisang + dense bamboo, and all 5 R15 villagers. No kelapa, pine or
  mangga stand-in; every tree outside the 28-wide north-road corridor (data assertion + spec). Tier
  budgets 50/100/150 instances and 50k/100k/150k tris (Sedang default ~23 instances / 58k est.,
  well within budget). Saved review camera `{0,20,72}->{0,5,14}` in `SPAWN_DRESSING_R5.md` (captures
  buildings row z=20, NPC row z=8, plaza apron). Server applier reuses the proven PropsR5 model path
  and NpcsR5 R15 rig path, with `setTier()` and exact folder detach/restore. Off by default; verdict
  blank; visual shot check deferred to item 42. `tests/specs/spawn_dressing_r5_spec.luau`.
  - Apply `SPAWN_DRESSING.md` using only
  approved or temporary assets: `buildings_r4` (temporary), pisang, jemuran, karung semen in context,
  and the fixed props and characters from 39–40. Make spawn feel lived-in within the tier budgets.
  Save the review camera.
- [x] 42. **Review handoff.** Done 2026-11-20. `docs/v2/evidence/h/2026-11-20-review-round5/REVIEW_ROUND5.md`
  (plus `REVIEW_ROUND5.html` and `docs/v2/visual/REVIEW_ROUND5.md`) lists all eight round-5 candidates
  with the exact dot-syntax one-call toggle, datamodel and saved camera, blank verdict cells throughout.
  Live Play sweep confirmed all 8 candidates enable and build their content folders (123/104/46/1405/
  1529/116 descendants for the six server appliers; the two client appliers override Terrain/sky).
  Every saved camera was checked in the VM with a centre-line `Workspace:Raycast` plus a scan of all
  vegetation-named objects within 12 studs of the sightline: centre lines clear; `props_r5` honestly
  flagged as partially screened by pines (~11.3 studs off-axis, the round-4 caveat), `sky_r5` looks up
  so off-axis grass does not block it. Screenshot pixels could not be retained this session
  (`screen_capture` returned `null`; a video probe showed HUD over a flat dark world and the game camera
  script overrides an injected `Scriptable` camera), so no visual claim or grade is made and any visual
  claim stays `UNVERIFIED` until a retained-screenshot/designer pass. Restores were run; nothing saved
  or published.
  - Write `REVIEW_ROUND5.md` with the toggles (dot syntax), datamodels and
  saved cameras. Check that every saved camera actually sees its subject (not hidden by trees or
  grass). The main session takes the Studio shots.
- [x] 43. **Refill.** Done 2026-11-20. Re-read this queue, the tracker, `docs/testing/BUGS.md` and
  `docs/testing/GATE1.md`. **No blocked item is agent-closable.** Every remaining blocker is one of:
  a licensed real asset ID that may not be invented, a shared Studio Importer / Open Cloud upload
  route, a designer/vision verdict, or designer hardware (phone emulator, five humans, a published
  place, a multi-client Local Server). No place saved or published; no ID invented. The re-check and
  the one final report are recorded below.

### Item 43 re-check of blocked items (2026-11-20)

| Item | Blocker that still stands | Agent-closable? |
|---|---|---|
| 4 buildings | real CC BY/CC0 Open Cloud IDs + Studio Importer + designer verdict | no |
| 5 vegetation | same visual/session gate; step-2 generation for three-stage padi | no |
| 6 props | wider set dressing needs the visual verdict and Studio Importer session | no |
| 7 textures | download → MaterialVariant → Open Cloud upload → designer verdict | no upload path |
| 8 NPCs | peci/batik/sarong still need builds; R15 validation + verdict | no (3 real free hat IDs landed in item 40, but no verdict) |
| 9 animations | shared Studio session / Designer builds; Quaternius licence conflict | no |
| 9b icons | new uploads through the approved Open Cloud route + image-input/vision review | no |
| 10b day-cycle live wiring | no licensed sound IDs for the 5 beds; no settings UI/persistence; visual verdict | no |
| 11 sky and fog | shipping sky needs a designer verdict on the licensed HDRIs now in the repo | no (CC0 HDRI IDs exist in `SkyMapR4`/`SkyMapR5`, still off by default, blank verdict) |
| 12 spawn view | no *approved* look to combine; fps proxy needs designer hardware; animations open | no (round 5 added more off-by-default candidates, still no verdict) |
| 14 VFX | V2 gate needs L7.1 particle textures; "after the frame is approved" | no |
| 15 raid moment | `police_walkin` verdict pending, frame unapproved, real assets + hardware | no |
| 16 budget/soak | no approved visuals to turn on; phone emulator + multi-client session | no (registry now 31 candidates, all off by default) |

Stale facts corrected during the re-check (blocker still stands): item 10b's "Rojo not running" no
longer applies — Rojo is running and Studio was successfully Rojo-synced this session; item 11's
"no licensed HDRI exists in the repo" is no longer true — the CC0 sets are in `SkyMapR4`/`SkyMapR5`
but remain gated behind a blank designer verdict; item 16's registry is 31 candidates, not 25.

`BUGS.md` has no open `blocker`/`major` defect. `GATE1.md` still has 2 `BLOCKED` (G4, Q5), 1
`LUNE-ONLY` (Q8) and 8 `UNVERIFIED` rows; every one of them needs the designer, a real device,
a human playtest, a published place or a multi-client Local Server, none of which is agent-closable.
The single final report is at `docs/v2/evidence/h/2026-11-20-final-report/FINAL_REPORT.md`.

### J. Round 6: sky pick, kampung vegetation, costumes, designer kit (added 2026-11-20 after the round-5 Studio review)

**Designer verdicts and notes, 2026-11-20** (recorded in `CANDIDATES.md`; shots in
`docs/v2/evidence/h/2026-11-20-review-round5/REVIEW_ROUND5_STUDIO.html`).

- **Spawn:** still flat. **The designer will compose spawn and sculpt the terrain himself.** The village
  is mostly flat but not perfectly flat. It should have gentle elevation like a real village (the sawah
  a little lower, for example). Agents do not dress spawn or sculpt the spawn terrain; they supply a kit
  instead (item 49).
- **Sky:** `sky_r5` is better. Compare it against free Creator Store skyboxes before choosing.
- **Ground:** fix the leftover asphalt, and stop the grass from covering the flower beds.
- **Characters:** the base is fine. Each role needs its own textured costume, for example a real police
  uniform for the polisi and batik for Pak RT. No more single-colour outfits.
- **Vegetation:** much denser, using what actually grows in an Indonesian kampung.
- **Textures:** still look strange.

**Sky best practice (main-session research, 2026-11-20).** A Roblox `Sky` is six cube faces. Our own
HDRI-to-cube conversion works, but it causes seams and the sun ends up out of place. Ready-made
Creator Store skyboxes are the safer route. A believable tropical look comes mostly from the layers
around the skybox:
- `Atmosphere`: Density about 0.25–0.35, humid Haze about 1–2, Color warm white, Decay light blue.
- Volumetric Terrain `Clouds`: Cover about 0.4–0.6 for cumulus.
- The sun stays on (`CelestialBodiesShown`), with soft `SunRays`, low `Bloom` and a slight saturation
  lift in `ColorCorrection`.

Prefer skies with cumulus in the upper half. The mirrored lower half doesn't matter, because the
terrain hides it.

**Real free Creator Store sky IDs** (found with Studio `search_asset`, 2026-11-20; licence = Creator
Store free model; strip any scripts on insert):

| ID | Name | Creator |
|---|---|---|
| 4607457995 | Realistic Sky | Xeksworld08 |
| 10256505900 | Sky-Realistic | Dev_Flowey |
| 9589448285 | Realistic Clear Sky | HeyItzDaredevil |
| 11219565245 | Realistic Clear Skies (SKYBOX) | TrainMaker6 |
| 71778157196658 | Blue Sky W Scattered Clouds Daytime Skybox | Rozosere48 |
| 79778158338852 | Sunless blue sky skybox realistic clouds | f0xz08 |

- [x] 44. **`sky_r6_a`…`sky_r6_f`, plus the `sky_r5` baseline.**
  - Load each Creator Store sky above on the server (`InsertService:LoadAsset`) and copy its six face
    IDs into `SkyMapR6`.
  - Record the ID, name and creator in `ASSET_MANIFEST.md`.
  - Apply the same atmosphere stack (above) to all of them.
  - Add one saved camera tilted up about 20°, so the sky fills half the frame.
  - Off by default; verdicts blank.
- [x] 45. **Ground fix (`spawn_ground_r6`).**
  - Turn the remaining back road strip into dirt.
  - Keep the grass decoration off the flower beds and plots (with a mask or a Terrain material choice).
  - Keep the stored road design as it is.
- [x] 46. **Terrain look rethink (`terrain_r6`).** The `textures_r4` overrides read as a red desert
  with straw grass, so drop the terrain-wide overrides.
  - Try the default Terrain materials with tuned `Terrain:SetMaterialColor`: lush green Grass, warm
    brown Ground, dark wet Mud for the sawah.
  - Keep CC0 textures only on parts and meshes (walls, roofs, wood).
  - Build two variants, `terrain_r6_a` and `terrain_r6_b`, with before/after shots from the spawn
    camera.
- [x] 47. **Kampung vegetation research and fill (`vegetation_r6`).**
  - Write `docs/v2/visual/KAMPUNG_VEGETATION.md`: what typically grows in a Javanese or Sundanese
    village yard and its edges, with reference photo links. Examples:
    - trees and crops: pisang, bambu, mangga, jambu air, rambutan, pepaya, nangka, singkong
    - ground cover and ornamentals: talas/keladi, pandan, puring, kembang sepatu, lidah mertua in pots
    - edges: a teh-tehan hedge (*pagar hidup*), alang-alang at the field edges
  - Source free models through the ladder (Creator Store first, then CC0). Record the real IDs; never
    invent one.
  - Build dense clusters along the yard edge, hedge line, fence line and sawah edge. Respect the
    exclusion zones and stay within the tier budgets.
  - Stage the clusters where the saved camera actually sees them.
- [x] 48. **Villager costumes (`npcs_r6`).** Each of the five R15 villagers gets a role-specific,
  textured outfit:

  | Role | Outfit |
  |---|---|
  | polisi | real Indonesian police uniform: brown shirt and trousers, plus a cap if one is available |
  | Pak RT | batik shirt and peci |
  | petani | caping, faded shirt, rolled-up trousers |
  | pedagang | apron or kaos |
  | petani wanita | kebaya-style top or headscarf |

  - **Route A:** free catalog or Creator Store clothing whose IDs come from a real search.
  - **Route B:** original classic-clothing templates (the Shirt/Pants template layout) drawn by script,
    uploaded as Images via Open Cloud and set as `Shirt.ShirtTemplate` / `Pants.PantsTemplate`.
  - Fix the 0-accessory bug: the three round-5 hat IDs never attach.
  - Turn the villagers to face the saved camera.
- [x] 49. **Designer kit (no spawn dressing).**
  - Put every approved or temporary asset in one tidy folder the designer can drag from, for example
    `ServerStorage.DesignerKit` or a Studio-only `ReplicatedStorage.DesignerKit`. Include:
    - pisang, the jemuran and the karung semen stack
    - `buildings_r4` (temporary)
    - the R15 villagers
    - the best vegetation clusters
  - Each item is anchored, pivoted at its base, true to scale and named in Indonesian.
  - Add a short `DESIGNER_KIT.md` on how to use the kit.
  - Add a one-page terrain brief, `TERRAIN_BRIEF.md`, with suggested elevation bands to support the
    designer's own sculpt. It is advice only. For example:
    - sawah 1–2 studs lower
    - yards at grade
    - a slight rise toward the warung and pasar
    - drainage ditches along the paths
- [x] 50. **Props: tools at real size (`props_r6`).**
  - The round-5 tools got smaller (gerobak 3.0 studs, sumur 2.5). Scale them with `Model:ScaleTo` to
    real targets:

    | Prop | Target |
    |---|---|
    | gerobak | about 6 studs tall, 8 long |
    | sumur | about 4–5 studs tall |
    | cangkul | about 4.5 studs |

  - Add a spec that reads the actual `GetBoundingBox` sizes and compares them with the targets.
  - Move the props' saved camera out from behind the pines.
- [x] 51. **Review handoff.** Write `REVIEW_ROUND6.md` with the toggles, datamodels and cameras. The
  main session takes the Studio shots.
- [x] 52. **Refill.** Re-read the tracker, `WORK_QUEUE.md`, `BUGS.md` and `GATE1.md` after items 44–51:
  Gate 1 unchanged (2 `BLOCKED` G4/Q5, 1 `LUNE-ONLY` Q8, 8 `UNVERIFIED`), no open `blocker`/`major`
  bug and no agent-closable row. Remaining rows need designer vision, a real device, a published place
  or tracks C/G/E art. Round-6 shots and verdicts belong to the designer from `REVIEW_ROUND6.md`.

### K. Round 7: make it actually work (added 2026-11-20 after the round-6 Studio review)

**Designer verdicts, 2026-11-20** (shots: `docs/v2/evidence/h/2026-11-20-review-round6/REVIEW_ROUND6_STUDIO.html`):

- **Sky:** `sky_r6_e` is chosen.
- **Ground:** `spawn_ground_r6` is chosen. `terrain_r6_a/b` are rejected.
- **Everything else:** the designer agrees with the main-session notes in `STUDIO_REVIEW.md`.

**Why this round exists.** The same four defects have now survived two or three rounds:

| Defect | Rounds failed |
|---|---|
| hats are 0 | R5, R6 |
| vegetation is sparse | R5, R6 |
| props can't be seen from the saved camera | R4, R5, R6 |
| grass covers the flower beds | R5, R6 |

Lune specs passed every time, because they check data, not the scene. The designer said: *"berkali kali tapi tetep gaprogress."* The rules below are not optional.

**Root cause, found in the Studio console on 2026-11-20 (SEEN-IN-STUDIO).**

- At runtime, `InsertService:LoadAsset` fails with `User is not authorized to access Asset` for every Creator Store model the place owner doesn't own:
  - all three hat IDs: 71002247087415, 126970096704856 and the caping;
  - five vegetation IDs: 15344074131, 8864962424, 184362803, 361802126 and 9639782964.
- The appliers `pcall`-warn and carry on, so the failure was invisible and the scene came out sparse or hatless.
- In the **Edit** datamodel, `game:GetObjects("rbxassetid://<id>")` loads the same IDs fine. Tested: 71002247087415 returns a MeshPart, 126970096704856 an Accessory, 15344074131 a Model, 8864962424 a MeshPart.

**Hard rules for section K (these override any habit from earlier rounds):**

1. **Studio proof is required.**
   - An item is ticked only when its `CHECK` lines print `PASS` in a real Studio Play session, run through `execute_luau`.
   - The raw output goes in `docs/v2/evidence/h/<date>-round7/CHECK_<item>.txt`, committed.
   - A Lune spec alone never ticks a section K item.
2. **Two failed attempts mean BLOCKED.** If a check still prints `FAIL` after two fix attempts, mark the item `BLOCKED — <paste the FAIL line>` and move on. Never tick a FAIL, and never weaken the check so that it passes.
3. **Failures must be loud.**
   - Every model applier keeps a `failures` count, and the check reads it.
   - Any load failure is a FAIL.
   - Don't `pcall`-and-continue silently.
4. **Use exact numbers.** Use the coordinates, counts and colours given below. Where a number is missing, choose one, write it in the item, and test it.
5. **The designer grades visuals.** Don't grade them yourself. Do run every objective check.

- [x] 53. **Check harness first: `tools/studio/review_check_r7.luau`.** PASS — all eight checks printed in real Studio Play Server VM; raw output `CHECK_53.txt` / `ATTEMPT2_console_raw.txt`.
  - One script, run with `execute_luau` in the **Server** datamodel during Play, prints one line per check: `CHECK <name> PASS|FAIL <measured> <target>`.
  - It must implement every check named in items 54–58: `LOAD_FAILURES`, `SKY_DEFAULT`, `GRASS_ON_BEDS`, `HATS`, `PROPS_VISIBLE`, `PROPS_ON_GRASS`, `VEG_COUNT` and `VEG_SPECIES`.
  - Visibility is measured with `workspace:Raycast` from the saved camera position to each subject's bounding-box centre:
    - exclude the subject itself and the player characters;
    - a subject counts as visible when nothing else is hit first, and it lies inside a 70° cone around the camera's look vector.
  - Grass is measured with `Terrain:ReadVoxels` on a 4×4-stud cell under each sample point. The material must not be `Enum.Material.Grass`; only Grass grows decoration blades.
  - Document how to run it in `REVIEW_ROUND7.md`.
- [x] 54. **Edit-time asset bake: replace runtime LoadAsset.** PASS — Route A refused (403 `Scope not authorized`), Route B Edit-mode bake used; `CHECK LOAD_FAILURES PASS 0 0` (`CHECK_54.txt`), no `not authorized` in console.
  - **Route A (preferred, durable):**
    - A Lune script uses the Open Cloud asset-delivery API with `ROBLOX_API_KEY` to download each model ID as a `.rbxm` into `assets/lookdev/<id>.rbxm`.
    - It strips every `Script`, `LocalScript` and `ModuleScript` with Lune's `roblox` library.
    - Map `assets/lookdev` to `ServerStorage.LookDevAssets` in `default.project.json`.
    - If the API refuses with 401, 403 or 404, record the exact response in the item and use Route B.
    - **Route A attempt 2026-11-20:** `GET https://apis.roblox.com/asset-delivery-api/v1/assetId/134692206104779` returned `HTTP 403 {"errors":[{"code":0,"message":"Scope not authorized."}]}` (key present, `x-api-key` sent; `skipSigningScripts` query corrected to a string). The API key lacks `legacy-asset:manage`. Using Route B.
  - **Route B (fallback):**
    - `tools/studio/bake_lookdev_assets.luau` runs in the **Edit** datamodel through `execute_luau`.
    - For every model and hat ID in `ModelMap*R4/R5/R6`, it calls `game:GetObjects`, strips the scripts and parents the result to `ServerStorage.LookDevAssets.<id>`.
    - This bake must be run before each review. Put it as step 1 of `REVIEW_ROUND7.md`.
    - Don't save the place.
  - **All model appliers:** clone from `ServerStorage.LookDevAssets` first and use `LoadAsset` only as the fallback.
  - **CHECK `LOAD_FAILURES` = 0** after enabling `vegetation_r7`, `npcs_r7` and `props_r7` in turn. The console must not contain `not authorized`.
- [x] 55. **Promote the approved picks to the default look.** PASS — fresh Play with no enable call: `SKY_DEFAULT PASS rbxassetid://2835177931`, `GRASS_ON_BEDS PASS 0 0` (`CHECK_55.txt`).
  - **Sky:** `sky_r6_e` plus its atmosphere stack becomes the shipping sky, applied at startup with no `enable` call.
  - **Ground:** `spawn_ground_r6` becomes the shipping ground.
  - **Candidates:** keep the remaining sky and terrain candidates as OFF candidates. `terrain_r6_a` and `terrain_r6_b` stay rejected and are not used.
  - **Flower beds:** under every flower bed and crop plot centre (read the real positions from MapSpec), paint the voxels to `Enum.Material.Ground`, or to `LeafyGrass` if it shows no blades. Use a box the size of the bed plus 1 stud.
  - **CHECK `SKY_DEFAULT`:** in a fresh Play with no enable call, `Lighting.Sky.SkyboxFt` equals sky E's Ft face.
  - **CHECK `GRASS_ON_BEDS` = 0:** every bed and plot centre has a non-Grass voxel.
- [x] 56. **`npcs_r7`: hats and real costumes.** This needs item 54. PASS — `CHECK HATS PASS 4 4` (`CHECK_56.txt`); four real R7 costume Image IDs uploaded and wired; designer PASS on PNGs + 2×2 sheet.
  - **Hats:**
    - Attach with `Humanoid:AddAccessory` from the baked Accessory.
    - If a baked asset is a bare MeshPart, wrap it in an `Accessory`, add a `Handle` and a `HatAttachment` matching the head's `HatAttachment`, then call `AddAccessory`.
    - **CHECK `HATS`:** petani ≥1, petani_wanita ≥1 and polisi ≥1 Accessory children, and Pak RT ≥1 (the peci).
  - **Peci:** search the Creator Store with `search_asset` for "peci", "kopiah" and "songkok". If no free one exists, build an original peci as the last resort:
    - a black `Part` 1.1×0.55×0.95 with `SpecialMesh` `MeshType=Cylinder` or a rounded `Block`;
    - Material `Fabric`, Color `#1A1A1A`;
    - welded to the head, sitting straight on top.
  - **Pak RT batik:** redraw the shirt template, 585×559 classic layout, as a real batik motif. Either:
    - *parang:* diagonal S-curved bands at 45°;
    - *kawung:* four-oval rosettes in a grid.

    Use at least 3 colours: sogan brown `#5C3A1E`, cream `#E8D9B5` and indigo `#2B3A55`. Fill the torso and both sleeves with the motif. Dots on a plain field are not acceptable.
  - **Polisi:**
    - Shirt: brown `#6B4A2B`, darker seams `#4E3520`, two chest pockets with flaps, shoulder epaulettes, a name tag on the right chest and a small badge on the left chest.
    - Pants: the same brown, with a black belt `#151515` and a buckle.
  - **Upload and preview:**
    - Upload the new templates as Images and record their IDs in `ASSET_MANIFEST.md`.
    - Commit the PNGs, plus a 2×2 contact sheet at `docs/v2/visual/art/models_r7/npcs/COSTUMES_SHEET.png` for the designer.
  - Keep the villagers facing the camera, spaced 4 studs apart.
- [x] 57. **`props_r7`: restage where they can be seen.** PASS — `PROPS_VISIBLE PASS 6 6`, `PROPS_ON_GRASS PASS 0 0` (`CHECK_57.txt`) after `front` 18→28 camera correction.
  - **Placement:**
    - Move all props out of the pine stand to an open yard with no tree or pine trunk within 15 studs.
    - Choose the spot by scanning `workspace` for tree models in code.
    - Lay them out in one row 6 studs apart, gerobak first, then sumur, lapak, pagar bambu, alat tani and jemuran.
    - Paint a `Ground` voxel pad under each prop: footprint plus 2 studs.
    - Keep the real sizes from round 6: gerobak 6 tall, sumur 4.5, cangkul 4.5.
  - **Camera:** place the saved camera 18 studs in front of the row and 7 studs up, looking at the row's centre at y=2.
    - **Attempt-2 correction 2026-11-20:** at `front=18` the two row ends (x≈±15) sat ~39° off the look axis, outside the 35° half-cone, so the real Studio check printed `PROPS_VISIBLE FAIL 4 6`. The camera rule was moved to `front=28` (applier `ReviewCameraPos` = row centre +28 Z / +7 Y), putting the worst end ~28° inside the cone with ~7° margin; the harness and its 70° cone were not changed. `PROPS_VISIBLE PASS 6 6` in `CHECK_57.txt`.
  - **CHECKS:**
    - `PROPS_VISIBLE` = 6/6;
    - `PROPS_ON_GRASS` = 0.
- [x] 58. **`vegetation_r7`: really dense.** This needs item 54. PASS — `VEG_COUNT PASS 67 60`, `VEG_SPECIES PASS 10 8`, `LOAD_FAILURES PASS 0 0` (`CHECK_58.txt`) after adding 20 far-band cells.
  - **Targets** within 100 studs of the saved camera and inside its 70° cone:
    - at least **60** plant model instances;
    - at least **8** distinct species, taken from `KAMPUNG_VEGETATION.md`.
  - **Composition:**
    - a continuous teh-tehan hedge along the fence line, one instance every 2 studs;
    - **at least 3** bambu clumps of 5–7 culms each;
    - **at least 6** pisang;
    - kembang sepatu and puring in front of every house;
    - talas and keladi along the ditches;
    - lidah mertua in pots by the doors;
    - alang-alang on the sawah verge.
  - **Placement rules:**
    - Respect the exclusion zones (paths, plots, plaza).
    - Random yaw.
    - Scale jitter of ±15%.
    - No two instances closer than 1.2 studs.
      - **Attempt-2 correction 2026-11-20:** at the original far-band positions the yaw-rotated bounding-box centres drifted past the 100-stud radius under the harness, so `VEG_COUNT FAIL 53 60`. Added 20 far-band cells at x=±40, z=66..84, all ≥2 studs apart and safely inside the cone/radius, and tightened the self-check min pair distance from 1.2 to 2 studs (stricter, not weaker). The harness was not changed. `VEG_COUNT PASS 67 60` in `CHECK_58.txt`.
  - **Budget:** stay inside the Sedang tier budget.
  - **CHECKS:**
    - `VEG_COUNT` ≥ 60;
    - `VEG_SPECIES` ≥ 8;
    - `LOAD_FAILURES` = 0.
- [x] 59. **Review handoff.** `REVIEW_ROUND7.md` documents bake step, toggles/datamodels/cameras and every `CHECK_*.txt` path; shots taken by main session.
  - Write `REVIEW_ROUND7.md`:
    - step 1 is the bake (if Route B);
    - then the toggles, datamodels and cameras;
    - then the path of every `CHECK_*.txt`.
  - The main session takes the shots.
- [x] 60. **Refill.** 2026-11-20: re-read `BUGS.md` (no open blocker/major) and `GATE1.md` (G4/Q5 BLOCKED, Q8 LUNE-ONLY, 8 UNVERIFIED) — no agent-closable row, nothing new queued.

### L. Round 8: fix what the round-7 Studio review found (added 2026-11-21)

Source: `docs/v2/evidence/h/2026-11-21-review-round7/STUDIO_REVIEW.md` (SEEN-IN-STUDIO, shots in `shots/`). Section K's hard rules apply unchanged: Studio PASS lines in `docs/v2/evidence/h/<date>-round8/CHECK_<item>.txt`, two failed attempts mean BLOCKED, never weaken a check. The designer grades visuals; the main session takes the shots.

Designer verdicts: sky E, ground, and the catalog outfits (commit 4408a04) are approved. Do not touch NPC outfits.

- [x] 61. **Sky is hidden by clouds.**
  - The shipping sky is E, but `Terrain.Clouds.Cover` is 1 in the live scene, so the skybox is invisible. Setting 0.5 on the client showed sky E correctly.
  - Set `Cover = 0.5` in the shipping look. Look at `src/client/World/Sky.luau` (the day-cycle preset `cloudCover` overrides it every tick, so fix the preset, not only the one-off write), `src/shared/World/DayCycle.luau` and `src/shared/Config/Seasons.luau`.
  - Keep `badai` and `hujan` weather overlays raising Cover; only the clear-day base changes.
  - **CHECK `CLOUD_COVER`:** in a fresh Play with no enable call, after 10 s, `workspace.Terrain.Clouds.Cover` is between 0.4 and 0.6 at ClockTime 13. Add it to `tools/studio/review_check_r7.luau` as a client check and document it.
- [x] 62. **Flower beds are raised mounds.**
  - `ShippingLookR7.luau` fills `Ground` voxels with `FillBlock` and adds volume, so each bed is a dirt mound. Paint the material at grade instead: `Terrain:ReadVoxels` the region, keep each voxel's occupancy, and `WriteVoxels` with the same occupancy and `Enum.Material.Ground` (only where the voxel is not air). No volume added.
  - **CHECKS:** `GRASS_ON_BEDS` still 0, plus new `BED_FLUSH`: the terrain surface height at every bed centre differs by at most 0.5 stud from a point 6 studs outside the bed (raycast down).
- [x] 63. **Vegetation: dense in the near and mid ground.**
  - 67 instances pass, but most are small far shrubs. Add a near-ground layer.
  - **CHECK `VEG_NEAR`:** at least 25 plant instances within 45 studs of the saved camera and inside the 70° cone, at least 6 species among them, none smaller than 2 studs tall.
  - Reuse the baked assets. Respect exclusion zones and the 2-stud spacing. Do not drop `VEG_COUNT` or `VEG_SPECIES`.
- [x] 64. **Props: better models, visible.**
  - The cangkul slot is an axe, the gerobak is a small modern wheelbarrow, and the pagar bambu barely shows.
  - Follow the asset ladder: check already-baked IDs first, then Creator Store via Edit-mode `GetObjects`, then `generate_mesh`. Needed: a real cangkul (hoe with a long wooden handle), a traditional wooden gerobak (two-wheel hand cart), a pagar bambu at least 8 studs long and 3 tall.
  - Record new IDs in `ASSET_MANIFEST.md` and add them to the bake list.
  - **CHECKS:** `PROPS_VISIBLE` 6/6, `PROPS_ON_GRASS` 0, plus `PROP_SIZE`: gerobak 4–6 studs long, cangkul 3.5–4.5 tall, pagar 8+ long.
- [x] 65. **Process fix.** `ServerStorage.LookDevAssets` survived a Studio restart, so the place was probably saved after the bake. Add a step to the review doc: the bake must not be saved, and say how to check that. Do not save the place yourself.
- [x] 66. **Review handoff.** Write `REVIEW_ROUND8.md` (bake, toggles, datamodels, cameras, every `CHECK_*.txt` path). The main session takes the shots.
- [x] 67. **No-op marker.** Tick this when items 61–66 are done; section M follows and holds the real refill (item 101).

### O. Round 9 fixes and the canonical-map look (added 2026-11-21 after the main-session Studio review of round 9)

**Do section O first, before the unticked items of section M (79 onward).** Section O fixes what the designer saw in Studio. Evidence: `docs/v2/evidence/h/2026-11-21-review-round9/` (`REVIEW_ROUND9_STUDIO.html`, `STUDIO_REVIEW.md`, `shots/`). Same rules as sections K and M apply. Items are numbered 136 onward.

**Designer verdicts, 2026-11-21 (recorded in `CANDIDATES.md`):**

| Candidate | Verdict |
|---|---|
| `buildings_r8` | **yes**: real buildings are far better than greybox. |
| `hubveg_r8` | **yes, densify**. |
| `facades_r8` | **yes, fix the stray pole**. |
| `water_r8_a` | **yes**: chosen river water. `water_r8_b` is kept only as the rain-season reference; `water_r8_c` is **no**. |
| `river_r8` | **partial**: keep bridge rails and stepping stones, redo the bank plants. |
| `sawah_r8` | **no**: tufts read as long green bars, no padi or gubuk visible. Redo. |
| `pathedge_r8` | **no**: pieces sit in the middle of the road. Redo. |
| `plots_r8` | **redo**: the fences are barely visible. |

**The target look: the canonical map.** The designer says `docs/v2/visual/art/map/map-plan-canonical.png` is the best picture of the intended village (the mood boards and `full-package/` sometimes contradict it; where they do, the canonical image wins on *look*, and `MapSpec.luau` stays the authority on *coordinates*). You can't read images, so this is what it shows. Treat it as the checklist for round 9 and 10:

- **Green everywhere.** The ground between buildings, plots and the ring road is full of medium and large round-canopy trees (about 8–12 studs), small shrubs and flower patches. The outer ring and the hills are a thick wall of broadleaf trees, with palms near the river and the corners. No pines.
- **Sawah.** Four stepped terraces along the north, each a long green band of rice rows with blue water between the rows and a grassy bund. A balai desa stands in the middle gap.
- **Plots.** Each plot is a fenced square with a gate, a scarecrow, a mailbox with a sign, a small irrigation ditch and a hut nearby. The fence is clearly visible from the road.
- **Paths.** Warm dirt paths that curve, with grass right up to the edge. A round ring road connects the hubs; a wide road leads south to the bridge.
- **Hubs.** The Pasar has a red roof and many striped red/white/blue stall awnings around it. The Warung is a cluster of tin-roof stalls and tables. Pos Polisi is blue-roofed. Pos Ronda is a bamboo tower. Pak RT's house has a yellow-orange roof. The central Lapangan has a small fountain or monument, bunting and umbrellas.
- **River.** A wide blue river with rocks, palms and a bamboo bridge about 8 studs wide.
- **Atmosphere.** Warm light, golden hour feel, a hazy blue-green hill ring.

Never copy the image into the game. Use it to decide *what* to add.

#### O1. Tools and bug fixes

- [x] 136. **Additive review staging.** `LookDevReview.enable(id)` keeps only one candidate active (enabling a second one disables the first), which made the main session stage the round-9 candidates one at a time. Add `LookDevReview.enableAdditive(id, game)` that stages a candidate without disabling the others, and `LookDevReview.disableAll()`. Existing `enable`/`disable` behaviour is unchanged. **CHECKS:** `ADDITIVE_STAGE`: stage `hubveg_r8`, `plots_r8` and `facades_r8` together and each has its parts present; `LOOKDEV_LEAK` PASS after `disableAll`. Document it in `REVIEW_ROUND9.md`.
- [x] 137. **Promote `water_r8_a` to the default look.** The designer chose A. Apply its values at startup with no `enable` call (client side, next to the shipping sky). Keep `water_r8_b` as a candidate named for the rain season and mark `water_r8_c` rejected in `CANDIDATES.md`. **CHECKS:** `WATER_DEFAULT`: in a fresh Play with no enable call, the terrain water properties equal variant A's values; `WATER_RESTORE` still PASS for b.
- [x] 138. **Item 102 is pulled forward: replace the pine backdrop now.** Do item 102 here, in full (default look, tropical trees, `forest_pines_legacy` candidate, `ring_r8` unblocked). Use the canonical look as the target: a **thick wall** of broadleaf round-canopy trees (8–12 studs, at least 3 species, plus palms on the river side) around the ring and on the hills, at least **250** instances in total, still inside the Rendah budget through item 104's thinning. Tick item 102 and this item together. **CHECKS:** as item 102, plus `RING_COUNT` ≥ 250.
- [x] 139. **`facades_r8` stray pole.** In the Pak RT shot a long yellow diagonal pole floats above the roof. Find which facade part it is (name it in the commit message), then fix its size, orientation or parent, or remove it if it is a bad ridge cap. Check every other hub for the same defect. **CHECKS:** `FACADE_STRAY`: for each hub, every `FacadePart`'s bounding box is inside the hub's bounding box grown by 3 studs, none extends more than 1 stud above the ridge, and none is longer than 12 studs; `FACADE_PARTS` and `DOOR_CLEAR` still PASS.

#### O2. Redo the rejected candidates

- [x] 140. **`sawah_r8` redo.** The current verge tufts are long flat bars and nothing reads as padi. Rebuild against the canonical look: on each of the four terraces, **rows of padi clumps** (small baked rice or grass-clump models, or small clusters of 3–5 thin blades; each clump at most 1.5 studs wide), one row every 2 studs along the terrace, so each terrace reads as a green band; keep the thin water sheet visible *between* the rows; a grassy bund on the terrace edge; the gubuk on terrace 2; stepping stones. **CHECKS:** `TUFT_SHAPE`: no padi or tuft part has any dimension over 2.5 studs; `PADI_ROWS` ≥ 10 rows per terrace and ≥ 250 clumps per terrace; `SAWAH_GREEN`: from the `sawah_above` camera at least 40% of the sampled terrace points (a 20 × 8 grid per terrace, raycast down) hit a padi part; `SAWAH_TOPS` unchanged; `GUBUK` = 1.
- [x] 141. **`river_r8` bank plants redo.** Keep the bridge rails and stepping stones. Replace the thin green posts with real plants from the baked list (talas, keladi, alang-alang, bambu clumps, palm / kelapa): at least **40** instances within 40 studs of the bridge on both banks, at least **4** species, at least **6** bamboo clumps or palms at 8+ studs tall, plus **12** boulders (1–4 studs, half-buried, two rock models) along the banks. **CHECKS:** `RIVER_BANK_VEG` ≥ 40; `BANK_PLANT_SHAPE`: no plant is thinner than 0.8 studs at its base or shorter than 1.5 studs; `RIVER_ROCKS` ≥ 12; `BRIDGE_WALKABLE` ≥ 8.
- [x] 142. **`pathedge_r8` redo.** The pieces sit in the middle of the dark road. Compute each path's centreline and half-width from `MapSpec`, and place pieces at a lateral offset of half-width + 0.3 to half-width + 2.5 on both sides, using real grass-clump models (at most 1.5 studs wide), pebbles and small stones; the grass must reach the path's edge, as in the canonical map. **CHECKS:** `PATH_EDGE_OFFSET`: every piece's distance from the nearest path centreline is between half-width and half-width + 3; `PATH_CLEAR`: nothing with `CanCollide` true inside the central 6 studs; `PATH_EDGE` ≥ 120.
- [x] 143. **`plots_r8` redo.** From the road the fence is barely visible, and the saved gate camera sat among the pines. Rebuild the plot dressing to the canonical plot module: a **3-stud-tall** bamboo fence with posts every 4 studs and two rails, a gate with a visible lintel and a name sign, a scarecrow, a mailbox with a small sign, a 2-stud irrigation ditch along the outer edge (thin water sheet), and a small gubuk in the corner of three plots. Add cameras `plot_aerial_01..10` (30 studs up, 40 studs back along the connector road) to `ReviewCameras`. **CHECKS:** `PLOT_FENCE` ≥ 8 segments per plot; `PLOT_FENCE_VISIBLE`: from each `plot_aerial_NN` camera at least 70% of that plot's fence segments are visible (raycast); `GATE_CLEAR` and `CAMERA_CLEAR` still PASS.
- [x] 144. **`hubveg_r8` densify.** The shot showed one small bamboo clump and three shrubs in front of the Warung. Target the canonical look: per hub, at least **30** instances within 40 studs, at least **2** large canopy trees (mangga, beringin or similar, 8–12 studs tall), **2** pisang groups of 3, **2** bamboo clumps of 5–7 culms with each culm 10+ studs tall, flower beds and shrubs near each door. No instance blocks a door or the 6-stud walking lane. **CHECKS:** `VEG_HUB_<hub>` ≥ 30; `HUB_TREES` ≥ 2 trees at 8+ studs per hub; `VEG_OVERLAP` = 0; `DOOR_CLEAR`; `PATH_REACH` to every hub door.
- [x] 145. **`blocks_r9`: fill the village blocks with trees.** In the canonical map the grass between the ring road, the plots and the hubs is full of medium trees and shrub patches. Add at least **60** trees (6–12 studs) and **80** shrubs/flower patches in those blocks, at least 4 tree species, random yaw ±15% scale, 3-stud minimum spacing, none inside a building footprint, path, plot, plaza or exclusion zone. **CHECKS:** `BLOCK_TREES` ≥ 60; `BLOCK_SPECIES` ≥ 4; `VEG_OVERLAP` = 0; `PATH_REACH` and `AVATAR_FIT` still PASS; `PERF_BUDGET` recorded.

#### O3. Adopt and dress, following the canonical map

- [x] 146. **Building kit from `buildings_r8` (the designer said yes).** The designer composes the spawn himself, so make the six real buildings easy to place. Write `docs/v2/visual/art/BUILDING_KIT.md`: per building, its ID, licence, bounding size, door position and facing, and the hub it suits (match them to the canonical roofs: red-roof Pasar, tin-roof Warung, blue-roof Polisi, yellow-roof Pak RT). Make each baked model's pivot sit at ground level at the centre of its footprint, facing -Z (front door toward the plaza). **CHECKS:** `PIVOT_GROUND`: each pivot's Y equals the base within 0.2 studs; `BLDG_VISIBLE` 6/6 still PASS.
- [x] 147. **`hubs_real_r9`: real buildings on the hubs (candidate, off by default).** For each hub, stage the matching real building scaled to fit inside the hub's `MapSpec` footprint, and hide the greybox hub body while keeping its sign. Skip any hub that has no good match and say so. This is only a candidate for the designer to compare. **CHECKS:** `HUB_FIT`: each staged building inside its footprint grown by 2 studs; `DOOR_CLEAR`; `PATH_REACH` to each door; `LOOKDEV_LEAK` PASS (the greybox hub is shown again on `disable`).
- [x] 148. **`pasar_awnings_r8`: Pasar stalls and awnings.** Around the Pasar, at least **10** lapak stalls with striped red/white/blue awnings (alternating coloured parts, no real brand), counters with goods (crates of vegetables, baskets, hanging cloth), and lamps. Use baked or generated stall models where they exist, otherwise original parts. **CHECKS:** `STALLS` ≥ 10; `AWNING_STRIPES` ≥ 30 parts; `LANE_CLEAR` for a 6-stud lane; `PROPS_ON_GRASS` = 0 (paved or dirt pad under each stall).
- [x] 149. **`plaza_r9`: central plaza dressing.** The Lapangan in the canonical map has a small fountain or monument at the centre, bunting, umbrellas and benches. Add a fountain with a simple water-colour disc, 4 benches, 4 striped umbrellas, a bunting string between 2 poles, and one large shade tree at the edge. Respect the 38 × 28 plaza and keep the 6-stud lanes. **CHECKS:** counts per kind; `LANE_CLEAR`; `PATH_REACH` across the plaza.
- [x] 150. **`ronda_tower_r9`: Pos Ronda tower to the brief height.** `RECONCILIATION.md` row 6 says the position stays as in `MapSpec` and the height follows the brief (28–32 studs, 8 × 8 base, bamboo, with a kentongan at the top and a ladder). Build it as a candidate over the greybox tower. **CHECKS:** `TOWER_HEIGHT` between 28 and 32; the base footprint is within 8 × 8 studs plus 1; it doesn't clip the ring road (`PATH_CLEAR`); `LOOKDEV_LEAK` PASS.
- [x] 151. **`rocks_r9`: boulders and stones.** Scatter at least **25** rocks (1–4 studs, two or three models from the baked kit or generated, half-buried) along the river, the hill foot and field edges, none on paths. **CHECKS:** `ROCK_COUNT` ≥ 25; `ROCK_SPECIES` ≥ 2; `PATH_CLEAR`; none within 2 studs of a plot gate.

#### O4. Verdicts and review

- [x] 152. **Record the verdicts.** Make sure `CANDIDATES.md` holds the table above (the main session wrote the first version): `**yes**`, `**no**` or `**pending**` at the start of each cell. For new candidates in this section use `pending`. A spec checks the format.
- [x] 153. **Camera additions.** Add to `REVIEW_CAMERAS.md` and `ReviewCameras.luau`, derived from `MapSpec`: `plot_aerial_01..10`, `pasar_awnings`, `plaza_centre`, `ronda_tower`, `river_rocks`, `forest_wall` (from the village edge toward the hills), and `canonical_overview` (a high 3/4 view from the south over the bridge looking north across the whole village, similar to the canonical map). **CHECK `CAMERA_CLEAR`** for the full set.
- [x] 154. **Canonical gap report.** Write `docs/v2/visual/CANONICAL_GAP.md`: a table of every feature in "The target look" list above, with *present in the default look / present as a candidate (id) / missing*, and the evidence file. Don't judge looks; state presence and counts only. List the missing features as proposals at the end (visual-only; no gameplay).
- [x] 155. **Review pack for section O.** Add the section O candidates to `REVIEW_ROUND9.md` and `SHOT_LIST.md`: the `enableAdditive` sequence (item 136) for the all-together shot from `canonical_overview`, then each candidate alone from its own camera, and every `CHECK_*.txt` path. The main session takes the screenshots.

### M. Round 9: dress the whole village (added 2026-11-21, long unattended run)

The designer reviews the results one candidate at a time afterwards, so produce **many separate, toggleable candidates** and do not wait for approval between items. Order matters: do them top to bottom.

**Rules for section M** (on top of section K's hard rules, which stay in force):

1. **Candidates, not defaults.** Every new look ships as a `LookDev` candidate, off by default, with a row in `CANDIDATES.md` (verdict cell `pending`), its id in `LookDev.IDS`, a spec under `tests/specs/`, and the `LookDev.IDS` count assertion bumped. Only bug fixes (section L) change the shipping look.
2. **Studio proof per item.** Scene-affecting items need `CHECK_<item>.txt` from real Studio Play under `docs/v2/evidence/h/<date>-round9/`. If Studio is unreachable, mark that item `BLOCKED — Studio unavailable` and continue with items that don't need it. Never tick on Lune alone.
3. **Don't touch:** the terrain sculpt (the designer does it), NPC catalog outfits from commit 4408a04, the chosen sky and ground, or anything gameplay. No gameplay feature before Gate 1.
4. **Real assets only.** Follow the asset ladder. Never invent an ID. Record every ID and licence in `ASSET_MANIFEST.md`. Creator Store models load through the Edit-mode bake (`tools/studio/bake_lookdev_assets.luau`), never runtime `LoadAsset`. Do not save the place.
5. **Clean up.** `disable()` must restore the exact prior state (items 68 and 98 check this). Budgets: Sedang tier unless the item says otherwise.
6. **Review camera.** Every candidate names its review camera from `REVIEW_CAMERAS.md` (item 69) in its `CANDIDATES.md` row, so the main session can shoot it without guessing.
7. **Commit per item**, topical, no attribution lines, tracker line updated, tests 0 failures, selene 0/0/0, stylua only on changed files.

#### M1. Tools first

- [x] 68. **Check harness r8.** Create `tools/studio/review_check_r8.luau`, reusing r7's helpers: `CHECK <name> PASS|FAIL <measured> <target>` lines, `visibleCount(subjects, cameraCF)` (raycast + 70° cone), `countNear(tag, origin, radius)`, `grassAt(pos)`. Add a `LOOKDEV_LEAK` check: for each candidate id, count `workspace:GetDescendants()` and `Lighting:GetDescendants()`, `enable`, `disable`, and count again; PASS only if equal. Document the run order in `REVIEW_ROUND9.md`.
- [x] 69. **Review cameras.** Write `docs/v2/visual/REVIEW_CAMERAS.md` and `src/shared/ReviewCameras.luau` with at least **24 named cameras** derived from `MapSpec.luau`, never hand-typed numbers: spawn (current saved), each of the six hubs at a 3/4 view 28 studs out and 9 up, each plot gate, the river bridge from both banks, sawah terraces from below and from above, the hill ring looking in, and a golden-hour and a night variant for spawn and Pasar. Each entry has position, look-at, and the datamodel to use. **CHECK `CAMERA_CLEAR`:** from every camera, a ray to its target hits nothing opaque within the first 6 studs (not inside a wall or tree). Fix any that fail by moving the camera, not by weakening the check.

#### M2. Land and water

- [x] 70. **`hubveg_r8`: vegetation per hub.** For each of the six hubs, add dressing from the baked species list (`KAMPUNG_VEGETATION.md`): at least **12** instances within 40 studs of the hub centre, at least **4** species, none inside a building's bounding box, path, plot or exclusion zone, 2-stud minimum spacing, random yaw, ±15% scale. **CHECKS:** `VEG_HUB_<hub>` ≥ 12 for each hub; `VEG_SPECIES_HUB` ≥ 4 for each; `VEG_OVERLAP` = 0 (no instance bounding box intersects a building or path).
- [x] 71. **`plots_r8`: plot fences and gates.** Along each plot's edge (footprint and gate radius from `MapSpec`) place bamboo fence segments with a gap at the gate, plus a simple gate arch built from two posts and a lintel. Fence segments overlap their neighbours by 0.2 studs, no z-fighting. **CHECKS:** `PLOT_FENCE` ≥ 6 segments per plot; `GATE_CLEAR`: a 6-wide, 8-tall box at every gate, tested with `GetPartBoundsInBox`, hits no part that has `CanCollide` true.
- [x] 72. **`sawah_r8`: terrace dressing.** On the four sawah terraces: a thin water sheet (`Transparency` 0.55, a muddy green-brown tint) only in the paddies, alang-alang tufts on every verge, one small gubuk (field hut: four posts, a thatch roof, a bench) on terrace 2, and a few stepping stones between terraces. The terrace terrain tops stay exactly 4.5 / 8.5 / 12.5 / 16.5. **CHECKS:** `SAWAH_TOPS` unchanged; `SAWAH_WATER` = 4 sheets; `SAWAH_VERGE` ≥ 40 tufts in total; gubuk present once.
- [x] 73. **`river_r8`: banks and bridge.** The river is at `z = 304 + 12 sin(2 pi x / 320)`, 28 wide. Add bank vegetation (talas, keladi, bambu, alang-alang) on both banks along the whole visible stretch, railings and posts on the 10 x 56 bridge, and 6 stepping stones near it. Do not edit the terrain. **CHECKS:** `RIVER_BANK_VEG` ≥ 30 within 40 studs of the bridge; `BRIDGE_RAILS` on both sides; `BRIDGE_WALKABLE`: the railings never narrow the walkable deck below 8 studs.
- [x] 74. **ring_r8: hills and forest ring.** DONE as section O items 138/102 (V-D4): 272 tropical trees, 4 species; default-look whole-workspace NO_PINES = 0; PERF_BUDGET 334/500. See docs/v2/evidence/h/2026-11-21-round9/CHECK_74.txt.
- [x] 75. **`pathedge_r8`: path borders.** Along every dirt path, small grass tufts, pebbles and the occasional puddle sheet (tiny, `Transparency` 0.4, no collision) on both edges, every 3–5 studs with jitter. **CHECKS:** `PATH_EDGE` ≥ 120 pieces; `PATH_CLEAR`: nothing with `CanCollide` true intrudes into the central 6 studs of any path.
- [x] 76. **`water_r8_a/b/c`: river water look.** Tune terrain water properties only (`WaterColor`, `WaterTransparency`, `WaterReflectance`, `WaterWaveSize`, `WaterWaveSpeed`) as client candidates with exact save and restore: clear tropical green, murky brown after rain, bright turquoise. **CHECKS:** each variant sets only values in the safe ranges documented in the module; `disable()` restores the prior values exactly.

#### M3. Buildings and hubs

- [x] 77. **`buildings_r8`: search better buildings.** Use the ladder to find real Indonesian-style buildings (rumah panggung, joglo, gubuk, warung, lumbung, pos ronda, masjid kecil). Test each in Edit mode with `GetObjects`, strip scripts, and bake the survivors. Keep at least 6 distinct buildings, record IDs and licences, and stage them in an open lot (like props_r7: one row, 20 studs apart, review camera in front). **CHECKS:** `LOAD_FAILURES` = 0; `BLDG_VISIBLE` 6/6; each has a `GetBoundingBox` width between 12 and 60 studs and a door at least 7 studs tall (a 7.25-stud avatar must fit).
- [x] 78. **`facades_r8`: facade details on the current buildings.** For each existing hub building, add original details from parts: shuttered windows, a porch roof, a ridge cap, a lantern bracket, a doorstep and an eave. Anchored, welded, `CanCollide` false for decorative pieces, no overlap with the door opening. **CHECKS:** `FACADE_PARTS` ≥ 10 per building; `DOOR_CLEAR`: each door opening (7 x 10.5 for Pak RT, scaled for the others) stays free of collidable parts.
- [x] 79. **`hubprops_r8`: props per hub.** For each hub add six to ten props that say what the hub is: Pasar (sayur crates, bakul baskets, timbangan), Warung (bangku, teko, toples), Polisi (flag, papan pengumuman, motor), Ronda (kentongan, bale bambu), Gelap alley (lampu, tong, kardus), Pak RT (meja, kursi rotan, bendera). Use the ladder; fall back to `generate_procedural_model`. Size by `GetBoundingBox` against real-world sizes. **CHECKS:** `HUBPROPS_VISIBLE` ≥ 5 from the hub's camera in `REVIEW_CAMERAS.md`; `PROPS_ON_GRASS` = 0.
- [x] 80. **`streetfurn_r8`: street furniture.** Lampu jalan / obor posts every 40 studs along the ring road, three papan petunjuk (signposts whose text lives in `Strings.luau` with `id` and `en`), a gapura at the village entrance, a tiang listrik line with a drooping cable (`Beam` or a chain of thin parts), and two bale-bale shelters. **CHECKS:** `STREETFURN` counts per kind; `STRINGS_PARITY` for the new keys; nothing within 6 studs of a road centreline except the posts at the verge.
- [x] 81. **`spanduk_r8`: banners and signage.** Warung and Pasar signs, a spanduk across the main road and bunting strings (`SurfaceGui` or `Decal` text from `Strings`, fonts from the existing UI set). No real brand logos. **CHECKS:** `SIGN_TEXT_PARITY` (id and en for each); each sign faces its approach camera within 30°.

#### M4. Life

- [x] 82. **`animals_r8`: village animals.** Ayam pecking around the warung, bebek by the river, two kambing near the sawah, a kucing on a roof. Client-side, Rendah budget: at most 14 animals, from baked or simple parts, driven by one Heartbeat loop with wander targets from `MapSpec`. **CHECKS:** `ANIMAL_COUNT` ≤ 14; `ANIMAL_BOUNDS`: after 60 s of simulation none left the map or fell below the ground; `ANIMAL_COST`: the loop's average step is under 0.3 ms, measured with `os.clock`.
- [x] 83. **`flyers_r8`: birds, butterflies, dragonflies.** Birds circling high (at most 6), kupu-kupu near the flower beds (at most 10), capung by the river. All procedural, with a per-tier cap. **CHECKS:** `FLYER_COUNT` within caps; `FLYER_COST` under 0.3 ms per frame.
- [x] 84. **`smoke_r8`: kitchen smoke, steam and fire.** Chimney smoke on two buildings, steam on the warung counter, and torch flames with a flickering `PointLight` that are only active at night. **CHECKS:** `EMITTERS` ≤ 12 with each `Rate` ≤ 12; `LIGHTS` ≤ 24 with `Range` ≤ 30; the torches are off at ClockTime 13.
- [x] 85. **`wind_r8`: gentle wind and sway.** Set `workspace.GlobalWind` to a gentle breeze, sway the jemuran laundry and hanging signs with a handful of tweens, and tilt the banana and bamboo models a few degrees with a slow sine from one shared loop. **CHECKS:** `WIND_SET` non-zero and `Magnitude` ≤ 12; `SWAY_TWEENS` ≤ 30; `disable()` restores `GlobalWind` and the CFrames.
- [ ] 86. **`npcs_r8`: more villager roles.** Add tengkulak, debt collector, ibu warung, anak-anak (use `BodyHeightScale` / `HeadScale` for kids) and bapak ojek. Use `HumanoidDescription` with real catalog IDs found through the catalog API the way commit 4408a04 did (see `ModelMapNpcsR7.luau`; rate limit: sleep 4 s per call). Never invent IDs; record them in `ASSET_MANIFEST.md`. Same spacing and facing rules as npcs_r7. **CHECKS:** `LOAD_FAILURES` = 0; each new role has at least one hat/accessory or a distinct shirt; no two roles share the same shirt+pants pair.
- [ ] 87. **`npcs_idle_r8`: idle motion.** Give the villagers a calm idle (subtle breathing/sway, no walking). Use a real Roblox animation ID from the catalog or `generate_animation`; if neither works, a small Motor6D sine sway from one shared loop. **CHECKS:** each villager has an `Animator` track `IsPlaying`, or an active sway loop (state which); cost under 0.3 ms per frame for 10 villagers.
- [ ] 88. **`ambient_walkers_r8`: ambient strollers.** Up to 8 villagers walking looped routes between hubs via `NpcWalk`, ambient only: no interaction, no dialogue, no gameplay. **CHECKS:** after 90 s each reached at least 3 waypoints, none stuck for more than 10 s, none off the roads by more than 8 studs, `Humanoid.WalkSpeed` ≤ 8.

#### M5. Light and sound

- [ ] 89. **`day_cycle` tune.** The verdict was `yes, tune`: 16:00 reads flat. Read `docs/v2/visual/DAY_CYCLE.md` and `DayCycle.luau`. Add stronger directional contrast at 15:00–17:00 (lower sun angle, warmer `ColorShift_Top`, a bit more `ShadowSoftness`), still tweening smoothly. Ship it as a candidate (`day_cycle_r8`), not a default change. **CHECKS:** `DAY_PHASES_MONOTONIC` (no jump above the documented limit between adjacent phases); `DAY_1600_CONTRAST`: the computed sun-vs-ambient luminance ratio at 16:00 is at least 20% higher than before; the maghrib values are unchanged.
- [ ] 90. **`night_r8`: warm night windows and lamps.** At night, windows turn warm (`Neon` material, colour `#FFCB7A` on the window glass parts), torches and street posts glow. Use the Rendah lamp budget. **CHECKS:** `NIGHT_WINDOWS` ≥ 12 lit at 20:00 and 0 at 13:00; `NIGHT_LIGHTS` ≤ 24.
- [ ] 91. **`grade_r8_a/b/c`: colour grades.** Three tropical colour-grade variants for the designer to pick: warm golden, fresh green, hazy humid. Each tunes `ColorCorrection`, `Bloom`, `SunRays` and `Atmosphere` only. No depth of field. **CHECKS:** each variant's values fall in the documented safe ranges; `disable()` restores exactly.
- [ ] 92. **`sounds_r8`: ambient sound beds.** `sounds` is still pending. Source real free sounds from the Creator Store (`search_asset`): jangkrik at night, ayam and birds by day, river water, a soft wind, kentongan. Positional, `RollOffMaxDistance` ≤ 80, grouped in a `SoundGroup`, never at full volume. **CHECKS:** every `Sound.IsLoaded` is true within 10 s and none reports `not authorized`; volumes ≤ 0.5; `disable()` stops and destroys them.

#### M6. Audits and hygiene

- [ ] 93. **Crop stage audit.** For all 12 crops × 3 stages (bibit, tumbuh, siap), measure `GetBoundingBox` and write a table. **CHECK `CROP_GROWTH`:** height grows from stage to stage (at least 15% each) and each is within 0.5–6 studs. Fix any crop that fails by rescaling in the model map, never by weakening the check.
- [ ] 94. **Icon audit.** A script (`tools/icon_audit.py` or Luau): for every icon PNG, check size, alpha coverage (between 15% and 85%) and flag near-duplicates by perceptual hash. Report `tier_biasa` with numbers only (the `icons` verdict said to fix it). Don't judge looks.
- [ ] 95. **Strings audit.** Add or extend a spec so that every `Strings.luau` key has a non-empty `id` and `en`, no leftover `TODO`/`lorem`/placeholder text, and no `id == en` for long strings (flag, don't fail, for loanwords). Grep `src/client` for hardcoded player-facing string literals in `Text =` assignments and move them into `Strings.luau`.
- [ ] 96. **IconMap coverage.** A spec that every `IconMap` slot resolves to a non-zero asset ID recorded in `ASSET_MANIFEST.md`, and that no ID appears twice by mistake.
- [ ] 97. **Perf budget table.** Measure and record in `docs/v2/visual/PERF_R9.md`: instances, parts, `MeshPart` triangle estimate and `ParticleEmitter` count for the default look and for each candidate enabled alone on top of it. **CHECK `PERF_BUDGET`:** the default look is within the Sedang tier budget in `VISUAL_MASTER_PLAN.md` §6. Flag, never hide, any candidate over budget.
- [ ] 98. **`LOOKDEV_LEAK` sweep.** Run the leak check from item 68 over **every** candidate in `LookDev.IDS` and save the output in `CHECK_98.txt`. Fix every leak in the candidate's `restore`/`disable`. Any candidate that can't be fixed in two attempts is marked `BLOCKED` with the delta.
- [ ] 99. **Gate 1 evidence sweep.** Go through `GATE1.md` and `BUGS.md`. For each row marked `LUNE-ONLY` or `UNVERIFIED` that Studio Play can prove with `execute_luau` (no human input needed), run it and save the output under `docs/v2/evidence/`. Change a status to `SEEN-IN-STUDIO` only with a file behind it; leave the rest and note why.

#### M7. Handoff

- [ ] 100. **Review pack.** Write `REVIEW_ROUND9.md`: the bake (step 1), then batches grouped by datamodel (Client: water, grade, sounds; Server: everything else), the exact `enable` sequence per batch, the camera name from `REVIEW_CAMERAS.md` for each candidate, and every `CHECK_*.txt` path. Add `docs/v2/evidence/h/<date>-round9/CHECKS_SUMMARY.md` with one PASS/FAIL/BLOCKED line per item. The main session takes the screenshots.
- [ ] 101. **No-op marker.** Tick this when items 68–100 are each ticked or `BLOCKED`; section N follows and holds the real refill (item 135).

### N. Round 10: more village, combined look, audits (added 2026-11-21, second long unattended run)

Same rules as section M (candidates off by default, Studio PASS per item, no gameplay, no terrain sculpt, no NPC outfit changes, real assets only, commit per item, stage files by name). **Review of round 9 so far (main session, 2026-11-21):** items 68–73 and 75–78 have PASS evidence and `lune` is at 2422 tests, selene 0/0/0. Visual grading is still pending; the designer will go through the candidates afterwards. Two things the agent should know:

- Item 74 was marked BLOCKED correctly (the default `BackgroundForest` has 254 pine-named instances), but the reason given ("reserved for designer grading") is wrong: **V-D4 already decided "tropical trees, no pines"**, so replacing the pine backdrop is closable. Item 102 does it.
- When a check's own geometry was wrong (item 71 `GATE_CLEAR`: axis-aligned box on a rotated gate) fixing the check is fine, but write the reason and keep the size and threshold unchanged, as you did. Keep doing that.

#### N1. Unblock and combine

- [x] 102. **(Pulled forward: do it as item 138 in section O and tick both.) Unblock item 74: replace the pine backdrop.** V-D4 is decided (tropical trees, no pines). In `Greybox` `buildForestRing`, replace the pine-named backdrop with tropical trees from the baked species (kelapa, mangga, bambu, pisang, jati or similar), same count or higher, same placement band, random yaw ±15% scale, within the Rendah budget. This is a **default-look change on purpose**; keep the old pines behind a `LookDev` candidate `forest_pines_legacy` so the designer can compare. Then finish `ring_r8` (hills and the band beyond ±400, at least 150 instances, 4 species). **CHECKS:** `NO_PINES` = 0 in the default look; `RING_COUNT` ≥ 150; `RING_SPECIES` ≥ 4; `PERF_BUDGET` still within Sedang. Untick and re-tick item 74 with the new evidence, and remove the item from "Decisions for designer".
- [ ] 103. **`full_r9`: everything approved-or-pending at once.** A candidate that stages, in order, the round-9 scene candidates that don't conflict: `hubveg_r8`, `plots_r8`, `sawah_r8`, `river_r8`, `pathedge_r8`, `facades_r8`, plus whichever of items 79–85 are ticked. Skip `buildings_r8` (it is a staging lot, not a village layout) and the water/grade/sound variants (the designer picks one). **CHECKS:** `LOAD_FAILURES` = 0; `CROSS_OVERLAP` = 0: no two candidates' parts with `CanCollide` true have intersecting bounding boxes (report the pair names on FAIL); `LOOKDEV_LEAK` PASS; `PERF_BUDGET` result recorded.
- [ ] 104. **Rendah/Sedang/Tinggi thinning.** Each round-9 candidate takes the player's quality tier from the existing tier module and thins itself: Rendah keeps at most 50% of instances (never the structural ones such as fences, bridge rails, doors), Tinggi keeps 100%. **CHECKS:** `TIER_THIN`: for each candidate, count at Rendah ≤ 0.55 × count at Tinggi, and at Tinggi equals the item's documented count.
- [ ] 105. **Walkability audit with everything on.** With `full_r9` staged, run `PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5.5, AgentCanJump = false})` from the spawn to each hub entrance and each plot gate. **CHECK `PATH_REACH`:** every route returns `Success` (16/16). If one fails, find the blocking candidate and fix it (move or shrink the part), never the check.
- [ ] 106. **Avatar scale audit with everything on.** A 7.25-stud-tall, 4-stud-wide box swept along each of those routes must hit no `CanCollide` part. **CHECK `AVATAR_FIT`** 16/16.
- [ ] 107. **Clean-Play smoke test.** `tools/studio/smoke_play.luau`: start a fresh Play, wait 60 s, read the console through `get_console_output`, and assert no error-level message and no warning outside a short allowlist in the same file (each allowed line carries a one-line reason). Run it for the default look and for `full_r9`. **CHECK `SMOKE_CLEAN`** 0 errors for both. Fix real errors; never grow the allowlist to hide one.

#### N2. More village

- [ ] 108. **`lapangan_r8`: the field.** The village field (lapangan) gets two goal posts, a flagpole with a red-white flag, bamboo benches along one side, a boundary of white-painted stones and a few sandy patches, using `MapSpec` for position. **CHECKS:** `LAPANGAN_PARTS` per kind; `PATH_REACH` for the field edge; the goal posts are sized against the 7.25-stud avatar (a 2.2-stud-tall-per-avatar-height ratio is fine; document the numbers you chose in the module).
- [ ] 109. **`pasar_ground_r8`: Pasar ground.** Around the Pasar, flat paving stones and cobble patches (parts, `Material` Cobblestone/Slate, no terrain edit), drainage gutters along the building edges, and a cleared 6-stud walking lane between stalls. **CHECKS:** `PASAR_PAVING` ≥ 60 pieces; `LANE_CLEAR`: the 6-stud lane has no collidable parts; paving is within 0.15 studs of ground height so nobody trips.
- [ ] 110. **`musala_r8`: musala (small prayer house).** A small musala with a green dome or tiered roof, a pengeras suara horn on a pole, a wudhu tap area and a shoe rack. Built from parts, modest in size, respectful. Place it with a clear approach on the village side of the ring road. **CHECKS:** `MUSALA_PARTS` ≥ 25; `DOOR_CLEAR` for its door; `PATH_REACH` to its door. Mark it in `CANDIDATES.md` as `needs designer review: cultural content`.
- [ ] 111. **`lumbung_r8`: lumbung and pekarangan.** A rice barn (lumbung padi) on stilts, garden fences with toga herbs and chilli pots, a tempat jemur padi (drying mat on the ground) and a well-swept dirt yard around each of three houses. **CHECKS:** counts per kind; `PROPS_ON_GRASS` = 0 for the yard pads; `DOOR_CLEAR`.
- [ ] 112. **`perahu_r8`: boats and river life.** Two small perahu at the river bank, a fishing net on poles, a bamboo landing stage and a stack of baskets (not in the water channel, keep the bridge span clear). **CHECKS:** counts; `BRIDGE_WALKABLE` unchanged; nothing intersects the river centreline within the bridge's 56 studs.
- [ ] 113. **`irrigation_r8`: irrigation and field life.** Two scarecrows (orang-orangan sawah) with a woven hat and a ragged shirt, two bamboo irrigation channels with a thin water sheet, a bamboo clapper bird-scarer and a small stack of padi sheaves. **CHECKS:** counts; `SAWAH_TOPS` unchanged; the water sheets sit within 0.3 studs of the terrace top.
- [ ] 114. **`kincir_r8`: water wheel.** A small wooden waterwheel beside the river that rotates slowly (one shared loop, 6 degrees per second). **CHECKS:** `KINCIR_ROT`: the wheel angle changes by 3–9 degrees over 1 s; one instance only; `disable()` stops and removes it.
- [ ] 115. **`laundry_r8`: hanging laundry.** Washing lines with sarung, batik cloth and kebaya hanging between posts behind two houses, plus a hammock and a tikar under the porch. Use solid colours or simple patterned decals made from existing assets; no brand logos. **CHECKS:** counts; cloths do not intersect walls (`GetPartsInPart` is empty); `CLOTH_SWAY` is optional and tied to item 85 when present.
- [ ] 116. **`layangan_r8`: kites.** Four layangan (kites) flying at 60–90 studs of altitude near the field, each with a thin tail and a string (`Beam`) down to a small kid-sized point on the ground; they rock gently. **CHECKS:** `KITE_COUNT` = 4; `KITE_COST` under 0.2 ms per frame; strings don't pass through buildings (raycast from kite to anchor hits nothing).
- [ ] 117. **`seated_r8`: seated villagers at the warung.** Use `HumanoidDescription` NPCs (same catalog outfits as npcs_r7) seated on the warung benches with `Humanoid.Sit` driven by a `Seat`, and a few glasses and plates on the table. At most 4. **CHECKS:** `SEATED_COUNT` ≤ 4; each `Humanoid.Sit` is true after 3 s; none intersects the bench.
- [ ] 118. **`crops_showcase_r8`: crop review plots.** For the designer's review: one plot per growth stage (bibit, tumbuh, siap) showing all 12 crops in rows, and a camera for each in `REVIEW_CAMERAS.md`. No gameplay state is touched; it is staged geometry only. **CHECKS:** `CROPS_STAGED` = 36; `CROP_GROWTH` re-run.

#### N3. Weather, seasons, atmosphere

- [ ] 119. **`season_r8_*`: seasonal look.** Three candidates tied to `Seasons.luau`: `season_r8_hujan` (wetter ground tint, more puddle sheets, slightly cooler grade), `season_r8_kemarau` (dry-grass tint, lower Cover, more haze) and `season_r8_panen` (golden padi tint, warmer light). They only touch `Lighting`, `Atmosphere`, `Clouds` and tinted existing decor, with exact restore. **CHECKS:** `SEASON_SAFE` ranges; `SEASON_RESTORE` exact; each preset differs from the others in at least two values by at least 10%.
- [ ] 120. **`rain_r8`: rain and mist.** A client rain effect (a ring of `ParticleEmitter` parts around the camera, at most 3 emitters, `Rate` ≤ 60 each) with a ground splash, and a morning mist `Atmosphere` bump. Only on when the season/weather state says `hujan`; off in `cerah`. **CHECKS:** `RAIN_EMITTERS` ≤ 3; `RAIN_OFF_CERAH`: emitters disabled when the weather is `cerah`; `RAIN_COST` under 0.5 ms per frame.
- [ ] 121. **`subuh_r8`: dawn look.** A dawn (04:30–06:00) preset: cool blue-to-peach `ColorShift`, soft low mist, the first warm lamp glow, birds silent until 06:00. Follows the same tween rules as `DayCycle`. **CHECKS:** `DAWN_PHASES_MONOTONIC`; `DAWN_SAFE` ranges.
- [ ] 122. **`lamps_shadows_r8`: night light cost.** Make sure no `PointLight`/`SpotLight` added by any round-9 candidate casts shadows (`Shadows = false`) and that every lamp has `Range` ≤ 30 and `Brightness` ≤ 3. **CHECK `LIGHT_COST`** across `full_r9`, with the counts reported.

#### N4. UI and text audits (objective only)

- [ ] 123. **Theme audit.** Scan `src/client` UI modules for hardcoded `Color3.fromRGB`, font and `UICorner` values that bypass the theme module. Write `docs/v2/visual/UI_THEME_AUDIT.md` listing file, line and value, and fix any **exact duplicates of a theme token** (same colour in a different place). Do not redesign. **CHECK `THEME_BYPASS`:** the count after is lower than before; list the rest.
- [ ] 124. **Phone-size UI bounds.** With the Device Simulator skill (`get_roblox_skill rbx-device-simulator-lua`) or an equivalent script, open each ScreenGui at 375×812, 812×375 and 1024×768 and measure that every visible `GuiObject` lies inside the safe area and no interactive element is smaller than 44×44 px. **CHECK `UI_BOUNDS`** per screen and size; fix the failures that are plain size or anchor bugs. Do not move layout the designer chose.
- [ ] 125. **Contrast audit.** For every `TextLabel`/`TextButton`, compute the contrast ratio between `TextColor3` and the nearest opaque background colour (or the stroke). **CHECK `CONTRAST`:** report the ones below 4.5:1 (3:1 for text 24 px or larger). Fix only the ones where a theme token with a better contrast exists.
- [ ] 126. **Minimum text size.** **CHECK `TEXT_MIN`:** no body text under 14 px at 375 px wide (use `TextScaled` with `UITextSizeConstraint.MinTextSize` ≥ 14). Fix the plain violations.

#### N5. Asset and doc hygiene

- [ ] 127. **Manifest coverage.** A spec that every numeric asset ID that appears in `src/shared/ModelMap*.luau`, `SkyMap*.luau`, `IconMap.luau` and the other asset maps is present in `docs/v2/visual/art/ASSET_MANIFEST.md`, and every manifest ID is used or marked `unused`. Fix the manifest, never delete an ID from code to pass.
- [ ] 128. **Candidate catalogue.** Add `docs/v2/visual/CANDIDATE_INDEX.md`, generated by a small script from `LookDev.IDS` and `CANDIDATES.md`: id, family, datamodel, review camera, verdict, and the module file. Flag every id missing from either side. A spec fails if `LookDev.IDS` and `CANDIDATES.md` disagree.
- [ ] 129. **Rejected-candidate register.** Write `docs/v2/visual/REJECTED.md`: every candidate with verdict `**no**`, its module files, the one-line reason, and whether anything else requires it. **Do not delete code.** The designer decides what to prune.
- [ ] 130. **Tracker refresh.** Update `VISUAL_MASTER_PLAN.md`'s visual tracker with a dated status line per layer L1–L10 (status words only: `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`, each with its evidence path).
- [ ] 131. **Evidence index.** Write `docs/v2/evidence/h/INDEX.md` listing every dated folder, what it proves and the status word. Flag any `SEEN-IN-STUDIO` claim in the docs that has no file behind it and downgrade the claim to `UNVERIFIED`.

#### N6. Review prep

- [ ] 132. **Shot list for the main session.** Write `docs/v2/evidence/h/<date>-round10/SHOT_LIST.md`: for every candidate ticked in rounds 8–10, one line with the exact `enable` call, datamodel, camera name (`REVIEW_CAMERAS.md`), the Play/Edit state required and the objective checks it already passed. Order it by datamodel so the main session needs the fewest restarts. Include `full_r9` and every `season_r8_*` and `grade_r8_*` as alternatives to compare.
- [ ] 133. **Camera additions.** Add a named camera to `REVIEW_CAMERAS.md` and `ReviewCameras.luau` for every new item above (lapangan, musala, lumbung, perahu, irrigation, kincir, laundry, kite sky, warung seated, crops showcase ×3), derived from `MapSpec`. **CHECK `CAMERA_CLEAR`** for the full set.
- [ ] 134. **Final report.** Write `docs/v2/evidence/h/<date>-round10/FINAL_REPORT.md`: commits, one PASS/FAIL/BLOCKED line per item, blocked items with the exact FAIL line, and the decisions-for-designer list.
- [ ] 135. **Refill.** Re-read `BUGS.md`, `GATE1.md`, `CANDIDATES.md` and `VISUAL_MASTER_PLAN.md`. Queue anything an agent can still close, in this format and at least 15 items long if there is that much to do. Only write "nothing left" if you can name the file you checked for each layer.

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

### Round 6 items 44–51 — LookDev verdicts and reversible defaults (2026-11-20)

Twelve off-by-default round-6 candidates ship with **blank verdict cells** in
`docs/v2/visual/CANDIDATES.md` and the exact toggles / datamodels / cameras in
`docs/v2/evidence/h/2026-11-20-review-round6/REVIEW_ROUND6.md`. No agent graded a visual. The
designer's look decisions are which (if any) of `sky_r6_a`..`sky_r6_f` and `terrain_r6_a`/`b` should
become the baseline, and whether the vegetation, villager and prop changes read well in Studio. All
are reversible one-call toggles and none affect shipping state. Safest reversible defaults chosen
while building: Route B Shirt/Pants sibling Image IDs for costumes (Open Cloud cannot create
Shirt/Pants assets), a manually invoked `DesignerKitBuilder.build()/clear()` with no spawn dressing,
`ScaleTo` targets of gerobak ~6 tall/8 long, sumur 4.5 and cangkul 4.5, and the props review camera
moved +12 in X clear of the pine row. No place was saved or published.

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
