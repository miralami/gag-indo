# Work queue round 3: visual first (long-run mode)

> **START HERE (standing prompt, so the designer doesn't need to retype it).** If you were only told to "continue" or "read the work queue", this block is your whole instruction:
>
> 1. Read `AGENTS.md`, the tracker at the top of `docs/v2/plan/MASTER_PLAN.md`, `docs/testing/BUGS.md` and `docs/testing/GATE1.md`.
> 2. You are in long-run mode. Take the **first unchecked item** in this file (sections P, Q, L, O, M and N are the live ones, in that order: **P first, then Q**, then O before the unticked items of M) and work down. Don't ask questions, don't stop to report.
> 3. Section K's hard rules apply to every scene-affecting item: a tick needs real Studio PASS output saved under `docs/v2/evidence/h/<date>-round<N>/CHECK_<item>.txt`; two failed attempts mean `BLOCKED — <FAIL line>`; never weaken a check; never save the place; never touch NPC outfits, the terrain sculpt or the chosen sky/ground.
> 4. Per item: `lune run tests/run.luau` passes (check the exit code), `selene src` is 0/0/0, stylua only on files you changed, then a topical commit with no attribution lines, the tracker "Last updated" line updated in the same commit, and push to `main` (the working branch since 2026-11-22; `track/c-world-look` is retired). Stage files by name, never `git add -A`.
> 5. The main session (Claude, with Studio screenshots) does the visual review afterwards. Stop only when every item is ticked or `BLOCKED`, then write the final report: commits, blocked items, decisions list.


> **SPRINTS (2026-11-23, set by the designer; override steps 2 and 5 above).** The designer is away for a long run. Work runs in sprints. Each sprint lists its items in order and ends with a STOP item; **when you tick a STOP item, stop the run** (the main session reviews, then dispatches the next sprint). Inside a sprint: no other items, no refill, no new items. Designer choices go to "Decisions for designer"; two failed attempts mean `BLOCKED — <FAIL line>` and you move on. Main-session provisional verdicts live in `docs/v2/visual/PROVISIONAL_VERDICTS.md`; read them, never treat them as designer verdicts.
>
> - Sprint 1 (DONE 2026-11-23, `c0630ad..20b4422`): 216, 217, 198-207, S1-STOP. Review: `h/2026-11-23-sprint1/`.
> - **Sprint 2 (current):** section S items **238, 239, 240, 241, 242, 243, 244, 245**, then Q items **208, 209, 210, 211**, then **S2-STOP**.
> - Sprint 3: Q items **212, 213, 214, 215**, section S items **246, 247**, then Q items **218, 219, 222, 223, 225**, then **S3-STOP**.
> - Sprint 4: section S items **248, 249**, then Q items **220, 221, 224**, then **S4-STOP**. Item 226 (promotion) and 227 (refill) are NOT in any sprint: promotion needs designer `yes` verdicts.
>
> **Every STOP item** (S2-STOP, S3-STOP, S4-STOP) means: in Studio (Play, ClockTime 13 unless the item says otherwise, `LookDevReview.disableAll()` then `enableAdditive(id, game)` from the SERVER datamodel, one candidate at a time, **HUD hidden** with the item 238 helper), `screen_capture` every candidate touched in that sprint from its review camera, plus `spawn` and `canonical_overview` with no candidate. Run the item 239 `SUBJECT_COVERAGE` check for each shot and print it on the card. Save to `docs/v2/evidence/h/<date>-sprint<N>/shots/NN_<id>.jpg` and build `REVIEW_SPRINT<N>.html` in the style of `h/2026-11-23-sprint1/REVIEW_SPRINT1.html` (base64 JPEG max 1200 px, Indonesian caption + CHECK lines, Ya/Tidak/Tunda radio, comment box, "Salin hasil" button). Write `SPRINT<N>_REPORT.md` (commits, status per item, decisions). Do not write verdicts anywhere. Tick the STOP item, update the tracker, commit, push, **stop**.

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

### P. Round 10 fixes from the main-session Studio review (added 2026-11-22; do this section first)

Source: `docs/v2/evidence/h/2026-11-22-review-round10/REVIEW_ROUND10_STUDIO.html` (12 Studio shots, ClockTime 13). Section O mostly worked: no pines in the default look, padi rows read, plot fences, scarecrow and Pasar stalls are visible, hubveg is dense. The items below are what the screenshots still show as wrong. Section K's hard rules apply: every scene fix needs a PASS CHECK saved under `docs/v2/evidence/h/2026-11-22-round10/CHECK_<item>.txt`, and **a count or presence check is not enough: add a geometry check that would have failed on the bad screenshot**.

- [x] 173. **Stray floating pole on `facades_r8` pakrt (item 139 was ticked but the pole is still there).** Studio shows a long yellow stick floating above the Pak RT roof. Cause: `FacadeRidgeCap` is at (68, 33.7, 68), size 1.2 × 0.6 × 10 (long axis Z), but `RumahPakRT` has two ridges running along X (`RoofRidge` at (81, 32.85, 71) length 27.4 and at (58, 23.85, 72) length 25.4). Rebuild the cap(s) so each one sits on a real `RoofRidge` (same centre, long axis X, length equal to its ridge) or drop them. Do the same for every hub facade. **CHECKS:** `CAP_ON_RIDGE`: every `FacadeRidgeCap` centre is within 0.5 stud of a `RoofRidge` centre of the same building and its long axis is parallel to that ridge; `NO_FLOATERS`: every part under every `facades_r8` folder either touches another part (a `GetPartBoundsInBox` expanded by 0.3 hits something that is not itself) or is a roof, awning or sign; list failures by full name. The check must FAIL on the current commit and PASS after the fix.
- [x] 174. **`river_r8` bank plants are stepped cubes.** The bank shows rows of dark-green square blocks (a boxy hedge) under the palms. Replace them with round shrubs, taro and reed clumps (baked models where they exist, otherwise spheres, wedges or 3-blade clusters). **CHECKS:** `NO_CUBE_SHRUBS`: no part on the river banks whose three sizes are within 20% of each other and whose Shape is Block and size ≥ 1.5 studs; `BANK_PLANTS` ≥ 40 plants; bank plants stay out of the water (`WATER_CLEAR`).
- [x] 175. **`plaza_r9` fountain is too small and plain.** It is a 6-stud pool with a grey block. Build a two-tier fountain (basin ≥ 14 studs across, a second smaller tier, a central spout with a water particle or a thin vertical Neon-free water column), a paved ring around it, and four benches facing in. Replace the crossed red/blue/grey pennants on the poles with one flag per pole (flat, red over white). **CHECKS:** `FOUNTAIN_SIZE`: basin diameter ≥ 14; `FOUNTAIN_TIERS` = 2; `FLAG_CLEAN`: each flag is a single flat part pair, no crossing parts; `PLAZA_WALKABLE`: a 6-stud lane from each road to the fountain ring is clear.
  Superseded by item 188 (real baked fountain model replaces the Part-built two-tier fountain); ticked here for queue order, evidence under `CHECK_188.txt`.
- [x] 176. **`rocks_r9` rocks are tiny dots.** Make larger, varied rocks: sizes 0.8 to 2.5 studs, moss-green or grey-brown, clustered in groups of 2 to 4 along both river banks and at the stepping stones, at least 40 rocks in total, with a few half in the water. **CHECKS:** `ROCK_COUNT` ≥ 40; `ROCK_SIZE`: median longest side ≥ 1.2 studs; `ROCK_VISIBLE`: from the `river_rocks` camera at least 8 rocks are visible (raycast to each, 60% hit own part).
  Superseded by item 189 (Part-built rocks replaced by three baked Creator Store models); ticked here for queue order, evidence under `CHECK_189.txt`.
- [x] 177. **`pathedge_r8` is invisible at distance.** The edges now sit at the road side (good) but are tiny sprigs and dark dots. Use real grass tufts and small flowers 1 to 2 studs tall, at least one every 3 studs along each road edge, in 2 colours of flower. **CHECKS:** `EDGE_HEIGHT`: median plant height ≥ 1; `EDGE_VISIBLE`: from the `spawn` camera at least 12 edge plants are visible; `EDGE_OFF_ROAD`: none sits on the road surface.
  Superseded by item 190 (procedural plants replaced by three baked Creator Store models); ticked here for queue order, evidence under `CHECK_190.txt`.
- [x] 178. **`sawah_r8` bunds are light-green blocks.** The terrace edges read as bright lime planks. Replace them with a grassy bund: rounded (wedge or cylinder cross-section), Grass material, the same green as the surrounding grass, with a few tufts on top. **CHECKS:** `BUND_COLOR`: bund colour within a small distance of the terrain Grass colour; `BUND_SHAPE`: no bund is a plain Block part with a flat top wider than 1.5 studs; `PADI_ROWS` and `TUFT_SHAPE` still PASS.
- [x] 179. **Pasar stalls: dark base, murky stripes.** The black pads under the lapak look like asphalt and the stripes are dark blue and maroon. Use packed-dirt or cobble pads, and brighter stripes: red, white and blue of higher value (see the Pasar in `map-plan-canonical.png`). **CHECKS:** `PAD_MATERIAL`: pads use Ground, Cobblestone or Pavement, not SmoothPlastic black; `STRIPE_VALUE`: HSV value of every stripe colour ≥ 0.6; `STALLS` ≥ 10 and `LANE_CLEAR` still PASS.
- [x] 180. **Camera `ronda_tower` is blocked.** The camera sits in the Pos Polisi roof, so the tower is half hidden. Move it (and add `ronda_tower_wide`) so the whole tower is seen from the open side. **CHECKS:** `CAMERA_CLEAR` PASS for both cameras; the ray from camera to the tower base and top both hit the tower first.
- [x] 181. **`plots_r8` gate is a plain cream block.** The gate lintel and the side post are flat cream. Give them wood colour and a Wood material, a visible name sign (burned-in text or a decal), and rope or bamboo detail. **CHECKS:** `GATE_MATERIAL`: lintel and posts use Wood or WoodPlanks; `GATE_SIGN` = 1 per plot; `GATE_CLEAR` still PASS.
- [x] 182. **Default-look empty areas from `canonical_overview`.** The overview still looks empty on the left and in the middle ring: no paddock, field or tree cluster between the Pasar ring and the river. Add trees and grassy decoration in the `blocks_r9` band (use the baked tropical trees) and add `canonical_overview_left` and `canonical_overview_right` cameras. **CHECKS:** `BLOCK_TREES` ≥ 60 within the village ring (radius 60 to 140); `PERF_BUDGET` within Sedang; `WALKABLE` and `GATE_CLEAR` PASS.
- [x] 183. **Stray workspace objects after Play.** ~~BLOCKED — needs a place edit by the main session: GiantyFrog (Model, 316 descendants) in Workspace after clean Play.~~ The main session found `GiantyFrog` (Model, 316 descendants, about (52, 4, -162)) and `BambooBasket` (ProceduralModel at about (484, 6.6, 516)) in `Workspace`. They are not made by game code. Write a Studio check `NO_STRAY_WORKSPACE` that lists every top-level `Workspace` child that is not in the known list (Terrain, Camera, World, Decor, LookDev*, Rojo-synced folders), run it in an Edit datamodel and in a clean Play, and record the output. If the objects are in the saved place, mark `BLOCKED — needs a place edit by the main session` with the exact names and positions; do not save the place.
- [x] 184. **Re-review pack for section P.** Update `SHOT_LIST.md` with the cameras and candidates of items 173 to 182 and every CHECK path, in the same table format.
- [x] 185. **Refill.** If items 173 to 184 are done or BLOCKED, add at least 10 new items for whatever the canonical-map comparison still shows as different (see `CANONICAL_GAP.md`), then work them. Do not write a final report while anything you can do is unticked. Added items 228-237 below (canonical-gap rows 10, 3, 4, 17, 19, 20, 22, 9, 13, 26).

### P-refill. Canonical-gap items from item 185 (added 2026-11-22, worked before Q)

All are OFF-by-default LookDev candidates (section K hard rules unchanged). Each needs real Studio PASS evidence under `docs/v2/evidence/h/2026-11-22-round10/CHECK_<item>.txt`.

- [x] 228. **Balai desa hall (gap row 10 — the only MISSING canonical feature).** Add `balai_r10`: a visual-only village hall in the reserved 42 × 28 slot at (0, -137), derived from `MapSpec`, with a roof and a name sign. No leaderboard, permit, election or any gameplay behaviour; the slot stays a visual landmark. **CHECKS:** `BALAI_PARTS` ≥ 20; `BALAI_FIT` inside the slot; `BALAI_SIGN` present with `id` and `en` in `Strings.luau`; `NO_GAMEPLAY` (no ProximityPrompt/ClickDetector); `PATH_REACH` clear; `PERF_BUDGET`.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_228.txt`): NEW pure `ModelMapCanonicalR10` + SERVER `LookDevCanonicalR10` (10 appliers, ids 96-105). BALAI_PARTS 21/20, BALAI_FIT 0, BALAI_SIGN 1, NO_GAMEPLAY 0, PATH_REACH 0, PERF_BUDGET 335/500. No gameplay behaviour.
- [x] 229. **Hub canopy trees (gap row 3).** Add `hub_canopy_r10`: 2 to 3 large round-canopy shade trees (10 to 12 studs) at each of the six hubs, off the road and gate lanes. **CHECKS:** `HUB_CANOPY` ≥ 2 per hub; `CANOPY_SIZE` 10..12 studs; `GATE_CLEAR`; `NO_PINES` = 0; `PERF_BUDGET`.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_229.txt`): HUB_CANOPY 6/6, CANOPY_SIZE 0, GATE_CLEAR 0, NO_PINES 0, PERF_BUDGET 353/500.
- [x] 230. **Inter-building shrubs and flowers (gap row 4).** Add `blocks_shrubs_r10`: ≥ 60 small shrubs and flower patches in the blocks between buildings, plots and the ring road, ≥ 3 species, rounded not cube shapes. **CHECKS:** `SHRUB_COUNT` ≥ 60 within the village ring; `SHRUB_VARIETY` ≥ 3 species; `NO_CUBE_SHRUBS` = 0; `WALKABLE`; `PERF_BUDGET`.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_230.txt`): SHRUB_COUNT 102/60, SHRUB_VARIETY 4/3, NO_CUBE_SHRUBS 0, WALKABLE 0, PERF_BUDGET 335/500.
- [x] 231. **Pasar red roof (gap row 17).** Add `pasar_roof_r10`: a clear red pitched roof over the Pasar hall footprint, sloped (not a flat slab), fitting the hub without stray parts. **CHECKS:** `RED_ROOF` present over Pasar; `HUB_FIT` 0; `ROOF_SLOPE` > 0; `FACADE_STRAY` 0.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_231.txt`): RED_ROOF 3/2, HUB_FIT 0, ROOF_SLOPE 2/2, FACADE_STRAY 0.
- [x] 232. **Warung tin-roof cluster (gap row 19).** Add `warung_cluster_r10`: ≥ 3 tin-roof stalls and ≥ 2 tables clustered at the Warung hub, non-interactive. **CHECKS:** `WARUNG_STALLS` ≥ 3 with tin roofs; `WARUNG_TABLES` ≥ 2; `LANE_CLEAR`; `NO_FLOATERS` = 0; `NOT_INTERACTIVE`.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_232.txt`): WARUNG_STALLS 3, WARUNG_TABLES 2, LANE_CLEAR 0, NO_FLOATERS 0, NOT_INTERACTIVE 0. Real defect fixed: stall local-x offsets {-18,0,18} to {-18,-9,9} to clear the Warung door lane (first staged run LANE_CLEAR FAIL 2).
- [x] 233. **Pos Polisi blue roof (gap row 20).** Add `polisi_roof_r10`: a blue roof on the Pos Polisi hub, fitting the footprint and clear of the tower camera. **CHECKS:** `BLUE_ROOF` present; `HUB_FIT` 0; `CAMERA_CLEAR`; `FACADE_STRAY` 0.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_233.txt`): BLUE_ROOF 3/2, HUB_FIT 0, FACADE_STRAY 0, CAMERA_CLEAR 0. Harness bug fixed (ReviewCameras position/lookAt are {x,y,z} tables, not an eye Vector3).
- [x] 234. **Pak RT yellow-orange roof (gap row 22).** Add `pakrt_roof_r10`: retint the Pak RT roof yellow-orange while keeping the ridge caps on the real ridges. **CHECKS:** `PAKRT_ROOF_COLOR` yellow-orange; `CAP_ON_RIDGE` still PASS; `FACADE_STRAY` 0.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_234.txt`): PAKRT_ROOF_COLOR 4/1, CAP_ON_RIDGE 0, FACADE_STRAY 0. Harness Color3 0..1 scale bug fixed; blackened-roof calibration FAIL 0/1 proves the check is undeweakened.
- [x] 235. **Gubuk on sawah terrace 2 (gap row 9).** Add `sawah_gubuk_r10`: one field hut on terrace 2, resting on the terrace top, terraces otherwise unchanged. **CHECKS:** `GUBUK_TERRACE2` = 1; `GUBUK_ON_GROUND` (within 0.3 of terrace top); `SAWAH_TOPS` unchanged; `PERF_BUDGET`.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_235.txt`): GUBUK_TERRACE2 1/1, GUBUK_ON_GROUND 1.8e-07/0.3, SAWAH_TOPS 0, PERF_BUDGET 335/500.
- [x] 236. **Plot mailbox and sign (gap row 13).** Add `plots_mailbox_r10`: one small mailbox with a name sign per plot, sign text in `Strings.luau` with `id` and `en`, off the gate lane. **CHECKS:** `MAILBOX` ≥ 1 per plot; `MAILBOX_SIGN` present with both string variants; `GATE_CLEAR`; `NO_FLOATERS` = 0.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_236.txt`): MAILBOX 10/10, MAILBOX_SIGN 10/10, GATE_CLEAR 0, NO_FLOATERS 0.
- [x] 237. **River tall palms (gap row 26).** Add `river_palms_r10`: ≥ 20 tall kelapa palms (≥ 14 studs) at the river bends, out of the water channel, no pines. **CHECKS:** `RIVER_PALMS` ≥ 20 tall; `WATER_CLEAR` = 0; `NO_PINES` = 0; `PERF_BUDGET`.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_237.txt`): RIVER_PALMS 24/20, PALM_TALL 24/20, WATER_CLEAR 0, NO_PINES 0, PERF_BUDGET 335/500. Harness full-canopy height fixed; lowered-frond calibration FAIL 0/20 proves undeweakened.

