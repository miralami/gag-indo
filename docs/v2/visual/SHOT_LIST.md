# Section O shot list (WORK_QUEUE item 155, 2026-11-21)

Main session takes these shots; a vision-capable designer grades them. Presence checks and counts in
the evidence paths are **not** visual verdicts. Camera names and datamodels come from
`docs/v2/visual/REVIEW_CAMERAS.md`; staging recipes from
`docs/v2/evidence/h/2026-11-21-round9/REVIEW_ROUND9.md` §23. Stage one candidate at a time with
`LookDevReview.enableAdditive(id, game)` from the SERVER datamodel and `disableAll()` between shots;
`water_r8_a` is already the shipping client default and needs no enable call. No place is saved.

| Shot | Candidate / state | Datamodel | Camera | CHECK evidence path |
|---|---|---|---|---|
| All-together additive (item 136) | `hubveg_r8` + `plots_r8` + `facades_r8` staged together via `enableAdditive`; no prior `enable` | Server | `canonical_overview` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_136.txt` |
| Base / default look | No candidate enabled | Server | `spawn`, `canonical_overview` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_138.txt` |
| Base / default look (shipped sky + water) | No candidate enabled | Client | `spawn_golden` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_137.txt` |
| 138 | `forest_pines_legacy` (comparison-only; default stays tropical) | Server | `forest_wall` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_138.txt` |
| 139 | `facades_r8` | Server | `hub_pakrt`; `hub_pasar`, `hub_gelap`, `hub_warung`, `hub_ronda`, `hub_polisi` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_139.txt` |
| 140 | `sawah_r8` | Server | `sawah_above`, `sawah_below` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_140.txt` |
| 141 | `river_r8` | Server | `bridge_north_bank`, `bridge_south_bank`, `river_rocks` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_141.txt` |
| 142 | `pathedge_r8` | Server | `spawn` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_142.txt` |
| 143 | `plots_r8` | Server | `plot_aerial_01`..`plot_aerial_10`, `plot_gate_01`..`plot_gate_10` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_143.txt` |
| 144 | `hubveg_r8` | Server | `hub_warung`; `hub_pasar`, `hub_gelap`, `hub_ronda`, `hub_polisi`, `hub_pakrt` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_144.txt` |
| 145 | `blocks_r9` | Server | `canonical_overview`, `spawn` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_145.txt` |
| 146 | `buildings_r8` (building kit) | Server | saved row camera on the staged folder (`ReviewCameraPos`/`ReviewLookAt`, `front=-228`, `up=60`, `lookY=16`); no registry name in `REVIEW_CAMERAS.md` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_146.txt` |
| 147 | `hubs_real_r9` | Server | `hub_pasar`, `hub_gelap`, `hub_warung`, `hub_ronda`, `hub_polisi`, `hub_pakrt` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_147.txt` |
| 148 | `pasar_awnings_r8` | Server | `pasar_awnings` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_148.txt` |
| 149 | `plaza_r9` | Server | `plaza_centre` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_149.txt` |
| 150 | `ronda_tower_r9` | Server | `ronda_tower` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_150.txt` |
| 151 | `rocks_r9` | Server | `river_rocks` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_151.txt` |

Notes: every camera above is in `docs/v2/visual/REVIEW_CAMERAS.md` except the `buildings_r8` row
camera, which is stored on its staged folder. `CAMERA_CLEAR` belongs to the main session's Studio
run; no visual pass/fail is recorded here.

## Section P re-review pack (WORK_QUEUE item 184, 2026-11-22)

Same staging rules as above; all CHECK paths below are under `docs/v2/evidence/h/2026-11-22-round10/`.
Item 183 is excluded: it is a stray-workspace check, not a scene-fix shot. Counts are not visual verdicts.

| Shot | Candidate / state | Datamodel | Camera | CHECK evidence path |
|---|---|---|---|---|
| 173 | `facades_r8` | Server | `ronda_tower`, `ronda_tower_wide` (context) | `docs/v2/evidence/h/2026-11-22-round10/CHECK_173.txt` |
| 174 | `river_r8` | Server | `river_rocks` | `docs/v2/evidence/h/2026-11-22-round10/CHECK_174.txt` |
| 175 | `plaza_r9` | Server | `plaza_centre` | `docs/v2/evidence/h/2026-11-22-round10/CHECK_175.txt` |
| 176 | `rocks_r9` | Server | `river_rocks` | `docs/v2/evidence/h/2026-11-22-round10/CHECK_176.txt` |
| 177 | `pathedge_r8` | Server | `spawn` | `docs/v2/evidence/h/2026-11-22-round10/CHECK_177.txt` |
| 178 | `sawah_r8` | Server | `sawah_above`, `sawah_below` | `docs/v2/evidence/h/2026-11-22-round10/CHECK_178.txt` |
| 179 | `pasar_awnings_r8` + `pasar_ground_r8` | Server | `pasar_awnings` | `docs/v2/evidence/h/2026-11-22-round10/CHECK_179.txt` |
| 180 | No candidate — camera-only fix | Server | `ronda_tower`, `ronda_tower_wide` | `docs/v2/evidence/h/2026-11-22-round10/CHECK_180.txt` |
| 181 | `plots_r8` | Server | `plot_aerial_01` | `docs/v2/evidence/h/2026-11-22-round10/CHECK_181.txt` |
| 182 | `blocks_r9` | Server | `canonical_overview`, `canonical_overview_left`, `canonical_overview_right` | `docs/v2/evidence/h/2026-11-22-round10/CHECK_182.txt` |

## Section Q sprint-3 shot list (WORK_QUEUE item 225, 2026-11-23)

Same staging rules as above. Every CHECK path below is under `docs/v2/evidence/h/2026-11-23-sprint3/`.
Camera names are the exact registry names in `docs/v2/visual/REVIEW_CAMERAS.md`. Rows for items whose
Studio harness lands later still use the mandated `CHECK_<item>.txt` path; presence checks and counts
are not visual verdicts. No place is saved.

| Shot | Candidate / state | Datamodel | Camera | CHECK evidence path |
|---|---|---|---|---|
| 212 | No candidate — default riverbank foam (`FOAM_LINE`, `PERF_BUDGET`) | Server | `bridge_north_bank`, `bridge_south_bank`, `river_rocks` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_212.txt` |
| 213 | `animals_r8` ducks reused in the shallows (`DUCKS`, `DUCKS_ON_WATER`; animation client-only) | Server | `bridge_north_bank`, `bridge_south_bank`, `river_rocks` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_213.txt` |
| 214 | No candidate — default sawah terrace retaining stones (`TERRACE_WALLS`, `WALL_ON_TERRAIN`) | Server | `sawah_above`, `sawah_below` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_214.txt` |
| 215 | No candidate — default sawah gubuk, scarecrows and bird-scare ribbons (`GUBUK`, `SCARECROWS`, `NO_FLOATERS`) | Server | `sawah_above`, `sawah_below` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_215.txt` |
| 218 | No candidate — lighting-only review variants; `clockTime` 16.5 / 21 comes from the registry (`CAMERA_CLEAR`) | Server | `plaza_centre_golden`, `plaza_centre_night`, `pasar_awnings_golden`, `pasar_awnings_night`, `path_curve_golden`, `path_curve_night`, `lamp_night_golden`, `lamp_night_night`, `crop_stages_golden` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_218.txt` |
| 219 | All `LookDev.IDS` staged and unstaged once (`LOOKDEV_LEAK`) | Server | `canonical_overview`, `spawn` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_219.txt` |
| 222 | No candidate — `Strings` id/en audit for the junction signs and Pasar board (`STRINGS_BOTH_VARIANTS`) | Server | `signpost_pasar`, `hub_pasar` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_222.txt` |
| 223 | No candidate — candidate-doc parity (`CANDIDATES.md`, `CANDIDATE_INDEX.md`) | Server | `canonical_overview` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_223.txt` |
| 246 | `lamps_r10` at `clockTime` 21 (`LAMP_POOL`, `LIGHT_COST`, `LAMP_NIGHT_ONLY`) | Server | `lamp_night` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_246.txt` |
| 247 | `crop_stages_r10` at ClockTime 13 and golden hour (`CROP_STAGE_HEIGHT`, `CROP_STAGE_COLOR`, `SUBJECT_COVERAGE_CROP_GOLDEN`) | Server | `crop_stages_close`, `crop_stages_golden` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_247.txt` |
| 250 | `road_fence_r10` (`SC250_ROAD_FENCE_R10`, `CG250_ROAD_FENCE_R10`) | Server | `path_curve` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_250.txt` |
| 250 | `ditch_water_r10` (`SC250_DITCH_WATER_R10`, `CG250_DITCH_WATER_R10`) | Server | `ditch_water_close` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_250.txt` |
| 250 | `crop_stages_r10` (`SC250_CROP_STAGES_R10`, `CG250_CROP_STAGES_R10`) | Server | `crop_stages_close` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_250.txt` |
| 250 | `hill_dressing_r10` (`SC250_HILL_DRESSING_R10`, `CG250_HILL_DRESSING_R10`) | Server | `terrace_wall` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_250.txt` |
| 250 | `hubveg_r8` (`SC250_HUBVEG_R8`, `CG250_HUBVEG_R8`) | Server | `hub_warung` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_250.txt` |
| 251 | `mountains_r10` (`MOUNTAIN_DIST`, `NO_BOX_MOUNTAIN`, `SUBJECT_COVERAGE_251`, `SC251_MAX`) | Server | `horizon_north`, `canonical_overview` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_251.txt` |
| 252 | `bamboo_bridge_r10` — default bridge hidden while staged (`BRIDGE_SWAP`, `BRIDGE_RESTORE`, `SUBJECT_COVERAGE_252`) | Server | `bridge_side` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_252.txt` |
| 253 | `kampung_r10` — baked shrubs, no Ball melons (`NO_MELONS`, `SHRUB_MODELS`, `LOOKDEV_LEAK`) | Server | `kampung_view` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_253.txt` |
| 254 | `crop_stages_r10` — leaf fans and visible produce (`CROP_STAGE_WIDTH`, `NO_MELONS`, `CROP_STAGE_HEIGHT`, `CROP_STAGE_COLOR`) | Server | `crop_stages_close` | `docs/v2/evidence/h/2026-11-23-sprint3/CHECK_254.txt` |

`horizon_south` and the other `CAL_*` names in the check harnesses are FAIL calibration anchors, not
review shots. `full_r10` is the item-220 perf-census staging label, not a `LookDev.IDS` candidate, so
it has no shot row.
