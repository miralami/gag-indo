# Review cameras (WORK_QUEUE section M item 69)

Registry: `src/shared/ReviewCameras.luau` (`ReviewCameras.all()`, `.get(name)`, `.names()`).
45 named cameras at item 118; 54 named cameras after item 133; 67 named cameras after item 216. Coordinates are computed at load from `src/server/World/MapSpec.luau` (hub centres,
footprints, road ring, bridge, terraces, hill edge, spawn), `src/shared/Config/Game.luau` (plot-ring
angles/radius) and `ModelMapVegetationR7.savedCamera` (the current saved spawn camera). No hand-typed
world coordinates. `ReviewCameras.clearDistance` is the 6-stud `CAMERA_CLEAR` ray length.

The **main session shoots these** in the datamodel named below; a **vision-capable designer grades**
the resulting shots. Neither file contents nor Lune checks are a visual verdict. The `CAMERA_CLEAR`
Studio check (ray from eye to lookAt must hit nothing opaque within the first 6 studs) is added by the
main session to the r8 harness; fix a failing camera by moving the camera, not by weakening the check.
Shots and verdicts belong under `docs/v2/evidence/h/<date>-round9/`.

## Cameras

| Name | Datamodel | Purpose |
|---|---|---|
| `spawn` | Server | Current saved camera: near vegetation, spawn ground and sky. |
| `hub_pasar` | Server | 3/4 view of Pasar from outside its front-right corner. |
| `hub_gelap` | Server | 3/4 view of the tengkulak shed, on the side clear of Pasar. |
| `hub_warung` | Server | 3/4 view of Warung, tables and awning. |
| `hub_ronda` | Server | 3/4 view of Pos Ronda and its watchtower. |
| `hub_polisi` | Server | 3/4 view of Pos Polisi from the road side. |
| `hub_pakrt` | Server | 3/4 view of Rumah Pak RT, the scale-reference house. |
| `plot_gate_01` | Server | Gate of P1 from the connector-road side. |
| `plot_gate_02` | Server | Gate of P2 from the connector-road side. |
| `plot_gate_03` | Server | Gate of P3 from the connector-road side. |
| `plot_gate_04` | Server | Gate of P4 from the connector-road side. |
| `plot_gate_05` | Server | Gate of P5 from the connector-road side. |
| `plot_gate_06` | Server | Gate of P6 from the connector-road side. |
| `plot_gate_07` | Server | Gate of P7 from the connector-road side. |
| `plot_gate_08` | Server | Gate of P8 from the connector-road side. |
| `plot_gate_09` | Server | Gate of P9 from the connector-road side. |
| `plot_gate_10` | Server | Gate of P10 from the connector-road side. |
| `plot_aerial_01` | Server | Fence and gate of P1 from 30 studs up and 40 studs back along the connector road. |
| `plot_aerial_02` | Server | Fence and gate of P2 from 30 studs up and 40 studs back along the connector road. |
| `plot_aerial_03` | Server | Fence and gate of P3 from 30 studs up and 40 studs back along the connector road. |
| `plot_aerial_04` | Server | Fence and gate of P4 from 30 studs up and 40 studs back along the connector road. |
| `plot_aerial_05` | Server | Fence and gate of P5 from 30 studs up and 40 studs back along the connector road. |
| `plot_aerial_06` | Server | Fence and gate of P6 from 30 studs up and 40 studs back along the connector road. |
| `plot_aerial_07` | Server | Fence and gate of P7 from 30 studs up and 40 studs back along the connector road. |
| `plot_aerial_08` | Server | Fence and gate of P8 from 30 studs up and 40 studs back along the connector road. |
| `plot_aerial_09` | Server | Fence and gate of P9 from 30 studs up and 40 studs back along the connector road. |
| `plot_aerial_10` | Server | Fence and gate of P10 from 30 studs up and 40 studs back along the connector road. |
| `bridge_north_bank` | Server | Bridge deck and railing from the north approach. |
| `bridge_south_bank` | Server | Bridge deck and railing from the south approach. |
| `sawah_below` | Server | Low view up the terrace bunds and paddy water. |
| `sawah_above` | Server | High view down the full sawah band. |
| `hill_ring_in` | Server | Hill/forest backdrop looking in across the village. |
| `pasar_awnings` | Server | Item-148 lapak stalls and striped awnings on the Pasar front apron, from the front-right 3/4. |
| `plaza_centre` | Server | Fountain, benches, umbrellas and bunting at the MapSpec plaza centre, seen from above. |
| `ronda_tower` | Server | Bamboo watchtower at MapSpec.RONDA_TOWER, framed whole from the open north-west side. |
| `ronda_tower_wide` | Server | Wider 3/4 of the whole Pos Ronda watchtower from farther out on the same open north-west side. |
| `river_rocks` | Server | Bank boulders and plants along MapSpec.riverCentreZ, looking downstream from the south bank. |
| `forest_wall` | Server | Tree wall beyond the village edge, looking north from MapSpec.TERRAIN_HALF toward the hills. |
| `canonical_overview` | Server | High 3/4 canonical-style overview from the south over the bridge toward the whole village. |
| `canonical_overview_left` | Server | Left flank of the canonical overview: village ring and river band west of the Pasar. |
| `canonical_overview_right` | Server | Right flank of the canonical overview: village ring and river band east of the Pasar. |
| `spawn_golden` | Client | Spawn framing under the golden-hour lighting preset. |
| `spawn_night` | Client | Spawn framing under the night lighting preset. |
| `pasar_golden` | Client | Pasar framing under the golden-hour lighting preset. |
| `pasar_night` | Client | Pasar framing under the night lighting preset. |
| `crop_bibit` | Server | Item-118 `crops_showcase_r8` bibit stage plot: the 12 seedling crop Models in the first row at the MapSpec Lapangan field. |
| `crop_tumbuh` | Server | Item-118 `crops_showcase_r8` tumbuh stage plot: the 12 growing crop Models in the second row at the MapSpec Lapangan field. |
| `crop_siap` | Server | Item-118 `crops_showcase_r8` siap stage plot: the 12 mature crop Models in the third row at the MapSpec Lapangan field. |
| `lapangan_view` | Server | Item-108 lapangan goals, flagpole, benches and stone edge from the south end of the field. |
| `musala_view` | Server | Item-110 musala door, wudhu and shoe rack from the front-left approach. |
| `lumbung_view` | Server | Item-111 lumbung padi, ladder and drying yard from the front-right of the Pasar barn. |
| `perahu_view` | Server | Item-112 perahu hull and gunwales on the south river bank, 3/4 from upstream. |
| `irrigation_view` | Server | Item-113 bamboo irrigation flume and water sheet on the second sawah terrace. |
| `kincir_view` | Server | Item-114 waterwheel blades and support posts from the river side, 3/4 east. |
| `laundry_view` | Server | Item-115 Pasar washing lines with sarung, batik and kebaya behind the back wall. |
| `kite_sky` | Server | Item-116 kites over the Lapangan, framed on the highest sail from above. |
| `warung_seated` | Server | Item-117 seated villagers, glasses and plates on the Warung benches from the front-left apron. |
| `path_curve` | Server | Connector dirt path between the ring road and the plot gates from the Lapangan edge. |
| `kampung_view` | Server | Outskirts between the ring and the plot ring, framing the future kampung house row. |
| `bridge_side` | Server | Side elevation of the river bridge deck and railing from the east bank. |
| `meadow_view` | Server | Open lawn between the Pasar ring and the plots, looking south across the meadow. |
| `terrace_wall` | Server | Sawah terrace bunds and retaining wall looking south toward the Balai gap. |
| `signpost_pasar` | Server | Pasar junction signpost and ukur board framed from the plaza side. |
| `lamp_night` | Server | Ring-road lamp posts and night lighting preset at ClockTime 21. |
| `horizon_north` | Server | North horizon over the hill and forest band from outside the playable square. |
| `horizon_south` | Server | South horizon over the bridge and river band from outside the playable square. |
| `fountain_close` | Server | Close view of the plaza fountain and its basin from the north-east approach. |