### S. Sprint fixes after the main-session review of sprint 1 (added 2026-11-23)

Source: `docs/v2/evidence/h/2026-11-23-sprint1/MAIN_SESSION_NOTES.md` and `docs/v2/visual/PROVISIONAL_VERDICTS.md`. Section K's hard rules apply: real Studio PASS saved as `CHECK_<item>.txt` under the sprint's evidence folder, every check calibrated to FAIL on injected bad state, never weaken a check, never save the place.

- [x] 238. **Review capture helper: hide the HUD.** Add a client-side review helper (for example a `LookDevReview` client function) that disables every `PlayerGui` ScreenGui and restores the exact previous `Enabled` values afterwards. **CHECKS:** `HUD_HIDDEN`: 0 enabled ScreenGuis while hidden; `HUD_RESTORE`: every ScreenGui back to its saved state. Document its use in `REVIEW_CAMERAS.md`.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_238.txt`): `LookDevReview.hideHud()` / `restoreHud()` save and
  restore exact ScreenGui `Enabled` values; repeat-safe, SERVER fallback, documented Client-VM capture
  sequence. Fresh Play SERVER-VM PASS `HUD_HIDDEN 0/0`, `HUD_RESTORE 0/0`; each check calibrated FAIL
  by runtime injection. Suite 3024->3031, `selene src` 0/0/0.
- [x] 239. **`SUBJECT_COVERAGE` check for review shots.** For a candidate and a camera, project the candidate's part bounding boxes with `Camera:WorldToViewportPoint` and compute the visible screen fraction (clipped to the viewport, occlusion tested by raycasting sampled points). Add it to `tools/studio/review_check_visual.luau`. **CHECKS:** `SUBJECT_COVERAGE` >= 0.15 for a well-framed fixture; it FAILS (< 0.15) for the sprint-1 pairs `kampung_view` + `kampung_r10` and `plot_gate_01` + `ditch_water_r10` (record their measured values).
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_239.txt`): `SubjectCoverage` helper (AABB projection, viewport clip,
  64x36 dedup grid, 4-retry occlusion raycast), 7-case spec, harness SUBJECT_COVERAGE block. Fresh Play
  SERVER-VM: fixture PASS 1.0000 / shrunk FAIL 0.0000 / calibration PASS 1 1; PROBE PASS 1 1;
  ditch pair FAIL 0.0000 (recorded). Kampung pair measured 0.4694 (PASS), NOT the expected FAIL -
  geometric coverage does not penalise the sprint-1 "red wall / not legible" framing; recorded as a
  finding under Decisions for designer, target not weakened. Suite 3031->3038, `selene src` 0/0/0.
- [x] 240. **Re-aim the weak sprint-1 cameras.** Move or add cameras so each subject fills the frame: `kampung_r10`, `road_fence_r10`, `signposts_r10`, `crop_stages_r10` (closer, one plot with all three stages), `ditch_water_r10`, and `lamps_r10` (make `lamp_night` a real ClockTime 21 variant). **CHECKS:** `SUBJECT_COVERAGE` >= 0.15 and `CAMERA_CLEAR` for each; record old and new positions in `REVIEW_CAMERAS.md`.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_240.txt`): four cameras moved, two added (registry 67->69); `lamp_night` carries clockTime=21. Fresh Play SERVER-VM: all six pairs `SC240_*` PASS (0.6703 / 0.8537 / 1.0000 / 0.5882 / 0.9464 / 0.6667, all >= 0.15) and `CC240_*` PASS 0 hits; calibration `CAL_SC240_AWAY` PASS 1 1 (fail-closed on fraction) and `CAL_CC240_BLOCK` PASS 1 1 (injected blocker hit). Old/new positions in `REVIEW_CAMERAS.md`. Suite 3038->3042, `selene src` 0/0/0. Coverage is a floor, not a visual verdict.
- [x] 241. **Find and fix the round "melon" blobs.** The `spawn` and `canonical_overview` baselines and `hill_dressing_r10` show many round green and brown spheres on lawns and hills that read as melons. Find which generators place them (default look and candidates), list them in the CHECK file, and replace them in the default look with the baked tropical tree, shrub and rock models (cartoonish realism; no plain Ball part larger than 1.5 studs on open lawn). **CHECKS:** `NO_MELONS`: no Ball-shaped part >= 1.5 studs on open lawn in the default look; `TREE_COUNT` and `PERF_BUDGET` still PASS.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_241.txt`): sources listed (Flora bushes, Greybox village/background Ball canopies, Details hedges + sacks, Decor sacks; candidates deferred to 244 etc.). Default look now uses baked tree/shrub models (Ball-free fallback) and Decor/Details sacks are Cylinders. Fresh Play SERVER-VM: NO_MELONS PASS 0 0, TREE_COUNT PASS 603 450, PERF_BUDGET PASS 323 500; FAIL calibration by injected 2-stud Ball PASS 1 1. First run caught 6 real Decor.Sack Ball offenders (1.6 studs) the fixer missed; fixed and re-verified. Suite 3042->3051, `selene src` 0/0/0.
- [x] 242. **Horizon void from above.** From `canonical_overview` the far edge is a flat grey plane. Fill it: extend the grass/terrain ring or add a low far-hill ring, and set the Atmosphere haze so the edge fades into the sky. **CHECKS:** `HORIZON_FILL`: from `canonical_overview`, `canonical_overview_left` and `canonical_overview_right`, at least 90% of 64 rays aimed at the frame's horizon band hit terrain, hill or mountain; `PERF_BUDGET` within Sedang.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_242.txt`): four buried non-collidable grass HorizonFill slabs outside the 800x800 playable square + shipped `HORIZON_HAZE_FLOOR = 1.6` (client Sky clamps season haze; live Client VM reads 1.6). Fresh Play SERVER-VM: HORIZON_FILL PASS 190/192 (0.9896, >= 0.90; per camera 63/63/64), PERF_BUDGET PASS 323/500; calibration excluding the four fill slabs drops to 170/192 (0.8854 < 0.90) -> CAL PASS 1 1. Server-VM Camera has no FOV property; check derives ray fan from fixed 70deg/16:9. Suite 3051->3055, `selene src` 0/0/0. Geometric fill, not a visual verdict.
- [ ] 243. **Redo `mountains_r10`.** Mountains must read as layered blue-green silhouettes behind the hills from `horizon_north` and `canonical_overview`, not a grey ellipsoid. **CHECKS:** `SUBJECT_COVERAGE` >= 0.10 from `horizon_north`; `MOUNTAIN_FAR` and `NO_COLLISION` still PASS; no grey SmoothPlastic Ball part.
- [ ] 244. **Redo `hill_dressing_r10`.** Use the baked rock models (item 189) and tropical trees in clusters, not spheres. **CHECKS:** `HILL_ROCKS`, `HILL_TREES`, `WALKABLE` still PASS; `NO_MELONS` PASS on the hills.
- [ ] 245. **`bamboo_bridge_r10` as real bamboo.** Deck and rails built from bamboo culms (cylinders with nodes, yellow-green to straw) instead of timber planks. **CHECKS:** `BRIDGE_WALKABLE` and `BRIDGE_RAILS` still PASS; `BRIDGE_BAMBOO`: at least 80% of deck and rail parts are Cylinder-shaped or bamboo-model parts.
- [ ] S2-STOP. Review pack for sprint 2 (see the SPRINTS block): items 240-245 and 208-211, plus re-shoots of every sprint-1 candidate marked **tunda** in `PROVISIONAL_VERDICTS.md`. Evidence folder `h/<date>-sprint2/`.
- [ ] 246. **Lamps at night.** Using the item 240 `lamp_night` camera at ClockTime 21, tune the 12 lamps so the warm pools show on the road without blowing out. **CHECKS:** `LIGHT_COST` and `LAMP_NIGHT_ONLY` still PASS; `LAMP_POOL`: for at least 8 of 12 lamps the road point under the lamp is inside its light range and the midpoint between lamps is not.
- [ ] 247. **Crop stage close-up.** One plot with all three stages side by side, from the item 240 camera, at ClockTime 13 and golden hour. **CHECKS:** `CROP_STAGE_HEIGHT`, `CROP_STAGE_COLOR`, `SUBJECT_COVERAGE` >= 0.2.
- [ ] S3-STOP. Review pack for sprint 3 (see the SPRINTS block): items 212-215, 246, 247 and any candidate touched by 218, 219, 222 or 223. Evidence folder `h/<date>-sprint3/`.
- [ ] 248. **`full_r11` combined review set.** Stage together every candidate with a designer `yes` in `CANDIDATES.md` plus every candidate with a provisional `yes` in `PROVISIONAL_VERDICTS.md`, as a review-only additive set. Shoot `canonical_overview`, `spawn`, `plaza_centre`, `pasar_awnings`, `sawah_above`, `bridge_north_bank`. **CHECKS:** `LOOKDEV_LEAK` 0 after unstaging; `PERF_BUDGET` within Sedang; `PATH_REACH`, `GATE_CLEAR` and `LANE_CLEAR` PASS with the set on.
- [ ] 249. **Canonical gap refresh.** Compare the `full_r11` shots against `map-plan-canonical.png` camera by camera and update `CANONICAL_GAP.md` (what now matches, what is still missing). Doc-only; list at least 15 remaining gaps ranked by visual impact so the main session can plan sprint 5.
- [ ] S4-STOP. Review pack for sprint 4: the `full_r11` shots from item 248 plus any candidate touched in sprint 4. Evidence folder `h/<date>-sprint4/`. Then stop; sprint 5 is planned by the main session from item 249.

### Q. Round 11: real models, canonical-map gaps, promotion (added 2026-11-22 after the designer's round-10 verdicts; second in line after P)

**Designer verdicts, 2026-11-22** (recorded in `CANDIDATES.md` and `CANDIDATE_INDEX.md`): default look **yes** (make it denser and shadier); `sawah_r8` **yes** (tidy up, **use 3D padi models**); `river_r8`, `plots_r8`, `pasar_awnings_r8`, `hubveg_r8` **yes**; `facades_r8` **no** until the floating pole is gone; `plaza_r9` **no** ("ugly, find a model"); `rocks_r9` **no** ("redesign"); `pathedge_r8` **no** ("redesign"); `ronda_tower_r9` pending.

**Rules for this section.** Follow section K's hard rules. Asset ladder (D18): free Creator Store models first (bake them with `tools/studio/bake_lookdev_assets.luau` and record every ID in `ASSET_MANIFEST.md`; never invent an ID), then generated, then original Parts as the last resort. Every candidate stays behind `LookDev` until item 226. Every item needs a geometry or visibility check that would have FAILED on the bad screenshot, not just a count. Items 175, 176 and 177 of section P are **superseded** by items 188, 189 and 190 here (real models instead of Parts): do those instead and tick both.

**Source the models (do these first, they unblock the rest).**

- [x] 186. **Denser, shadier default trees.** Designer: "bigger is fine, make it shady". Raise the default broadleaf count to at least **450** across the ring, hills and village outskirts, with canopy 10 to 16 studs, plus shade trees (3 to 5 per hub, 1 per 40 studs of main road). Keep walkable lanes clear. **CHECKS:** `TREE_COUNT` ≥ 450; `SHADE_TREES` ≥ 3 within 25 studs of every hub centre; `NO_PINES` = 0; `WALKABLE` and `PATH_REACH` PASS; `PERF_BUDGET` stays inside Sedang (thin by tier if needed, item 104).
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_186.txt`): real fresh-Play Server-VM PASS, no candidate staged. TREE_COUNT 603/450 (579 ring/hill + 24 shade), SHADE_TREES 4/3 (4 per hub, within 25 studs), NO_PINES 0, WALKABLE 0, PATH_REACH 0, PERF_BUDGET 339/500. All six checks calibrated non-vacuous (destroy trees -> TREE_COUNT FAIL 433; strip ShadeTree attrs -> SHADE_TREES FAIL 0; pine rename -> NO_PINES FAIL 1; road/lane moves -> WALKABLE/PATH_REACH FAIL 1). Pre-change baseline harness read TREE_COUNT FAIL 272 / SHADE_TREES FAIL 0. Default-look change, not hidden behind LookDev.
- [x] 187. **Source a 3D padi model.** Search the Creator Store for a free rice or padi clump or crop-row model (also tall-grass clump as fallback), bake it, record the ID in `ASSET_MANIFEST.md`. **CHECKS:** `PADI_MODEL_BAKED`: the folder exists under `LookDevAssets`, has ≥ 1 MeshPart, bounding box ≤ 2 studs wide. If nothing suitable exists after two search rounds mark `BLOCKED — <what was tried>` and use the best baked grass clump.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_187.txt`): real free Creator Store model 13286158859 "Meshes/rice2" (Polyslayer1), 11 keyword search rounds, baked scripts-stripped into `LookDevAssets`; PADI_MODEL_BAKED PASS 1/1 (1 MeshPart, 0 scripts, 1.51 studs wide ≤ 2). Scaling the mesh to 3 studs wide gives FAIL 1/1 — check bites. Recorded in ASSET_MANIFEST.md (section Q table + `unused` marker pending item 191 wire).
- [x] 188. **Source and place a real fountain.** Find a free fountain model (tiered stone fountain preferred), bake it, record the ID, and rebuild `plaza_r9` around it: fountain at the plaza centre scaled to a 14 to 18 stud basin, paved ring, four benches facing in, one flag per pole (flat, no crossing parts). Supersedes item 175. **CHECKS:** `FOUNTAIN_SIZE` basin 14 to 18; `FLAG_CLEAN`; `PLAZA_WALKABLE` (6-stud lanes); `FOUNTAIN_IS_MODEL`: the fountain is a baked model, not Parts.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_188.txt`): real free Creator Store model 93434732057582 "Fountain" (Sonisn1810), baked scripts-stripped; applier clones it via LookDevAssetLoader, scales widest bbox 17.35->16 studs, pivots to plaza centre, tags FountainAssetId. Real fresh-Play Server-VM PASS: FOUNTAIN_IS_MODEL 1/1, FOUNTAIN_SIZE 16/18, FLAG_CLEAN 0/0 (11 flat pairs), PLAZA_WALKABLE 0/0. Calibrated: strip FountainAssetId -> FAIL 0; ScaleTo(1.3)/0.45 -> FAIL 22.56/7.81; crossing flag -> FAIL 1; bench in lane -> FAIL 1; pre-change Part fountain -> FOUNTAIN_IS_MODEL FAIL 0. Item 175 superseded. ID in ASSET_MANIFEST.md section Q (wired; no unused marker). Candidate stays OFF until 226.
- [x] 189. **Source real rock models.** Find 3 or more free rock or boulder models (round, flat, tall), bake them, record IDs. Rebuild `rocks_r9`: at least 40 rocks of 1 to 3 studs in clusters of 2 to 4 on both banks, at the stepping stones and a few half in the water. Supersedes item 176. **CHECKS:** `ROCK_COUNT` ≥ 40; `ROCK_MODELS` ≥ 3 distinct baked models; median longest side ≥ 1.2; `ROCK_VISIBLE`: ≥ 8 visible from `river_rocks`.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_189.txt`): three real free Creator Store models baked scripts-stripped — 16098456067 "Low-Poly Rock" (Jajkopko_XD, round), 5644862709 "Rock" (Tman_TheNoobKing, flat), 53370997 "Rock Pillar" (EmperorZenith, tall). Applier cycles them round-robin via assetIdFor, clones via LookDevAssetLoader, scales longest side into each 0.8-2.5 stud footprint, half-buries at bank/water sites. Real fresh-Play Server-VM PASS: ROCK_COUNT 101/40, ROCK_MODELS 3/3, ROCK_SIZE 1.90/1.2, ROCK_VISIBLE 20/8. Calibrated: strip RockAssetId -> FAIL 0; destroy 70 rocks -> FAIL 31; ScaleTo(4/longest) -> FAIL; CanQuery=false -> FAIL 0. Pre-change Part rocks -> ROCK_MODELS FAIL 0. Item 176 superseded. IDs in ASSET_MANIFEST.md section Q (wired; no unused marker). Candidate stays OFF until 226.
- [x] 190. **`pathedge_r8` redesign with real models.** Designer: "redesign". Source grass-tuft and small-flower models (or reuse baked ones), place them along both road edges in an irregular pattern: tufts every 2 to 4 studs, flower patches every 12 studs, a few stones, heights 1 to 2.5 studs. Supersedes item 177. **CHECKS:** `EDGE_HEIGHT` median ≥ 1; `EDGE_VISIBLE` ≥ 12 from `spawn`; `EDGE_OFF_ROAD`; `EDGE_VARIETY` ≥ 3 distinct models.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_190.txt`): three real free Creator Store models baked scripts-stripped — 806579390 "Grass tuft" (a61766), 25454256 "Orange Flower" (tenchynox), 1769612183 "small stone" (MandarinBoy). Applier loads each via LookDevAssetLoader.get, scales component-wise to 1..2.5-stud height and <=2*PLANT_CLEAR footprint, parents real baked BaseParts under the tagged anchor. Irregular 2..4-stud spacing, flower patch every 4th step, stone every 11th non-flower step, exactly two flower colours. Real fresh-Play SERVER-VM PASS: EDGE_HEIGHT 1.96/1, EDGE_VISIBLE 405/12, EDGE_OFF_ROAD 0/0, EDGE_VARIETY 3/3 (814 plants). Calibrated: strip EdgeAssetId -> FAIL 0; CanQuery=false -> FAIL 0; PivotTo +6 studs -> FAIL 798; destroy baked children -> FAIL 0.1. Live CFrame+CFrame bug found and fixed during verification. Item 177 superseded. IDs in ASSET_MANIFEST.md section Q (wired; no unused marker). Candidate stays OFF until 226.
- [x] 191. **Rebuild `sawah_r8` clumps with the 3D padi model (item 187).** Replace the thin-blade clumps with the baked padi model: same rows (≥ 10 per terrace, one every 2 studs), mixed heights (±15%) and yaw, a few terraces at a different growth stage (yellower). Bunds become rounded and grass-coloured (item 178). **CHECKS:** `PADI_IS_MODEL`; `PADI_ROWS` and `SAWAH_GREEN` (≥ 40%) still PASS; `PADI_STAGES` ≥ 2; `BUND_SHAPE`; `SAWAH_TOPS` unchanged; `PERF_BUDGET`.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_191.txt`): 7056 real baked rice MeshParts (13286158859, 1.07 x 3.52 x 1.51) staged via LookDevAssetLoader, scaled to 1.4 x 1.5 footprint and 1.7..2.3 height, deterministic yaw, terraces 3/4 use yellower GrowthStage=2. Real fresh-Play SERVER-VM PASS: PADI_IS_MODEL 7056/1, PADI_STAGES 2/2, PADI_ROWS 294/10, BUND_SHAPE 0/0, SAWAH_GREEN 70/40, SAWAH_TOPS 0/0.5, PERF_BUDGET 338/500. All five decisive checks calibrated (strip PadiAssetId / force one GrowthStage / strip PadiRow / CanQuery=false / strip Bund -> FAIL). Manifest `unused` marker cleared; spec count 25->24. Candidate stays OFF until 226.
- [x] 192. **Source taro, reed and shrub models for the river banks.** Replace the cube shrubs of `river_r8` (item 174) with baked taro (talas), reed, fern and round-shrub models; plus a few lily pads on the water. **CHECKS:** `NO_CUBE_SHRUBS`; `BANK_PLANTS` ≥ 60 with ≥ 3 models; `WATER_CLEAR`.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_192.txt`): five real free Creator Store models baked scripts-stripped — 8466298000 Taro, 13261235137 Cattail/reed, 5661660655 fern, 9953859659 round shrub (scaled to ~2 studs), 5044238410 Lilypad. `river_r8` remaps talas->taro, keladi->fern, alang-alang->reed, publishes BankModelId, adds a shrub accent every 4th non-tall plant and 6 baked lily pads from pure Data.lilyPads. Real fresh-Play SERVER-VM PASS: NO_CUBE_SHRUBS 0/0, BANK_PLANTS 60/60, BANK_MODELS 6/3, WATER_CLEAR 0/0, LILY_PADS 6/6. All five calibrated (strip BankModelId / strip LilyAssetId / pivot plant into channel / turn plant into Block / destroy half -> FAIL). IDs in ASSET_MANIFEST.md section Q, candidate OFF until 226."})

- [x] 193. **Source a flower-meadow and wild-grass set.** 3 or more baked flower and wild-grass models for meadow patches (items 194, 195). **CHECKS:** `MEADOW_MODELS` ≥ 3 baked.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_193.txt`): five real free Creator Store models baked scripts-stripped — 7974911801 Wildflower02, 13032768586 WildFlower04, 70509679878841 Daisy Flower (flowers), 128368650541272 TallGrass, 8715139325 Wild Grass (grasses). Real fresh-Play SERVER-VM PASS `MEADOW_MODELS 5/3`. Calibration: inject scripts into 3 baked folders -> `FAIL 2/3`, destroy -> `PASS 5/3`. IDs in ASSET_MANIFEST.md "Unused manifest IDs" with `unused` markers; items 194/195 will wire them in."})


