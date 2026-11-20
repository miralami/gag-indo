# Textures r4 — base-material overrides, full surface coverage

WORK_QUEUE item 29. Twelve CC0 1K PBR sets (36 maps) applied as `MaterialVariant`s
with `BaseMaterial` set and installed through `MaterialService:SetBaseMaterialOverride`,
so all matching Parts **and Terrain** change — not just name-matched MeshParts.
Off by default; no visual verdict is claimed here.

## Toggle

```
require(game.ReplicatedStorage.Shared.LookDev).enable("textures_r4")
require(game.ReplicatedStorage.Shared.LookDev).disable()
```

Studio-only gate. `.disable()` restores every saved base-material override string
exactly and destroys the temporary variants; shipping defaults are untouched.
The applier is inert until the main session adds `textures_r4` to the central
`LookDev` registry and requires `LookDevTexturesR4` in the client bootstrap.

## What is covered

| Base material | Variant | Surface | Source | Studs per tile |
| --- | --- | --- | --- | --- |
| Grass | `R4_DryGrass` | dry / withered grass | Poly Haven `withered_grass` | 10 |
| Ground | `R4_Laterite` | laterite red dirt | Poly Haven `red_laterite_soil_stones` | 10 |
| Mud | `R4_PaddyMud` | rice-paddy mud / wet clay | ambientCG `Ground026` | 8 |
| Cobblestone | `R4_Cobblestone` | cobblestone path | Poly Haven `cobblestone_floor_04` | 6 |
| WoodPlanks | `R4_WeatheredPlanks` | weathered planks | Poly Haven `weathered_planks` | 8 |
| Wood | `R4_Bilik` | woven bamboo / bilik | Poly Haven `bamboo_wall_02` | 6 |
| Brick | `R4_BrickWall` | weathered brick wall | Poly Haven `worn_brick_wall` | 6 |
| Concrete | `R4_PlasterWall` | weathered plaster wall | Poly Haven `blue_plaster_weathered` | 8 |
| Slate | `R4_ClayTile` | clay roof tile | Poly Haven `clay_roof_tiles_03` | 8 |
| Metal | `R4_CorrugatedMetal` | corrugated seng | Poly Haven `worn_corrugated_iron` | 8 |
| Rock | `R4_RiverBank` | riverbank stones | Poly Haven `river_small_rocks` | 12 |
| Sand | `R4_SandPath` | sandy dirt path | Poly Haven `stony_dirt_path` | 8 |

`TextureMapR4.surfaces` also aliases `grass`, `ground`, `mud`, `wood`, `slate`,
`paddy_mud`, `laterite`, `bilik`, `clay_tile`, `plaster`, `corrugated_metal` and
`dry_grass`, so the named r4 surfaces are explicit in data, not inferred from names.

## Review aid

- `render/contact_sheet.png` — labelled colour maps, one tile per surface.
- `render/contact_sheet_maps.png` — diffuse / normal / roughness per surface.
- `MANIFEST.md`, `download_manifest.json`, `upload_manifest.json` — source URLs,
  authors, CC0 licence text, MD5s, operation IDs and real asset IDs.

The sheets are dumps of the downloaded maps, not Studio screenshots. The
designer/vision observer owns the yes/no.

## Saved review camera (absolute world coordinates)

Derived from `MapSpec.SPAWN` (`{ x = 0, y = GROUND_Y, z = 28, lookZ = -1 }`),
camera behind spawn looking north across the plaza, matching the absolute-camera
convention in `docs/v2/visual/art/daycycle/README.md`. Both points are inside the
mapped plaza/lapangan area; no off-map position is used.

| Shot id | `camera_position` | `look_at_position` |
| --- | --- | --- |
| `spawn_surface_override` | `{ 0, 12, 52 }` | `{ 0, 3, -20 }` |

No screenshot, visual grade or Studio claim is recorded here.

## Local spec check

Before the main session merges the spec into `tests/run.luau`:

```
lune run docs/v2/visual/art/textures_r4/src/run_spec.luau
```
