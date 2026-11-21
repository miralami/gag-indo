# Round-9 check harness — REVIEW_ROUND9.md (WORK_QUEUE section M)

Session: `<fill: Studio session name / placeId>`. No place is saved or published in this round.
Harness fix (2026-11-21): `bboxAABB`/`bboxCentre` now measure single BasePart/MeshPart assets (teh-tehan) directly instead of returning nil; VEG_OVERLAP still requires `unreadable == 0`. Re-run needed in Studio.

## 1. Edit-mode bake (step 1)

Stop Play. Run `tools/studio/bake_lookdev_assets.luau` in the EDIT datamodel via Studio MCP `execute_luau`. The bake is runtime-only: NEVER save the place after it. Verify `ServerStorage.LookDevAssets` is empty after a no-save restart, as in round 8's process fix.

## 2. Run order for `review_check_r8.luau`

Start a fresh real Play session after the bake. Paste the WHOLE file into Studio MCP `execute_luau` in this order:

1. SERVER datamodel — scene checks: `LOAD_FAILURES`, `SKY_DEFAULT`, `GRASS_ON_BEDS`, `HATS`, `PROPS_VISIBLE`, `PROPS_ON_GRASS`, `VEG_COUNT`, `VEG_SPECIES`, `BED_FLUSH`, `VEG_HUB_pasar`, `VEG_HUB_gelap`, `VEG_HUB_warung`, `VEG_HUB_ronda`, `VEG_HUB_polisi`, `VEG_HUB_pakrt`, `VEG_SPECIES_HUB`, `VEG_OVERLAP`, `PLOT_FENCE`, `GATE_CLEAR`, `SAWAH_TOPS`, `SAWAH_WATER`, `SAWAH_VERGE`, `GUBUK`, `RIVER_BANK_VEG`, `BRIDGE_RAILS`, `BRIDGE_WALKABLE`, `PATH_EDGE`, `PATH_CLEAR`, `VEG_NEAR`, `PROP_SIZE`, `CAMERA_CLEAR`, `LOOKDEV_LEAK`. The three r8 hub-veg families (item 70) read the staged `LookDevModelsVegetationHubR8_hubveg_r8` folder; they FAIL at measured 0 in a clean Play when that candidate is not staged. The two r8 plots families (item 71) read the staged `LookDevPlotsR8_plots_r8` folder; `PLOT_FENCE` and `GATE_CLEAR` FAIL in a clean Play when that candidate is not staged. `GATE_CLEAR` probes the opening in the marker's own CFrame (plot yaw), lifted 0.05 above the ground surface to avoid touching the collidable ground slab. The four r8 sawah families (item 72) read the staged `LookDevSawahR8_sawah_r8` folder; all FAIL at measured 0 in a clean Play when that candidate is not staged. `SAWAH_TOPS` raycasts Terrain only at the eight `MapSpec.paddyWater()` pane centres (a missing Terrain/read is a FAIL); `SAWAH_WATER` requires four water-sheet groups of two valid panes; `SAWAH_VERGE` requires >=40 verge tufts; `GUBUK` requires one terrace-2 roof with four posts and one bench sharing its `Gubuk` id. The three r8 river families (item 73) read the staged `LookDevRiverR8_river_r8` folder and `MapSpec.BRIDGE`; all FAIL at measured 0 when the candidate is not staged or MapSpec cannot be read. `RIVER_BANK_VEG` requires >=30 veg within 40 studs of the bridge centre on both banks; `BRIDGE_RAILS` requires both sides to have a deck-spanning rail and >=4 posts; `BRIDGE_WALKABLE` requires both sides and a clear |x|<4 corridor with walkable width >=8. The two r8 path-edge families (item 75) read the staged `LookDevPathEdgeR8_pathedge_r8` folder and the real `MapSpec` road geometry (four arms, two continuations, 56 ring chords); both FAIL when the candidate is absent or MapSpec cannot be read. `PATH_EDGE` requires >=120 candidate Parts; `PATH_CLEAR` requires no staged Part inside the central 6 studs of any path (non-collidable intruders are reported in detail only).
2. CLIENT datamodel — client-owned checks: the same lines where observable, plus `CLOUD_COVER`, `WATER_SAFE` and `WATER_RESTORE`. Run water, grade, sounds and clouds candidates here; `LOOKDEV_LEAK` must also be run in this datamodel for client-owned candidates. `WATER_SAFE` and `WATER_RESTORE` (item 76) are CLIENT-only: each enables `water_r8_a/b/c` once, reads the five Terrain water properties, disables, and checks range/exact restore against a baseline read before any enable. Both FAIL at measured 0 if Terrain or the baseline cannot be read, and the prior active candidate is re-enabled when the cycle ends.

`CAMERA_CLEAR` (item 69) is SERVER-ONLY: it loads `ReviewCameras`, which requires MapSpec from
`ServerScriptService`, so the check is skipped in the Client VM to avoid a `WaitForChild` block.

## 3. Reading CHECK lines

Every line is `CHECK <name> PASS|FAIL <measured> <target>`. `PASS` means `measured` met `target`; `measured` may be a number or a formatted string. `FAIL` is an objective failure, not a visual verdict. The call returns `{ order = ..., checks = ..., byName = ... }`; each check carries its raw `detail`.

## 4. Item-77 run — buildings_r8 (WORK_QUEUE section M)

Ordered steps. No place is saved or published.

1. Stop Play. Because Rojo has not synced the new/changed modules, inject them into the Edit datamodel at runtime (not saved to the place): `ReplicatedStorage.Shared.ModelMapBuildingsR8` and the changed `ReplicatedStorage.Shared.LookDev`, `ReplicatedStorage.Shared.LookDevReview`; and `ServerScriptService.Server.Main.server` plus `ServerScriptService.Server.World.LookDevBuildingsR8`. Confirm the six baked building folders for the `BuildingSlot` set exist under `ServerStorage.LookDevAssets` — `LookDevAssetLoader` needs them, so a missing folder is a load failure rather than a geometry result.
2. Start a FRESH real Play session after the injection (do not reuse a session that already staged another candidate).
3. In the SERVER datamodel, stage via `require(game.ReplicatedStorage.Shared.LookDevReview).enable("buildings_r8", game)`.
4. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER VM. Capture `BLDG_VISIBLE`, `BLDG_WIDTH` and `BLDG_DOOR` plus the guards `LOAD_FAILURES` and `LOOKDEV_LEAK`. Targets: 6/6 building Models inside the review-camera cone, 6/6 world bbox widths in [12,60], 6/6 DoorGauges with `Size.Y >= 7` and zero collidable building geometry intersecting the gauge's oriented volume (`GetPartsInPart`); guards 0 load failures and 0 leaks. A missing folder, camera attribute, model or gauge FAILs at measured 0 — never a skip.
5. Stop Play without saving. `CAMERA_CLEAR` is SERVER-only (`ReviewCameras` requires MapSpec from `ServerScriptService`, so it is skipped in the Client VM). The Client-VM cloud/water lines (`CLOUD_COVER`, `WATER_SAFE`, `WATER_RESTORE`) are out of scope for this server-side run.

**Fix note (2026-11-21, run notes only — no Studio result claimed).** Earlier live Studio runs showed 20-stud centre spacing caused neighbour occlusion (`BLDG_VISIBLE` 4/6) and world-AABB door overlap false-positives on rotated roof panels (`BLDG_DOOR` 3/6); those were addressed by 20 studs of clear gap with gap-derived centres, a model-free 340x80 site scan, and rotation-aware `GetPartsInPart` for gauge placement and the harness check. Two further root causes are now confirmed:

1. `BLDG_DOOR` 3/6 — `apply()` staged the model before parenting it into the Workspace folder, so `GetPartsInPart` saw zero building parts and the first ladder candidate always won. The applier now sets `model.Name` and `model.Parent = folder` **before** `stage(...)`; a parenting failure counts a failure and `continue`s, never staging an unparented model. Gauge ladder, probe, harness and CanCollide/Size filters unchanged; no building `CanCollide` cleared.
2. `BLDG_VISIBLE` 4/6 — the former +Z camera rule put shipping `PosPolisi`/`RumahPakRT` parts between camera and row. A harness sweep of the same cone/raycast logic verified camera `(0,60,-200)` looking at `(0,16,28)` gives 6/6; other sampled positions failed. The camera rule is now signed `front=-228, up=60, lookY=16` (min-Z facade side). Harness cone, 6/6 target, raycast filters and site scan unchanged.

Required fresh Play verification: re-inject `ModelMapBuildingsR8` and `LookDevBuildingsR8` (plus `review_check_r8.luau` if it changed); stop Play; start a fresh real Play session; confirm the six baked `BuildingSlot` folders under `ServerStorage.LookDevAssets`; stage via `LookDevReview.enable("buildings_r8", game)`; capture `BLDG_VISIBLE`, `BLDG_WIDTH`, `BLDG_DOOR`, `LOAD_FAILURES`, `LOOKDEV_LEAK` and `CAMERA_CLEAR`. No place save, no publish. Until that run is captured, no PASS is claimed.