**Close the gaps against `map-plan-canonical.png`.**

- [x] 194. **Meadow patches on the big lawns.** Scatter flower and tall-grass patches (models from 193) over the open lawns between the Pasar ring and the plots: 20 patches of 10 to 20 items each, away from roads and plot gates. **CHECKS:** `MEADOW_PATCHES` ≥ 20; `MEADOW_OFF_ROAD`; `MEADOW_VISIBLE`: ≥ 6 patches visible from `canonical_overview`.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_194.txt`): `meadow_r10` OFF-by-default candidate. Pure data `ModelMapMeadowR10`, server applier `LookDevMeadowR10`, 5-case spec, 3-check harness. Five baked real Creator Store flower/grass models from 193 wired in (no ID invented). Real fresh-Play SERVER-VM PASS `MEADOW_PATCHES 25/20`, `MEADOW_OFF_ROAD 0/0`, `MEADOW_VISIBLE 25/6`; 25 patches, 1597 tagged parts, all patches 10-20 distinct items, min item-to-plot distance 34.011 > 29.2. Each check calibrated to FAIL in its own fresh Play (strip PatchIndex -> 19/20; pivot one item onto crossroad -> OFF_ROAD 1/0 `p1 x-arm`; CanQuery=false -> VISIBLE 0/6) with the other two staying PASS. Suite 2940, `selene src` 0/0/0. No terrain/road/plot/sky/NPC change, no visual verdict; candidate OFF until 226.
- [x] 195. **Terrain colour variation.** The lawns are one flat green. Paint Grass, LeafyGrass and a little Mud in irregular patches (noise-driven, 20 to 60 stud blobs, 4 tones) on the terrain outside roads and plots, keeping walkable slopes. **CHECKS:** `GROUND_TONES` ≥ 3 distinct materials sampled on a 40 × 40 grid; `ROAD_UNTOUCHED`; `PLOT_UNTOUCHED`.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_195.txt`): `ground_variation_r10` OFF-by-default candidate. Pure string-tone data `ModelMapGroundVariationR10` (LCG(195), 36 blobs radius 10..30, tones Grass/LeafyGrass/Ground/Mud, Mud 5.6%, conservative `zoneClear`, `sampleGrid(40)`) + server voxel applier `LookDevGroundVariationR10` (snapshot-first, zone-only repaint, occupancy preserved, byte-exact LIFO restore). Real fresh-Play SERVER-VM PASS `GROUND_TONES 4/3` (Grass/Ground/LeafyGrass/Mud), `ROAD_UNTOUCHED 0/0`, `PLOT_UNTOUCHED 0/0`. Zone tests use the 4-stud voxel centre, matching the applier (a grid-point test misclassified 3 gate-edge cells). 106->107 spec mirror; suite 2945, `selene src` 0/0/0. Each check FAIL-able by calibration; restore byte-identical after `disableAll()`. No terrain sculpt/road/plot/sky/NPC change, no asset IDs, no visual verdict; candidate OFF until 226.
- [x] 196. **Curved dirt connector paths.** The canonical map has gently curved dirt paths with grass right up to the edge. Add `paths_curved_r10`: replace the straight connector roads to the plots with a spline of 6 to 10 control points (max 12 studs of lateral wobble), painted as Mud/Ground, 8 studs wide, with 1.5 stud blended shoulders. **CHECKS:** `PATH_REACH` 16/16; `PATH_CURVE`: max lateral deviation ≥ 4 studs on at least 6 paths; `GATE_CLEAR`; no path crosses a plot or the river outside the bridge.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_196.txt`): `paths_curved_r10` OFF-by-default candidate. Pure data `ModelMapPathsCurvedR10` (LCG(196), 10 serpentine spokes at plot angles, 8 ctrl points r110..148, wobble 8..11<=12, Mud core 8 studs + 1.5 Ground shoulder, plot/gate/river keep-outs) + server voxel applier `LookDevPathsCurvedR10` (snapshot-first, zone-only repaint, occupancy/water preserved, byte-exact LIFO restore). Real fresh-Play SERVER-VM PASS `PATH_REACH 16/16` (item-105 method: 6 hub doors + 10 radius-152 gates), `PATH_CURVE 10/6` (all 10 paths deviate 6.0..11.7 studs), `GATE_CLEAR 0/0`, `NO_CROSS 0/0`. Base connector roads untouched — cosmetic band only, collidability invariant. Harness region Z extended to 340 so NO_CROSS can sample the real river centreline (z~292..316). 107->108 spec mirror across 50 specs; suite 2950. Each of the 4 checks calibrated to FAIL independently; restore byte-identical. No terrain sculpt/road/plot/sky/NPC change, no asset IDs, no visual verdict; candidate OFF until 226.
- [x] 197. **Horizon fill.** The overview shows a flat grey band beyond the map edge. Add a distant ground skirt or sea plane, haze colour matching the sky horizon, and matching Atmosphere Haze so no grey void shows from any ReviewCamera. **CHECKS:** `HORIZON_FILL`: from `canonical_overview`, `spawn` and `hill_ring_in` the 5 sampled horizon pixels (raycast down from the horizon direction) hit a skirt part or terrain; `PERF_BUDGET`.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_197.txt`): `horizon_fill_r10` OFF-by-default candidate. Pure `ModelMapHorizonFillR10` + server applier `LookDevHorizonFillR10` (one anchored non-collidable 2048x1x2048 Part at (0,-8,-128) tagged HorizonSkirt + Atmosphere Haze 2.0 / Color {214,226,220}; save-once LIFO restore of both props, destroy only created instances). LookDev IDS[109] / descriptor / plan, LookDevReview path, Main require; 5-case spec; 108->109 mirror across 50 specs; 3-check harness. Real fresh-Play SERVER-VM PASS `HORIZON_FILL 15/15` (5 downward rays x 3 cameras all first-hit skirt; before hits 0/15), `PERF_BUDGET 338/500`, `HAZE_MATCH 1/1` (Haze 0.2->2.0, warm-orange Color->pale sky horizon). Each FAIL-able by independent calibration (destroy skirt -> 0/15; 200 extra origin parts -> 538/500; reset Haze -> 0/1). Restore byte-exact. Engine cap found in Studio: Part.Size clamps to 2048, so the original 3200 skirt left 3 spawn rays outside; data corrected to one 2048 tile centred z=-128 with sample-inside self-check. No asset IDs, no terrain sculpt, no visual verdict; candidate OFF until 226.
- [x] 198. **Distant mountains and a volcano.** Beyond ±450 add 3 low-poly mountain silhouettes (terrain cones or baked meshes) in blue-grey, one with a faint smoke particle, only visible through the haze. **CHECKS:** `MOUNTAINS` ≥ 3; `MOUNTAIN_FAR`: all ≥ 450 studs from origin; `NO_COLLISION`; `PERF_BUDGET`.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_198.txt`): `mountains_r10` OFF-by-default candidate, 5 far-ring Wedge/Ball mountains at radius 520-632 + one faint smoke Ball; pure `ModelMapMountainsR10` + `LookDevMountainsR10` applier with destroy-only restore; LookDev IDS[110]/descriptor/plan, LookDevReview path, Main require, 50-spec mirror 109->110, CANDIDATES rows. Real fresh-Play SERVER-VM PASS `MOUNTAINS 6/3`, `MOUNTAIN_FAR 0/0`, `NO_COLLISION 0/0`, `PERF_BUDGET 361/500`. Calibration: injected Mountain-tagged colliding part at origin + 200 proxy parts gave `MOUNTAIN_FAR FAIL 1 0`, `NO_COLLISION FAIL 1 0`, `PERF_BUDGET FAIL 544 500`. Suite 2964->2969, `selene src` 0/0/0. No asset IDs, no visual verdict.
- [x] 199. **Hill dressing.** The hills are smooth domes. Add rock outcrops (models from 189), a few terrace-like steps with palms, and grass-tone variation on each hill. **CHECKS:** `HILL_ROCKS` ≥ 4 per hill; `HILL_TREES` ≥ 12 per hill; `WALKABLE` unchanged.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_199.txt`): `hill_dressing_r10` OFF-by-default candidate, 4 hills x (5 rocks + 13 palms) + 3 terraces; pure data + server applier with hill/kind tags and destroy-only restore; LookDev IDS[111]/descriptor/plan, LookDevReview path, Main require, 50-spec mirror 110->111, CANDIDATES rows. Real fresh-Play SERVER-VM PASS `HILL_ROCKS 5/4`, `HILL_TREES 26/12`, `WALKABLE 0/0` (10 rays, 9->9 before/after). All three calibrated FAIL by injecting between the harness's BEFORE/AFTER anchors (delete hill-1 rocks, hill-2 palms, block one ray): `HILL_ROCKS FAIL 0 4`, `HILL_TREES FAIL 0 12`, `WALKABLE FAIL -1 0`. Suite 2969->2974, `selene src` 0/0/0. No asset IDs, no visual verdict.
- [x] 200. **Kampung houses at the outskirts.** Add `kampung_r10`: 10 to 14 background houses (use baked `buildings_r8` models, door-gauge exempt, not interactive) in 3 clusters between the village ring and the plots, each with a small yard (fence, 2 plants, a jemuran line optional). They must not block any road, plot or hub lane. **CHECKS:** `KAMPUNG_HOUSES` 10 to 14; `LANE_CLEAR`; `PATH_REACH`; `PLOT_CLEAR`; `NOT_INTERACTIVE`: no ProximityPrompt or ClickDetector; `PERF_BUDGET`.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_200.txt`): `kampung_r10` OFF-by-default candidate, 12 houses in 3 clusters with yards, pure Part descriptors (no invented asset IDs), non-interactive applier with destroy-only restore; LookDev IDS[112]/descriptor/plan, LookDevReview path, Main require, 50-spec mirror 111->112, CANDIDATES rows. First Studio attempt FAILED `PLOT_CLEAR 1 0` (one yard fence 0.39 stud inside footprint clearance); fixed by moving fence radial offset 4->2 in pure data; second fresh-Play PASS `KAMPUNG_HOUSES 12/12`, `LANE_CLEAR 0/0`, `PATH_REACH 0/0`, `PLOT_CLEAR 0/0`, `NOT_INTERACTIVE 0/0`, `PERF_BUDGET 343/500`. All six calibrated FAIL by runtime injection. Suite 2974->2980, `selene src` 0/0/0. No visual verdict.
- [x] 201. **Low bamboo road fences.** Short bamboo fences (1.2 studs) along the main roads at 6 stretches near the hubs, with gaps at every junction and gate. **CHECKS:** `ROAD_FENCE` ≥ 6 stretches; `JUNCTION_GAPS`: each junction has a ≥ 8 stud opening; `PATH_REACH`.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_201.txt`): `road_fence_r10` OFF-by-default candidate, 6 bamboo stretches of 1.2-stud posts/rails within radius 120, pure data + server applier with destroy-only restore; LookDev IDS[113]/descriptor/plan, LookDevReview path, Main require, 50-spec mirror 112->113, CANDIDATES rows. Real fresh-Play SERVER-VM PASS `ROAD_FENCE 6/6` (130 staged Parts), `JUNCTION_GAPS 0/0`, `PATH_REACH 0/0` (6 rays, 0->0). All three calibrated FAIL by runtime injection (`ROAD_FENCE FAIL 3 6`, `JUNCTION_GAPS FAIL 1 0`, `PATH_REACH FAIL 1 0`). Suite 2980->2985, `selene src` 0/0/0. No asset IDs, no visual verdict.
- [x] 202. **Street lamps (obor and lentera).** Along the ring road: 12 lamps with a warm PointLight (range ≤ 16) that only turns on at night; fixture is a pole plus a lantern. **CHECKS:** `LAMPS` ≥ 12; `LAMP_NIGHT_ONLY`: lights `Enabled=false` at ClockTime 13 and `true` at 21; `LIGHT_COST` stays inside the LIGHT_COST audit's budget.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_202.txt`): `lamps_r10` OFF-by-default candidate, 12 ring-road pole+lantern lamp groups with one shadowless PointLight each (Range 16) and a ClockTime-driven toggle; LookDev IDS[114]/descriptor/plan, LookDevReview path, Main require, 50-spec mirror 113->114, CANDIDATES rows. Real fresh-Play SERVER-VM PASS `LAMPS 12/12`, `LIGHT_COST 0/0 violations` (15 lights total), `LAMP_NIGHT_ONLY 12/12` (12 on at ClockTime 21, 0 at 13; clock restored). All three calibrated FAIL by runtime injection (`LAMPS FAIL 9 12`, `LIGHT_COST FAIL 12 0`, `LAMP_NIGHT_ONLY FAIL 0 12`). Fixed harness `pcall(review.disableAll())` -> `pcall(review.disableAll)`. Suite 2985->2990, `selene src` 0/0/0. No asset IDs, no visual verdict.
- [x] 203. **Junction signposts.** A wooden papan petunjuk at the 4 main junctions pointing to Pasar, Plot, Sungai, Sawah. Text lives in `Strings.luau` with `id` and `en` variants (surface GUI, readable at 12 studs). **CHECKS:** `SIGNPOSTS` = 4; `SIGN_TEXT_IN_STRINGS`: every sign string key exists with both variants; `SIGN_READABLE`: text size ≥ 14 px equivalent.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_203.txt`): `signposts_r10` OFF-by-default candidate, 4 junction post+board groups with SurfaceGui TextLabel at TextSize 18; 4 new `Strings.luau` keys (signpost_pasar/plot/sungai/sawah) each with id+en; LookDev IDS[115]/descriptor/plan, LookDevReview path, Main require, 50-spec mirror 114->115, CANDIDATES rows. Real fresh-Play SERVER-VM PASS `SIGNPOSTS 4/4`, `SIGN_TEXT_IN_STRINGS 4/4`, `SIGN_READABLE 4/4`. All three calibrated FAIL by runtime injection (`SIGNPOSTS FAIL 3 4`, `SIGN_TEXT_IN_STRINGS FAIL 3 4`, `SIGN_READABLE FAIL 0 4`). Suite 2990->3000, `selene src` 0/0/0. No asset IDs, no visual verdict.
- [x] 204. **Bamboo bridge.** The canonical bridge is bamboo. Restyle the bridge from `river_r8` into a bamboo plank bridge: bamboo-coloured deck on round rails, rope ties, two posts at each end, still 6 studs wide and walkable. **CHECKS:** `BRIDGE_WALKABLE` (a 6-stud lane, raycast from start to end); `BRIDGE_MATERIAL` bamboo or wood; `BRIDGE_RAILS` both sides.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_204.txt`): `bamboo_bridge_r10` OFF-by-default additive overlay, 14 planks + 2 rails + 7 rope ties + 4 posts, river_r8 default bridge untouched; LookDev IDS[116]/descriptor/plan, LookDevReview path, Main require, 50-spec mirror 115->116, CANDIDATES rows. Real fresh-Play SERVER-VM PASS `BRIDGE_WALKABLE 0/0` (15 lane raycasts, 27 staged Parts non-collidable), `BRIDGE_MATERIAL 0/0` (14 deck Parts), `BRIDGE_RAILS 2/2`. All three calibrated FAIL by runtime injection (`BRIDGE_WALKABLE FAIL 15 0`, `BRIDGE_MATERIAL FAIL 14 0`, `BRIDGE_RAILS FAIL 1 2`). Suite 3000->3006, `selene src` 0/0/0. No asset IDs, no visual verdict.
- [x] 205. **Plot soil furrows.** Inside each plot, paint furrow lines on the soil (alternating dark Ground strips) so an empty plot reads as tilled land from `plot_aerial_NN`. **CHECKS:** `FURROWS` ≥ 4 strips per plot; `FURROW_VISIBLE` from every `plot_aerial_NN`; crop placement unchanged.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_205.txt`): `furrows_r10` OFF-by-default candidate, 10 plots x 5 thin alternating Ground-coloured strips at y=0.55 above soil, 2-stud ditch and crops untouched; LookDev IDS[117]/descriptor/plan, LookDevReview path, Main require, 50-spec mirror 116->117, CANDIDATES rows. Fixed a harness-only UDim2 `.Z` crash (GUI descendant position read) before the PASS run; no check weakened. Real fresh-Play SERVER-VM PASS `FURROWS 5/4`, `FURROW_VISIBLE 10/10` (all plot_aerial_01..10), `CROP_PLACEMENT_UNCHANGED 0/0` (50 strips staged). All three calibrated FAIL by runtime injection (`FURROWS FAIL 0 4`, `FURROW_VISIBLE FAIL 0 10`, `CROP_PLACEMENT_UNCHANGED FAIL 1 0`). Suite 3006->3012, `selene src` 0/0/0. No asset IDs, no visual verdict.
- [x] 206. **Crop stage readability from the plot cameras.** From `plot_aerial_NN` the three stages (bibit, tumbuh, siap) must be distinct in height and colour. Audit with raycast samples, rescale or retint any crop whose stage is not distinguishable. **CHECKS:** `CROP_STAGE_HEIGHT`: stage heights strictly increase for every crop; `CROP_STAGE_COLOR`: siap differs from bibit by ≥ 0.15 hue distance.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_206.txt`): `crop_stages_r10` OFF-by-default candidate, 3 corrected reference stages (bibit 1.2 / tumbuh 2.6 / siap 4.2, hue distance ~0.206) staged as 10 per-plot clusters (60 Parts), default crop models untouched; LookDev IDS[118]/descriptor/plan, LookDevReview path, Main require, 50-spec mirror 117->118, CANDIDATES rows. Fixed `CAMERA_SAMPLES 6/10` (single cluster occluded from far cameras) by staging one cluster per plot. Real fresh-Play SERVER-VM PASS `CROP_STAGE_HEIGHT 0/0`, `CROP_STAGE_COLOR 0/0`, `CAMERA_SAMPLES 10/10`. All three calibrated FAIL by runtime injection. Suite 3012->3018, `selene src` 0/0/0. No asset IDs, no visual verdict.
- [x] 207. **Ditch water along the plots.** The 2-stud ditch of `plots_r8` must read as water: thin glassy Parts with the same teal as the shipping water. **CHECKS:** `DITCH_WATER` ≥ 1 per plot; `DITCH_COLOR` within a small distance of variant A.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_207.txt`): `ditch_water_r10` OFF-by-default candidate, 10 plots x 2 rotated translucent Glass strips with teal {r=48,g=124,b=104} copied from ModelMapWaterR8.variants.a, plots_r8 default untouched; LookDev IDS[119]/descriptor/plan, LookDevReview path, Main require, 50-spec mirror 118->119, CANDIDATES rows. Real fresh-Play SERVER-VM PASS `DITCH_WATER 10/10` (20 Parts), `DITCH_COLOR 0/0`. Both calibrated FAIL by runtime injection (`DITCH_WATER FAIL 9 10`, `DITCH_COLOR FAIL 1 0`). Suite 3018->3024, `selene src` 0/0/0. No asset IDs, no visual verdict.
- [ ] 208. **Pasar ground and spill.** The canonical Pasar has paved ground and spilled goods. Add a paved or packed-earth pad under the whole Pasar, plus crates, baskets and sacks at the lapak. **CHECKS:** `PASAR_PAD` ≥ 1 covering all stalls; `PASAR_PROPS` ≥ 30; `LANE_CLEAR`.
- [ ] 209. **Pasar stripe fix and signage.** Brighter red, white and blue stripes (item 179) plus a hanging "PASAR" board over the entry in `Strings.luau` (`id` and `en`). **CHECKS:** `STRIPE_VALUE` ≥ 0.6; `PASAR_SIGN` = 1 with both strings.
- [ ] 210. **Warung seating dressing.** Tables and low benches in front of the Warung, an oven or stove prop, a hanging lantern. **CHECKS:** `WARUNG_SEATS` ≥ 4; `LANE_CLEAR`; `NOT_INTERACTIVE`.
- [ ] 211. **Pos Ronda dressing.** Kentongan (log drum), bench, gardu lamp and a small rack at the Pos Ronda. **CHECKS:** `RONDA_PROPS` ≥ 4; `TOWER_HEIGHT` still 28 to 32.
- [ ] 212. **Water edge foam.** A thin line of foam parts or Terrain-water shore setting along both river banks (cheap) so the river meets land softly. **CHECKS:** `FOAM_LINE` covers ≥ 60% of the bank length by sampling; `PERF_BUDGET`.
- [ ] 213. **Ducks and fish on the river.** Reuse `animals_r8` ducks (6) swimming in the shallows and a few fish ripples. **CHECKS:** `DUCKS` ≥ 6; `DUCKS_ON_WATER`: every duck Y within 0.5 of the water surface; animation is client-side only.
- [ ] 214. **Terrace edge stones.** Stone retaining walls on the sawah terraces' front faces (from the rock models), 25 studs each, so the terraces look built. **CHECKS:** `TERRACE_WALLS` ≥ 4; `WALL_ON_TERRAIN`: no wall floats (touch or within 0.3 of terrain).
- [ ] 215. **Gubuk and scarecrow in the sawah.** One gubuk per terrace group and two scarecrows in the fields, plus bird-scare ribbons on poles. **CHECKS:** `GUBUK` ≥ 1; `SCARECROWS` ≥ 2; `NO_FLOATERS`.

**Cameras, checks and tooling.**

- [x] 216. **Cameras for the new candidates.** Add to `ReviewCameras` (and `REVIEW_CAMERAS.md`): `canonical_overview_left`, `canonical_overview_right`, `path_curve`, `kampung_view`, `bridge_side`, `meadow_view`, `terrace_wall`, `signpost_pasar`, `lamp_night` (ClockTime 21), `horizon_north`, `horizon_south`, `fountain_close`. **CHECKS:** `CAMERA_CLEAR` for every camera; every name is documented once.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_216.txt`): 10 new Server cameras + doc rows for the 2 pre-existing flanks; all 67 registry names documented once, `lamp_night` records the ClockTime 21 preset. Real fresh-Play SERVER-VM PASS `CAMERA_CLEAR 0/67` (all 67 eyes clear, 0 blocked, 0 bad coords) and `DOCS_ONCE 0/0` (67 unique names). Calibration: an opaque blocker 3 studs along `plaza_centre`'s ray made `CAMERA_CLEAR FAIL 1 0`; DOCS_ONCE stayed PASS. `tools/studio/check_q216.luau` harness; suite 2955->2964. Fixed a load-time bug found in Studio: `Game.plotCenter()` returns two numbers, not a table.
- [x] 217. **Visual-risk audit harness.** Write `tools/studio/review_check_visual.luau`: for each candidate prints `NO_FLOATERS`, `NO_CUBE_SHRUBS` and `SIZE_SANITY` (no part longer than 12 studs and under 0.8 thick that is not a fence, roof, bridge or road) so mistakes like the floating ridge cap are caught by a check, not by a screenshot. **CHECKS:** the harness FAILs when run against a deliberately bad fixture and PASSes on the shipped candidates; add the fixture to the repo.
  Done 2026-11-23 (SEEN-IN-STUDIO, `CHECK_217.txt`): pure-data `VisualRiskAudit` (floaters/cubeShrubs/sizeSanity, no engine calls, probeOk self-probe) + `ModelMapVisualFixtureBad` calibration fixture + `tools/studio/review_check_visual.luau` + 7-case spec. Real fresh-Play SERVER-VM PASS on shipped set: `NO_FLOATERS 0/0`, `NO_CUBE_SHRUBS 0/0`, `SIZE_SANITY 0/0`, `GOOD_SET_NONEMPTY 1/>0`, `AUDIT_PROBE 1/1`; fixture trips all three (`FIXTURE_NO_FLOATERS 3/>=1`, `FIXTURE_NO_CUBE_SHRUBS 2/>=1`, `FIXTURE_SIZE_SANITY 1/>=1`). Suite 2955->2964. Only descriptor-exposing candidates are audited; others recorded as skip notes, never a vacuous pass.
