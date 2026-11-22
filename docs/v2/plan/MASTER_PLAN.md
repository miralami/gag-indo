# Juragan Desa — Master Plan

> Written 2026-11-14. This is the single direction for every agent working on this repo.
> It supersedes `archive/HANDOFF_ROADMAP.md` and `archive/HANDOFF_ART_PASS.md` for ordering and priorities.
> `plan/PLAN.md` stays the feature reference, `visual/ART.md` the art bible, `TECH.md` the code conventions,
> `plan/DECISIONS.md` the designer's decisions. Where this file disagrees with them on *what comes
> first* or *what counts as done*, this file wins.

## Progress tracker — read first, update last

**Last updated:** 2026-11-23 - sprint 1 reviewed by the main session (provisional verdicts in `docs/v2/visual/PROVISIONAL_VERDICTS.md`, notes `h/2026-11-23-sprint1/MAIN_SESSION_NOTES.md`); sprints 2-4 queued (section S items 238-249 plus Q 208-215, 218-225), each ending in a STOP review pack. 2026-11-23 - SPRINT 1 S1-STOP COMPLETE: review pack written at `docs/v2/evidence/h/2026-11-23-sprint1/` — 12 Studio `screen_capture` JPGs in `shots/` (10 sprint candidates from their paired review cameras, plus `spawn` and `canonical_overview` baselines) captured in fresh Play at ClockTime 13 with SERVER-VM `LookDevReview.disableAll()` then `enableAdditive(id, game)` one candidate at a time; `REVIEW_SPRINT1.html` (base64 JPEG ≤1200 px, Indonesian captions + CHECK lines, Ya/Tidak/Tunda + comment per card, Salin hasil button); `SPRINT1_REPORT.md` (commits, PASS per item, decisions for designer). All 12 JPGs confirmed 1375x753 non-blank by technical QA; visual yes/no left to designer, `CANDIDATES.md` untouched. SPRINT 1 RUN STOPPED. Previous: 2026-11-23 - SPRINT 1 item 207 COMPLETE (SEEN-IN-STUDIO, `CHECK_207.txt`): `ditch_water_r10` OFF-by-default candidate; 10 plots x 2 rotated translucent Glass strips, teal {48,124,104} from ModelMapWaterR8.variants.a, plots_r8 default untouched; LookDev IDS[119]/descriptor/plan, LookDevReview path, Main require, CANDIDATES rows, 50-spec mirror 118->119. Real fresh-Play SERVER-VM PASS `DITCH_WATER 10/10`, `DITCH_COLOR 0/0`; both calibrated FAIL by injection. Suite 3018->3024, `selene src` 0/0/0. Next: S1-STOP. 2026-11-23 - SPRINT 1 item 206 COMPLETE (SEEN-IN-STUDIO, `CHECK_206.txt`): `crop_stages_r10` OFF-by-default candidate; 3 corrected stages (bibit 1.2/tumbuh 2.6/siap 4.2, hue distance ~0.206), 10 per-plot clusters / 60 Parts, default crops untouched; LookDev IDS[118]/descriptor/plan, LookDevReview path, Main require, CANDIDATES rows, 50-spec mirror 117->118. Fixed `CAMERA_SAMPLES 6/10` by staging one cluster per plot. Real fresh-Play SERVER-VM PASS `CROP_STAGE_HEIGHT 0/0`, `CROP_STAGE_COLOR 0/0`, `CAMERA_SAMPLES 10/10`; all three calibrated FAIL by injection. Suite 3012->3018, `selene src` 0/0/0. Next: item 207. 2026-11-23 - SPRINT 1 item 205 COMPLETE (SEEN-IN-STUDIO, `CHECK_205.txt`): `furrows_r10` OFF-by-default candidate; 10 plots x 5 alternating Ground-coloured strips at y=0.55 above soil, ditch and crops untouched; LookDev IDS[117]/descriptor/plan, LookDevReview path, Main require, CANDIDATES rows, 50-spec mirror 116->117. Fixed harness-only UDim2 `.Z` crash before PASS run. Real fresh-Play SERVER-VM PASS `FURROWS 5/4`, `FURROW_VISIBLE 10/10`, `CROP_PLACEMENT_UNCHANGED 0/0`; all three calibrated FAIL by injection. Suite 3006->3012, `selene src` 0/0/0. Next: item 206. 2026-11-23 - SPRINT 1 item 204 COMPLETE (SEEN-IN-STUDIO, `CHECK_204.txt`): `bamboo_bridge_r10` OFF-by-default additive overlay; 14 planks + 2 rails + 7 rope ties + 4 posts, river_r8 default untouched; LookDev IDS[116]/descriptor/plan, LookDevReview path, Main require, CANDIDATES rows, 50-spec mirror 115->116. Real fresh-Play SERVER-VM PASS `BRIDGE_WALKABLE 0/0`, `BRIDGE_MATERIAL 0/0`, `BRIDGE_RAILS 2/2`; all three calibrated FAIL by injection. Suite 3000->3006, `selene src` 0/0/0. Next: item 205. 2026-11-23 - SPRINT 1 item 203 COMPLETE (SEEN-IN-STUDIO, `CHECK_203.txt`): `signposts_r10` OFF-by-default candidate; 4 junction post+board groups, SurfaceGui TextLabel TextSize 18, 4 new Strings keys with id+en; LookDev IDS[115]/descriptor/plan, LookDevReview path, Main require, CANDIDATES rows, 50-spec mirror 114->115. Real fresh-Play SERVER-VM PASS `SIGNPOSTS 4/4`, `SIGN_TEXT_IN_STRINGS 4/4`, `SIGN_READABLE 4/4`; all three calibrated FAIL by injection. Suite 2990->3000, `selene src` 0/0/0. Next: item 204. 2026-11-23 - SPRINT 1 item 202 COMPLETE (SEEN-IN-STUDIO, `CHECK_202.txt`): `lamps_r10` OFF-by-default candidate; 12 ring-road lamps, one shadowless PointLight each (Range 16), night-only toggle; LookDev IDS[114]/descriptor/plan, LookDevReview path, Main require, CANDIDATES rows, 50-spec mirror 113->114. Real fresh-Play SERVER-VM PASS `LAMPS 12/12`, `LIGHT_COST 0/0`, `LAMP_NIGHT_ONLY 12/12` (12 on at 21, 0 at 13); all three calibrated FAIL by injection. Suite 2985->2990, `selene src` 0/0/0. Next: item 203. 2026-11-23 - SPRINT 1 item 201 COMPLETE (SEEN-IN-STUDIO, `CHECK_201.txt`): `road_fence_r10` OFF-by-default candidate; 6 bamboo stretches, gaps at junctions; LookDev IDS[113]/descriptor/plan, LookDevReview path, Main require, CANDIDATES rows, 50-spec mirror 112->113. Real fresh-Play SERVER-VM PASS `ROAD_FENCE 6/6`, `JUNCTION_GAPS 0/0`, `PATH_REACH 0/0`; all three calibrated FAIL by injection. Suite 2980->2985, `selene src` 0/0/0. Next: item 202. 2026-11-23 - SPRINT 1 item 200 COMPLETE (SEEN-IN-STUDIO, `CHECK_200.txt`): `kampung_r10` OFF-by-default candidate; 12 non-interactive houses in 3 clusters with yards; LookDev IDS[112]/descriptor/plan, LookDevReview path, Main require, CANDIDATES rows, 50-spec mirror 111->112. First Studio attempt FAILED `PLOT_CLEAR 1 0`; fixed in pure data (fence offset 4->2) and second fresh-Play PASSed all six checks; all six calibrated FAIL by injection. Suite 2974->2980, `selene src` 0/0/0. Next: item 201. 2026-11-23 - SPRINT 1 item 199 COMPLETE (SEEN-IN-STUDIO, `CHECK_199.txt`): `hill_dressing_r10` OFF-by-default candidate; 4 hills x (5 rocks + 13 palms) + terraces; LookDev IDS[111]/descriptor/plan, LookDevReview path, Main require, CANDIDATES rows, 50-spec mirror 110->111. Real fresh-Play SERVER-VM PASS `HILL_ROCKS 5/4`, `HILL_TREES 26/12`, `WALKABLE 0/0`; all three calibrated FAIL. Suite 2969->2974, `selene src` 0/0/0. Next: item 200. 2026-11-23 - SPRINT 1 item 198 COMPLETE (SEEN-IN-STUDIO, `CHECK_198.txt`): `mountains_r10` OFF-by-default candidate; pure data + server applier + 5-case spec + harness; LookDev IDS[110]/descriptor/plan, LookDevReview path, Main require, CANDIDATES rows, 50-spec mirror 109->110. Real fresh-Play SERVER-VM PASS `MOUNTAINS 6/3`, `MOUNTAIN_FAR 0/0`, `NO_COLLISION 0/0`, `PERF_BUDGET 361/500`; three checks calibrated FAIL with injected bad state. Suite 2964->2969, `selene src` 0/0/0. Next: item 199. 2026-11-23 - SPRINT 1 items 216 + 217 COMPLETE (SEEN-IN-STUDIO): item 216 adds 10 review cameras + doc rows for all 67 names, `CAMERA_CLEAR 0/67`, `DOCS_ONCE 0/0` (`CHECK_216.txt`), calibrated FAIL with an injected blocker, fixed `Game.plotCenter()` two-return bug; item 217 adds pure-data `VisualRiskAudit` + `ModelMapVisualFixtureBad` + `review_check_visual.luau`, shipped set PASS 0/0 on all three predicates with `AUDIT_PROBE 1/1`, deliberately-bad fixture trips all three (`CHECK_217.txt`). Suite 2955->2964, `selene src` 0/0/0, stylua clean. Next: item 198. 2026-11-23 - sprint 1 queued in WORK_QUEUE (items 216, 217, 198-207, then S1-STOP review pack; no refill). 2026-11-22 - section Q item 197 COMPLETE: `horizon_fill_r10` OFF-by-default candidate stages one anchored non-collidable 2048x1x2048 Part (HorizonSkirt, centred (0,-8,-128)) and matches it with Atmosphere Haze 2.0 / Color {214,226,220}. Pure `ModelMapHorizonFillR10` + server applier `LookDevHorizonFillR10` (save-once LIFO restore of Haze/Color, destroy only created instances) + 5-case spec + 3-check harness; LookDev IDS[109] / LookDevReview / Main wired; 108->109 spec mirror across 50 specs. Real fresh-Play SERVER-VM PASS `h/2026-11-22-round11/CHECK_197.txt` (SEEN-IN-STUDIO): HORIZON_FILL 15/15 (5 downward rays x 3 review cameras, before hits 0/15), PERF_BUDGET 338/500, HAZE_MATCH 1/1; all 3 FAIL-able by independent calibration; restore byte-exact. Engine cap: Part.Size clamps to 2048, so the original 3200 skirt failed 12/15; data corrected to a 2048 tile centred z=-128 with sample-inside self-check. Suite **2955**, `selene src` 0/0/0. No asset IDs, no terrain sculpt, no visual verdict; candidate OFF until 226. 2026-11-22 - section Q item 196 COMPLETE: `paths_curved_r10` OFF-by-default candidate paints a cosmetic curved Mud/Ground dirt band (8 studs core + 1.5 shoulder) along 10 serpentine plot-angle spokes (LCG(196), 8 ctrl points r110..148, wobble 8..11<=12) outside plots/gates/river. Pure `ModelMapPathsCurvedR10` + server voxel applier `LookDevPathsCurvedR10` (snapshot-first, occupancy/water preserved, byte-exact LIFO restore) + 5-case spec + 4-check harness; LookDev / LookDevReview / Main wired; 107->108 spec mirror across 50 specs. Real fresh-Play SERVER-VM PASS `h/2026-11-22-round11/CHECK_196.txt` (SEEN-IN-STUDIO): PATH_REACH 16/16 (item-105 method), PATH_CURVE 10/6 (6.0..11.7 studs), GATE_CLEAR 0/0, NO_CROSS 0/0; harness Z extended to 340 to sample the river. All 4 FAIL-able by independent calibration; restore byte-identical. Suite **2950**, `selene src` 0/0/0. Base roads untouched (collidability invariant), no asset IDs; candidate OFF until 226; no visual verdict. 2026-11-22 - team setup: `main` is now the working branch (track/c-world-look merged and retired); three-person team rules for agents in `AGENTS.md` "Team and authority", `CLAUDE.md` entry point, CODEOWNERS/PR template/CONTRIBUTING. Suite **2945**, `selene src` 0/0/0. 2026-11-22 - section Q item 195 COMPLETE: `ground_variation_r10` OFF-by-default candidate repaints terrain voxels in 4 tones (Grass/LeafyGrass/Ground/Mud, Mud 5.6%) in 36 noise-driven 20-60 stud blobs outside roads/plots, occupancy preserved, walkable slopes intact. Pure `ModelMapGroundVariationR10` + server voxel applier `LookDevGroundVariationR10` (snapshot-first, byte-exact LIFO restore) + 5-case spec + 3-check harness; LookDev / LookDevReview / Main wired; 106->107 spec mirror. Real fresh-Play SERVER-VM PASS `h/2026-11-22-round11/CHECK_195.txt` (SEEN-IN-STUDIO): GROUND_TONES 4/3, ROAD_UNTOUCHED 0/0, PLOT_UNTOUCHED 0/0; zone tests at 4-stud voxel centres; restore byte-identical. All three FAIL-able by calibration. Suite **2945**, `selene src` 0/0/0. No terrain sculpt/road/plot/sky/NPC change, no asset IDs; candidate OFF until 226; no visual verdict. 2026-11-22 - section Q item 194 COMPLETE: `meadow_r10` OFF-by-default candidate scatters 25 flower/tall-grass patches (10-20 items each) on the lawns between the Pasar ring and the plots, using the five baked real Creator Store models from item 193 (no ID invented). Pure `ModelMapMeadowR10` (radial plot-gate clearance + per-item zone resample, min item-to-plot 34.011 > 29.2) + server `LookDevMeadowR10` + 5-case spec + 3-check harness; LookDev / LookDevReview / Main wired. Real fresh-Play SERVER-VM PASS `h/2026-11-22-round11/CHECK_194.txt` (SEEN-IN-STUDIO): MEADOW_PATCHES 25/20, MEADOW_OFF_ROAD 0/0, MEADOW_VISIBLE 25/6 (1597 tagged parts). All three calibrated to FAIL independently (strip PatchIndex -> 19/20; pivot item onto crossroad -> OFF_ROAD 1/0; CanQuery=false -> VISIBLE 0/6) while the others stay PASS. Suite **2940**, `selene src` 0/0/0. No terrain/road/plot/sky/NPC change; candidate OFF until 226; no visual verdict. 2026-11-22 - section Q item 193 COMPLETE (source-only): five real free Creator Store flower/grass models baked scripts-stripped — 7974911801 Wildflower02, 13032768586 WildFlower04, 70509679878841 Daisy Flower, 128368650541272 TallGrass, 8715139325 Wild Grass. Real fresh-Play SERVER-VM PASS `h/2026-11-22-round11/CHECK_193.txt` (SEEN-IN-STUDIO): MEADOW_MODELS 5/3; calibrated (inject scripts into 3 folders -> FAIL 2/3, destroy -> PASS 5/3). IDs in ASSET_MANIFEST.md "Unused manifest IDs" with `unused` markers; items 194/195 wire them in. No applier/terrain change. Suite **2935**, `selene src` 0/0/0. 2026-11-22 - section Q item 192 COMPLETE: `river_r8` cube shrubs replaced with five real baked Creator Store models — 8466298000 Taro, 13261235137 Cattail/reed, 5661660655 fern, 9953859659 round shrub (scaled to ~2 studs), 5044238410 Lilypad; talas->taro, keladi->fern, alang-alang->reed, BankModelId published, shrub accent + 6 baked lily pads from pure Data.lilyPads. Real fresh-Play SERVER-VM PASS `h/2026-11-22-round11/CHECK_192.txt` (SEEN-IN-STUDIO): NO_CUBE_SHRUBS 0/0, BANK_PLANTS 60/60, BANK_MODELS 6/3, WATER_CLEAR 0/0, LILY_PADS 6/6. All five calibrated (strip BankModelId / strip LilyAssetId / pivot plant into channel / turn plant into Block / destroy half -> FAIL). Lily scale bug found and fixed live (0.3 -> 0.08 keeps 3.3-stud footprint). IDs in ASSET_MANIFEST.md section Q, candidate OFF until 226. Suite **2935**, `selene src` 0/0/0. 2026-11-22 - section Q item 191 COMPLETE: `sawah_r8` padi clumps rebuilt with the real baked Creator Store rice model 13286158859 "Meshes/rice2" (Polyslayer1, free, lone MeshPart 1.07 x 3.52 x 1.51), loaded via LookDevAssetLoader, scaled to 1.4 x 1.5 footprint / 1.7..2.3 height, deterministic yaw, terraces 3/4 use yellower GrowthStage=2. Real fresh-Play SERVER-VM PASS `h/2026-11-22-round11/CHECK_191.txt` (SEEN-IN-STUDIO): PADI_IS_MODEL 7056/1, PADI_STAGES 2/2, PADI_ROWS 294/10, BUND_SHAPE 0/0, SAWAH_GREEN 70/40, SAWAH_TOPS 0/0.5, PERF_BUDGET 338/500. All five decisive checks calibrated (strip PadiAssetId / force one GrowthStage / strip PadiRow / CanQuery=false / strip Bund -> FAIL). Manifest `unused` marker cleared, spec count 25->24. IDs in ASSET_MANIFEST.md section Q, candidate OFF until 226. Suite **2933**, `selene src` 0/0/0. 2026-11-22 - section Q items 190 (+177 superseded) COMPLETE: three real free Creator Store models baked scripts-stripped — 806579390 "Grass tuft" (a61766), 25454256 "Orange Flower" (tenchynox), 1769612183 "small stone" (MandarinBoy). `pathedge_r8` loads each via LookDevAssetLoader.get, scales component-wise to 1..2.5-stud height and <=2*PLANT_CLEAR footprint, parents real baked BaseParts under the tagged anchor; irregular 2..4-stud spacing, flower patch every 4th step, stone every 11th, exactly two flower colours. Real fresh-Play SERVER-VM PASS `h/2026-11-22-round11/CHECK_190.txt` (SEEN-IN-STUDIO): EDGE_HEIGHT 1.96/1, EDGE_VISIBLE 405/12, EDGE_OFF_ROAD 0/0, EDGE_VARIETY 3/3 (814 plants). All four calibrated (strip EdgeAssetId/CanQuery=false/PivotTo +6/destroy baked children -> FAIL; live CFrame+CFrame bug found and fixed). IDs in ASSET_MANIFEST.md section Q, candidate OFF until 226. Suite **2931**, `selene src` 0/0/0. 2026-11-22 - section Q items 189 (+176 superseded) COMPLETE: three real free Creator Store rock models 16098456067 (round), 5644862709 (flat), 53370997 (tall) baked scripts-stripped; `rocks_r9` clones them round-robin via LookDevAssetLoader, scales into each 0.8-2.5-stud footprint. Real fresh-Play SERVER-VM PASS `h/2026-11-22-round11/CHECK_189.txt` (SEEN-IN-STUDIO): ROCK_COUNT 101/40, ROCK_MODELS 3/3, ROCK_SIZE 1.90/1.2, ROCK_VISIBLE 20/8. All four calibrated (strip id/destroy 70/ScaleTo 4/CanQuery=false -> FAIL; pre-change Part rocks -> ROCK_MODELS FAIL 0). IDs in ASSET_MANIFEST.md section Q, candidate OFF until 226. Suite **2931**, `selene src` 0/0/0. 2026-11-22 - section Q items 188 (+175 superseded) COMPLETE: sourced free Creator Store fountain 93434732057582 "Fountain" (Sonisn1810), baked scripts-stripped, `plaza_r9` applier clones via LookDevAssetLoader and scales 17.35->16-stud basin at plaza centre. Real fresh-Play SERVER-VM PASS `h/2026-11-22-round11/CHECK_188.txt` (SEEN-IN-STUDIO): FOUNTAIN_IS_MODEL 1/1, FOUNTAIN_SIZE 16/18, FLAG_CLEAN 0/0, PLAZA_WALKABLE 0/0. All four calibrated (strip FountainAssetId/ScaleTo 1.3+0.45/cross flag/bench-in-lane -> FAIL; pre-change Part fountain -> FOUNTAIN_IS_MODEL FAIL 0). ID in ASSET_MANIFEST.md section Q, candidate OFF until 226. Suite **2930**, `selene src` 0/0/0. 2026-11-22 - section Q item 187 COMPLETE: sourced a real free Creator Store 3D padi model 13286158859 "Meshes/rice2" (Polyslayer1) over 11 search rounds, baked scripts-stripped into LookDevAssets, PADI_MODEL_BAKED PASS 1/1 (1 MeshPart, 0 scripts, 1.51 studs wide <=2) under `h/2026-11-22-round11/CHECK_187.txt` (SEEN-IN-STUDIO), scale-to-3 calibration FAIL. ID recorded in ASSET_MANIFEST.md section Q with `unused` marker pending item 191. 2026-11-22 - section Q item 186 COMPLETE: denser/shadier DEFAULT forest (designer-approved, not behind LookDev). `MIN_INSTANCES` 450, ANGLE_STEP 3->2 + 9 radii, 4 shade anchors/hub via pure-data `shadeAnchors(MapSpec.HUBS)`, Greybox `makeTree` shared by both loops with `ShadeTree=true`. Real fresh-Play SERVER-VM PASS `h/2026-11-22-round11/CHECK_186.txt` (SEEN-IN-STUDIO): TREE_COUNT 603/450, SHADE_TREES 4/3, NO_PINES 0, WALKABLE 0, PATH_REACH 0, PERF_BUDGET 339/500. All six calibrated (destroy trees/strip ShadeTree/pine rename/road+lane moves -> FAIL; pre-change baseline 272/0 FAIL). Suite **2930**, `selene src` 0/0/0. 2026-11-22 - section P items 228-237 COMPLETE (P-refill, all 10 OFF-by-default candidates, ids 96-105): NEW pure `ModelMapCanonicalR10` + single SERVER applier `LookDevCanonicalR10`, 10 galleries/index rows, count 95->105 across 49 specs + mirrors. Real fresh-Play SERVER-VM PASS for all 10 under `h/2026-11-22-round10/CHECK_228.txt`..`CHECK_237.txt` (SEEN-IN-STUDIO): balai BUDGET 335/500, canopy 6/6, shrubs 102/60, pasar roof RED 3/2 SLOPE 2/2, warung stalls 3 tables 2 LANE_CLEAR 0 (real stall-lane defect fixed), polisi BLUE 3/2 CAMERA_CLEAR 0, pakrt ROOF_COLOR 4/1 CAP_ON_RIDGE 0 (Color3-scale harness bug fixed + blackening calibration FAIL), gubuk TERRACE2 1/1 ON_GROUND 1.8e-07, mailbox 10/10 signs 10/10, palms 24/20 tall 24/20 (full-canopy harness fix + lowered-frond calibration FAIL). 3 harness bugs fixed, 1 real geometry defect fixed, no check weakened. Suite **2928**, `selene src` 0/0/0; WORK_QUEUE items ticked. 2026-11-22 - section P item 185 refill COMPLETE: added 10 canonical-gap items (228-237, all OFF candidates) from `CANONICAL_GAP.md` rows 10,3,4,17,19,20,22,9,13,26. 2026-11-22 - section P item 184 COMPLETE: `SHOT_LIST.md` re-review pack table added for items 173-182 (item 183 excluded, BLOCKED); doc-only. 2026-11-22 - section P items 180 and 182 COMPLETE with real Studio PASS (`CAMERA_CLEAR 0 0`/`TOWER_RAY 0 0`, `CHECK_180.txt`; `BLOCK_TREES 68 60`/`PERF_BUDGET 390 500`/`WALKABLE 0 0`/`GATE_CLEAR 0 0`, `CHECK_182.txt`); item 183 BLOCKED — needs a place edit by the main session: GiantyFrog (Model, 316 descendants) in Workspace after clean Play (`CHECK_183.txt`); suite 2914. 2026-11-22 - section P items 174-179 and 181 COMPLETE, all with real Play/Server-VM PASS evidence under `h/2026-11-22-round10/CHECK_174.txt,CHECK_175.txt,CHECK_176.txt,CHECK_177.txt,CHECK_178.txt,CHECK_179.txt,CHECK_181.txt`: 174 river Round Ball/Wedge bank plants (`NO_CUBE_SHRUBS 0 0`, `BANK_PLANTS 60 >=40`, `WATER_CLEAR 0 0`); 175 plaza two-tier 14-stud fountain + flat flags (`FOUNTAIN_SIZE 14 14`, `FOUNTAIN_TIERS 2 2`, `FLAG_CLEAN 0 0`, `PLAZA_WALKABLE 0 0`, one check-script `pairs` shadow bug fixed); 176 rocks 0.8-2.5 studs in clusters (`ROCK_COUNT 101 40`, `ROCK_SIZE 1.40 1.2`, `ROCK_VISIBLE 22 8`); 177 pathedge 1-2 stud plants (`EDGE_HEIGHT 1.59 1`, `EDGE_VISIBLE 458 12`, `EDGE_OFF_ROAD 0 0`); 178 sawah rounded Grass bunds (`BUND_COLOR 0 12`, `BUND_SHAPE 0 0`, `PADI_ROWS 294 10`, `TUFT_SHAPE 0 0`); 179 Pasar Cobblestone/Pavement pads + bright stripes (`PAD_MATERIAL 0 0`, `STRIPE_VALUE 0.925 0.6`, `STALLS 12 10`, `LANE_CLEAR 0 0`); 181 wood plot gates + one sign each (`GATE_MATERIAL 0 0`, `GATE_SIGN 10 10`, `GATE_CLEAR 0 0`). Suite **2904**, `selene src` 0/0/0; WORK_QUEUE items ticked. 2026-11-22 - section P item 173 COMPLETE: pakrt facade ridge caps rebuilt onto the two real Greybox RoofRidges (world-Z axis per live geometry), real Server-VM PASS `CAP_ON_RIDGE 7 7` / `NO_FLOATERS 0 0` (`h/2026-11-22-round10/CHECK_173.txt`), suite 2874; WORK_QUEUE item 173 ticked. 2026-11-22 - designer verdicts for round 10 recorded; section Q (items 186-227) queued. 2026-11-22 — main-session Studio review of section O recorded (REVIEW_ROUND10_STUDIO.html); fixes queued as section P (items 173-185). 2026-11-22 — Round 10 section N progress: items 103-105 COMPLETE (`full_r9` additive review set, walkability `PATH_REACH 16 16`, tier thinning `TIER_THIN`), 106 BLOCKED (`AVATAR_FIT FAIL 2 16`, pre-existing shipping geometry), 107 COMPLETE (`SMOKE_CLEAN 0 0` both looks; real smoke_r8 `NumberSequence`->`NumberRange` bug fixed + guarded), 108 COMPLETE (`lapangan_r8` field: `LAPANGAN_PARTS`/`LAPANGAN_PATH_REACH`/`LAPANGAN_GOAL_SIZE` PASS, new ID 80), 109 COMPLETE (`pasar_ground_r8` Pasar ground: `PASAR_PAVING` 76>=60, `PASAR_GROUND_LANE_CLEAR` 0 overlaps, slab bottoms on GROUND_Y, new ID 81), 110 COMPLETE (`musala_r8` prayer house: `MUSALA_PARTS` 49, `MUSALA_DOOR_CLEAR` 0 hits, `MUSALA_PATH_REACH` 0 overlaps, new ID 82; stale `Painted` material + two harness geometry bugs fixed), 111 COMPLETE (`lumbung_r8` lumbung/pekarangan: `LUMBUNG_PARTS` 90, `LUMBUNG_DOOR_CLEAR` 0 hits, `LUMBUNG_PROPS_ON_GRASS` 0/24 grassy, Ground pads restored byte-exact LIFO, new ID 83; stale `Leaf` material fixed), 112 COMPLETE (`perahu_r8` boats/river life: `PERAHU_PARTS` 39, `PERAHU_RIVER_CLEAR` 0/39 overlaps in 56-stud [-28,28] span, 0 global channel hits, synthetic violation flagged, new ID 84; `BRIDGE_WALKABLE` unchanged), 113 COMPLETE (`irrigation_r8` irrigation/field life: `IRRIGATION_PARTS` 50, `IRRIGATION_WATER_ON_TERRACE` 0 failed / worst delta 0.25 <= 0.3 over 2 sheets, synthetic violation flagged, new ID 85; `SAWAH_TOPS` unchanged), 114 COMPLETE (`kincir_r8` water wheel: `KINCIR_ROT PASS 6.0000 3..9`, one folder/root/Heartbeat, real 6.02 deg/1.02s, disable stops+removes, re-enable fresh, new ID 86; all existing checks unchanged), 115 COMPLETE (`laundry_r8` hanging laundry: `LAUNDRY_PARTS` 44, `LAUNDRY_CLOTH_CLEAR` 0 wall hits / 12 cloths probed / 9 wall parts, synthetic overlap flagged, new ID 87; CLOTH_SWAY skipped; all existing checks unchanged), 116 COMPLETE (`layangan_r8` kites: `KITE_COUNT` 4 roots/4 Beams/4 anchors, `KITE_STRING_CLEAR` 4 rays/0 hits, `KITE_COST` 0.149ms < 0.2; two real Studio bugs fixed — invalid Beam FaceColor/Width and over-budget 44-part rotation; new ID 88; all existing checks unchanged), 117 COMPLETE (`seated_r8` seated villagers at Warung: `SEATED_COUNT` 4 real R15 rigs/4 Seats/all Sit=true after real 3s, `SEATED_ON_BENCH` 32 probes/0 hits, synthetic old-Z clip flagged, 4/4 props, disable/re-enable PASS; one real bench-clip bug fixed — seats ON bench gave 8 lower-leg hits, zLift 0.35->1.35 front edge; new ID 89; exact R7 catalog IDs only, no new IDs; thresholds/counts unchanged), 118 COMPLETE (`crops_showcase_r8` crop review plots: `CROPS_STAGED` 36 Models/3 stage plots/12 per stage/306 Parts/0 state objects, `CAMERA_CLEAR` 45 cameras/0 blocked incl. 3 new crop cameras, synthetic destroyed-crop discriminated, disable/re-enable PASS; standalone `crop_growth_check.luau` re-run PASS `CHECK CROP_GROWTH PASS 12 12` fresh Client VM; new ID 90; 3 Server review cameras crop_bibit/crop_tumbuh/crop_siap in ReviewCameras.luau + REVIEW_CAMERAS.md registry only; item 133 overlap noted as designer decision; no gameplay-state write), 119 COMPLETE (`season_r8_*` seasonal looks: CLIENT appliers for hujan/kemarau/panen; `SEASON_SAFE` 3/3, `SEASON_RESTORE` 3/3, `SEASON_DISTINCT` 16>=2 pairs 22/26/16; two real bugs fixed — server->client applier for client-only Clouds, MapSpec-unreachable PUDDLE_Y_FALLBACK=0.53; synthetic out-of-range + decor tint discriminated; new IDs 91-93), 120 COMPLETE (`rain_r8` client rain + mist: `RAIN_EMITTERS` 3/3, `RAIN_OFF_CERAH` 3/3 both directions, `RAIN_COST` 0.0042ms<0.5ms over 3600 steps; two real runtime bugs fixed — stale WEATHER_CERAH token + invalid NumberSequence keypoint constructor; synthetic rate/density flagged, exact restore, no override leak; new ID 94). Evidence `h/2026-11-21-round10/CHECK_103..124.txt,CHECK_133.txt` (Studio checks); LUNE-ONLY audits 123/125/126/127/128 in docs/v2/visual + specs; `SHOT_LIST.md` staging queue. Items 134/135 COMPLETE (`FINAL_REPORT.md`; refill re-read four files, 0 open bugs). N7 items 156-172 COMPLETE (refill: 7 sourced §11 engine-fact write-backs, 21 URLs access 2026-11-22 + 10 stale CANDIDATES/CANDIDATE_INDEX check cells refreshed, all still `pending`); N7 first queued as 136-152 collided with section-O 136-155, renumbered to 156-172 — all 171 item numbers now unique. Suite **2872 tests**, `selene src` 0/0/0. Earlier 2026-11-21 — Round 9 reviewed in Studio (`h/2026-11-21-review-round9/`): buildings_r8, hubveg_r8, facades_r8 and water_r8_a accepted; sawah, pathedge, river plants and plots rejected. WORK_QUEUE section O COMPLETE (items 136-155, before the rest of M; 2558 tests, selene 0/0/0); section M item 80 `streetfurn_r8` also COMPLETE (Studio PASS `STREETFURN` 37, `STRINGS_PARITY` 3 3, `STREETFURN_CLEAR` 0, `CHECK_080.txt`). Item 136 COMPLETE — additive review staging (`LookDevReview.enableAdditive`/`disableAll`), real Studio PASS `ADDITIVE_STAGE 3 3` (hubveg 96 + plots 120 + facades 60 staged together, 0 leaked) and `LOOKDEV_LEAK 0 0` (`CHECK_136.txt`); existing single-active enable/disable unchanged; item 137 COMPLETE — `water_r8_a` promoted to the shipping client default via `Water.mount()` at boot (no enable call), real Studio PASS `WATER_DEFAULT 5 5` (fresh Play, all five Terrain water properties equal variant A), `WATER_SAFE 3 3`, `WATER_RESTORE 3 3` (`CHECK_137.txt`); `water_r8_b` kept as rain-season candidate, c rejected. Earlier: Round 9 reviewed (items 68-73, 75-79 have Studio PASS evidence, 2451 tests, selene 0/0/0). WORK_QUEUE section N (round 10, items 102-135) queued: unblocks the pine backdrop (V-D4), combined full_r9 look, tier thinning, walkability and smoke audits, 14 more village candidates, weather and seasons, UI audits, doc hygiene. Earlier: WORK_QUEUE section M (round 9) in progress: M1 tools items 68–69 COMPLETE, M2 items 70–73 COMPLETE — `hubveg_r8` per-hub vegetation: 96 slots (16/hub × 6 hubs), 9 species, clone-first baked assets; real Studio PASS for all six `VEG_HUB_*` (16 ≥12), `VEG_SPECIES_HUB` (min=9 ≥4), `VEG_OVERLAP` (0 0) (`CHECK_70.txt`). `plots_r8` procedural plot fences + gate arches: 10 plots × 8 fence segments + 3 gate parts, no asset IDs; real Studio PASS `PLOT_FENCE` (min=8 ≥6), `GATE_CLEAR` (0 hits/10 gates) (`CHECK_71.txt`). `sawah_r8` procedural terrace dressing: 4 water sheets × 2 panes, 240 verge blades (80 tufts ×3), 1 gubuk, 3 stepping stones, no asset IDs; real Studio PASS `SAWAH_TOPS` (0 0.5), `SAWAH_WATER` (4 sheets), `SAWAH_VERGE` (240 ≥40), `GUBUK` (1 1) (`CHECK_72.txt`). `river_r8` bank vegetation + bridge rails: 84 veg (56 near bridge, both banks), rails both sides with an 8-stud clear deck, 6 stepping stones, no asset IDs; real Studio PASS `RIVER_BANK_VEG` (56 ≥30), `BRIDGE_RAILS` (2/2), `BRIDGE_WALKABLE` (8 ≥8), with 50 ids (`CHECK_73.txt`). `pathedge_r8` procedural dirt-path borders: 618 pieces (309 grass tufts, 283 pebbles, 26 puddles at Transparency 0.4) on both edges of all 4 arms + 56 ring segments + 2 continuations, no asset IDs; real Studio PASS `PATH_EDGE` (618 ≥120), `PATH_CLEAR` (0 intruders across 62 paths), with 51 ids (`CHECK_75.txt`). `water_r8_a/b/c` river water looks: 3 OFF-by-default CLIENT candidates tuning only the 5 Terrain water properties (clear tropical green / murky brown after rain / bright turquoise), pure data safe ranges + exact save/restore, no asset IDs; real Studio CLIENT-VM PASS `WATER_SAFE` (3/3 variants in range), `WATER_RESTORE` (3/3 exact restore of all 5 values), with 54 ids and no place saved (`CHECK_76.txt`). `buildings_r8` six real Creator Store Indonesian buildings (rumah/joglo/pendopo/warung/nipa) landed OFF by default as candidate 55; real Studio SERVER-VM PASS `BLDG_VISIBLE` (6/6), `BLDG_WIDTH` (6/6, widths 22.72–57.65), `BLDG_DOOR` (6/6 gauges 7.25 tall, zero rotation-aware collider overlaps), with `LOAD_FAILURES` (0 0), `LOOKDEV_LEAK` (0 leaks), `CAMERA_CLEAR` (0 blocked/26), 55 ids and no place saved (`CHECK_77.txt`). `facades_r8` procedural hub facade details: 60 tagged decorative Parts (10 × 6 hubs, all six kinds each) + six avatar-fit door gauges, anchored/welded/non-collidable, no asset IDs; real Studio SERVER-VM PASS `FACADE_PARTS` (6/6 hubs, 10 each), `DOOR_CLEAR` (6/6 gauges, zero rotation-aware collider/decorative hits), with `LOAD_FAILURES` (0 0), `LOOKDEV_LEAK` (0 leaks), `CAMERA_CLEAR` (0 blocked/26), 56 ids and no place saved (`CHECK_78.txt`). r8 check harness with `LOOKDEV_LEAK` PASS 0 leaks, and 26 MapSpec-derived review cameras with `CAMERA_CLEAR` PASS 0 blocked/26; see the section M entries below. Section L (round 8, items 61-67) COMPLETE — all real-Studio CHECK lines PASS (CLOUD_COVER, BED_FLUSH, VEG_NEAR, PROP_SIZE); see the section L entry below. Item 74 `ring_r8` BLOCKED — `NO_PINES` FAIL 254 0 in the default look (shipping `BackgroundForest` pines; two clean attempts, check not weakened), needs a designer scope decision (`CHECK_74.txt` + WORK_QUEUE "Decisions for designer"). Remaining section M (items 79-101) queued for the long unattended run: 30+ LookDev candidates across land, water, buildings, hubs, life, light and sound, plus audits. Earlier: WORK_QUEUE section L (round 8, items 61-67) was queued: cloud cover hiding sky E, flower-bed mounds, near-ground vegetation, better prop models. Earlier: round-7 Studio review (`h/2026-11-21-review-round7/`). The npcs_r7 villagers now wear designer-picked catalog outfits (`h/2026-11-21-catalog-outfits/`), with 2343 tests passing. Earlier: 2026-11-20 — round-6 designer verdicts recorded from real Studio shots (`h/2026-11-20-review-round6/`): sky_r6_e and spawn_ground_r6 were chosen. Root cause of the missing hats and the sparse vegetation: runtime LoadAsset is not authorized for unowned Creator Store models, while Edit-mode GetObjects works. WORK_QUEUE section K (round 7, items 53–60) COMPLETE — all eight real-Studio checks PASS; see the section K entry below. Earlier: WORK_QUEUE section J items 44–52 COMPLETE. Item 44: six OFF-BY-DEFAULT Creator Store sky candidates `sky_r6_a`..`sky_r6_f` wired — six real free Models, 36 face IDs read from a Play-Solo Server VM and recorded in `h/2026-11-20-sky-r6-asset-load/REPORT.md` (`SEEN-IN-STUDIO` for the load only), one shared humid atmosphere + sun/ray/bloom/CC stack, one saved ~20° camera. Item 45: `spawn_ground_r6` server candidate — tanah Parts over the FULL road corridor including the 30-wide back ring strip R5 left dark, `FloraGrass` wedges masked off flower beds and tagged plots, exact Visible/CanCollide restore, default generators untouched. Item 46: two OFF-BY-DEFAULT CLIENT candidates `terrain_r6_a`/`terrain_r6_b` — Terrain-wide texture override dropped; built-in Grass/Ground/Mud colours tuned via pcall-guarded `SetMaterialColor` with exact restore; CC0 maps kept on parts/meshes only; saved camera `{0,20,72}`→`{0,5,14}`. All verdict cells blank; `sky_r5` unchanged as the round-6 baseline. Final suite 2332 passing; `selene src` 0/0/0; focused stylua and `git diff --check` clean; `LookDev.IDS` = 43. Items 47–52 complete (below); no Gate 1 row became agent-closable. Item 47 prep: `KAMPUNG_VEGETATION.md` + 25 real Creator Store IDs in `h/2026-11-20-r6-vegetation-ids/REPORT.md`; item 48 Route B finding in `h/2026-11-20-r6-costume-research/REPORT.md`. Round-5 designer verdicts recorded from real Studio shots (`h/2026-11-20-review-round5/`); WORK_QUEUE section J (round 6, items 44–52: Creator Store sky comparison with six real free IDs, ground fix, terrain rethink, kampung vegetation, role costumes, designer kit and terrain brief, real-size props) queued. The designer composes spawn and sculpts the terrain himself. Earlier: WORK_QUEUE section I items 35–43 COMPLETE (long-run closed). Item 43 refill re-read this tracker, WORK_QUEUE, `BUGS.md` and `GATE1.md`: no blocked item is agent-closable; all remaining blockers are licensed real IDs / Open Cloud uploads / designer-vision verdicts / designer hardware (phone, five humans, published place, multi-client Local Server). Single final report with commits, blockers and decisions at `h/2026-11-20-final-report/FINAL_REPORT.md`. `BUGS.md` has no open blocker/major defect; GATE1 rows still 2 BLOCKED / 1 LUNE-ONLY / 8 UNVERIFIED. (At item 43 close: final suite 2248 passing; `selene src` 0/0/0; focused stylua and `git diff --check` clean; `LookDev.IDS` = 31.) No place saved or published. Earlier in section I: items 35–42 complete. Item 35: `textures_r4` darkening fixed by neutralising Terrain material colours while the CC0 base-material override is live and restoring exact originals on disable (`h/2026-11-20-textures-r4-fix/REPORT.md` has live before/during/after reads). Items 36–39: four new OFF-BY-DEFAULT candidates wired and spec'd — `spawn_ground_r5` (feathered tanah paths, road default untouched), `vegetation_r5` (pisang/dense bamboo, no kelapa or pines, exclusion zones, R4 IDs), `sky_r5` (bright humid sky from two reused real CC0 HDRIs, Clouds.Cover 0.4, no ridge, seam fix), `props_r5` (right-sized tools, contextual gudang karung stack, R4 IDs). Item 40: `npcs_r5` solid upright R15 villagers from body-colour HumanoidDescriptions plus three real free Creator Store hat Models (creators/URLs in `art/models_r5/npcs/MANIFEST.md`); peci/batik/sarong noted as Designer builds, no ID invented. Item 41: `spawn_r5` off-by-default dressing pass composes only approved/temporary assets (temporary gudang+warung, jemuran, contextual gudang karung stack, rescaled tools, pisang + dense bamboo, 5 R15 villagers) from the R4/R5 source maps; tier budgets 50/100/150 instances and 50k/100k/150k tris (Sedang default ~23/58k est.), north-road corridor kept clear, saved camera `{0,20,72}->{0,5,14}` in `SPAWN_DRESSING_R5.md`; spec `tests/specs/spawn_dressing_r5_spec.luau`. Item 42: round-5 review handoff written at `h/2026-11-20-review-round5/REVIEW_ROUND5.md` + `REVIEW_ROUND5.html` and `docs/v2/visual/REVIEW_ROUND5.md`; all 8 candidates enable in a fresh Play VM, saved cameras sightline-checked in VM (props_r5 honestly flagged as pine-screened), verdict cells blank, no screenshot claim (pixels unobtainable this session). All verdicts blank. Earlier the same day: designer verdicts on round 4 recorded from real Studio shots (`h/2026-11-20-review-round4/STUDIO_REVIEW.md`); WORK_QUEUE section I (round 5, items 35–43: texture fix, dirt-path spawn ground, vegetation cleanup, Indonesian sky, props, R15 characters, spawn dressing) queued. Earlier: WORK_QUEUE section H (round 4, items 28–34) complete. All seven round-3 review bugs fixed with regression specs (`tests/specs/review_round3_bugfix_spec.luau`, including the throwing-root `LookDevReview` cases). `textures_r4` (12 CC0 base-material override sets / 36 Image IDs), `sky_r4_a/b/c` (3 CC0 HDRIs / 18 cube faces, one face verified in a fresh Play Client VM) and four textured r4 model families (21 real CC0/CC BY Model IDs) integrated off by default with blank verdicts; `SPAWN_DRESSING.md` planning brief written. `REVIEW_ROUND4.md` plus the description-based `docs/v2/evidence/h/2026-11-20-review-round4/REVIEW_ROUND4.html` and `REPORT.md` capture all eight candidates from the saved cameras via the vision observer with blank verdicts and an explicit "not a screenshot claim" note — no screenshot pixels were retained, so no image is embedded; Play stopped, nothing saved or published. All 75 r4 IDs licence-audited CC0/CC BY with attribution; banned sources absent. `LookDev.IDS` = 31. Item 34 re-checked items 12/14/15/16 — all remain `BLOCKED` (blank verdicts, no approved look, missing L7.1 VFX assets, unrigged police dummy, designer hardware). After item 41: 2248 passing; `selene src` 0 errors / 0 warnings / 0 parse errors; focused stylua and `git diff --check` clean. Previously item 40 2232; items 36-39 2219; item 35 2177; before that 2173.

