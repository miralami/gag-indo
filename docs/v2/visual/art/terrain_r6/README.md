# Terrain r6 — tuned built-in Terrain colours (candidates, OFF by default)

WORK_QUEUE section J item 46. Two CLIENT candidates, `terrain_r6_a` and `terrain_r6_b`, share one
applier (`src/client/World/LookDevTerrainR6.luau`) and one pure-data module
(`src/shared/TerrainMapR6.luau`). Each is a candidate **awaiting a designer yes**; neither is shipped
on by default.

The designer said `textures_r4` read as a "red desert with straw grass". That candidate installed
CC0 base-material overrides on Terrain too. These variants do **not** do that: Terrain keeps its
built-in material and only its `GetMaterialColor`/`SetMaterialColor` values are tuned. CC0 maps stay
on parts and meshes only. No asset ID is introduced — every map URL comes from `TextureMapR4`.

## Palettes

Plain `{r,g,b}` triples (0–255), converted to a colour at apply time. Exact prior Terrain colours
are captured with `GetMaterialColor` and restored on disable; Water is untouched.

| Terrain material | `terrain_r6_a` | `terrain_r6_b` |
|---|---|---|
| Grass (lush tropical green / brighter olive) | `{ 74, 148, 62 }` | `{ 118, 158, 66 }` |
| Ground (warm brown / lighter sandy brown) | `{ 140, 104, 72 }` | `{ 176, 148, 106 }` |
| Mud (dark wet sawah / medium wet) | `{ 72, 60, 44 }` | `{ 104, 88, 66 }` |

Both variants apply the **same** part/mesh CC0 override set: `Brick`, `Concrete`, `Slate`, `Metal`,
`Wood`, `WoodPlanks`, mapped to the existing `TextureMapR4` variants `brick`, `plaster`,
`clay_tile`, `corrugated_metal`, `bilik`, `weathered_planks`. `Grass`, `Ground`, `Mud`,
`Cobblestone`, `Rock` and `Sand` get no base-material override. Every override string is restored
exactly and every created `MaterialVariant` is destroyed on disable.

## Saved review camera

One shared spawn camera for before/after shots, copied from `SPAWN_DRESSING_R5.md`:

- eye = `{ 0, 20, 72 }`
- look = `{ 0, 5, 14 }`

The applier never moves the camera.

## Review

Toggle with dot syntax from a Studio command bar / `execute_luau` VM:

```luau
require(game.ReplicatedStorage.Shared.LookDevReview).enable("terrain_r6_a", game)
require(game.ReplicatedStorage.Shared.LookDevReview).disable()

require(game.ReplicatedStorage.Shared.LookDevReview).enable("terrain_r6_b", game)
require(game.ReplicatedStorage.Shared.LookDevReview).disable()
```

Plain `LookDev.enable("terrain_r6_a")` / `LookDev.enable("terrain_r6_b")` also work in a VM where
the applier is already registered. Both are client appliers.

**Before/after shots are taken by the MAIN SESSION in Studio.**
No screenshot was captured or graded for this candidate, no screenshot file is claimed here, nothing
was saved or published, and no Studio appearance verdict is made by an agent. The designer yes/no cells in
`docs/v2/visual/CANDIDATES.md` are blank for both rows.
