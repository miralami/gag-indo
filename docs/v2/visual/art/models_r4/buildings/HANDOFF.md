# buildings_r4 — handoff (WORK_QUEUE item 31 lane)

**Status: `LUNE-ONLY`.** Four real textured CC0 GLBs downloaded, decimated, exported and uploaded.
Static spec passes. No Studio load, screenshot, visual grade, place save or publish happened.
Verdict cell stays blank; the main session owns registry, `CANDIDATES.md`, `ASSET_MANIFEST.md` and
`tests/run.luau` integration. This lane did not touch those shared files.

## What shipped

| Slot | Source | Exported file | Tris | Target height | Real Model ID |
|---|---|---|---:|---:|---:|
| `rumah` | Grab3D Stilt House CC0 | `export/buildings_r4/rumah_r4.glb` | 7,569 | 22 | `134692206104779` |
| `kandang` | Grab3D Chicken Coop CC0 | `export/buildings_r4/kandang_r4.glb` | 7,616 | 6 | `102638587410748` |
| `gudang` | Grab3D Garden Shed CC0 | `export/buildings_r4/gudang_r4.glb` | 7,560 | 10 | `108444766706310` |
| `warung` | Grab3D Market Stall CC0 | `export/buildings_r4/warung_r4.glb` | 7,460 | 9 | `123167704485524` |

Every ID is from a completed Open Cloud `POST /assets/v1/assets` → operation poll with
`done = true`; see `upload_manifest.json`. Key read from `ROBLOX_API_KEY` only; never printed,
logged or written. Raw source pages, direct URLs, exact licence quote, author and hashes are in
`SOURCE_LICENCES.md` and `source_verification.json`. Export hashes and per-ratio counts are in
`decimation_report.json`.

Licence result: all four are **CC0 1.0 Universal** from Grab3D, author **Grab3D**; attribution is
not required, but the provenance credit string is recorded. Quaternius, Creator Store, NC/ND,
Free Standard and unknown licences were excluded. Grab3D states these Lightweight pieces are
procedural Blender kits with baked PBR textures; the downloaded assets are real JPEG-textured GLBs
(base colour, roughness/metallic, some normal maps), not grey boxes or script-built placeholders
made by this lane.

## Decimation

Pinned tool: `@gltf-transform/cli@4.5.1` (`weld` → `simplify --error 0.05` at the highest tested
ratio reaching ≤7,800 tris → `resize --width 1024 --height 1024`). Budget from
`SOURCING_BUILDINGS_VEG.md`: landmark ≤8,000 tris. Results:

- `rumah`: 20,400 → 7,569 (ratios 0.38/8518, 0.33/8136, 0.28/7848, 0.23/7569).
- `kandang`: 18,576 → 7,616 (0.42/9034, 0.37/8586, 0.32/8200, 0.27/7906, 0.22/7616).
- `gudang`: 11,860 → 7,560 (0.66/8402, 0.61/7956, 0.56/7560).
- `warung`: 15,744 → 7,460 (0.50/8170, 0.45/7460).

Every export still has ≥1 embedded JPEG image and ≥1 material with `baseColorTexture`.
`rumah`'s `stilt-house_door_l` node gets `scale.y = 1.12`: source door 2.088 m of 7.197 m would be
6.38 studs at 22 studs; patched door is 2.3386 m → ~7.25 studs at `targetHeight = 22`, still under
the eave. No other geometry edits.

## Review staging and camera

Pure data: `src/shared/ModelMapBuildingsR4.luau`. Staging is on **real MapSpec terrain**, replacing
the off-map r3 `(500,500)` corner idea: origin `{ 0, 0.5, 20 }` = `SPAWN.x`, `SPAWN.z - 8`.
Slots form a row at `z = 20` with `rumah` at `x = -38` (front toward +Z, `ry = math.pi`) and the
other three at `x = 4/22/40`, `ry = 0`. `rotX = 0` for all four; the field exists for Z-up imports.

Saved camera (absolute, inside `MapSpec.TERRAIN_HALF = 400`):

- `camera_position = { 0, 22, 84 }`
- `look_at_position = { 0, 7, 20 }`

## Server toggle

`src/server/World/LookDevModelsBuildingsR4.luau` is SERVER-ONLY (`InsertService:LoadAsset` is blocked
on the client). Main session must require it from `Main.server.luau` and add `buildings_r4` to the
LookDev registry/IDS. From the **Server** command bar:

```luau
require(game.ReplicatedStorage.Shared.LookDev).enable("buildings_r4")
require(game.ReplicatedStorage.Shared.LookDev).disable()
```

Dot syntax, not colon. Each apply creates `Workspace.LookDevModelsBuildingsR4_buildings_r4`, saves
any same-named previous folder, loads each slot, anchors every `BasePart`, sets `CanCollide = false`,
scales with `ScaleTo(targetHeight / bodySizeY)`, applies `rotX + ry`, and places the bounding-box
bottom on `MapSpec.GROUND_Y`. All engine calls are `pcall`'d; failed loads warn and never throw.
`restore()` destroys the active folder and re-parents the previous one. No asset ID literal appears
in the applier.

## Commands and results

Run from repository root:

```powershell
python docs/v2/visual/art/models_r4/buildings/scripts/fetch_sources.py
python docs/v2/visual/art/models_r4/buildings/scripts/inspect_glb.py docs/v2/visual/art/models_r4/buildings/raw/buildings_r4/*.glb
python docs/v2/visual/art/models_r4/buildings/scripts/decimate.py
python docs/v2/visual/art/models_r4/buildings/scripts/upload_buildings.py
lune run docs/v2/visual/art/models_r4/buildings/scripts/run_spec.luau
```

- `fetch_sources.py`: licence page HTTP 200, origin page HTTP 200, four source pages HTTP 200,
  four GLBs HTTP 200; glTF magic verified; hashes written.
- `inspect_glb.py`: raw tris 20,400 / 18,576 / 11,860 / 15,744; images 2 / 3 / 3 / 2; textured
  material present in all four; `COLOR_0 = false` (texture-based).
- `decimate.py`: four exports ≤8,000 tris, images and textured materials retained.
- `upload_buildings.py`: four POSTs HTTP 200, four operations completed with real `assetId`. First
  attempt POSTed `rumah` then hit a manifest-key `KeyError` before recording the operation; no ID
  from that orphan operation was used. The script was fixed and re-run; the four IDs above are the
  recorded completed operations.
- `run_spec.luau`: **All 9 tests passed** (local runner; central `tests/run.luau` not edited).

## BLOCKED gaps / designer builds

- **BLOCKED — visual verdict:** no Studio capture or vision review. Designer decides yes/no from the
  camera above; no agent graded these models.
- **BLOCKED — Studio proof:** no `SEEN-IN-STUDIO` claim; place never saved or published.
- **Designer builds required for the four requested buildings: none.** All four had compliant CC0
  downloads. Optional polish briefs, if the verdict fails:
  - `rumah`: localise the stilts/roof and remove the source water patch + rowing boat; keep the
    patched door ≥7 studs at 22 studs. Reference: `source_verification.json` Stilt House page.
  - `warung`: add a `WARUNG` sign and a bilik/cloth awning to the market stall; keep it under the
    8,000-tri budget. Reference: `https://grab3d.com/models/buildings/market-stall/`.
  - `gudang`: add a rice-sack/clutter cluster if the shed reads too generic.
- Main session must merge `ModelMapBuildingsR4`, the applier, spec registration, candidate row and
  central asset manifest. Until then `buildings_r4` is not toggleable in a synced client.
