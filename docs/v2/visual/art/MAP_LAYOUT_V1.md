# Map layout v1 (2026-11-25)

Status: `SEEN-IN-STUDIO` in Edit, in the place `Development-Juragan-Desa`. The place is **not saved**.
Evidence is in `docs/v2/evidence/map_layout_v1/`. The before shot is `00`, the after shot is `01`, and
`04`, `05` and `06` are the brief's three view corridors.

The target is the illustrated brief `map/map_design_brief.webp`. The layout follows where things are
drawn, not the coordinate labels printed on the drawing. Those labels disagree with each other: hub
labels and plot labels use opposite Z signs, and the 400-stud arrows do not match the pixel spacing.
Drawn positions were read with one scale, about 0.9 stud per pixel in X and 0.8 in Z. The scale is
pinned to what the terrain already fixed: the river at z ≈ 304 and the sawah terraces at
z −312..−376. The world keeps the MapSpec 800 × 800 scale, which is the "wider world" the owner likes.

The script that produced the layout is `tools/studio/map_layout_v1.luau`. It is a reconstruction of
the Studio run and has not been replayed on a fresh place. The run applied the steps in a slightly
different order, then made fixes by hand that the script now includes: `fixups`, the hub rescale to
human scale, and the nearest-centre match in `dressing`. Load it as a ModuleScript in
Edit and run `steps.<name>()` in the order given by `.order`. Nothing is destroyed. Old road strips,
the Jalan tile kit, and the trees that had no free spot were moved to `ServerStorage.ParkedLayout`.

## World structure after the pass

The following list describes the world tree after the pass.

- `Workspace.JuraganMap.Hubs` holds the hub 3D models, each tagged with the attribute `MapHub`.
- `Roads` holds dirt strips with a shoulder: the octagon ring, the main roads, lanes, and spokes to the plots.
- `PlotYards` holds a 76 × 76 Ground patch and kit fence around each plot, with the gate facing the village.
- `Nature` has two parts. `ForestBelt` holds 300 trees plus 60 more at the edges. `VillageTrees` holds 170 trees.
- `Props` holds the `kit_*` and `prop_*_v2` meshes, used as hub dressing.
- `Village` holds every earlier LookDev folder, NPCs included. They were kept as the owner asked, moved with their hub, and gathered here.
- All 14,139 parts are anchored, the display NPC rigs included. `TengkulakGelap_v1` and `Lahan_v3`
  are packages that were rescaled. If a package auto-update arrives, it may undo the scale.

## Coordinates

Units are studs. X points east and −Z points north. Ground is at Y 0.5.

| Item | Model | Centre (x, z) | Facing | Scale | Size (x × h × z) |
|---|---|---|---|---|---|
| Lapang Warga (plaza) | `alun_alun_area` | 0, 0 | – | 1.2 | 120 × 36 × 120 |
| Rumah Pak RT | `rumah_pakrt` | 80, −112 | south | 2.0 | 48 × 27 × 48 |
| Pos Polisi | `R5_gudang` (stand-in) | −80, −112 | south | 2.6 | 24 × 26 × 25 |
| Pos Ronda (+ tower) | `pos_ronda` | −165, −45 | east | 1.4 | 42 × 22 × 27 |
| Pasar | `pasar_diorama` | −82, 102 | north (open side is local −Z) | 2.0 | 68 × 26 × 59 |
| Tengkulak Gelap | `TengkulakGelap_v1` | −61, 148 | joined to the Pasar's back by the alley | Pasar's (0.68 of the .blend) | 28 × 18 × 39 |
| Warung | `R5_warung` (stand-in) | 104, 84 | north | 2.8 | 35 × 25 × 25 |
| Balai Desa | `rumah_desa` (stand-in) | 0, −246 | south | 1.8 | 46 × 39 × 47 |
| Kebun (Kebun Sawit corner) | `Lahan_v3` | 345, −250 | – | 1.0 | 90 × 18 × 91 |
| Lapangan (goals, kites) | LookDev | 160, −48 | – | – | 72 × 56 |
| Musala | LookDev | 46, 140 | – | – | – |
| Crop showcase | LookDev | 62, 232 | – | – | – |
| Empang (pond) | terrain | 300, 244 | – | – | 52 × 32 water |
| Proyek Mangkrak | reserved, empty | 312, 186 | – | – | 68 × 52 |

The plots are numbered clockwise from the north, as in the drawing. Each gameplay plot keeps its own
size, which is 40 to 46 studs. Only the yard around it is new.

| P1 | P2 | P3 | P4 | P5 | P6 | P7 | P8 | P9 | P10 |
|---|---|---|---|---|---|---|---|---|---|
| 150, −235 | 300, −130 | 320, 5 | 300, 105 | 160, 228 | −160, 228 | −320, 120 | −325, 0 | −300, −130 | −150, −235 |

