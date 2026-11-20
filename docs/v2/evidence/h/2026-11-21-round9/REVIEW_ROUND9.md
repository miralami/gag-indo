# Round-9 check harness — REVIEW_ROUND9.md (WORK_QUEUE section M)

Session: `<fill: Studio session name / placeId>`. No place is saved or published in this round.
Harness fix (2026-11-21): `bboxAABB`/`bboxCentre` now measure single BasePart/MeshPart assets (teh-tehan) directly instead of returning nil; VEG_OVERLAP still requires `unreadable == 0`. Re-run needed in Studio.

## 1. Edit-mode bake (step 1)

Stop Play. Run `tools/studio/bake_lookdev_assets.luau` in the EDIT datamodel via Studio MCP `execute_luau`. The bake is runtime-only: NEVER save the place after it. Verify `ServerStorage.LookDevAssets` is empty after a no-save restart, as in round 8's process fix.

## 2. Run order for `review_check_r8.luau`

Start a fresh real Play session after the bake. Paste the WHOLE file into Studio MCP `execute_luau` in this order:

1. SERVER datamodel — scene checks: `LOAD_FAILURES`, `SKY_DEFAULT`, `GRASS_ON_BEDS`, `HATS`, `PROPS_VISIBLE`, `PROPS_ON_GRASS`, `VEG_COUNT`, `VEG_SPECIES`, `BED_FLUSH`, `VEG_HUB_pasar`, `VEG_HUB_gelap`, `VEG_HUB_warung`, `VEG_HUB_ronda`, `VEG_HUB_polisi`, `VEG_HUB_pakrt`, `VEG_SPECIES_HUB`, `VEG_OVERLAP`, `PLOT_FENCE`, `GATE_CLEAR`, `SAWAH_TOPS`, `SAWAH_WATER`, `SAWAH_VERGE`, `GUBUK`, `RIVER_BANK_VEG`, `BRIDGE_RAILS`, `BRIDGE_WALKABLE`, `VEG_NEAR`, `PROP_SIZE`, `CAMERA_CLEAR`, `LOOKDEV_LEAK`. The three r8 hub-veg families (item 70) read the staged `LookDevModelsVegetationHubR8_hubveg_r8` folder; they FAIL at measured 0 in a clean Play when that candidate is not staged. The two r8 plots families (item 71) read the staged `LookDevPlotsR8_plots_r8` folder; `PLOT_FENCE` and `GATE_CLEAR` FAIL in a clean Play when that candidate is not staged. `GATE_CLEAR` probes the opening in the marker's own CFrame (plot yaw), lifted 0.05 above the ground surface to avoid touching the collidable ground slab. The four r8 sawah families (item 72) read the staged `LookDevSawahR8_sawah_r8` folder; all FAIL at measured 0 in a clean Play when that candidate is not staged. `SAWAH_TOPS` raycasts Terrain only at the eight `MapSpec.paddyWater()` pane centres (a missing Terrain/read is a FAIL); `SAWAH_WATER` requires four water-sheet groups of two valid panes; `SAWAH_VERGE` requires >=40 verge tufts; `GUBUK` requires one terrace-2 roof with four posts and one bench sharing its `Gubuk` id. The three r8 river families (item 73) read the staged `LookDevRiverR8_river_r8` folder and `MapSpec.BRIDGE`; all FAIL at measured 0 when the candidate is not staged or MapSpec cannot be read. `RIVER_BANK_VEG` requires >=30 veg within 40 studs of the bridge centre on both banks; `BRIDGE_RAILS` requires both sides to have a deck-spanning rail and >=4 posts; `BRIDGE_WALKABLE` requires both sides and a clear |x|<4 corridor with walkable width >=8.
2. CLIENT datamodel — client-owned checks: the same lines where observable, plus `CLOUD_COVER`. Run water, grade, sounds and clouds candidates here; `LOOKDEV_LEAK` must also be run in this datamodel for client-owned candidates.

`CAMERA_CLEAR` (item 69) is SERVER-ONLY: it loads `ReviewCameras`, which requires MapSpec from
`ServerScriptService`, so the check is skipped in the Client VM to avoid a `WaitForChild` block.

## 3. Reading CHECK lines

Every line is `CHECK <name> PASS|FAIL <measured> <target>`. `PASS` means `measured` met `target`; `measured` may be a number or a formatted string. `FAIL` is an objective failure, not a visual verdict. The call returns `{ order = ..., checks = ..., byName = ... }`; each check carries its raw `detail`.