## Notes

- `Server` cameras review world geometry (models, plots, terrain); `Client` cameras review lighting.
  Shoot a `Client` camera in a Client Play VM, a `Server` camera in a Server Play VM.
- The four lighting variants reuse the exact geometry of `spawn` and `hub_pasar`; only the lighting
  preset changes. The main session sets that preset for the shot.
- `lamp_night` is the ClockTime 21 night preset on the ring road. The registry has no `clockTime`
  field, so the name selects the preset and the main session sets ClockTime 21 for the shot.
- The registry requires MapSpec from `ServerScriptService.Server.World`, so load it from the Server
  datamodel or the Lune Env harness. The returned `datamodel` field is data for the shooter, not a
  promise that the module itself loads in both VMs.

## HUD-free review captures (WORK_QUEUE item 238)

`src/shared/LookDevReview.luau` has a client-side review helper for clean shots:
`hideHud(root?)` saves the exact prior `Enabled` of every `ScreenGui` under the local player's
`PlayerGui`, sets them all to `false`, and returns the count disabled; `restoreHud()` writes every
saved value back exactly and clears the saved state. A second `hideHud` keeps the original saved
values and also records later `ScreenGui`s, so repeated calls do not lose state. If `PlayerGui`
cannot be resolved, `hideHud` returns 0 and changes nothing.