**Long-run 2026-11-21 — WORK_QUEUE section O item 138 COMPLETE (does items 102 + 74):** the default
`BackgroundForest` is now a deterministic tropical wall of 272 trees / 4 species (bambu, kelapa,
mangga, pisang) from `Shared.ModelMapForestR9`, ring band 260-380 plus hills 400-460. The stale
top-level pine forest baked into the saved place is destroyed at build time. Real Studio fresh-Play
Server-VM PASS: `NO_PINES 0 0`, `RING_COUNT 272 250`, `RING_SPECIES 4 4`, `PERF_BUDGET 334 500`,
`LOAD_FAILURES 0 0`, `LOOKDEV_LEAK 0 leaks`, `CAMERA_CLEAR 0 blocked`, `ADDITIVE_STAGE 3 3`
(`h/2026-11-21-round9/CHECK_138.txt`, `CHECK_102.txt`, `CHECK_74.txt`). `PERF_BUDGET`'s proxy was
aligned to the recorded 100-stud census method (`2026-11-19-budget-check/REPORT.md`, baseline 335);
the target 500 was not changed. Old pines stay OFF by default behind `LookDev.IDS[58]`
`forest_pines_legacy`, which stages 83 pines and restores all 272 tropical trees exactly.
Items 74/102/138 ticked; the item-74 Decisions block is retired. Suite **2467 tests**; `selene src` 0/0/0.

Item 139 COMPLETE: the stray yellow pole was `FacadeRidgeCap` (25.6–51.2 studs from `width * 0.8`;
pakrt 38.4, laid across its Z-running ridge). Caps are now 10 studs, pakrt's cap turned along Z, and
pakrt's left eave moved 1.5 studs inward. New `FACADE_STRAY` check PASS `0 0` across all six hubs;
`FACADE_PARTS 6 6` and `DOOR_CLEAR 6 6` unchanged (`h/2026-11-21-round9/CHECK_139.txt`). Suite
**2468 tests**; `selene src` 0/0/0.

Item 140 COMPLETE: sawah terraces now stage real padi rows (2-stud spacing, 3-5-blade clumps) instead
of flat verge bars. Real Studio staged-Play PASS `TUFT_SHAPE 0 0`, `PADI_ROWS 294 10`,
`PADI_CLUMPS 1764 250`, `SAWAH_GREEN 76 40`, `SAWAH_TOPS 0 0.5`, `SAWAH_WATER 4 4`, `GUBUK 1 1`
(`h/2026-11-21-round9/CHECK_140.txt`). The 35,520 staged parts exist only while this OFF-by-default
candidate is on; default PERF_BUDGET stays 334/500. Suite **2471 tests**; `selene src` 0/0/0.

Item 141 COMPLETE: `river_r8` thin posts replaced with 54 baked bank plants (5 species, 27 tall) and
12 half-buried boulders; bridge rails/stones unchanged. Real Studio staged-Play PASS
`RIVER_BANK_VEG 54 >=40`, `BANK_PLANT_SHAPE 0 0`, `RIVER_ROCKS 12 >=12`, `BRIDGE_RAILS 2 2`,
`BRIDGE_WALKABLE 8 >=8` (`h/2026-11-21-round9/CHECK_141.txt`). Suite **2474 tests**; `selene src`
0/0/0.

Item 142 COMPLETE: `pathedge_r8` now places 626 baked grass-clump/pebble pieces at halfWidth+0.3..2.5
on both sides of every MapSpec path. Real Studio staged-Play PASS `PATH_EDGE_OFFSET 0 0`,
`PATH_CLEAR 0 0`, `PATH_EDGE 626 >=120` (`h/2026-11-21-round9/CHECK_142.txt`). FLAGGED, not hidden:
with this candidate staged `PERF_BUDGET` is 1146/500, over the Sedang proxy; item 142 has no perf
clause and no check was weakened. CANDIDATES.md marks it pending/over-budget; default look stays
334/500. Suite **2476 tests**; `selene src` 0/0/0.

Item 143 COMPLETE: `plots_r8` rebuilt to the canonical plot module — 3-stud two-rail bamboo fence,
posts every 4 studs, gate lintel + name sign, scarecrow, mailbox, 2-stud outer ditch, gubuk in plots
2/5/8, plus 10 new `plot_aerial_01..10` review cameras. Real Studio staged-Play PASS
`PLOT_FENCE 16 >=8`, `PLOT_FENCE_VISIBLE 87 >=70`, `GATE_CLEAR 0 hits`, `CAMERA_CLEAR 0 blocked/36`
(`h/2026-11-21-round9/CHECK_143.txt`). First run correctly FAILED visibility 37 (rails occluded by
their own posts); the measurement now excludes self-occlusion, target 70 unchanged. Suite
**2482 tests**; `selene src` 0/0/0; default PERF_BUDGET 334/500.

Item 144 COMPLETE: `hubveg_r8` densified to 36 anchors / 50 staged instances per hub (300 total),
with >=2 canopy trees per hub at 8-12 studs, 2 pisang groups of 3, 2 bamboo clumps of 5-7 culms
(10.5-12 studs), door flower beds, all within 40 studs. Real Studio staged-Play PASS
`VEG_HUB_* 50 >=30`, `HUB_TREES 2 >=2`, `VEG_SPECIES_HUB 14 >=4`, `VEG_OVERLAP 0 0`,
`PATH_REACH 0 0`, `DOOR_CLEAR 6 6` (with facades staged), `FACADE_STRAY 0 0`, `CAMERA_CLEAR 0/36`
(`h/2026-11-21-round9/CHECK_144.txt`). DOOR_CLEAR correctly failed 0/6 with hubveg alone (no facade
gauges). FLAGGED, not hidden: staged PERF_BUDGET 799/500 (hubveg) / 848/500 (+facades), over the
Sedang proxy; item 144 has no perf clause, no check weakened, CANDIDATES.md records the flag, default
look stays 334/500. Suite **2486 tests**; `selene src` 0/0/0.

Item 145 COMPLETE: `blocks_r9` fills the village grass blocks with 72 medium trees (6-12 studs, 4
species) and 96 shrubs, deterministic lattice with R5 exclusion zones, 3-stud spacing and review-camera
sightline rejection, reusing verified R4/R6 IDs. Real Studio staged-Play PASS `BLOCK_TREES 72 >=60`,
`BLOCK_SPECIES 4 >=4`, `VEG_OVERLAP 0 0` (with hubveg), `PATH_REACH 0 0`, `AVATAR_FIT 0 0`,
`CAMERA_CLEAR 0 blocked/36` (`h/2026-11-21-round9/CHECK_145.txt`). First run correctly FAILED
CAMERA_CLEAR 1/36 (a block tree in the hub_warung 6-stud sightline); data now excludes all 36 named
camera rays, check unchanged. PERF_BUDGET recorded: 354/500 blocks alone, 819/500 with hubveg
(flagged, item asks only that it be recorded); default look 334/500. Suite **2495 tests**;
`selene src` 0/0/0.

Item 146 COMPLETE: building kit doc + ground-level pivots. `stage()` sets each staged building's
`WorldPivot` to (footprint centre, bbox-bottom Y, z) facing -Z; geometry unchanged. Real Studio
staged-Play PASS `PIVOT_GROUND 0 0` (max delta ~8e-4 of 0.2 tolerance), `BLDG_VISIBLE 6/6`,
`BLDG_DOOR 6/6`, `BLDG_WIDTH 6/6`, `CAMERA_CLEAR 0/36` (`h/2026-11-21-round9/CHECK_146.txt`).
`docs/v2/visual/art/BUILDING_KIT.md` records ID/licence/bbox/door offset per building and a hub
mapping marked PROPOSAL awaiting the designer (no look verdict by an agent). Suite **2497 tests**;
`selene src` 0/0/0; default look unchanged.

Item 147 COMPLETE: `hubs_real_r9` stages one real Creator Store building per hub (PROPOSAL mapping
from BUILDING_KIT.md, pending designer), downscaled into MapSpec footprint+2, ground-base pivot, with
the greybox body hidden but its Sign kept. Real Studio staged-Play PASS `HUB_FIT 0 0` (6/6 staged,
0 offenders), `DOOR_CLEAR 6 6`, `PATH_REACH 0 0`, `LOOKDEV_LEAK 0`, `CAMERA_CLEAR 0/36`
(`h/2026-11-21-round9/CHECK_147.txt`). Verified hide/restore: body Transparency 1 / CanCollide false
while staged, Sign unchanged 0, after disable body back to 0/true, state attribute removed, folder
gone. DOOR_CLEAR/PATH_REACH correctly failed 0/6 and 6/0 with hubs_real alone (no facade/veg gauges);
with the documented additive set both PASS — no check weakened. PERF_BUDGET FLAGGED not hidden:
692/500 alone, 1206/500 additive (facades+hubveg+hubs_real), over the Sedang proxy; item has no perf
clause, default look 334/500. Suite **2506 tests**; `selene src` 0/0/0.

Item 148 COMPLETE: `pasar_awnings_r8` stages 12 procedural lapak stalls (72 alternating red/white/blue
stripe Parts, counters, produce crates, baskets, hanging cloth, lamps) around the Pasar, built from
original Parts with no asset IDs or real brand. Real Studio staged-Play PASS `STALLS 12 >=10`,
`AWNING_STRIPES 72 >=30`, `LANE_CLEAR 0 0` (6-stud lane), `PASAR_AWNING_ON_GRASS 0 0`, `CAMERA_CLEAR 0/36`
(`h/2026-11-21-round9/CHECK_148.txt`). Each stall has a Ground voxel pad (ReadVoxels snapshot -> FillBlock
-> WriteVoxels LIFO restore); restore verified byte-for-byte, LOOKDEV_LEAK 0. PERF_BUDGET FLAGGED not
hidden: 558/500 over the Sedang proxy; item has no perf clause, default look 334/500. Suite **2515 tests**;
`selene src` 0/0/0.

Item 149 COMPLETE: `plaza_r9` dresses the central Lapangan with a water-disc fountain, 4 benches,
4 striped umbrellas (24 alternating red/white/blue stripes), bunting between 2 poles (11 flags) and
one ~12-stud procedural shade tree, all original Parts inside the 38x28 dressed area derived from
MapSpec.PLAZA. Real Studio staged-Play PASS `PLAZA_FOUNTAIN 1/1`, `PLAZA_BENCHES 4/4`,
`PLAZA_UMBRELLAS 4/4`, `PLAZA_BUNTING 1/1`, `PLAZA_SHADE_TREE 1/1`, `PLAZA_LANE_CLEAR 0 0`
(4 six-stud lanes), `PLAZA_PATH_REACH 0 0` (4 road-arm corridors), `CAMERA_CLEAR 0/36`
(`h/2026-11-21-round9/CHECK_149.txt`). PERF_BUDGET 404/500 — under the Sedang proxy; default look
334/500. Suite **2524 tests**; `selene src` 0/0/0.

Item 150 COMPLETE: `ronda_tower_r9` stages a bamboo Pos Ronda watchtower at MapSpec.RONDA_TOWER,
height 30 studs (brief 28-32), 7.7x7.7 base (brief 8x8 + 1), with deck, pitched roof, kentongan and
ladder — all 24 original Parts, no asset IDs, greybox untouched. Position from RECONCILIATION.md row
6 decision "MAP_SPEC position, brief height". Real Studio staged-Play PASS `TOWER_HEIGHT 30 28..32`,
`TOWER_BASE 7.7 <=9`, `TOWER_PATH_CLEAR 0 0` (0 of 24 parts over 62 MapSpec paths), `LOOKDEV_LEAK 0`
(`h/2026-11-21-round9/CHECK_150.txt`). PERF_BUDGET 334/500 — equal to default, under the Sedang
proxy. Suite **2532 tests**; `selene src` 0/0/0.

Item 151 COMPLETE: `rocks_r9` scatters 48 half-buried rocks in three procedural shapes (16 each:
round/wedge/cluster stand-ins, no verified rock model id exists), bands 24 river-bank / 12 hill-foot /
12 field-edge, 1.6-3.6 studs, no asset IDs. Real Studio staged-Play PASS `ROCK_COUNT 48 >=25`,
`ROCK_SPECIES 3 >=2`, `ROCK_PATH_CLEAR 0 0` (0 of 80 parts over 62 MapSpec paths), `ROCK_GATE_CLEAR 0 0`
(0 of 48 rocks within 2 studs of 10 plot gates, plotCenter source), `CAMERA_CLEAR 0/36`
(`h/2026-11-21-round9/CHECK_151.txt`). PERF_BUDGET 334/500 — equal to default, under the Sedang proxy.
Suite **2541 tests**; `selene src` 0/0/0.

Items 152–155 COMPLETE (section O4 verdicts and review). Item 152: CANDIDATES.md verdict cells audited
against the designer table — facades_r8 **yes** (stray pole fixed, item 139), pathedge_r8 **no**,
sawah_r8 **no**, plots_r8/river_r8 `pending` redo/partial, water_r8_c **no**; all three gallery tables
still spec-valid (`candidate_gallery_spec`). Item 153: six new MapSpec-derived Server cameras added
(`pasar_awnings`, `plaza_centre`, `ronda_tower`, `river_rocks`, `forest_wall`, `canonical_overview`),
plot_aerial_01..10 confirmed; REVIEW_CAMERAS.md count 26→42. Real Studio full-set PASS
`CAMERA_CLEAR 0 blocked/42 checked` (`h/2026-11-21-round9/CHECK_153.txt`). Item 154:
`docs/v2/visual/CANONICAL_GAP.md` — 29 canonical features (10 default / 18 candidate / 1 missing:
balai desa), counts + evidence only, no look grading; missing entry is a visual-only proposal. Item 155:
`REVIEW_ROUND9.md` §23 review pack (additive sequence from `canonical_overview`, per-candidate camera
table, all CHECK_*.txt paths) + new `docs/v2/visual/SHOT_LIST.md` (14 candidates + additive + 2 base
shots, no grading). Suite **2547 tests**; `selene src` 0/0/0.

Item 80 COMPLETE: `streetfurn_r8` stages 30 Models / 116 original Parts — 21 lampu/obor posts every
40 studs on the MapSpec ring-road verge (11 lampu, 10 obor), 3 papan petunjuk (sign text from Strings
keys `sign_pasar`/`sign_sawah`/`sign_balai`, no Text literals), a south bridge-approach gapura, an east
road-arm tiang listrik line with an 8-segment sagging cable, and 2 bale-bale shelters; no asset IDs.
Real Studio staged-Play PASS `STREETFURN 37 >=18+all kinds`, `STRINGS_PARITY 3 3`,
`STREETFURN_CLEAR 0 0` (0 of 25 non-exempt parts over 62 MapSpec paths; verge posts/gapura/pole/cable
exempt per the brief), `LOOKDEV_LEAK 0`, `CAMERA_CLEAR 0/42`
(`h/2026-11-21-round9/CHECK_080.txt`). Initial run failed on a `RECIPES.post` vs emitted `lampu` key
mismatch; fixed by renaming the recipe key + a spec guard, re-verified green. PERF_BUDGET 369/500 staged
— above the 334/500 default but under the Sedang proxy (500); FLAGGED, keep off by default. Suite
**2558 tests**; `selene src` 0/0/0.

Item 81 COMPLETE: `spanduk_r8` stages Warung and Pasar signs, a south-road-crossing spanduk and two
bunting strings — 5 signed Models + 2 bunting strings of original Parts, no asset IDs, no real brand.
Sign text rendered via `Strings.get` with the existing `Visuals.fonts` (no Text literals); 5 new Strings
keys (`spanduk_selamat_datang`, `sign_warung`, `spanduk_pasar`, `bunting_mampir`, `bunting_belanja`).
Real Studio staged-Play PASS `SIGN_TEXT_PARITY 5 5` (all keys id+en valid), `SIGN_FACING 0 <=30deg`
(5 signs, worst 0deg toward hub_warung/hub_pasar/canonical_overview), `LOOKDEV_LEAK 0`, `CAMERA_CLEAR
0/42` (`h/2026-11-21-round9/CHECK_081.txt`). Harness crossed Luau's 200-register top-level limit with
the new SIGN locals; fixed by scoping the two checks in a `do...end` block, no check weakened.
PERF_BUDGET 359/500 staged — above the 334/500 default, under the Sedang proxy; FLAGGED, off by
default. Suite **2570 tests**; `selene src` 0/0/0.

Item 82 COMPLETE: `animals_r8` stages 11 simple-Part animals (4 ayam by the warung, 4 bebek by the
river, 2 kambing near the sawah, 1 kucing on a roof) behind ONE client Heartbeat loop driving a pure
shared step function with MapSpec-derived wander bands; no asset IDs. Real Studio Server-VM PASS on a
deterministic 60 s sim (3600 steps) `ANIMAL_COUNT 11 1..14`, `ANIMAL_BOUNDS 0 offenders` (X ±400,
Y 0.5..22.5 above the 0.5 ground plane), `ANIMAL_COST 0.0068 <0.3ms/step`, `CAMERA_CLEAR 0/42`
(`h/2026-11-21-round9/CHECK_082.txt`). No real 60 s wait — deterministic sim in a `do...end` harness
scope. PERF_BUDGET 334/500 — equal to default, under the Sedang proxy. Suite **2580 tests**;
`selene src` 0/0/0.

