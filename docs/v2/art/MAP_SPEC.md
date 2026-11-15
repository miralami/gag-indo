# Juragan Desa — Map Spec

Status: **draft v1, 2026-11-15.** Source of truth for the Track C world build. Written from the
ChatGPT map brief (`art/map/`), corrected against the code. Where this file and the images disagree,
this file wins. The images are **art-style and building-shape reference only**; their scale, road
network and hub positions are illustrative.

Reference images (`docs/v2/art/map/`):
- `map-plan-canonical.png` — the one image whose labels match the coordinates here.
- `mood-board-2/3/4.png` — style, building silhouettes, set dressing, season mood. Layouts differ from this spec: ignore them.

Conventions: studs, X = east, **-Z = north**, ground plane **Y = 0.5** (`src/server/World/Ground.luau`).
Roblox walk speed is 16 studs/s. Terrain voxel is 4 studs; a FillBlock's visible top is `regionTop + 2`.

## 1. Scale (decision)

The code today fills a 400 x 400 square, but only the six hubs near the middle and the ring at r=90
are built, and the hubs are tiny (Pasar plinth 16 x 10). In Studio that reads as small. The ChatGPT map
fills the same square and draws every building about twice as big, so it reads as open world.

Decisions:
1. **Playable square is 340 x 340 (|x|, |z| <= 170)**, down from 400. The hill ring starts at +-170.
   Update `PLAYABLE_HALF`, the village base slab and the clear envelope to match.
2. **Hubs are bigger than today** (footprints in §3) so they read from the spawn and on a phone.
3. **No empty stretch longer than ~30 studs**: every gap is ground cover, props, a fence, a tree
   cluster or a path. Dense near hubs, calm in the open between them, never bare.
4. Edge to edge is about 20 s of walking, spawn to any hub under 4 s, spawn to any plot gate under 6 s.
   Short on purpose: phone first, tutorial beats stay close together.

If the blockout still feels too big, shrink to |x|,|z| <= 150 by moving only the river, Balai and
sawah (§5), never the plot ring or hubs.

## 2. Layout overview (north up)

```
              hill + forest ring (outside +-170)
   ┌──────────────────────────────────────────────┐
   │     SAWAH TERRACES  (z -152 .. -176, climb N)│
   │              BALAI DESA (future)             │
   │         P10                  P1              │
   │   P9    ┌ NW alley ┐          P2             │
   │  (Gelap)│ Pasar    │ Warung                  │
   │   P8  Ronda  PLAZA+SPAWN        P3   Proyek  │
   │         │ Polisi   │ Pak RT                  │
   │   P7                              P4         │
   │         P6    Lapangan   P5   Empang         │
   │ ~~~~~~~~~ river + bamboo bridge ~~~~~~~~~~~~ │
   └──────────────────────────────────────────────┘
```

## 3. Hubs

Door = side facing the plaza or road. Accent colours are `ART.md` §5.

| Hub | Centre (X, Z) | Footprint | Door | Accent | Landmark silhouette |
|---|---|---|---|---|---|
| Pasar | (-32, -32) | 32 x 26 | SE, into plaza | `merah` | striped spanduk roof, stall row |
| Tengkulak Gelap | (-40, -60) | 16 x 14 | SE, into back alley | dark `malam` + lantern | low tiled shed, red lantern door |
| Warung | (34, -34) | 26 x 22 | S | `genteng` | zinc + tile roof, motorbikes |
| Pos Ronda | (-54, 0) | 22 x 20 | E | `bambu` / `padi` roof | bamboo watchtower at (-56, -17), 16 studs tall |
| Pos Polisi | (-34, 34) | 24 x 22 | N | `malam` | blue roof, patrol car, siren |
| Rumah Pak RT | (34, 34) | 26 x 24 | N | `kunyit` | big house, flag, gold trim |
| Lapangan Warga | (0, 48) | 36 x 28 | open | — | well/fountain, flagpole; crowd space |
| Central plaza | (0, 0) | 48 x 42 | — | — | spawn, notice board, small tree |

Rules:
- All hub corners stay inside **r <= 66** from the origin so the plot connector ring (§4) never clips a hub.
- The Gelap sits in a dead-end alley 8 studs wide behind the Pasar (Pasar z >= -45, Gelap z <= -53).
- Headroom of 9.5 studs under every walkable roof and awning (`greybox_spec` rule stays).
- Hub NPC spots (tag `NpcSpawn`): pakrt (34, 21), polisi (-34, 21), tengkulak (-40, -49).

## 4. Roads and plots

- **Main roads**: X axis (z = 0) and Z axis (x = 0), 18 studs wide, from the plaza to r = 68. West road
  ends at Pos Ronda. Ground material, not grass, so decoration blades do not clip.
- **Connector ring**: 8 studs wide, centreline r = 72 (r 68..76), touching every plot gate. It is
  **broken** between 222 and 246 degrees (NW) where the Gelap alley dead-ends: P9 is reached from the
  west arm, P10 from the north road.
- **North road** continues 12 wide between P10 and P1 to the Balai. **South road** continues 12 wide
  between P5 and P6 to the bridge.
- **Ten plots** on r = 96, 36 degrees apart, ordered **clockwise from the north** so
  `PlotService.getNeighbors` (index +-1) means physical neighbours. Each is a `PlotAnchor` part with
  attribute `PlotIndex`; `lookAt(origin)` so **-Z faces the village** and the gate sits on the inner side.
- Plot footprint **40 x 40** (34 x 34 tile base from `PlotService`: 4 x 4 tiles of 6 + 1.5 gap, plus
  fence and path). Inner corners of neighbours stay at least 9 studs apart.
- Gate centre = plot centre x 0.79 (r = 76).

