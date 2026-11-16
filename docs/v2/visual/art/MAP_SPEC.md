# Juragan Desa — Map Spec

Status: **draft v1, 2026-11-15.** Source of truth for the Track C world build. Written from the
ChatGPT map brief (`art/map/`), corrected against the code. Where this file and the images disagree,
this file wins. The images are **art-style and building-shape reference only**; their scale, road
network and hub positions are illustrative.

Reference images (`docs/v2/visual/art/map/`):
- `map-plan-canonical.png` — the one image whose labels match the coordinates here.
- `mood-board-2/3/4.png` — style, building silhouettes, set dressing, season mood. Layouts differ from this spec: ignore them.

Conventions: studs, X = east, **-Z = north**, ground plane **Y = 0.5** (`src/server/World/Ground.luau`).
Roblox walk speed is 16 studs/s. Terrain voxel is 4 studs; a FillBlock's visible top is `regionTop + 2`.

## 0. Scale revision S=2 (2026-11-16) — supersedes the numbers below

Rumah Pak RT was rebuilt to concept-art proportions (48 x 34, ridge 32.6, door 7 x 10.5, avatar 7.25 tall)
and became the scale reference. The village is built at **S = 2**: every distance and hub footprint
below is doubled. **`src/server/World/MapSpec.luau` is the numeric authority**; sections 1 to 11 keep
the design intent and the old half-scale numbers for history.

| Item | S=1 (below) | S=2 (built) |
|---|---|---|
| Playable square | 400 x 400 | 800 x 800 (hills from +-400) |
| Plot ring | r 96, footprint 40 | r 192, footprint 56, gate r 152 |
| Hubs | Pasar 32x26 ... | Pasar 64x52, Warung 52x44, Polisi 48x44, Ronda 44x40, Gelap 32x28, Pak RT 48x34 |
| Roads | 18 wide, ring r 72 | 28 wide, ring r 144 (12 wide), continuations 16 |
| River | z = 152 + 6 sin, 16 wide | z = 304 + 12 sin(2 pi x / 320), 28 wide, bridge 10 x 56 |
| Sawah | 3 terraces, top 12.5 | 4 terraces, tops 4.5 to 16.5, 84-wide Balai gap |
| Hills | 12..40 | 40..80, west sunset gap <= 24 at z 132 |
| Spawn | (0, 14) | (0, 28), faces north |

Gelap (-80,-120) sits outside the r <= 132 hub rule on purpose: the ring is broken there for its alley.
Terrace tops measured live at exactly 4.5 / 8.5 / 12.5 / 16.5 (single-layer 40-wide strips).

## 1. Scale (decision)

**Keep it big: the playable square stays 400 x 400 (|x|, |z| <= 200).** The code fills this square
today but builds only a small cluster in the middle, so Studio feels small; the ChatGPT map fills the
whole square and draws every building about twice as big. We take the big version.

1. **Hubs are bigger than today** (footprints in §3) so they read from the spawn and on a phone.
2. **Cover the whole square with purpose.** Calm open space is allowed, but never bare: ground cover,
   paths, fences, tree clusters, signs, ambient NPCs. Dense near hubs, sparse between.
3. Walking at 16 studs/s: spawn to any hub under 4 s, spawn to any plot gate under 6 s, edge to edge
   about 25 s. Long trips are fine because **traversal mechanics will come later** (sprint, ojek or
   bicycle, fast travel, glider). Reserve their space now: wide roads, no one-stud gaps, no steps on
   main roads, a clear ground-level line from every plot gate to the plaza.
4. Do not shrink the map to fix emptiness. Add density and traversal.

## 2. Layout overview (north up)