Item 83 COMPLETE: `flyers_r8` stages procedural burung (6, high over the plaza), kupu-kupu (10, flower
beds) and capung (4/6/8 by FidelityTier) — body + two sine-flapping wing Parts, no asset IDs, one
client Heartbeat loop over a pure shared step. Real Studio Server-VM PASS on a deterministic 60 s sim
`FLYER_COUNT PASS 0 invalid tiers` (all 3 tiers within per-kind caps; totals 20/22/24) and
`FLYER_COST 0.0104 <0.3ms/step` (24 flyers), `CAMERA_CLEAR 0/42`
(`h/2026-11-21-round9/CHECK_083.txt`). PERF_BUDGET 334/500 — equal to default, under the Sedang proxy.
Suite **2591 tests**; `selene src` 0/0/0.

Item 84 COMPLETE: `smoke_r8` stages 9 emitters (2 chimney smoke, 1 warung steam, 6 torch flames, max
Rate 10 <= 12) and 6 flickering PointLights (Range 14 <= 30), original Parts, no asset IDs, one client
Heartbeat flicker + ClockTime night gate. Real Studio Server-VM pure-data PASS `EMITTERS 0 violations`,
`LIGHTS 0 violations`, `TORCH_NIGHT 13=false 20=true 5=true` (torches off at ClockTime 13),
`CAMERA_CLEAR 0/42` (`h/2026-11-21-round9/CHECK_084.txt`). PERF_BUDGET 334/500 — equal to default, under
the Sedang proxy. Suite **2601 tests**; `selene src` 0/0/0.

Item 85 COMPLETE: `wind_r8` sets a gentle `workspace.GlobalWind` (magnitude 2.92 <= 12), sways 6
jemuran cloths + 4 hanging sign boards with 10 capped TweenService tweens, and leans 6 pisang/bambu
Models from ONE Heartbeat sine loop (Euler X -3.5..-2.7deg within +/-4), original Parts, MapSpec hubs,
no asset IDs; the existing gameplay `Wind.luau` is untouched. Real Studio CLIENT-VM MUTATING cycle
PASS `WIND_SET 2.92/<=12`, `SWAY_TWEENS 10/<=30`, `WIND_RESTORE 0 mismatches` (16 targets + GlobalWind
restored exactly), `LOOKDEV_LEAK 0`, `CAMERA_CLEAR 0/42`
(`h/2026-11-21-round9/CHECK_085.txt`). MapSpec+Ground injected into the Client datamodel at runtime
(ServerScriptService does not replicate Edit->Client); place not saved. PERF_BUDGET 334/500 — equal to
default, under the Sedang proxy. Suite **2611 tests**; `selene src` 0/0/0.

Item 86 COMPLETE: `npcs_r8` adds 5 villager roles (tengkulak, debt_collector, ibu_warung, anak_anak,
bapak_ojek) as R15 rigs in a second camera-facing row (z=14, 6-stud spacing) through
`HumanoidDescription` and 15 real catalog IDs (5 distinct shirt/pants pairs + a hat each), all sourced
via catalog API + economy GET and recorded in `ASSET_MANIFEST.md`. Kids get BodyHeightScale 0.8 /
HeadScale 1.2; `HumanoidDescription.BodyHeightScale` is absent in this Studio build, so the applier
writes the authoritative scale to the rig Humanoid's scale Instances after build (verified live:
kid 0.8/1.2 vs adult 1/1). Real Studio SERVER-VM PASS `NPC8_ROLES 5/5` (each rig >=1 Accessory),
`NPC8_OUTFITS 5/5` (5 distinct pairs, 5 hats), `LOAD_FAILURES 0`, `LOOKDEV_LEAK 0`, `CAMERA_CLEAR 0/42`
(`h/2026-11-21-round9/CHECK_086.txt`). PERF_BUDGET 420/500 — flagged, up from default 334 by the
extra rigs, still under the Sedang proxy ceiling. Suite **2621 tests**; `selene src` 0/0/0.

Item 87 COMPLETE: `npcs_idle_r8` gives 10 staged R15 villagers a calm idle — the real catalog
animation 71483261700852 "Standing Idle" (type 61, recorded in `ASSET_MANIFEST.md`) plays on each
`Animator`, plus one shared Heartbeat sine root sway <=1deg. Roles/outfits come from the verified
`npcs_r7` + `npcs_r8` maps (5+5). Studio SERVER-VM PASS `IDLE_TRACKS 10/10` (10 playing tracks),
`IDLE_SWAY 10/10` (one loop, all 10 base pivots restored, 0 mismatches), `IDLE_COST 0.0018ms/<0.3ms`
(3600-step sim of the same hot-path step function), `LOAD_FAILURES 0`, `LOOKDEV_LEAK 0`,
`CAMERA_CLEAR 0/42` (`h/2026-11-21-round9/CHECK_087.txt`). A restore-audit defect (trailing
`resetDiagnostics()` wiped the audit) was found and fixed; re-run PASS. PERF_BUDGET 334/500, default.
Suite **2632 tests**; `selene src` 0/0/0.

Item 88 COMPLETE: `ambient_walkers_r8` stages up to 8 plain R15 villagers (no catalog outfit/asset ID)
on looped MapSpec road routes, driven by the REAL `NpcWalk.walkTo` in cancellable task.spawn loops —
ambient only: no interaction, dialogue or gameplay. `Humanoid.WalkSpeed` 6 <= 8. Studio SERVER-VM PASS
`WALKER_SPEED 6/8`, `WALKER_MOVE 8/8` (all rigs displaced live via NpcWalk; loopCount 1 after first
waypoint leg), `WALKER_WAYPOINTS 3/3`, `WALKER_STUCK 0/10s`, `WALKER_ROAD 0/8studs` (pure 90 s / 1800-step
sim of the same step math; NpcWalk yields via task.wait so real 90 s cannot be pumped), `LOAD_FAILURES 0`,
`LOOKDEV_LEAK 0`, `CAMERA_CLEAR 0/42` (`h/2026-11-21-round9/CHECK_088.txt`). A harness observation-window
defect (0.5 s < shortest ~3 s waypoint leg) was fixed to a 6 s bounded poll; assertion unchanged; re-run
PASS. PERF_BUDGET 334/500, default. Suite **2642 tests**; `selene src` 0/0/0.

Item 89 COMPLETE: `day_cycle_r8` ships the tuned Sore look as an OFF-by-default CLIENT candidate —
warmer lower sun (ColorShift_Top 255/190/96), darker Ambient (84/70/68), sunClockOffset -0.75,
ShadowSoftness 0.45 (shipping 0.3), still 20-40 s tweens; Maghrib and all other phases field-for-field
unchanged. Numeric limits newly documented in `visual/DAY_CYCLE.md` (Rec.709 luminance ratio, 1.25x
phase-jump headroom). Studio VM PASS `DAY_PHASES_MONOTONIC 0.623529 <=0.779412`,
`DAY_1600_CONTRAST 2.705297 >=2.592990` (+25.20% vs base 2.160825), `DAY_MAGHRIB_UNCHANGED 1 1`,
`LOAD_FAILURES 0`, `LOOKDEV_LEAK 0`, `CAMERA_CLEAR 0/42`, `PERF_BUDGET 334/500`
(`h/2026-11-21-round9/CHECK_089.txt`). A Color3-userdata vacuous PASS (0 >= 0 in Studio while Lune
measured 2.16->2.71) was found and fixed via pcall duck-typed channel reads + `baseRatio > 0` /
`baseJump > 0` non-vacuity guards — checks made stricter, no threshold weakened; re-run PASS. Visual
yes/no remains the designer's. Suite **2653 tests**; `selene src` 0/0/0.

Item 90 COMPLETE: `night_r8` is an OFF-by-default SERVER candidate staging 16 warm window panes
(`Neon`, `#FFCB7A`; 12 facade-window anchors + Pak RT's 4 real glass positions) and 12 shadowless
Rendah PointLights (6 street posts + 6 torches, Range 14, Brightness 0.6), all gated by
`Lighting.ClockTime` through one shared gate with a deterministic `setClockForCheck(20|13)` override
(never writes real Lighting). Studio SERVER-VM PASS `NIGHT_WINDOWS 16 >=12` (16 lit at 20:00, 0 at
13:00), `NIGHT_LIGHTS 12 <=24` (0 shadow offenders), `LOAD_FAILURES 0`, `LOOKDEV_LEAK 0`,
`CAMERA_CLEAR 0/42`, `PERF_BUDGET 334/500` (`h/2026-11-21-round9/CHECK_090.txt`). Exact folder/
listener/override restore. Visual yes/no remains the designer's. Suite **2659 tests**;
`selene src` 0/0/0.

Item 91 COMPLETE: `grade_r8_a/b/c` are three OFF-by-default SERVER colour grades (warm golden, fresh
green, hazy humid) touching only Atmosphere/ColorCorrection/Bloom/SunRays, never depth of field.
Inclusive numeric safe ranges documented in `visual/GRADE_R8.md` (established now — none existed).
Studio SERVER-VM PASS `GRADE_SAFE 3/3` (45 distinct live readings, all inside documented ranges),
`GRADE_RESTORE 3/3` (all 15 properties + Lighting descendant count exact after disable),
`GRADE_NO_DOF 0/0` (4 checks), `LOAD_FAILURES 0`, `LOOKDEV_LEAK 0`, `CAMERA_CLEAR 0/42`,
`PERF_BUDGET 334/500` (`h/2026-11-21-round9/CHECK_091.txt`). First run FAILed vacuously (all variants
read unchanged baseline) because the injected applier was never required so registration never ran;
the harness now requires it explicitly (spec-locked), no range/threshold weakened; re-run PASS.
Visual yes/no remains the designer's. Suite **2666 tests**; `selene src` 0/0/0.

Item 92 COMPLETE: `sounds_r8` is an OFF-by-default SERVER candidate staging six real free Creator
Store audio beds (jangkrik night, ayam + birds day, river + wind always, kentongan event) — each a
tiny invisible anchored Part hosting one looped positional Sound, Volume <= 0.5, RollOffMaxDistance
<= 80, all in one `JD_sounds_r8` SoundGroup. Six IDs sourced via Studio MCP `search_asset`, each
verified `IsLoaded=true` (real TimeLength, no `not authorized`) in BOTH Play VMs and recorded in
`visual/art/ASSET_MANIFEST.md`; no ID invented, no shipping audio slot changed. Studio SERVER-VM PASS
`SOUND_LOADED 6/6` (all loaded in 0.51 s with lengths; the <=10 s IsLoaded poll is the only available
not-authorized proxy), `SOUND_VOLUME 6/6` (max vol 0.5, rolloff 80, 0 offenders), `SOUND_RESTORE 1/1`
(all Sounds/Parts/group destroyed, exact restore), `LOAD_FAILURES 0`, `LOOKDEV_LEAK 0`,
`CAMERA_CLEAR 0/42`, `PERF_BUDGET 334/500` (`h/2026-11-21-round9/CHECK_092.txt`). Aural yes/no
remains the designer's. Suite **2672 tests**; `selene src` 0/0/0.

Item 93 COMPLETE (crop stage audit): live CLIENT-VM `Model:GetBoundingBox()` over all 12 crops x 3
stages (36 models), with staged parts anchored in the same call to freeze physics drift (two
identical runs). Verbatim `CHECK CROP_GROWTH PASS 12 12` — every stage within 0.5..6 studs and both
growth gaps >= 15% (`h/2026-11-21-round9/CHECK_093.txt`, full 36-row table). One defect found and
fixed BY RESCALING THE MODEL MAP, never by weakening the check: bawang bibit was 0.412 studs (<0.5)
with stem size[2] 0.8; `CropModelCandidates.archetypes.bawang.stem.size[2]` 0.8 -> 1.4 lifts bibit to
0.615 (0.615/1.147/1.579, g1 86.3%, g2 37.6%). `crop_growth_check.luau` (engine-only check) and
`crop_growth_audit_spec.luau` (locks thresholds 0.5/6/15 and the 1.4 rescale) added. Audit + data fix
only; no look/default change, no visual verdict. Suite **2672 tests**; `selene src` 0/0/0.

Item 94 COMPLETE (icon audit): `tools/icon_audit.py` (Python + Pillow, report-only) audits all 58
icon PNGs for size, alpha coverage (15-85% inclusive) and dHash-8x8 near-duplicates (Hamming<=5).
Deterministic output, exit 0, no visual judgment. Result: 51 coverage PASS / 7 FAIL (4 thin icons
6.07-14.66% + 3 opaque contact sheets 100%), 35 near-duplicate pairs (all render<->render_r3 same-slot
revisions / contact sheets / tier badges). `tier_biasa` numbers: render 256x256 47.13% hash
40d49e969696d460 nearest dist 5; r3 256x256 61.23% hash 50c492b2b296cc54 nearest dist 10
(`h/2026-11-21-round9/CHECK_094.txt`). Whether the r3 redraw resolved the designer verdict is a
visual call, NOT made here. No Luau/tests touched.

Item 95 COMPLETE (strings audit): extended `strings_integrity_spec.luau` — banned words now include
lorem/ipsum/dolor/"sit amet"/placeholder; long `id == en` strings (>=12 chars) emit a non-failing
`[STRINGS FLAG] id==en long key=... value=...` line (sorted) plus a determinism test. Baseline clean:
350 keys all with non-empty id/en, 0 placeholder hits; 2 long loanwords flagged, NOT failed
(`admin_title`, `raid_breaking`). All 32 `Text =` literals in src/client are empty/glyph/technical —
0 word-like player-facing strings to move, so no Strings.luau/src/client change
(`h/2026-11-21-round9/CHECK_095.txt`). Designer's call on flagged copy.

Item 96 COMPLETE (IconMap coverage): new pure-Lune `iconmap_manifest_spec.luau` — all 27 slots
(12/2/5/8 families) resolve via non-zero `IconMap.candidateIds` (the zero `entry.id` is by design),
every ID is recorded in the ASSET_MANIFEST.md icon CSV rows (55 parsed, 27/27 matched, 0 missing),
0 duplicates within r2 and 0 r2/r3 overlap (`h/2026-11-21-round9/CHECK_096.txt`). No invented IDs.
Suite **2676 tests**; `selene src` 0/0/0.

Item 97 COMPLETE (perf budget table): live dual-VM census (fresh default + all 79 candidates staged
alone via `enable`, deltas self-correcting against recorded `pre`; deterministic on repeats) recorded
in `visual/PERF_R9.md` + `h/2026-11-21-round9/CHECK_097.txt`. Verbatim `CHECK PERF_BUDGET PASS 334 500`
(default within Sedang ~500 draw-call proxy; 3921 inst / 1713 parts / 299 MeshParts / 66,248 prim tris
/ 0 emitters). MeshPart triangle count not exposed to Luau — reported as separate count, no invented
triangle figures; `smoke_r8` live emitters 0 here (MapSpec server-only; pure-data 9 from item 84).
8 over-budget candidates FLAGGED never hidden (pathedge_r8 1146, buildings_r8 1740, hubveg_r8 799,
hubs_real_r9 692, pasar_awnings_r8 558, vegetation_r7 584, npcs_idle_r8 505, crops 673) — all
off by default; reproduces prior CHECK_142/144/147/148 flags. Heavy sawah_r8 (408k prim tris / 30k
parts, outside spawn census) noted. No default change, no visual verdict. No Luau source/spec changed.

Item 98 COMPLETE (LOOKDEV_LEAK sweep): ran the item-68 leak check over all 79 `LookDev.IDS` in BOTH
VMs with all appliers registered (46 server + 33 client; no vacuous pass). Pre-fix server FAIL:
`CHECK LOOKDEV_LEAK FAIL 1 leaks: spawn_ground_r6(w3921->3963 +42,l6->6 +0) 0 leaks`; client PASS.
Root cause: `LookDevSpawnGroundR6.apply()` calls buildCovers()+buildPaths(), both call makeFolder(), but
old single `createdFolder` ref held only the second folder — the cover folder (41 parts) survived
restore, +42 descendants/cycle (also seen in item 97 residue). Fix: track every folder in a
`createdFolders` list, destroy all in clearCreated(); runtime-injected into Server VM, place NOT saved.
Post-fix both VMs `CHECK LOOKDEV_LEAK PASS 0 leaks 0 leaks` (candidateCount=79, two deterministic runs)
recorded in `h/2026-11-21-round9/CHECK_098.txt`. Hardened `spawn_ground_r6_spec` restore case (old
source-string assertion passed WITH the leak). 1 leak, 1 fix; no candidate hit the two-attempt BLOCKED
threshold. Suite **2676 tests**; `selene src` 0/0/0; stylua clean; diff clean.

Item 99 COMPLETE (Gate 1 evidence sweep): went through GATE1.md + BUGS.md LUNE-ONLY/UNVERIFIED rows.
Real Play Server VM drove pure shipped functions with the exact spec damaged inputs; verbatim `CHECK
BUG014 PASS` / `CHECK BUG018 PASS` twice each, recorded in `h/2026-11-21-round9/CHECK_099.txt`. Flipped
BUG-014 (Produce.snapshot) + BUG-018 (PlayerData.migrate) to SEEN-IN-STUDIO — full fix is a pure function
provable with no human input. LEFT with reasons: BUG-017 (sanitize half proven, isStale ordering needs
service mocks), BUG-015/016/019 (need Player/Remote/DataStore mocks), BUG-006/007 (visual sign-off), all
GATE1 rows (G1/G2/Q1 composite, G4b phone-visual, G6 fps half needs hardware + count recorded 13059/3921,
G7 five humans, Q6 published place, Q7 real device, Q8 inherently LUNE process gate). No Luau/spec changed.

Items 100+101 COMPLETE (review pack + no-op marker): appended §24 to `h/2026-11-21-round9/REVIEW_ROUND9.md`
(datamodel batches — note registry says grade/sounds are SERVER and animals/flyers/smoke/wind/day_cycle
are CLIENT, unlike item-100 shorthand; exact `enable(id, game)`/additive sequences; camera name per
candidate from `REVIEW_CAMERAS.md`; all 50 `CHECK_*.txt` paths) and wrote `CHECKS_SUMMARY.md` (one
PASS/LUNE-ONLY line per item 68–100; visual/aural grading left to designer). All items 68–100 ticked or
BLOCKED (74 closed via 138/102), so 101 no-op marker ticked. Section N (round 10) follows.

Item 103 COMPLETE (`full_r9` combined review set): staged all 13 approved/pending round-9 scene candidates
together (9 server + 4 client-applier ids) in one SERVER VM lane via `LookDevReview.enableAdditive`. Real
Play PASS, two deterministic runs, `h/2026-11-21-round10/CHECK_103.txt`: `CHECK CROSS_OVERLAP PASS 0
collidable pairs 0 pairs` (anti-vacuity guard: 13 folders, 35949 parts, 0 unreadable, stagedOk; 7 expected
non-collidable decorative overlaps reported), `CHECK STAGE_COUNT PASS 13 13`, `CHECK LOAD_FAILURES PASS 0 0`,
`CHECK LOOKDEV_LEAK PASS 0 leaks 0 leaks`, `CHECK PERF_BUDGET RECORDED 2041 500` (proxy 500, over but
off-by-default; default look still 334 per CHECK_097 — recorded, not hidden). First naive CROSS_OVERLAP
was vacuous (0 collidable parts by design); guard added. Deviation: additive review set, NOT a new LookDev
ID — one ID cannot span the two VM registries and would break 33 `#IDS==79` specs; item 136 precedent.
Decision recorded under WORK_QUEUE "Decisions for designer". No Luau/spec changed; no place saved.
Suite **2676 tests**; `selene src` 0/0/0.

Item 104 COMPLETE (Rendah/Sedang/Tinggi thinning): `Shared.TierThin.shouldKeep(tier, index, structural?)`
pure helper (even-index keep at Rendah <=50%; structural/nil-Sedang/Tinggi keep all; unknown->Tinggi),
`LookDev` tier injection, and 9 round-9 server appliers gating only DECORATIVE instances (structural
fences/bridge rails/water/boards/lamps/first-5 props never thinned). Real fresh-Play Server-VM PASS
`TIER_THIN` `h/2026-11-21-round10/CHECK_104.txt`: 8 thinnable candidates decorative Rendah <=0.55 x
Tinggi (hubveg 132->48, plots 468->234, sawah 7056->3528, river 138->69, pathedge 626->313, hubprops
17->7, streetfurn 18->9, spanduk 12->4), facades all-structural EXEMPT 60/60/60, structural count held
constant everywhere, Sedang==Tinggi, added=0, ANTI_VACUITY PASS. River MIN_BANK_VEG now validates
unthinned data; facades exemption + TIER_THIN decorative-count interpretation under WORK_QUEUE
"Decisions for designer". 11-case `tier_thin_spec` NEW. Suite **2687 tests**; `selene src` 0/0/0.

Item 105 COMPLETE (walkability audit): fresh Play Server VM, all 13 full_r9 candidates staged,
16 `PathfindingService:CreatePath({AgentRadius=2, AgentHeight=5.5, AgentCanJump=false})` routes from
`MapSpec.SPAWN` to 6 hub doors + 10 live staged `GateMarker` plot gates. Real Studio PASS
`h/2026-11-21-round10/CHECK_105.txt`: `CHECK PATH_REACH PASS 16 16`, anti-vacuity staged=13
folders=13 parts=35949 markers=10 routes=16, two deterministic runs. No blocker found -> no part
moved or shrunk, no check weakened; no source/spec/harness change (still **2687 tests**, selene
0/0/0). All lookdev parts CanCollide=false by design, so the guard proves real staging + routes.

Item 120 COMPLETE (`rain_r8` client rain + mist): NEW pure `ModelMapRainR8` (3-emitter recipe Rate 50/50/44, SPLASH_Y=0.53, MIST_DELTA=0.05/MAX=0.35, MAX_STEP_MS=0.5, no IDs/engine API) + NEW CLIENT applier `LookDevRainR8` (one Heartbeat camera-follow calling the same `pump(dt)` the cost check times, weather override, exact LIFO restore). New ID 94, client Review path, 3 harness checks (`RAIN_EMITTERS`/`RAIN_OFF_CERAH`/`RAIN_COST`), new spec, 1 CANDIDATES pending row. TWO real bugs fixed with no check weakened: (1) stale `WEATHER_CERAH` token made the `cerah` override a no-op; (2) invalid two-arg `NumberSequence.new(kp0,kp1)` left the folder empty — both now have Lune regression locks. Real fresh-Play CLIENT-VM PASS `h/2026-11-21-round10/CHECK_120.txt` (SEEN-IN-STUDIO): RAIN_EMITTERS 3/3, RAIN_OFF_CERAH 3/3 both directions, RAIN_COST 0.0042ms<0.5ms over 3600 steps, synthetic rate/density flagged, exact restore + no override leak. All existing checks byte-identical. Suite **2825 tests**, `selene src` 0/0/0. No visual/aural verdict.

Items 134/135 COMPLETE (N6 close + refill): item 134 NEW `h/2026-11-21-round10/FINAL_REPORT.md` — 20-commit table, 31 per-item lines (105-135), 16 blocked entries with verbatim FAIL/reason lines, 12 designer decisions, gates (itself not evidence). Item 135 re-read BUGS/GATE1/CANDIDATES/VISUAL_MASTER_PLAN; 0 open bugs, all remaining gate rows designer/hardware, all 45 pending candidate checks already PASS — queued 17 agent-closable objective doc/evidence items (N7, items 156-172: 7 §11 engine-fact write-backs + 10 stale check-cell refreshes) and named the checked file for each non-closable layer. No visual verdict, no place save.

N7 items 156-172 COMPLETE (refill close): 7 §11 engine-fact write-backs into `VISUAL_MASTER_PLAN.md` with 21 sourced `create.roblox.com` URLs (access 2026-11-22; undocumented points stated explicitly, never guessed) + 10 stale check cells in `CANDIDATES.md`/`CANDIDATE_INDEX.md` refreshed with PASS check ids and CHECK paths, mirrored verbatim, all still starting `pending` with no visual/aural verdict. N7 first queued as 136-152 collided with pre-existing section-O 136-155; renumbered to 156-172 (`DOC_FACT_136..142` -> `DOC_FACT_156..162`); all 171 item numbers unique. `FINAL_REPORT.md` addendum records the post-report work. Suite **2872 tests**, `selene src` 0/0/0. No visual verdict, no place save.

Items 132/133 COMPLETE (N6 review prep): item 132 NEW `h/2026-11-21-round10/SHOT_LIST.md` — 46 rows by datamodel (Server 35 incl. full_r9 additive, Client 11), verbatim enable calls, 42 unique CHECK paths all verified, all season_r8_*/grade_r8_* included, 0 rejected candidates; item 133 SEEN-IN-STUDIO `CHECK_133.txt` — 9 new round-10 cameras appended to `ReviewCameras.luau` (existing 45 byte-identical, coords from MapSpec) + doc (54 total), NEW `cameras_new_r10_spec` (real-registry guard), fresh-Play SERVER-VM full-set `CAMERA_CLEAR PASS 0 blocked/54 checked` at unchanged 6-stud ray; shot-list camera placeholders reconciled to new names. Suite **2872 tests**, `selene src` 0/0/0. No visual verdict, no place save.

Items 124/125/126 COMPLETE (UI objective audits): item 124 SEEN-IN-STUDIO `h/2026-11-21-round10/CHECK_124.txt` — 3 exact device-sim viewports, 116 GuiObjects/screen, 0 safe-area violations at 375x812/1024x768, 1 at 812x375 (PanelShadow auto-decoration escaped the panel-only UIScale refit) fixed at `Admin.luau:204` (UIScale parent frame->gui) and re-verified fresh-Play (shadow inside, panel unchanged), 31 compact designer controls <44px left + flagged, 0 truncated text; item 125 LUNE-ONLY `CONTRAST_AUDIT.md` + spec — 5 better-contrast token swaps (active tab state preserved via background), no new colours; item 126 LUNE-ONLY `TEXT_MIN_AUDIT.md` + spec — all under-14px text protected by locked body=13/small=11, zero code changes, no lock weakened. No visual verdict, no place save.

Items 123/127/128/131 COMPLETE (objective UI audits + hygiene, LUNE-ONLY unless noted): item 123 NEW `UI_THEME_AUDIT.md` + `theme_bypass_spec` — baseline 0 exact-colour theme-token duplicates (already 0, no reduction claimed, no colour code changed), 6 non-token radii left as designer decisions; item 127 NEW `assetmap_manifest_spec` (code IDs vs manifest) — 10 uncovered IDs appended to ASSET_MANIFEST.md coverage section (existing rows byte-identical), 24 unused marked, 0 code IDs deleted; item 128 NEW `CANDIDATE_INDEX.md` (95 IDs × family/datamodel/camera/verdict/module, no invented cameras) + `candidate_index_spec` (95/95 parity, documented-only cameras); item 131 NEW `docs/v2/evidence/h/INDEX.md` indexing all 82 dated folders (57 SEEN-IN-STUDIO, 24 LUNE-ONLY, 1 BLOCKED), downgrade audit found none. Suite **2860 tests**, `selene src` 0/0/0. No visual verdict, no place save.

Items 129/130 COMPLETE (visual doc hygiene): NEW `docs/v2/visual/REJECTED.md` (exactly 31 `**no**` candidates, verdict reasons verbatim, resolved module files, dependant column; no code deleted) and `VISUAL_MASTER_PLAN.md` refreshed (Last updated 2026-11-22, one dated status line per L1-L10, all 10 evidence paths verified; conservative statuses L8 BLOCKED on designer, L2/L7/L10 UNVERIFIED). Doc-only, no specs/tests.

Item 122 COMPLETE (`lamps_shadows_r8` night light cost audit): AUDIT-ONLY, no new ID (IDS stays 95). New `LIGHT_COST` harness check after `DAWN_SAFE` (SERVER VM, stages 13-ID full_r9 additive set, requires Shadows=false/Range<=30/Brightness<=3 with anti-vacuity totalLights>0) + new spec. Real fresh-Play SERVER-VM PASS `h/2026-11-21-round10/CHECK_122.txt` (SEEN-IN-STUDIO): LIGHT_COST PASS 0 0 violations, 13 IDs staged, totalLights=6 all Shadows=false/Range 14/Brightness 0.9, synthetic flag of each threshold + exact restore. Suite **2850 tests**, `selene src` 0/0/0. No visual verdict.

Item 121 COMPLETE (`subuh_r8` dawn look): NEW pure `ModelMapSubuhR8` (4 phases 4.5/5/5.5/6, Top.R+warmth monotone, DAWN_SAFE intersection bands, `BAND_EPSILON=1e-4`, birdsAudible>=6 no Sound) + NEW CLIENT applier `LookDevSubuhR8` (DayCycle tween rules, real Color3 both write paths, direct-write phase snap, LIFO restore, <=6 lamp glow @5:00-5:30 Shadows=false Range 14). New ID 95, 2 harness checks (`DAWN_PHASES_MONOTONIC`/`DAWN_SAFE`) after RAIN_COST, new spec, 1 CANDIDATES row. TWO real runtime bugs fixed with no check weakened/band widened: raw byte-table Color3 writes silently no-op (now `engineColor` both paths, plus nil TweenInfo pcall fix) and float32 `Density=0.2199999988` false-failing band min (now 1e-4 epsilon). Real fresh-Play CLIENT-VM PASS `h/2026-11-21-round10/CHECK_121.txt` (SEEN-IN-STUDIO): DAWN_PHASES_MONOTONIC 3/3, DAWN_SAFE 4/4, 4/4 phases changed to authored endpoints 0 band failures, synthetic brightness/phase discriminated, 1 s hold stable, exact restore + no override leak, no Sound staged. Suite **2843 tests**, `selene src` 0/0/0. No visual/aural verdict.

Item 119 COMPLETE (`season_r8_*` seasonal looks): NEW pure `ModelMapSeasonR8` (3 presets tied to Config.Seasons.sky, season-safe bands, 3 decor tint selectors, 6 hujan puddle sheets, DISTINCT_PCT=10/TARGET=2, PUDDLE_Y_FALLBACK=0.53, no IDs/engine API) + NEW CLIENT applier `LookDevSeasonR8` (3 keyed closures, LIFO restore of Lighting/Atmosphere/Clouds + tinted decor, exact puddle folder restore). New IDs 91-93, count literals 90->93, 3 client Review paths, 3 harness checks (`SEASON_SAFE`, `SEASON_RESTORE`, `SEASON_DISTINCT`), new spec, 3 CANDIDATES pending rows. TWO real bugs fixed with no check weakened: (1) first SERVER applier could not reach client-only Clouds -> converted to CLIENT applier; (2) MapSpec unreachable from Client VM -> documented PUDDLE_Y_FALLBACK=0.53. Real fresh-Play CLIENT-VM PASS `h/2026-11-21-round10/CHECK_119.txt` (SEEN-IN-STUDIO): SEASON_SAFE 3/3, SEASON_RESTORE 3/3, SEASON_DISTINCT 16>=2 (pairs 22/26/16), 14 props restored exactly, Cover 0.58/0.40/0.48 holds after 1s (Sky does not overwrite), hujan 6 sheets, synthetic out-of-range flagged, synthetic decor tint changed+restored exactly, lifecycle PASS. All existing checks byte-identical. Suite **2812 tests**, `selene src` 0/0/0. Candidates off by default; no new camera.

Item 118 COMPLETE (`crops_showcase_r8` crop review plots): NEW pure `ModelMapCropsShowcaseR8` (12 exact Config/Crops ids, 3 stages, 3 plots at MapSpec.LAPANGAN z 80/96/112, built-in tokens only, no IDs/engine API) + NEW server `LookDevCropsShowcaseR8` applier (3 stage Models + 36 crop Models from `CropModelCandidates.partsFor`, 306 original Parts, anchored/non-collidable, NO gameplay/crop-state writes, exact folder save/restore, diagnostics). New ID 90, count literals 89->90, review path, 1 harness check `CROPS_STAGED`, new spec, CANDIDATES pending row. 3 Server review cameras `crop_bibit`/`crop_tumbuh`/`crop_siap` in BOTH ReviewCameras.luau + REVIEW_CAMERAS.md (registry entries only, no in-game Camera; item 133 overlap noted as designer decision). Real fresh-Play PASS `h/2026-11-21-round10/CHECK_118.txt` (SEEN-IN-STUDIO): CROPS_STAGED 36 Models/3 plots/12 per stage/306 Parts/0 state objects, CAMERA_CLEAR 45 cameras/0 blocked incl. 3 new, synthetic destroyed-crop discriminated, disable/re-enable PASS; standalone verbatim `crop_growth_check.luau` re-run in fresh Client VM PASS `CHECK CROP_GROWTH PASS 12 12`, thresholds 0.5/6.0/15% untouched. All existing checks byte-identical. Suite **2798 tests**, `selene src` 0/0/0. Candidate off by default; no shipping default changed.

Item 117 COMPLETE (`seated_r8` seated villagers at Warung): NEW pure `ModelMapSeatedR8` (outfit KEYS only, exact R7 catalog IDs stay in ModelMapNpcsR7; 4 seat sites at bench front edge z=-56.65, 4 glasses + 4 plates, 8 probe parts, no engine API) + NEW server `LookDevSeatedR8` applier (real R15 rigs via `CreateHumanoidModelFromDescriptionAsync` + sync fallback, R7 HumanoidDescription recipe, `seat:Sit` + fallback + one bounded 0.2s re-assert, unanchored collidable rigs, exact save/restore, diagnostics). New ID 89, count literals 88->89, review path, 2 harness checks (`SEATED_COUNT`, `SEATED_ON_BENCH`), new spec, CANDIDATES pending row. Real fresh-Play Server-VM PASS `h/2026-11-21-round10/CHECK_117.txt` (SEEN-IN-STUDIO): SEATED_COUNT 4 real R15 rigs/4 Seats, all Sit=true after real 3s; SEATED_ON_BENCH 32 probes/0 hits; synthetic old-Z clip flagged; 4/4 props; disable/re-enable PASS. ONE real bug fixed: seats ON bench gave 8 lower-leg clips -> zLift 0.35->1.35 (front edge), thresholds/counts unchanged. Two pre-existing R7 catalog asset warnings noted, unrelated to checks. All existing checks byte-identical. Suite **2787 tests**, `selene src` 0/0/0. Candidate off by default; no new camera.

Item 116 COMPLETE (`layangan_r8` kites): NEW pure `ModelMapLayanganR8` (48 original Parts: kiteroot 4, spine 4,
spar 4, sail 16, tail 16, anchor 4; 4 textureless Beam strings; field centre 0,96, altitudes 64/72/80/88
in [60,90], no asset IDs/decals/brand) + NEW server `LookDevLayanganR8` applier (ONE shared Heartbeat
sine-rock loop, KiteAngle attr, Beams via ColorSequence/Width0/Width1 no Texture, diagnostics, exact folder
save/detach-restore). New ID 88, count literals 87->88, review path, 3 harness checks (`KITE_COUNT`,
`KITE_COST`, `KITE_STRING_CLEAR`), new spec, CANDIDATES pending row. Real fresh-Play Server-VM PASS
`h/2026-11-21-round10/CHECK_116.txt` (SEEN-IN-STUDIO): KITE_COUNT 4/4/4/1, STRING_CLEAR 4 rays/0 hits,
COST 0.149ms < 0.2, real rock, synthetic wall ray flagged, disable/re-enable PASS. TWO real Studio bugs
fixed (Beam FaceColor/Width invalid -> ColorSequence/Width0/Width1; 44-moving-part cost 0.254ms -> tail
static 28 move 0.149ms, limit/counts unchanged). All existing checks byte-identical. Suite **2777 tests**,
`selene src` 0/0/0. Candidate off by default; no shipping default changed. No new camera.

Item 115 COMPLETE (`laundry_r8` hanging laundry): NEW pure `ModelMapLaundryR8` (44 original Parts in 7 kinds:
post 8, line 4, sarung 4, batik 4, kebaya 4 — two washing lines/house behind pasar+gelap; hammock 10, tikar
10 — under each +Z porch; solid Wood/Fabric colours only, no asset IDs/decals/brand logos, behind/porch
site derivation, CLOTH_SWAY deliberately absent) + NEW server `LookDevLaundryR8` applier (anchored
non-collidable, live MapSpec.hub/hubPoint, exact folder save/detach-restore, no terrain edit, no animation).
New ID 87, count literals 86->87, review path, 2 harness checks (`LAUNDRY_PARTS`, `LAUNDRY_CLOTH_CLEAR`),
new spec, CANDIDATES pending row. Real fresh-Play Server-VM PASS `h/2026-11-21-round10/CHECK_115.txt`
(SEEN-IN-STUDIO): `LAUNDRY_PARTS` 44>=40 all counts match, `LAUNDRY_CLOTH_CLEAR` 0 wall hits / 12 cloths
probed / 9 wall parts / 2 hub Models, synthetic wall-overlap probe flagged, disable/re-enable PASS. All
existing checks byte-identical. Suite **2766 tests**, `selene src` 0/0/0. Candidate off by default; no
shipping default changed. No new camera.

Item 114 COMPLETE (`kincir_r8` water wheel): NEW pure `ModelMapKincirR8` (21 original Parts: wheelroot 1,
hub 1, axle 1, spoke 8, blade 8, support 2; DEG_PER_SEC=6; one bank site x=-68, nearest face 14 studs from
channel, clear of bridge; no asset IDs/invalid tokens) + NEW server `LookDevKincirR8` applier (ONE shared
Heartbeat loop turning all parts 6 deg/s, numeric WheelAngle attr, diagnostics wheelRoot/connectionCount/
isApplied/pump, exact folder save/detach-restore, no terrain edit). New ID 86, count literals 85->86,
review path, ONE harness check `KINCIR_ROT`, new spec, CANDIDATES pending row. Real fresh-Play Server-VM
PASS `h/2026-11-21-round10/CHECK_114.txt` (SEEN-IN-STUDIO): `KINCIR_ROT PASS 6.0000 3..9` with 1 folder/1
root/1 connection, real Heartbeat 6.0225 deg/1.024s, CFrame moves, disable removes all (0/0/0) and angle
stable across 1 s, re-enable yields fresh rotating wheel. All existing checks byte-identical. Suite
**2756 tests**, `selene src` 0/0/0. Candidate off by default; no shipping default changed. No new camera.

Item 113 COMPLETE (`irrigation_r8` irrigation and field life): NEW pure `ModelMapIrrigationR8` (50 original
Parts in 9 kinds: scarecpole 2, crossbar 2, shirt 10, head 2, hat 6 — two scarecrows; flume 12 + watersheet
2 — two bamboo channels; clapper 6; sheaf 8; terrace tops mirror MapSpec.TERRACES, water sheet tops =
terrace.top+0.25 <= 0.3, no asset IDs/invalid tokens) + NEW server `LookDevIrrigationR8` applier (anchored
non-collidable, Terrace attr, exact folder save/detach-restore, NO Terrain read/write). New ID 85, count
literals 84->85, review path, 2 harness checks, new spec, CANDIDATES pending row. Real fresh-Play
Server-VM PASS `h/2026-11-21-round10/CHECK_113.txt` (SEEN-IN-STUDIO): `IRRIGATION_PARTS` 50>=40 all counts
match, `IRRIGATION_WATER_ON_TERRACE` 0 failed / 2 sheets / worst delta 0.25 <= 0.3, synthetic violation
flagged, disable/re-enable PASS. `SAWAH_TOPS` READ-ONLY and byte-identical. Suite **2746 tests**,
`selene src` 0/0/0. Candidate off by default; no shipping default changed. No new camera.

Item 112 COMPLETE (`perahu_r8` boats and river life): NEW pure `ModelMapPerahuR8` (39 original Parts in
8 kinds: hull 6, gunwale 4, seat 4 — two perahu; netframe 4 + netmesh 6 — fishing net on poles;
stageplank 6 + stagepile 4 — bamboo landing stage; basket 5 — stack of baskets; river centreline mirror,
bank offset 18, channel half 14, no asset IDs/invalid material tokens) + NEW server `LookDevPerahuR8`
applier (anchored non-collidable tagged Parts, exact folder detach/restore, no terrain edit). New ID 84,
count literals 83->84, review path, 2 harness checks, new spec, CANDIDATES pending row. Real fresh-Play
Server-VM PASS `h/2026-11-21-round10/CHECK_112.txt` (SEEN-IN-STUDIO): `PERAHU_PARTS` 39>=35 all counts
match, `PERAHU_RIVER_CLEAR` 0/39 overlaps within the 56-stud [-28,28] bridge crossing, 0 global channel
hits, synthetic violating box correctly flagged (non-vacuous), disable/re-enable PASS. `BRIDGE_WALKABLE`
READ-ONLY and byte-identical. Suite **2736 tests**, `selene src` 0/0/0. Candidate off by default; no
shipping default changed. No new camera.

Item 111 COMPLETE (`lumbung_r8` lumbung and pekarangan): NEW pure `ModelMapLumbungR8` (90 original Parts
in 12 kinds: 6-stilt barn, tiered thatch roof, door+ladder+vents, plus fence/toga/chilli/drying-mat/rake
kit at pasar/gelap/pakrt, MapSpec.hub/hubPoint derived, no asset IDs) + 1 invisible door gauge + NEW
server `LookDevLumbungR8` applier (anchored non-collidable, Ground voxel yard pads snapshotted with
ReadVoxels and restored byte-exact LIFO via WriteVoxels, folder save/detach-restore). New ID 83, count
literals 82->83, review path, 3 harness checks, new spec, CANDIDATES pending row. Real fresh-Play
Server-VM PASS `h/2026-11-21-round10/CHECK_111.txt` (SEEN-IN-STUDIO): `LUMBUNG_PARTS` 90>=80 all counts
match, `LUMBUNG_DOOR_CLEAR` gauge dims/pose/API OK 0 collidable hits (`-LookVector` radial),
`LUMBUNG_PROPS_ON_GRASS` 0/24 grassy over 3 exact yards, Ground pads changed then restored byte-exact
LIFO, PFS yard+spawn routes PASS, disable/re-enable PASS. One real error fixed, not hidden: stale
`Leaf` material token (6 toga leaves failed to stage -> `Plastic`, spec guard; shared allowlist left
intact because other modules use Leaf). Suite **2727 tests**, `selene src` 0/0/0. Candidate off by
default; no shipping default changed. No new camera.

Item 110 COMPLETE (`musala_r8` small prayer house): NEW pure `ModelMapMusalaR8` (49 original Parts
plus 1 invisible door gauge: walls, green RGB tiered roof, pengeras suara horn, wudhu tap area, shoe
rack; MapSpec.ROAD site r 120 @ 30deg -> (60,103.92), yaw 30, door radial-out toward ring, no terrain
edit/asset IDs) + NEW server `LookDevMusalaR8` applier (anchored, non-collidable, save/detach/restore).
New ID 82, 38 count literals 81->82, review path, 3 harness checks, new spec. CANDIDATES verdict
exactly `needs designer review: cultural content`. Real fresh-Play Server-VM PASS
`h/2026-11-21-round10/CHECK_110.txt` (SEEN-IN-STUDIO): `MUSALA_PARTS` 49>=25,
`MUSALA_DOOR_CLEAR` gauge dims/pose/API OK with 0 collidable hits, `MUSALA_PATH_REACH` 0/50 overlaps
in site-local frame, PFS spawn->approach->door routes PASS, disable/re-enable PASS. Three real errors
fixed, none hidden: stale `Painted` material token (13 parts failed to stage -> `Plastic`, allowlist
entry removed, spec guard); harness LookVector sign (local -Z); world-AABB false positives on the
rotated kit (lane measured site-local). Suite **2718 tests**, `selene src` 0/0/0. Candidate off by
default; no shipping default changed. Designer verdict still pending by item design.

Item 109 COMPLETE (`pasar_ground_r8` Pasar ground): NEW pure `ModelMapPasarGroundR8` (94 original
Parts: 40 Cobblestone paving, 36 Slate cobble, 18 drainage gutters; MapSpec.hub("pasar")-local
offsets via hubPoint, no terrain edit, no asset IDs) + NEW server `LookDevPasarGroundR8` applier
(anchored, non-collidable, save/detach/restore). Slab bottoms sit on GROUND_Y, `PAVING_TOL=0.15` on
the bbox bottom face. New ID 81, 37 spec count literals 80->81, review path, 2 harness checks, new
spec. Real fresh-Play Server-VM PASS `h/2026-11-21-round10/CHECK_109.txt` (SEEN-IN-STUDIO):
`PASAR_PAVING` 76>=60, slab bottoms on GROUND_Y (max delta 0.0000), `PASAR_GROUND_LANE_CLEAR` 0
overlaps over a 6.0-stud lane (94 tagged parts tested, non-vacuous), PFS lane-crossing route PASS,
disable/re-enable PASS. Distinct name `PASAR_GROUND_LANE_CLEAR` used — item 148 owns bare
`LANE_CLEAR`; that check untouched. Suite **2710 tests**, `selene src` 0/0/0. Candidate off by
default; no shipping default changed.

Item 108 COMPLETE (`lapangan_r8` village field): NEW pure `ModelMapLapanganR8` (54 original Parts:
2 goals, red-white flagpole, 4 benches, 24 boundary stones, 5 sand patches; MapSpec.LAPANGAN-local
offsets, outside the RoadSouth corridor) + NEW server `LookDevLapanganR8` applier (anchored,
non-collidable, save/detach/restore). Goal sizing documented in-module: AVATAR_HEIGHT 7.25 x
GOAL_RATIO 2.2 = GOAL_HEIGHT 15.95 studs. New ID 80, 36 spec count literals 79->80, review path,
3 harness checks, new spec. Real fresh-Play Server-VM PASS `h/2026-11-21-round10/CHECK_108.txt`
(SEEN-IN-STUDIO): `LAPANGAN_PARTS` per-kind counts match, `LAPANGAN_PATH_REACH` 0/5 blocked,
`LAPANGAN_GOAL_SIZE` 15.94~15.95 (2 goals), PFS field-edge routes 4/4, restore/re-enable PASS,
anti-vacuity 54 parts/5 corridors/2 goals. Suite **2702 tests**, `selene src` 0/0/0. Candidate off
by default; no shipping default changed.

Item 107 COMPLETE (clean-Play smoke): `tools/studio/smoke_play.luau` NEW — `ORDER`/`emit`/`byName`
harness with a 5-entry reason-tagged allowlist and no info-ignored bucket; main session feeds
`get_console_output` lines via `_G.SMOKE_CONSOLE_LINES` (Luau cannot call the MCP tool). Two fresh-Play
60 s windows, `h/2026-11-21-round10/CHECK_107.txt` (SEEN-IN-STUDIO): default look and full_r9 staged
13/13, both `CHECK SMOKE_CLEAN PASS 0 0` (8 known-noise lines, 0 violations). Real error found and
FIXED, not allowlisted: `LookDevSmokeR8.luau:77-78` used `NumberSequence.new` for ParticleEmitter
`Lifetime`/`Speed` (need `NumberRange`) -> 9 build warnings per full_r9 stage; now `NumberRange.new`,
spec-guarded. Allowlist scope + the fix under WORK_QUEUE "Decisions for designer". Suite
**2693 tests** (+1 NumberRange guard, +5 smoke_play harness guards); `selene src` 0/0/0.

Item 106 BLOCKED (`CHECK AVATAR_FIT FAIL 2 16`, `h/2026-11-21-round10/CHECK_106.txt`): the 4x7.25x4
avatar box swept along item 105's 16 routes hit CanCollide parts on 14/16 routes (attempt 2 with a
>0.1-stud penetration filter: 13/16). The IDENTICAL hit set with NOTHING staged proves every blocker
is pre-existing shipping geometry (`RumahPakRT` walls, `Plot_4.SignPost`, `kit_fence`, house
Floor/Desk/Table, NPC UpperTorso) — 0 of 35,949 staged lookdev parts are collidable, so there is no
blocking candidate to move/shrink, and re-scoping to staged-only would weaken + vacate the check.
Two FAILs -> BLOCKED; no part changed, no check weakened, no default look touched. Corrected-gauge
follow-up and shipping-world clearance under WORK_QUEUE "Decisions for designer". Suite unchanged
**2687 tests**, `selene src` 0/0/0.