| Plot | Centre | Gate | Plot | Centre | Gate |
|---|---|---|---|---|---|
| P1 | (30, -91) | (24, -72) | P6 | (-30, 91) | (-24, 72) |
| P2 | (78, -56) | (62, -44) | P7 | (-78, 56) | (-62, 44) |
| P3 | (96, 0) | (76, 0) | P8 | (-96, 0) | (-76, 0) |
| P4 | (78, 56) | (62, 44) | P9 | (-78, -56) | (-62, -44) |
| P5 | (30, 91) | (24, 72) | P10 | (-30, -91) | (-24, -72) |

Plot dressing: wooden pagar, gate, mailbox, small irrigation ditch, one scarecrow, one hut or
lumbung. Own plot is marked by the owner sign (already built). `Game.plotRadius` becomes **96**.

## 5. Terrain

Everything gameplay stays on Y = 0.5. Elevation lives in two named exceptions and in the hill ring.

**River (south).** Centreline `z(x) = 140 + 5 * sin(2 pi x / 160)`. Water 16 wide, banks sloping over
4 studs each side, channel bed at Y = -3.5, water surface at about Y = -0.5. It must be **carved**
(Air through the base slab first) or it stays buried like before. Measure with `ReadVoxels`;
target at least 1000 Water voxels. Bamboo bridge at x = 0, deck 8 x 30 (z 125..155), top Y = 1.5
with 4-stud approach ramps and railings. South bank (z 152..170) is meadow, then hills.

**Sawah terraces (north).** Behind the Balai (0, -136, 42 x 28). Three terraces climbing north,
each 8 deep in z and 4 studs higher: tops at Y = 4.5 / 8.5 / 12.5 over z -152..-160, -160..-168,
-168..-176, spanning x -150..150. Walkable: a 12-wide ramp at x = 0 and stairs at x = +-70.
Paddy water is a shallow sheet; **spike first** (terrain water is a full voxel deep, a thin Part
may be better). The terrain-never-above-0.5 test excludes this band (z < -150) and the river band.

**Hills.** Start at +-170. Heights 12 to 40 (raise `MAX_HILL_HEIGHT` from 22). Keep one gap about
60 wide and no higher than 12 on the sunset side (read the sun direction from Lighting at ClockTime
17.2 before placing). Forest on the slopes. Sawit hill (future) at the NE corner, about (190, -170).

**Future slots (reserve now, do not build yet):** Proyek mangkrak (145, 60) 34 x 30; Empang
(125, 100) 34 x 24; Balai Desa as above. Re-check overlaps in the blockout.

## 6. Flow and sightlines

- **Spawn** (0, 0.5, 14), size 8, **faces -Z** (north). First frame: the north road to the Balai
  and terraces at the end, Pasar roof on the left, Warung on the right. Never a tree trunk.
- Beat sheet distances: plant at own plot gate (<= 6 s), sell at the Pasar (3 s), raid seen from the
  plaza, rumour at the Warung (3 s), rank-up at plot.
- Three orientation landmarks: Pos Ronda tower (west), Pasar roof (north-west), terrace slope (north).
  From any plot gate at least one is visible.
- View corridors: spawn -> north road -> Balai and sawah; south road -> bridge -> river sunset;
  east and west roads -> hubs.
- Drama stage: the plaza and Lapangan hold a 10-player crowd. The raid itself plays at the target plot.

## 7. Seasons

Same geometry in all three; only lighting, materials and overlays change (`Config/Seasons.luau`).
Hujan: fog band, wet-dark ground, river fuller, paddy flooded. Kemarau: amber haze, dry grass, river
low, paddy cracked. Pancaroba: pale gold, mixed cloud. Do not edit terrain at runtime; use overlay parts
and colour changes.

## 8. Dressing rules

Palette only from `ART.md` §3, at most three dominant hues per view. Contour (ink outline) on hubs,
NPCs and interactables within 60 studs, none on backdrop. Per hub 8 to 12 props: kabel, motorbike,
jemuran, karung, galon, spanduk, kursi plastik, pot. Story gags: motor without plate behind the Warung,
envelope on Pak RT's table, pinjol banner, proyek mangkrak, tall cabai-price board, free-roaming ayam.

## 9. Build plan

1. **Blockout** in Studio on the Ground plane: plots, hubs as boxes, roads, spawn. Done = tags
   (`PlotAnchor`, `NpcSpawn`, prompts) work and the first-session harness passes.
2. **Terrain**: base slab 340 x 340, carve river, terraces, hills. Done = measured numbers in an
   evidence report (grid max 0.5 inside the village band, Water voxels > 1000, terraces at 4.5/8.5/12.5).
3. **Kit pieces** (fence, stall, roof types, bridge plank), then hubs one by one, Warung first as reference.
4. **Plots and ring**, then dressing, then lighting and season pass.
5. Retire `Greybox.luau` to a test fallback.

Performance: instancing and shared textures, 60 fps on mid-range Android, instance count tracked in
`PERF_AUDIT.md`.

## 10. Code that must change with this spec

- `src/shared/Config/Game.luau`: `plotRadius = 96`.
- `src/server/World/Greybox.luau`: hub centres, base slab 340, river carve, terraces, spawn position and facing.
- `src/server/World/Landscape.luau`: `PLAYABLE_HALF = 170`, `MAX_HILL_HEIGHT`, hill positions.
- Specs: `greybox_spec.luau`, `landscape_spec.luau` (surface <= 0.5 test excludes the sawah and river bands).

## 11. Open questions

- Sun azimuth for the sunset gap.
- Paddy water: terrain voxel vs thin Part.
- Final feel of scale after the Studio blockout (fallback: +-150 square, see §1).
