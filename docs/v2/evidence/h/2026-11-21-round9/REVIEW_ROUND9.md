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