**Long-run 2026-11-20 — WORK_QUEUE section K items 53–60 COMPLETE (round 7, hard Studio PASS
ticking):** item 53 check harness `tools/studio/review_check_r7.luau` runs in the real Play Server VM
and prints exactly eight `CHECK <name> PASS|FAIL <measured> <target>` lines; documented in
`h/2026-11-20-round7/REVIEW_ROUND7.md`. Item 54 Route A Open Cloud asset-delivery refused (HTTP 403
`Scope not authorized`), so Route B Edit-mode `game:GetObjects` bake to
`ServerStorage.LookDevAssets` was used; all model appliers clone first with `LoadAsset` fallback.
Item 55 promoted sky E (`rbxassetid://2835177931`) + spawn ground R6 as shipping defaults; terrain
R6 a/b stay rejected; remaining sky/terrain candidates OFF. Item 56 `npcs_r7` hats + four real R7
costume Image IDs uploaded via Open Cloud (`shirt_pak_rt` 92996938301042, `shirt_polisi`
133590758790821, `pants_polisi` 98235919851901, `shirt_petani` 81581201405716; recorded in
`models_r7/npcs/upload_manifest.json` and `ASSET_MANIFEST.md`), designer PASS on PNGs + 2×2 sheet.
Item 57 `props_r7` restaged to a clear 40×40 yard; camera `front` 18→28 to keep all six inside the
70° cone (harness unchanged). Item 58 `vegetation_r7` 88 slots / 11 species with 20 added far-band
cells; self-check min pair distance tightened 1.2→2. All eight checks PASS in real Studio:
`LOAD_FAILURES 0 0`, `SKY_DEFAULT rbxassetid://2835177931`, `GRASS_ON_BEDS 0 0`, `HATS 4 4`,
`PROPS_VISIBLE 6 6`, `PROPS_ON_GRASS 0 0`, `VEG_COUNT 67 60`, `VEG_SPECIES 10 8`; raw output in
`CHECK_53.txt`…`CHECK_58.txt` and `ATTEMPT2_console_raw.txt` under `h/2026-11-20-round7/`. Item 59
review handoff written. Item 60 refill re-read `BUGS.md` / `GATE1.md`: no open blocker/major, Gate 1
unchanged (G4/Q5 BLOCKED, Q8 LUNE-ONLY, 8 UNVERIFIED), no agent-closable row, nothing new queued.
Final suite 2340 passing; `selene src` 0 errors / 0 warnings / 0 parse errors. `LookDev.IDS` = 46.
All three r7 candidates remain OFF by default with no visual graded by an agent; no place saved or
published.

**Long-run 2026-11-21 — WORK_QUEUE section M item 68–69 COMPLETE (round 9, M1 tools):** item 68
created `tools/studio/review_check_r8.luau` — the r7 CHECK-line helpers plus a mutating
`LOOKDEV_LEAK` check that enable/disables every `LookDev.IDS` entry and requires workspace and
Lighting descendant counts to return unchanged. In a clean real-Studio Play (no candidate staged,
34 bake folders, 46 ids) it emitted `CHECK LOOKDEV_LEAK PASS 0 leaks 0 leaks`
(`h/2026-11-21-round9/CHECK_68.txt`). First run reported 2 false leaks because candidates had been
direct-staged by the round-8 session; the sweep now runs in a fresh Play, documented in
`REVIEW_ROUND9.md`. Item 69 created `src/shared/ReviewCameras.luau` + `docs/v2/visual/REVIEW_CAMERAS.md`
with 26 cameras derived from MapSpec (spawn, six hubs, ten plot gates, both bridge banks, sawah
below/above, hill ring, four lighting variants). Added the SERVER-ONLY `CAMERA_CLEAR` check to the r8
harness; real Studio measured `CHECK CAMERA_CLEAR PASS 0 blocked/26 checked 0 blocked`
(`CHECK_69.txt`). The `asVector3` helper was fixed to accept the module's array-style Vec3 (was the
only cause of the first 26/26 "bad coords" FAIL); no camera or check was weakened. No place saved or
published.

**Long-run 2026-11-21 — WORK_QUEUE section M item 70 COMPLETE (round 9, M2):** `hubveg_r8`
per-hub vegetation dressing landed OFF by default as candidate 47 (`LookDev.IDS`), wired through
`LookDevReview` (server path) and booted from `Main.server.luau`. Pure data
(`Shared.ModelMapVegetationHubR8`) derives 16 deterministic slots per hub from `MapSpec.HUB_ORDER`
with a seeded polar generator; all IDs come from the verified R7 map. Real Studio Play (fresh, no
direct-staged candidates, 34 bake folders, 47 ids) staged 96 models with 0 load failures and
measured `CHECK VEG_HUB_<hub> PASS 16 >=12` for all six hubs, `CHECK VEG_SPECIES_HUB PASS min=9
>=4 each`, `CHECK VEG_OVERLAP PASS 0 0`, `CHECK CAMERA_CLEAR PASS 0 blocked/26 checked`, `CHECK
LOOKDEV_LEAK PASS 0 leaks` (`h/2026-11-21-round9/CHECK_70.txt`). Three earlier `VEG_OVERLAP` FAILs
(20 → 7 → 7) were fixed in the data (per-species footprints from measured bbox; mangga/pisang
dropped), the harness (single BasePart bbox reading) and the applier (place by measured bbox centre,
kembang sepatu pivot offset up to 32.73 studs) — never by weakening a target. Final suite 2365
passing, `selene src` 0/0/0. No place saved or published; visual grading is the designer's.

**Long-run 2026-11-21 — WORK_QUEUE section M item 71 COMPLETE (round 9, M2):** `plots_r8`
procedural plot fences and gate arches landed OFF by default as candidate 48. Pure data
(`Shared.ModelMapPlotsR8`) derives 8 fence segments per plot with a 6-stud gate gap on the inner
(-Z) edge and 0.2-stud neighbour overlap; the server applier reads each real `Plot_<i>` CFrame
(designer PlotAnchor overrides) and builds 10 × (8 fence + 2 posts + lintel + invisible marker)
anchored, non-collidable Parts with no asset IDs. Real Studio Play (fresh, only plots_r8 staged,
48 ids) measured `CHECK PLOT_FENCE PASS min=8 (P1..P10:8) >=6 each`, `CHECK GATE_CLEAR PASS 0
hits/10 gates 0`, `CHECK LOAD_FAILURES PASS 0 0`, `CHECK CAMERA_CLEAR PASS 0 blocked/26 checked`,
`CHECK LOOKDEV_LEAK PASS 0 leaks` (`h/2026-11-21-round9/CHECK_71.txt`). The first GATE_CLEAR FAIL
(18 hits) was a check-geometry defect — the box was world-aligned and centred at ground, hitting
GroundNorth and rotated plots' Base/SignPost; the check now uses the marker's own yaw frame lifted
8/2+0.05 above ground, with the 6x8x1 target and zero-hit condition unchanged. Final suite 2372
passing, `selene src` 0/0/0. No place saved or published; visual grading is the designer's.

**Long-run 2026-11-21 — WORK_QUEUE section M item 72 COMPLETE (round 9, M2):** `sawah_r8`
terrace dressing landed OFF by default as candidate 49. Pure data (`Shared.ModelMapSawahR8`) derives
four water sheets (two `MapSpec.paddyWater()` panes each), 80 deterministic alang-alang tufts on the
bunds (three blades each = 240 Parts), one terrace-2 gubuk (four posts + thatch roof + bench) and
three stepping stones; the server applier stages tagged, anchored, non-collidable Parts with no asset
IDs and never touches Terrain, greybox, padi rows or terrace tops. Real Studio Play (fresh, only
sawah_r8 staged, 49 ids) measured `CHECK SAWAH_TOPS PASS 0 0.5` (8 Terrain-only raycasts, top diff 0),
`CHECK SAWAH_WATER PASS 4 4 sheets` (transparency 0.55, muddy green-brown, panes in terrace bands),
`CHECK SAWAH_VERGE PASS 240 >=40`, `CHECK GUBUK PASS 1 1` (terrace 2, 4 posts + 1 bench on the same
id), `CHECK LOAD_FAILURES PASS 0 0`, `CHECK CAMERA_CLEAR PASS 0 blocked/26 checked`, `CHECK
LOOKDEV_LEAK PASS 0 leaks` (`h/2026-11-21-round9/CHECK_72.txt`). All four item checks PASS on the
first run — no target weakened, no place saved. Final suite 2380 passing, `selene src` 0/0/0.
Visual grading is the designer's.

**Long-run 2026-11-21 — WORK_QUEUE section M item 77 COMPLETE (round 9, M3):** `buildings_r8`
six real free Creator Store Indonesian buildings landed OFF by default as candidate 55, wired
through `LookDevReview` (server path) and booted from `Main.server.luau`. Edit-mode `GetObjects`
bake to `ServerStorage.LookDevAssets` (scripts stripped) supplied the six models; pure data
(`Shared.ModelMapBuildingsR8`) records verified IDs/licences/scales, a 20-stud CLEAR-GAP row, a
340x80 model-free site scan and a signed-Z review camera (min-Z/facade side, 228 out, 60 up).
`rumah_joglo` (id 4820552419) is scaled 0.75 so its staged width is 57.65 (native 76.87 broke the
12..60 band). The applier parents each model into the staged folder before the rotation-aware
`GetPartsInPart` door-gauge search; the harness BLDG_DOOR test uses the same oriented-geometry
method (world AABB false-positived on rotated roof panels). Real Studio Play in the SERVER VM
(fresh, 55 ids, 41 baked folders) measured `CHECK BLDG_VISIBLE PASS 6 6`, `CHECK BLDG_WIDTH PASS
6 6`, `CHECK BLDG_DOOR PASS 6 6`, plus `CHECK LOAD_FAILURES PASS 0 0`, `CHECK LOOKDEV_LEAK PASS 0
leaks` and `CHECK CAMERA_CLEAR PASS 0 blocked/26 checked`; no place saved
(`h/2026-11-21-round9/CHECK_77.txt`). Two honest FAIL attempts (centre-spacing occlusion 4/6;
unparented gauge search 3/6) were fixed in code/check correctness, never by weakening a target.
Final suite 2412 passing, `selene src` 0/0/0. Visual grading is the designer's.

**Long-run 2026-11-21 — WORK_QUEUE section M item 78 COMPLETE (round 9, M3):** `facades_r8`
procedural hub facade details landed OFF by default as candidate 56, wired through `LookDevReview`
(server path) and booted from `Main.server.luau`. Pure data (`Shared.ModelMapFacadesR8`) gives each
of the six Greybox hubs ten decorative recipes spanning shuttered windows, porch roofs, ridge caps,
lantern brackets, doorsteps and eaves, plus an explicit avatar-fit door gauge (7 x 10.5 x 2 for
pakrt, 6 x 9 x 2 for the other five) in each open local +Z front. The server applier places every
piece in the live `MapSpec.hub(key)` frame, stages them anchored, non-collidable and WeldConstraint-
tagged, and destroys the whole folder on disable; no shipping Greybox part is edited and no asset
ID is used. The new harness checks use all-six-kinds counting and the same rotation-aware
`GetPartsInPart` door probe as BLDG_DOOR. Real Studio Play in the SERVER VM (fresh, 56 ids, 41
baked folders) measured `CHECK FACADE_PARTS PASS 6 6`, `CHECK DOOR_CLEAR PASS 6 6`, plus `CHECK
LOAD_FAILURES PASS 0 0`, `CHECK LOOKDEV_LEAK PASS 0 leaks` and `CHECK CAMERA_CLEAR PASS 0
blocked/26 checked`; no place saved (`h/2026-11-21-round9/CHECK_78.txt`). Both item checks PASS on
the first run after runtime-only module injection — no target weakened, no skip. Eleven older specs
had their ID-count assertions bumped 55→56 (indices unchanged). Final suite 2422 passing,
`selene src` 0/0/0. Visual grading is the designer's.

**Long-run 2026-11-21 — WORK_QUEUE section M item 79 COMPLETE (round 9, M3):** `hubprops_r8`
six-hub vernacular props landed OFF by default as candidate 57 (`LookDev.IDS[57]`), wired through
`LookDevReview` (server path) and booted from `Main.server.luau`. Pure data
(`Shared.ModelMapHubPropsR8`) gives 47 props across the six Greybox hubs (pasar 9, gelap 6, warung
9, ronda 7, polisi 8, pakrt 8), each 6–10, using the asset ladder: verified baked IDs (karung,
gerobak, lapak, jemuran, bale bambu, sumur, motor 106061905410704), the step-(2) agent-generated
`BambooBasket` (generationId 14b48661-4c08-425f-ab3f-c641c1a885fd, recorded in `ASSET_MANIFEST.md`)
and procedural Roblox parts — no invented IDs. Applier stages in each live `MapSpec.hub(key)` frame,
snapshots/restores Terrain pads LIFO with `ReadVoxels`/`WriteVoxels` (grass check forces GRASS_Y=4),
and destroys the folder on disable. Ronda props use explicit tree-free, gauge-clear slots after Studio
showed the regular `at()` row hid three props behind `Tree_12`; the Lune 2D unmasked self-check and
the Studio raycast both pass with the final slots. Real Studio Play (fresh, full module re-injection,
only hubprops_r8 staged, 43 baked folders) measured `CHECK HUBPROPS_VISIBLE PASS 6 5` (per-hub
pasar 9, ronda 7, polisi 8, warung 9, pakrt 8, gelap 6), `CHECK HUBPROPS_ON_GRASS PASS 0 0`, plus
`CHECK LOAD_FAILURES PASS 0 0`, `CHECK LOOKDEV_LEAK PASS 0 leaks 0 leaks` and `CHECK CAMERA_CLEAR
PASS 0 blocked/26 checked`; no place saved (`h/2026-11-21-round9/CHECK_79.txt`). No target weakened,
no skip. Final suite 2441 passing, `selene src` 0/0/0. Visual grading is the designer's.

**Long-run 2026-11-21 — WORK_QUEUE section O item 136 COMPLETE (round 9, O1 tools):** additive
review staging. `LookDev` gained `enableAdditive(id, opts)` (same candidate + studio gate as enable,
idempotent, never touches `enabledId` or restores another candidate), `disableAll()` (restores all
additive ids in reverse order plus the single enabled one, repeatable) and a read-only `additiveIds()`
accessor; `LookDevReview` gained `enableAdditive(id, root, opts)` and `disableAll()`. Existing
`enable`/`disable`/`current` are byte-for-byte unchanged. New pure spec `lookdev_additive_spec.luau`
locks all five cases. Real Studio Play (SERVER VM, fresh, 43 bake folders) measured `CHECK
ADDITIVE_STAGE PASS 3 3` — hubveg_r8 (96 tagged models), plots_r8 (120 tagged parts) and facades_r8
(60 tagged parts) all staged simultaneously with no disable between them, 0 leaked after
`disableAll()` — plus `CHECK LOOKDEV_LEAK PASS 0 leaks 0 leaks`, `CHECK LOAD_FAILURES PASS 0 0` and
`CHECK CAMERA_CLEAR PASS 0 blocked/26 checked`; no place saved (`h/2026-11-21-round9/CHECK_136.txt`).
No target weakened, no skip. Final suite 2446 passing, `selene src` 0/0/0.

