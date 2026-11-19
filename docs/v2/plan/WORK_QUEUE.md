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
- [ ] 2. **Look-dev corner (V0.4).** A 60×60-stud corner with a warung, a road bend and a sawah
  edge, built in a separate Studio Folder toggled by `LookDev`. Apply V-D1 (remove the world
  outline here first) and V-D2 (golden hour). Save the camera positions for three review shots.
- [x] 3. **Prop audit (V-D3).** List the ten low-poly props in a table with the verdict: keep +
  retexture, or replace. For each one to replace, name a candidate found with the asset ladder.
  Done 2026-11-20: `docs/v2/visual/art/PROP_AUDIT.md` lists all ten with current representation,
  `hubprops` LookDev coverage and a **replace** verdict each, plus a verified step-(1) ladder candidate
  (Poly Haven / explicit-CC0 Sketchfab) or a concrete step-(2)/(3) fallback where no free upgrade exists
  (`sumur`, `hut`). Licence caveats (`gerobak`, `motor` platform field, `wall` download size) flagged;
  no ID invented, no model ingested, no visual verdict claimed.

### B. Asset sourcing, ladder order
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

- [ ] 9b. **Icons, improve (D18).** Keep the round-2 set as the base; redraw `tier_biasa` (it's an
  empty box) and `debt` (unclear). Polish the rest for more depth and readability at 48 px. Make
  it a new candidate revision with before/after contact sheets.

### C. Light and atmosphere (L1)
- [x] 10a. **Day-cycle phase table (V-D2, D19), pure half.** Done 2026-11-20: `src/shared/World/DayCycle.luau`
  holds the eight `DAY_CYCLE.md` phases over a 24-minute day with golden-hour spawn, a readable night,
  gap/midnight blending and a Rendah light budget. `clockAt`/`segmentAt`/`presetFor`/`phaseInfo`/
  `isNight` layer a fresh grade over the season/weather preset without mutating it. 15-case
  `day_cycle_spec`; 2050 passing, LUNE-ONLY. `Strings.luau` gained the 8 phase labels and
  `setting_adzan`, but no sound/search code consumes them yet.
- [ ] 10b. **Day-cycle live wiring (V-D2, D19), remaining half.** Wire `presetFor` into
  `client/World/Sky.luau` (Future lighting, Atmosphere, warm ColorCorrection, Bloom kept low,
  SunRays) and the 20–40 s phase tweens; add the time-of-day sound beds (ayam, bedug, kentongan,
  jangkrik, soft adzan) with a player setting to turn adzan on or off, muted during satire moments.
  Night needs lanterns that actually emit light. Check each FidelityTier at Rendah in Studio; this
  half needs the vision observer / designer for any visual verdict.
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
- [x] 19. **Indonesian text review** (moved from round 2 item 24). Read every `id` string for
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
