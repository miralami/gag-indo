# `npcs_r4` handoff — WORK_QUEUE item 31 (npcs lane)

Status: **`LUNE-ONLY`**. Five real textured models downloaded, verified, decimated, uploaded and
wired as one off-by-default LookDev candidate. No Studio visual verdict is claimed; no place was
saved or published. The central registry, `CANDIDATES.md`, `ASSET_MANIFEST.md` and `tests/run.luau`
are owned by the main session and were **not** edited here.

## What shipped

- `src/shared/ModelMapNpcsR4.luau` — pure data: five real IDs, slots on real plaza ground
  (`y = MapSpec.GROUND_Y = 0.5`), `targetHeight = 5` per slot, `rotX = -pi/2` for the Z-up source,
  and a saved review camera derived from `MapSpec.SPAWN` / `MapSpec.PLAZA`.
- `src/server/World/LookDevModelsNpcsR4.luau` — SERVER-ONLY applier: `InsertService:LoadAsset`,
  anchors every `BasePart`, `CanCollide = false`, `ScaleTo(targetHeight/bodySizeY)`, `rotX + ry`,
  folder save/restore, no-ID guard and pcall on every engine call. No asset ID literals.
- `tests/specs/model_map_npcs_r4_spec.luau` — 11 passing cases: licence/attribution, real IDs,
  manifest cross-check, `targetHeight`, `rotX`, no-ID guard, anchor/collide/scale strings and the
  camera inside the real `MapSpec` ground footprint.
- `MANIFEST.md`, `sources.json`, `upload_manifest.json`, `raw/npcs_r4/*.glb`,
  `export/npcs_r4/*.glb`, `src/*.py` — provenance and reproducible pipeline.

## Toggle and review camera

From the **Server** command bar (client `LoadAsset` is blocked):

```luau
require(game.ReplicatedStorage.Shared.LookDev).enable("npcs_r4")
require(game.ReplicatedStorage.Shared.LookDev).disable() -- restore
```

Prerequisite: the main session must add `npcs_r4` to `LookDev.IDS` and `LookDev.candidates` and
require `LookDevModelsNpcsR4` from `Main.server.luau`. Unknown ids are ignored by `LookDev.register`.

| Candidate | Datamodel | Slots | camera_position | look_at_position | Verdict |
|---|---|---|---|---|---|
| `npcs_r4` | Server | 5, row on the plaza at x -16..16, z 8, y 0.5 | `{ 0, 7, 28 }` (spawn) | `{ 0, 2.5, 8 }` | blank |

The row sits on the real terrain near spawn, not in the obsolete `(500,500)` corner. Both camera
points are inside `MapSpec.PLAZA` (`|x| <= 48`, `|z| <= 42`) and the 800×800 terrain footprint.

## Commands and results

| Command | Result |
|---|---|
| `python docs/v2/visual/art/models_r4/npcs/src/source_scan.py` | 363 page-verified CC0/CC BY rows cached; Quaternius and other banned licences excluded |
| `python docs/v2/visual/art/models_r4/npcs/src/download_sources.py` | 5 real GLBs in `raw/npcs_r4/`, exact page metadata in `sources.json` |
| `python docs/v2/visual/art/models_r4/npcs/src/decimate_glb.py` | 4646→1884, 3396→1804, 896→894, 5128→1689 tris; all ≤ 2000 |
| `python docs/v2/visual/art/models_r4/npcs/src/bake_vertex_colors.py` | `petani_caping`: 62 primitives baked to `COLOR_0`, 1962 tris unchanged |
| `python docs/v2/visual/art/models_r4/npcs/src/verify_exports.py` | 5/5 textured, ≤ 2000 tris, valid buffer views; `rotX` needed only for `petani_wanita` |
| `python docs/v2/visual/art/models_r4/npcs/src/upload_models.py` | HTTP 200 on all 5 POSTs, 5 completed operations, 5 real IDs in `upload_manifest.json`; key never printed or written |
| `lune run docs/v2/visual/art/models_r4/npcs/src/run_spec.luau` | `passed=11 failed=0` |

`ROBLOX_API_KEY` was read from the environment only. No key value was written to any file.

## BLOCKED gaps / designer builds briefs

1. **Exact Indonesian headwear — designer builds.** No compliant CC0/CC BY character with a true
   *caping* or *peci* was found. The five sources are real but generic. Brief for the designer:
   keep these as base bodies, add a woven conical caping to `petani_caping` and a black velvet peci
   to `tukang_peci` as separate authored geometry, then re-export one merged textured GLB per role.
   Reference: Indonesian rice-farmer and village-official silhouettes in
   `docs/v2/visual/art/reference/README.md`. A CC BY 3.0 `bamboo hat` (Republic Clone,
   https://poly.pizza/m/9xm5jS34YV8, 22 tris) is a page-verified starting hat if the designer wants
   a licensed base; it was not ingested here because attaching it is an art decision.
2. **Polisi desa identity — designer builds.** `Male Officer` is a generic uniformed figure. Brief:
   add Indonesian village-police insignia and a local patch; no brand or real police mark.
3. **Petani wanita / pedagang wardrobe — designer builds.** The sources are a generic woman and a
   retail worker. Brief: add kerudung/apron and market-day colour accents to separate the two
   silhouettes at 5-stud scale; keep faces caricatured (D7), not uncanny.
4. **R15 re-rig — blocked in this lane.** None of the five carries an R15 humanoid rig. Three have
   external skins/clips and two are static meshes. A rigger must retarget/rebuild to R15 before any
   gameplay use; this lane only stages anchored review dummies.
5. **Visual verdict — blocked.** No Studio capture was taken and no agent graded these models.
   The main session's designer/vision pass fills the verdict cell from the saved camera above.