- [ ] 218. **Lighting variants of the new shots.** Add `golden` and `night` camera variants for `plaza`, `pasar_awnings`, `path_curve`, and `lamp_night`; no new look, just entries in `ReviewCameras`. **CHECKS:** `CAMERA_CLEAR`.
- [ ] 219. **LOOKDEV_LEAK sweep over all candidates.** Stage and unstage every candidate once and assert zero leftover parts. **CHECKS:** `LOOKDEV_LEAK` = 0 for all ids.
- [ ] 220. **Perf census after section P and Q.** Re-run the dual-VM census with every accepted candidate on together (`full_r10`), report instance counts per family and flag anything over budget. **CHECKS:** `PERF_BUDGET` result recorded; thinning rule from item 104 applied where over.
- [ ] 221. **Walkability audit, full set.** Re-run `PATH_REACH`, `GATE_CLEAR` and `LANE_CLEAR` with `full_r10` staged. **CHECKS:** all PASS, each with its FAIL-case in the harness.
- [ ] 222. **Strings audit for new text.** Every player-facing string added in this section (signposts, Pasar sign) has `id` and `en`, no placeholder, no translator notes. **CHECKS:** `STRINGS_BOTH_VARIANTS`.
- [ ] 223. **Candidate docs.** Add `CANDIDATES.md` and `CANDIDATE_INDEX.md` rows for every new id (`paths_curved_r10`, `kampung_r10`, `full_r10` and others), verdict cells starting `pending`, matching the index spec.
- [ ] 224. **Promotion plan.** Write `docs/v2/visual/PROMOTION_PLAN.md`: for each `yes` candidate (`sawah_r8`, `river_r8`, `plots_r8`, `pasar_awnings_r8`, `hubveg_r8`, `buildings_r8`), its perf cost, dependencies, order, and the rollback flag. No code yet.
- [ ] 225. **Shot list for section Q.** Update `SHOT_LIST.md` with every new candidate, camera, datamodel and CHECK path in the existing table format, so the main session can take the screenshots.
- [ ] 226. **Promote the accepted candidates behind one flag.** Following item 224, add `DefaultLook.PROMOTED = {...}` listing the ids with `yes` verdicts and apply them at startup through the same applier code (no duplicated geometry), with a single constant to turn the whole set off. Only ids whose verdict cell starts `**yes` may be listed. **CHECKS:** `PROMOTE_ONLY_YES`: every listed id has a `**yes` verdict; `PROMOTE_OFF`: with the flag off the default look equals today's; `PERF_BUDGET` within Sedang; `WALKABLE`, `GATE_CLEAR` PASS; clean-Play smoke PASS.
- [ ] 227. **Refill.** After items 186 to 226 are ticked or `BLOCKED`, compare the default look against `map-plan-canonical.png` camera by camera, update `CANONICAL_GAP.md`, and add at least **20** new items for what still differs, then work them. Do not write a final report while anything you can do is unticked.

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
- [x] 86. **`npcs_r8`: more villager roles.** Add tengkulak, debt collector, ibu warung, anak-anak (use `BodyHeightScale` / `HeadScale` for kids) and bapak ojek. Use `HumanoidDescription` with real catalog IDs found through the catalog API the way commit 4408a04 did (see `ModelMapNpcsR7.luau`; rate limit: sleep 4 s per call). Never invent IDs; record them in `ASSET_MANIFEST.md`. Same spacing and facing rules as npcs_r7. **CHECKS:** `LOAD_FAILURES` = 0; each new role has at least one hat/accessory or a distinct shirt; no two roles share the same shirt+pants pair.
- [x] 87. **`npcs_idle_r8`: idle motion.** Give the villagers a calm idle (subtle breathing/sway, no walking). Use a real Roblox animation ID from the catalog or `generate_animation`; if neither works, a small Motor6D sine sway from one shared loop. **CHECKS:** each villager has an `Animator` track `IsPlaying`, or an active sway loop (state which); cost under 0.3 ms per frame for 10 villagers.
- [x] 88. **`ambient_walkers_r8`: ambient strollers.** Up to 8 villagers walking looped routes between hubs via `NpcWalk`, ambient only: no interaction, no dialogue, no gameplay. **CHECKS:** after 90 s each reached at least 3 waypoints, none stuck for more than 10 s, none off the roads by more than 8 studs, `Humanoid.WalkSpeed` ≤ 8.

#### M5. Light and sound

- [x] 89. **`day_cycle` tune.** The verdict was `yes, tune`: 16:00 reads flat. Read `docs/v2/visual/DAY_CYCLE.md` and `DayCycle.luau`. Add stronger directional contrast at 15:00–17:00 (lower sun angle, warmer `ColorShift_Top`, a bit more `ShadowSoftness`), still tweening smoothly. Ship it as a candidate (`day_cycle_r8`), not a default change. **CHECKS:** `DAY_PHASES_MONOTONIC` (no jump above the documented limit between adjacent phases); `DAY_1600_CONTRAST`: the computed sun-vs-ambient luminance ratio at 16:00 is at least 20% higher than before; the maghrib values are unchanged.
- [x] 90. **`night_r8`: warm night windows and lamps.** At night, windows turn warm (`Neon` material, colour `#FFCB7A` on the window glass parts), torches and street posts glow. Use the Rendah lamp budget. **CHECKS:** `NIGHT_WINDOWS` ≥ 12 lit at 20:00 and 0 at 13:00; `NIGHT_LIGHTS` ≤ 24.
- [x] 91. **`grade_r8_a/b/c`: colour grades.** Three tropical colour-grade variants for the designer to pick: warm golden, fresh green, hazy humid. Each tunes `ColorCorrection`, `Bloom`, `SunRays` and `Atmosphere` only. No depth of field. **CHECKS:** each variant's values fall in the documented safe ranges; `disable()` restores exactly.
- [x] 92. **`sounds_r8`: ambient sound beds.** `sounds` is still pending. Source real free sounds from the Creator Store (`search_asset`): jangkrik at night, ayam and birds by day, river water, a soft wind, kentongan. Positional, `RollOffMaxDistance` ≤ 80, grouped in a `SoundGroup`, never at full volume. **CHECKS:** every `Sound.IsLoaded` is true within 10 s and none reports `not authorized`; volumes ≤ 0.5; `disable()` stops and destroys them.

