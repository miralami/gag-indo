# Juragan Desa — Master Plan

> Written 2026-11-14. This is the single direction for every agent working on this repo.
> It supersedes `archive/HANDOFF_ROADMAP.md` and `archive/HANDOFF_ART_PASS.md` for ordering and priorities.
> `plan/PLAN.md` stays the feature reference, `visual/ART.md` the art bible, `TECH.md` the code conventions,
> `plan/DECISIONS.md` the designer's decisions. Where this file disagrees with them on *what comes
> first* or *what counts as done*, this file wins.

## Progress tracker — read first, update last

**Last updated:** 2026-11-21 — WORK_QUEUE section M (round 9) in progress: M1 tools items 68–69 COMPLETE, M2 items 70–73 COMPLETE — `hubveg_r8` per-hub vegetation: 96 slots (16/hub × 6 hubs), 9 species, clone-first baked assets; real Studio PASS for all six `VEG_HUB_*` (16 ≥12), `VEG_SPECIES_HUB` (min=9 ≥4), `VEG_OVERLAP` (0 0) (`CHECK_70.txt`). `plots_r8` procedural plot fences + gate arches: 10 plots × 8 fence segments + 3 gate parts, no asset IDs; real Studio PASS `PLOT_FENCE` (min=8 ≥6), `GATE_CLEAR` (0 hits/10 gates) (`CHECK_71.txt`). `sawah_r8` procedural terrace dressing: 4 water sheets × 2 panes, 240 verge blades (80 tufts ×3), 1 gubuk, 3 stepping stones, no asset IDs; real Studio PASS `SAWAH_TOPS` (0 0.5), `SAWAH_WATER` (4 sheets), `SAWAH_VERGE` (240 ≥40), `GUBUK` (1 1) (`CHECK_72.txt`). `river_r8` bank vegetation + bridge rails: 84 veg (56 near bridge, both banks), rails both sides with an 8-stud clear deck, 6 stepping stones, no asset IDs; real Studio PASS `RIVER_BANK_VEG` (56 ≥30), `BRIDGE_RAILS` (2/2), `BRIDGE_WALKABLE` (8 ≥8), with 50 ids (`CHECK_73.txt`). `pathedge_r8` procedural dirt-path borders: 618 pieces (309 grass tufts, 283 pebbles, 26 puddles at Transparency 0.4) on both edges of all 4 arms + 56 ring segments + 2 continuations, no asset IDs; real Studio PASS `PATH_EDGE` (618 ≥120), `PATH_CLEAR` (0 intruders across 62 paths), with 51 ids (`CHECK_75.txt`). `water_r8_a/b/c` river water looks: 3 OFF-by-default CLIENT candidates tuning only the 5 Terrain water properties (clear tropical green / murky brown after rain / bright turquoise), pure data safe ranges + exact save/restore, no asset IDs; real Studio CLIENT-VM PASS `WATER_SAFE` (3/3 variants in range), `WATER_RESTORE` (3/3 exact restore of all 5 values), with 54 ids and no place saved (`CHECK_76.txt`). r8 check harness with `LOOKDEV_LEAK` PASS 0 leaks, and 26 MapSpec-derived review cameras with `CAMERA_CLEAR` PASS 0 blocked/26; see the section M entries below. Section L (round 8, items 61-67) COMPLETE — all real-Studio CHECK lines PASS (CLOUD_COVER, BED_FLUSH, VEG_NEAR, PROP_SIZE); see the section L entry below. Item 74 `ring_r8` BLOCKED — `NO_PINES` FAIL 254 0 in the default look (shipping `BackgroundForest` pines; two clean attempts, check not weakened), needs a designer scope decision (`CHECK_74.txt` + WORK_QUEUE "Decisions for designer"). Remaining section M (items 77-101) queued for the long unattended run: 30+ LookDev candidates across land, water, buildings, hubs, life, light and sound, plus audits. Earlier: WORK_QUEUE section L (round 8, items 61-67) was queued: cloud cover hiding sky E, flower-bed mounds, near-ground vegetation, better prop models. Earlier: round-7 Studio review (`h/2026-11-21-review-round7/`). The npcs_r7 villagers now wear designer-picked catalog outfits (`h/2026-11-21-catalog-outfits/`), with 2343 tests passing. Earlier: 2026-11-20 — round-6 designer verdicts recorded from real Studio shots (`h/2026-11-20-review-round6/`): sky_r6_e and spawn_ground_r6 were chosen. Root cause of the missing hats and the sparse vegetation: runtime LoadAsset is not authorized for unowned Creator Store models, while Edit-mode GetObjects works. WORK_QUEUE section K (round 7, items 53–60) COMPLETE — all eight real-Studio checks PASS; see the section K entry below. Earlier: WORK_QUEUE section J items 44–52 COMPLETE. Item 44: six OFF-BY-DEFAULT Creator Store sky candidates `sky_r6_a`..`sky_r6_f` wired — six real free Models, 36 face IDs read from a Play-Solo Server VM and recorded in `h/2026-11-20-sky-r6-asset-load/REPORT.md` (`SEEN-IN-STUDIO` for the load only), one shared humid atmosphere + sun/ray/bloom/CC stack, one saved ~20° camera. Item 45: `spawn_ground_r6` server candidate — tanah Parts over the FULL road corridor including the 30-wide back ring strip R5 left dark, `FloraGrass` wedges masked off flower beds and tagged plots, exact Visible/CanCollide restore, default generators untouched. Item 46: two OFF-BY-DEFAULT CLIENT candidates `terrain_r6_a`/`terrain_r6_b` — Terrain-wide texture override dropped; built-in Grass/Ground/Mud colours tuned via pcall-guarded `SetMaterialColor` with exact restore; CC0 maps kept on parts/meshes only; saved camera `{0,20,72}`→`{0,5,14}`. All verdict cells blank; `sky_r5` unchanged as the round-6 baseline. Final suite 2332 passing; `selene src` 0/0/0; focused stylua and `git diff --check` clean; `LookDev.IDS` = 43. Items 47–52 complete (below); no Gate 1 row became agent-closable. Item 47 prep: `KAMPUNG_VEGETATION.md` + 25 real Creator Store IDs in `h/2026-11-20-r6-vegetation-ids/REPORT.md`; item 48 Route B finding in `h/2026-11-20-r6-costume-research/REPORT.md`. Round-5 designer verdicts recorded from real Studio shots (`h/2026-11-20-review-round5/`); WORK_QUEUE section J (round 6, items 44–52: Creator Store sky comparison with six real free IDs, ground fix, terrain rethink, kampung vegetation, role costumes, designer kit and terrain brief, real-size props) queued. The designer composes spawn and sculpts the terrain himself. Earlier: WORK_QUEUE section I items 35–43 COMPLETE (long-run closed). Item 43 refill re-read this tracker, WORK_QUEUE, `BUGS.md` and `GATE1.md`: no blocked item is agent-closable; all remaining blockers are licensed real IDs / Open Cloud uploads / designer-vision verdicts / designer hardware (phone, five humans, published place, multi-client Local Server). Single final report with commits, blockers and decisions at `h/2026-11-20-final-report/FINAL_REPORT.md`. `BUGS.md` has no open blocker/major defect; GATE1 rows still 2 BLOCKED / 1 LUNE-ONLY / 8 UNVERIFIED. (At item 43 close: final suite 2248 passing; `selene src` 0/0/0; focused stylua and `git diff --check` clean; `LookDev.IDS` = 31.) No place saved or published. Earlier in section I: items 35–42 complete. Item 35: `textures_r4` darkening fixed by neutralising Terrain material colours while the CC0 base-material override is live and restoring exact originals on disable (`h/2026-11-20-textures-r4-fix/REPORT.md` has live before/during/after reads). Items 36–39: four new OFF-BY-DEFAULT candidates wired and spec'd — `spawn_ground_r5` (feathered tanah paths, road default untouched), `vegetation_r5` (pisang/dense bamboo, no kelapa or pines, exclusion zones, R4 IDs), `sky_r5` (bright humid sky from two reused real CC0 HDRIs, Clouds.Cover 0.4, no ridge, seam fix), `props_r5` (right-sized tools, contextual gudang karung stack, R4 IDs). Item 40: `npcs_r5` solid upright R15 villagers from body-colour HumanoidDescriptions plus three real free Creator Store hat Models (creators/URLs in `art/models_r5/npcs/MANIFEST.md`); peci/batik/sarong noted as Designer builds, no ID invented. Item 41: `spawn_r5` off-by-default dressing pass composes only approved/temporary assets (temporary gudang+warung, jemuran, contextual gudang karung stack, rescaled tools, pisang + dense bamboo, 5 R15 villagers) from the R4/R5 source maps; tier budgets 50/100/150 instances and 50k/100k/150k tris (Sedang default ~23/58k est.), north-road corridor kept clear, saved camera `{0,20,72}->{0,5,14}` in `SPAWN_DRESSING_R5.md`; spec `tests/specs/spawn_dressing_r5_spec.luau`. Item 42: round-5 review handoff written at `h/2026-11-20-review-round5/REVIEW_ROUND5.md` + `REVIEW_ROUND5.html` and `docs/v2/visual/REVIEW_ROUND5.md`; all 8 candidates enable in a fresh Play VM, saved cameras sightline-checked in VM (props_r5 honestly flagged as pine-screened), verdict cells blank, no screenshot claim (pixels unobtainable this session). All verdicts blank. Earlier the same day: designer verdicts on round 4 recorded from real Studio shots (`h/2026-11-20-review-round4/STUDIO_REVIEW.md`); WORK_QUEUE section I (round 5, items 35–43: texture fix, dirt-path spawn ground, vegetation cleanup, Indonesian sky, props, R15 characters, spawn dressing) queued. Earlier: WORK_QUEUE section H (round 4, items 28–34) complete. All seven round-3 review bugs fixed with regression specs (`tests/specs/review_round3_bugfix_spec.luau`, including the throwing-root `LookDevReview` cases). `textures_r4` (12 CC0 base-material override sets / 36 Image IDs), `sky_r4_a/b/c` (3 CC0 HDRIs / 18 cube faces, one face verified in a fresh Play Client VM) and four textured r4 model families (21 real CC0/CC BY Model IDs) integrated off by default with blank verdicts; `SPAWN_DRESSING.md` planning brief written. `REVIEW_ROUND4.md` plus the description-based `docs/v2/evidence/h/2026-11-20-review-round4/REVIEW_ROUND4.html` and `REPORT.md` capture all eight candidates from the saved cameras via the vision observer with blank verdicts and an explicit "not a screenshot claim" note — no screenshot pixels were retained, so no image is embedded; Play stopped, nothing saved or published. All 75 r4 IDs licence-audited CC0/CC BY with attribution; banned sources absent. `LookDev.IDS` = 31. Item 34 re-checked items 12/14/15/16 — all remain `BLOCKED` (blank verdicts, no approved look, missing L7.1 VFX assets, unrigged police dummy, designer hardware). After item 41: 2248 passing; `selene src` 0 errors / 0 warnings / 0 parse errors; focused stylua and `git diff --check` clean. Previously item 40 2232; items 36–39 2219; item 35 2177; before that 2173.

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
