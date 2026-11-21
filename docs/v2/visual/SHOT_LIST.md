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
