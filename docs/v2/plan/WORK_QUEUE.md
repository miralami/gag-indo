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
- [ ] 0a. **Q6 live capture for admins.** The Q6 run sheet makes the designer copy numbers by hand
  from the HUD, because `Persistence` only works in Studio. Add an admin-only (`Admins.isAdmin`)
  server command that also works in a published place and prints the same `Q6_BEFORE_JSON` and
  `Q6_RESULT_JSON` lines to the server console (F9). Rate-limit it, make it read-only, and give it
  a gate spec. Update `Q6_PUBLISHED_PLACE.md` §C to use it. This is test tooling, not a gameplay
  feature.

### A. Foundation (V0)
- [ ] 1. **Reference board (V0.3).** Put 15–20 images under `docs/v2/visual/art/reference/`, each
  with a source link and licence: Indonesian village at senja, sawah terraces, pasar, warung at
  night, rain on seng, rumah panggung, kelapa and pisang, bambu fences. The designer adds 3–5.
  Build `reference/README.md` as a grid with captions.
- [ ] 2. **Look-dev corner (V0.4).** A 60×60-stud corner with a warung, a road bend and a sawah
  edge, built in a separate Studio Folder toggled by `LookDev`. Apply V-D1 (remove the world
  outline here first) and V-D2 (golden hour). Save the camera positions for three review shots.
- [ ] 3. **Prop audit (V-D3).** List the ten low-poly props in a table with the verdict: keep +
  retexture, or replace. For each one to replace, name a candidate found with the asset ladder.

### B. Asset sourcing, ladder order
- [ ] 4. **Buildings:** rumah panggung, warung, pos polisi, rumah Pak RT, pasar stalls, gubuk
  sawah. Ladder per building; replace boxes behind `LookDev`.
- [ ] 5. **Vegetation (V-D4):** kelapa, pisang, bambu clumps, shrubs, padi at three stages, and a
  dense grass layer (Terrain decoration plus cards). Remove the pines within sight of the
  village.
- [ ] 6. **Props:** fences (bambu), lanterns (oil lamp, petromax), crates, karung, sepeda, gerobak,
  jemuran, signs, motor. Prefer set dressing that tells the story.
- [ ] 7. **Ground and surface textures (D18):** cobblestone and dirt paths, tanah sawah, pematang
  edges, river banks, bambu, genteng, seng, wood. Download CC0 PBR texture sets (ambientCG, Poly
  Haven) and turn them into MaterialVariants on Terrain and parts. Upload the maps through Open
  Cloud and record source and licence. The round-2 agent-drawn textures are rejected.
- [ ] 8. **NPCs and characters:** caricature NPC bodies and accessories (peci, caping, seragam
  polisi) from the ladder. Keep R15 compatibility.
- [ ] 9. **Animations (V-D6):** Creator Store walk/idle for NPCs; list the authored ones
  (cangkul, panen) under "Designer builds" or generate them with Studio MCP
  `generate_animation`.

- [ ] 9b. **Icons, improve (D18).** Keep the round-2 set as the base; redraw `tier_biasa` (it's an
  empty box) and `debt` (unclear). Polish the rest for more depth and readability at 48 px. Make
  it a new candidate revision with before/after contact sheets.

### C. Light and atmosphere (L1)
- [ ] 10. **Lighting and day cycle (V-D2, D19):** Future lighting, Atmosphere, warm
  ColorCorrection, Bloom kept low, SunRays. Build the eight phases in
  `docs/v2/visual/DAY_CYCLE.md` as a pure, Lune-tested phase table layered over the season and
  weather presets in `Sky.luau`, with golden hour at spawn. Follow the designer answers in
  DAY_CYCLE.md: 24-minute day and readable night. Add the time-of-day sound beds (ayam, bedug,
  kentongan, jangkrik, soft adzan) with a player setting to turn adzan on or off, muted during
  satire moments. Night needs lanterns that
  actually emit light. Check each FidelityTier at Rendah.
- [ ] 11. **Sky and fog:** a tropical skybox, a distant ridge silhouette, and haze depth.

### D. The frame (V1)
- [ ] 12. **Spawn view.** Combine A–C on the spawn view only. Save the camera position, then
  check the instance count and fps proxy against the budget. Leave the five screenshot tests to
  the review pass.
- [ ] 13. **Review pass handoff.** Write `docs/v2/visual/REVIEW_ROUND3.md` listing every
  candidate with its toggle and camera position, in the order to review. The designer, or a
  session that can see screenshots, fills in the verdicts.

### E. Moments (V2), after the frame is approved
- [ ] 14. **Harvest, reveal and sale VFX (M2–M4):** particles, a pop scale, a cash fly, a sound
  sync. Behind tiers.
- [ ] 15. **Raid moment (M5) lights and the police walk-in,** using the round-1 `police_walkin`
  candidate if it was approved.

### E2. Text
- [ ] 19. **Indonesian text review** (moved from round 2 item 24). Read every `id` string for
  natural, non-translated-sounding Indonesian, in the `humanizer-indonesia` style. Put the
  proposed edits in a table under "Decisions for designer" and don't change `Strings.luau`.

### F. Close
- [ ] 16. **Budget and soak** with all approved visuals on, at each tier.
- [ ] 17. **Regression replay**: G3 beat sheet, G5 timings and a full-session `output.log`.
- [ ] 18. **Refill** from `VISUAL_MASTER_PLAN.md` V1–V3, `CANDIDATES.md` and `BUGS.md`. Repeat
  until nothing is left.

## Designer builds

Models the ladder couldn't supply, each with a brief and a reference.

- (none yet)

## Decisions for designer

- (none yet)