**Main-session use:** in a **Client VM** `execute_luau`, call `hideHud(game)`, take the
`screen_capture` for the chosen camera from the table above, then call `restoreHud()` in the same
session. Do not leave the HUD hidden after the shot. No visual verdict is made by this helper.

Exact commands (Client datamodel):

```luau
local Review = require(game.ReplicatedStorage.Shared.LookDevReview)
local hiddenCount = Review.hideHud(game) -- all PlayerGui ScreenGuis now disabled
-- main session: screen_capture at ReviewCameras.get("spawn") (or another named camera)
local restored = Review.restoreHud() -- every ScreenGui back to its saved Enabled
```

One-line command-bar form:

```luau
require(game.ReplicatedStorage.Shared.LookDevReview).hideHud(game)
require(game.ReplicatedStorage.Shared.LookDevReview).restoreHud()
```

`execute_luau` normally runs in the **SERVER VM**, where `Players.LocalPlayer` is nil; the helper
then uses `Players:GetPlayers()[1].PlayerGui`. The self-contained SERVER-VM harness
`tools/studio/check_q238.luau` proves `HUD_HIDDEN` (0 enabled ScreenGuis while hidden) and
`HUD_RESTORE` (every temporary ScreenGui back to its saved value) and cleans up after itself. Use
that for checks; use the Client VM sequence above for actual capture shots.

## SUBJECT_COVERAGE (WORK_QUEUE item 239)

`src/shared/SubjectCoverage.luau` measures the visible screen fraction of a candidate from a named
review camera: project each tagged `BasePart` AABB with `Camera:WorldToViewportPoint`, clip to the
viewport (default 1375x753), then raycast a shared 64x36 grid cell centre through every covered
cell. A cell counts only when the first opaque hit belongs to the candidate; overlapping rects are
visited once. `measure(candidateId, cameraName, viewportSize?, deps?)` returns `fraction` plus
`sampleCount`, `hitCount`, `partCount`, `rects`, `camera`, `viewport` and `reason`. No place save;
the temporary Camera is unparented. Target stays **0.15**; a <0.15 value is a camera/framing defect,
not a reason to lower the target.

The SERVER-VM harness `tools/studio/review_check_visual.luau` prints three harness pairs:

| Pair | Purpose |
|---|---|
| temporary `Q239_FIXTURE` part + `spawn`, then shrunk fixture + `spawn` | PASS >=0.15 and calibrated FAIL <0.15 |
| `kampung_r10` staged + `kampung_view` | sprint-1 weak pair, expected FAIL <0.15 |
| `ditch_water_r10` staged + `plot_gate_01` | sprint-1 weak pair, expected FAIL <0.15 |

Each staged pair is restored with `LookDevReview.disableAll()`; values are recorded by the main
session in `CHECK_239.txt`. The camera pairs above are measurement inputs, not visual verdicts.
