# Round-9 check harness — REVIEW_ROUND9.md (WORK_QUEUE section M)

Session: `<fill: Studio session name / placeId>`. No place is saved or published in this round.
Harness fix (2026-11-21): `bboxAABB`/`bboxCentre` now measure single BasePart/MeshPart assets (teh-tehan) directly instead of returning nil; VEG_OVERLAP still requires `unreadable == 0`. Re-run needed in Studio.

## 1. Edit-mode bake (step 1)

Stop Play. Run `tools/studio/bake_lookdev_assets.luau` in the EDIT datamodel via Studio MCP `execute_luau`. The bake is runtime-only: NEVER save the place after it. Verify `ServerStorage.LookDevAssets` is empty after a no-save restart, as in round 8's process fix.

## 2. Run order for `review_check_r8.luau`

Start a fresh real Play session after the bake. Paste the WHOLE file into Studio MCP `execute_luau` in this order:

1. SERVER datamodel — scene checks: `LOAD_FAILURES`, `SKY_DEFAULT`, `GRASS_ON_BEDS`, `HATS`, `PROPS_VISIBLE`, `PROPS_ON_GRASS`, `VEG_COUNT`, `VEG_SPECIES`, `BED_FLUSH`, `VEG_HUB_pasar`, `VEG_HUB_gelap`, `VEG_HUB_warung`, `VEG_HUB_ronda`, `VEG_HUB_polisi`, `VEG_HUB_pakrt`, `VEG_SPECIES_HUB`, `VEG_OVERLAP`, `VEG_NEAR`, `PROP_SIZE`, `CAMERA_CLEAR`, `LOOKDEV_LEAK`. The three r8 hub-veg families (item 70) read the staged `LookDevModelsVegetationHubR8_hubveg_r8` folder; they FAIL at measured 0 in a clean Play when that candidate is not staged.
2. CLIENT datamodel — client-owned checks: the same lines where observable, plus `CLOUD_COVER`. Run water, grade, sounds and clouds candidates here; `LOOKDEV_LEAK` must also be run in this datamodel for client-owned candidates.

`CAMERA_CLEAR` (item 69) is SERVER-ONLY: it loads `ReviewCameras`, which requires MapSpec from
`ServerScriptService`, so the check is skipped in the Client VM to avoid a `WaitForChild` block.

## 3. Reading CHECK lines

Every line is `CHECK <name> PASS|FAIL <measured> <target>`. `PASS` means `measured` met `target`; `measured` may be a number or a formatted string. `FAIL` is an objective failure, not a visual verdict. The call returns `{ order = ..., checks = ..., byName = ... }`; each check carries its raw `detail`.