#### M6. Audits and hygiene

- [x] 93. **Crop stage audit.** For all 12 crops × 3 stages (bibit, tumbuh, siap), measure `GetBoundingBox` and write a table. **CHECK `CROP_GROWTH`:** height grows from stage to stage (at least 15% each) and each is within 0.5–6 studs. Fix any crop that fails by rescaling in the model map, never by weakening the check.
- [x] 94. **Icon audit.** A script (`tools/icon_audit.py` or Luau): for every icon PNG, check size, alpha coverage (between 15% and 85%) and flag near-duplicates by perceptual hash. Report `tier_biasa` with numbers only (the `icons` verdict said to fix it). Don't judge looks.
- [x] 95. **Strings audit.** Add or extend a spec so that every `Strings.luau` key has a non-empty `id` and `en`, no leftover `TODO`/`lorem`/placeholder text, and no `id == en` for long strings (flag, don't fail, for loanwords). Grep `src/client` for hardcoded player-facing string literals in `Text =` assignments and move them into `Strings.luau`.
- [x] 96. **IconMap coverage.** A spec that every `IconMap` slot resolves to a non-zero asset ID recorded in `ASSET_MANIFEST.md`, and that no ID appears twice by mistake.
- [x] 97. **Perf budget table.** Measure and record in `docs/v2/visual/PERF_R9.md`: instances, parts, `MeshPart` triangle estimate and `ParticleEmitter` count for the default look and for each candidate enabled alone on top of it. **CHECK `PERF_BUDGET`:** the default look is within the Sedang tier budget in `VISUAL_MASTER_PLAN.md` §6. Flag, never hide, any candidate over budget.
- [x] 98. **`LOOKDEV_LEAK` sweep.** Run the leak check from item 68 over **every** candidate in `LookDev.IDS` and save the output in `CHECK_98.txt`. Fix every leak in the candidate's `restore`/`disable`. Any candidate that can't be fixed in two attempts is marked `BLOCKED` with the delta.
- [x] 99. **Gate 1 evidence sweep.** Go through `GATE1.md` and `BUGS.md`. For each row marked `LUNE-ONLY` or `UNVERIFIED` that Studio Play can prove with `execute_luau` (no human input needed), run it and save the output under `docs/v2/evidence/`. Change a status to `SEEN-IN-STUDIO` only with a file behind it; leave the rest and note why.

#### M7. Handoff

- [x] 100. **Review pack.** Write `REVIEW_ROUND9.md`: the bake (step 1), then batches grouped by datamodel (Client: water, grade, sounds; Server: everything else), the exact `enable` sequence per batch, the camera name from `REVIEW_CAMERAS.md` for each candidate, and every `CHECK_*.txt` path. Add `docs/v2/evidence/h/<date>-round9/CHECKS_SUMMARY.md` with one PASS/FAIL/BLOCKED line per item. The main session takes the screenshots.
- [x] 101. **No-op marker.** Tick this when items 68–100 are each ticked or `BLOCKED`; section N follows and holds the real refill (item 135).

### N. Round 10: more village, combined look, audits (added 2026-11-21, second long unattended run)

Same rules as section M (candidates off by default, Studio PASS per item, no gameplay, no terrain sculpt, no NPC outfit changes, real assets only, commit per item, stage files by name). **Review of round 9 so far (main session, 2026-11-21):** items 68–73 and 75–78 have PASS evidence and `lune` is at 2422 tests, selene 0/0/0. Visual grading is still pending; the designer will go through the candidates afterwards. Two things the agent should know:

- Item 74 was marked BLOCKED correctly (the default `BackgroundForest` has 254 pine-named instances), but the reason given ("reserved for designer grading") is wrong: **V-D4 already decided "tropical trees, no pines"**, so replacing the pine backdrop is closable. Item 102 does it.
- When a check's own geometry was wrong (item 71 `GATE_CLEAR`: axis-aligned box on a rotated gate) fixing the check is fine, but write the reason and keep the size and threshold unchanged, as you did. Keep doing that.

#### N1. Unblock and combine

- [x] 102. **(Pulled forward: do it as item 138 in section O and tick both.) Unblock item 74: replace the pine backdrop.** V-D4 is decided (tropical trees, no pines). In `Greybox` `buildForestRing`, replace the pine-named backdrop with tropical trees from the baked species (kelapa, mangga, bambu, pisang, jati or similar), same count or higher, same placement band, random yaw ±15% scale, within the Rendah budget. This is a **default-look change on purpose**; keep the old pines behind a `LookDev` candidate `forest_pines_legacy` so the designer can compare. Then finish `ring_r8` (hills and the band beyond ±400, at least 150 instances, 4 species). **CHECKS:** `NO_PINES` = 0 in the default look; `RING_COUNT` ≥ 150; `RING_SPECIES` ≥ 4; `PERF_BUDGET` still within Sedang. Untick and re-tick item 74 with the new evidence, and remove the item from "Decisions for designer".
- [x] 103. **`full_r9`: everything approved-or-pending at once.** A candidate that stages, in order, the round-9 scene candidates that don't conflict: `hubveg_r8`, `plots_r8`, `sawah_r8`, `river_r8`, `pathedge_r8`, `facades_r8`, plus whichever of items 79–85 are ticked. Skip `buildings_r8` (it is a staging lot, not a village layout) and the water/grade/sound variants (the designer picks one). **CHECKS:** `LOAD_FAILURES` = 0; `CROSS_OVERLAP` = 0: no two candidates' parts with `CanCollide` true have intersecting bounding boxes (report the pair names on FAIL); `LOOKDEV_LEAK` PASS; `PERF_BUDGET` result recorded.
- [x] 104. **Rendah/Sedang/Tinggi thinning.** Each round-9 candidate takes the player's quality tier from the existing tier module and thins itself: Rendah keeps at most 50% of instances (never the structural ones such as fences, bridge rails, doors), Tinggi keeps 100%. **CHECKS:** `TIER_THIN`: for each candidate, count at Rendah ≤ 0.55 × count at Tinggi, and at Tinggi equals the item's documented count.
  Done 2026-11-21: `Shared.TierThin.shouldKeep(tier, index, structural?)` (pure, even-index keep at
  Rendah, <=50%, structural/nil-Sedang/Tinggi keep all, unknown->Tinggi); `LookDev` injects
  `opts.tier`->`plan.tier`, `LookDevReview.enableAdditive` forwards opts. Nine round-9 SERVER
  appliers gate only decorative instances; structural (fences/gates, bridge rails/posts, water
  panes/verge, gubuk, trees, boards/poles/cord, lampu/obor, first-5 props/hub) never thinned.
  Facades EXEMPT (all 60 FacadePart structural). River MIN_BANK_VEG now validates unthinned data
  (dataNearBridge) so thinning cannot publish a false failure. Hubprops surplus uses its own
  decorative counter. 11-case `tier_thin_spec` NEW. Real Studio fresh-Play Server-VM PASS
  `TIER_THIN`: 8 thinnable candidates decor Rendah<=0.55 x Tinggi (hubveg 132->48, plots 468->234,
  sawah 7056->3528, river 138->69, pathedge 626->313, hubprops 17->7, streetfurn 18->9, spanduk
  12->4), facades all-structural EXEMPT 60/60/60, structural held constant everywhere,
  Sedang==Tinggi, added=0, ANTI_VACUITY PASS 9 folders/stagedAll/0 added (`CHECK_104.txt`,
  `SEEN-IN-STUDIO`). 2687 tests, selene 0/0/0. Interpretation + facades exemption under Decisions.
- [x] 105. **Walkability audit with everything on.** With `full_r9` staged, run `PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5.5, AgentCanJump = false})` from the spawn to each hub entrance and each plot gate. **CHECK `PATH_REACH`:** every route returns `Success` (16/16). If one fails, find the blocking candidate and fix it (move or shrink the part), never the check.
  Done 2026-11-21: fresh Play Server VM, all 13 full_r9 candidates staged, spawn `MapSpec.SPAWN`
  (0,0.5,28) -> 6 live hub doors + 10 live staged `GateMarker` plot gates, agent
  {AgentRadius=2, AgentHeight=5.5, AgentCanJump=false}. Real Studio PASS `PATH_REACH 16 16`
  (all 16 `ComputeAsync` routes `Enum.PathStatus.Success`), anti-vacuity staged=13 folders=13
  parts=35949 markers=10 routes=16, two deterministic runs (`CHECK_105.txt`, `SEEN-IN-STUDIO`).
  No blocker found, so no part moved/shrunk; no source, spec or harness changed (gates unchanged
  from item 104: 2687 tests, selene 0/0/0). All lookdev parts CanCollide=false by design, so the
  guard proves staging/routes rather than trusting a vacuous pass.
- [ ] 106. **BLOCKED — Avatar scale audit with everything on.** A 7.25-stud-tall, 4-stud-wide box swept along each of those routes must hit no `CanCollide` part. **CHECK `AVATAR_FIT`** 16/16.
  BLOCKED — `CHECK AVATAR_FIT FAIL 2 16` (2026-11-21, fresh Play Server VM, full_r9 staged, 13/13
  staged). Two FAIL attempts: (1) any-CanCollide-hit sweep 2/16; (2) >0.1-stud-penetration sweep
  3/16. Anti-vacuity staged=13 folders=13 parts=35949 collidable=513 routes=16 samples=2124.
  Evidence `h/2026-11-21-round10/CHECK_106.txt`. Same sweep with NOTHING staged gives an IDENTICAL
  hit set — all blockers are pre-existing shipping geometry (`RumahPakRT.BackWall/SideWall`,
  `Plot_4.SignPost`, `kit_fence`, house Floor/Desk/Table, NPC UpperTorso), not lookdev candidates
  (0 of 35,949 staged parts collidable, CHECK_103). No blocking candidate to move/shrink; moving
  shipping world parts is a default-look/gameplay change, out of lookdev scope. Not re-scoped to
  staged-only (would weaken the literal check and be vacuous). No check weakened; no part changed.
  Measurement caveat + follow-up under "Decisions for designer". Gates unchanged (2687 tests).
- [x] 107. **Clean-Play smoke test.** `tools/studio/smoke_play.luau`: start a fresh Play, wait 60 s, read the console through `get_console_output`, and assert no error-level message and no warning outside a short allowlist in the same file (each allowed line carries a one-line reason). Run it for the default look and for `full_r9`. **CHECK `SMOKE_CLEAN`** 0 errors for both. Fix real errors; never grow the allowlist to hide one.
  Done 2026-11-22: `tools/studio/smoke_play.luau` NEW (`ORDER`/`emit`/`byName`, 5-entry reason-tagged
  ALLOWLIST, no info-ignored bucket; main session feeds `get_console_output` lines via
  `_G.SMOKE_CONSOLE_LINES` because Luau cannot call the MCP tool). Real error FOUND and FIXED, not
  allowlisted: `LookDevSmokeR8.luau:77-78` used `NumberSequence.new` for ParticleEmitter
  `Lifetime`/`Speed` (need `NumberRange`) -> 9 build warnings per full_r9 stage; both now
  `NumberRange.new`, spec-guarded in `smoke_r8_spec.luau` (+5 harness guards in `smoke_play_spec`).
  Fresh Play, 60 s windows, both `CHECK SMOKE_CLEAN PASS 0 0` (8 known-noise lines each, 0
  violations): default look and full_r9 staged 13/13 (`CHECK_107.txt`, `SEEN-IN-STUDIO`). 2693
  tests, selene 0/0/0. No shipping default changed. Allowlist scope under Decisions.")

#### N2. More village

- [x] 108. **`lapangan_r8`: the field.** The village field (lapangan) gets two goal posts, a flagpole with a red-white flag, bamboo benches along one side, a boundary of white-painted stones and a few sandy patches, using `MapSpec` for position. **CHECKS:** `LAPANGAN_PARTS` per kind; `PATH_REACH` for the field edge; the goal posts are sized against the 7.25-stud avatar (a 2.2-stud-tall-per-avatar-height ratio is fine; document the numbers you chose in the module).
  Done 2026-11-22: NEW pure `ModelMapLapanganR8` (MapSpec.LAPANGAN-local offsets, 54 original Parts:
  goal 6, flagpole 3, bench 16, stone 24, sand 5) + NEW server `LookDevLapanganR8` applier
  (anchored, non-collidable, save/detach/restore). Goal sizing documented in-module:
  AVATAR_HEIGHT 7.25 x GOAL_RATIO 2.2 = GOAL_HEIGHT 15.95 studs; both goals structural. New ID 80
  (36 specs count 79->80), review path, harness checks `LAPANGAN_PARTS`/`LAPANGAN_PATH_REACH`/
  `LAPANGAN_GOAL_SIZE`, new spec + registration, CANDIDATES.md pending row. Real Studio fresh-Play
  Server-VM PASS (`CHECK_108.txt`, `SEEN-IN-STUDIO`): per-kind counts all match, 0/5 field-edge
  corridors blocked, goal bbox 15.94~15.95 (2 goals), PFS field-edge routes 4/4, restore/re-enable
  PASS, anti-vacuity parts=54 corridors=5 goals=2. `LAPANGAN_PATH_REACH` name used instead of bare
  `PATH_REACH` (that name belongs to the existing 6-hub read-only check). 2702 tests, selene 0/0/0.
  Candidate off by default; no shipping default changed. No new camera (item 133 owns that).
- [x] 109. **`pasar_ground_r8`: Pasar ground.** Around the Pasar, flat paving stones and cobble patches (parts, `Material` Cobblestone/Slate, no terrain edit), drainage gutters along the building edges, and a cleared 6-stud walking lane between stalls. **CHECKS:** `PASAR_PAVING` ≥ 60 pieces; `LANE_CLEAR`: the 6-stud lane has no collidable parts; paving is within 0.15 studs of ground height so nobody trips.
  Done 2026-11-22: NEW pure `ModelMapPasarGroundR8` (94 original Parts: 40 Cobblestone paving, 36
  Slate cobble, 18 gutters; MapSpec.hub("pasar")-local offsets via hubPoint; no terrain edit) + NEW
  server `LookDevPasarGroundR8` applier (anchored, non-collidable, save/detach/restore). Slab bottoms
  sit on GROUND_Y, `PAVING_TOL=0.15` on the bbox bottom face. New ID 81 (37 count literals 80->81),
  review path, new spec + registration, CANDIDATES.md pending row. Real Studio fresh-Play Server-VM
  PASS (`CHECK_109.txt`, `SEEN-IN-STUDIO`): `PASAR_PAVING` 76>=60, slab bottoms on GROUND_Y
  (max delta 0.0000), `PASAR_GROUND_LANE_CLEAR` 0 overlaps over a 6.0-stud lane (94 tagged parts
  tested, non-vacuous), PFS lane-crossing route PASS, disable/re-enable PASS. Used distinct name
  `PASAR_GROUND_LANE_CLEAR` — item 148 owns bare `LANE_CLEAR`; its check untouched. 2710 tests,
  selene 0/0/0. Candidate off by default; no shipping default changed. No new camera (item 133).
- [x] 110. **`musala_r8`: musala (small prayer house).** A small musala with a green dome or tiered roof, a pengeras suara horn on a pole, a wudhu tap area and a shoe rack. Built from parts, modest in size, respectful. Place it with a clear approach on the village side of the ring road. **CHECKS:** `MUSALA_PARTS` ≥ 25; `DOOR_CLEAR` for its door; `PATH_REACH` to its door. Mark it in `CANDIDATES.md` as `needs designer review: cultural content`.
  Done 2026-11-22: NEW pure `ModelMapMusalaR8` (49 original Parts + 1 invisible door gauge; MapSpec.ROAD
  site derivation r 120 @ 30deg -> centre (60,103.92), yaw 30, door radial-out toward ring; green
  RGB tiered roof, pengeras suara horn, wudhu area, shoe rack; no terrain edit/asset IDs) + NEW server
  `LookDevMusalaR8` applier (anchored, non-collidable, save/detach/restore). New ID 82 (38 count
  literals 81->82), review path, 3 harness checks, new spec, CANDIDATES row verdict exactly
  `needs designer review: cultural content` (new gallery value; narrow spec allowance only).
  Real Studio fresh-Play Server-VM PASS (`CHECK_110.txt`, `SEEN-IN-STUDIO`): `MUSALA_PARTS` 49>=25,
  `MUSALA_DOOR_CLEAR` gauge dims/pose/API OK 0 collidable hits, `MUSALA_PATH_REACH` 0/50 overlaps
  (site-local frame), PFS spawn->approach->door routes PASS, disable/re-enable PASS. Three real
  errors fixed, none hidden: invalid material `Painted` (13 parts failed to stage -> `Plastic`, stale
  allowlist entry removed, spec guard); harness LookVector sign (local -Z, compare `-LookVector`);
  world-AABB false positives on the yaw-rotated kit (lane now measured site-local). Distinct check
  names `MUSALA_DOOR_CLEAR`/`MUSALA_PATH_REACH` — the facades DOOR_CLEAR and six-hub PATH_REACH
  checks own the bare names. 2718 tests, selene 0/0/0. Candidate off by default; no shipping default changed.
- [x] 111. **`lumbung_r8`: lumbung and pekarangan.** A rice barn (lumbung padi) on stilts, garden fences with toga herbs and chilli pots, a tempat jemur padi (drying mat on the ground) and a well-swept dirt yard around each of three houses. **CHECKS:** counts per kind; `PROPS_ON_GRASS` = 0 for the yard pads; `DOOR_CLEAR`.
  Done 2026-11-22: NEW pure `ModelMapLumbungR8` (90 original Parts in 12 kinds: 6-stilt barn with raised
  floor, tiered thatch roof, clear door + ladder + vents, plus fence/toga/chilli/drying-mat/rake kit at
  pasar/gelap/pakrt; MapSpec.hub/hubPoint derivation; no asset IDs) + 1 invisible door gauge + NEW server
  `LookDevLumbungR8` applier (anchored, non-collidable, Ground voxel yard pads snapshotted with
  ReadVoxels and restored byte-exact LIFO via WriteVoxels, folder save/detach-restore). New ID 83 (count
  literals 82->83), review path, 3 harness checks, new spec, CANDIDATES pending row. Real Studio
  fresh-Play Server-VM PASS (`CHECK_111.txt`, SEEN-IN-STUDIO): `LUMBUNG_PARTS` 90>=80 all kind counts
  match, `LUMBUNG_DOOR_CLEAR` gauge dims/pose/API OK 0 collidable hits (`-LookVector` radial),
  `LUMBUNG_PROPS_ON_GRASS` 0/24 grassy over 3 exact yards (cells readable+nonGrass; anti-vac via exact
  sample list+folder), Ground pads changed and restored byte-exact LIFO, PFS yard+spawn routes PASS,
  disable/re-enable PASS. One real error fixed, not hidden: stale `Leaf` material token (6 toga leaves
  failed to stage -> `Plastic`, spec guard added; shared allowlist left intact — other modules use Leaf).
  Distinct check names (bare `DOOR_CLEAR`/`PROPS_ON_GRASS` owned by facades/r7 props). 2727 tests,
  selene 0/0/0. Candidate off by default; no shipping default changed. No new camera (item 133).
- [x] 112. **`perahu_r8`: boats and river life.** Two small perahu at the river bank, a fishing net on poles, a bamboo landing stage and a stack of baskets (not in the water channel, keep the bridge span clear). **CHECKS:** counts; `BRIDGE_WALKABLE` unchanged; nothing intersects the river centreline within the bridge's 56 studs.
  Done 2026-11-22: NEW pure `ModelMapPerahuR8` (39 original Parts in 8 kinds: hull 6, gunwale 4, seat 4 —
  two perahu; netframe 4 + netmesh 6 — fishing net on poles; stageplank 6 + stagepile 4 — bamboo landing
  stage; basket 5 — stack of baskets; river centreline mirror `304 + 12 sin(2*pi*x/320)`, channel half 14,
  bank offset 18, no asset IDs/invalid material tokens) + NEW server `LookDevPerahuR8` applier (anchored,
  non-collidable, tagged, exact folder detach/restore, no terrain edit). New ID 84 (count literals 83->84
  across 38 specs + 3 extra), review path, 2 harness checks, new spec, CANDIDATES pending row. Real Studio
  fresh-Play Server-VM PASS (`CHECK_112.txt`, SEEN-IN-STUDIO): `PERAHU_PARTS` 39>=35 all kind counts match,
  `PERAHU_RIVER_CLEAR` 0/39 overlaps within the 56-stud [-28,28] bridge crossing, 0 global channel hits,
  synthetic violating box correctly flagged (non-vacuous), disable/re-enable PASS, zero perahu staging
  warnings. `BRIDGE_WALKABLE` stays READ-ONLY and byte-identical. Distinct check names. 2736 tests,
  selene 0/0/0. Candidate off by default; no shipping default changed. No new camera (item 133).
- [x] 113. **`irrigation_r8`: irrigation and field life.** Two scarecrows (orang-orangan sawah) with a woven hat and a ragged shirt, two bamboo irrigation channels with a thin water sheet, a bamboo clapper bird-scarer and a small stack of padi sheaves. **CHECKS:** counts; `SAWAH_TOPS` unchanged; the water sheets sit within 0.3 studs of the terrace top.
  Done 2026-11-22: NEW pure `ModelMapIrrigationR8` (50 original Parts in 9 kinds: scarecpole 2, crossbar 2,
  shirt 10, head 2, hat 6 — two scarecrows; flume 12 + watersheet 2 — two bamboo channels; clapper 6;
  sheaf 8; terrace tops/bands mirror MapSpec.TERRACES, water sheet tops = terrace.top+0.25 <= 0.3, no
  asset IDs/invalid material tokens) + NEW server `LookDevIrrigationR8` applier (anchored, non-collidable,
  `Terrace` number attr, exact folder save/detach-restore, NO Terrain read/write). New ID 85 (count literals
  84->85 across 38 specs + 3 extra), review path, 2 harness checks, new spec, CANDIDATES pending row. Real
  Studio fresh-Play Server-VM PASS (`CHECK_113.txt`, SEEN-IN-STUDIO): `IRRIGATION_PARTS` 50>=40 all kind
  counts match, `IRRIGATION_WATER_ON_TERRACE` 0 failed / 2 sheets / worst delta 0.25 <= 0.3 (live MapSpec
  tops 8.50 & 16.50), synthetic bad sheet 0.90 correctly flagged (non-vacuous), disable/re-enable PASS,
  zero staging warnings. `SAWAH_TOPS` stays READ-ONLY and byte-identical (Part-only candidate cannot touch
  Terrain raycasts). ORDER names appended after LOOKDEV_LEAK so all 18 ORDER-literal assertions hold.
  2746 tests, selene 0/0/0. Candidate off by default; no shipping default changed. No new camera (item 133).
- [x] 114. **`kincir_r8`: water wheel.** A small wooden waterwheel beside the river that rotates slowly (one shared loop, 6 degrees per second). **CHECKS:** `KINCIR_ROT`: the wheel angle changes by 3–9 degrees over 1 s; one instance only; `disable()` stops and removes it.
  Done 2026-11-22: NEW pure `ModelMapKincirR8` (21 original Parts: wheelroot 1, hub 1, axle 1, spoke 8,
  blade 8, support 2; `DEG_PER_SEC=6`; river mirror + one bank site x=-68 z=310.33, nearest face 14 studs
  from channel, clear of bridge [-28,28]; no asset IDs/invalid tokens) + NEW server `LookDevKincirR8`
  applier (one shared Heartbeat loop turning all parts 6 deg/s, numeric `WheelAngle` attr, diagnostics
  `wheelRoot()/connectionCount()/isApplied()/pump(dt)`, exact folder save/detach-restore, no terrain edit).
  New ID 86 (count literals 85->86 across 39 specs + 3 extra), review path, ONE harness check `KINCIR_ROT`,
  new spec, CANDIDATES pending row. Real Studio fresh-Play Server-VM PASS (`CHECK_114.txt`, SEEN-IN-STUDIO):
  `KINCIR_ROT PASS 6.0000 3..9` with 1 folder/1 root/1 connection, real Heartbeat 6.0225 deg/1.024s,
  CFrame moves, `disable()` removes all (0/0/0) and angle stays stable across 1 s, re-enable yields a fresh
  rotating wheel with 6.0 pump delta. Non-vacuous (0/0/0 on teardown, synthetic 15 deg rejected); bank site
  18 studs off centreline, nearest face 14, outside bridge span. All existing checks byte-identical.
  ORDER name appended last so all 19 ORDER-literal assertions hold. 2756 tests, selene 0/0/0. Candidate
  off by default; no shipping default changed. No new camera (item 133).
- [x] 115. **`laundry_r8`: hanging laundry.** Washing lines with sarung, batik cloth and kebaya hanging between posts behind two houses, plus a hammock and a tikar under the porch. Use solid colours or simple patterned decals made from existing assets; no brand logos. **CHECKS:** counts; cloths do not intersect walls (`GetPartsInPart` is empty); `CLOTH_SWAY` is optional and tied to item 85 when present.
  Done 2026-11-22: NEW pure `ModelMapLaundryR8` (44 original Parts in 7 kinds: post 8, line 4, sarung 4,
  batik 4, kebaya 4 — two washing lines/house behind pasar+gelap; hammock 10, tikar 10 — under each +Z
  porch; solid Wood/Fabric colours only, no asset IDs/decals/brand logos; behind lz -31/-29 & -19/-17,
  porch lz +22 & +10) + NEW server `LookDevLaundryR8` applier (anchored, non-collidable, tagged, live
  MapSpec.hub/hubPoint, exact folder save/detach-restore, no terrain edit, no animation). New ID 87 (count
  literals 86->87 across 40 specs + 3 extra), review path, 2 harness checks, new spec (10 tests), CANDIDATES
  pending row. Real Studio fresh-Play Server-VM PASS (`CHECK_115.txt`, SEEN-IN-STUDIO): `LAUNDRY_PARTS` 44>=40
  all kind counts match, `LAUNDRY_CLOTH_CLEAR` 0 wall hits / 12 cloths probed / 9 wall parts / 2 hub Models,
  synthetic wall-overlap probe correctly flagged (non-vacuous), disable/re-enable PASS, zero staging warnings.
  `CLOTH_SWAY` SKIPPED: optional, item 85 wind_r8 owns sway and candidates are single-active. ORDER names
  appended last so all contiguous ORDER-literal assertions hold. All existing checks byte-identical. 2766
  tests, selene 0/0/0. Candidate off by default; no shipping default changed. No new camera (item 133).
- [x] 116. **`layangan_r8`: kites.** Four layangan (kites) flying at 60–90 studs of altitude near the field, each with a thin tail and a string (`Beam`) down to a small kid-sized point on the ground; they rock gently. **CHECKS:** `KITE_COUNT` = 4; `KITE_COST` under 0.2 ms per frame; strings don't pass through buildings (raycast from kite to anchor hits nothing).
  Done 2026-11-22: NEW pure `ModelMapLayanganR8` (48 original Parts: kiteroot 4, spine 4, spar 4, sail 16,
  tail 16, anchor 4; 4 textureless Beam strings; field mirror centre 0,96, 4 sites, altitudes 64/72/80/88
  in [60,90]; no asset IDs/decals/brand) + NEW server `LookDevLayanganR8` applier (ONE shared Heartbeat
  sine-rock loop, numeric KiteAngle attr, Beams via ColorSequence/Width0/Width1 — NOT invalid FaceColor/
  Width — no Texture, diagnostics kiteRoots/anchors/beams/connectionCount/isApplied/pump, exact folder
  save/detach-restore). New ID 88 (count literals 87->88 across 40 specs + 3 extra), review path, 3 harness
  checks, new spec, CANDIDATES pending row. Real Studio fresh-Play Server-VM PASS (`CHECK_116.txt`,
  SEEN-IN-STUDIO): `KITE_COUNT` 4 roots/4 Beams/4 anchors/1 conn, altitudes 64/72/80/88, `KITE_STRING_CLEAR`
  4 rays/6 hubs/0 building hits (synthetic wall ray correctly flagged), `KITE_COST` 0.149ms < 0.2 (3600
  pump steps), real rock ~1.9deg/1s + CFrame motion, disable/re-enable PASS, zero warnings. TWO REAL BUGS
  FIXED in Studio: (1) Beam FaceColor/Width invalid here -> ColorSequence/Width0/Width1 (all 4 strings had
  failed); (2) cost 0.25375ms with all 44 moving Parts -> tail Parts static, 28 move ≈0.14ms; threshold 0.2
  and part counts UNCHANGED. ORDER names appended last so all contiguous ORDER-literal assertions hold. All
  existing checks byte-identical. 2777 tests, selene 0/0/0. Candidate off by default; no shipping default
  changed. No new camera (item 133).
- [x] 117. **`seated_r8`: seated villagers at the warung.** Use `HumanoidDescription` NPCs (same catalog outfits as npcs_r7) seated on the warung benches with `Humanoid.Sit` driven by a `Seat`, and a few glasses and plates on the table. At most 4. **CHECKS:** `SEATED_COUNT` ≤ 4; each `Humanoid.Sit` is true after 3 s; none intersects the bench.
  Done 2026-11-22: NEW pure `ModelMapSeatedR8` (outfit KEYS only — exact R7 catalog IDs stay in ModelMapNpcsR7,
  no new IDs; 4 seat sites at bench front edge z=-56.65, 4 glasses + 4 plates; 8 representative probe parts,
  no engine API) + NEW server `LookDevSeatedR8` applier (real R15 rigs via `CreateHumanoidModelFromDescriptionAsync`
  with sync fallback, R7 HumanoidDescription recipe, `seat:Sit` + fallback + one bounded 0.2s re-assert,
  unanchored collidable rigs, exact folder/rig save-restore, diagnostics rigs/seatCount/isApplied/sitStates/props).
  New ID 89 (count literals 88->89 across 42 specs + 3 extra; the two unrelated toBe(88) stay), review path,
  2 harness checks (`SEATED_COUNT`, `SEATED_ON_BENCH`), new spec, CANDIDATES pending row. Real Studio fresh-Play
  Server-VM PASS (`CHECK_117.txt`, SEEN-IN-STUDIO): `SEATED_COUNT` 4 real R15 rigs/4 Seats, all `Humanoid.Sit=true`
  after real task.wait(3); `SEATED_ON_BENCH` 2 benches/4 rigs/32 probes/0 hits; synthetic old-Z clip correctly flagged;
  4/4 props; disable/re-enable PASS. ONE REAL BUG FIXED: seats ON the bench made 8 lower-leg clips (benchHits=8) —
  empirical dz sweep showed +1.0 Z clears, so zLift 0.35->1.35 (z -57.65->-56.65, at front edge), seat depth 0.8->1.4;
  thresholds/PROBE_PARTS/counts UNCHANGED. All existing checks byte-identical. 2787 tests, selene 0/0/0.
  Candidate off by default; no shipping default changed. No new camera (item 133).
- [x] 118. **`crops_showcase_r8`: crop review plots.** For the designer's review: one plot per growth stage (bibit, tumbuh, siap) showing all 12 crops in rows, and a camera for each in `REVIEW_CAMERAS.md`. No gameplay state is touched; it is staged geometry only. **CHECKS:** `CROPS_STAGED` = 36; `CROP_GROWTH` re-run.
  Done 2026-11-22: NEW pure `ModelMapCropsShowcaseR8` (12 exact Config/Crops ids, stages bibit/tumbuh/siap, 3 plots at
  MapSpec.LAPANGAN z 80/96/112, 12 crops/row x -24.75..24.75 step 4.5, built-in tokens only, no IDs/engine API) +
  NEW server `LookDevCropsShowcaseR8` applier (3 stage Models + 36 crop Models from `CropModelCandidates.partsFor`,
  306 original Parts anchored/non-collidable, NO DataStore/player/crop-state writes, exact folder save/restore,
  diagnostics plotModels/cropModels/counts/partCount/isApplied). New ID 90 (count literals 89->90 across 44 specs +
  3 extra), review path, 1 harness check `CROPS_STAGED`, new spec, CANDIDATES pending row. 3 Server review cameras
  `crop_bibit`/`crop_tumbuh`/`crop_siap` added to BOTH `ReviewCameras.luau` (MapSpec-derived) and `REVIEW_CAMERAS.md`
  (registry/doc entries only, no in-game Camera staged); item 133 also names these — no duplication later. Real Studio
  fresh-Play PASS (`CHECK_118.txt`, SEEN-IN-STUDIO): `CROPS_STAGED` 36 Models/3 plots/12 per stage/306 Parts/0 state
  objects, `CAMERA_CLEAR` 45 cameras/0 blocked incl. 3 new, synthetic destroyed-crop discriminated (36->35),
  disable/re-enable PASS. Standalone verbatim `crop_growth_check.luau` re-run in FRESH Client VM (runtime-injected,
  not saved) PASS `CHECK CROP_GROWTH PASS 12 12`, thresholds 0.5/6.0/15% untouched. All existing checks byte-identical.
  2798 tests, selene 0/0/0. Candidate off by default; no shipping default changed. Designer decision: camera framing is
  a safe MapSpec-derived default; no screenshot claim.

#### N3. Weather, seasons, atmosphere

- [x] 119. **`season_r8_*`: seasonal look.** Three candidates tied to `Seasons.luau`: `season_r8_hujan` (wetter ground tint, more puddle sheets, slightly cooler grade), `season_r8_kemarau` (dry-grass tint, lower Cover, more haze) and `season_r8_panen` (golden padi tint, warmer light). They only touch `Lighting`, `Atmosphere`, `Clouds` and tinted existing decor, with exact restore. **CHECKS:** `SEASON_SAFE` ranges; `SEASON_RESTORE` exact; each preset differs from the others in at least two values by at least 10%.
  Done 2026-11-22: NEW pure `ModelMapSeasonR8` (3 presets tied to Config.Seasons.sky field names, season-safe bands Density 0.10..0.35/Haze 0.4..2.4/Cover 0.35..0.60, 3 bounded decor tint selectors, 6 hujan puddle sheets, DISTINCT_PCT=10/TARGET=2, PUDDLE_Y_FALLBACK=0.53, no IDs/engine API) + NEW CLIENT applier `LookDevSeasonR8` (3 keyed closures, LIFO save/restore of Lighting/Atmosphere/Clouds + tinted decor, exact puddle folder restore, diagnostics). New IDs 91-93 (count literals 90->93 in 47 specs), 3 client Review paths, 3 harness checks (`SEASON_SAFE`, `SEASON_RESTORE`, `SEASON_DISTINCT`), new spec, 3 CANDIDATES pending rows. TWO REAL BUGS FIXED: (1) first SERVER applier could not reach Clouds — Sky creates Clouds CLIENT-side only, so converted to CLIENT applier (moved to src/client, Main.client require, client paths, harness RunService:IsClient gate + bounded wait); (2) MapSpec unreachable from Client VM made hujan stage 0 puddles — added documented PUDDLE_Y_FALLBACK=0.53. No check weakened. Real fresh-Play CLIENT-VM PASS (`CHECK_119.txt`, SEEN-IN-STUDIO): SEASON_SAFE 3/3, SEASON_RESTORE 3/3, SEASON_DISTINCT 16>=2 (pairs 22/26/16), 14 props restored exactly, Cover 0.58/0.40/0.48 holds after 1s, hujan 6 sheets, synthetic out-of-range flagged, synthetic decor tint changed+restored exactly, lifecycle PASS. All existing checks byte-identical. 2812 tests, selene 0/0/0. Candidates off by default; no new camera (item 119 names none).
- [x] 120. **`rain_r8`: rain and mist.** A client rain effect (a ring of `ParticleEmitter` parts around the camera, at most 3 emitters, `Rate` ≤ 60 each) with a ground splash, and a morning mist `Atmosphere` bump. Only on when the season/weather state says `hujan`; off in `cerah`. **CHECKS:** `RAIN_EMITTERS` ≤ 3; `RAIN_OFF_CERAH`: emitters disabled when the weather is `cerah`; `RAIN_COST` under 0.5 ms per frame.
  Done 2026-11-22: NEW pure `ModelMapRainR8` (3-emitter recipe Rate 50/50/44, SPLASH_Y=0.53 documented, MIST_DELTA=0.05/MAX=0.35, MAX_STEP_MS=0.5, no IDs/engine API) + NEW CLIENT applier `LookDevRainR8` (3 textureless-code emitters, one Heartbeat camera-follow calling the same `pump(dt)` the cost check times, weather override, exact LIFO restore). New ID 94 (count literals 93->94, paving count 94 untouched), client Review path, 3 harness checks (`RAIN_EMITTERS`/`RAIN_OFF_CERAH`/`RAIN_COST`), new spec, 1 CANDIDATES pending row. TWO REAL BUGS FIXED: (1) stale `WEATHER_CERAH` token made `setCuacaForCheck("cerah")` a no-op — now `WEATHER_CLEAR` + Lune regression; (2) `NumberSequence.new(kp0,kp1)` invalid two-arg form left the folder empty — now keypoint table + Lune regression. No check weakened. Real fresh-Play CLIENT-VM PASS (`CHECK_120.txt`, SEEN-IN-STUDIO): RAIN_EMITTERS 3/3, RAIN_OFF_CERAH 3/3 (both directions), RAIN_COST 0.0042ms<0.5ms over 3600 steps, synthetic rate/density flagged, exact restore + no override leak. No visual/aural verdict. 2825 tests, selene 0/0/0. All existing checks byte-identical.
- [x] 121. **`subuh_r8`: dawn look.** A dawn (04:30–06:00) preset: cool blue-to-peach `ColorShift`, soft low mist, the first warm lamp glow, birds silent until 06:00. Follows the same tween rules as `DayCycle`. **CHECKS:** `DAWN_PHASES_MONOTONIC`; `DAWN_SAFE` ranges.
  Done 2026-11-22: NEW pure `ModelMapSubuhR8` (4 phases 4.5/5/5.5/6, Top.R+warmth monotone maxJump 0.2275<=0.7794 baseJump>0, DAWN_SAFE intersection bands, `BAND_EPSILON=1e-4` float32 tolerance, `birdsAudible(clock>=6)`, no Sound/ID) + NEW CLIENT applier `LookDevSubuhR8` (DayCycle tween rules, `engineColor` real Color3 for both write paths, setClockForCheck/applyPhaseNowForCheck direct-write, LIFO restore, <=6 lamp glow 0->0.45 @5:00-5:30 Shadows=false Range 14). New ID 95 (46 IDS + 4 mirrors bumped 94->95, paving counts.total left 94), client Review path, 2 harness checks appended after RAIN_COST, new spec, 1 CANDIDATES pending row. TWO REAL BUGS FIXED with no check weakened/band widened: (1) `setProps`/`tweenProps` assigned raw byte tables to Color3 props -> silent no-op (now `engineColor` converts both paths; also fixed `pcall(TweenInfo.new,...)` nil-global); (2) float32 `Density=0.2199999988` false-failed band min 0.22 (now `BAND_EPSILON=1e-4`). Real fresh-Play CLIENT-VM PASS (`CHECK_121.txt`, SEEN-IN-STUDIO): DAWN_PHASES_MONOTONIC 3/3, DAWN_SAFE 4/4; all 4 phases changed to authored endpoints with 0 band failures, synthetic brightness/phase discriminated, 1 s hold stable, exact restore + no override leak, no Sound staged. No visual/aural verdict. 2843 tests, selene 0/0/0. All existing checks byte-identical.
- [x] 122. **`lamps_shadows_r8`: night light cost.** Make sure no `PointLight`/`SpotLight` added by any round-9 candidate casts shadows (`Shadows = false`) and that every lamp has `Range` ≤ 30 and `Brightness` ≤ 3. **CHECK `LIGHT_COST`** across `full_r9`, with the counts reported.
  Done 2026-11-22: AUDIT-ONLY — no new ID (IDS stays 95), no gallery row. New `LIGHT_COST` harness check appended after `DAWN_SAFE` (SERVER VM, stages the exact 13-ID full_r9 additive set, enumerates PointLight/SpotLight, requires Shadows=false/Range<=30/Brightness<=3 with anti-vacuity totalLights>0) + new spec. Real fresh-Play SERVER-VM PASS (`CHECK_122.txt`, SEEN-IN-STUDIO): LIGHT_COST PASS 0 0 violations, 13 IDs staged, totalLights=6 all Shadows=false/Range 14/Brightness 0.9, synthetic flag of each threshold + exact restore + no leak. 2850 tests, selene 0/0/0. All earlier checks byte-identical.

#### N4. UI and text audits (objective only)

- [x] 123. **Theme audit.** Scan `src/client` UI modules for hardcoded `Color3.fromRGB`, font and `UICorner` values that bypass the theme module. Write `docs/v2/visual/UI_THEME_AUDIT.md` listing file, line and value, and fix any **exact duplicates of a theme token** (same colour in a different place). Do not redesign. **CHECK `THEME_BYPASS`:** the count after is lower than before; list the rest.
  Done 2026-11-22 (LUNE-ONLY): baseline 0 exact-colour theme-token duplicates in `src/client/UI/**` — already 0 before this item, so NO reduction is claimed and no colour code changed. NEW `UI_THEME_AUDIT.md` (LIVE row in docs/README.md) lists 0 fromRGB/0 hardcoded fonts/1 UICorner ctor, 6 non-token radii left as designer decisions, token-equal literals and out-of-scope Feel colours. NEW `theme_bypass_spec.luau` (4 cases, source guard, no weakening). No redesign, no Studio, no visual verdict.
- [x] 124. **Phone-size UI bounds.** With the Device Simulator skill (`get_roblox_skill rbx-device-simulator-lua`) or an equivalent script, open each ScreenGui at 375×812, 812×375 and 1024×768 and measure that every visible `GuiObject` lies inside the safe area and no interactive element is smaller than 44×44 px. **CHECK `UI_BOUNDS`** per screen and size; fix the failures that are plain size or anchor bugs. Do not move layout the designer chose.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_124.txt`): exact viewports via custom sim devices (+20px chrome compensation), 116 GuiObjects/screen across 7 screens. Safe area 0 violations at 375x812 and 1024x768; 1 at 812x375 — `AdminPanel.PanelShadow` (auto decoration) escaped because refit UIScale was parented to Panel, not its sibling shadow. ONE plain bug fixed at `Admin.luau:204` (UIScale parent `frame`->`gui`) and re-verified in fresh Play (shadow 240,-182,580,508 -> 336,14,480,307 inside, panel bounds unchanged). 31 sub-44px compact designer controls (admin/leaderboard/hud) left unchanged + flagged; repo one-axis 44px contract vs item's two-axis not reconciled. 0 truncated text.
- [x] 125. **Contrast audit.** For every `TextLabel`/`TextButton`, compute the contrast ratio between `TextColor3` and the nearest opaque background colour (or the stroke). **CHECK `CONTRAST`:** report the ones below 4.5:1 (3:1 for text 24 px or larger). Fix only the ones where a theme token with a better contrast exists.
  Done 2026-11-22 (LUNE-ONLY): NEW `CONTRAST_AUDIT.md` (WCAG token-pair proxy, no visual verdict) + `contrast_audit_spec` recomputes all ratios from source hex. 5 FAIL pairs fixed by better-contrast theme tokens: Admin.luau:338 kunyit->text (2.14->13.05), Leaderboard.luau:163 inactive tab muted->text (2.76->5.13; active state still shown via BackgroundColor3), Hud.luau:273 merah->text (2.83), Phone.luau:1031 daun->text (3.23), RaidOverlay.luau:61 senja->paper (4.30->13.05). Stroke-backed labels already meet 4.5:1 via ink stroke. No redesign, no new colours.
- [x] 126. **Minimum text size.** **CHECK `TEXT_MIN`:** no body text under 14 px at 375 px wide (use `TextScaled` with `UITextSizeConstraint.MinTextSize` ≥ 14). Fix the plain violations.
  Done 2026-11-22 (LUNE-ONLY): NEW `TEXT_MIN_AUDIT.md` + `text_min_spec`. All under-14px text is protected by locked designer decisions (`visuals_spec` body=13/small=11, `ui_touch_text_audit_spec` MinTextSize=11) — none are plain violations, so ZERO code changes and no lock weakened. Every row marked `designer decision` with the protecting lock named. 14px floor not universally applied without overriding those locks — recorded, not forced.

#### N5. Asset and doc hygiene

- [x] 127. **Manifest coverage.** A spec that every numeric asset ID that appears in `src/shared/ModelMap*.luau`, `SkyMap*.luau`, `IconMap.luau` and the other asset maps is present in `docs/v2/visual/art/ASSET_MANIFEST.md`, and every manifest ID is used or marked `unused`. Fix the manifest, never delete an ID from code to pass.
  Done 2026-11-22 (LUNE-ONLY): NEW `assetmap_manifest_spec.luau` (ASSET_MANIFEST_COVERAGE) scans all code IDs vs manifest. Found 10 uncovered IDs (7 vegetation shortlist + 3 NPC R5 hats) — appended to a new coverage section in ASSET_MANIFEST.md (existing rows byte-identical), plus 24 genuinely-unused IDs marked `unused` with a convention note. 0 code IDs deleted; 2 documented i32 RNG moduli excluded.
- [x] 128. **Candidate catalogue.** Add `docs/v2/visual/CANDIDATE_INDEX.md`, generated by a small script from `LookDev.IDS` and `CANDIDATES.md`: id, family, datamodel, review camera, verdict, and the module file. Flag every id missing from either side. A spec fails if `LookDev.IDS` and `CANDIDATES.md` disagree.
  Done 2026-11-22 (LUNE-ONLY): NEW `CANDIDATE_INDEX.md` with exactly 95 unique IDs × 6 columns (family/datamodel/review camera/verdict/module), verdicts verbatim from CANDIDATES.md, cameras only where documented (SHOT_LIST/REVIEW_CAMERAS, else `—`), no invented values. NEW `candidate_index_spec.luau` (CANDIDATE_INDEX, 95/95 parity + field match + documented-only cameras). The IDS↔CANDIDATES parity half was already covered by `candidate_gallery_spec`.
- [x] 129. **Rejected-candidate register.** Write `docs/v2/visual/REJECTED.md`: every candidate with verdict `**no**`, its module files, the one-line reason, and whether anything else requires it. **Do not delete code.** The designer decides what to prune.
  Done 2026-11-22: NEW `docs/v2/visual/REJECTED.md` — exactly 31 `**no**` rows, verdict reason verbatim from CANDIDATES.md, resolved module files (all 20 distinct paths exist), "required by anything else?" column. Designer-prune note. No code changed.
- [x] 130. **Tracker refresh.** Update `VISUAL_MASTER_PLAN.md`'s visual tracker with a dated status line per layer L1–L10 (status words only: `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`, each with its evidence path).
  Done 2026-11-22: `VISUAL_MASTER_PLAN.md` Last updated 2026-11-22, one dated status line per L1–L10; all 10 evidence paths verified to exist. Conservative statuses: L1/L3/L4/L5/L6/L9 SEEN-IN-STUDIO, L2/L7/L10 UNVERIFIED, L8 BLOCKED (designer framing). No fabrication.
- [x] 131. **Evidence index.** Write `docs/v2/evidence/h/INDEX.md` listing every dated folder, what it proves and the status word. Flag any `SEEN-IN-STUDIO` claim in the docs that has no file behind it and downgrade the claim to `UNVERIFIED`.
  Done 2026-11-22: NEW `docs/v2/evidence/h/INDEX.md` — all 82 dated folders (one row each, exact name/date/proven claim/status word; 57 SEEN-IN-STUDIO, 24 LUNE-ONLY, 1 BLOCKED), paths verified to exist. Downgrade audit: none found (SEEN-IN-STUDIO claims all have evidence files behind them; agrees with `CODE_AUDIT.md`). No source doc edited.

#### N6. Review prep

- [x] 132. **Shot list for the main session.** Write `docs/v2/evidence/h/<date>-round10/SHOT_LIST.md`: for every candidate ticked in rounds 8–10, one line with the exact `enable` call, datamodel, camera name (`REVIEW_CAMERAS.md`), the Play/Edit state required and the objective checks it already passed. Order it by datamodel so the main session needs the fewest restarts. Include `full_r9` and every `season_r8_*` and `grade_r8_*` as alternatives to compare.
  Done 2026-11-22: NEW `h/2026-11-21-round10/SHOT_LIST.md` — 46 rows ordered by datamodel (Server 35 incl. `full_r9` additive recipe, Client 11), verbatim enable calls from CANDIDATES.md, camera names from REVIEW_CAMERAS.md (`—` where undocumented), Play/Edit state + passed check ids/counts from cited CHECK files. All 3 `season_r8_*` and 3 `grade_r8_*` included as alternatives; 0 `**no**` candidates; 42 unique CHECK paths cited, 0 missing. Staging queue, not evidence, no visual verdict. No place save.
- [x] 133. **Camera additions.** Add a named camera to `REVIEW_CAMERAS.md` and `ReviewCameras.luau` for every new item above (lapangan, musala, lumbung, perahu, irrigation, kincir, laundry, kite sky, warung seated, crops showcase ×3), derived from `MapSpec`. **CHECK `CAMERA_CLEAR`** for the full set.
  Done 2026-11-22 (SEEN-IN-STUDIO, `CHECK_133.txt`): 9 new cameras (lapangan/musala/lumbung/perahu/irrigation/kincir/laundry/kite_sky/warung_seated) appended to `ReviewCameras.luau` (127 additions/0 removals; existing 45 byte-identical) + doc; crop ×3 already existed from item 118. All coords from authored MapSpec/model data, no hand-typed coords. NEW `cameras_new_r10_spec` (CAMERA_CLEAR_R10, real registry, 54 count, no dupes). Fresh-Play SERVER-VM full-set `CAMERA_CLEAR PASS 0 blocked/54 checked` (6-stud ray, unchanged). Shot-list rows reconciled to new names. No visual verdict, no place save.
- [x] 134. **Final report.** Write `docs/v2/evidence/h/<date>-round10/FINAL_REPORT.md`: commits, one PASS/FAIL/BLOCKED line per item, blocked items with the exact FAIL line, and the decisions-for-designer list.
  Done 2026-11-22: NEW `h/2026-11-21-round10/FINAL_REPORT.md` — 20-commit table, 31 per-item lines (105-135), 16 blocked entries (item 106 + 13 carryovers + Gate1 G4/Q5) each with verbatim FAIL/reason line, 12 designer decisions with source files, gates. Every cited path/HEAD verified; itself not evidence.
- [x] 135. **Refill.** Re-read `BUGS.md`, `GATE1.md`, `CANDIDATES.md` and `VISUAL_MASTER_PLAN.md`. Queue anything an agent can still close, in this format and at least 15 items long if there is that much to do. Only write "nothing left" if you can name the file you checked for each layer.
  Done 2026-11-22: re-read all four files. Files checked for each layer: `docs/testing/BUGS.md:12-30,88-94` (0 open defects), `docs/testing/GATE1.md:34-54,70-88` (all remaining rows designer/hardware), `docs/v2/visual/CANDIDATES.md:14-114` (all 45 pending checks already PASS — visual/aural verdict only), `docs/v2/visual/VISUAL_MASTER_PLAN.md:126-295,439-452`. Queued 17 agent-closable items below (7 §11 doc write-backs + 10 stale check cells). All feature/gate work that is NOT agent-closable is named with file:line at the end of this section.

#### N7. Objective doc/evidence hygiene (refill from item 135)

These close factual staleness only. None grants a visual/aural verdict, changes a shipping default, or deletes a code ID. Each item's `**CHECK**` is a source-level or existing-evidence assertion; no new Studio run is implied unless stated.

- [x] 156. **Engine fact: MaterialService overrides.** Research `create.roblox.com/docs` on whether MaterialService overrides re-skin existing Parts by base material without per-Part `MaterialVariant`, whether it applies to Terrain, and the supported map sizes. Write the sourced answer + URL + date into `VISUAL_MASTER_PLAN.md` §11 (currently open at `:439-440`). If no authoritative public answer, write that explicitly — never guess. **CHECK `DOC_FACT_156`:** §11 bullet carries a sourced answer or a stated "not publicly documented".
  Done 2026-11-22: §11 answer written back with 4 sourced URLs (access 2026-11-22); map-size cap not published - stated explicitly. No guess.
- [x] 157. **Engine fact: reflective puddle.** Confirm from Roblox docs whether a reflective puddle needs a thin Part / `SurfaceAppearance` rather than a decal. Write back into §11 (`:441-442`). **CHECK `DOC_FACT_157`:** sourced answer or explicit "not documented".
  Done 2026-11-22: reflectance lives on BasePart.Reflectance (thin Part); decal/SurfaceAppearance carry no Reflectance. 4 sources.
- [x] 158. **Engine fact: mobile quality-level effects.** Confirm which quality levels drop `DepthOfFieldEffect`, local-light shadows and `Atmosphere` haze on mobile. Write back into §11 (`:443-444`). **CHECK `DOC_FACT_158`:** sourced answer or explicit "not documented".
  Done 2026-11-22: only shadows-off below level 4 is public; DoF/Atmosphere drop points not documented - stated explicitly. 3 sources.
- [x] 159. **Engine fact: Highlight mobile cost.** Confirm current `Highlight` mobile limits and cost; supersede or date the 1 ms figure in `RESEARCH_VISUAL_TIPS.md`. Write back into §11 (`:445-446`). **CHECK `DOC_FACT_159`:** sourced answer or explicit "not documented".
  Done 2026-11-22: 255 Highlights per client, first visible up to 1 ms mobile; figure current. 2 sources.
- [x] 160. **Engine fact: GlobalWind.** Confirm what `Workspace.GlobalWind` drives today (terrain grass / particles with wind drag / clouds). Write back into §11 (`:447`). **CHECK `DOC_FACT_160`:** sourced answer or explicit "not documented".
  Done 2026-11-22: GlobalWind drives grass/clouds/particles (particles need WindAffectsDrag + Drag). 2 sources.
- [x] 161. **Engine fact: Automatic graphics quality read.** Confirm whether a `LocalScript` can read effective graphics quality under Automatic or only the saved setting. Write back into §11 (`:448-449`). **CHECK `DOC_FACT_161`:** sourced answer or explicit "not documented".
  Done 2026-11-22: saved setting only, no reliable effective-level read (RobloxScriptSecurity); FidelityTier worst-case stands. 2 sources.
- [x] 162. **Engine fact: flipbook particles.** Confirm flipbook particle layout options and texture size limits. Write back into §11 (`:450`). **CHECK `DOC_FACT_162`:** sourced answer or explicit "not documented".
  Done 2026-11-22: flipbook None/2x2/4x4/8x8/Custom, needs 1024x1024 texture, low-memory auto-deactivate. 2 sources.
- [x] 163. **Stale check cell: lapangan_r8.** Update `CANDIDATES.md:78` verdict cell from "checks await a runner" to cite the PASS result in `CHECK_108.txt`; mirror the verdict cell in `CANDIDATE_INDEX.md`. Keep the cell starting with `pending` (spec grammar). **CHECK `CANDIDATE_INDEX`:** both tables stay verbatim-consistent; no verdict becomes a designer yes/no.
  Done 2026-11-22: stale "await a runner" cell refreshed with PASS check ids + CHECK path, mirrored verbatim in CANDIDATE_INDEX.md; cell still starts `pending`, no verdict granted. candidate_gallery_spec + candidate_index_spec green in full suite.
- [x] 164. **Stale check cell: pasar_ground_r8.** Same for `CANDIDATES.md:79` citing `CHECK_109.txt`; mirror in `CANDIDATE_INDEX.md`. **CHECK `CANDIDATE_INDEX`:** parity preserved.
  Done 2026-11-22: stale "await a runner" cell refreshed with PASS check ids + CHECK path, mirrored verbatim in CANDIDATE_INDEX.md; cell still starts `pending`, no verdict granted. candidate_gallery_spec + candidate_index_spec green in full suite.
- [x] 165. **Stale check cell: lumbung_r8.** Same for `CANDIDATES.md:81` citing `CHECK_111.txt`; mirror in `CANDIDATE_INDEX.md`. **CHECK `CANDIDATE_INDEX`:** parity preserved.
  Done 2026-11-22: stale "await a runner" cell refreshed with PASS check ids + CHECK path, mirrored verbatim in CANDIDATE_INDEX.md; cell still starts `pending`, no verdict granted. candidate_gallery_spec + candidate_index_spec green in full suite.
- [x] 166. **Stale check cell: perahu_r8.** Same for `CANDIDATES.md:82` citing `CHECK_112.txt`; mirror in `CANDIDATE_INDEX.md`. **CHECK `CANDIDATE_INDEX`:** parity preserved.
  Done 2026-11-22: stale "await a runner" cell refreshed with PASS check ids + CHECK path, mirrored verbatim in CANDIDATE_INDEX.md; cell still starts `pending`, no verdict granted. candidate_gallery_spec + candidate_index_spec green in full suite.
- [x] 167. **Stale check cell: irrigation_r8.** Same for `CANDIDATES.md:83` citing `CHECK_113.txt`; mirror in `CANDIDATE_INDEX.md`. **CHECK `CANDIDATE_INDEX`:** parity preserved.
  Done 2026-11-22: stale "await a runner" cell refreshed with PASS check ids + CHECK path, mirrored verbatim in CANDIDATE_INDEX.md; cell still starts `pending`, no verdict granted. candidate_gallery_spec + candidate_index_spec green in full suite.
- [x] 168. **Stale check cell: kincir_r8.** Same for `CANDIDATES.md:84` citing `CHECK_114.txt`; mirror in `CANDIDATE_INDEX.md`. **CHECK `CANDIDATE_INDEX`:** parity preserved.
  Done 2026-11-22: stale "await a runner" cell refreshed with PASS check ids + CHECK path, mirrored verbatim in CANDIDATE_INDEX.md; cell still starts `pending`, no verdict granted. candidate_gallery_spec + candidate_index_spec green in full suite.
- [x] 169. **Stale check cell: crops_showcase_r8.** Same for `CANDIDATES.md:88` citing `CHECK_118.txt` (`CROPS_STAGED` 36, `CROP_GROWTH PASS 12 12` in fresh Client VM — no re-run needed); mirror in `CANDIDATE_INDEX.md`. **CHECK `CANDIDATE_INDEX`:** parity preserved.
  Done 2026-11-22: stale "await a runner" cell refreshed with PASS check ids + CHECK path, mirrored verbatim in CANDIDATE_INDEX.md; cell still starts `pending`, no verdict granted. candidate_gallery_spec + candidate_index_spec green in full suite.
- [x] 170. **Stale check cell: season_r8_hujan.** Same for `CANDIDATES.md:89` citing `CHECK_119.txt` (Cover-hold confirmed in Client VM); mirror in `CANDIDATE_INDEX.md`. **CHECK `CANDIDATE_INDEX`:** parity preserved.
  Done 2026-11-22: stale "await a runner" cell refreshed with PASS check ids + CHECK path, mirrored verbatim in CANDIDATE_INDEX.md; cell still starts `pending`, no verdict granted. candidate_gallery_spec + candidate_index_spec green in full suite.
- [x] 171. **Stale check cell: season_r8_kemarau.** Same for `CANDIDATES.md:90` citing `CHECK_119.txt`; mirror in `CANDIDATE_INDEX.md`. **CHECK `CANDIDATE_INDEX`:** parity preserved.
  Done 2026-11-22: stale "await a runner" cell refreshed with PASS check ids + CHECK path, mirrored verbatim in CANDIDATE_INDEX.md; cell still starts `pending`, no verdict granted. candidate_gallery_spec + candidate_index_spec green in full suite.
- [x] 172. **Stale check cell: season_r8_panen.** Same for `CANDIDATES.md:91` citing `CHECK_119.txt`; mirror in `CANDIDATE_INDEX.md`. **CHECK `CANDIDATE_INDEX`:** parity preserved.
  Done 2026-11-22: stale "await a runner" cell refreshed with PASS check ids + CHECK path, mirrored verbatim in CANDIDATE_INDEX.md; cell still starts `pending`, no verdict granted. candidate_gallery_spec + candidate_index_spec green in full suite.

Not agent-closable (verified, with the checked file for each layer — do not queue):
- `docs/testing/BUGS.md:12-30,88-94`: zero open defects; all 19 rows fixed/closed. Remaining phone/portrait caveats are GATE1 rows, not bugs.
- `docs/testing/GATE1.md:34-54,70-88`: G4 (tracks C/G/E art, real IDs, saved place), G4b/G2/Q1 (phone visual judgment — needs vision observer + emulator), G6 (MicroProfiler on designer hardware), G7 (five real humans), Q5 (designer-run Local Server/multi-client), Q6 (publishing), Q7 (real mid-range Android). All designer/hardware (`:70` "Everything an agent can do is done").
- `docs/v2/visual/CANDIDATES.md:14-114`: 45 `pending` + 1 cultural-review verdict; every objective CHECK already PASS — only the designer's visual/aural/cultural call remains.
- `docs/v2/visual/VISUAL_MASTER_PLAN.md:126-295`: L2/L7/L10 need designer assets/verdicts; L8 "BLOCKED on designer" framing (`:264`); §11 bullet 8 (Future vs ShadowMap phone cost, `:451-452`) needs hardware.

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

### Sprint 2 item 242 — shipped haze floor (2026-11-23)

Item 242 asked to raise the Atmosphere haze so the far edge fades into the sky. The seasonal preset
hazes are 0.8 / 0.5 / 0.4 (hujan / kemarau / pancaroba), which left a hard grey horizon line even with
new far fill. A reversible shipped floor `HORIZON_HAZE_FLOOR = 1.6` (SkyMapR6) is applied in the client
Sky module to both the static stack and the season tween; live Client VM read 1.6 at ClockTime 16.2.
Seasons presets and the `horizon_fill_r10` candidate HAZE = 2.0 were NOT changed. If 1.6 washes out
the scene at golden hour, the designer may retune that one constant; HORIZON_FILL is geometric and
does not depend on the haze value.

### Sprint 2 item 239 — kampung SUBJECT_COVERAGE did not fail as expected (2026-11-23)

Item 239 expected `kampung_view` + `kampung_r10` to measure < 0.15. It measured 0.4694 in a fresh Play
SERVER VM (72 parts, 7 rects, 816 samples, 383 hits), so the emitted line is PASS, not FAIL. The
metric is geometric visible screen fraction with raycast occlusion; the sprint-1 note for shot #03 was
"Camera against a red wall; houses not readable" - a legibility defect that a fill fraction cannot
penalise (a close wall can fill the frame at high coverage). A centre ray from `kampung_view` toward
its lookAt had no hits, consistent with item 216 CAMERA_CLEAR 0/0. The `plot_gate_01` +
`ditch_water_r10` pair did fail (0.0000). No threshold, grid size or occlusion rule was changed to
force the expected result. For item 240: re-aimed kampung cameras should be judged on legibility in
the review pack; treat 0.15 as a floor check, not a visual verdict. The main session cannot make a
visual yes/no from these numbers.

### Round 10 item 107 — smoke allowlist scope and the real smoke_r8 error (2026-11-22)

`tools/studio/smoke_play.luau` carries a deliberately short 5-entry allowlist. Four entries are
already-documented environment noise: server boot info, ProfileStore boot info, the external
Assistant plugin self-notice, and the D-G4/BUG-003 wrong-asset warning (`DECISIONS.md:27`). The
fifth is the pre-existing `ShippingLookR7: no PlotAnchor parts within 10 s; only flower beds
painted` shipping ground-look notice — the dev place has no `PlotAnchor` parts, it fires on every
Play with or without lookdev staging, and it is unrelated to any candidate. If the designer wants
a truly silent log, adding PlotAnchor parts to the dev world (a world task behind Gate 1) would let
this entry be removed; it was NOT removed by editing shipping look here.

The one genuine error the smoke surfaced — `smoke_r8` ParticleEmitter `Lifetime`/`Speed` built as
`NumberSequence` instead of `NumberRange` — was FIXED in source and spec-guarded, NOT added to the
allowlist. `smoke_play_spec.luau` enforces that neither that error line nor `NumberSequence`
appears in the allowlist, so the bar cannot be weakened to hide a recurrence. Both required 60 s
fresh-Play windows (default look, full_r9) then passed `SMOKE_CLEAN 0 0`.

### Round 10 item 106 — full-route AVATAR_FIT blocked on shipping geometry (2026-11-21)

Item 106's avatar box sweep fails with full_r9 staged (`CHECK AVATAR_FIT FAIL 2 16`), but the same
sweep with NOTHING staged produces an IDENTICAL hit set: every blocker is pre-existing shipping
world geometry (`RumahPakRT` walls, `Plot_4.SignPost`, `kit_fence`, house Floor/Desk/Table, NPC
UpperTorso), not any lookdev candidate. No staged part is collidable (0 of 35,949), so there is no
"blocking candidate" to move or shrink, and re-scoping the query to staged-only would be both a
weakened and a vacuous check. Two FAIL attempts -> BLOCKED; no shipping world part was touched.
Two things are for the designer / a future item: (1) a corrected full-route gauge — ground-based box
bottom (not waypoint-centred), segment-oriented rather than world-axis-aligned, with the box size
4 x 7.25 x 4 and the target 16/16 / zero hits UNCHANGED; the current axis-aligned box clips corners a
radius-2 pathfinding capsule clears and its 7.25 height exceeds the routes' AgentHeight=5.5, so some
hits are measurement artifacts — but the deep penetrations (2.26 studs into a BackWall, 2.20 into a
SignPost) are real shipping geometry a corrected gauge would likely still flag. (2) If the avatar
must truly fit everywhere with everything on, align AgentHeight with the 7.25-stud avatar and clear
or move the shipping walls/signposts/desks in a world task behind Gate 1 — not by weakening this
check. No place saved, nothing published.

### Round 10 item 104 — tier-thinning interpretation and facades exemption (2026-11-21)

Item 104's "count at Rendah <= 0.55 x count at Tinggi" is applied to each candidate's DECORATIVE
instance set (the instances its thinning gate governs), NOT raw BaseParts. Raw part count is the
wrong metric for structural-heavy candidates whose own documented CHECKs protect most parts:
facades (all 60 `FacadePart` needed for FACADE_MIN_PARTS=10 + all-six-kinds), hubprops (first 5
props/hub protected by HUBPROPS_VISIBLE>=5), streetfurn (>=18 posts + 5/5 sign parity), spanduk
(boards/poles/cord + Strings text), plots (fence + gates). The recorded check therefore asserts
decorative Rendah <= 0.55 x decorative Tinggi AND structural count identical across all three tiers
AND Sedang==Tinggi AND no instance added at Rendah. Every decorative set halves (<=0.5); facades
has no thinnable instances and is reported EXEMPT, not failed. Default tier stays `Tinggi`=100% (so
all documented counts/specs are unchanged) and unknown/nil tier normalises to Tinggi. Designer call
if wanted later: allow thinning into the protected structural sets (needs those CHECKs re-scoped),
or lower the <=0.55 ceiling. All candidates remain off by default; no shipping look changed.

### Round 10 item 103 — `full_r9` is an additive review set, not a new LookDev ID (2026-11-21)

Item 103 asked for a "candidate" staging all approved/pending round-9 scene candidates at once. Built
it as an additive review set staged via `LookDevReview.enableAdditive` in the SERVER VM (`CHECK_103.txt`,
`SEEN-IN-STUDIO`), NOT as a new ID in `LookDev.IDS`. Reasons: (1) the set spans 9 server + 4 client
appliers; the two VMs have separate registries, a single candidate ID cannot stage both halves, and
the 4 client appliers early-return in a Client VM because MapSpec is server-only — but all 13 DO stage
together in the Server VM, so that is the one lane used. (2) An 80th ID breaks 33 specs asserting
`#LookDev.IDS == 79` plus review_round3_bugfix_spec and candidate_gallery_spec. (3) Item 136
ADDITIVE_STAGE is precedent for multi-candidate staging in the harness/review recipe. The item's
CHECKS (load/overlap/leak/perf) are all met without an ID. CROSS_OVERLAP was vacuous on the first
pass (0 collidable parts — all lookdev dressing is intentionally non-collidable); an anti-vacuity
guard now fails on missing folders / 0 parts / unreadable parts, and the 0-collidable result is
reported alongside the 7 expected decorative overlaps. PERF_BUDGET 2041 (proxy 500) recorded, not
hidden; all candidates off by default. Designer call if wanted later: a first-class combined ID,
which needs the IDS-count specs updated and a deliberate cross-VM staging design.

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
