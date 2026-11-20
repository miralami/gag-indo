# Round-7 check harness — REVIEW_ROUND7.md (WORK_QUEUE item 53)

Objective checks only. `tools/studio/review_check_r7.luau` prints exactly eight lines of the form
`CHECK <name> PASS|FAIL <measured> <target>` and returns a results table. It runs in the **Server**
datamodel during a real Studio Play session. No visual verdict is made here; visual grading belongs
to the designer. A missing folder, attribute, service or failed read is a FAIL, never a skip.

## 1. Order of operations

1. **Edit-mode bake first (item 54).** Stop Play. In the **Edit** datamodel run
   `tools/studio/bake_lookdev_assets.luau` through `execute_luau` with `datamodel_type="Edit"`.
   It loads the real model/hat IDs with `game:GetObjects`, strips every Script/LocalScript/
   ModuleScript and parents the result under `ServerStorage.LookDevAssets`. Do **not** save the
   place. Repeat the bake before each review or after any asset/code change.
2. Start a real Play session. In a **fresh Play with no enable call**, paste the whole contents of
   `tools/studio/review_check_r7.luau` into `execute_luau` with `datamodel_type="Server"`. Save the
   `SKY_DEFAULT` and `GRASS_ON_BEDS` lines from this run (item 55 requires the fresh-Play state).
3. Still in Play, **Server** datamodel, run the enable sequence below, then run the same harness
   again and save the full eight-line output.
4. Separately inspect the Play console (F9) for any `not authorized` line. The harness does not read
   console text; it reads only the three load-failure counters.

## 2. Exact enable sequence (Server datamodel, dot syntax)

The reviewed sequence used by the main session, in this order, via `execute_luau` with
`datamodel_type="Server"` (one `execute_luau` call is fine):

```luau
local World = game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("World")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
require(World.LookDevModelsVegetationR7).apply()
require(World.LookDevModelsNpcsR7).apply()
require(World.LookDevModelsPropsR7)
require(Shared.LookDev).enable("props_r7")
```

The third `require` is required before `enable("props_r7")`: the Server command-bar VM is separate
from the boot-time server VM, so without it `LookDev` has no props applier and `enable` returns ok
while staging nothing. The alternative `LookDevReview.enable(id, game)` sequence also prepares the
applier, but never use the colon form. The harness itself never enables and never restores a
candidate.

All three staged folders must exist in `workspace` when the harness runs:

- `LookDevModelsVegetationR7_vegetation_r7`
- `LookDevModelsNpcsR7_npcs_r7`
- `LookDevModelsPropsR7_props_r7`

If a later enable restores/detaches an earlier family's folder, re-stage it before measuring. A
missing folder is a FAIL for that family's checks; it is not omitted from the eight lines.

## 3. Fixed cameras and measurement contract

| Check | Measurement |
| --- | --- |
| `LOAD_FAILURES` | `LookDevFailures.get("vegetation_r7") + .get("npcs_r7") + .get("props_r7")`; PASS only at 0. |
| `SKY_DEFAULT` | `Lighting:FindFirstChildOfClass("Sky").SkyboxFt` equals `rbxassetid://2835177931` (SkyMapR6 set E `SkyboxFt`); the plain integer `2835177931` is also accepted. Fresh Play, no enable call. |
| `GRASS_ON_BEDS` | Six `SpawnGroundMapR6.flowerBeds` centres plus every `Workspace` part tagged `PlotAnchor`. The grid-aligned 4-stud `Terrain:ReadVoxels` cell containing each sample at **y = 4** (`math.floor(coord / 4) * 4` .. `+4` on each axis). A sample passes only when at least one returned material is not `Enum.Material.Grass`; a failed read counts as a failure sample. PASS only at 0 failed samples. |
| `HATS` | Under `LookDevModelsNpcsR7_npcs_r7`, rigs tagged `LookDevR7="npcs_r7"` with `Role` in `{petani, petani_wanita, polisi, pak_rt, pedagang}`. Each of petani, petani_wanita, polisi and pak_rt needs at least one `Accessory` descendant; measured is the number of those four roles satisfied out of 4. |
| `PROPS_VISIBLE` | Under `LookDevModelsPropsR7_props_r7`, the six `PropSlot` models (gerobak, sumur, lapak, pagar_bambu, alat_tani, jemuran). Raycast from the folder's `ReviewCameraPos` attribute to each model's bounding-box centre, filtered to exclude the subject's own descendants and every player character; a first hit by anything else blocks it. The centre must also lie inside a 70° cone around `ReviewLookAt - ReviewCameraPos`. PASS only at 6/6. The applier writes those two Vector3 attributes (7 studs up, looking at the row centre at y=2; `front` was corrected 18→28 on attempt 2 so all six row ends lie inside the cone); missing attributes make the check FAIL. |
| `PROPS_ON_GRASS` | Same six models; their bounding-box centre's 4-stud Terrain cell at **y = 4** must contain at least one material other than Grass. A missing model counts as a failing sample. PASS only at 0. |
| `VEG_COUNT` | Under `LookDevModelsVegetationR7_vegetation_r7`, models tagged `LookDevR7="vegetation_r7"`. Fixed camera eye `{0,20,150}`, look `{0,8,96}`; count centres within 100 studs of the eye and inside a 70° cone. PASS at >= 60. |
| `VEG_SPECIES` | Distinct `Species` string attribute values among the same in-cone, in-range vegetation models. PASS at >= 8. |