```
              hill + forest ring (outside +-200)
   ┌──────────────────────────────────────────────┐
   │     SAWAH TERRACES  (z -156 .. -180, climb N)│
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

Door = side facing the plaza or road. Accent colours are `visual/ART.md` §5.

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

**River (south).** Centreline `z(x) = 152 + 6 * sin(2 pi x / 160)`. Water 16 wide, banks sloping over
4 studs each side, channel bed at Y = -3.5, water surface at about Y = -0.5. It must be **carved**
(Air through the base slab first) or it stays buried like before. Measure with `ReadVoxels`;
target at least 1000 Water voxels. Bamboo bridge at x = 0, deck 8 x 30 (z 137..167), top Y = 1.5
with 4-stud approach ramps and railings. South bank (z 164..200) is meadow, then hills.

**Sawah terraces (north).** Behind the Balai (0, -137, 42 x 28, z -151..-123). Three terraces
climbing north, each 8 deep in z and 4 studs higher: tops at Y = 4.5 / 8.5 / 12.5 over z -156..-164,
-164..-172, -172..-180, spanning x -170..170, then the hill. Walkable: a 12-wide ramp at x = 0 and
stairs at x = +-70. **Paddy water is thin geometry, not terrain water**: on each terrace a flat Part,
about 0.2 studs thick, Glass or SmoothPlastic, `malam`-tinted, Transparency 0.35, Reflectance 0.15,
CanCollide false, sitting 0.1 above the terrace top, inset 2 studs from the bund so a ridge of
terrain frames it. Plant rows (padi) as repeated instanced strips over it. The terrain-never-above-0.5
test excludes z < -150 and the river band.

**Hills.** Start at +-200. Heights 12 to 40 (raise `MAX_HILL_HEIGHT` from 22). **Sunset gap, decided:**
measured in Studio at ClockTime 17.2 the sun direction is (-0.93, 0.20, 0.31), i.e. west, 18 degrees
south of west, about 11 degrees above the horizon. Keep the west edge low where that line leaves the
square: hills on the west edge between z = 35 and z = 100 are at most 12 high, widest gap at z = 66.
P7 and P8 look straight into it. Forest on the slopes elsewhere. Sawit hill (future) at the NE
corner, about (220, -180).

**Future slots (reserve now, do not build yet):** Proyek mangkrak (140, 65) 34 x 30; Empang
(130, 118) 34 x 24. Re-check overlaps in the blockout.

## 6. Flow and sightlines

- **Spawn** (0, 0.5, 14), size 8, **faces -Z** (north). First frame: the north road to the Balai
  and terraces at the end, Pasar roof on the left, Warung on the right. Never a tree trunk.
- Beat sheet distances: plant at own plot gate (<= 6 s), sell at the Pasar (3 s), raid seen from the
  plaza, rumour at the Warung (3 s), rank-up at plot. The big square makes the *rest* of the map a
  walk; that is what the later traversal mechanics are for.
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

Palette only from `visual/ART.md` §3, at most three dominant hues per view. Contour (ink outline) on hubs,
NPCs and interactables within 60 studs, none on backdrop. Per hub 8 to 12 props: kabel, motorbike,
jemuran, karung, galon, spanduk, kursi plastik, pot. Story gags: motor without plate behind the Warung,
envelope on Pak RT's table, pinjol banner, proyek mangkrak, tall cabai-price board, free-roaming ayam.

## 9. Build plan

1. **Blockout** in Studio on the Ground plane: plots, hubs as boxes, roads, spawn. Done = tags
   (`PlotAnchor`, `NpcSpawn`, prompts) work and the first-session harness passes.
2. **Terrain**: base slab 400 x 400, carve river, terraces, hills. Done = measured numbers in an
   evidence report (grid max 0.5 inside the village band, Water voxels > 1000, terraces at 4.5/8.5/12.5).
3. **Kit pieces** (fence, stall, roof types, bridge plank), then hubs one by one, Warung first as reference.
4. **Plots and ring**, then dressing, then lighting and season pass.
5. Retire `Greybox.luau` to a test fallback.

Performance: instancing and shared textures, 60 fps on mid-range Android, instance count tracked in
`qa/PERF_AUDIT.md`.

## 10. Code that must change with this spec

- `src/shared/Config/Game.luau`: `plotRadius = 96`.
- `src/server/World/Greybox.luau`: hub centres, river carve (slab stays 400), terraces, paddy water Parts, spawn position and facing.
- `src/server/World/Landscape.luau`: `MAX_HILL_HEIGHT`, hill positions, the low sunset gap on the west edge (`PLAYABLE_HALF` stays 200).
- Specs: `greybox_spec.luau`, `landscape_spec.luau` (surface <= 0.5 test excludes the sawah and river bands).

## 11. Open questions

- Which traversal mechanic first (sprint, ojek or bicycle, fast travel, glider); it decides road surface and width details.
- Whether the plot ring (r = 96) feels too close to the centre once the map is dressed; the fix would be moving plots outward, not shrinking the map.