**Long-run 2026-11-21 — WORK_QUEUE section O item 137 COMPLETE (round 9, O1):** `water_r8_a`
promoted to the shipping client default. New `src/client/World/Water.luau` writes variant A's five
Terrain water properties at boot via `Water.mount()` (called from `Main.client` right after
`Sky.mount`, guarded), with NO LookDev enable call and independent of the candidate appliers so their
save/restore round-trips stay intact. `Water.defaultValues()` is a pure copy of A's values. New read-
only CLIENT harness check `WATER_DEFAULT` compares all five live Terrain readings to A with NO
candidate enabled. Real Studio Play (fresh, no enable) measured `CHECK WATER_DEFAULT PASS 5 5`
(readings WaterColor=(48,124,104) / 0.28 / 0.35 / 0.42 / 0.9, 0 mismatches), `CHECK WATER_SAFE PASS
3 3`, `CHECK WATER_RESTORE PASS 3 3` (b round-trip still exact against the promoted baseline) and
`CHECK LOAD_FAILURES PASS 0 0`; no place saved (`h/2026-11-21-round9/CHECK_137.txt`). `CANDIDATES.md`
marks a promoted, b the rain-season reference, c rejected. No target weakened, no skip. Final suite
2451 passing, `selene src` 0/0/0.

**Long-run 2026-11-21 — WORK_QUEUE section M item 76 COMPLETE (round 9, M3):** `water_r8_a/b/c`\nriver water looks landed OFF by default as client candidates 52–54. Pure data\n(`Shared.ModelMapWaterR8`) defines the five Terrain water properties, documented safe ranges\n(WaterColor R/G/B 0..255; Transparency 0.05..0.75; Reflectance 0..0.6; WaveSize 0..1; WaveSpeed\n-2..2), and three distinct palettes (clear tropical green, murky brown after rain, bright\nturquoise). The client applier (`Client.World.LookDevWaterR8`, one make() factory) pcall-guards\nevery read/write and saves/restores all five prior values exactly; no Part, no Instance and no\nasset ID is created. Real Studio Play in the CLIENT VM (fresh, 54 ids) measured `CHECK WATER_SAFE\nPASS 3 3` (all 15 property readings inside their bands, failures/errors empty) and `CHECK\nWATER_RESTORE PASS 3 3` (all five properties matched the baseline exactly after each disable,\nincluding the out-of-band default Reflectance=1 / WaveSpeed=10), plus `CHECK LOAD_FAILURES PASS\n0 0` and `CHECK LOOKDEV_LEAK PASS 0 leaks`; post-run current=nil and Terrain read back verbatim —\nno net change (`h/2026-11-21-round9/CHECK_76.txt`). CAMERA_CLEAR is Server-only and absent by\ndesign in the Client run. Both item checks PASS on the first run — no target weakened, no place\nsaved. Final suite 2400 passing, `selene src` 0/0/0. Visual grading is the designer's.\n\n**Long-run 2026-11-21 — WORK_QUEUE section M item 75 COMPLETE (round 9, M2):** `pathedge_r8`
dirt-path borders landed OFF by default as candidate 51. Pure data (`Shared.ModelMapPathEdgeR8`)
derives deterministic jittered placements on both edges of every real `MapSpec` path family (4
axis-aligned road arms, 56 rotated ring segments, 2 continuations), cycling grass tufts and pebbles
with ~1-in-10 flat puddles at Transparency 0.4; the server applier stages tagged, anchored,
non-collidable Parts with no asset IDs and never touches Terrain, road slabs, RoadEdge strips or
buildings. Real Studio Play (fresh, only pathedge_r8 staged, 51 ids) measured `CHECK PATH_EDGE PASS
618 >=120` (309 tufts / 283 pebbles / 26 puddles) and `CHECK PATH_CLEAR PASS 0 0` (0 intruders in
the central 6 studs of any of 62 paths, minimum candidate offset 3.81 > 3), plus `CHECK
LOAD_FAILURES PASS 0 0`, `CHECK CAMERA_CLEAR PASS 0 blocked/26 checked`, `CHECK LOOKDEV_LEAK PASS 0
leaks` (`h/2026-11-21-round9/CHECK_75.txt`). Both item checks PASS on the first run — no target
weakened, no place saved. Final suite 2393 passing, `selene src` 0/0/0. Visual grading is the
designer's.

**Long-run 2026-11-21 — WORK_QUEUE section M item 74 BLOCKED (round 9):** `ring_r8` hills and
forest ring could not tick: `NO_PINES` requires 0 pine-named instances workspace-wide and runs in
the default look, but the shipping `BackgroundForest` (`Greybox.buildForestRing`) already contains
254 pines. Two clean default-look Play attempts both measured `CHECK NO_PINES FAIL 254 0`
(`h/2026-11-21-round9/CHECK_74.txt`); the check was not weakened. No OFF-by-default candidate can
change a no-candidate default-look run; reaching 0 requires a shipping default-look forest
replacement reserved for designer visual grading. Logged under WORK_QUEUE "Decisions for designer"
(scope: authorize V-D4 default-look replacement vs re-scope the item to the additive ±400 band).
Item stays unchecked/BLOCKED; the long run continues with item 75. No place saved.

**Long-run 2026-11-21 — WORK_QUEUE section M item 73 COMPLETE (round 9, M2):** `river_r8` river
banks and bridge dressing landed OFF by default as candidate 50. Pure data (`Shared.ModelMapRiverR8`)
derives deterministic vegetation on both bank shelves from the real `MapSpec.riverCentreZ`, a rail
layout whose inner faces sit at |x|=4 (8-stud clear deck), and six stepping stones; the server
applier stages tagged, anchored, non-collidable Parts with no asset IDs and never touches Terrain,
the greybox bridge/rails, the ford or padi rows. Real Studio Play (fresh, only river_r8 staged, 50
ids) measured `CHECK RIVER_BANK_VEG PASS 56 >=30` (28 per bank within 40 studs), `CHECK
BRIDGE_RAILS PASS 2 2` (one deck-spanning rail + 8 posts per side), `CHECK BRIDGE_WALKABLE PASS 8
>=8` (inner faces ±4, no offenders), `CHECK LOAD_FAILURES PASS 0 0`, `CHECK CAMERA_CLEAR PASS 0
blocked/26 checked`, `CHECK LOOKDEV_LEAK PASS 0 leaks` (`h/2026-11-21-round9/CHECK_73.txt`). All
three item checks PASS on the first run — no target weakened, no place saved. Final suite 2387
passing (incl. the new Enum.Material validity spec), `selene src` 0/0/0. Visual grading is the
designer's.

**Long-run 2026-11-21 — WORK_QUEUE section L items 61–67 COMPLETE (round 8, hard Studio PASS
ticking):** item 61 clear-day cloud cover — the day-cycle preset `cloudCover` was corrected in
`src/shared/Config/Seasons.luau` and `src/shared/World/DayCycle.luau` (clear base 0.5, hujan 0.55,
badai 1.0 overlays kept), and a client-only `CLOUD_COVER` check was added to
`tools/studio/review_check_r7.luau` → `CHECK CLOUD_COVER PASS 0.500@ct13.00 0.4-0.6` in a fresh
Client Play at ClockTime 13 (`CHECK_61.txt`). Item 62 flower beds — `ShippingLookR7` now repaints
Ground voxels at grade with `ReadVoxels`/`WriteVoxels`, preserving occupancy and adding no volume →
`GRASS_ON_BEDS PASS 0 0`, `BED_FLUSH PASS 0 0.5` (`CHECK_62.txt`). Item 63 near vegetation — a
`vegetation_r7_near_bed` layer plus six well-behaved NEAR_PLAN slots (bambu/mangga/pisang) survives
real baked-model bbox drift; VEG_NEAR first measured 21 in-cone instances (FAIL), fixed to 27 / 7
species / 0 small with the Sedang budget 120/120 and the check unweakened → `VEG_COUNT PASS 94 60`,
`VEG_SPECIES PASS 10 8`, `VEG_NEAR PASS 27 inst/7 sp/0 small` (`CHECK_63.txt`). Item 64 props —
R7-only overrides to real catalog models (cangkul `4951145641`, gerobak `10506531785`, bamboo pagar
`85094565897097`; IDs in `ASSET_MANIFEST.md` and the bake list), R4/R5/R6 maps unchanged →
`PROPS_VISIBLE PASS 6 6`, `PROPS_ON_GRASS PASS 0 0`, `PROP_SIZE PASS g=4.99 c=4.00 p=8.54`
(`CHECK_64.txt`). Item 65 no-save process fix recorded in
`h/2026-11-21-round8/PROCESS_FIX_NO_SAVE.md`; item 66 handoff in
`h/2026-11-21-round8/REVIEW_ROUND8.md` with bake, toggles, datamodels and review cameras; item 67
no-op. Three new Lune regressions registered (`cloud_cover_spec`, `veg_near_spec`,
`props_r8_ids_spec`); final suite 2357 passing, `selene src` 0 errors / 0 warnings / 0 parse errors.
All four review cameras are recorded but no shot files were produced (screen capture could not
persist image data; the Studio capture subagent timed out), so the four visual verdicts remain OPEN
for the designer; the CHECK_* evidence is objective, not a visual verdict. No place saved or
published, NPC outfits untouched.

**Long-run 2026-11-20 — WORK_QUEUE section J items 47–52 COMPLETE (atomic commit, serialized
registry):** item 47 `vegetation_r6` — pure data + server applier, 102 slots / 42 staged in the saved
camera band, R4 IDs via require plus five proven shortlist IDs, tier budgets and exclusion zones;
`LookDev.IDS` 40→41. Item 48 `npcs_r6` — five R15 villagers, ten real costume Image IDs from
`models_r6/npcs/upload_manifest.json` applied to Shirt/Pants siblings (Route B; HumanoidDescription
rejects Image IDs), multi-strategy hat attacher and a ~180° facing flip. Item 49 DesignerKit —
`ServerStorage.DesignerKit` via manual `build()`/`clear()`, 17 Indonesian-named drag-source items
resolved from source maps, `DESIGNER_KIT.md` + advice-only `TERRAIN_BRIEF.md`; no spawn dressing, no
LookDev registration. Item 50 `props_r6` — seven reused R4 IDs, `Model:ScaleTo` from actual
`GetBoundingBox` (gerobak ~6 tall/8 long, sumur 4.5, cangkul 4.5), saved camera moved +12 in X clear
of the pines. Item 51 `REVIEW_ROUND6.md` — all twelve round-6 toggles, datamodels and saved cameras
with blank verdicts; Studio shots belong to the designer. Main session serialized the registry 41→43,
wired the review paths / bootstrap / three previously unwired specs and bumped every count assertion.
Item 52 refill re-read this tracker, `WORK_QUEUE.md`, `BUGS.md` and `GATE1.md`: Gate 1 unchanged at
2 `BLOCKED` (G4, Q5), 1 `LUNE-ONLY` (Q8), 8 `UNVERIFIED`, no open `blocker`/`major` bug and no
agent-closable row. Final suite 2332 passing; `selene src` 0/0/0; focused stylua and
`git diff --check` clean. All twelve round-6 candidates remain off by default with blank verdicts;
no place saved or published.

**Previous update (2026-11-20, round-3 verdicts / section H queued):** designer verdicts on round 3 recorded (icons_r3 and day_cycle yes; corner and the four r3 model families no; textures_r3 and sky_r3 retest); WORK_QUEUE section H (round 4, items 28–34: bug fixes plus free online textures, HDRIs and models) queued; toggle docs now use `LookDev.enable`. Tests: 2101 passing. Earlier the same day: WORK_QUEUE section G items 20–27
complete (`LUNE-ONLY` for the code/spec gates; one server-only `LoadAsset` probe was `SEEN-IN-STUDIO`
in Edit and Play-Solo Server VMs, place never saved or published). The `ROBLOX_API_KEY` Open Cloud
route was verified on a real texture (HTTP 200) and used for every later upload; the key was never
printed, logged or committed. Section G integrated 27 real CC0 Poly Haven PBR maps (`textures_r3`),
27 original r3 icons (`icons_r3`), 20 CC0 / designer-build models in four server-side families
(`buildings_r3`, `vegetation_r3`, `props_r3`, `npcs_r3`), six CC0 HDRI cube faces (`sky_r3`) and the
`day_cycle` code half (five silent beds, `id = 0`, no invented sound ID). Central registry now has
17 off-by-default LookDev candidates; IDs live only in shared maps and the ASSET_MANIFEST. Client
`InsertService:LoadAsset` was proven blocked, so model appliers are server-side only.
`docs/v2/visual/REVIEW_ROUND3.md` lists the review order, Server-datamodel rule and saved cameras;
all verdicts are blank and no agent graded any visual. Item 27 re-checked items 12/14/15/16: all
remain `BLOCKED` on designer/vision verdicts, licensed VFX assets and hardware, with their reasons
updated. `lune run tests/run.luau`: 2101 passing; `selene src`: 0 errors / 0 warnings / 0 parse
errors; `stylua`: clean on all touched Luau.

**Previous update (2026-11-19):** branch `track/c-world-look` — designer one-pager delivered at `docs/testing/DESIGNER_GATE1.md` (six open Gate 1 rows, execution `BLOCKED` on designer/hardware) — `lune run tests/run.luau`: 2056 passing (round-3 item 2 added a 21-part corner LookDev candidate + 6-case spec; round-3 item 10a added a 15-case pure day-cycle spec; round-3 item 0a added a 10-case published-place Q6 admin capture/compare spec; round-2 item 23 added an 8-case Q6 persistence comparator spec and a gated Studio rehearsal driver; item 22 added a 12-case Q5 multi-client comparator spec and a gated Studio driver; item 20 moved 12 pure modules to `--!strict` and fixed 33 real LSP errors with type-only casts; item 19 fixed BUG-019 damaged dynamic tile numerics and added 3 farm-failure cases; item 18 added a 4-case client error-boundary spec that boots the real Main.client with forced UI/feel throws; item 17 added a 3-case 8-hour economy sim (optimal/broke/idle); item 16 added a 3-case save-fuzz spec (1000 damaged saves) and fixed BUG-018 legacy harvest coercion; item 15 added a 3-case remote-fuzz spec (25 C->S handlers fuzzed); item 14 added 8 mutation-killer cases inside existing specs; item 13 added a 4-case streaming-readiness spec; item 10 added a candidate-gallery drift-lock spec; item 9 had set 1964, item 8 1956, item 7 1950, item 6 1944, item 5 1939, item 4 1933; refresh commit `47c0802` had set 1929). Now on WORK_QUEUE round 3 — work top to bottom, ticking here in the same commit. Round 3 item 1 delivered a 15-image reference board (`docs/v2/visual/art/reference/README.md`, sources and licences recorded); designer picks 3–5 more under V-D5. Round 3 item 3 delivered the V-D3 prop audit (`docs/v2/visual/art/PROP_AUDIT.md`): all ten low-poly props marked replace with verified ladder candidates/fallbacks, no IDs invented or models ingested. Round 3 item 2 delivered an off-by-default 60×60 warung/road/sawah corner candidate (`LookDevCorner`, 21 Parts, V-D1/V-D2), three saved review cameras and live Studio toggle verification (`docs/v2/evidence/h/2026-11-20-lookdev-corner/REPORT.md`); `screen_capture` timed out, so the visual verdict stays pending. Round 3 items 4–9 are `BLOCKED` on real Open Cloud IDs, the shared Studio Importer session (D-G2) and a designer/vision-observer verdict: verified ladder candidates were recorded in `SOURCING_BUILDINGS_VEG.md` (items 4/5) and `SOURCING_TEXTURES_NPC_ANIM.md` (items 7/8/9); no model downloaded, ID invented or visual verdict claimed. Round 3 item 19 was a docs-only Indonesian copy review: proposed edits are under WORK_QUEUE "Decisions for designer"; `Strings.luau` unchanged. Round 3 item 0a shipped admin-only, read-only Q6 commands for a published place (`src/server/Testing/Q6Admin*.luau`, `Q6_PUBLISHED_PLACE.md` §C); `LUNE-ONLY` until the designer runs the published check. Round 3 item 10a shipped the pure 8-phase day-cycle table (`src/shared/World/DayCycle.luau`); item 10b (live Sky/lamp/sound wiring) is still open. **WORK_QUEUE item 29 regression replay `SEEN-IN-STUDIO`** on synced code after items 1–28 (G3 9/9, forced raid, Q2 zero game-code errors, G5 20/20/20 s + 48 s Super reveal, Q5 30-min soak flat memory/234 cycles, no regression) — `docs/v2/evidence/h/2026-11-19-regression-replay/`. **Gate 1 follow-ups 2026-11-19 (all `SEEN-IN-STUDIO` on synced code, Rojo `localhost:34872`, fresh VERIFY-TEMP mock profile):** real minigame `Cancel.Activated` proof — fired 1×, scrim `true→false`, PlayArea destroyed, 0 commit remotes, profile unchanged (`h/2026-11-19-cancel-proof/`); G3 full §4 beat sheet desktop, all 9 steps `ok=true`, zero game-code errors in `output.log` (`h/2026-11-19-g3-beatsheet/`); G5 three fresh desktop runs, first harvest 20/21/21 s, Super reveal ~110 s, raid gossip ~5:22 — config already meets all targets, no balance change (`h/2026-11-19-g5-timings/`). **Q5 ten-player half attempted and `BLOCKED`** — Studio MCP has no local-server/team-test tool, no scriptable substitute (`h/2026-11-19-q5-multiclient/`). G3/G5 phone halves later closed `SEEN-IN-STUDIO` (items 32/33) after device emulation was confirmed working. Review finding 1 (cutscene) now `SEEN-IN-STUDIO`: raycasts of the exact `cameraFor` eye→target lines against the built world (1706 parts) found all four shots clear, but the police zoom at standOff 18 was blocked by `Tree_12.Canopy_2`; zoom standOff reduced 18→14 (largest clear value; kades clear throughout) and locked by a spec — evidence `h/2026-11-19-review-fixes/` (`REPORT.md`, `raycasts.json`). Review finding 2 (harness `force` restores `raidSafeUntil` after `RaidService.start`, never writes a zero cooldown to real save data) now `SEEN-IN-STUDIO`: fired through the real `Harness_Command` remote with a sentinel cooldown 1796000001, raid started (`incoming`, `InRaid=true`) and the sentinel + whole cooldown table were unchanged after `start` — evidence `h/2026-11-19-gate1-studio/`. That same pass closed **BUG-004**: zero-cash/zero-seed/no-tile player got exactly 1 `padi` seed, cash stayed 0, `n_seed_floor` notified (`SEEN-IN-STUDIO`); Q3 mid-loan recovery also `SEEN-IN-STUDIO` (borrow 375 → owed 412 → repay → active=false). Q2 full-session `output.log` saved (no game-code errors; only BUG-003 + Assistant warnings), now `SEEN-IN-STUDIO` after D-G4 (see sweep note at end of this line). Earlier Studio pass: BUG-011 phone, raid cutscene, Gate 1 harness/Q3 cases, perf switches + fps sampler `SEEN-IN-STUDIO` (`h/2026-11-17-phone-studio/`, `-raid-cutscene/`, `-gate1/`, `-perf-switches/`). Found + fixed BUG-012 (cash-fly `Vector2.Z` crash on sell). Added Studio-only `FpsSampler` (`ClientFps` attribute; no-op in published place). Real fps cost table on the designer phone, save repair, portrait rotation and phone-width readability still need the designer or a throwaway profile. **Synced-code sweep 2026-11-19** (`h/2026-11-19-gate1-sweep/`, Rojo on `localhost:34872`, sync confirmed inside Studio): the earlier join-bootstrap failure did not reproduce (no bug, no fix); force-raid no-save, BUG-004 and mid-loan recovery were re-confirmed; **Q2 and Q3 now `SEEN-IN-STUDIO`** — Q2 via the accepted BUG-003 exclusion (D-G4), Q3 by closing mid-minigame cancel (not reproduced — `Minigame_Cancel:FireClient` closes the scrim; BUG-013 closed, static spec `minigame_cancel_spec.luau`), the exact full-sack boundary/shop restock and the every-button/every-screen sweep (749×388, 0 dead ends). Q3 drove UI with `GuiService.SelectedObject` + keyboard Return; `user_mouse_input` did not activate buttons. The older unsynced pass `h/2026-11-19-gate1-studio/` is superseded on those two observations; its `output.log` remains the Q2 evidence. Place never saved or published; no `profile:Save()`; throwaway profile restored; all `__Verify*` probes removed. **Round-2 WORK_QUEUE items 1–14 now ticked** — item 12 (30-min all-candidates-on soak) `SEEN-IN-STUDIO`: 1801.83 s / 234 cycles, memory net-down both sides with a plateau after GC, census plateaus post-soak, pending 0, no desync symptom, zero game-code errors; evidence `h/2026-11-19-soak-all-candidates/`. Item 13 (StreamingEnabled readiness audit) `LUNE-ONLY`: shipping client already streaming-safe (no unbounded waits on streamable parts; world parts via CollectionService tags), locked by a mutation-checked 4-case spec; setting NOT flipped, decision parked for the designer; evidence `h/2026-11-19-streaming-readiness/`. Item 14 (mutation testing) `LUNE-ONLY`: 25/25 service-function faults killed after 8 new killer cases; all faults reverted; evidence `h/2026-11-19-mutation-testing/`. Next up: item 15 (remote fuzzing). Round-3 item 13 delivered the designer handoff `docs/v2/visual/REVIEW_ROUND3.md` (all nine toggles, three saved corner cameras, review order, blank verdicts). Round-3 classification 2026-11-20: items 9b and 10b are `BLOCKED` — the icon revision needs new Open Cloud uploads (the 27 base IDs are real) and the live day cycle needs licensed time-of-day sound IDs, an adzan settings UI/persistence and a designer/vision verdict; item 17's replay evidence is carried forward from HEAD `350c48f` because all later commits changed no gameplay default (a replay after approved visual integration belongs to item 16). Round-3 close 2026-11-20: items 11, 12, 14, 15 and 16 are `BLOCKED` on licensed skybox/VFX assets, approved visuals, a designer/vision verdict and designer hardware; item 18's refill scan found no further agent-closable work (all blocker/major bugs fixed or closed, all remaining Gate 1 rows designer/hardware-gated), so round 3 is exhausted.

**Long-run 2026-11-19 — WORK_QUEUE item 1 (`LUNE-ONLY`):** added `tests/specs/multiplayer_sim_spec.luau`
(9 cases) — ten interleaved Fakes players on the real Economy/Market/Debt, Raid and Farm services;
per-player cash/item/tile/debt/raid isolation, finite non-negative cash, no duplicated seeds, no
stuck raid or minigame state, no leak. No defect found, so no production fix needed. Suite 1709.
This is the scriptable Lune half of Q5; the live ten-client session stays `BLOCKED` on the designer
(`h/2026-11-19-q5-multiclient/`).

**Long-run 2026-11-19 — WORK_QUEUE item 2 (`LUNE-ONLY`):** full remote-handler security re-pass —
all 48 `OnServerEvent`/`OnServerInvoke` connections reviewed, every C->S remote validated/rate-limited/
guarded with a failure-path spec; closed the sole gap with `tests/specs/state_request_failure_spec.luau`.
No production fix needed. Results/coverage map in `docs/testing/CODE_AUDIT.md`. Suite 1712.

**Long-run 2026-11-19 — WORK_QUEUE item 3 (`LUNE-ONLY`):** data pass — added `tests/specs/data_pass_failure_spec.luau`
(7 cases) driving the real PlayerData with a fake ProfileStore: Studio store key + Cancel-on-leave/
timeout, Reconcile→migrate→sanitize order before loaded callbacks, failed-load kick, OnSessionEnd
kick + clear, leave-mid-load EndSession, saveAndConfirm receipt/error/timeout and pcall-isolated
beforeRelease. No defect found, so no production fix needed. Suite 1719.

**Long-run 2026-11-19 — WORK_QUEUE item 4 (`SEEN-IN-STUDIO`):** all eight Studio checks of the
LUNE-ONLY items driven on the real Rojo-synced modules via Studio MCP `execute_luau` (pure/config in
Edit mode; CabaiEvent + headroom in a Play Solo Server VM with the built 1706-part World), place
never saved/published, no `profile:Save()`: FidelityTier tiers forced and settings read
(0.4/0.7/1.0 particleRate, 25/50/80 swayRange), TierScale bursts 8/14/20 + wind sway, crop
bibit/tumbuh/siap config + selection, Cabai timed ×3 banner/300 s countdown and forced on/off,
debt-collector hook events + unsubscribe, all NPC archetype fields, 9.5-stud headroom clear in all
six hubs (zero offenders, raycasts pass), three season presets. No defect found, so no code fix and
no new gated hook needed. Evidence `docs/v2/evidence/h/2026-11-19-studio-checks/`. Suite 1719.

**Long-run 2026-11-19 — WORK_QUEUE item 5 (`SEEN-IN-STUDIO`):** Greybox retired to a test-only
fallback in the code path. `tests/specs/greybox_retirement_spec.luau` (6 cases) proves
`Map.isDesignerWorld()` keys on `VillageWorld`/`PlotAnchor`, `Village.build()` calls Greybox only with
no designer world, and all six hubs / 5 prompts / 3 NPCs bind from tags alone. In Studio, injecting a
designer world made `Village.build()` create zero Greybox parts in Edit mode (279→279), and in a
Play Solo Server VM the 1706-part Greybox world was destroyed and never regenerated (297 parts =
287 + exactly the 10 injected designer parts), six hubs bound, console identical (0 new Output
errors). Place never saved/published, no `profile:Save()`. Evidence
`docs/v2/evidence/h/2026-11-19-greybox-retirement/`. Suite 1725. The shipped place still needs the
designer's real village (Track C); fallback kept on until then — see WORK_QUEUE "Decisions for
designer".

**Long-run 2026-11-19 — WORK_QUEUE item 6 (`LUNE-ONLY` behaviour, `SEEN-IN-STUDIO` load/no-regression):**
performance pass. Instance counts per hub recorded in a Play Solo Server VM (1706 parts / 3289
descendants, six hubs unchanged — the fixes are client-only). Fixed two connection leaks with no
teardown: `Wind.stop()` (heartbeat + WindShake tag-removed signal) and `CameraFeel.stop()`
(heartbeat + CharacterAdded/CharacterRemoving), both idempotent and restart-safe, with `isStarted()`
diagnostics. Fixed the Wind 20 Hz hot-path allocation: FidelityRuntime is resolved once in start()
instead of a fresh pcall closure + require each tick (1→0 closures and resolutions per tick), while
settings() is still read each tick so tier changes land next tick. `tests/specs/perf_hotpath_spec.luau`
(7 cases) proves once-per-start resolution (Wind.resolveCount 0→1, still 1 after 50 fires while
settings() runs 50×), disconnect-on-stop, part restoration and restart. Studio client VM confirms
both modules load with `stop` present, 11 PlayerGui children mounted and 0 new Output errors.
Evidence `docs/v2/evidence/h/2026-11-19-performance/`. Suite 1732; selene 0 errors / 3 pre-existing
warnings in untouched files.

**Long-run 2026-11-19 — WORK_QUEUE item 7 (`SEEN-IN-STUDIO` text wiring, `LUNE-ONLY` scanner):** localization
pass. Appended 8 keys (cash/gain/price labels, Admin button, Juragan/Ordal chat tags, plot empty/owned)
to `Strings.luau` and routed every hardcoded player-facing literal through them: Hud, Tiles, Admin,
ActionFeel, Tags and the PlotService world sign. `ActionFeel.start(lang)` / `Tags.mount(lang)` now take
the locale resolved once in `Main.client`; plot signs follow the owner's `LocaleId` like DebtCollector.
`strings_integrity_spec.luau` gained a src-wide scanner that flags word-like literals assigned to
`*Text` (glyphs allowlisted), a self-test proving it catches stragglers, and reports zero today.
`plot_failure_spec` asserts key-derived sign text. Studio Play Solo confirms the live HUD cash label
(`Rp 35,857` — comma separator is the en-us client by design), all 9 unclaimed signs rendering
`Lahan Kosong`, all 8 keys resolving id/en, and 0 new Output errors; place never saved/published,
no `profile:Save()`, returned to Edit. Evidence `docs/v2/evidence/h/2026-11-19-localization/`.
Suite 1750; selene 0 errors / 3 pre-existing warnings.

**Long-run 2026-11-19 — WORK_QUEUE item 8 (`LUNE-ONLY` behaviour, `SEEN-IN-STUDIO` load/no-regression):** code
health pass. Cleared the 3 remaining selene unused-variable warnings by deleting confirmed dead code:
`tryAddHudButton` in Admin (wiring it would inject a second HUD button and change UI behaviour — a
designer choice — so it was removed instead; the append-only `admin_button` Strings key stays),
`stripTop` in MapSpec, `hubWall` in Greybox. Extracted Phone's three generic, parent-explicit view
helpers (`clearChildren`, `sectionLabel`, `scrollPage`) into a new `src/client/UI/PhoneWidgets.luau`,
keeping local aliases in Phone so every call site is unchanged; restored the `Icons` require Phone
still needs for app-grid tiles. `tests/specs/code_health_spec.luau` (5 cases) locks exact helper output
and asserts no inline definitions remain. No other >600-line file was split — the rest are tightly
coupled stateful controllers where a split adds risk without benefit, and vendored ProfileStore is
off-limits. Studio Play Solo confirms Phone + PhoneWidgets both load all their functions with 0 probe
errors and no new Output errors; place never saved/published, returned to Edit. Evidence
`docs/v2/evidence/h/2026-11-19-code-health/`. Suite 1754; selene 0 errors / 0 warnings / 0 parse errors.

**Long-run 2026-11-19 — WORK_QUEUE item 9 (`SEEN-IN-STUDIO` load/gate/reversibility, `LUNE-ONLY` specs; NOT approved, checkbox stays open):** look-dev candidates for designer review. Pure shared registry/gate `src/shared/LookDev.luau` holds two candidates, both "candidate, awaiting designer yes", cartoonish-realism, no asset IDs (spec-enforced built-in-material allowlist + no-ID token scan): `plaza_lighting` (alternative material + midday lighting preset on the Pasar hub) and `police_walkin` (existing `Village.police[1]` NPC walked to the cutscene road anchor over the real 1.8 s walkin shot). Thin reversible appliers `src/client/World/LookDevPlaza.luau` and `src/server/World/LookDevWalkin.luau` register via isolated `pcall(require, ...)` in the Main bootstraps. Toggle OFF by default, Studio-only, in-memory only, one active at a time, never persisted; `:disable()` restores originals. `tests/specs/lookdev_candidates_spec.luau` (15 cases) locks gate/plans/no-IDs/wiring. Both Play Solo VMs: `current()` nil by default, both candidates unapproved, both appliers loaded/registered, 0 probe errors; live toggle proved ClockTime 17.2→11.4→restored. Place never saved/published, returned to Edit. Evidence `docs/v2/evidence/h/2026-11-19-lookdev-candidates/`. Suite 1769; selene 0 errors / 0 warnings / 0 parse errors. Final visual approval `BLOCKED` on the designer's yes (queue "Decisions for designer").