The y=4 voxel choice is shared by both grass checks so beds and props are judged against the same
Terrain layer; it is printed in the returned detail table.

## 4. Save the raw output

Copy the printed `CHECK ...` lines verbatim — no edits, no reformatting, no dropped FAIL lines — to:

```
docs/v2/evidence/h/2026-11-20-round7/CHECK_<item>.txt
```

For this harness the file is `CHECK_53.txt`; the fresh-Play sky/ground run belongs in
`CHECK_55.txt`, and the later family checks use `CHECK_54.txt` / `CHECK_56.txt` / `CHECK_57.txt` /
`CHECK_58.txt`. The returned results table may be appended unchanged, but the eight `CHECK` lines
are the evidence. Commit each `CHECK_*.txt` with the item that produced it. A claim of
`SEEN-IN-STUDIO` requires that committed file; a Lune spec alone never ticks a section-K item.

## 5. Visual grading

This document and the harness record counts, materials and geometry only. No screenshot is retained
here and no visual is graded: all yes/no visual decisions belong to the designer. If a check prints
FAIL after two fix attempts, mark the item `BLOCKED — <paste the FAIL line>` per section-K rule 2;
never weaken a check to make it pass.

No place was saved or published by this handoff, and `ROBLOX_API_KEY` is neither printed nor used.

## 6. Recorded Studio results (2026-11-20)

Two real Play runs in the place `Development-Juragan-Desa` (placeId 132087524375529), Server
datamodel, harness executed verbatim from `tools/studio/review_check_r7.luau`. No `not authorized`
line in either console.

- **Fresh Play, no enable call** (item 55 contract): `SKY_DEFAULT PASS`, `GRASS_ON_BEDS PASS`;
  the six family checks correctly FAIL because no family is staged. Saved to `CHECK_55.txt`.
- **Staged run** — after `LookDevModelsVegetationR7.apply()`, `LookDevModelsNpcsR7.apply()`,
  `require(LookDevModelsPropsR7)` then `LookDev.enable("props_r7")` — all eight lines PASS:

```
CHECK LOAD_FAILURES PASS 0 0
CHECK SKY_DEFAULT PASS rbxassetid://2835177931 rbxassetid://2835177931
CHECK GRASS_ON_BEDS PASS 0 0
CHECK HATS PASS 4 4
CHECK PROPS_VISIBLE PASS 6 6
CHECK PROPS_ON_GRASS PASS 0 0
CHECK VEG_COUNT PASS 67 60
CHECK VEG_SPECIES PASS 10 8
```

Attempt 1 (`ATTEMPT1_console_raw.txt`) had `PROPS_VISIBLE FAIL 4 6` and `VEG_COUNT FAIL 53 60`;
both were fixed in data only (prop review camera `front` 18→28; 20 far-band vegetation cells inside
the fixed cone) without weakening the harness. Attempt 2 raw console: `ATTEMPT2_console_raw.txt`.
The per-item evidence files are `CHECK_53.txt`, `CHECK_54.txt`, `CHECK_55.txt`, `CHECK_56.txt`,
`CHECK_57.txt` and `CHECK_58.txt`.
