# Review cameras (WORK_QUEUE section M item 69)

Registry: `src/shared/ReviewCameras.luau` (`ReviewCameras.all()`, `.get(name)`, `.names()`).
45 named cameras at item 118; 54 named cameras after item 133; 67 named cameras after item 216; 69 named cameras after item 240; 78 named cameras after items 218, 247 and 250 (eight lighting variants plus `crop_stages_golden`); 106 named cameras after item 255 (28 `hero_*` views). Coordinates are computed at load from `src/server/World/MapSpec.luau` (hub centres,
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
| `pasar_awnings_golden` | Server | Item-218 golden-hour variant of `pasar_awnings`: same eye/target, `clockTime = 16.5`. |
| `pasar_awnings_night` | Server | Item-218 night variant of `pasar_awnings`: same eye/target, `clockTime = 21`. |
| `plaza_centre` | Server | Fountain, benches, umbrellas and bunting at the MapSpec plaza centre, seen from above. |
| `plaza_centre_golden` | Server | Item-218 golden-hour variant of `plaza_centre`: same eye/target, `clockTime = 16.5`. |
| `plaza_centre_night` | Server | Item-218 night variant of `plaza_centre`: same eye/target, `clockTime = 21`. |
| `ronda_tower` | Server | Bamboo watchtower at MapSpec.RONDA_TOWER, framed whole from the open north-west side. |
| `ronda_tower_wide` | Server | Wider 3/4 of the whole Pos Ronda watchtower from farther out on the same open north-west side. |
| `river_rocks` | Server | Bank boulders and plants along MapSpec.riverCentreZ, looking downstream from the south bank. |
| `forest_wall` | Server | Tree wall beyond the village edge, looking north from MapSpec.TERRAIN_HALF toward the hills. |
| `canonical_overview` | Server | High 3/4 canonical-style overview from the south over the bridge toward the whole village. |
| `canonical_overview_left` | Server | Left flank of the canonical overview: village ring and river band west of the Pasar. |
| `canonical_overview_right` | Server | Right flank of the canonical overview: village ring and river band east of the Pasar. |

Item 242 (2026-11-23): the three canonical overview cameras now see a buried `HorizonFill` grass ring beyond the playable square and a shipped Atmosphere.Haze floor of 1.6, so the far edge fades into the sky instead of ending at a grey plane. Geometry is measured by `tools/studio/check_q242.luau`; this is not a look verdict — the designer grades the S2-STOP shots.

Item 208 (2026-11-23): the DEFAULT-look Pasar now has one non-collidable packed-earth `PasarPad` under the five stall counters (local x -32..32, z -18..26; stops at the Gelap and Pasar door lanes) and 30 `PasarProp` crates/baskets/sacks at the lapak. `hub_pasar`, `pasar_awnings`, `pasar_golden`, `pasar_night`, `signpost_pasar` and `canonical_overview` therefore frame this geometry. Measured by `tools/studio/check_q208.luau`; no look verdict — the designer grades the S2-STOP shots.

Item 209 (2026-11-23): the DEFAULT-look Pasar now also has 30 `PasarStripe` awnings over the five stall counters in the item-179 red/white/blue palette, plus one Strings-backed `PasarSign` board ("PASAR" / "Market") hanging just inside the front eave clear of the six hub door lanes. The same review cameras frame them. Measured by `tools/studio/check_q209.luau`; no look verdict — the designer grades the S2-STOP shots.

Item 210 (2026-11-23) data note: the DEFAULT-look Warung front now has four tagged `WarungDress` seats (the two existing benches plus two low stools), a serving table, a genteng stove and a hanging kunyit lantern, all clear of the six hub door lanes and carrying no prompts. `hub_warung` and `warung_seated` frame this geometry. Measured by `tools/studio/check_q210.luau`; no look verdict — the designer grades the S2-STOP shots.

Item 211 (2026-11-23) data note: the DEFAULT-look Pos Ronda floor now carries tagged `RondaDress` props for all four kinds (kentongan, bench, gardu lamp, rack), non-collidable and non-interactive. `hub_ronda`, `ronda_tower` and `ronda_tower_wide` frame this geometry; `tools/studio/check_q211.luau` stages `ronda_tower_r9` only for the `TOWER_HEIGHT` bbox guard (28..32, not the default greybox nominal 36) and restores via `disableAll()`. No look verdict — the designer grades the S2-STOP shots.
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
| `path_curve` | Server | Item-250 downward close 3/4 of the first `road_fence_r10` bamboo stretch, from outside the road shoulder. |
| `path_curve_golden` | Server | Item-218 golden-hour variant of `path_curve`: same eye/target, `clockTime = 16.5`. |
| `path_curve_night` | Server | Item-218 night variant of `path_curve`: same eye/target, `clockTime = 21`. |
| `kampung_view` | Server | Item-240 close view of one four-house `kampung_r10` cluster from outside the plot ring. |
| `bridge_side` | Server | Item-252 downward 3/4 view of the `bamboo_bridge_r10` culm deck from above the north-east bank. |
| `meadow_view` | Server | Open lawn between the Pasar ring and the plots, looking south across the meadow. |
| `terrace_wall` | Server | Item-250 downward view of `hill_dressing_r10` rocks and palms on the north hill from its south foot. |
| `signpost_pasar` | Server | Item-240 close view of the east-junction `signposts_r10` board and post from the plaza side. |
| `lamp_night` | Server | Item-240 close 3/4 of the first `lamps_r10` pole and lantern; `clockTime = 21` night variant. |
| `lamp_night_golden` | Server | Item-218 golden-hour variant of `lamp_night`: same eye/target, `clockTime = 16.5`. |
| `lamp_night_night` | Server | Item-218 night variant of `lamp_night`: same eye/target, `clockTime = 21`. |
| `crop_stages_close` | Server | Item-250 downward close view of one plot with all three `crop_stages_r10` stages side by side. |
| `crop_stages_golden` | Server | Item-247 golden-hour close-up: same eye/target as `crop_stages_close`, `clockTime = 16.5`. |
| `ditch_water_close` | Server | Item-250 close downward view of one plot's two `ditch_water_r10` glass strips. |
| `horizon_north` | Server | North horizon over the hill and forest band from outside the playable square. |
| `horizon_south` | Server | South horizon over the bridge and river band from outside the playable square. |
| `fountain_close` | Server | Close view of the plaza fountain and its basin from the north-east approach. |

## Item 255 hero cameras

All `hero_*` cameras are ClockTime 13 except `hero_lamps_r10_night` (21). Where sprint 3 already
proved coverage the hero view reuses the exact base eye/target; the rest derive a close eye from the
candidate's data module and `MapSpec`. They are the cameras the item-255 `SUBJECT_COVERAGE >= 0.30`,
`CAMERA_GRASS` and `HERO_CLEAR` Studio check measures; verdicts stay pending the designer.

| Name | Datamodel | Purpose |
|---|---|---|
| `hero_balai_r10` | Server | Item-255 close hero view of the balai_r10 pavilion at FUTURE_SLOTS[1]. |
| `hero_hub_canopy_r10` | Server | Item-255 hero view of hub_canopy_r10 over the plaza. |
| `hero_blocks_shrubs_r10` | Server | Item-255 hero view of blocks_shrubs_r10 in the plots. |
| `hero_pasar_roof_r10` | Server | Item-255 hero view of the pasar_roof_r10 roof. |
| `hero_warung_cluster_r10` | Server | Item-255 hero view of warung_cluster_r10 from the framed Warung eye. |
| `hero_polisi_roof_r10` | Server | Item-255 hero view of the polisi_roof_r10 roof. |
| `hero_pakrt_roof_r10` | Server | Item-255 hero view of the pakrt_roof_r10 roof. |
| `hero_sawah_gubuk_r10` | Server | Item-255 hero view of the sawah_gubuk_r10 hut. |
| `hero_plots_mailbox_r10` | Server | Item-255 hero view of plots_mailbox_r10. |
| `hero_river_palms_r10` | Server | Item-255 close hero view of the first river_palms_r10 bank anchor. |
| `hero_meadow_r10` | Server | Item-255 hero view of meadow_r10 from the framed meadow camera. |
| `hero_ground_variation_r10` | Server | Item-255 close hero view of the first ground_variation_r10 tone blob. |
| `hero_paths_curved_r10` | Server | Item-255 close hero view of the first paths_curved_r10 serpentine spoke. |
| `hero_horizon_fill_r10` | Server | Item-255 hero view of horizon_fill_r10 from the north-horizon camera. |
| `hero_mountains_r10` | Server | Item-255 hero view of mountains_r10 from the north-horizon camera. |
| `hero_hill_dressing_r10` | Server | Item-255 hero view of hill_dressing_r10 from a data-derived eye above the saved hill surface. |
| `hero_kampung_r10` | Server | Item-255 hero view of kampung_r10 from the framed kampung camera. |
| `hero_road_fence_r10` | Server | Item-255 hero view of road_fence_r10: sprint-3 path_curve geometry, daytime. |
| `hero_lamps_r10` | Server | Item-255 hero view of lamps_r10 at ClockTime 13: sprint-3 lamp_night geometry. |
| `hero_lamps_r10_night` | Server | Item-255 hero view of lamps_r10 at ClockTime 21: same geometry as hero_lamps_r10. |
| `hero_signposts_r10` | Server | Item-255 hero view of signposts_r10 from the framed signpost camera. |
| `hero_bamboo_bridge_r10` | Server | Item-255 hero view of bamboo_bridge_r10 from the framed bridge camera. |
| `hero_furrows_r10` | Server | Item-255 hero view of furrows_r10 in the plots. |
| `hero_crop_stages_r10` | Server | Item-255 hero view of crop_stages_r10: sprint-3 crop_stages_close geometry, daytime. |
| `hero_ditch_water_r10` | Server | Item-255 hero view of ditch_water_r10: sprint-3 ditch_water_close geometry, daytime. |
| `hero_default_warung` | Server | Item-255 hero view of the default Warung: sprint-3 hub_warung geometry, daytime. |
| `hero_river_foam_212` | Server | Item-255 close hero view of the first river_foam_212 bank strip. |
| `hero_terrace_walls_214` | Server | Item-255 hero view of the default terrace walls (214) from the above-hill hero eye. |

## Notes

- `Server` cameras review world geometry (models, plots, terrain); `Client` cameras review lighting.
  Shoot a `Client` camera in a Client Play VM, a `Server` camera in a Server Play VM.
- The four lighting variants reuse the exact geometry of `spawn` and `hub_pasar`; only the lighting
  preset changes. The main session sets that preset for the shot.
- `lamp_night` is a real ClockTime 21 night variant: its registry record carries `clockTime = 21`.
  The main session reads that field and sets `Lighting.ClockTime = 21` for the shot, then restores the
  prior value. Game lighting defaults are unchanged. `tools/studio/check_q240.luau` does the same
  temporary set/restore before staging `lamps_r10`.
- `mountains_r10` (item 243) now stages ten layered blue-green Wedge/Cylinder silhouettes behind
  the north hill ring, framed from `horizon_north` (the `SUBJECT_COVERAGE >= 0.10` camera) and above
  the village from `canonical_overview`. This is a data note only; the designer verdict cell in
  `CANDIDATES.md` stays pending.
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

## Item 240 re-aim: old and new positions

Coordinates below are the registry's numeric eye / lookAt at load, in studs. The first four cameras
were moved in place; `crop_stages_close` and `ditch_water_close` are new, with the sprint-1 camera
formerly used for that subject listed as the old pair. `REVIEW_CAMERAS.md` keeps the historical
item-239 table above unchanged. The registry still owns the formulas; these numbers are the record
of what changed.

| Camera | Old eye -> lookAt | New eye -> lookAt |
|---|---|---|
| `kampung_view` (moved) | `(99.3313, 19.5, -139.7288)` -> `(119.3313, 0.5, -159.7288)` | `(188.8782, 19.5, 68.7460)` -> `(155.0493, 5, 56.4333)` |
| `path_curve` (moved) | `(0, 10, 124)` -> `(0, 1.5, 150)` | `(90, 5.25, -26)` -> `(90, 1.1, -10)` |
| `signpost_pasar` (moved) | `(18, 10, -8)` -> `(-40, 4.5, -40)` | `(120, 10, ~0)` -> `(144, 7.5, 0)` |
| `lamp_night` (moved) | `(0, 10, 144)` -> `(60, 4.5, 120)` | `(124, 10, -12)` -> `(144, 5, 0)` |
| `crop_stages_close` (new; was `plot_aerial_03`) | `(152, 30.5, 0)` -> `(192, 0.5, 0)` | `(220, 10, 0)` -> `(200, 3.1, 0)` |
| `ditch_water_close` (new; was `plot_gate_01`) | `(42.6443, 12, -131.2458)` -> `(46.9706, 10, -144.5606)` | `(68.9108, 10, -212.0856)` -> `(65.2026, 0.58, -200.6729)` |

`lamp_night` now carries `clockTime = 21` in the registry. The main session sets
`Lighting.ClockTime = 21` before the shot and restores the prior value afterwards; the check harness
does the same before staging. No game lighting default changes. The self-contained SERVER-VM check
`tools/studio/check_q240.luau` stages each pair, prints `SC240_*` (target 0.15) and `CC240_*` (target
0 opaque hits within the 6-stud `CAMERA_CLEAR` ray), and proves both checks can FAIL by injection.
A passing fraction is a floor check, not a visual verdict: the designer still grades re-shoot shots.

## Item 250 re-aim: old and new positions (2026-11-23)

`CAMERA_GRASS` is measured by `tools/studio/review_check_visual.luau` from the shared pure-data rules in
`src/shared/CameraGrass.luau`: FAIL when the eye is under **4 studs** above the terrain voxel column
directly below it, or when the finite eye→lookAt ray crosses a Grass/LeafyGrass column within **12 studs**
of the eye at under **3 studs** height. Voxels are read with grid-aligned `Terrain:ReadVoxels(region, 4)`.
`tools/studio/check_q250.luau` re-checks the same five eyes while staging each paired candidate and
prints `SC250_*` (0.15 coverage floor), `CG250_*` (0 grass failures), `CAMERA_CLEAR_218` and old-eye
calibration. No threshold was weakened; a bad camera is re-aimed here, not measured more loosely.

| Camera / sprint-2 shot | Old eye -> lookAt | New eye -> lookAt |
|---|---|---|
| `path_curve` (moved) | `(90, 5.25, -26)` -> `(90, 1.1, -10)` | `(90, 10, -26)` -> `(90, 1.1, -10)` |
| `ditch_water_close` (moved; was `plot_gate_01`) | `(42.6443, 12, -131.2458)` -> `(46.9706, 10, -144.5606)` | `(69.5288, 11, -213.9877)` -> `(65.2026, 0.58, -200.6729)` |
| `crop_stages_close` (new; was `plot_aerial_03`) | `(152, 30.5, 0)` -> `(192, 0.5, 0)` | `(212, 11, 0)` -> `(200, 3.1, 0)` |
| `hill_dressing_r10` via `terrace_wall` (re-aimed) | `(-120, 37.5, -318)` -> `(-120, 16.5, -238)` | `(0, 17.9, -409.8)` -> `(0, 13.15, -441.7)` |
| `hub_warung` (re-aimed target) | `(113.7990, 9.5, -26.2010)` -> `(68, 12.5, -68)` | `(113.7990, 9.5, -26.2010)` -> `(68, 2.5, -68)` |

`terrace_wall` previously faced south toward the village, so the `hill_dressing_r10` rocks on hill 4 at
`(0, -462)` were behind the lens (sprint-2 coverage 0.0000). It now stands at that hill's south foot with
a 17.9-stud eye (14 studs above the hill-dressing slope proxy) and looks down at its rocks/palms, keeping
the lens and the first 12 studs of the look ray above grass for `CAMERA_GRASS`.
`hub_warung` keeps its 9.5-stud eye and hub-centre bearing but aims down at the
dressed front at grade instead of up at the roof ridge. The `ditch_water_close` eye is one voxel farther out and one stud higher than
the sprint-2 eye; exact coordinates stay MapSpec-derived in the registry. `CAL_CAMERA_GRASS_OLD` uses the
old rows above plus the recorded `(46.9706, 10, -144.5606)` sprint-2 point as an eye, and must see at
least one FAIL so the check cannot pass vacuously.

## Items 218 and 247: lighting variants (2026-11-23)

`plaza_centre_golden`, `plaza_centre_night`, `pasar_awnings_golden`, `pasar_awnings_night`,
`path_curve_golden`, `path_curve_night`, `lamp_night_golden` and `lamp_night_night` reuse their base
eye/target and datamodel exactly; only `clockTime` changes. Golden hour is **16.5**, the midpoint of
`Config.WorldConstants.GOLDEN_HOUR` (16.0–17.0) and the same convention as `LookDevCorner.goldenHourClock`;
night is **21**, the value `lamp_night` already carried from item 240. `crop_stages_golden` is the same
eye/target as `crop_stages_close` at 16.5 for the item-247 golden-hour shot; the plain
`crop_stages_close` stays at the sprint pack's ClockTime 13. `tools/studio/check_q250.luau` prints the
`CAMERA_CLEAR_218` proof for all eight variants. `tools/studio/check_q247.luau` prints `CROP_STAGE_HEIGHT`,
`CROP_STAGE_COLOR` and `SUBJECT_COVERAGE_CROP_GOLDEN` (>= 0.2) with FAIL calibrations. These are data and
geometry checks, not visual verdicts.
