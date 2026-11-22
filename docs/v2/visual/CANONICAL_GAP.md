# Canonical-map gap report (WORK_QUEUE section O item 154, 2026-11-21)

Scope: the "target look" checklist in `docs/v2/plan/WORK_QUEUE.md` lines 868–876. Status means
**presence in the shipping default look**, **presence only in an OFF-by-default LookDev candidate**,
or **missing**. Counts are objective reads from the cited evidence; no visual quality verdict is made
here and no look is graded. `docs/v2/visual/art/map/RECONCILIATION.md` governs coordinate conflicts;
`MapSpec.luau` stays the coordinate authority.

| # | Canonical feature | Status | Counts / presence (no look judgement) | Evidence file(s) |
|---|---|---|---|---|
| 1 | Green everywhere — thick broadleaf round-canopy tree wall on the outer ring and hills; ≥3 species; no pines | present in default look | 272 `ForestTree` instances, 4 species (kelapa, mangga, pisang, bambu), 0 pine-named instances; `PERF_BUDGET 334/500` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_138.txt` |
| 2 | Green everywhere — medium/large round-canopy trees (8–12 studs) in the blocks between buildings, plots and ring road | present as a candidate (`blocks_r9`) | 72 trees, 4 species; 168 staged instances total (`BLOCK_TREES 72`, `BLOCK_SPECIES 4`) | `docs/v2/evidence/h/2026-11-21-round9/CHECK_145.txt` |
| 3 | Green everywhere — large canopy trees at each hub (8–12 studs) | present as a candidate (`hubveg_r8`) | 2 canopy trees per hub across 6 hubs (`HUB_TREES 2 >=2`), 50 staged instances per hub | `docs/v2/evidence/h/2026-11-21-round9/CHECK_144.txt` |
| 4 | Green everywhere — small shrubs and flower patches between buildings, plots and the ring road | present as a candidate (`blocks_r9`, `hubveg_r8`) | 96 shrubs (`CHECK_145`), 50 staged instances/hub with 14 species/hub (`CHECK_144`) | `docs/v2/evidence/h/2026-11-21-round9/CHECK_145.txt`, `docs/v2/evidence/h/2026-11-21-round9/CHECK_144.txt` |
| 5 | Green everywhere — palms at the map corners / outer ring | present in default look | `kelapa` is one of the 4 default ring species in the 272-tree wall | `docs/v2/evidence/h/2026-11-21-round9/CHECK_138.txt` |
| 6 | Sawah — four stepped terraces with blue water between the rows | present in default look | 4 water sheets × 2 panes (`SAWAH_WATER 4/4`), terrace tops unchanged (`SAWAH_TOPS 0/0.5`) | `docs/v2/evidence/h/2026-11-21-round9/CHECK_72.txt` |
| 7 | Sawah — green bands of rice rows on all four terraces | present as a candidate (`sawah_r8`) | 294 rows, 1764 clumps, `SAWAH_GREEN 76/40` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_140.txt` |
| 8 | Sawah — grassy bund dressing on the terrace edges | present as a candidate (`sawah_r8`) | 240 verge pieces (`SAWAH_VERGE 240 >=40`) | `docs/v2/evidence/h/2026-11-21-round9/CHECK_140.txt` |
| 9 | Sawah — small gubuk (field hut) on terrace 2 | present as a candidate (`sawah_r8`) | 1 gubuk (`GUBUK 1/1`) | `docs/v2/evidence/h/2026-11-21-round9/CHECK_140.txt` |
| 10 | Sawah — balai desa standing in the middle gap | missing | 42 × 28 reserved slot at (0, -137); no hall built in default or in any LookDev candidate | `docs/v2/visual/art/MAP_SPEC.md`, `docs/v2/visual/art/map/RECONCILIATION.md` |
| 11 | Plots — the ten square plot sites (anchors and gates) | present in default look | 10 `PlotAnchor` parts, 40 × 40 footprint each, gates on the inner side | `docs/v2/visual/art/MAP_SPEC.md` |
| 12 | Plots — visible fence, gate and name sign | present as a candidate (`plots_r8`) | 16 fence segments per plot (min=16 ≥8), 10 gates clear, `PLOT_FENCE_VISIBLE 87 >=70` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_143.txt` |
| 13 | Plots — scarecrow, mailbox with sign, irrigation ditch and hut | present as a candidate (`plots_r8`) | staged in 10 plots; corner gubuk in plots 2/5/8 | `docs/v2/evidence/h/2026-11-21-round9/CHECK_143.txt`, `docs/v2/visual/CANDIDATES.md` |
| 14 | Paths — warm dirt paths | present in default look | `spawn_ground_r6` promoted to the shipping default at item 55; dirt over the full road corridor | `docs/v2/plan/MASTER_PLAN.md`, `docs/v2/visual/CANDIDATES.md` |
| 15 | Paths — grass right up to the path edge | present as a candidate (`pathedge_r8`) | 626 staged pieces (`PATH_EDGE 626 >=120`), `PATH_EDGE_OFFSET 0 0`, `PATH_CLEAR 0 0` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_142.txt` |
| 16 | Paths — round ring road and wide south bridge road | present in default look | 4 axis roads, 56 ring segments, 2 continuations (62 mapped paths); 12-wide south continuation | `docs/v2/evidence/h/2026-11-21-round9/CHECK_75.txt`, `docs/v2/visual/art/MAP_SPEC.md` |
| 17 | Hubs — Pasar with a red roof | present as a candidate (`hubs_real_r9`) | 1 of 6 mapped buildings (`indonesian_house`, PROPOSAL); `HUB_FIT 0 0` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_147.txt`, `docs/v2/visual/art/BUILDING_KIT.md` |
| 18 | Hubs — many striped red/white/blue awnings around the Pasar | present as a candidate (`pasar_awnings_r8`) | 12 stalls (`STALLS 12 >=10`), 72 stripes (`AWNING_STRIPES 72 >=30`), 24 per colour | `docs/v2/evidence/h/2026-11-21-round9/CHECK_148.txt` |
| 19 | Hubs — Warung as a cluster of tin-roof stalls and tables | present as a candidate (`hubs_real_r9`) | 1 of 6 mapped buildings (`warung_penyetan`, PROPOSAL) | `docs/v2/evidence/h/2026-11-21-round9/CHECK_147.txt`, `docs/v2/visual/art/BUILDING_KIT.md` |
| 20 | Hubs — blue-roofed Pos Polisi | present as a candidate (`hubs_real_r9`) | 1 of 6 mapped buildings (`pendopo_jawa`, PROPOSAL) | `docs/v2/evidence/h/2026-11-21-round9/CHECK_147.txt`, `docs/v2/visual/art/BUILDING_KIT.md` |
| 21 | Hubs — bamboo Pos Ronda tower | present as a candidate (`ronda_tower_r9`) | 24 original Parts, `TOWER_HEIGHT 30` (28..32), `TOWER_BASE 7.7` (≤9) | `docs/v2/evidence/h/2026-11-21-round9/CHECK_150.txt` |
| 22 | Hubs — Pak RT house with a yellow-orange roof | present as a candidate (`hubs_real_r9`) | 1 of 6 mapped buildings (`rumah_4`, PROPOSAL) | `docs/v2/evidence/h/2026-11-21-round9/CHECK_147.txt`, `docs/v2/visual/art/BUILDING_KIT.md` |
| 23 | Hubs — Lapangan fountain/monument, bunting and umbrellas | present as a candidate (`plaza_r9`) | 1 fountain, 11 bunting flags, 4 umbrellas, 4 benches, 1 shade tree | `docs/v2/evidence/h/2026-11-21-round9/CHECK_149.txt` |
| 24 | River — wide blue water | present in default look | variant A applied at boot, `WATER_DEFAULT 5/5` (WaterColor 48/124/104, Transparency 0.28) | `docs/v2/evidence/h/2026-11-21-round9/CHECK_137.txt` |
| 25 | River — rocks along the banks and field edges | present as a candidate (`rocks_r9`, `river_r8`) | 48 rocks (24 river-band, `ROCK_COUNT 48 >=25`, `ROCK_SPECIES 3 >=2`) plus 12 bank boulders (`RIVER_ROCKS 12 >=12`) | `docs/v2/evidence/h/2026-11-21-round9/CHECK_151.txt`, `docs/v2/evidence/h/2026-11-21-round9/CHECK_141.txt` |
| 26 | River — palms near the river | present as a candidate (`river_r8`) | 54 bank plants, 5 species, 27 tall plants (`RIVER_BANK_VEG 54 >=40`) | `docs/v2/evidence/h/2026-11-21-round9/CHECK_141.txt`, `docs/v2/plan/MASTER_PLAN.md` |
| 27 | River — bamboo bridge about 8 studs wide | present in default look | greybox bamboo bridge deck with rails; 8-stud clear corridor (`BRIDGE_WALKABLE 8 >=8`, rails staged by the candidate for the check) | `docs/v2/evidence/h/2026-11-21-round9/CHECK_141.txt`, `docs/v2/plan/MASTER_PLAN.md` |
| 28 | Atmosphere — warm light / golden-hour feel | present in default look | golden-hour season preset; sky `sky_r6_e` promoted at item 55 (designer verdict **yes**) | `docs/v2/plan/MASTER_PLAN.md`, `docs/v2/visual/CANDIDATES.md` |
| 29 | Atmosphere — hazy blue-green hill ring | present in default look | 272-tree hill/ring forest; sky + Atmosphere stack promoted at item 55 | `docs/v2/evidence/h/2026-11-21-round9/CHECK_138.txt`, `docs/v2/plan/MASTER_PLAN.md` |

**Summary:** 29 features audited: **10 present in default look** (rows 1, 5, 6, 11, 14, 16, 24, 27,
28, 29), **18 present as candidates** (rows 2, 3, 4, 7, 8, 9, 12, 13, 15, 17, 18, 19, 20, 21, 22,
23, 25, 26), **1 missing** (row 10).

## Missing features — proposals (visual only, no gameplay)

- **Balai desa in the central gap (row 10).** Add a visual-only hall model in the reserved 42 × 28
  slot at (0, -137), derived from `MapSpec`, with a roof and signage. Do not add leaderboards, permits,
  elections or any gameplay behaviour; the slot remains a visual landmark only until a designer
  decision assigns it a function.