**Long-run 2026-11-19 — WORK_QUEUE item 10 (`LUNE-ONLY`; bug hunt by reading):** whole-tree defect-pattern scan of `src/server`/`src/client`/`src/shared` plus full reads of all high-risk money/data/net/live/logic modules (subagent recon twice failed `ECONNREFUSED`, done in main session). Two real defects found, fixed and mutation-proven, logged in `docs/testing/BUGS.md`: **BUG-014 (major)** `src/shared/Produce.luau` `snapshot()` lacked the `type(stack) == "table"` guard its siblings have, so a damaged non-table value in the dynamic-key `produce`/`gudang.stacks` tables (which SaveSanitize deliberately leaves untouched) threw and broke `State_Snapshot:FireClient`; now skips corrupt stacks and defaults non-table `traits` to `{}` — 2 cases in `tests/specs/produce_spec.luau`. **BUG-015 (minor)** `EconomyService` Nama Baik bonus read `MarketConfig.namaBaikMaxBonus` but clamped with a hardcoded ±0.05, silently capping a tuned config; now clamps to `±maxBonus` (shipped 5% unchanged) — `tests/specs/economy_config_spec.luau`. Both regression specs mutation-checked (old code fails them: BUG-014 pcall false, BUG-015 expected 69 got 68). Evidence `docs/v2/evidence/h/2026-11-19-bug-hunt-reading/`. Suite 1772; selene 0 errors / 0 warnings / 0 parse errors.

**Long-run 2026-11-19 — WORK_QUEUE item 11 (`LUNE-ONLY`; spec coverage gaps):** mapped every `src/server`/`src/client` module to the specs that require it and inspected each spec's failure-case names; full coverage list + N/A justifications in `docs/v2/evidence/h/2026-11-19-spec-coverage/COVERAGE.md`. Three genuine gaps closed: **FirstSession** had only happy-path specs → `first_session_failure_spec.luau` (6 cases: nil player, player who left with no loaded data, missing story/tutorial/flags, null stats, unusable ToolService); **client/State** was never spec'd (only `shared/State` was) → `client_state_failure_spec.luau` (6 cases: malformed snapshot/patch ignored, valid ones applied, idempotent listener disconnect); **RankService** lacked damaged-save recovery → `rank_failure_spec.luau` (4 cases: NaN/non-number Nama Baik, NaN attribute mirror, damaged cooldowns table). A truthy non-table `story` crash was judged defensive-only (SaveSanitize repairs `story`/`flags` to tables on load) and not logged as a bug, consistent with item 10. Suite 1788; selene 0 errors / 0 warnings / 0 parse errors.

**Long-run 2026-11-19 — WORK_QUEUE item 12 (`LUNE-ONLY` specs + partial Studio smoke):** inventoried every `PlayerRemoving` handler and `onBeforeRelease` hook against prior spec coverage (table in `docs/v2/evidence/h/2026-11-19-player-leave-cleanup/REPORT.md`). Six uncovered handlers got `tests/specs/player_leave_cleanup_spec.luau` (10 cases): debt collector NPC dismissal, IsAdmin attribute clear, leaderboard final flush, harness gate close, evidence offers/tokens drop, Net/State release hook. Raid/farm/plot/ratelimit/data-pass leave paths already covered and verified; cleanup was already correct, so no game source changed. Suite 1798; selene 0/0/0. Studio: clean boot, real `RaidService.resolveOnLeave` / `Gate.close` / `EvidenceService.tokenCount` exercised in the live Server datamodel (`SEEN-IN-STUDIO`); the actual leave-transition is `BLOCKED — Studio MCP cannot fire the engine PlayerRemoving signal and has no local-server/team-test tool to spawn a departing second player`. Place not saved.

**Long-run 2026-11-19 — WORK_QUEUE item 13 (`LUNE-ONLY` specs + Studio 10-reset loop):** audited every `CharacterAdded`/respawn connection; each binds once per session (`PlayerData.onLoaded` or idempotent `start()`), never per respawn; `CameraFeel` uses a generation counter, `RaidOverlay` clears per-cutscene death connections. No game source changed. `tests/specs/respawn_rejoin_spec.luau` (5 cases): FarmService/Cosmetics connect once across 10 respawns with exactly one teleport/hat per reset, CameraFeel keeps one connection per signal across 10 cycles, `Theme.screenGui` is `ResetOnSpawn=false` (phone page rebuild already in `lazy_pages_spec`). Suite 1803; selene 0/0/0. Studio (`SEEN-IN-STUDIO`, `h/2026-11-19-respawn-rejoin/`): 10 Humanoid-kill resets all spawned a fresh character at the same plot position, Client PlayerGui stayed at 11 ScreenGuis with none `ResetOnSpawn=true`, clean boot; exact engine connection count is not introspectable via Studio MCP (separate `require` VM, no signal API), so the one-handler invariants are locked by specs. Place not saved.

**Long-run 2026-11-19 — WORK_QUEUE item 14 (`LUNE-ONLY`, money path):** `tests/specs/purchase_idempotency_spec.luau` (5 cases) drives the real `PlayerData` + `Receipts` against a fake ProfileStore (synthetic ids 111/777): duplicate PurchaseId grants/notifies once, leave mid-grant is not acknowledged and a rejoin retry grants once, failed save re-confirms on retry with no double grant, unknown and placeholder-0 products never acknowledged, erroring game-pass check grants nothing. Fixed **BUG-016** (major): the dedup early-return acknowledged a replayed PurchaseId without re-confirming a save, so a failed-save-then-retry could acknowledge a purchase never durably saved; dedup path now re-runs `saveAndConfirm` before acknowledging (no re-grant/re-notify). Mutation-checked. Suite 1808; selene 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-purchases/REPORT.md`.

**Long-run 2026-11-19 — WORK_QUEUE item 15 (`LUNE-ONLY`, cross-server failures):** `tests/specs/cross_server_failure_spec.luau` (9 cases) drives the real `LiveConfig` against fake DataStore/MessagingService: read/write/publish/subscribe errors never throw, malformed messages sanitized, local changes survive failed writes, and OrderedDataStore failed-write bursts stay inside the retry/throttle budget. Analytics budget and OrderedDataStore backoff/last-good already covered by existing specs; **MemoryStore N/A** (no usage in `src/`, none invented). Fixed **BUG-017** (major): `LiveConfig` stored `updatedAt` but never ordered by it, so a late stale message or eventually-consistent read rolled newer live config back across all servers, and a corrupt timestamp could freeze all future updates. Fix: finite non-negative `updatedAt` in `sanitize()` + `isStale()` guard in `subscribe()`/`load()`. Mutation-checked. Suite 1817; selene 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-cross-server-failures/REPORT.md`.

**Long-run 2026-11-19 — WORK_QUEUE item 16 (`LUNE-ONLY`, admin authority):** `tests/specs/admin_authority_spec.luau` (4 cases) wires the REAL `Admins` allowlist + `LiveConfig` + `AdminService` (existing `season_admin_failure_spec` only exercised them mocked): non-allowlisted player refused for all privileged actions on a published server, forging the `IsAdmin` attribute grants nothing, the allowlisted designer changes the real config and grants cash with `earned=false`/`sku=admin_grant`, and Studio's everyone-is-admin still enforces every payload bound. No source bug; no game source changed. Suite 1821; selene 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-admin-authority/REPORT.md`.

**Long-run 2026-11-19 — WORK_QUEUE item 17 (`LUNE-ONLY`, analytics audit):** `tests/specs/analytics_audit_spec.luau` (24 cases) audits `ANALYTICS.md` against `src/`: `GetService("AnalyticsService")` has a single owner, all 16 documented §2 events have call sites, economy/onboarding emissions exist, `ShopPurchase` stays intentionally unwired, `first_harvest` is an example with no call site, and the extra undocumented `first_session` funnel is flagged. It also drives the real `OnboardingService` + `Analytics` (steps 1..N in order, once, then `finished`) and real `EconomyService` (Source/Sink with post-mutation balance, refused spends emit nothing). 3-field payload cap and never-fatal wrapper already covered by `analytics_spec`. No source bug; no game source changed. Studio dashboard check still `belum diverifikasi di Studio`. Suite 1845; selene 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-analytics-audit/REPORT.md`.

**Long-run 2026-11-19 — WORK_QUEUE item 18 (`LUNE-ONLY` specs, `SEEN-IN-STUDIO` plot walks):** new dependency-free `src/server/World/NpcWalk.luau` gives world movers stuck detection, a timeout and a teleport fallback onto the goal (cancellation/unparent aborts without teleport). `NpcFactory:walkTo` (police via RaidService) and `DebtCollector.summon` both delegate to it; the collector now walks to `plot.spawnCFrame.Position` for every plot. `tests/specs/npc_pathing_robustness_spec.luau` (9 cases) locks all paths and both call sites; mutation-checked. Studio Server VM: real Part walked to all ten plots (final XZ distance 0.00 each) and the stuck fallback commanded exactly the goal; no game-code errors, place not saved, no `profile:Save()`. Caller-level live run limited by no bound `Village.police` and no assigned solo plot (wiring locked by spec). Caught/fixed a native-`vector` mismatch in the new module during the Studio run (`type()` returns `"vector"`), now field-read via `pcall`. Suite 1854; selene 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-npc-pathing/`.

**Long-run 2026-11-19 — WORK_QUEUE item 19 (`SEEN-IN-STUDIO`):** device-sim Studio at 749×388 (safe rect `{0,-58,749,388}`); probed live `AbsolutePosition`/`AbsoluteSize` of every screen and app page — HUD, Phone home, all six lazy pages, Shop/Leaderboard panels, Toasts, Minigame and RaidOverlay — 0 off-screen/inset violations. Found and fixed one genuine layout defect: `src/client/UI/Admin.luau` `refit()` fitted the `UIScale` to full camera height 388 while the GUI inset leaves 330 usable, clipping the panel's bottom rows ~17–25 px; it now subtracts `GuiService:GetGuiInset().Y` (in-Studio re-probe scale 0.4435, panel bottom 324 < 330, 0 violations). Layout-only, no text size reduced; place not saved, no `profile:Save()`, returned to Edit. Suite 1854; selene 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-ui-fit/`.

