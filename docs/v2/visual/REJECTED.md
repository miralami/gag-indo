# Rejected candidate register

Designer decides what to prune; this register is informational only. Verdict source: CANDIDATES.md (do not edit).

Count: **31** candidates with verdict `**no**` in the CANDIDATES.md main table. Nothing here is deleted or changed.

"Required by anything else?" means: another candidate or shipping feature that references the id, its applier module, or its shared data module beyond the universal `LookDevReview.paths` / `Main.client|server` boot require. `no` = none found. Module files are resolved from `src/shared/LookDevReview.luau` (`datamodel` + `path`) against the `src/{client,server}/` roots. All 20 distinct module files below exist.

| ID | Module file(s) | Verdict — one-line reason (verbatim from CANDIDATES.md) | Required by anything else? |
|---|---|---|---|
| `textures` | `src/client/World/LookDevTextures.luau` | **no** — use downloaded CC0 PBR textures as MaterialVariants (D18) | no |
| `npcs` | `src/client/World/LookDevNpcs.luau` | **no** — real 3D models via the D15 ladder | no |
| `crops` | `src/client/World/LookDevCrops.luau` | **no** — real 3D models via the D15 ladder | `crops_showcase_r8` (pending) requires `src/shared/CropModelCandidates.luau` |
| `hubprops` | `src/client/World/LookDevHubProps.luau` | **no** — keep the idea, rebuild mostly as 3D models, case by case | no |
| `corner` | `src/client/World/LookDevCorner.luau` | **no** — off the map with no terrain and flat primitives; rebuild inside the real village instead — 2026-11-20 | no (`textures_r3` only optionally picks up its staged folder; `ModelMapBuildingsR4.derivedFrom` is metadata) |
| `buildings_r3` | `src/server/World/LookDevModelsR3.luau` | **no** — smaller than the player, untextured grey; real textured models via the D15 ladder — 2026-11-20 | no |
| `vegetation_r3` | `src/server/World/LookDevModelsR3.luau` | **no** — tiny, mostly grey; real textured models via the D15 ladder — 2026-11-20 | no |
| `props_r3` | `src/server/World/LookDevModelsR3.luau` | **no** — grey fragments that don't read; real textured models via the D15 ladder — 2026-11-20 | no |
| `npcs_r3` | `src/server/World/LookDevModelsR3.luau` | **no** — grey blocks, CC0 rigs lie flat; real rigged textured models — 2026-11-20 | no |
| `textures_r4` | `src/client/World/LookDevTexturesR4.luau` | **no** — still wrong after the fix: red-desert ground and straw grass; rethink the terrain approach (round 6) — 2026-11-20 | no (`src/shared/TextureMapR4.luau` is read by `TerrainMapR6`, whose only consumers are the two rejected `terrain_r6_*` ids) |
| `sky_r4_a` | `src/client/World/LookDevSkyR4.luau` | **no** — redo: clear direction is right but it doesn't read as an Indonesian sky; find Indonesian sky references (round 5) — 2026-11-20 | `sky_r5` (yes, tune) reuses `src/shared/SkyMapR4.luau` |
| `sky_r4_b` | `src/client/World/LookDevSkyR4.luau` | **no** — redo: keep only as a mild-cloud reference; not too cloudy (round 5) — 2026-11-20 | `sky_r5` (yes, tune) reuses `src/shared/SkyMapR4.luau` |
| `sky_r4_c` | `src/client/World/LookDevSkyR4.luau` | **no** — too overcast for the default; overcast belongs to rain/season events later — 2026-11-20 | `sky_r5` (yes, tune) reuses `src/shared/SkyMapR4.luau` |
| `npcs_r4` | `src/server/World/LookDevModelsNpcsR4.luau` | **no** — not solid; use solid Roblox R15 characters instead — 2026-11-20 | no |
| `spawn_ground_r5` | `src/server/World/LookDevSpawnGroundR5.luau` | **no** — fix: the back road is still asphalt and tall grass covers the flower beds (round 6) — 2026-11-20 | no |
| `sky_r6_a` | `src/client/World/LookDevSkyR6.luau` | **no** — designer picked sky_r6_e — 2026-11-20 | `sky_r6_e` (chosen) shares this applier module |
| `sky_r6_b` | `src/client/World/LookDevSkyR6.luau` | **no** — designer picked sky_r6_e — 2026-11-20 | `sky_r6_e` (chosen) shares this applier module |
| `sky_r6_c` | `src/client/World/LookDevSkyR6.luau` | **no** — designer picked sky_r6_e — 2026-11-20 | `sky_r6_e` (chosen) shares this applier module |
| `sky_r6_d` | `src/client/World/LookDevSkyR6.luau` | **no** — designer picked sky_r6_e — 2026-11-20 | `sky_r6_e` (chosen) shares this applier module |
| `sky_r6_f` | `src/client/World/LookDevSkyR6.luau` | **no** — designer picked sky_r6_e — 2026-11-20 | `sky_r6_e` (chosen) shares this applier module |
| `terrain_r6_a` | `src/client/World/LookDevTerrainR6.luau` | **no** — also turns the wooden building walls almost black — 2026-11-20 | no |
| `terrain_r6_b` | `src/client/World/LookDevTerrainR6.luau` | **no** — also turns the wooden building walls almost black — 2026-11-20 | no |
| `vegetation_r6` | `src/server/World/LookDevModelsVegetationR6.luau` | **no** — still sparse; 5 IDs failed LoadAsset (not authorized); redo after the asset bake (item 58) — 2026-11-20 | `river_r8` (pending) and `pathedge_r8` (also rejected) require `src/shared/ModelMapVegetationR6.luau`; `hubveg_r8` / `blocks_r9` reach it via `ModelMapVegetationR7` |
| `props_r6` | `src/server/World/LookDevModelsPropsR6.luau` | **no** - staged inside the pine stand and buried in grass; only the jemuran is visible (item 57) - 2026-11-20 | no (`src/shared/ModelMapPropsR6.luau` is required only by the rejected `props_r7`) |
| `vegetation_r7` | `src/server/World/LookDevModelsVegetationR7.luau` | **no** - not graded visually; objective Studio checks only | `hubveg_r8` (yes, densify), `blocks_r9` (pending) and `src/shared/ReviewCameras.luau` require `src/shared/ModelMapVegetationR7.luau` |
| `props_r7` | `src/server/World/LookDevModelsPropsR7.luau` | **no** - not graded; objective Studio checks only | no |
| `sawah_r8` | `src/server/World/LookDevSawahR8.luau` | **no** — original rejected: tufts read as long green bars, no padi or gubuk visible; padi redo staged (item 140), await designer re-review — 2026-11-21 | `season_r8_hujan/kemarau/panen` (pending) tint its `PadiPart` staged parts (`src/shared/ModelMapSeasonR8.luau`) |
| `pathedge_r8` | `src/server/World/LookDevPathEdgeR8.luau` | **no** — original rejected: pieces sat in the middle of the road; edge redo staged (item 142, 626 pieces), checks pass but staged `PERF_BUDGET` 1146/500 is FLAGGED over the Sedang proxy, keep off by default; default look 334/500 — 2026-11-21 | `season_r8_hujan/kemarau/panen` (pending) tint its `LookDevPathEdgeR8` staged puddle/grass parts (`src/shared/ModelMapSeasonR8.luau`) |
| `water_r8_b` | `src/client/World/LookDevWaterR8.luau` | **no** — kept only as the rain-season reference — 2026-11-21 | `water_r8_a` (chosen, PROMOTED) shares this applier module |
| `water_r8_c` | `src/client/World/LookDevWaterR8.luau` | **no** — **rejected** — too much like a swimming pool | `water_r8_a` (chosen, PROMOTED) shares this applier module |
| `spawn_r5` | `src/server/World/LookDevSpawnDressingR5.luau` | **no** — the designer will compose spawn and sculpt the terrain elevation himself — 2026-11-20 | no |