## 5. Item-78 run — facades_r8

Ordered run notes. No Studio result is claimed; no place is saved or published.

1. Stop Play. Inject the changed modules at runtime: `ReplicatedStorage.Shared.ModelMapFacadesR8`, `ReplicatedStorage.Shared.LookDev`, `ReplicatedStorage.Shared.LookDevReview`, `ServerScriptService.Server.Main.server`, `ServerScriptService.Server.World.LookDevFacadesR8`, and the new `tools/studio/review_check_r8.luau`.
2. Start a FRESH real Play session in the SERVER datamodel. Do not reuse a session that staged another candidate.
3. Stage with `require(game.ReplicatedStorage.Shared.LookDevReview).enable("facades_r8", game)`.
4. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER VM. Capture `FACADE_PARTS` and `DOOR_CLEAR`, plus `LOAD_FAILURES` and `LOOKDEV_LEAK`. Exact targets: `FACADE_PARTS 6 6` (each hub folder has >=10 `FacadePart` Parts and all six `FacadeKind` values) and `DOOR_CLEAR 6 6` (each `FacadeDoorGauge` has the exact 7/10.5/2 pakrt or 6/9/2 other sizes, zero collidable hub parts and zero `FacadePart` hits in a rotation-aware `GetPartsInPart` probe at the gauge's exact Size/CFrame). A missing folder, per-hub folder, gauge or hub Model FAILs at measured 0, never a skip. Guards: `LOAD_FAILURES 0 0`, `LOOKDEV_LEAK 0 leaks`.
5. Stop Play. No save, no publish. Visual yes/no is the designer's.

## 6. Item-79 run — hubprops_r8

Ordered run notes. **No Studio result is claimed**; no PASS is asserted, no place is saved or published.

1. Stop Play. Inject at runtime: `ReplicatedStorage.Shared.ModelMapHubPropsR8`, the changed
   `Shared.LookDev` and `Shared.LookDevReview`, `ServerScriptService.Server.Main.server`,
   `ServerScriptService.Server.World.LookDevHubPropsR8`, and the new
   `tools/studio/review_check_r8.luau`. Confirm the nine baked asset folders exist under
   `ServerStorage.LookDevAssets` plus the step-(2) generated `generated_bamboo_basket` folder
   (0 scripts, 18 parts, native bbox ~4.24x4.24x2.6, scaled to 2x2x1.5; CC0-equivalent,
   generationId `14b48661-4c08-425f-ab3f-c641c1a885fd`, no invented ID, runtime-only, never saved).
2. Start a FRESH real Play session in the SERVER datamodel; do not reuse one that staged another
   candidate. Stage with
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("hubprops_r8", game)`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Capture `HUBPROPS_VISIBLE`, `HUBPROPS_ON_GRASS`, `LOAD_FAILURES` and `LOOKDEV_LEAK`. Targets:
   `HUBPROPS_VISIBLE >= 5` (minimum number of `HubProp` Models visible from each hub's
   `hub_<key>` camera inside the 70-degree cone with one occlusion ray) and `HUBPROPS_ON_GRASS 0`
   (Terrain voxel at `GRASS_Y=4` under each prop is not Grass). A missing staging folder, missing
   camera or failed read FAILs at measured 0/1 per hub — never a skip. The item-79 grass line is
   named `HUBPROPS_ON_GRASS` so it does not collide with the existing r7 `PROPS_ON_GRASS` CHECK;
   `LOAD_FAILURES 0 0` and `LOOKDEV_LEAK` remain the shared guards.
4. Stop Play without saving. Both new checks are SERVER-only: `ReviewCameras` requires MapSpec from
   `ServerScriptService`, so they are skipped in the Client VM. Visual yes/no is the designer's.

## 7. Item-136 run — additive review staging (WORK_QUEUE section O)

Ordered run notes. **No Studio result is claimed**; no place is saved or published. No tracker tick
or evidence CHECK file is written by the implementation agent; the main session owns those.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.LookDev`,
   `ReplicatedStorage.Shared.LookDevReview`, and the changed
   `tools/studio/review_check_r8.luau`. The three appliers
   (`ServerScriptService.Server.World.LookDevModelsVegetationHubR8`, `LookDevPlotsR8`,
   `LookDevFacadesR8`) are already booted by `Main.server`; a fresh Play after injection gives each
   one a clean registration in the SERVER VM.
2. Start a FRESH real Play session in the SERVER datamodel; do not reuse one that staged another
   candidate. For a manual combined visual review, stage all three from the command bar:
   ```lua
   local review = require(game.ReplicatedStorage.Shared.LookDevReview)
   review.disableAll()
   review.enableAdditive("hubveg_r8", game)
   review.enableAdditive("plots_r8", game)
   review.enableAdditive("facades_r8", game)
   -- review current() stays nil; all three folders are present at once
   -- when finished: review.disableAll()
   ```
   `enableAdditive` uses the same Studio gate as `enable` and never disables another candidate.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. `ADDITIVE_STAGE` is self-staging: it calls `disableAll()` first, stages the same three ids
   with `enableAdditive(id, game, { studio = true })`, counts each staged folder's tagged parts, and
   calls `disableAll()` again. Folder/tag pairs: `LookDevModelsVegetationHubR8_hubveg_r8`
   (`LookDevHubVegR8 == "hubveg_r8"`), `LookDevPlotsR8_plots_r8` (`LookDevPlotsR8 == "plots_r8"`),
   `LookDevFacadesR8_facades_r8` (`FacadePart == true`). Expected:
   `CHECK ADDITIVE_STAGE PASS 3 3` — measured is the number of the three candidates with parts
   present, target is 3. A missing folder, blocked stage or leaked folder FAILs at measured 0..2;
   the raw `detail` carries `parts`, `leaked` and `errors`.
4. `LOOKDEV_LEAK` runs immediately after `ADDITIVE_STAGE` in `ORDER`, i.e. after `disableAll()`.
   Expected `CHECK LOOKDEV_LEAK PASS 0 leaks 0 leaks`. Guards `LOAD_FAILURES 0 0` and
   `CAMERA_CLEAR 0 blocked/26 checked` should still PASS.
5. Stop Play without saving. `ADDITIVE_STAGE` is SERVER-only: in the Client VM it emits
   `CHECK ADDITIVE_STAGE FAIL 0 3` rather than staging. Visual yes/no is the designer's.

## 8. Item-137 run — `water_r8_a` shipping default (WORK_QUEUE section O)

Ordered run recipe. **No Studio result is claimed** by the implementation agent; the main session
owns the CHECK evidence. No place is saved or published.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapWaterR8`,
   `StarterPlayerScripts.Client.World.Water`, the changed `StarterPlayerScripts.Client.Main.client`,
   and the changed `tools/studio/review_check_r8.luau`. No LookDev module is changed: the default
   write path is independent of `LookDevWaterR8.appliers.a`, which keeps its own save/restore.
2. Start a FRESH real Play session in the CLIENT datamodel. Do NOT call `LookDev.enable(...)`,
   `LookDevReview.enable(...)` or stage any candidate. `Main.client` applies variant A at boot
   through `guarded("Water.mount", ...)`, right after `guarded("Sky.mount", ...)`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the CLIENT
   VM. Expect `CHECK WATER_DEFAULT PASS 5 5`: all five Terrain water properties match
   `ModelMapWaterR8.valuesFor("a")` (WaterColor per 8-bit channel rounded; numeric props within
   0.01). `WATER_DEFAULT` is READ-ONLY and never enables a candidate. A missing Terrain or map
   FAILs at `0 5` with the reason in `detail.reason`; partial matches list `detail.mismatches`.
4. In the SAME run, read `CHECK WATER_SAFE PASS 3 3` and `CHECK WATER_RESTORE PASS 3 3`. The
   existing mutating cycle enables/disables a/b/c and restores the prior active candidate. With no
   candidate staged, its baseline is the boot-applied A default, so each applier's own previous-value
   snapshot must restore to A — including `water_r8_b`. No weakening of either target.
5. Stop Play without saving. `WATER_DEFAULT`, `WATER_SAFE` and `WATER_RESTORE` are CLIENT-only.

## 9. Item-138 run — tropical default forest (WORK_QUEUE section O)

Ordered recipe. **No Studio result is claimed by the implementation agent**; the main session owns
the CHECK evidence and the tracker ticks. No place is saved or published.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapForestR9` and the
   changed `ServerScriptService.Server.World.Greybox`, plus the changed
   `tools/studio/review_check_r8.luau`.
2. Start a FRESH real Play session in the SERVER datamodel. Do NOT call `LookDev.enable(...)`,
   `LookDevReview.enable(...)` or stage any candidate: this change is the shipping default. At boot
   `Greybox.buildBackgroundForest` fills `BackgroundForest` with
   `Tropical_<species>_<angle>_<layer>` Models carrying `ForestTree = true` and
   `ForestSpecies = <species>`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Expect `CHECK NO_PINES PASS 0 0` (no Name with the pine substring anywhere in the workspace),
   `CHECK RING_COUNT PASS <n> 250` (at least 250 `ForestTree` trees in `BackgroundForest`),
   `CHECK RING_SPECIES PASS 4 4` (kelapa, mangga, pisang, bambu all present), and read
   `CHECK PERF_BUDGET ...` as the recorded cost. A missing folder or unreadable attribute FAILs at
   0 — never a skip. No target is weakened.
4. For comparison only, use a SEPARATE fresh Play and stage `forest_pines_legacy` via
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("forest_pines_legacy", game)`;
   re-read the same lines to see the old backdrop, then `disableAll()`. Do not grade the default
   look with the candidate staged.
5. Stop Play without saving. Visual yes/no stays the designer's; this recipe reports objective
   counts only.

## 10. Item-139 run — `facades_r8` stray pole

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence and tracker ticks. No place is saved or published.

1. Stop Play. Inject at runtime (not saved) the changed `ReplicatedStorage.Shared.ModelMapFacadesR8`
   and `tools/studio/review_check_r8.luau`.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY `facades_r8` from the Server VM:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("facades_r8", game)`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER VM.
   Read `FACADE_STRAY`, `FACADE_PARTS` and `DOOR_CLEAR`. Expected:
   `CHECK FACADE_STRAY PASS 0 0` (every tagged `FacadePart` bbox inside its hub Model bbox grown 3,
   top <= hub ridge + 1, no side > 12), `CHECK FACADE_PARTS PASS 6 6`, `CHECK DOOR_CLEAR PASS 6 6`.
   `FACADE_STRAY` is READ-ONLY; a missing folder, gauge or hub Model FAILs with the offender in
   `detail.offenders`, never a vacuous pass.
4. Stop Play without saving. Fixed in data: `FacadeRidgeCap` on pakrt was a 38.4-stud gold bar laid
   across (not along) its Z-running ridge; all six caps were 25.6–51.2 studs. Caps are now 10 studs
   and pakrt's runs along local Z; pakrt's `FacadeEave_L` also moved 1.5 studs inward to stay inside
   hub bbox + 3. Visual grading remains the designer's.

## 11. Item-140 run — `sawah_r8` padi redo (WORK_QUEUE section O)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence and tracker ticks. No place is saved or published.

1. Stop Play. Inject at runtime (not saved) the changed `ReplicatedStorage.Shared.ModelMapSawahR8`,
   `ServerScriptService.Server.World.LookDevSawahR8` and the changed
   `tools/studio/review_check_r8.luau`. The applier is already booted by `Main.server`.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY `sawah_r8` from the Server VM:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("sawah_r8", game)`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER VM.
   Read `TUFT_SHAPE` (target `0` oversized PadiPart parts), `PADI_ROWS` (target `10`, minimum distinct
   `PadiRow` ids per terrace), `PADI_CLUMPS` (target `250`, minimum distinct `PadiClump` ids per
   terrace) and `SAWAH_GREEN` (target `40`, minimum percentage of a 20x8 grid per terrace hit by a
   PadiPart from the `sawah_above` camera). The four checks are READ-ONLY and stage nothing.
4. Re-read the guards `SAWAH_TOPS` (target `0.5`), `SAWAH_WATER` (`4 sheets`), `SAWAH_VERGE`
   (`>=40`) and `GUBUK` (`1`) in the same run; all must stay PASS. A missing folder, camera or
   Raycast FAILs with a reason in `detail.reason`, never a skip. No target is weakened.
5. Stop Play without saving. Visual grading — does the band read as padi? — stays the designer's.

## 12. Item-141 run — `river_r8` bank plants redo (WORK_QUEUE section O)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence and tracker ticks. No place is saved or published.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapRiverR8`, the changed
   `ServerScriptService.Server.World.LookDevRiverR8` and the changed
   `tools/studio/review_check_r8.luau`. Confirm the baked plant asset folders for the five species
   exist under `ServerStorage.LookDevAssets` (talas/keladi use the R4 shrub stand-in, alang-alang the
   R6 ID, bambu/kelapa their R4 IDs) so `LookDevAssetLoader` clones them instead of falling back.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY `river_r8` from the Server VM:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("river_r8", game)`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER VM.
   Read `RIVER_BANK_VEG` (now target `>=40` in-radius plants, both banks), `BANK_PLANT_SHAPE` (target
   `0` offenders: every `BankPlant` base Part is >=0.8 studs in X and Z and >=1.5 studs tall),
   `RIVER_ROCKS` (target `>=12` `BankRock` Parts within 40 studs of the bridge, each axis 1–4 studs)
   and the unchanged guard `BRIDGE_WALKABLE` (target `>=8` clear studs). All four checks are
   READ-ONLY and stage nothing; a missing folder/tag or failed Part read FAILs with the offender in
   `detail`, never a vacuous pass. The two rock shapes are procedural stand-ins (Ball, squashed
   Wedge) — no verified rock model ID exists in the shared maps. No target is weakened.
4. Stop Play without saving. Rails and stepping stones are untouched. Visual grading — do the bank
   plants and boulders read as a planted river? — stays the designer's.

## 13. Item-142 run — `pathedge_r8` edge-band redo (WORK_QUEUE section O)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence and tracker ticks. No place is saved or published.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapPathEdgeR8`, the
   changed `ServerScriptService.Server.World.LookDevPathEdgeR8` and the changed
   `tools/studio/review_check_r8.luau`. Confirm the baked `ServerStorage.LookDevAssets.361802126`
   grass folder exists (verified alang-alang ID from `Shared.ModelMapVegetationR6.ids.alang_alang`)
   so the clumps clone instead of falling back to thin procedural blades.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY this candidate from the
   Server VM:
   ```lua
   require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("pathedge_r8", game)
   ```
   The applier now derives each piece's nearest centreline point and half-width from MapSpec
   (`roadArms`, `roadContinuations`, `ROAD.ringWidth`), with lateral signed distance in the
   `[halfWidth + 0.3, halfWidth + 2.5]` band; grass stays within `CLUMP_MAX_WIDTH / 2` of the edge
   so its inner face reaches the road. Each staged Part carries `PathEdgePart = true` plus numeric
   `Lateral`, `HalfWidth`, `CentreX`, `CentreZ`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Read `CHECK PATH_EDGE_OFFSET PASS 0 0` (READ-ONLY: every tagged piece's `|Lateral|` lies in
   `[HalfWidth, HalfWidth + 3]`, its CFrame agrees with the recorded centre, and that centre lies on
   a MapSpec centreline), plus the unchanged `CHECK PATH_CLEAR PASS 0 0` and `CHECK PATH_EDGE PASS
   <count> >=120`. A missing folder, tag or attribute FAILs with part name, measured lateral and
   allowed band in `detail.offenders` — never a vacuous pass. No target is weakened.
4. Read the guards `LOAD_FAILURES` (0) and `LOOKDEV_LEAK` (0 leaks). `PATH_EDGE_OFFSET`, `PATH_EDGE`
   and `PATH_CLEAR` are SERVER-side; this Studio has no `Part.GetBoundingBox`, so clump scaling uses
   CFrame + Size corner math. Visual grading — does the grass read as a planted road edge? — stays
   the designer's.

## 14. Item-143 run — `plots_r8` canonical dressing (WORK_QUEUE section O)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence and tracker ticks. No place is saved or published.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapPlotsR8`,
   `ReplicatedStorage.Shared.ReviewCameras`, `ServerScriptService.Server.World.LookDevPlotsR8` and
   the changed `tools/studio/review_check_r8.luau`. The applier is already booted by `Main.server`.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY this candidate:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("plots_r8", game)`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Read `CHECK PLOT_FENCE ... >=8 each` (now eight two-rail fence runs per plot; posts are
   `fence_post` and do not count), `CHECK PLOT_FENCE_VISIBLE ... >=70` (READ-ONLY: each
   `plot_aerial_NN` eye raycasts every `Kind=="fence"` rail centre; the first opaque hit must be
   that rail, transparent ditch water is skipped, missing camera/ray/zero segment FAILs at 0),
   `CHECK GATE_CLEAR ... 0` and `CHECK CAMERA_CLEAR ... 0 blocked` (now includes the ten aerials).
   No target was weakened.
4. Read the guards `LOAD_FAILURES 0 0` and `LOOKDEV_LEAK 0 leaks` in the same run. Stop Play
   without saving. Visual grading — does the fence read as bamboo from the road? — stays the
   designer's.


## 15. Item-144 run — `hubveg_r8` densify (WORK_QUEUE section O)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence and tracker ticks. No place is saved or published.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapVegetationHubR8`,
   `ServerScriptService.Server.World.LookDevModelsVegetationHubR8` and the changed
   `tools/studio/review_check_r8.luau`. The applier is already booted by `Main.server`. Confirm the
   baked R7 asset folders under `ServerStorage.LookDevAssets` (mangga, pisang, bambu, bunga,
   kembang sepatu plus the nine base species) so clone-first loading succeeds — no new asset ID.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY this candidate additively:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("hubveg_r8", game)`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Read `VEG_HUB_<hub>` (now `>=30` in-radius instances per hub; group children are counted as
   individual staged models), `HUB_TREES` (READ-ONLY, `>=2` per hub with `HubVegTree == true` and
   `HubVegTreeHeight` in 8..12), `VEG_SPECIES_HUB` (unchanged `>=4` each), `VEG_OVERLAP` (unchanged
   `0`) and `DOOR_CLEAR` (unchanged, facades). A missing folder or unreadable attribute FAILs at
   measured 0, never a skip.
4. In the same run read the new READ-ONLY `PATH_REACH` (target `0` blocked lanes): a 6-stud lane
   from each MapSpec hub front outward 24 studs must contain no opaque staged hub-veg AABB. This is
   the section-O six-hub-door subset only; item 105's full PathfindingService 16/16 audit remains a
   separate section-M item and this recipe claims no PathfindingService success. Read the guards
   `LOAD_FAILURES 0 0` and `LOOKDEV_LEAK 0 leaks` too.
5. Stop Play without saving. Visual grading — do the canopy trees, pisang/bambu groups and door
   beds read as the canonical village? — stays the designer's.

## 16. Item-145 run — `blocks_r9` village grass blocks (WORK_QUEUE section O)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence, tracker ticks and any visual verdict. No place is saved or published.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapBlocksR9`, the
   changed `ReplicatedStorage.Shared.LookDev` and `LookDevReview`,
   `ServerScriptService.Server.World.LookDevBlocksR9`, and the changed
   `tools/studio/review_check_r8.luau`. Confirm the R4/R6 baked asset folders for mangga, bambu,
   pisang, teh-tehan, shrubs, bunga, kembang sepatu and alang-alang exist under
   `ServerStorage.LookDevAssets`; no new asset ID is introduced.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY this candidate additively:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive("blocks_r9", game)`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Read the three new READ-ONLY lines: `CHECK BLOCK_TREES PASS <n> >=60` (72 tagged trees at
   6-12 studs in pure data), `CHECK BLOCK_SPECIES PASS 4 >=4` (mangga/bambu/pisang/teh-tehan
   stand-ins) and `CHECK AVATAR_FIT PASS 0 0` (no collidable staged part intersects a 7 x 7.25 x 4
   gauge along any of the six PATH_REACH hub-door corridors). A missing folder, tag or failed Part
   read FAILs at measured 0 for the count lines and 6 for AVATAR_FIT — never a vacuous pass.
4. In the SAME run read `CHECK VEG_OVERLAP ... 0`, `CHECK PATH_REACH ... 0` and `CHECK PERF_BUDGET ...`
   (record the measured value; flag over the Sedang proxy, do not weaken the target). PATH_REACH
   reads the hubveg folder, so stage `hubveg_r8` additively too if it is not already staged; do not
   change the check. Read the guards `LOAD_FAILURES 0 0` and `LOOKDEV_LEAK 0 leaks`.
5. Stop Play without saving. `AVATAR_FIT` covers only this section-O block subset; item 106's full
   16/16 PathfindingService audit remains separate. Visual grading — do the blocks read as a
   canonical full kampung, not an orchard grid? — stays the designer's.

## 17. Item-146 run — building kit ground pivots (WORK_QUEUE section O)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence, tracker ticks and any visual verdict. No place is saved or published.

1. Stop Play. Inject at runtime (not saved) the changed `ServerScriptService.Server.World.LookDevBuildingsR8`
   and `tools/studio/review_check_r8.luau`. The applier is already booted by `Main.server`; confirm
   the six baked `BuildingSlot` folders exist under `ServerStorage.LookDevAssets`.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY this candidate:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("buildings_r8", game)`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Read `CHECK PIVOT_GROUND <failing> 0` (READ-ONLY; target 0 failing models — each pivot's Y
   within 0.2 studs of its own world bbox bottom) and `CHECK BLDG_VISIBLE 6 6` (unchanged geometry).
   A missing folder, unreadable pivot or zero staged Models FAILs at measured 6, never a skip.
4. Read the guards `LOAD_FAILURES 0 0` and `LOOKDEV_LEAK 0 leaks` in the same run. Stop Play without
   saving. The kit table and hub mapping proposal live in `docs/v2/visual/art/BUILDING_KIT.md`;
   visual grading — does each building suit its proposed hub? — stays the designer's.

## 18. Item-147 run — `hubs_real_r9` real buildings on six hubs (WORK_QUEUE section O)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence, tracker ticks and any visual verdict. No place is saved or published. The
hub → building matches are the PROPOSAL in `docs/v2/visual/art/BUILDING_KIT.md`, pending designer yes.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapHubsRealR9`, the
   changed `ReplicatedStorage.Shared.LookDev` and `LookDevReview`,
   `ServerScriptService.Server.World.LookDevHubsRealR9`, and the changed
   `tools/studio/review_check_r8.luau`. Confirm the six baked `BuildingSlot` folders exist under
   `ServerStorage.LookDevAssets` so `LookDevAssetLoader` clones them instead of falling back; no new
   asset ID is introduced.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY this candidate:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("hubs_real_r9", game)`.
   Each staged Model is named `R9_<hub>_<slot>` in `LookDevHubsRealR9_hubs_real_r9` and carries
   `HubRealR9 = "hubs_real_r9"`, `HubRealR9Hub` and `HubRealR9Slot`. The greybox hub Model's
   non-sign `BasePart`s are set `Transparency = 1` / `CanCollide = false`; `Sign` and its children
   stay visible. The exact prior values are saved in attributes and put back on disable.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Read the new READ-ONLY `CHECK HUB_FIT 0 0`: PASS iff every mapped hub has at least one staged
   building and every staged Model's world AABB lies inside `MapSpec.hubBounds(hub)` grown 2 studs
   on each side. A missing folder, tag, MapSpec or unreadable bbox FAILs at measured 6 (one per
   hub), never a vacuous pass. `HUB_FIT` sits in `ORDER` directly after `AVATAR_FIT`.
4. In the SAME run read `CHECK DOOR_CLEAR 6 6` (stage `facades_r8` additively too if it is not already
   staged — `DOOR_CLEAR` grades the facade gauges, which this candidate does not add),
   `CHECK PATH_REACH 0 0` (stage `hubveg_r8` additively too; the six 6-stud hub-door lanes start at
   the footprint facade plane so an inside-footprint building cannot block them), and the guards
   `LOAD_FAILURES 0 0` and `LOOKDEV_LEAK 0 leaks`. Then call
   `require(game.ReplicatedStorage.Shared.LookDevReview).disable()` and re-run `LOOKDEV_LEAK`: the
   staged folder must be gone and all six greybox hub bodies back at their prior opacity/collision
   with the signs still readable.
5. Stop Play without saving. Fit numbers from the pure data (0.25-stud inset, downscale only,
   world axes swapped for yaw 90):

   | Hub | Building | Fit scale | Final `ScaleTo` | World bbox W × D | MapSpec footprint W × D |
   | --- | --- | --- | --- | --- | --- |
   | `pasar` | `indonesian_house` | 0.989814 | 0.989814 | 36.296 × 51.500 | 64 × 52 |
   | `gelap` | `rumah_joglo` | 0.486640 | 0.364980 (0.75 base baked in) | 28.060 × 27.500 | 32 × 28 |
   | `warung` | `warung_penyetan` | 1.000000 | 1.000000 | 24.000 × 13.820 | 52 × 44 |
   | `ronda` | `nipa_hut` | 0.891849 | 0.891849 | 39.500 × 20.263 (yaw 90) | 40 × 44 |
   | `polisi` | `pendopo_jawa` | 0.843677 | 0.843677 | 25.749 × 43.500 | 48 × 44 |
   | `pakrt` | `rumah_4` | 0.611314 | 0.611314 | 22.992 × 33.500 | 48 × 34 |

6. Stop Play without saving. Visual grading — does each real building read as its hub at that
   scale, and should the PROPOSAL mapping be kept? — stays the designer's.

## 19. Item-148 run — `pasar_awnings_r8` lapak stalls and awnings (WORK_QUEUE section O)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence, tracker ticks and any visual verdict. No place is saved or published.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapPasarAwningsR8`,
   the changed `ReplicatedStorage.Shared.LookDev` and `LookDevReview`,
   `ServerScriptService.Server.World.LookDevPasarAwningsR8`, and the changed
   `tools/studio/review_check_r8.luau`. No asset ID is introduced: every stall is original Parts.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY this candidate:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("pasar_awnings_r8", game)`.
   Twelve `PasarStall_` Models appear in `LookDevPasarAwningsR8_pasar_awnings_r8`, each with
   `PasarStall = true`; six `AwningStripe` Parts per stall carry `StripeColour`
   `red`/`white`/`blue` (72 total). A Ground voxel pad is snapshotted and painted under every stall.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Read the four new READ-ONLY lines: `CHECK STALLS >=10` (count of tagged Models),
   `CHECK AWNING_STRIPES >=30` (count of valid striped Parts), `CHECK LANE_CLEAR 0 0` (zero staged
   parts whose CFrame+Size AABB intersects the 6-stud lane rectangle in the pure data module), and
   `CHECK PASAR_AWNING_ON_GRASS 0 0` (Terrain voxel at `GRASS_Y=4` under each stall is not Grass).
   A missing folder, tag, lane data or unreadable MapSpec FAILs at measured 0/1, never a skip.
   The grass line is named `PASAR_AWNING_ON_GRASS` so it cannot collide with r7's `PROPS_ON_GRASS`.
4. Call `require(game.ReplicatedStorage.Shared.LookDevReview).disable()` and re-run
   `LOOKDEV_LEAK`: the staged folder must be gone and every saved voxel region written back byte-for-
   byte. Capture `LOAD_FAILURES 0 0` and `LOOKDEV_LEAK 0 leaks` as the shared guards.
5. Stop Play without saving. Record staged `PERF_BUDGET` if the main session measures it; the
   candidate is off by default and the default look is untouched. Visual grading — do the stalls read
   as a canonical Pasar and do the stripes read as red/white/blue without a brand? — stays the
   designer's.

## 20. Item-149 run — `plaza_r9` central plaza dressing (WORK_QUEUE section O)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence, tracker ticks and any visual verdict. No place is saved or published.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapPlazaR9`, the changed
   `ReplicatedStorage.Shared.LookDev` and `LookDevReview`,
   `ServerScriptService.Server.World.LookDevPlazaR9`, and the changed
   `tools/studio/review_check_r8.luau`. No asset ID is introduced: the tree and every other piece are
   original Parts; nothing is painted into Terrain (the plaza is already Ground).
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY this candidate:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("plaza_r9", game)`. One
   `PlazaFountain` Model (with a `FountainWater` disc tagged `WaterColour = "water"`), four
   `PlazaBench` Models, four `PlazaUmbrella` Models (six `UmbrellaStripe` Parts each,
   `StripeColour` red/white/blue alternating), one `PlazaBunting` Model (two `BuntingPole` Parts,
   one `BuntingLine`, eleven `BuntingFlag` Parts) and one `PlazaShadeTree` Model appear in the single
   `LookDevPlazaR9_plaza_r9` folder. Every anchor is plaza-local, resolved from `MapSpec.PLAZA`
   inside the 38x28 dressed area; the four 6-stud arm lanes stop at the fountain rim.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Read the seven new READ-ONLY lines: `CHECK PLAZA_FOUNTAIN 1 1` (one fountain Model with a
   water-colour disc), `CHECK PLAZA_BENCHES 4 4`, `CHECK PLAZA_UMBRELLAS 4 4` (all four carry
   alternating red/white/blue stripes), `CHECK PLAZA_BUNTING 1 1` (at least two poles, at least six
   flags and a line spanning both poles), `CHECK PLAZA_SHADE_TREE 1 1` (at least 10 studs tall at the
   plaza edge), `CHECK PLAZA_LANE_CLEAR 0 0` (no visible staged Part's CFrame+Size AABB intersects a
   6-stud lane) and `CHECK PLAZA_PATH_REACH 0 0` (all four corridors from the road-arm mouths at the
   plaza edge to the centre rim are clear). A missing folder, tag, pure data module or MapSpec FAILs
   at measured 0 for the count lines and a positive blocked count for the two clearance lines —
   never a vacuous pass. These are AABB clearances, not a PathfindingService audit.
4. Call `require(game.ReplicatedStorage.Shared.LookDevReview).disable()` and re-run `LOOKDEV_LEAK`:
   the staged folder must be gone. Capture `LOAD_FAILURES 0 0` and `LOOKDEV_LEAK 0 leaks` as the
   shared guards. Read staged `PERF_BUDGET` if the main session measures it; record and flag over
   the Sedang proxy without weakening any target.
5. Stop Play without saving. Visual grading — does the fountain/bunting/umbrella/bench/tree set read
   as the canonical Lapangan? — stays the designer's.

## 21. Item-150 run — `ronda_tower_r9` Pos Ronda watchtower (WORK_QUEUE section O)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence and tracker ticks, and the designer owns the visual yes/no. No place is saved or
published.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapRondaTowerR9`, the
   changed `ReplicatedStorage.Shared.LookDev` and `LookDevReview`,
   `ServerScriptService.Server.World.LookDevRondaTowerR9`, and the changed
   `tools/studio/review_check_r8.luau`. No asset ID is introduced: the tower is 24 original Parts
   (4 bamboo legs, deck, 2 roof panels, kentongan + slit, 2 ladder rails + 13 rungs). The greybox
   tower stays visible underneath; `LOOKDEV_LEAK` covers folder cleanup, not greybox hiding.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY this candidate:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("ronda_tower_r9", game)`. One
   `RondaTower` Model appears inside `LookDevRondaTowerR9_ronda_tower_r9` at
   `MapSpec.RONDA_TOWER.x/.z` on `MapSpec.GROUND_Y`; the recipe height is 30 studs, the four
   `TowerLeg` Parts span 7.7x7.7 studs, and the kentongan and ladder are tagged at the top/side.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Read the three new READ-ONLY lines: `CHECK TOWER_HEIGHT 30 28..32` (staged Model world
   `GetBoundingBox` Y size, inclusive 28-32), `CHECK TOWER_BASE 7.7 <=9` (four legs' collective
   CFrame+Size XZ AABB, 8x8 brief + 1 tolerance), `CHECK TOWER_PATH_CLEAR 0 0` (no staged Part AABB
   intersects a MapSpec road arm, continuation or ring chord; the SAME path table as `PATH_CLEAR`).
   A missing folder/model/MapSpec FAILs at measured 0 height or base and a positive overlap count —
   never a vacuous pass. These are AABB clearances, not a PathfindingService audit.
4. Call `require(game.ReplicatedStorage.Shared.LookDevReview).disable()` and re-run `LOOKDEV_LEAK`:
   the staged folder must be gone and any prior folder re-parented. Capture `LOAD_FAILURES 0 0` and
   `LOOKDEV_LEAK 0 leaks` as the shared guards. Read staged `PERF_BUDGET` if measured; record and
   flag over the Sedang proxy without weakening any target.
5. Stop Play without saving. Visual grading — does the tower read as the canonical bamboo Pos Ronda
   with kentongan and ladder at the brief height? — stays the designer's.

## 22. Item-151 run — `rocks_r9` boulders and stones (WORK_QUEUE section O)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence and tracker ticks, and the designer owns the visual yes/no. No place is saved or
published.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapRocksR9`, the changed
   `ReplicatedStorage.Shared.LookDev` and `LookDevReview`,
   `ServerScriptService.Server.World.LookDevRocksR9`, and the changed
   `tools/studio/review_check_r8.luau`. No asset ID is introduced: three procedural Part shapes
   (Ball, squashed Wedge, three-ball cluster) stand in for rock models because no verified rock
   MODEL id exists in the shared asset maps.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY this candidate:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("rocks_r9", game)`. The applier reads
   live gate positions first from staged `plots_r8` `gate_marker` Parts, then from tagged
   `PlotAnchor` parts, then from `Config.Game.plotCenter`; unreadable gates abort staging, so a run
   without any readable plot gates FAILs rather than passing vacuously.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Read four new READ-ONLY lines: `CHECK ROCK_COUNT 48 >=25` (tagged `RockR9` Models in
   `LookDevRocksR9_rocks_r9`), `CHECK ROCK_SPECIES 3 >=2` (distinct `RockKind` values),
   `CHECK ROCK_PATH_CLEAR 0 0` (no staged Part CFrame+Size AABB touches a MapSpec road arm,
   continuation or ring chord — the SAME path table as `PATH_CLEAR`) and `CHECK ROCK_GATE_CLEAR 0 0`
   (no rock Model bbox centre within 2 studs of a plot gate). Missing folder, gates or MapSpec FAIL;
   no check is vacuous. These are AABB/XZ clearances, not a visual grade. The existing `PATH_CLEAR`
   and `GATE_CLEAR` lines belong to earlier items and are unchanged.
4. Call `require(game.ReplicatedStorage.Shared.LookDevReview).disable()` and re-run `LOOKDEV_LEAK`:
   the staged folder must be gone and any prior folder re-parented. Capture `LOAD_FAILURES 0 0` and
   `LOOKDEV_LEAK 0 leaks` as the shared guards. Read staged `PERF_BUDGET` if measured; record and
   flag over the Sedang proxy without weakening any target.
5. Stop Play without saving. Visual grading — do the boulders read as natural half-buried stones
   along the river, hill foot and field edges? — stays the designer's.

## 23. Section O review pack (item 155 — shots to be taken by the main session)

No agent grades these shots. Camera names and datamodels are from `docs/v2/visual/REVIEW_CAMERAS.md`;
the per-shot plan is `docs/v2/visual/SHOT_LIST.md`. Start each single-candidate shot from a fresh
Play (or `review.disableAll()`), stage one id from the SERVER datamodel with
`require(game.ReplicatedStorage.Shared.LookDevReview).enableAdditive(id, game)`, shoot, then
`disableAll()`. `water_r8_a` needs no enable: it is the shipping client default. No place is saved
or published.

### (a) All-together additive shot (item 136) — `canonical_overview`

```lua
local review = require(game.ReplicatedStorage.Shared.LookDevReview)
review.disableAll()
review.enableAdditive("hubveg_r8", game)
review.enableAdditive("plots_r8", game)
review.enableAdditive("facades_r8", game)
-- shoot `canonical_overview` in the SERVER datamodel; current() stays nil,
-- all three staged folders are present together
review.disableAll()
```

Do not substitute `enable(id)` — it disables the previously staged candidate. Verified objective
backup: `ADDITIVE_STAGE PASS 3 3`, `LOOKDEV_LEAK PASS 0 leaks 0 leaks` (`CHECK_136.txt`).

### (b) Each section-O candidate alone

| Item | Candidate | Datamodel | Review camera(s) | CHECK evidence |
|---|---|---|---|---|
| 138 | `forest_pines_legacy` (comparison only) | Server | `forest_wall` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_138.txt`, `docs/v2/evidence/h/2026-11-21-round9/CHECK_102.txt`, `docs/v2/evidence/h/2026-11-21-round9/CHECK_74.txt` |
| 139 | `facades_r8` | Server | `hub_pakrt` (stray-pole fix); `hub_pasar`, `hub_gelap`, `hub_warung`, `hub_ronda`, `hub_polisi` for the same-defect sweep | `docs/v2/evidence/h/2026-11-21-round9/CHECK_139.txt` |
| 140 | `sawah_r8` | Server | `sawah_above` (padi rows), `sawah_below` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_140.txt` |
| 141 | `river_r8` | Server | `bridge_north_bank`, `bridge_south_bank`, `river_rocks` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_141.txt` |
| 142 | `pathedge_r8` | Server | `spawn` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_142.txt` |
| 143 | `plots_r8` | Server | `plot_aerial_01`..`plot_aerial_10`, `plot_gate_01`..`plot_gate_10` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_143.txt` |
| 144 | `hubveg_r8` | Server | `hub_warung` (densify shot), plus `hub_pasar`, `hub_gelap`, `hub_ronda`, `hub_polisi`, `hub_pakrt` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_144.txt` |
| 145 | `blocks_r9` | Server | `canonical_overview`, `spawn` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_145.txt` |
| 146 | `buildings_r8` (building kit) | Server | saved row camera on the staged folder (`ReviewCameraPos`/`ReviewLookAt`, `front=-228`, `up=60`, `lookY=16`); no registry name in `REVIEW_CAMERAS.md` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_146.txt` |
| 147 | `hubs_real_r9` | Server | `hub_pasar`, `hub_gelap`, `hub_warung`, `hub_ronda`, `hub_polisi`, `hub_pakrt` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_147.txt` |
| 148 | `pasar_awnings_r8` | Server | `pasar_awnings` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_148.txt` |
| 149 | `plaza_r9` | Server | `plaza_centre` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_149.txt` |
| 150 | `ronda_tower_r9` | Server | `ronda_tower` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_150.txt` |
| 151 | `rocks_r9` | Server | `river_rocks` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_151.txt` |

Base look: no candidate enabled — `spawn` and `canonical_overview` in the SERVER datamodel,
`spawn_golden` in the CLIENT datamodel for the shipped sky/water.

### (c) Every `CHECK_*.txt` in this folder

- `docs/v2/evidence/h/2026-11-21-round9/CHECK_68.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_69.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_70.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_71.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_72.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_73.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_74.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_75.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_76.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_77.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_78.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_79.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_102.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_136.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_137.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_138.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_139.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_140.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_141.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_142.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_143.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_144.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_145.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_146.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_147.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_148.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_149.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_150.txt`
- `docs/v2/evidence/h/2026-11-21-round9/CHECK_151.txt`

The exact `CHECK_138`..`CHECK_151` set present on disk is CHECK_138, 139, 140, 141, 142, 143,
144, 145, 146, 147, 148, 149, 150, 151 — 14 files, all listed above. No `CHECK_152`..`CHECK_155`
file exists; main session writes those if needed.

## Item-80 run — `streetfurn_r8` street furniture (WORK_QUEUE section M)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence and tracker ticks. No place is saved or published.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapStreetFurnR8`,
   `ReplicatedStorage.Shared.Strings`, the changed `ReplicatedStorage.Shared.LookDev`,
   `ReplicatedStorage.Shared.LookDevReview`, `ServerScriptService.Server.World.LookDevStreetFurnR8`
   and the changed `tools/studio/review_check_r8.luau`.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY this candidate from the
   Server VM:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("streetfurn_r8", game)`.
   Shoot `spawn` or `canonical_overview` from `docs/v2/visual/REVIEW_CAMERAS.md`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Read `STREETFURN` (per-kind counts: >=18 lampu+obor posts with >=8 of each, 3 signs,
   1 gapura, >=1 pole line with >=1 cable part, 2 bale-bale), `STRINGS_PARITY` (3 valid `sign_*`
   keys with non-empty `id` and `en`) and `STREETFURN_CLEAR` (0 non-exempt parts within 6 studs of
   a MapSpec road centreline; the `VergePost` exemption covers only the lampu/obor posts, gapura and
   pole/cable line, which are designed to stand on the verge). All three are READ-ONLY; a missing
   folder, Strings key or MapSpec FAILs, never a skip.
4. Re-read the guards `LOAD_FAILURES 0 0` and `LOOKDEV_LEAK 0`; stop Play without saving. Visual
   grading stays the designer's.

## Item-81 run — `spanduk_r8` banners and signage (WORK_QUEUE section M)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence and tracker ticks. No place is saved or published.

1. Stop Play. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapSpandukR8`,
   `ReplicatedStorage.Shared.Strings`, the changed `ReplicatedStorage.Shared.LookDev`,
   `ReplicatedStorage.Shared.LookDevReview`, `ReplicatedStorage.Shared.ReviewCameras`,
   `ServerScriptService.Server.World.LookDevSpandukR8`, the changed `ServerScriptService.Server.Main.server`
   and the changed `tools/studio/review_check_r8.luau`.
2. Start a FRESH real Play session in the SERVER datamodel. Stage ONLY this candidate from the
   Server VM:
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("spanduk_r8", game)`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Read `SIGN_TEXT_PARITY` (5/5 item-81 `Strings.raw` keys with non-empty `id` and `en`, every
   staged `SignKey` known, staged signs > 0) and `SIGN_FACING` (each staged sign board's `LookVector`
   projected to XZ must be within <= 30deg of the horizontal sign->approach-camera direction; a
   missing folder, Strings key or ReviewCameras read FAILs at measured 0/ERR, never a skip). Both are
   SERVER-side and READ-ONLY; `SIGN_FACING` uses `hub_warung` / `hub_pasar` / `canonical_overview` from
   `docs/v2/visual/REVIEW_CAMERAS.md`, so shoot those review cameras when grading the board fronts.
4. Re-read the guards `LOAD_FAILURES 0 0` and `LOOKDEV_LEAK 0`; stop Play without saving. Visual
   grading stays the designer's.

## Item-82 run — `animals_r8` village animals (WORK_QUEUE section M)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence and tracker ticks. No place is saved or published.

1. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapAnimalsR8`, the changed
   `Shared.LookDev` and `Shared.LookDevReview`, the new
   `PlayerScripts.Client.World.LookDevAnimalsR8`, and the changed
   `tools/studio/review_check_r8.luau`.
2. Start a fresh real Play session. The three item checks are READ-ONLY and need NO staged candidate:
   they call the pure module's spawn/stepAll with the live `ServerScriptService.Server.World.MapSpec`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM (the Client VM cannot read MapSpec, so every ANIMAL_* line FAILs there by design). Read
   `ANIMAL_COUNT` (1..14, per-kind counts 4 ayam / 4 bebek / 2 kambing / 1 kucing),
   `ANIMAL_BOUNDS` (0 offenders over 3600 steps of 1/60 s; `|x|,|z| <= TERRAIN_HALF`,
   `y >= GROUND_Y - 0.05`; detail carries min/max x/z/y and any offenders) and `ANIMAL_COST`
   (average `os.clock` step < 0.3 ms; detail carries the total and step count). No 60-second real
   wait is involved.
4. For a visual pass only, stage the client applier from the CLIENT datamodel with
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("animals_r8", game)` and shoot
   `hub_warung`, `river_rocks` and `sawah_above` from `docs/v2/visual/REVIEW_CAMERAS.md`. Re-read
   `LOOKDEV_LEAK 0` after disable; stop Play without saving. Visual yes/no stays the designer's.

## Item-83 run — `flyers_r8` birds, butterflies, dragonflies (WORK_QUEUE section M)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
the CHECK evidence and tracker ticks. No place is saved or published.

1. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapFlyersR8`, the changed
   `Shared.LookDev` and `Shared.LookDevReview`, the new
   `PlayerScripts.Client.World.LookDevFlyersR8`, and the changed
   `tools/studio/review_check_r8.luau`.
2. Start a fresh real Play session. The two item checks are READ-ONLY and need NO staged candidate:
   they call the pure module's spawn/caps/kindCounts/stepAll with the live
   `ServerScriptService.Server.World.MapSpec`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM (the Client VM cannot read MapSpec, so both FLYER_* lines FAIL there by design). Read
   `FLYER_COUNT` (0 invalid tiers; per-tier caps 6 burung / 10 kupu / 4 Rendah..8 Tinggi capung,
   at least one of each; detail carries per-tier counts and caps), then `FLYER_COST` (24 flyers,
   3600 steps at 1/60 s, average `os.clock` step < 0.3 ms; detail carries total ms, steps and
   flyer count). No 60-second real wait is involved.
4. For a visual pass only, stage the client applier from the CLIENT datamodel with
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("flyers_r8", game)` and shoot
   `canonical_overview`, `hub_warung` and `bridge_south_bank` from `docs/v2/visual/REVIEW_CAMERAS.md`.
   Re-read `LOOKDEV_LEAK 0` after disable; stop Play without saving. Visual yes/no stays the
   designer's.

## Item-84 run — `smoke_r8` kitchen smoke, steam and fire (WORK_QUEUE section M)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
CHECK evidence, tracker ticks and the visual verdict. No place is saved or published.

1. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapSmokeR8`, the changed
   `Shared.LookDev` and `Shared.LookDevReview`, the new
   `PlayerScripts.Client.World.LookDevSmokeR8`, and the changed
   `tools/studio/review_check_r8.luau`.
2. Start a fresh real Play session. The three item checks are READ-ONLY and need no staged
   candidate: they call `recipes(MapSpec)` and `isNight` from the pure shared module with the live
   `ServerScriptService.Server.World.MapSpec`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM (the Client VM cannot read MapSpec, so all three FAIL there by design). Read `EMITTERS`
   (0 violations; 9 total, 2 chimneys + 1 steam + 6 torch flames, max Rate 10 <= 12), `LIGHTS`
   (0 violations; 6 lights, max Range 14 <= 30) and `TORCH_NIGHT` (`13=false 20=true 5=true`).
   Missing module/MapSpec FAILs at measured >= 1, never a skip.
4. For a visual pass only, stage the client applier from the CLIENT datamodel with
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("smoke_r8", game)`; set
   `Lighting.ClockTime` to 13 (torches off) then 20 (torches on with Heartbeat flicker), and shoot
   `hub_warung`, `hub_pasar` and `canonical_overview` from `docs/v2/visual/REVIEW_CAMERAS.md`.
   Re-read `LOOKDEV_LEAK 0` after disable; stop Play without saving. Visual yes/no stays the
   designer's.

## Item-85 run — `wind_r8` gentle wind and sway (WORK_QUEUE section M)

Run-note recipe. **No Studio result is claimed** by the implementation agent; the main session owns
CHECK evidence, tracker ticks and the visual verdict. No place is saved or published.

1. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapWindR8`, the changed
   `Shared.LookDev` and `Shared.LookDevReview`, the new
   `PlayerScripts.Client.World.LookDevWindR8`, and the changed
   `tools/studio/review_check_r8.luau`.
2. Start a fresh real Play session. Three checks are CLIENT-ONLY and MUTATING: run the WHOLE
   `tools/studio/review_check_r8.luau` in the CLIENT VM via Studio MCP `execute_luau`, not the
   Server VM. The `do -- 12a-wind` block guards each check with `isClient`, enables `wind_r8` through
   `LookDevReview.enable("wind_r8", game)`, reads while staged, disables, compares, and restores any
   prior active candidate; all three still emit on error.
3. Read `WIND_SET` (magnitude > 0 and <= 12; expect ~2.92 from `(2.5, 0, 1.5)`), `SWAY_TWEENS`
   (0 < count <= 30; expect 10 jemuran/sign tweens), and `WIND_RESTORE` (0 mismatches; compares the
   captured baseline `workspace.GlobalWind` and every staged Part `CFrame` / Model pivot against the
   applier's saved originals at 1e-4 tolerance, after `disable()` destroys the folder). Targets are
   `0 < M <= 12`, `30`, and `0`; a missing module or failed enable FAILs at measured -1/1, never a skip.
4. For a visual pass only, stage again from the CLIENT datamodel with
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("wind_r8", game)`; shoot
   `hub_warung`, `hub_pasar` and `canonical_overview` from `docs/v2/visual/REVIEW_CAMERAS.md` and
   watch the cloths/signs sway and the pisang/bambu lean. Call `LookDevReview.disable()` and re-read
   `LOOKDEV_LEAK 0`; stop Play without saving. Visual yes/no stays the designer's.

## Item-86 run — `npcs_r8` five more villager roles (WORK_QUEUE section M)

Implementation-only run note. **No Studio result is claimed here**; the main session owns CHECK
evidence, `CHECK_086.txt`, tracker ticks and the visual yes/no. No place is saved or published.

1. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapNpcsR8`, the changed
   `Shared.LookDev` and `Shared.LookDevReview`, the new
   `ServerScriptService.Server.World.LookDevModelsNpcsR8`, and the changed
   `tools/studio/review_check_r8.luau`. The 15 verified catalog IDs are already recorded in
   `docs/v2/visual/art/ASSET_MANIFEST.md` by the main session; agents never invent or re-source IDs.
2. Start a fresh real Play session. `npcs_r8` is a SERVER candidate (HumanoidDescription rigs): run
   the WHOLE `tools/studio/review_check_r8.luau` in the SERVER VM via Studio MCP `execute_luau`.
   MapSpec is not needed by this family — the two checks read the staged folder and its rig
   attributes directly. Stage with
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("npcs_r8", game)`.
3. Read `NPC8_ROLES` (5/5: exactly one rig per role stamped `LookDevR8="npcs_r8"` plus an
   `Accessory` descendant) and `NPC8_OUTFITS` (5/5 unique `ShirtId`+`PantsId` pairs, all with a
   non-empty `HatIds` attribute). Missing folder/rig/attribute FAILs at measured <5, never a skip.
   Guard: `LOAD_FAILURES 0 0` now sums `npcs_r8` alongside `vegetation_r7`/`npcs_r7`/`props_r7`.
4. Shoot the second row (z=14, x=-12..12, 6-stud spacing, same camera-facing yaw as `npcs_r7`)
   from the saved `Shared.ModelMapNpcsR8.savedCamera`, then call `LookDevReview.disable()` and
   re-read `LOOKDEV_LEAK 0`; stop Play without saving. Visual yes/no stays the designer's.

## Item-87 run — `npcs_idle_r8` calm villager idle (WORK_QUEUE section M)

Implementation-only run note. **No Studio result is claimed here**; the main session owns CHECK
evidence, `CHECK_087.txt`, tracker ticks and the visual yes/no. No place is saved or published.

1. Inject at runtime (not saved): `ReplicatedStorage.Shared.ModelMapNpcsIdleR8`, the changed
   `Shared.LookDev` and `Shared.LookDevReview`, the new
   `ServerScriptService.Server.World.LookDevNpcsIdleR8`, and the changed
   `tools/studio/review_check_r8.luau`. The one real catalog ID is "Standing Idle",
   `rbxassetid://71483261700852` (AssetTypeId 61); it is already recorded in
   `docs/v2/visual/art/ASSET_MANIFEST.md` by the main session, agents never invent or re-source IDs.
2. Start a fresh real Play session. `npcs_idle_r8` is a SERVER candidate and the new checks are
   SERVER-ONLY and MUTATING: run the WHOLE `tools/studio/review_check_r8.luau` in the SERVER VM via
   Studio MCP `execute_luau`. The `do -- 12d. WORK_QUEUE item 87` block stages via
   `Review.enable("npcs_idle_r8", game, { studio = true })`, is self-contained (no dependency on
   `npcs_r7`/`npcs_r8` being enabled), restores the prior candidate on error, and emits all three
   checks even on failure.
3. Read `IDLE_TRACKS` (10/10 rigs have an `Animator` with a playing, looped track whose
   `AnimationId` is exactly `rbxassetid://71483261700852`), `IDLE_SWAY` (one shared `Heartbeat`
   connection, upward-tilt <=1 degree after deterministic `pump(1/60)` ticks, and a clean restore
   audit: 10 targets, 0 mismatches, maxDelta <=1e-4) and `IDLE_COST` (real 3600-step `os.clock`
   measurement of the same pure `step()` the loop calls, <0.3 ms/step for 10 villagers; pure-Lune
   baseline ~0.0108 ms/step). Missing rig/track/loop FAILs at measured 0, never a skip. Guard:
   `LOAD_FAILURES 0 0` now sums `npcs_idle_r8` alongside `vegetation_r7`/`npcs_r7`/`props_r7`/`npcs_r8`.
4. The 10 outfits come 5+5 from `ModelMapNpcsR7.catalog/roles/slots` and
   `ModelMapNpcsR8.catalog/roles/slots` (two five-wide rows at z=8 and z=14). Shoot the staged
   rows from the saved `Shared.ModelMapNpcsR8.savedCamera`, then call `LookDevReview.disable()` and
   re-read `LOOKDEV_LEAK 0`; stop Play without saving. Visual yes/no stays the designer's.

## Item-88 run — `ambient_walkers_r8` ambient strollers (WORK_QUEUE section M)

Implementation-only SERVER-VM recipe. **No Studio result is claimed here**; the main session owns
`CHECK_088.txt`, the tracker tick and the visual yes/no. No place is saved or published.

1. Inject at runtime (not saved): the new `Shared.ModelMapAmbientWalkersR8`, the changed
   `Shared.LookDev` / `Shared.LookDevReview`, the new
   `ServerScriptService.Server.World.LookDevAmbientWalkersR8`, and the changed
   `tools/studio/review_check_r8.luau`. No asset IDs are involved — the rigs are plain R15
   `HumanoidDescription` bodies with skin colours only, so `ASSET_MANIFEST.md` is untouched.
2. Start a fresh real Play session and paste the WHOLE `tools/studio/review_check_r8.luau` into
   Studio MCP `execute_luau` in the SERVER VM. The `do -- 12e. WORK_QUEUE item 88` block is
   self-contained: it stages via `review.enable("ambient_walkers_r8", game, { studio = true })`,
   reads all five checks, disables and re-enables the prior candidate. All five emit even on error.
3. `WALKER_SPEED` reads `Humanoid.WalkSpeed` live from every staged rig (0 < rigs <= 8, every speed
   <= 8; target emitted is 8). `WALKER_MOVE` is the live "via `NpcWalk`" proof: after enabling, the
   harness lets the real `task.spawn` loops run ten real `task.wait(0.05)` steps, then compares each
   rig's `GetPivot().Position` with the saved base pivot; PASS iff at least one rig moved >0.05
   studs (measured movedCount / rigCount).
4. `WALKER_WAYPOINTS`, `WALKER_STUCK` and `WALKER_ROAD` all read ONE pure
   `ModelMapAmbientWalkersR8.simulate(90, routes())` run — the 90-second horizon is a deterministic
   1800-step sim, NOT a real 90-second wait, because the real `NpcWalk.walkTo` yields via
   `task.wait(0.05)` on every step. The sim mirrors NpcWalk's lerp, 0.5-stud arrival snap, 0.05-stud
   stall threshold and waypoint wrap. Targets: every walker >=3 waypoints reached (min emitted / 3),
   max continuous stuck <=10 s (emitted / 10), max deviation from a road corridor <=8 studs
   (emitted / 8). Lune baseline: 8 walkers, min 3 reached, 0 s stuck, 0 studs deviation.
5. Read the guard `LOAD_FAILURES 0 0` (the list now sums `ambient_walkers_r8` too). Call
   `LookDevReview.disable()` and re-read `LOOKDEV_LEAK 0`; stop Play without saving. Visual yes/no
   stays the designer's.

## Item-89 run — `day_cycle_r8` tuned Sore (WORK_QUEUE section M, CLIENT candidate)

Implementation-only CLIENT-VM recipe. **No Studio result is claimed here**; the main session owns
`CHECK_089.txt`, the tracker tick and the visual yes/no. No place is saved or published.

1. Inject at runtime (not saved) into the **Client** datamodel: `Shared.ModelMapDayCycleR8`,
   `Client.World.LookDevDayCycleR8`, the changed `Shared.LookDev` / `Shared.LookDevReview` and the
   changed `tools/studio/review_check_r8.luau`. `ServerScriptService` does not replicate Edit→Client,
   so a client applier must live under `Players.LocalPlayer.PlayerScripts.Client.World`; use
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("day_cycle_r8", game, { studio = true })`
   (it pre-registers the applier in this VM, then calls `LookDev.enable`). No asset IDs: the nine
   existing Lighting/effect properties, six Rendah lamp lights and `Lighting.ShadowSoftness` are
   restored exactly by `LookDevReview.disable()`.
2. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the CLIENT
   VM. The three item-89 checks are PURE and VM-agnostic (`do -- 12f. Item 89`): they require
   `Shared.ModelMapDayCycleR8` with a pcall, always emit, never stage and never skip. Their Lune
   baselines: `DAY_PHASES_MONOTONIC` tuned jump 0.623529 <= documented limit 0.779412 (1.25x the
   original table's own max); `DAY_1600_CONTRAST` tuned ratio 2.705297 >= target 2.592990
   (+25.20% over the original 2.160825); `DAY_MAGHRIB_UNCHANGED` 1/1. Any missing module or read
   FAILs the line rather than skipping it. The definitions are in `docs/v2/visual/DAY_CYCLE.md`.
3. Review at spawn (16:00, pure Sore) against the `day_cycle` before-shot from
   `docs/v2/visual/CANDIDATES.md`; the change is lower sun angle, warmer `ColorShift_Top`, darker
   Ambient and ShadowSoftness 0.45. The subjective yes/no (does 16:00 now read directional?) is the
   designer's — this recipe and the three numeric checks make no visual verdict. Stop Play without
   saving.

## Item-90 run — `night_r8` warm night windows and lamps (WORK_QUEUE section M, SERVER candidate)

Implementation-only SERVER-VM recipe. **No Studio result is claimed here**; the main session owns
`CHECK_090.txt`, the tracker tick and the visual yes/no. No place is saved or published.

1. Stop Play. Inject at runtime (not saved) into the **Server** datamodel: `ReplicatedStorage.Shared.ModelMapNightR8`, the new `ServerScriptService.Server.World.LookDevNightR8`, the changed `Shared.LookDev` / `Shared.LookDevReview`, the changed `ServerScriptService.Server.Main.server`, and the changed `tools/studio/review_check_r8.luau`. No asset IDs: 16 warm panes are original Parts and 12 glow sources are shadowless `PointLight`s, restored exactly by `LookDevReview.disable()`.
2. Start a FRESH real Play session and paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the **SERVER** VM. The `do -- 12g. Item 90` block is self-contained: it stages via `LookDev.enable("night_r8", { studio = true })`, drives the applier's deterministic clock override, reads the real staged panes/lights at 20:00 and 13:00, then disables and re-enables the prior candidate. Both lines emit even on error; `game`-nil in Lune is expected, a syntax/register error is not.
3. Read `NIGHT_WINDOWS` (`PASS` requires >=12 lit warm panes at 20:00 and 0 at 13:00; emits measured lit-at-20, target `12`, with `lit13`, `panes` and `clockAtCheck` in `detail`) and `NIGHT_LIGHTS` (`PASS` requires 1..24 enabled `PointLight`s with `Shadows == false`; emits enabled count, target `24`, with `shadowOffenders` and `budget` in `detail`). The applier stages 16 panes (12 facade shutter anchors + 4 Pak RT glass) and 12 lights (6 street posts + 6 torches). Both lines use `LookDevNightR8.setClockForCheck(20|13)` / `clearClockForCheck()` — a gate override that never writes `Lighting.ClockTime`, so the live clock is untouched.
4. Read the guards `LOAD_FAILURES 0 0` and `LOOKDEV_LEAK 0 leaks`. For the visual pass only, stage from the SERVER datamodel with `require(game.ReplicatedStorage.Shared.LookDevReview).enable("night_r8", game)`, set `Lighting.ClockTime` to 13 (dark panes, lamps off) then 20 (warm panes, lamps on) and shoot `spawn`, `canonical_overview` and `hub_warung` from `docs/v2/visual/REVIEW_CAMERAS.md`. Call `LookDevReview.disable()` and re-read `LOOKDEV_LEAK 0`; stop Play without saving. Visual grading — do the windows read as warm night and the lamps as a Rendah glow? — stays the designer's.