**Long-run 2026-11-19 — WORK_QUEUE item 20 (`LUNE-ONLY`):** new `tests/specs/ui_touch_text_audit_spec.luau` (5 cases) walks every UI source file under `src/client/UI`, `Minigames`, `Feel` and `server/World`: no `TextSize`/`MinTextSize` literal below `Visuals.type.small` (11), every interactive button meets the checked-in `PhoneLayout.meetsTouch` one-axis 44 px rule (grid-sized families checked against their cell sizes), and source-of-truth constants locked. Fixed the two genuine stragglers in `src/client/UI/Phone.luau`: app-label and phone-toggle `UITextSizeConstraint.MinTextSize` 9/10→11 (both let `TextScaled` render below the minimum). Mutation-checked: reverting either fix fails two cases. No button failed the audit. Decision recorded in WORK_QUEUE (one-axis touch rule kept to protect item 19's AdminPanel fit). Suite 1859; selene 0/0/0. No evidence dir (static audit, no Studio claim).

**Long-run 2026-11-19 — WORK_QUEUE item 21 (`SEEN-IN-STUDIO` for selection, `LUNE-ONLY` for binding/cancel policy):** gamepad/keyboard navigation. New pure `src/client/UI/Navigation.luau` (no Roblox globals) holds the LIFO/cancel/rescue policy; permanent `_byId` registry is separate from the active `_stack` so close→reopen restores a default. New Studio-only `src/client/UI/NavBridge.luau` binds B/Escape at ContextActionPriority.High (Begin gate, Sink only on an actual close, else Pass), writes/watches `GuiService.SelectedObject`, and follows each root's Visible. Registered in Phone, Hud Shop, Leaderboard, Admin (unregister on destroy), Minigame and RaidOverlay; started in Main.client after all mounts. `navigation_spec` (17 cases) + `nav_wiring_spec` (7 cases) pin pure policy and static wiring; suite 1883, selene 0/0/0. Studio pass (`GuiService.SelectedObject`, Client VM): 9/9 checks — default on open for three screens, newest-open default, close-top falls back to lower, close-all clears, close→reopen restores. Found and fixed a real close→reopen defect this pass (registry/stack split), mutation-checked. Play Solo returned to Edit, place not saved/published, no `profile:Save()`. Decision recorded (raid overlay non-dismissable, phase-driven default). **B/Escape key-press → actual close in Studio is `BLOCKED — Roblox Studio MCP input cannot produce a ContextActionService Begin event`** (only `UserInputService.InputBegan` and CAS `Cancel` observable; `VirtualInputManager:SendKeyEvent` lacks RobloxScript capability); the binding is pinned by spec and needs a real-device manual session for the final input→Sink link. Evidence `docs/v2/evidence/h/2026-11-19-gamepad-nav/` (`REPORT.md`, `results.json`).

**Long-run 2026-11-19 — WORK_QUEUE item 22 (`SEEN-IN-STUDIO`):** audio hygiene. New pure `src/client/AudioPolicy.luau` (no Roblox globals) holds the config audit, playable-id set, per-role loop state machine and pooled one-shot invariant. `src/client/Audio.luau` now owns the Sound/SoundGroup/Tween objects: one grouped, volumed Sound per configured id created at mount (17), never reallocated, one-shots reset TimePosition and replay the pooled Sound, and both looping roles go through the pure policy. The fade tween is cosmetic; the authoritative outgoing Stop is `task.delay(FADE_SECONDS)` guarded by a per-Sound token that `cancelFade` invalidates on replay/newer fade, so intermediate outgoing loops always stop and a replayed loop survives. Two genuine Studio-found defects: a role-generation guard skipped Stop on intermediate outgoing beds (left 4 ambience loops playing); and TweenService does not step under the Studio MCP environment (Part and Sound tweens neither animate nor fire Completed while Heartbeat advances), so cleanup cannot depend on a tween callback. `audio_policy_spec` (13) + `audio_wiring_spec` (12), suite 1908, selene 0/0/0; both guards mutation-checked. Studio census (Play Solo, Client VM): 4 SoundGroups and 17 Sounds with 0 ungrouped / 0 bad volumes before and after a rapid 7-step `Cuaca` sequence (0.12 s gaps, real SeasonService signal), exactly one music and one ambience loop after settle. No `MusicZone` parts exist (Track C designer world not built); place not saved/published, no `profile:Save()`, returned to Edit. Evidence `docs/v2/evidence/h/2026-11-19-audio-hygiene/` (`REPORT.md`, `results.json`).

**Long-run 2026-11-19 — WORK_QUEUE item 23 (`SEEN-IN-STUDIO`):** Lighting × FidelityTier per hub. Drove the live `FidelityRuntime` singleton (via a temporary injected LocalScript, since the Studio MCP `execute_luau` tool has a separate ModuleScript `require` cache) through all six hubs × three tiers (18 combinations), moving the character to each hub centre. Every row reported the forced tier via `get()` and the player `FidelityTier` attribute, with settings advancing correctly (Rendah none/off/false/minimal, Sedang key/near/false/half, Tinggi all/on/true/full). The Lighting descendant census was identical in all 18 rows and after a `Rendah→Tinggi→Rendah→Sedang→Tinggi→Rendah` cycle plus clear — 6 effects (Atmosphere, BloomEffect, ColorCorrectionEffect, ColorGradingEffect, Sky, SunRaysEffect), `DepthOfFieldEffect` count 0 — and hub-local light counts did not change across tiers: no tier switch creates or destroys a Lighting effect, so none sticks. Finding recorded as a designer decision (not a defect): the four lighting-related tier settings are reported but have no consumer — Sky alone owns Lighting post effects from seasons/weather, and `cameraDoF=true` created no DoF effect; wiring tier→lighting is V0.4 / designer-blocked. Verification-only, no production code changed, probe instances destroyed, place not saved/published, returned to Edit. Evidence `docs/v2/evidence/h/2026-11-19-lighting-fidelity/` (`REPORT.md`, `results.json`). Suite unchanged at 1908.

**Long-run 2026-11-19 — WORK_QUEUE item 24 (`LUNE-ONLY`):** strict types on pure modules. Added `--!strict` to all 24 `src/shared/Config/*` modules, 6 pure `client/Feel/*` logic modules (`FidelityTier`, `TierScale`, `FpsSampler`, `CutsceneSequencer`, `CutsceneState`, `MomentGuard`) and both pure `server/Testing/*` policy modules (`Gate`, `RaidTrigger`) — 32 files. Engine-facing modules (`ActionFeel`, `CameraFeel`, `FidelityRuntime`, `PerfSwitches`, `Harness`) stay non-strict because they touch game services/Instances at load; `LazyPages` was already strict. Fixed the 18 surfaced strict errors with annotation-only, runtime-erased changes (type aliases for heterogeneous config rows in Audio/Products/RaidCutscene, `::` casts on `table.remove` results in FidelityTier/FpsSampler, typed callback lists/maps, `data: any`/`resolve(): any`) — no behaviour change. `luau-lsp analyze` with a freshly regenerated gitignored sourcemap: 17 distinct errors before and after (zero introduced; remaining are pre-existing in engine-facing files). Suite unchanged at 1908, `lune` 1908 passed, `selene` 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-strict-types/REPORT.md`.

**Long-run 2026-11-19 — WORK_QUEUE item 25 (`SEEN-IN-STUDIO`):** dead code and dead strings. Removed 22 confirmed-dead `Strings` keys (exact-literal + prefix-aware reverse scan over `src/`+`tests/`, docs mentions and substring matches excluded) and 5 definition-only exported functions (`Village.getWorld`, `State.touchAll`, `Crops.isRegrow`, `MarketService.pressure`, `FarmService.hasGrowing`). No dead modules (the two apparent orphans load via `pcall(require,...)`) and no stale Rojo mappings (all four `$path` resolve), so none removed. Kept `NavBridge.debugState` (Studio hook), `PlotService.getNeighbors` and `Theme.sticker` (documented/live helper), `Audio.configured` (borderline Config API). New spec `tests/specs/dead_code_spec.luau` proves all removals, a no-unreferenced-key invariant, lookalike survival and mapping resolution. `luau-lsp analyze` error file set unchanged from item 24 — zero new type errors. `lune` 1927 passed (1908 + 19), `selene` 0/0/0. Clean Studio Edit→Play→Edit (`Development-Juragan-Desa`): no game-code errors, no references to removed keys/functions, returned to Edit, nothing saved/published. One unrelated pre-existing audio `ContentId rbxassetid://203785492` asset-type warning. Evidence `docs/v2/evidence/h/2026-11-19-dead-code/REPORT.md`.

**Long-run 2026-11-19 — WORK_QUEUE item 26 (`LUNE-ONLY`):** test-suite health. Three baseline runs identical at 1927 passed — no flaky spec. Added wall-clock timing per case/suite/total to `tests/lib/Test.luau` (PASS/FAIL text and return values unchanged) and a per-spec timing report to `tests/run.luau` (`--timing` prints the full table; name filter still works), with 3 characterization cases in `tests/specs/harness_timing_spec.luau`. Timing exposed one 14× outlier (`economy_money_spec` payout case, 1.236 s): `Env.new()` re-walked the whole `src/` tree and re-read module source on every construction (48× in that case). Memoized the static directory listing and source text in `tests/lib/Env.luau` (fresh Instance tree + module cache per Env preserved). Full suite **31.7 s → 4.8 s (~6.6×)**, slowest case 1.236 s → 0.213 s, nothing over 2 s. `lune` 1930 passed (1927 + 3) ×3 with identical bodies; `selene src` 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-suite-health/REPORT.md`.

**Long-run 2026-11-19 — WORK_QUEUE item 27 (`LUNE-ONLY`):** CI. `.github/workflows/tests.yml` already existed; scoped `push` to `main` and `track/*` (kept `pull_request`), added the missing `selene src` step and made the test invocation `lune run tests/run.luau`. `CompeyDev/setup-rokit@v0.1.2` installs all tools pinned in `rokit.toml` (lune, selene, rojo, luau-lsp, stylua) onto PATH — confirmed from the action README. Local verification: `lune` 1930 passed, `selene src` 0/0/0, workflow YAML parsed with the expected triggers/steps. The GitHub-hosted run is `UNVERIFIED` locally until the push triggers it. Evidence `docs/v2/evidence/h/2026-11-19-ci/REPORT.md`.

**Long-run 2026-11-19 — WORK_QUEUE item 28 (`LUNE-ONLY`):** docs refresh. No game code touched. `docs/v2/plan/TECH.md` brought current (commands, 1930 count, `selene` gate, new Track C specs table, new §12 documenting FidelityTier / FpsSampler / CutsceneSequencer / LazyPages / RaidTrigger / SaveSanitize + harness `raid`/`raidState` hooks; stale cutscene gap fixed). `docs/testing/HARNESS.md` gained the `raid`/`raidState` actions. `docs/README.md` snapshot dates updated to 2026-11-19. `BALANCE.md` and `LOCALIZATION.md` regenerated from live code and dated: 3 ranks / 12 crops / 5 rarity tiers (~1.51× expected multiplier) with real config values; 333 bilingual `Strings` keys (0 empty id/en, verified by loading the module under lune), correct spec names. Historical evidence reports, `v2/archive/` and signed run sheets were left as records. `lune` 1930 passed, `selene src` 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-docs-refresh/REPORT.md`.

**Long-run 2026-11-19 — WORK_QUEUE item 29 (`SEEN-IN-STUDIO`):** regression replay on synced code after items 1–28 (HEAD `350c48f`, placeId 132087524375529, Rojo `localhost:34872`, fresh VERIFY-TEMP Mock profile reverted before commit). G3 full nine-step beat sheet all `ok=true`, cash 50→77→57→157, padi 5→4→6, tutorialStep 1→5, rank `gurem` — matches the item-28 baseline. Forced raid `raid{viral,force}` → `incoming`/`inRaid=true`/`busy=true`, no stuck state, exercising items 21/22/23 paths together. Q2 full-session Output: zero game-code errors/warnings, only external Assistant-plugin warnings + AnalyticsService notices + one harness camera notice; BUG-003 did not recur. G5 three fresh profiles, real grow timers, no `ready` shortcut: first harvest 20/20/20 s (<45 s), Super reveal 48 s (<5 min), raid gossip 310 s (<420 s) — meets/beats baseline, no balance change. Q5 client-half soak 1801.71 s / 234 cycles / `done=true`: client memory 2617.57→2586.09 MB (235 samples, min 2578.21, max 2618.38, delta −31.5 MB), server 2617.5→2587.3 MB, no leak/stuck/desync; 1339 plant / 1339 harvest / 178 sell / 174 buy failures are graceful seed-starved refusals (probe buys 1 padi but plants 6), same class as the 2026-11-14 baseline; economy still advanced cash 50→945, rank `gurem`→`petani`, lifetimeEarned 1495. No regression found, no bug filed. Evidence `docs/v2/evidence/h/2026-11-19-regression-replay/` (`REPORT.md`, `results.json`, `soak.json`, `g3-g5-q2-output.log`, `soak-output.log`). Q5 ten-player/multi-client half stays `BLOCKED` (no local-server/team-test tool). `lune` 1930 passed, `selene src` 0/0/0.

**Long-run 2026-11-19 — WORK_QUEUE item 30 (`LUNE-ONLY`):** Gate 1 status sheet. No game code touched. All 16 rows of `docs/testing/GATE1.md` had their evidence column rewritten to what exists today: Q2/Q3 gained post-change regression-replay proof (`h/2026-11-19-regression-replay/`), G3/G5 a second desktop-half confirmation, G4b the item-19/20 desktop + `LUNE-ONLY` proof (749×388 probe 0 violations, touch/text audit), Q8 the current 1930-passing count and every bug's regression spec. Statuses unchanged: 3 `SEEN-IN-STUDIO` (Q2/Q3/Q4), 4 `BLOCKED` (G3/G4/G5/Q5), 1 `LUNE-ONLY` (Q8), 8 `UNVERIFIED`. Added a "Designer actions to close the open rows" table with the exact action + evidence path for all 11 open rows. Every cited evidence directory, spec file and the `DECISIONS.md:27` D-G4 citation verified to exist. `lune` 1930 passed, `selene src` 0/0/0.

**Long-run 2026-11-19 — WORK_QUEUE item 31, refill round 1 (`LUNE-ONLY`):** scanned all 24 `[ ]`/`[~]` checkboxes (all in this file; GATE1.md/BUGS.md use status words). Second bug-hunt-by-reading over all 53 `src/` files changed since item 10 (`de8e5e1..HEAD`): **no new defects** — every diff is a strict annotation, dead-code removal, or an already-specced BUG-016/017/011/005/012 fix. Subagent transport `ECONNREFUSED`, hunt ran in main session. Overturned a stale block: `StudioDeviceSimulatorService:SetDeviceAsync("iphone_14")` yields a real 749×389 viewport, harness replies there (`lastOk=true`), `screen_capture` works — the "no device emulation" reason for the G3/G5 phone halves being `BLOCKED` is false (item 19 used `SetDeviceAsync` at 749×388). Appended items 32 (G3 phone beat sheet) / 33 (G5 phone timings) / 34 (refill round 2). Q5 ten-player half stays `BLOCKED` (no multi-client tool, re-confirmed). `lune` 1930 passed, `selene src` 0/0/0.

**Long-run 2026-11-19 — WORK_QUEUE item 32 (`SEEN-IN-STUDIO`):** G3 gap closed. Replayed the full nine-step §4 harness beat sheet at a real iPhone 14 viewport (749×389, inset 0,58) on a fresh VERIFY-TEMP Mock profile (reverted before commit), device set via `SetDeviceAsync("iphone_14")` in **Edit before Play** (setting it during Play yielded a 1×1 render viewport). All nine steps `ok=true`, 9 commands → 9 replies, cash 50→77→57→157, padi 5→4→6, tutorialStep 1→5, sack 1 at harvest — identical to the desktop baseline (`h/2026-11-19-regression-replay/`). Output: zero game-code errors/warnings (only external Assistant-plugin, BUG-003 asset-type ×3 and AnalyticsService notices). Commands needed ≥300 ms spacing (4/s rate limit) and a first-new-reply collector (last-reply grabbed stale state and failed sell once). Evidence `docs/v2/evidence/h/2026-11-19-g3-phone/` (`REPORT.md`, `results.json`, `output.log`). GATE1.md G3 row + designer-action row and this file's G3 checkbox marked `SEEN-IN-STUDIO`; the old "no device emulation" block is overturned. `lune` 1930 passed, `selene src` 0/0/0.

**Long-run 2026-11-19 — WORK_QUEUE item 33 (`SEEN-IN-STUDIO`):** G5 gap closed. Re-ran the three fresh-profile first-session timings at a real iPhone 14 viewport (749×389, inset 0,58; `SetDeviceAsync("iphone_14")` in **Edit before Play**) with a VERIFY-TEMP Mock profile (reverted before commit) and no `ready` shortcut. Timings stamped to Output via `print("[G5P] ... wall=...")`, commands paced ≥300 ms. First harvest 22/20/21 s (<45 s) across three restarted sessions; first Bagus reveal at harvest ~20–22 s, guaranteed-Super second harvest 70 s from t0 / 48 s from plant (<5 min); raid gossip `scripted_raid_gossip` at 315 s from t0 (<7 min), matching `scriptedRaidDelay=330` s. Zero game-code errors/warnings (only external Assistant-plugin, BUG-003 asset-type ×3 and AnalyticsService notices). Evidence `docs/v2/evidence/h/2026-11-19-g5-phone/` (`REPORT.md`, `results.json`, `output.log`). GATE1.md G5 row + designer-action row and this file's G5 checkbox marked `SEEN-IN-STUDIO`; counts now 5 `SEEN-IN-STUDIO` / 2 `BLOCKED`. Tier guarantee remains `LUNE-ONLY` (`first_session_spec.luau`). `lune` 1930 passed, `selene src` 0/0/0.

**Long-run 2026-11-19 — WORK_QUEUE item 34, refill round 2 (`LUNE-ONLY`; full round added nothing, refill loop closed):** re-scanned all 21 remaining `[ ]`/`[~]` checkboxes (all in this file; GATE1.md/BUGS.md use status words). Every one needs the designer — physical device / real touch / multiple human clients / art / a published place / a human look judgement — none agent-doable. Third bug-hunt-by-reading over the 53 `src/` files changed since item 10 (`de8e5e1..HEAD`): confirmed items 32/33 touched **zero** source files so the set is byte-identical to round 2; reviewed all 568 substantive +/- code lines (strict `::` casts/type aliases, dead-code removals, or already-specced BUG-014/015/016/017, item 21/22 NavBridge+AudioPolicy, NpcWalk extraction, text-size/GuiService-inset UI-fit tweaks, RaidTrigger cooldown typing) — **no new concrete defect**. No new item appended; refill loop stopped per the queue's own rule. `lune` 1930 passed, `selene src` 0/0/0.

**Round 2 — WORK_QUEUE item 1 (`SEEN-IN-STUDIO`):** phone emulation proven active; no downgrade of the G3/G5 phone claims. Controlled comparison via `StudioDeviceSimulatorService` (device set in Edit before Play, `FitToWindow`): `average_windows` → 1365×768 / aspect 1.77 / `TouchEnabled=false`; `iphone_14` → 749×389 / 1.92 / `TouchEnabled=true`; `samsung_galaxy_a06` → 705×338 / 2.08 / `TouchEnabled=true`; portrait forced during Play → 388×761 / 0.51. `Game.StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor` (title is landscape-only by design, which is why a pre-Play portrait setting reverts on entering Play). Switching devices flips touch and reshapes the viewport — emulation is live. `screen_capture` accepted but not visually analysable in this session (no image input), so no visual claim. No GATE1/MASTER_PLAN status change required; G6/G7/Q5/Q6/Q7 remain designer/hardware gates. Evidence `docs/v2/evidence/h/2026-11-19-phone-emulation/` (`REPORT.md`, `results.json`). `lune` 1929 passed (refresh commit `47c0802` changed the suite to 1929; this line is now authoritative), `selene src` 0/0/0. Place not saved or published.

**Round 2 — WORK_QUEUE item 2 (`SEEN-IN-STUDIO`):** CI green on `track/c-world-look`. `gh run list`/`gh run view` showed the historical failure (`44458499132`, `a618f02`) was the `dead_code_spec` "item 25: Rojo mappings resolve > $path Packages exists on disk" check, already fixed by refresh commit `47c0802`; runs `44472087680` and `44473085751` are `success`. Bumped `actions/checkout@v4`→`@v5` in `.github/workflows/tests.yml` to clear the `Node.js 20 is deprecated` warning — v5 confirmed to exist (`gh api repos/actions/checkout/tags`, `git/ref/tags/v5`) and its `action.yml` declares `using: node24`; no other workflow change (setup-rokit's nested `actions/cache` is skipped, `cache` defaults false). YAML parsed (`checkout@v5`); `lune` 1929 passed, `selene src` 0/0/0. Evidence `docs/v2/evidence/h/2026-11-19-ci-round2/` (`REPORT.md`). Re-check the pushed run below.

**Round 2 — WORK_QUEUE item 3 (`LUNE-ONLY` audit):** re-audited all 48 evidence `REPORT.md` files plus the five `SEEN-IN-STUDIO` gate rows (G3/G5/Q2/Q3/Q4) against build + Rojo sync + method + no hand-injection/stale source + behaviour (not structure alone). **No status downgraded.** Every current `SEEN-IN-STUDIO` row has at least one Rojo-synced behaviour report (g3-phone / g5-phone / gate1-sweep / regression-replay / cancel-proof). The only hand-injected Edit-DataModel pass (`h/2026-11-19-gate1-studio`) was already superseded by `h/2026-11-19-gate1-sweep`, whose header confirms Rojo `localhost:34872` sync from inside Studio and records its two unreliable observations (minigame Cancel, join bootstrap) as non-reproduced, not defects. "Stale" hits elsewhere are technical (fade identity/harness replies/cross-server config), not evidence staleness. 15 older 2026-11-14/17 reports name build+method but omit the literal "Rojo-synced" wording — documentation gap only, no integrity defect, all backed by newer synced re-runs. All cited evidence paths exist (apparent misses are prose fragments or future designer targets). Recorded in `docs/testing/CODE_AUDIT.md` with a table and an item-28 follow-up (GATE1 Q4 cell should also cite `gate1-sweep`). `lune` 1929 passed, `selene src` 0/0/0. No source file changed.

**Round 2 — WORK_QUEUE item 4 (`SEEN-IN-STUDIO`):** agent-made icon CANDIDATE set for every `IconMap.luau` slot (27 = 12 crops, 5 tiers, 2 currency, 8 phone apps), generated deterministically (`docs/v2/visual/art/icons/src/generate_icons.py`, 256x256 transparent RGBA + `contact_sheet.png`) and uploaded via Studio MCP `open_cloud_invoke` (`assetType=Image`; all `moderationState=Approved`; creator User `172146044`; NOT the `ROBLOX_API_KEY` env var, no key printed/logged/committed). Every returned ID recorded immediately in `docs/v2/visual/art/ASSET_MANIFEST.md` (28 rows incl. one pipeline-probe disc). Wired behind an OFF-BY-DEFAULT `icons` LookDev candidate: IDs live in `src/shared/IconMap.luau` `candidateIds` (entry `id` stays 0 so letters remain default), applied by new `src/client/UI/LookDevIcons.luau` and booted behind `pcall` in `Main.client.luau`; LookDev holds only a pure-data `idsSource` pointer so its no-ID guard holds. Live Edit-VM round-trip: `crop_padi` 0→114251482326552, `tier_sultan` 0→124401414397944, `phone` 0→135874869613602, `disable()` restored all to 0, `hasApplier("icons")=true`. No agent visually graded the art (no image input this session) — all CANDIDATES awaiting designer yes/no, never approved or shipped on by default; gallery `docs/v2/visual/CANDIDATES.md`. Evidence `docs/v2/evidence/h/2026-11-19-icons-candidates/` (`REPORT.md`, `results.json`). `lune` 1933 passed, `selene src` 0/0/0. Place not saved or published.

**Round 2 — WORK_QUEUE item 5 (`SEEN-IN-STUDIO`):** seven deterministic 512x512 tileable RGBA hero textures per `TEXTURES.md`, generated by `docs/v2/visual/art/textures/src/generate_textures.py` (wrapped 3x3 draw for true seamlessness; validity + seam checks pass; `contact_sheet.png`), uploaded via Studio MCP `open_cloud_invoke` (`assetType=Image`, all `moderationState=Approved`, `texture_sawah` briefly `Reviewing` then Approved; creator User `172146044`; NOT the `ROBLOX_API_KEY` env var, no key printed/logged/committed), every ID recorded immediately in `docs/v2/visual/art/ASSET_MANIFEST.md`. Wired behind an OFF-BY-DEFAULT `textures` LookDev candidate: IDs live in `src/shared/TextureMap.luau` `candidateIds`, all shipping `Visuals.textures` slots stay 0, applied by new `src/client/World/LookDevTextures.luau` booted behind `pcall` in `Main.client.luau`; LookDev holds only a pure-data `idsSource` pointer so its no-ID guard holds. `SurfaceAppearance` is MeshPart-only (Studio-verified: parenting to greybox `Pasar` Parts throws), so the adapter targets the imported v2 `prop_*`/`kit_*` MeshParts. Live Play-VM round-trip: 7 slots `0 → IDs → 0`, `usingCandidates()` `false → true → false`, 10 MeshParts received real `rbxassetid://…` ColorMaps on enable and all were destroyed on disable. No agent visually graded the art (no image input this session) — all CANDIDATES awaiting designer yes/no, never approved; gallery `docs/v2/visual/CANDIDATES.md`. Evidence `docs/v2/evidence/h/2026-11-19-textures-candidates/` (`REPORT.md`, `results.json`). `lune` 1939 passed, `selene src` 0/0/0. Place not saved or published.

**Round 2 — WORK_QUEUE item 6 (`SEEN-IN-STUDIO`):** 19 procedural caricature detail recipes (6 Pak RT, 5 Tengkulak, 4 Polisi, 4 debt collector) in `src/shared/NpcModelCandidates.luau` (pure data, no asset IDs), applied by `src/client/World/LookDevNpcs.luau` to the live box NPCs only while the OFF-BY-DEFAULT `npcs` LookDev candidate is enabled and all destroyed on disable. Follows the fictional design cards in `npcs.md` / `Config/NpcArchetypes.luau`; Polisi badge is a plain fictional disc, no real insignia. Approach changed from Blender/imported meshes to procedural source-controlled primitives: subagent transport down (`ECONNREFUSED`) and place saves forbidden, so it stays in Rojo and is fully reversible. `LookDev.luau` gains a fifth pure-data `npcs` candidate (`idsSource` pointer, no numeric IDs), booted behind `pcall` in `Main.client.luau`. The restricted Studio MCP `execute_luau` VM has no `Enum.PartShape` member, so shape resolution is under `pcall` with a default-Block fallback (real LocalScript VM resolves cylinder/ball/wedge). Live Play-VM round-trip: 15 detail parts on the 3 tagged NPCs (`pakrt=6|tengkulak=5|polisi=4`), all removed on disable (no `DebtCollector` in place; its recipe proven by source + spec). Render is a schematic parsed directly from the recipe source by `docs/v2/visual/art/npcs/src/generate_npc_preview.py`, NOT a Studio screenshot (captures can't be saved this session). No agent visually graded the art — all CANDIDATES awaiting designer yes/no; gallery `docs/v2/visual/CANDIDATES.md`. Evidence `docs/v2/evidence/h/2026-11-19-npc-candidates/` (`REPORT.md`, `results.json`). `lune` 1944 passed, `selene src` 0/0/0. Place not saved or published.

**Round 2 — WORK_QUEUE item 7 (`SEEN-IN-STUDIO`):** low-poly growth-stage models (bibit/tumbuh/siap) for all 12 crops in `Config/Crops` (36 models) as pure-data recipes in `src/shared/CropModelCandidates.luau` (`partsFor(cropId, stage)`, no asset IDs), shown in a floating in-world showcase by `src/client/World/LookDevCrops.luau` only while the OFF-BY-DEFAULT `crops` LookDev candidate is enabled and all destroyed on disable; shipping `FarmService` crop visuals untouched. Palette from `ART.md §3`. `LookDev.luau` gains a sixth pure-data `crops` candidate (`idsSource` pointer, `cropCount=12`, `stageCount=3`, no numeric IDs), booted behind `pcall` in `Main.client.luau`. Approach is source-controlled primitives (not imported meshes) for the same transport/place-save reasons as item 6. Restricted Studio MCP `execute_luau` VM cannot resolve `Enum.PartType` shapes, so shape resolution is under `pcall` with default-Block fallback (real LocalScript VM resolves Cylinder/Sphere/Wedge). Live Play-VM round-trip: 36 models / 339 parts (303 from `partsFor()` + 36 soil bases) appeared and all were removed on disable. Render dumped from the same `partsFor()` via Lune (`docs/v2/visual/art/crops/src/dump_crops.luau`) so it cannot drift — NOT a Studio screenshot. No agent visually graded the art — all CANDIDATES awaiting designer yes/no; gallery `docs/v2/visual/CANDIDATES.md`. Evidence `docs/v2/evidence/h/2026-11-19-crop-candidates/` (`REPORT.md`, `results.json`). `lune` 1950 passed, `selene src` 0/0/0. Place not saved or published.

**Round 2 — WORK_QUEUE item 8 (`SEEN-IN-STUDIO`):** warung counter, pasar stall, pos polisi desk, Pak RT table, lanterns and signs as pure-data primitive-part recipes in `src/shared/HubPropCandidates.luau` (`partsFor(hubKey)` for pasar/warung/polisi/pakrt + shared lantern + accent sign, no asset IDs), attached CFrame-relative to each hub's anchor part by `src/client/World/LookDevHubProps.luau` only while the OFF-BY-DEFAULT `hubprops` LookDev candidate is enabled and all destroyed on disable; shipping `Greybox` hub props untouched. Hub models found recursively under `workspace.World`. Palette from `ART.md §3`; sign uses each hub's own accent. Within per-hub budget: 11/11/11/10 parts (MAP_SPEC 8–12), spec-locked at `<= 12`. `LookDev.luau` gains a seventh pure-data `hubprops` candidate (`idsSource` pointer, `hubCount=4`, no numeric IDs), booted behind `pcall` in `Main.client.luau`. Approach is source-controlled primitives (not imported meshes) for the same transport/place-save reasons as items 6/7. Restricted Studio MCP `execute_luau` VM cannot resolve Enum shape/material members, so those lookups are under `pcall` with safe defaults (real LocalScript VM resolves them). Live Play-VM round-trip: 43 parts (pakrt=10, pasar=11, polisi=11, warung=11) appeared under `LookDevHubPropDetails` and all were removed on disable. Render dumped from the same `partsFor()` via Lune (`docs/v2/visual/art/hubprops/src/dump_hubprops.luau`) so it cannot drift — NOT a Studio screenshot. No agent visually graded the art — all CANDIDATES awaiting designer yes/no; gallery `docs/v2/visual/CANDIDATES.md`. Evidence `docs/v2/evidence/h/2026-11-19-hubprops-candidates/` (`REPORT.md`, `results.json`). `lune` 1956 passed, `selene src` 0/0/0. Place not saved or published.

**Round 2 — WORK_QUEUE item 9 (`SEEN-IN-STUDIO`):** free Creator Store audio search for the audio event list (`Config/Audio.sounds`); round 1 had 17 licensed IDs, the only empty slots were the sawah/hutan music beds. Two free APMOfficial beds chosen and verified loading in a Play VM (`IsLoaded=true`, lengths read) before recording: `music_sawah` 9042889348 ("Close Your Eyes - 60 - No Melody", 58.59 s) and `music_hutan` 9048807207 ("Cavernous Wonders 60 A", 60.97 s), both with licence/source in `docs/v2/visual/art/ASSET_MANIFEST.md`. IDs live only in `src/shared/SoundMap.luau` (pure data, `candidateIds`/`candidateOrder`/`assetUrl`/`playable`); the ID-free `src/client/World/LookDevSounds.luau` find-or-creates the round-1 `JD_<group>` SoundGroups, creates one Sound per candidate with Looped/Volume from config, drives loop state via `AudioPolicy.new(SoundMap.playable())` + `:transition` (at most one active loop per role), and stops/destroys everything on disable. Shipping `Config/Audio` slots stay `id=0`. `LookDev.luau` gains an eighth pure-data `sounds` candidate (`idsSource` pointer, `soundCount=2`, no numeric IDs), booted behind `pcall` in `Main.client.luau`. Live Play-VM round-trip: 2 Sounds in `JD_music`, both loaded (`music_hutan` playing as the single active loop, `music_sawah` pooled), all destroyed on disable; SoundMap flag `false→true→false`. No agent graded the sound — all CANDIDATES awaiting designer yes/no; gallery `docs/v2/visual/CANDIDATES.md`. Evidence `docs/v2/evidence/h/2026-11-19-sound-candidates/` (`REPORT.md`, `results.json`). `lune` 1964 passed, `selene src` 0/0/0. Place not saved or published.

**Round 2 — WORK_QUEUE item 10 (`LUNE-ONLY`):** gallery `docs/v2/visual/CANDIDATES.md` maintained across all eight LookDev candidates with one row each and the six required columns (toggle, render/screenshot, fps cost, blank designer yes/no); per-asset icon (27) and texture (7) tables also have blank yes/no. Added `tests/specs/candidate_gallery_spec.luau` (4 cases, registered in `tests/run.luau`) parsing the markdown tables: required columns, exactly one row per `LookDev.IDS` with no extras, each toggle names its candidate and its render path exists on disk and cost states fps, and all three designer yes/no columns are blank. Mutation-checked: filling a cell or deleting the `sounds` row each fails one case; restore passes. Evidence `docs/v2/evidence/h/2026-11-19-candidate-gallery/` (`REPORT.md`, `results.json`). `lune` 1968 passed, `selene src` 0/0/0. Designer fills yes/no; no agent graded any art.

**Round 2 — WORK_QUEUE item 11 (`SEEN-IN-STUDIO`):** budget census at all six MapSpec hubs with candidates on and off, forced across Rendah/Sedang/Tinggi by the live `FidelityRuntime` singleton from a probe LocalScript injected into PlayerScripts (same require cache as Main.client). LookDev is single-active, so all-on = baseline + the sum of the eight disjoint per-candidate deltas. 100-stud Workspace census of instances/parts/estimated triangles (primitive Shape table Block/Wedge 12, Cylinder 32, Ball/Sphere 320, cross-checked against the pure-data recipes: crops 339 parts/27,416 tris/36 models, hubprops 43/3,648, NPC details 19/656). Counts are tier-invariant. Worst all-on 49,208 triangles (9.8% of the ~500k Sedang budget) and 712 parts; baseline alone 230–347 parts, 13,232–19,780 triangles. Triangles PASS; the ~500 draw-call proxy exceeds only in the all-on stress case and entirely because of the 339-part Studio-only crops review showcase — the shipping state (all candidates off) is within budget. Camera-frustum cross-check discarded (probe camera returned zero parts); 100-stud census is the reported metric. Low-tier showcase trim parked under WORK_QUEUE "Decisions for designer"; no delivered art changed. Probe cleaned, Play stopped, place not saved or published. Evidence `docs/v2/evidence/h/2026-11-19-budget-check/` (`REPORT.md`, `results.json`). `lune` 1968 passed (no spec added), `selene src` 0/0/0.

**Round 2 — WORK_QUEUE item 12 (`SEEN-IN-STUDIO`):** 1800 s client soak with all eight LookDev candidates applied at once (six client adapters via `.apply` + `plaza_lighting` on Client and `police_walkin` on Server via `LookDev.enable`, all `ok`; single-active LookDev assembled additively as in item 11), fresh in-memory mock profile (VERIFY-TEMP, reverted), harness at 2 commands/s. Ran to deadline 1801.83 s / 234 cycles / `done=true` with pending queue always 0. No leak: client memory 2750.97→2635.36 MB (net −115.6; one GC compaction −120.4 at sample 54 then +11.4 MB over 180 cycles, +3.06 over the final 40 = plateau), server 2760.76→2636.04 MB (−124.7). No growth: census 6735→6898 instances / 1706→1840 parts over the soak then +2 instances / +0 parts over ~993 s post-soak, zero crop parts persisted; Roblox has no raw connection counter, so stuck replies (pending 0) + instance/part census are the proxies. No desync symptom: cash 50→754, padi 5→0, tilesOwned 6, rank gurem→petani, lifetimeEarned 0→1324, tutorialStep 5. Refusals (1337 plant/harvest, 178 sell, 172 buy) are graceful by design (buy 1, plant 6). Zero game-code errors, BUG-003 did not recur. Probe cleaned, Play stopped, place not saved or published, git clean. Evidence `docs/v2/evidence/h/2026-11-19-soak-all-candidates/` (`REPORT.md`, `soak.json`, `soak-output.log`). `lune` 1968 passed (no spec added), `selene src` 0/0/0. Ten-player half BLOCKED (no team-test tool in Studio MCP).

**Round 2 — WORK_QUEUE item 13 (`LUNE-ONLY`):** StreamingEnabled readiness audit; setting NOT flipped (designer decision). Audited all 71 WaitForChild calls (26 client) and every world-part path: zero unbounded waits on streamable paths — client calls are ReplicatedStorage.Shared or bounded (Remotes 30/10 s, Terrain 10 s, Humanoid 10 s, PlayerGui owner-replicated). World parts come from CollectionService tags that follow streaming (Tile/WindShake/NpcSpawn/LeaderboardBoard/MusicZone) with added/removed signals or re-polling; the one shipping workspace snapshot (Phone.neighborPlayers) is nil-guarded, attribute-validated and re-polled. Four LookDev review tools use one-time workspace scans (off by default, dev-only) — parked with the designer decision. Added `tests/specs/streaming_readiness_spec.luau` (4 cases: no unbounded WFC with non-vacuous floor, classifier self-check, tag-based consumers, shipping snapshots supplemental), mutation-checked (injected unbounded WFC gave `1 FAILED, 1971 passed`, probe removed). Evidence `docs/v2/evidence/h/2026-11-19-streaming-readiness/` (`REPORT.md`, `results.json`). `lune` 1972 (+4), `selene src` 0/0/0. Proposal added under WORK_QUEUE "Decisions for designer".

**Round 2 — WORK_QUEUE item 14 (`LUNE-ONLY`):** mutation testing of 25 service functions across economy/inventory/raid/debt/receipts/save. One exact-line fault each, full lune suite with the fault, byte-for-byte restore in `finally`. Pass 1: 15 killed, 7 survived, 3 MANIFEST_ERROR (ambiguous strings, not applied). Pass 2 with occurrence indexing: I10/D17 killed, D19 survived. Pass 3: eight killer cases added inside the existing spec files (zero-transfer analytics E07, gudang without stacks I09, source-stack-key deletion I12, zero-owed repay D19, exact-cash raid fine R15, inactive saveAndConfirm S25, and source-invariant locks for the behaviourally-equivalent defence-in-depth guards R14/R16). Re-ran all eight: 8/8 killed, exactly one named test failing each time (no cross-killing). Final **25/25 killed, 0 survived**; all faults reverted, diff on the six targets empty. Evidence `docs/v2/evidence/h/2026-11-19-mutation-testing/` (`REPORT.md`, `results.json`). `lune` 1980 (+8), `selene src` 0/0/0.

**Rules for this section.** Every agent reads it before touching the repo, so nobody has to rediscover
the state from scratch. Whoever finishes a task ticks it here **in the same commit**, adds its status
word (§7) and an evidence path, and bumps the "Last updated" line. `[x]` = done with evidence,
`[~]` = partly done (say what is missing), `[ ]` = not started. Never tick without evidence. The
gate rows' full detail stays in `docs/testing/GATE1.md`; defects stay in `docs/testing/BUGS.md`.

**Visual direction:** `docs/v2/visual/VISUAL_MASTER_PLAN.md` (written 2026-11-16, D14: aim realistic, land believable) plans light, materials, models, VFX, camera and UI fidelity in phases V0–V4 with its own tracker. It sits under this file; nothing in it is built yet (`UNVERIFIED`).

### Next up (recommended order)

Handoff 2026-11-17: the code-only frontier is mostly done (failure-path specs for every server service, save repair, fidelity tiers, raid cutscene, lazy phone). The bottleneck is now Studio, which was closed all session, so the many `LUNE-ONLY` items below are untested in play.

1. **Studio pass first (main session only, needs Studio open):** BUG-011 done `SEEN-IN-STUDIO` 2026-11-17 (mount, first-tap build, app open, ID/EN, landscape; `docs/v2/evidence/h/2026-11-17-phone-studio/`). Still to do in this order —
   - ~~BUG-011: phone mounts / build / apps / rotation / ID/EN.~~ Done except portrait rotation (`LUNE-ONLY`; viewport cannot be changed via MCP).
   - ~~Raid cutscene: camera hand-back / FOV / BREAKING NEWS / 20 s window.~~ Done `SEEN-IN-STUDIO` 2026-11-17 via a gated `raid` harness hook (`docs/v2/evidence/h/2026-11-17-raid-cutscene/`); phone-width readability of the lower third still needs the designer's device (emulator cannot be set via MCP).
   - `FidelityTier` attribute switches live; admin perf switches toggle and restore; record fps per switch on the designer phone (V0.2 cost table).
   - ~~Save repair warns once on a damaged profile.~~ Left `LUNE-ONLY` (`tests/specs/save_reconcile_spec.luau`): driving the real load path needs a throwaway DataStore profile with corrupted fields, which would touch real save data in the dev place; not safe to force from the harness. The warning text and once-only count are proven in Lune; a real damaged-profile load stays a designer/test-place task.
   - Portrait rotation: left `LUNE-ONLY` (`tests/specs/phone_layout_spec.luau`); the Studio MCP cannot change `Camera.ViewportSize`/device orientation, so only the landscape structure was observable in play.
   - ~~Then the Gate 1 rows in `docs/testing/GATE1.md` (Q3 dead ends).~~ Q3 closed `SEEN-IN-STUDIO` 2026-11-19 on synced code (`h/2026-11-19-gate1-sweep/`): mid-minigame cancel not reproduced, exact full-sack boundary/shop restock and every-button sweep all driven, 0 dead ends. Q2 closed the same day via D-G4. G3 beat sheet and G5 timings now proven at desktop size (`SEEN-IN-STUDIO`, `h/2026-11-19-g3-beatsheet/`, `h/2026-11-19-g5-timings/`); their phone-size halves remain `BLOCKED` on device emulation. Still open (all designer-side): phone-size BUG-008/009 re-check (G4b), fps (G6), ten-player session (Q5, `BLOCKED`, `h/2026-11-19-q5-multiclient/`).
2. **F — raid cutscene framing:** after a review finding, anchors moved off the MapSpec hub centres onto the NPC front spots (Pak RT 68/47, Polisi -68/42) at head height, and a pure `RaidCutscene.cameraFor` places the eye on the -z front side outside all six hub footprints; `RaidOverlay.placeCamera` consumes it. Line of sight `SEEN-IN-STUDIO`: raycasts of the exact `cameraFor` eye→target lines against built geometry cleared all four shots; zoom standOff 18→14 because the police shot at 18 was blocked by `Tree_12.Canopy_2` (10/12/14 clear, 16+ blocked) — `h/2026-11-19-review-fixes/`. Framing composition and the police NPC walk-in remain `BLOCKED` on the designer's look-dev pass + authored NPC animation (visual plan §8; cannot read captures).
3. **G — icon upload (designer/Open Cloud):** `BLOCKED` on designer. All `IconMap.luau` slots are `id=0 / NEEDS-ASSET`, no final icon art exists (only mockup PNGs in `visual/mockups/src/icons/`), and asset IDs must never be invented. Designer uploads (landing in their inventory) then fills IDs in `IconMap.luau` + `ASSET_MANIFEST.md`.
4. **V0.3–V0.5:** `BLOCKED` on designer — reference board needs designer/CC0 photos (V-D5 open), look-dev corner needs the designer's visual judgement, and V-D1..V-D5 answers are not in `DECISIONS.md` yet.
5. **Bugs:** BUG-004 **closed** — D-G3 option A (free-seed floor) implemented and now `SEEN-IN-STUDIO`: zero cash + zero seeds + no tiles → exactly 1 `padi` seed, cash still 0, `n_seed_floor` notified; once-per-session guard held (`h/2026-11-19-gate1-studio/`, re-confirmed in `h/2026-11-19-gate1-sweep/`). BUG-013 **closed — not reproduced**: the 2026-11-19 minigame-Cancel report was an unsynced-source artifact; on synced code the real `Cancel.Activated` closes the scrim with 0 commit remotes and an unchanged profile (`h/2026-11-19-cancel-proof/`), wiring locked by `tests/specs/minigame_cancel_spec.luau`. Join bootstrap was likewise never broken (`Main.server.luau:95/101`) — no bug row.
6. **H — harness force raid no longer writes save data:** `force` used to leave `data.cooldowns.raidSafeUntil = 0` on the live profile. `RaidTrigger.withTemporaryCooldown` restores the exact old cooldown table/value after `RaidService.start` on success and error (specs `LUNE-ONLY`, `raid_trigger_spec`), and is now `SEEN-IN-STUDIO`: with the synced modules driven through the real `Harness_Command` remote and a sentinel cooldown 1796000001, the raid started and the whole cooldown table was unchanged afterwards — `h/2026-11-19-gate1-studio/results.json`, re-confirmed in `h/2026-11-19-gate1-sweep/results.json`. Q3 mid-loan recovery (borrow → repay clears debt) also `SEEN-IN-STUDIO` there; mid-minigame cancel now **not reproduced / closed** (BUG-013) on synced code — `Minigame_Cancel:FireClient` closes the scrim, static guard `tests/specs/minigame_cancel_spec.luau`.

### Phase 0 — repo safe for parallel work

- [x] 0.1 Working tree committed in topical commits.
- [x] 0.2 Studio failures: BUG-001, BUG-002 fixed `SEEN-IN-STUDIO`; BUG-003 is external, excluded by D-G4.
- [x] 0.3 Playtest harness — `docs/testing/HARNESS.md`.
- [x] 0.3b Bug sweep — `docs/testing/BUGS.md`.
- [x] 0.4 Baseline — `docs/v2/evidence/baseline/`.
- [x] 0.5 Tool pipeline — `plan/TOOLS.md`, D-G1 decided; Open Cloud key exists and introspects valid 2026-11-14 (user env var `ROBLOX_API_KEY`, scopes include `asset` read/write). Shells started before it was set see it empty: read it from the User environment or restart.

### Gate 1 at a glance (detail: `docs/testing/GATE1.md`)

- [x] G2/Q1 no open blocker or major bug — all defects BUG-001 through BUG-010 addressed; BUG-003 closed external (`SEEN-IN-STUDIO`).
- [x] G3 harness plays the full beat sheet at phone size — `SEEN-IN-STUDIO` 2026-11-19: desktop half all 9 §4 steps (`h/2026-11-19-g3-beatsheet/`, reconfirmed `h/2026-11-19-regression-replay/`), phone half replayed at real 749×389 (`SetDeviceAsync("iphone_14")` in Edit before Play) with all 9 steps `ok=true`, cash 50→77→57→157, tutorialStep 1→5, zero game-code errors/warnings (`h/2026-11-19-g3-phone/`, item 32). Old "no device emulation" block overturned (item 31).
- [ ] G4 nothing visible is a placeholder — icons are letters, NPCs are boxes, most actions are silent.
- [~] G4b text readable at phone size — signs on boards, HUD and phone checked at iPhone 14 (`evidence/h/2026-11-14-audit-fixes/`); app pages updated with 44x44 touch targets.
- [x] G5 first harvest < 45 s, first reveal < 5 min, raid < 7 min — `SEEN-IN-STUDIO` 2026-11-19: desktop 3 fresh runs 20/21/21 s, Super ~110 s, raid ~5:22 (`h/2026-11-19-g5-timings/`, reconfirmed `h/2026-11-19-regression-replay/`); phone half replayed at real 749×389 (`SetDeviceAsync("iphone_14")` in Edit before Play) with first harvest 22/20/21 s, Super 70 s, raid gossip ~5:15 (315 s), real grow timers, no `ready` shortcut (`h/2026-11-19-g5-phone/`, item 33). Config already meets all targets, no balance change. Tier guarantee `LUNE-ONLY` (`first_session_spec.luau`). Old device-emulation block overturned (item 31).
- [~] G6 fps and instance count — instance count saved; Studio-only `ClientFps` sampler works (~60 unfocused, no per-switch delta; `h/2026-11-17-perf-switches/`); designer phone ~30 fps at max, 60 at lowest; real mid-range fps still a designer task.
- [ ] G7 five real people, own phones (designer).
- [x] Q3 no dead ends — `SEEN-IN-STUDIO`: death, reset, rejoin mid-raid, full-sack sell recovery via the gated raid hook (`h/2026-11-17-gate1/`); mid-loan recovery and zero-cash/zero-seed/no-tile recovery (`h/2026-11-19-gate1-studio/`); mid-minigame cancel (not reproduced, BUG-013 closed), exact full-sack boundary/shop restock and every-button/every-screen sweep — 0 dead ends (`h/2026-11-19-gate1-sweep/`).
- [x] Q2 zero errors/warnings — `SEEN-IN-STUDIO`: full-session `output.log` with zero game-code errors (`h/2026-11-19-gate1-studio/output.log`) plus the accepted BUG-003 exclusion (D-G4, `DECISIONS.md:27`).
- [~] Q5 soak — 30-min client soak done (`SEEN-IN-STUDIO` 2026-11-14); ten-player session attempted 2026-11-19 and `BLOCKED` — Studio MCP has no local-server/team-test tool (`h/2026-11-19-q5-multiclient/`); needs a human at the Test tab.
- [ ] Q6 persistence in a published place.
- [ ] Q7 touch on a real mid-range phone.

### Tracks

**A. Game feel**
- [~] Crop growth stages (bibit / tumbuh / siap) exist in `FarmService`; not judged by a human.
- [x] Plant, harvest, sell feedback: particles, tweens, camera nudge, cash-fly — `LUNE-ONLY`, `tests/specs/feel_spec.luau`.
- [x] Rarity reveal: toast tint, Sultan/Langka shake, sting hooks, ActionFeel — `LUNE-ONLY`, `tests/specs/feel_spec.luau`.
- [~] First tier consumers: ActionFeel bursts scale count and lifetime (never below 1 particle), Wind sways only within the tier range with a fade — `LUNE-ONLY`, `src/client/Feel/TierScale.luau`, `tests/specs/tier_consumers_spec.luau`; not seen in Studio.
- [~] V0.2 admin perf switches (Highlights, shadows, bloom, terrain decoration, particles; local, reversible) in the admin panel with the live tier — panel structure + live tier seen in Studio; shadows/decoration toggle and restore `SEEN-IN-STUDIO` (all 5 states restore, `h/2026-11-17-perf-switches/`); `src/client/Feel/PerfSwitches.luau`, `tests/specs/perf_switches_spec.luau`. Studio-only `FpsSampler` publishes `ClientFps` (`tests/specs/fps_sampler_spec.luau`); Studio readings ~60 with no per-switch delta, real cost table still a designer-phone task.
- [~] V0.1 `FidelityTier` tier selection (Rendah/Sedang/Tinggi, fast down, slow up, frozen in hook moments, §6 settings table) — `LUNE-ONLY`, `src/client/Feel/FidelityTier.luau`, `tests/specs/fidelity_tier_spec.luau`; wired live by `src/client/Feel/FidelityRuntime.luau` (Heartbeat feed, `FidelityTier` player attribute, `tests/specs/fidelity_runtime_spec.luau`); no visual reads the tier yet, no settings toggle, rarity reveal and raid overlay freeze the tier via `src/client/Feel/MomentGuard.luau` (`tests/specs/hook_moment_spec.luau`), thresholds unmeasured on a phone, not seen switching in Studio.

**B. First session**
- [x] Four-step tutorial (plant, harvest, sell, buy) — `SEEN-IN-STUDIO` via harness.
- [x] Next Goal card after the tutorial (next rank, then daily tasks) — `SEEN-IN-STUDIO` desktop, `src/shared/NextGoal.luau`.
- [x] Broke-player seed floor (BUG-004, D-G3) — now `SEEN-IN-STUDIO` (2026-11-19, `h/2026-11-19-gate1-studio/`); regression `tests/specs/seedfloor_spec.luau`.
- [x] Tutorial padi ~20 s, first session only — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] Guaranteed Bagus on first harvest, Super/Langka on the second — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] BayarLater loan offer beat (~2:30) — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] Scripted NPC neighbour raid as a spectator (~5:30) — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] Warung rumour / Tengkulak whisper (~7:00) — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] Rank-up ceremony to Petani (~9:00) — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] Explain "Sus" the first time it changes (keep the word; it is satire) — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] Analytics funnel step per beat — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.

**C. World** (art direction: **cartoonish realism**, D11 — chunky shapes, Roblox textured materials; reference: the Warung)
- [x] Hub buildings, trees, decor, flora, shelf goods, hills — `SEEN-IN-STUDIO` desktop.
- [x] Hub names painted on sign boards (BUG-008) — `SEEN-IN-STUDIO` desktop.
- [~] 9.5-stud headroom in all six hubs - `MapSpec.HEADROOM` set to 9.5 and asserted across all six hubs in `tests/specs/greybox_spec.luau` (`LUNE-ONLY`); only the Warung photographed in Studio.
- [x] Spawn composition: the player spawns facing a tree trunk; frame plot, NPC and hub instead (spawn finalised from `src/server/World/MapSpec.luau`, `LUNE-ONLY` in `greybox_spec`) — `LUNE-ONLY`, `tests/specs/greybox_spec.luau`.
- [x] Golden-hour look: clock 16:00-17:00, warm golden senja atmosphere, sunset skybox, and realistic background pine forest leaving sunset corridor clear; golden-hour window and three season preset ids finalised in `src/server/World/MapSpec.luau` (`LUNE-ONLY`, `tests/specs/greybox_spec.luau`) + existing Studio evidence in `docs/v2/evidence/c/2026-11-14-world-look/REPORT.md`.
- [x] Terrain grass decoration: `Terrain.Decoration = true`, road painted Ground material to prevent blade clipping — `SEEN-IN-STUDIO`, `docs/v2/evidence/c/2026-11-14-world-look/REPORT.md`.
- [x] Terrain tops out on the 0.5 gameplay plane instead of burying it — `SEEN-IN-STUDIO` (live raycasts: 0.500 at every grid and key point, idempotent over three runs); screenshots `BLOCKED` (this model cannot save or read viewport captures), `docs/v2/evidence/c/2026-11-15-terrain-fix/REPORT.md`.
  - Note: **a place's terrain can be older than the source that made it.** `Greybox.applyTerrain` always clears the whole 400×16×400 village band (Y −8…8) with Air before filling, so a slab from an earlier generator cannot survive under a rebuild. Smooth Terrain's visible top face is `regionTop + 2` for a 4-stud voxel, not a whole-voxel snap.
- [x] Map spec written (layout, hubs, plots, terrain, scale): `docs/v2/visual/art/MAP_SPEC.md`, art reference `docs/v2/visual/art/map/` — `UNVERIFIED` until built in Studio.
- [x] World at S=2: Rumah Pak RT as scale reference, all hubs, plots (r 192), roads, river, 4 sawah terraces, hills, spawn from `MapSpec.luau` — `SEEN-IN-STUDIO` numerically (grid 0.5 over 1014 points, 0 holes; 10 plots, 6 hubs, spawn); `LUNE-ONLY` specs; screenshots by the designer only. Terrace tops exactly 4.5/8.5/12.5/16.5 live (0 bad of 80 samples).
- [~] Terraced sawah and river: built from `MapSpec.luau`, 4 terraces exact and river water live (`SEEN-IN-STUDIO` numerically, `evidence/c/2026-11-15-terrain-fix/` style probes); three season presets not re-tuned yet, no photo.
- [x] `Greybox.luau` retired to a test fallback — code path proven `SEEN-IN-STUDIO` 2026-11-19
  (`docs/v2/evidence/h/2026-11-19-greybox-retirement/`); the place file itself stays Track C.

**D. UI**
- [x] HUD readable, stats under the top bar (BUG-009) — `SEEN-IN-STUDIO` desktop.
- [x] Phone is the single control panel (Seed Shop and Leaderboard are apps; device look; landscape on short screens) — `SEEN-IN-STUDIO` desktop and iPhone 14.
- [x] Seed bar shows only owned or selected seeds, centred — `SEEN-IN-STUDIO`.
- [~] Cabai banner gold with countdown — `LUNE-ONLY` (event not seen running).
- [x] App pages (Report, Farm, Loan, Quests, Cheat, Decor) at phone size and with real taps — `LUNE-ONLY`, `src/client/UI/Phone.luau`, `src/shared/PhoneLayout.luau`, `tests/specs/phone_layout_spec.luau`.
- [x] Stats panel as icon chips (cash first, sack, Sus, Nama Baik) — `LUNE-ONLY`, `src/client/UI/Hud.luau`.
- [x] D6: Indonesian default plus a language picker (today only `Strings.langFor`); closes BUG-007 — `LUNE-ONLY`, `src/client/UI/Hud.luau`.
- [x] BUG-006 world label under the HUD panel — `LUNE-ONLY`, `src/client/UI/Hud.luau`.
- [x] Phone app pages build on open and are destroyed on leave/close (`src/client/UI/LazyPages.luau`, `tests/specs/lazy_pages_spec.luau`); BUG-011 fixed — `SEEN-IN-STUDIO` 2026-11-17: first tap builds the device frame, home grid and all 8 app tiles (lazy), `App_phone` opens `PagePhone` and hides home, ID→EN switches tile labels, landscape applies on the short viewport; Output clean except external BUG-003 (`docs/v2/evidence/h/2026-11-17-phone-studio/`). Portrait rotation and the other 7 app pages remain `LUNE-ONLY`.
- [ ] Fonts chosen on a phone (§9.3).

**E. Audio**
- [x] Village music, Pasar music, day ambience — `SEEN-IN-STUDIO`, `art/ASSET_MANIFEST.md`.
- [x] UI sounds, tier stings, raid sting, rain and night ambience — `SEEN-IN-STUDIO`, `art/ASSET_MANIFEST.md`.

**F. Characters and cutscenes**
- [~] Caricature NPC framework from design cards (Pak RT/Tengkulak/Polisi archetype data and fictionality markers) — `LUNE-ONLY`, `src/shared/Config/NpcArchetypes.luau`, `tests/specs/npc_framework_spec.luau`; visual models/rigs still pending.
- [~] Raid cutscene timeline (establish, triple zoom, police walk-in, letter; 7.0 s; skippable after the first viewing via client attribute `RaidCutsceneSeen`) — `LUNE-ONLY`, `src/client/Feel/CutsceneSequencer.luau`, `src/shared/Config/RaidCutscene.luau`, `tests/specs/cutscene_sequencer_spec.luau`; wired into `src/client/UI/RaidOverlay.luau` (Scriptable camera restored on finish/skip/cancel/death, `CameraFeel.pause/resume`, BREAKING NEWS lower third `raid_lower_third`, decisions in `src/client/Feel/CutsceneState.luau`); server `RaidService.INCOMING_SECONDS` now matches the cutscene so the 20 s choice window is intact. Camera hand-back on finish/skip/death/Raid_End, FOV ease (26→72), BREAKING NEWS bar and the full 20 s choice window now `SEEN-IN-STUDIO` 2026-11-17 via a gated `raid` harness hook (`docs/v2/evidence/h/2026-11-17-raid-cutscene/`). Real `focusAnchors` + `anchorFor` resolver wired into `placeCamera` (`LUNE-ONLY` + data/structure `SEEN-IN-STUDIO`, `h/2026-11-17-cutscene-anchors/`); 2026-11-18 anchors corrected to the NPC front spots (Pak RT 68/47, Polisi -68/42, head height) and a pure `RaidCutscene.cameraFor` places the eye on the -z front outside all six hub footprints; 2026-11-19 zoom standOff 18→14 (police at 18 was occluded by `Tree_12.Canopy_2`); eye→target line of sight for all four shots `SEEN-IN-STUDIO` (`h/2026-11-19-review-fixes/raycasts.json`). Framing quality and the police NPC walk-in still `BLOCKED` on the designer's look-dev pass + authored NPC asset/animation (visual plan §8).
- [~] Raid and debt-collector cutscene state/event hooks (logic only) — `LUNE-ONLY`, `src/server/Npc/CutsceneHooks.luau`, wired in `src/server/Law/RaidService.luau` and `src/server/Economy/DebtCollector.luau`; full sinetron presentation still pending.

**G. Asset pipeline**
- [x] Asset manifest started.
- [x] Open Cloud key — verified by introspection 2026-11-14 (`ROBLOX_API_KEY`, never committed or printed).
- [~] Icon set (crops, tools, tiers, currency, phone apps); 6–8 hero textures. — code-side icon slot map and HUD/Phone/seed-bar wiring done (`LUNE-ONLY`, `src/shared/IconMap.luau`, `tests/specs/iconmap_spec.luau`, slot IDs empty / `NEEDS-ASSET`); upload and filled IDs still pending.

**H. QA and integration**
- [x] Thirty-minute client soak — `evidence/h/2026-11-14-soak/`.
- [x] Quest and Raid failure-path specs; fixed NaN progress completing quests, NaN login streak burning the daily claim, raid start/leave erroring on saves without `cooldowns`/`stats` — `LUNE-ONLY`, `tests/specs/quest_failure_spec.luau`, `tests/specs/raid_failure_spec.luau`.
- [x] Worker, Storage and Cheat failure-path specs; fixed NaN cash letting the buruh harvest and `trySpend` succeed, fractional/infinite gudang capacity, withdraw losing items when the sack table is missing, curi_air erroring without `cooldowns` — `LUNE-ONLY`, `tests/specs/worker_failure_spec.luau`, `tests/specs/storage_failure_spec.luau`, `tests/specs/cheat_failure_spec.luau`.
- [x] Evidence, Plot, Warung and Neighbor failure-path specs; fixed reports/cheat logs erroring without `cooldowns`/`stats`, tile prompt erroring on a save with nil `tilesOwned` or `tiles`, Nama Baik staying NaN and water erroring without `cooldowns` — `LUNE-ONLY`, `tests/specs/evidence_failure_spec.luau`, `tests/specs/plot_failure_spec.luau`, `tests/specs/warung_neighbor_failure_spec.luau`.
- [x] Save repair on load: `src/server/Data/SaveSanitize.luau` runs after Reconcile and migration, resets wrong-typed or NaN/inf template fields (one level into known tables), keeps dynamic keys and negative cash, warns once with the count — `LUNE-ONLY`, `tests/specs/save_reconcile_spec.luau`; not seen on a real damaged profile. Reason: forcing it would need a throwaway DataStore profile with corrupted fields (real save data in the dev place); the once-only warning is proven in Lune, the real load is a designer/test-place task.
- [x] Sus, Almanak, Season, Admin, Cosmetics and Leaderboard failure-path specs; fixed NaN Sus spreading through get/add/reduce, Almanak throwing on a damaged entry or string trait list, admin `grantItem` writing unknown item ids, Cosmetics erroring without `cosmetics`/`equipped`, a failed leaderboard read blanking the last good board — `LUNE-ONLY`, `tests/specs/sus_almanak_failure_spec.luau`, `tests/specs/season_admin_failure_spec.luau`, `tests/specs/cosmetics_leaderboard_failure_spec.luau`.
- [x] Receipts, Onboarding, Tool, Items, Cabai, Badges and Passes failure-path specs; fixed a receipt being acknowledged for an unknown grant type or a missing PurchaseId, ProcessReceipt erroring on a damaged `receipts` table, NaN item counts being spendable, ToolService erroring on a non-table `tools`, CabaiEvent starting twice — `LUNE-ONLY`, `tests/specs/onboarding_receipts_failure_spec.luau`, `tests/specs/tool_items_failure_spec.luau`, `tests/specs/events_badges_passes_failure_spec.luau`.
- [x] Strings integrity (every key has id and en, matching placeholders, every referenced key and `@key` exists) and config cross-reference specs; no defects found — `LUNE-ONLY`, `tests/specs/strings_integrity_spec.luau`, `tests/specs/config_crossref_spec.luau`.
- [~] Full-session `output.log` captured (`h/2026-11-19-gate1-studio/output.log`, zero game-code errors; Q2 still `UNVERIFIED` pending D-G4); fps on the phone emulator, ten-player session and published-place persistence still open.
- [ ] Five real players (designer).

### Parked for Phase 2 (do not start before Gate 1)

- Crop economy has no trade-off: profit per minute per tile rises in a straight line (padi 8 → sawit 96); only the cabai x3 event creates a choice. Needs the balance simulation (§6).
- Outside-audit ideas (gotong royong, koperasi, pasar mingguan, proyek desa): see `docs/improvements/SINTESIS.md` §4.

## 0. The one rule above all others

**It has to be a game.** Playable, fun, solid, tested, with no stupid bugs: an actual product a
stranger can pick up and enjoy. A small game that works beats a big one that does not. Every
other section of this plan is in service of this, and when anything conflicts with it, this wins.

### The MVP

The MVP is the smallest version of Juragan Desa that is a complete, fun game on its own. It must
exist and be solid before anything else is added.

| In the MVP | Must be true |
|---|---|
| Core loop: plant, grow, harvest, sell, buy seeds, expand the plot | Works every time, on phone and desktop, alone or with ten players. Feels good. |
| Rarity reveal | Every tier shows correctly; the top tiers are a moment. |
| One real village | Built map, lighting, icons, sound. No placeholder visible. |
| Progression: ranks, tools, gudang, daily tasks | Always a clear next goal for at least the first few hours. |
| The satire core: cheating, Sus, raid, bribe, BayarLater and the debt collector | Each works start to finish and is funny. |
| First session (section 4) | A stranger finishes it without help. |
| Saving | Progress survives leaving, rejoining, crashing and server shutdown. |

**Anything not on this list, and anything on it that is not solid, is switched off** behind a
LiveConfig flag until it is. A feature that half works is hidden, not shipped. Existing systems
that are outside the MVP (seasons effects, market pressure, buruh, almanak, leaderboards,
cosmetics, passes) stay in only if they pass the bar below; otherwise they are flagged off and
come back one at a time.

### The quality bar

A build is a product only when all of these hold. Track H checks them and nobody overrides them.

1. **No blocker or major bugs known.** Blocker: crash, soft lock, lost progress, lost or duplicated money or items, a core action that fails. Major: anything a player notices and is annoyed by in a normal session. Both are fixed before any new work continues.
2. **Zero errors and zero warnings** in the server and client Output through a full session.
3. **Every button does something, every screen can be closed, every state can be left.** No dead ends: dying, resetting, rejoining mid-raid, mid-loan, mid-minigame, with a full sack, with zero cash and zero seeds all recover.
4. **Broke-player check:** a player with no cash, no seeds and no crops can always get going again.
5. **Thirty-minute soak** with the harness, and a ten-player session, with no leak, no desync and no stuck state.
6. **Persistence verified** in a published test place with real DataStores, not only in Studio.
7. **Works on phone:** touch only, small screen, mid-range device frame rate.
8. **Every defect gets a regression test** where the logic can be tested in Lune, before the fix is merged.

**Bugs come first.** A known bug outranks any feature, polish or art task in every track. Track
H keeps one list, `docs/testing/BUGS.md` (id, severity, steps, owner track, status), and it is
the first thing every agent reads at the start of a session.

## 1. Where the game really is

> Written 2026-11-14 at the start of Phase 0; kept as the original diagnosis. The current state is
> the **Progress tracker** at the top of this file.

| Fact | Consequence |
|---|---|
| About 30 systems and 481 passing Lune tests. | The logic is ahead of everything else. More systems will not make the game better right now. |
| No human has ever played it. The one Studio run (2026-11-13) could not plant a crop, take a screenshot, or save data. | Every "VERIFIED" in the audit docs (FTUE, balance, perf, localization) means "reasoned about", not "seen running". Treat them as unverified. |
| The world is still built by `World/Greybox.luau`. Every icon, texture, sound and product ID is `0`. | The player sees grey parts, emoji-era UI and silence. This is the biggest gap between the game and a real game. |
| The satire (raid, pinjol collector, bribes) is the game's best idea and a new player meets none of it in the first session. | The first ten minutes are a generic farming tutorial. |
| Most of M4, the audits and the art pass are uncommitted in one working tree. | Parallel agents cannot start until this is committed. |

## 2. Direction

**North star:** a stranger on a phone laughs within three minutes, sees something they want to
show a friend within ten, and has a reason to come back tomorrow.

**Priority order (designer, 2026-11-14):** 1. Fun. 2. Looks and sound. 3. Depth. 4. Social drama.
All four get built; the order decides who waits when two things compete.

**Launch:** when the gates in section 6 pass, not on a date and not after a fixed list of
releases. This replaces D3.

### Rules every agent follows

1. **Seen running, or not done.** A change is done when it has been observed in a Studio playtest
   and the evidence is saved (section 7). Lune tests are required and are not enough.
2. **Feel before features.** No new gameplay system is started before Gate 1 passes. Until then
   every hour goes into making what exists feel, look and sound great.
3. **The satire is the product.** If a screen, sound or line could belong to any farming game,
   it is not finished. Indonesian specifics, per `visual/ART.md` pillar 4 and D7 (fictional names, real stereotypes).
4. **Phone first.** Judge every change on the mobile emulator at phone size before desktop.
5. **Cut rather than fake.** Report a smaller thing that works instead of a bigger thing that might.
   Never invent asset IDs, product IDs, prices, UserIds or Roblox policy.
6. **Server decides everything.** `TECH.md` ground rules and the monetization guardrails in
   `plan/PLAN.md` §3.7 do not change.

## 3. Phase 0 — Make the repo safe for parallel work

One agent, alone, before anyone else starts. Nothing here is optional.

| # | Task | Done when |
|---|---|---|
| 0.1 | Commit the working tree in topical commits (M4 remainder, audits, art pass, tests). Ask the designer before committing. | `git status` is clean; `lune run tests/run.luau` passes. |
| 0.2 | Fix the known Studio failures: wrong asset type `rbxassetid://203785492`, Clouds not under Terrain, Greybox terrain stacking on rebuild. | A Play Solo run shows zero errors and zero warnings in Output. |
| 0.3 | Build the playtest harness: a documented Studio MCP routine that starts a play session, plants, harvests, sells, buys, and captures screenshots at desktop and phone size. The 2026-11-13 run could not trigger prompts; solve that first (test-only server hooks behind a Studio-only flag are acceptable). | `docs/testing/HARNESS.md` exists and a second agent can follow it to produce screenshots of the full loop. |
| 0.3b | Bug sweep: play every MVP flow in section 0 through the harness, including the dead-end cases in the quality bar, and open `docs/testing/BUGS.md` with everything found. Flag off any non-MVP system that fails. | The bug list exists with severities and owner tracks; flagged-off systems are listed in it. |
| 0.4 | Record the baseline: screenshots and timings of the current first ten minutes on phone size. | Saved under `docs/v2/evidence/baseline/`. This is what "better" is measured against. |
| 0.5 | Set up the tool pipeline (section 5, track G scouting): confirm Blender MCP export to Roblox, decide how assets get uploaded and who presses the button. | `docs/v2/plan/TOOLS.md` lists each tool, its licence terms, and the upload route. |

## 4. Phase 1 — The great ten minutes

Goal: the first ten minutes are the best ten minutes of any Indonesian Roblox game. Everything
in this phase serves the beat sheet below. Tracks in section 5 run in parallel.

### First-session beat sheet (target, tune in playtests)

| Time | Beat | What the player feels |
|---|---|---|
| 0:00 | Spawn on your plot at golden hour. Village sounds, music, an NPC calls you over. No menu. | "This looks good." |
| 0:15 | First plant. One tap, satisfying dig, soil flies, sound. | Control. |
| 0:45 | First harvest. The tutorial padi grows in about 20 seconds, not 60. Guaranteed *Bagus*. | First reward. |
| 1:30 | Sell at the Pasar. A thermal *struk* prints, cash flies to the HUD. | Money is fun. |
| 2:30 | Buy seeds from a rotating shelf; plant a full row. The phone buzzes: BayarLater offers a loan. | Temptation, first joke. |
| 4:00 | Second harvest: a guaranteed *Super* or *Langka* reveal with the full sting. | "Whoa." |
| 5:30 | A scripted NPC neighbour gets raided: the full sinetron cutscene, seen as a spectator. | The hook. "That can happen to me?" |
| 7:00 | A rumour at the warung or a whisper from the Tengkulak Gelap. Never an instruction. | Curiosity about cheating. |
| 9:00 | Rank up to Petani with a ceremony. A slow kebun crop is planted and will be ready later; daily tasks appear. | A reason to return. |

Rules for the beat sheet: the tutorial still never tells the player to cheat (`plan/PLAN.md` §3.1);
guaranteed outcomes are first-session only and decided by the server; no wait longer than ten
seconds without something to do or watch.

### Gate 1 — the MVP gate, exit criteria

- The MVP list in section 0 is complete and the whole quality bar in section 0 passes.
- `docs/testing/BUGS.md` has no open blocker or major bug.

- The harness plays the full beat sheet on phone size with zero Output errors or warnings.
- Nothing visible in the first ten minutes is a placeholder: no greybox part, no emoji, no missing icon, no silent action.
- Time to first harvest is under 45 seconds, first rarity reveal under 5 minutes, raid witnessed under 7 minutes.
- All text a player sees, in the world and on the HUD, is readable at phone size: no overlapping labels, no clipped text, nothing hidden under the HUD (BUG-006, BUG-008, BUG-009). Added 2026-11-14 after the designer's phone playtest; it is part of 'no placeholder visible', made explicit.
- Measured on a real phone by the designer (Xiaomi 12 Lite, 2026-11-14, self-reported): about 30 fps at maximum graphics and 60 fps at the lowest. Recorded in `docs/v2/evidence/h/2026-11-14-perf/DESIGNER_PHONE_REPORT.md`; the 60 fps target must hold at the device's default quality.
- Frame rate and instance count are measured on the phone emulator and recorded; the target is 60 fps on mid-range Android (`visual/ART.md` §5).
- Five real people play ten minutes on their own phones without help. The designer runs this. Their confusion points are fixed or logged.

## 5. Tracks (parallel)

Each track is one agent, or one agent at a time, in its own worktree and branch
(`track/<letter>-<slug>`). A track owns its files; nobody else edits them.

| Track | Mission | Owns | Key deliverables |
|---|---|---|---|
| **A. Game feel** | Every core action feels great: plant, grow, harvest, sell, buy, reveal. | `src/client/Minigames/*`, `src/client/UI/Tiles.luau`, `src/client/UI/Minigame.luau`, new `src/client/Feel/*` | Hit feedback, tweens, particles, camera nudges, haptics, cash-fly, visible crop growth stages, rarity reveal sequence per `visual/ART.md` §7 and §9. |
| **B. First session** | Implement the beat sheet. | `src/server/Progression/OnboardingService.luau`, new `src/server/Progression/FirstSession*.luau`, onboarding entries in `Config` | Beat-sheet script, guaranteed first-session outcomes, scripted NPC raid, rank-up ceremony, return hook. Analytics funnel step per beat. |
| **C. World** | Replace the greybox with a real village. | `JuraganDesa.rbxl` (the only track that saves the place file), `src/server/World/*`, `src/client/World/*`, `Config/Seasons.luau` lighting values | Map built to the tag contract in `TECH.md` §3, terraced sawah and river in Terrain, five hubs each with a landmark and accent colour, set dressing, three season lighting presets, `Greybox.luau` retired to a test fallback. |
| **D. UI** | Rebuild every screen on the approved kit. | `src/client/UI/*` except the files owned by A | HUD, shop (spanduk), phone (app grid, BayarLater, chat), surat (raid, fines), struk, quest calendar, per D1 redirects. Image icons everywhere. Phone size first. |
| **E. Audio** | The village is never silent. | `src/client/Audio.luau`, `src/shared/Config/Audio.luau` | Music per area, weather ambience, UI sounds, tier stings, raid sting, collector voice barks. Sources: Roblox licensed catalogue first. Mix levels checked on phone speakers. |
| **F. Characters and cutscenes** | NPCs with personality; the raid as a show. | `src/server/World/NpcFactory.luau`, `src/client/UI/RaidOverlay.luau`, new `src/client/Cutscene/*`, `docs/v2/visual/art/npcs.md` | Caricature NPCs from design cards, idle and talk animations, the sinetron raid cutscene (`plan/PLAN.md` §3.1), the debt collector scene at the plot. |
| **G. Asset pipeline** | Produce and deliver every asset the other tracks ask for. | `docs/v2/visual/art/*`, `docs/v2/plan/TOOLS.md`, `src/shared/Config/Visuals.luau`, `src/client/UI/Icons.luau`, an `assets/` source folder | Icon set (crops, tools, tiers, currency), 6 to 8 hero textures, modular building kit and props via Blender MCP, Toolbox finds restyled to the palette. An asset manifest mapping every slot to an ID, source and licence. |
| **H. QA and integration** | Keep `master` green and prove things work. | `tests/*`, `docs/testing/*`, `docs/v2/evidence/*`, merges into `master` | Runs the harness on every merged track, owns the Studio queue, measures performance, files defects back to the owning track, keeps the evidence index. |

### Shared files

These are touched by many tracks. Rules instead of owners:

| File | Rule |
|---|---|
| `src/shared/Strings.luau` | Append only, both ID and EN, keys prefixed by track area. Never reorder or rename existing keys. |
| `src/shared/Remotes.luau` | Append only. A changed contract needs a written reason in the PR. |
| `src/server/Main.server.luau`, `src/client/Main.client.luau` | One line per new module; track H resolves conflicts. |
| `src/client/UI/Theme.luau` | Track D only. Others request components from D. |
| `src/server/Data/PlayerData.luau` | Schema changes only through a migration with a test, announced to track H before merging. |
| `JuraganDesa.rbxl` | Track C only. It is binary and cannot be merged. Everyone else leaves it unsaved. |

### Assets and outside tools (track G, with the designer)

- **Order of preference:** Roblox Toolbox and licensed catalogue, restyled → made in Blender via MCP → generated by an outside tool and cleaned up.
- **Every asset has a manifest row:** slot, source, licence, who approved it. No row, no merge.
- **Outside tools:** track G may research and propose tools (image, 3D, audio generation) in `plan/TOOLS.md` with their commercial-use terms. Creating accounts, accepting terms, paying, or connecting a new MCP server is the designer's step, not the agent's.
- **Uploads:** agents prepare files; the designer uploads or approves the upload route, then the ID goes into the manifest and config. IDs stay `0` until then and the UI must degrade cleanly.
- **Never:** commercial music, ripped game assets, real people's faces or names (D7), real brand logos.

## 6. After Gate 1

Each phase has a gate. No phase starts before the previous gate passes.

### Phase 2 — Depth: hours 1 to 20

`plan/BALANCE.md` only models progress up to Juragan at about one hour. This phase answers "what do I
do after that?" using systems that already exist before adding new ones.

- Rebuild the balance model as a runnable Lune simulation checked against real playtest timings, then tune `Config` against it.
- Long goals: Almanak completion rewards, kebun and perkebunan crops, the sawit permit and hill concession, tool tiers, plot expansion beyond 12 tiles.
- Hidden cheats on the discovery model and the informant NPC (`plan/PLAN.md` §4.4).
- **NPC neighbours who cheat**, pulled forward from v3: a new game has near-empty servers, and the report and raid loop must work with one player online.
- Housing and plot decoration as the visible status goal and main cosmetic surface (`plan/PLAN.md` §5).

**Gate 2:** a tester plays three sessions on three days and can name their next goal each time; the simulation and observed income per minute agree within a stated margin.

### Phase 3 — Social drama

Kepala Desa, Dana Desa, proyek mangkrak, serangan fajar, the election count, the cross-server
viral ticker (`plan/PLAN.md` §4), then trading, stealing, security and hush money (`plan/PLAN.md` §5).
Spec first, per the format in `archive/HANDOFF_ROADMAP.md` phase C. Roblox policy on trading and paid
random items is verified from primary sources before any code.

**Gate 3:** a ten-player test server produces an election, a corruption report and a raid without admin help, and the alt-account and spam scenarios in `qa/SECURITY_AUDIT.md` are re-run against the new remotes.

### Phase 4 — Launch readiness

Real product IDs and prices (D9), receipt tests in a live test place, maturity questionnaire
answered by the designer, icon and thumbnails and a raid clip from real footage, a re-run of
security, performance and localization audits with runtime evidence, then a soft launch to a
small audience before going public.

**Launch gate:** all earlier gates pass, DataStore persistence is verified in a published test place, purchases grant exactly once in a live test, and the designer says go.

Livestock, empang, processing, seasonal events and seed crates (`plan/PLAN.md` §6) come after launch, steered by player data.

## 7. How work is proven and reported

**Status words.** Use exactly these in every report:

| Word | Meaning |
|---|---|
| `SEEN-IN-STUDIO` | Observed in a play session; evidence saved. |
| `LUNE-ONLY` | Unit tests pass; not observed running. |
| `UNVERIFIED` | Written, not run. |
| `BLOCKED` | Needs the designer or another track; say which. |

**Evidence.** `docs/v2/evidence/<track>/<yyyy-mm-dd>-<slug>/` holding screenshots at phone and
desktop size, the Output log, and a `REPORT.md` of at most twenty lines: what changed, status
word per item, what was not checked, decisions needed.

**Definition of done for any task:**

1. `lune run tests/run.luau` passes; new logic has a spec; no test removed or weakened.
2. Observed in Studio at phone size with zero new Output errors or warnings.
3. Before and after screenshots saved for anything visible; a short clip description for anything that moves or sounds.
4. Player text is in `Strings.luau` in ID and EN; the EN explains the reference.
5. Only the track's own files and the shared files (by their rules) are touched.
6. Merged by track H, not by the author.

**Studio access.** If only one Studio session is available, track H runs the queue: tracks ask for
a slot, H runs the harness on their branch and returns the evidence. If each agent has its own
Studio, each still uses the harness and never saves the place file unless it is track C.

**Decisions.** When blocked on a designer decision, do not guess and do not stop: log it in the
report with options and a recommendation, add a row to `plan/DECISIONS.md` as `open`, and continue
with unblocked work.

## 8. Hard rules

- Do not revert or overwrite another track's work. **Always commit finished work** (designer, 2026-11-14): topical commits, tests passing, tracker ticked in the same commit; no attribution lines, then push to the working branch (`AGENTS.md`, 2026-11-16).
- Do not publish, change experience settings, create products, or spend Robux or money.
- Do not start a system from Phase 2 or later before its gate, even if it looks easy.
- Do not mark anything `SEEN-IN-STUDIO` without the evidence folder.
- Save data changes go through `PlayerData.migrate` with a fixture test.
- Nothing sold blocks a raid, clears a VIRAL case, or is random.

## 9. Open decisions for the designer

1. Upload route for assets: designer uploads by hand, or an Open Cloud key the designer creates for track G.
2. One Studio session shared through track H, or one per agent.
3. Fonts for display and body (`visual/ART.md` §12), chosen on a phone once track D has both on screen.
4. D9 product IDs and prices: needed for Phase 4, not before.
5. Admin UserIds (D10) for the playtest place.
