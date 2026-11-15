# Terrain no longer buries the Y=0.5 gameplay plane — 2026-11-15

Track C. Fixes the "trees floating over a dark glossy sheet" report: generated Smooth Terrain
topped out 1.5–2.1 studs **above** the authored ground plane, so it swallowed the road, the plots
and the bottom of every tree trunk.

Place: `Development-Juragan-Desa` (placeId 132087524375529), Studio instance
`13fc0c2c-5986-400a-b1b9-57aa5bbe33c2`, **Play** mode (Server + Client DataModels).
Nothing was saved and nothing was published.

## Root cause

`src/server/World/Greybox.luau` sized the terrain slab from a wrong model of the mesher.

- Assumed: `FillBlock` snaps the visible top face up to a whole 4-stud voxel
  (`4 * ceil(regionTop / 4)`).
- Measured: the visible top face is `regionTop + TERRAIN_VOXEL / 2`, i.e. **half a voxel above the
  requested region**. Probe series with `h = 4` fills: centre −10 → −6.0, −8 → −4.0, −6 → −2.0,
  −4 → 0.015, −3 → 1.0, −2 → 2.0, 0 → 4.015.

So the old `TERRAIN_BASE_Y = GROUND_Y - TERRAIN_VOXEL/2 - 0.5` (= −2) put the region top at 0 and
the surface at **2.0**, and the pre-fix slab at −1.5 measured **2.516** — both above the road top
(0.58) and above `World.Ground` (0.5).

Fix: `TERRAIN_BASE_Y = GROUND_Y - TERRAIN_VOXEL` (= −3.5) → region top −1.5 → surface **0.500**,
exactly the authored plane. Verified twice with `h = 4, centre −3.5` and once with `h = 8,
centre −5.5`.

The clear envelope was widened to Y −8…8 (`400 × 16 × 400`) so any slab an older generator left in
the place is removed before refilling.

## Before / after (live raycasts, parts excluded so only Terrain is hit)

| Point | Old slab (−1.5) | Fixed |
|---|---|---|
| spawn (0, 16) | 2.516 | **0.500** |
| Pos Ronda (−30, −26) | 2.516 | **0.500** |
| 15×15 grid, \|x\|,\|z\| ≤ 175, step 25 | 2.0–2.6 everywhere | max **0.500**, min **0.500**, 0 points over 0.5, 0 holes |
| boundary ring at ±195 | — | **0.50** on all 20 probes |

Key gameplay points, all exactly 0.500 after the fix: spawn, Pasar (0,0), Tengkulak Gelap (0,−16),
Rumah Pak RT (30,26), Pos Polisi (−30,26), Pos Ronda (−30,−26), Warung (30,−26), four plots
(±20,±20), four road points (±60/0, 0/±60), watchtower (−20,−30), sawah rows (0,−100) and (0,−58).

The only points above 0.5 are three probes exactly on the outer edge of the base slab
((−200,0)=1.786 Grass, (−100,−200)=0.876 Mud, (100,−200)=1.465 Rock). Those are Landscape hill
skirts meshing into the base edge: their above-ground footprints stay outside \|x\|,\|z\| ≤ 200 by
spec, and every probe at ±195 is flat 0.500. Not gameplay zone.

## Idempotency

`Greybox.applyTerrain` + `Landscape.apply` run twice more in the live server:

```
before rerun: max=1.786 over0.5=3
after run 2:  max=1.786 over0.5=3
after run 3:  max=1.786 over0.5=3
```

Same envelope, no growth, no stacking.

## What the "dark glossy sheet" actually was

Not water, not glass, not metal. Reproducing the old slab and raycasting from the camera at spawn
and at Pos Ronda with parts included:

```
OLD slab all-parts at spawn:     y=2.516 mat=Grass inst=Workspace.Terrain  reflectance=0.00
OLD slab all-parts at PosRonda:  y=2.516 mat=Grass inst=Workspace.Terrain  reflectance=0.00
FIXED  terrain at spawn:         y=0.500 mat=Ground inst=Workspace.Terrain
```

- The top-most thing in the scene was the **terrain itself**, 1.94 studs above the road part
  (top 0.58) and 2.0 above `World.Ground`, covering the road, the plots and the trunk bottoms.
- Material colour at the time: `Terrain:GetMaterialColor(Ground)` = `0.541, 0.416, 0.275`
  (`#8a6a46`, Landscape's Ground colour, applied after Greybox's), `Grass` = `#6f8a3f`.
  `Lighting.ClockTime` = 17.2, so the flat smooth surface sat in canopy shade; `#8a6a46` at roughly
  half brightness is `≈ (75, 57, 38)`, which matches the dark brown in the user's screenshot.
- Water was never the cause: the river volume is fully overlapped by the village base slab, and the
  pre-fix build had **0 columns with Water as the top material** (1400 water cells, top face −4,
  i.e. buried). The new, one-voxel-lower base swallows those cells too: a `ReadVoxels` survey of
  the river box (−110…110 × −12…8 × 60…160) now returns Grass=2600, Ground=200, **Water=0**.
  Nothing visible changed (the water was already buried); making the river real is the unticked
  Track C item "Terraced sawah and river".

## Standing and walking

Client DataModel after the fix:

```
hrp y=4.693  floor=Enum.Material.Ground  state=Running
walked dz=-1.07 over 1.5 s, y after=4.693, floor=Ground
bbox minY=0.347 (feet), ray under character: y=0.580 mat=Ground inst=Workspace.World.Road
```

The character stands on the road (0.58) and walks without falling or climbing. Road top 0.58,
`World.Ground` top 0.500, terrain surface 0.500, `Tree_1` trunk bottom 0.500 (its 4-stud cylinder
is vertical after the 90° roll, so `Position.Y - Size.X/2 = 0.5`).

## Screenshots — SEEN-IN-STUDIO

`after-spawn.webp` (user-supplied, Play session, 2026-11-15): road, grass and tree trunks sit on one
plane, no buried ground or glossy sheet. The user confirmed "it's normal now". The agent that wrote the
numbers could not capture images itself; the numeric checks above were re-run independently and match.

## Sawah rows

The four terrace rows used to step up (`y = -1.5 + row * 1.5`, 3 tall) and their surfaces ran to
about 6.5 studs, i.e. they were built off the same broken base. They now sit at the same
`TERRAIN_BASE_Y` and are flat at 0.500, so the whole generated band honours one ceiling. The stepped
look belongs to the unticked Track C item "Terraced sawah and river" and will come back with it.

## Tests

`lune run tests/run.luau`: **611 passing**. `tests/specs/greybox_spec.luau` now asserts the measured
surface rule (`regionTop + TERRAIN_VOXEL/2 <= GROUND_Y`) and the 400×16×400 clear envelope;
`tests/specs/landscape_spec.luau`'s copy of the owned volumes follows the new terrace depth.
