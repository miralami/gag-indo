# Designer kit — `ServerStorage.DesignerKit` (WORK_QUEUE item 49)

Status: Studio-only, manually invoked. Source/data checks are `LUNE-ONLY`; no Studio load,
no screenshot and no visual verdict are claimed here. The kit is a drag-source folder for
the designer, not a LookDev candidate and not a spawn dressing pass.

## Run it

In Studio, in the **Server** Command Bar (Edit mode, Rojo synced):

```lua
require(game.ServerScriptService.Server.World.DesignerKitBuilder).build()
require(game.ServerScriptService.Server.World.DesignerKitBuilder).clear()
```

`build(parent?)` makes exactly one Folder named `DesignerKit` under `parent`, or under
`ServerStorage` when omitted. `clear(parent?)` destroys only that exact folder. Requiring
the module does nothing. Failed loads warn and are skipped; nothing throws. Other candidates
still use dot syntax (`LookDev.enable("id")` / `LookDev.disable()`) — the kit itself registers
nothing.

## What is in the folder

| Source | Indonesian name(s) |
|---|---|
| `ModelMapVegetationR4` | Pisang, Mangga (broadleaf stand-in), Bambu |
| `ModelMapPropsR4` | Jemuran, Karung semen, Gerobak, Sumur, Alat tani |
| `ModelMapBuildingsR4` | Rumah panggung, Kandang ayam, Gudang, Warung (all temporary) |
| `ModelMapNpcsR5` | Petani, Pedagang, Petani wanita, Tukang peci, Polisi (R15 role rigs) |

Every id, height and villager body colour is read at require time from those existing
source maps; no new asset ID and no costume Image ID lives in the kit. No kelapa, no pine.
Villagers are assembled from role body colours into standard R15 rigs — no imported body,
no hat, no animation.

## Handling

Every item is Anchored, non-colliding, pivoted so its bounding-box bottom sits at `y=0`, and
kept true to source scale: model heights come from the source slot target, R15 rigs keep
their native height. The Indonesian name in the table is the instance name in the folder —
drag from the folder, keep the pivot, and do not un-anchor a display item before placing it.
Karung semen belongs by the gudang or a small renovation spot, not loose at spawn.

This is drag-source only: no spawn dressing, no terrain sculpt, no place save or publish,
no LookDev registration and no visual verdict. The designer composes the spawn and sculpts
the terrain; look decisions stay with the designer. Elevation ideas are in
[`TERRAIN_BRIEF.md`](TERRAIN_BRIEF.md) — advice only.
