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
