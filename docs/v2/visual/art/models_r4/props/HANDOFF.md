# `props_r4` — LookDev review handoff (WORK_QUEUE item 31, props lane)

Status: `LUNE-ONLY`. This is a static handoff with no Studio screenshot, no `SEEN-IN-STUDIO` claim
and no visual yes/no. The candidate is OFF BY DEFAULT; verdict cells stay blank. No file was saved
or published and no commit was made in this lane. The main session owns the central registry edits
listed below.

Seven real textured `Model` assets were uploaded through completed Open Cloud operations using
`ROBLOX_API_KEY` (never printed or written). Source, licence, author, attribution and face counts
are in `SOURCE_LICENSES.md` and `prepare_report.json`; asset IDs and operation IDs are in
`upload_manifest.json`. No ID was invented.

## Real uploads

| Slot | Export GLB | Asset ID | Operation ID | targetHeight | rotX |
|---|---|---:|---|---:|---:|
| `gerobak` | `export/gerobak.glb` | `119426685469058` | `f651b872-e57c-4ab8-9eff-5ec3afb1a32e` | 6 | 0 |
| `sumur` | `export/sumur.glb` | `95025959179405` | `60b22273-5646-4a4b-b90a-ed6a35a72af3` | 5 | 0 |
| `lapak` | `export/lapak.glb` | `115924626989907` | `cd2cd78f-2b2a-428e-a222-4654234fcf90` | 8 | 0 |
| `pagar_bambu` | `export/pagar_bambu.glb` | `103341007913673` | `fb9a9077-3469-40d1-9b56-8e7b1b40b86d` | 5 | 0 |
| `alat_tani` | `export/alat_tani.glb` | `109848917287023` | `4aacfef0-a396-4073-a99a-9b0f1fc28c9b` | 3 | 0 |
| `karung` | `export/karung.glb` | `87487192428396` | `63e9a304-2b34-4bbb-8eb6-3d8f3a84d53a` | 2 | 0 |
| `jemuran` | `export/jemuran.glb` | `138444489439223` | `ddf1afce-d119-484d-a9fe-5bc2680cec0c` | 7 | 0 |

## Staging and saved camera

All coordinates are absolute world studs on real playable terrain, inside
`MapSpec.TERRAIN_HALF = 400`, above `MapSpec.GROUND_Y = 0.5`. Two rows sit on the plaza's north-east
shoulder outside all six hub footprints and the plot connector ring. Every source was Y-up, so
`rotX = 0` throughout; the applier still honours a non-zero `rotX`.

| Row | Slots | Camera position | Look-at |
|---|---|---|---|
| north | `gerobak` (130, 116), `sumur` (138, 116), `lapak` (146, 116) | `{ 142, 9, 146 }` | `{ 142, 3, 122 }` |
| south | `pagar_bambu` (130, 128), `alat_tani` (138, 128), `karung` (146, 128), `jemuran` (154, 128) | same | same |

Slot `ry` is `math.pi` on the north row (faces the saved camera at +Z) and `0.35` on the south row
(fence and clothesline read side-on rather than edge-on).

## Files added by this lane

- `src/shared/ModelMapPropsR4.luau` — pure data: seven IDs, slots, `targetHeight`, `rotX`, camera,
  staging. No game APIs, no instances, no ID construction.
- `src/server/World/LookDevModelsPropsR4.luau` — SERVER-ONLY applier. No asset ID literals.
- `tests/specs/model_map_props_r4_spec.luau` — static spec for IDs, licence chain, adapter shape and
  `MapSpec` footprint.
- `docs/v2/visual/art/models_r4/props/{src,raw,export,prepare_report.json,upload_manifest.json,SOURCE_LICENSES.md,HANDOFF.md}` —
  pipeline, source evidence, exports and this handoff.

## Central edits still owned by the main session

These files were deliberately NOT touched by this lane:

- `src/shared/LookDev.luau`: add `props_r4` to `LookDev.IDS` and `LookDev.candidates`; otherwise
  `LookDev.register` silently ignores the applier.
- `src/shared/LookDevReview.luau`: add `props_r4 = { datamodel = "server", path = { "World", "LookDevModelsPropsR4" } }`.
- `src/server/Main.server.luau`: require the applier at boot.
- `tests/run.luau`: add `require("./specs/model_map_props_r4_spec")`.
- `docs/v2/visual/art/ASSET_MANIFEST.md`: add the seven ID / source / licence rows.
- `docs/v2/visual/CANDIDATES.md` and `docs/v2/evidence/`: only after a Studio pass records a verdict.

## Review from a SERVER command bar

After the central edits land:

```luau
require(game.ReplicatedStorage.Shared.LookDevReview).enable("props_r4", game)
require(game.ReplicatedStorage.Shared.LookDevReview).disable()
```

`InsertService:LoadAsset` is blocked on the client, so this must run in the Server datamodel. Each
apply creates a Workspace folder named `LookDevModelsPropsR4_props_r4`, saves any same-named folder
first, and loads each slot as `R4_<slot>`. A failed load warns with the family and slot and is
skipped. `disable()` restores the folder that was there before, if any.

Every loaded model is oriented with `rotX + ry`, normalised with
`Model:ScaleTo(targetHeight / bodySizeY)` and then every BasePart descendant is anchored with
`CanCollide = false`. Anchoring stops a model falling through the ground; non-colliding is
deliberate because this staging is on walkable terrain near spawn — a colliding display model
would be an invisible player blocker. Missing, zero, fractional or negative IDs are rejected before
`LoadAsset`. Every engine call is wrapped in `pcall`.

## Validation performed

- Standalone Lune runner for `tests/specs/model_map_props_r4_spec.luau` (no `tests/run.luau` edit):
  **7 passed, 0 failed**.
- `lune run tests/run` baseline: **2103 passed, 9 failed**. All nine failures are in other active
  lanes (`lookdev_corner_spec`, `model_map_r3_spec`, `sky_map_r3_spec`); none touches `props_r4`.
  The new spec is deliberately not registered there yet.
- Selene on `src/shared/ModelMapPropsR4.luau` and `src/server/World/LookDevModelsPropsR4.luau`:
  **0 errors, 0 warnings, 0 parse errors**. On the spec file, Selene 0.27.1 with `std = "roblox"`
  reports the same `require("@lune/fs")` lint as the existing `model_map_r3_spec.luau`; Lune itself
  runs the spec cleanly.

These are static checks only. Studio insertion, screenshot capture and visual judgment remain for
the main session's vision observer.

## Sourcing decisions

No designer builds needed. All seven slots were filled by compliant real CC0 / CC BY models; no
mesh was generated by script, CSG or Roblox primitives. A grey-only Poly Pizza washing-line
candidate was rejected before upload in favour of the CC0 Grab3D `Clothesline`. The Grab3D package
manifest carries `extras.generator: "Created by grab3d"`; that generation note is disclosed in
`SOURCE_LICENSES.md` alongside the verbatim CC0 licence text.