The roads are laid out as follows.

- The octagon ring has half extents of 228 in X and 172 in Z, an 80-stud chamfer and a width of 14.
- The north and south spine is 20 wide inside the ring. It continues 14 wide to the Balai at z −222 and to the bridge at z 278.
- The east and west road is 18 wide.
- 10-stud lanes run from each hub door to the axes.
- 10-stud spokes run from the ring to every plot, to the Kebun and to the Proyek reserve.

## Assumptions to confirm next iteration

These are reversible defaults. Each one is one line in the script.

1. **P4 is not drawn.** It is placed east-south-east at (300, 105), between P3 and the Proyek reserve.
2. **Lapangan.** The drawing's "Lapang Warga" is the central plaza, so the alun-alun model sits there.
   The football field was moved east of the plaza, next to Pak RT.
3. **`Lahan_v3`** is used as the Kebun in the north-east corner, because the drawing shows a farm hut there.
4. **`rumah_desa`** stands in for the Balai Desa. Its red tile roof matches the drawing.
5. *(Replaced in v1.1.)* The Gelap now sits behind the Pasar and joins it through the back alley.
6. **Hub sizes** are set to human scale against the 5-stud NPCs. A first pass scaled them to the
   drawing and put the Pasar stall counters at head height (5.0). They now top out at 3.6, and the
   Pak RT table at 2.6. As a result, the Pasar is 68 × 59, smaller than the 100 × 84 MapSpec
   footprint. *(v1.1: the old awning stall ring and its paving were parked, because the 3D model
   replaces them.)*

## Gaps

- There are no 3D models yet for **Pos Polisi** or **Warung**. They use the R4 gudang and warung meshes,
  scaled up. A new model only needs `MapHub` and its row in `L.HUBS`.
- **Play shows only part of this layout.** Since v1.1, `World/MapHubGate.luau` hides the Roblox-built
  hubs, the Greybox road strips and the `Decor`/`Details` dressing whenever `JuraganMap.Hubs` holds
  the matching 3D model (evidence `09`). It hides them in place and destroys nothing. The ten Greybox
  plots, the hub prompts and the NPC spots still sit at the old MapSpec positions. The ProximityPrompts
  for the hidden hubs are therefore invisible and in the old spots. The logic transfer, planned as the
  next sprint, has to move prompts, tags, plots and NPC spots onto the models in `JuraganMap.Hubs`, and
  update MapSpec to these coordinates.
- Dressing built against the old Roblox walls (night windows, porch bulb, hub spanduk) is parked in
  v1.1. The 3D models have no night glow yet.
- `Jalan_v3` (the road tile kit) was not used. The roads are plain Parts, so their look can be swapped
  for the kit later.

## v1.1 tidy pass (2026-11-25)

The designer gave four instructions:

- park the old Roblox-built hubs, because the 3D models replace them;
- make room for the models so nothing overlaps;
- let the roads bend where they need to;
- join the Tengkulak Gelap to the Pasar through a back alley.

The step is `steps.tidy()` in the layout script. It runs after `unify`.

Edit changes are the following.

- **Gelap.** It was moved behind the Pasar at the Pasar's scale, in the exact relative placement of
  `assets/blender/pasar_gelap_blockout.blend`. Its walls and `Alley_Floor` land within 0.1 stud of their
  mapped Blender points. Studio maps Blender (x, y, z) to (−x, z, y) about the Pasar's `Ground_Dirt`.
  The Gelap is reached only through the alley from the Pasar. The lumbung barn now stands on its old spot.
- **Parked** to `ServerStorage.ParkedLayout`:
  - the old Pasar awning stall ring and its paving;
  - `LookDevPlazaR9`, which doubled the `alun_alun_area` fountain and benches;
  - every night window;
  - two torches, the Pak RT porch bulb, and the hub spanduk signs and bunting;
  - six trees inside the Gelap footprint;
  - the ten yard fence pieces each spoke crossed, which leaves an open gate.

  Each parked item carries the attribute `ParkedFrom`.
- **Moved out of footprints and lanes:**
  - the Pasar laundry, hammock and tikar;
  - the lumbung drying yards for the Pasar and Pak RT;
  - the warung eat-in table;
  - the vendor and police NPCs;
  - the hub prop rows for the Pasar, Polisi, Warung and Pak RT, split around each lane;
  - street furniture and three trees that sat on the moved roads.
- **Roads:**
  - The ring's south straight jogs to z 178 behind the Gelap.
  - The Ronda lane stops at its front.
  - The Pasar lane runs into the market aisle.
  - The Kebun spoke stops at the Lahan edge.

An audit checked every hub footprint against `GetPartBoundsInBox`, and every road against what stands
on it. It leaves only the intended contacts: the Pasar and Gelap touching at the alley, and walkers on
roads. The evidence shots are `08` (before) through `14` (top after). The look is the owner's call.
