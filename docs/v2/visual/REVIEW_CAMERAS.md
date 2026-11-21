# Review cameras (WORK_QUEUE section M item 69)

Registry: `src/shared/ReviewCameras.luau` (`ReviewCameras.all()`, `.get(name)`, `.names()`).
45 named cameras. Coordinates are computed at load from `src/server/World/MapSpec.luau` (hub centres,
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
| `ronda_tower` | Server | Bamboo watchtower at MapSpec.RONDA_TOWER, 3/4 from the north shoulder at mid-height. |
| `river_rocks` | Server | Bank boulders and plants along MapSpec.riverCentreZ, looking downstream from the south bank. |
| `forest_wall` | Server | Tree wall beyond the village edge, looking north from MapSpec.TERRAIN_HALF toward the hills. |
| `canonical_overview` | Server | High 3/4 canonical-style overview from the south over the bridge toward the whole village. |
| `spawn_golden` | Client | Spawn framing under the golden-hour lighting preset. |
| `spawn_night` | Client | Spawn framing under the night lighting preset. |
| `pasar_golden` | Client | Pasar framing under the golden-hour lighting preset. |
| `pasar_night` | Client | Pasar framing under the night lighting preset. |
| `crop_bibit` | Server | Item-118 `crops_showcase_r8` bibit stage plot: the 12 seedling crop Models in the first row at the MapSpec Lapangan field. |
| `crop_tumbuh` | Server | Item-118 `crops_showcase_r8` tumbuh stage plot: the 12 growing crop Models in the second row at the MapSpec Lapangan field. |
| `crop_siap` | Server | Item-118 `crops_showcase_r8` siap stage plot: the 12 mature crop Models in the third row at the MapSpec Lapangan field. |

## Notes

- `Server` cameras review world geometry (models, plots, terrain); `Client` cameras review lighting.
  Shoot a `Client` camera in a Client Play VM, a `Server` camera in a Server Play VM.
- The four lighting variants reuse the exact geometry of `spawn` and `hub_pasar`; only the lighting
  preset changes. The main session sets that preset for the shot.
- The registry requires MapSpec from `ServerScriptService.Server.World`, so load it from the Server
  datamodel or the Lune Env harness. The returned `datamodel` field is data for the shooter, not a
  promise that the module itself loads in both VMs.
