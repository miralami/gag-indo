# CHECKS_SUMMARY — round 9, one verdict line per item (WORK_QUEUE item 100)

Datetime: 2026-11-21. Verdicts read from each `CHECK_*.txt` under
`docs/v2/evidence/h/2026-11-21-round9/`. `PASS` = objective check(s) emitted PASS with a Studio
evidence file. `LUNE-ONLY` = audit proven by specs/data only (no Studio emit). `BLOCKED` = left
unresolved with reason. A visual/aural yes/no is NOT claimed here — a designer grades shots; these
are the objective checks and evidence paths only. No place saved, nothing published.

| Item | Candidate / task | Verdict | Evidence | Primary emit (verbatim, first line) |
|---|---|---|---|---|
| 68 | r8 check harness | PASS | CHECK_68.txt | `CHECK LOOKDEV_LEAK PASS 0 leaks 0 leaks` |
| 69 | review cameras | PASS | CHECK_69.txt | `CHECK CAMERA_CLEAR PASS 0 blocked/26 checked 0 blocked` |
| 70 | `hubveg_r8` | PASS | CHECK_70.txt | `CHECK LOAD_FAILURES PASS 0 0` / `VEG_HUB_pasar PASS 16 >=12` |
| 71 | `plots_r8` | PASS | CHECK_71.txt | `CHECK LOAD_FAILURES PASS 0 0` / `PLOT_FENCE PASS min=8 >=6 each` |
| 72 | `sawah_r8` | PASS | CHECK_72.txt | `CHECK LOAD_FAILURES PASS 0 0` / `SAWAH_TOPS PASS 0 0.5` |
| 73 | `river_r8` | PASS | CHECK_73.txt | `CHECK LOAD_FAILURES PASS 0 0` / `RIVER_BANK_VEG PASS 56 >=30` |
| 74 | `ring_r8` forest ring | PASS | CHECK_74.txt (+138/102) | `CHECK RING_COUNT PASS 272 250`; formerly BLOCKED, resolved via 138/102 (no pines) |
| 75 | `pathedge_r8` | PASS | CHECK_75.txt | `CHECK LOAD_FAILURES PASS 0 0` / `PATH_EDGE PASS 618 >=120` |
| 76 | `water_r8_a/b/c` | PASS | CHECK_76.txt | `CHECK WATER_SAFE PASS 3 3` / `WATER_RESTORE PASS 3 3` |
| 77 | `buildings_r8` | PASS | CHECK_77.txt | `CHECK BLDG_VISIBLE PASS 6 6` / `BLDG_WIDTH PASS 6 6` |
| 78 | `facades_r8` | PASS | CHECK_78.txt | `CHECK FACADE_PARTS PASS 6 6` / `DOOR_CLEAR PASS 6 6` |
| 79 | `hubprops_r8` | PASS | CHECK_79.txt | `CHECK HUBPROPS_VISIBLE PASS 6 5` / `HUBPROPS_ON_GRASS PASS 0 0` |
| 80 | `streetfurn_r8` | PASS | CHECK_080.txt | `CHECK STREETFURN PASS 37 >=18 posts` / `STRINGS_PARITY PASS 3 3` |
| 81 | `spanduk_r8` | PASS | CHECK_081.txt | `CHECK SIGN_TEXT_PARITY PASS 5 5` / `SIGN_FACING PASS 0 <=30deg` |
| 82 | `animals_r8` | PASS | CHECK_082.txt | `CHECK ANIMAL_COUNT PASS 11 1..14` / `ANIMAL_BOUNDS PASS 0 0` |
| 83 | `flyers_r8` | PASS | CHECK_083.txt | `CHECK FLYER_COUNT PASS 0 0 invalid tiers` / `FLYER_COST PASS 0.0104 <0.3ms` |
| 84 | `smoke_r8` | PASS | CHECK_084.txt | `CHECK EMITTERS PASS 0 0 violations` / `LIGHTS PASS 0 0 violations` |
| 85 | `wind_r8` | PASS | CHECK_085.txt | `CHECK WIND_SET PASS 2.915 0<M<=12` / `SWAY_TWEENS PASS 10 30` |
| 86 | `npcs_r8` | PASS | CHECK_086.txt | `CHECK NPC8_ROLES PASS 5 5` / `NPC8_OUTFITS PASS 5 5` |
| 87 | `npcs_idle_r8` | PASS | CHECK_087.txt | `CHECK IDLE_TRACKS PASS 10 10` / `IDLE_SWAY PASS 10 10` |
| 88 | `ambient_walkers_r8` | PASS | CHECK_088.txt | `CHECK WALKER_SPEED PASS 6 8` / `WALKER_MOVE PASS 8 8` |
| 89 | `day_cycle_r8` | PASS | CHECK_089.txt | `CHECK DAY_PHASES_MONOTONIC PASS` / `DAY_1600_CONTRAST PASS 2.705 >=2.5929` |
| 90 | `night_r8` | PASS | CHECK_090.txt | `CHECK NIGHT_WINDOWS PASS 16 12` / `NIGHT_LIGHTS PASS 12 24` |
| 91 | `grade_r8_a/b/c` | PASS | CHECK_091.txt | `CHECK GRADE_SAFE PASS 3 3` / `GRADE_RESTORE PASS 3 3` |
| 92 | `sounds_r8` | PASS | CHECK_092.txt | `CHECK SOUND_LOADED PASS 6 6` / `SOUND_VOLUME PASS 6 6` |
| 93 | crop stage audit | PASS | CHECK_093.txt | `CHECK CROP_GROWTH PASS 12 12` |
| 94 | icon audit | LUNE-ONLY | CHECK_094.txt | 58 PNGs: 51 PASS / 7 FAIL (flagged, not hidden); 35 near-dup pairs. Pure file audit. |
| 95 | strings audit | LUNE-ONLY | CHECK_095.txt | 2 `[STRINGS FLAG]` lines; spec-driven, no Studio emit. |
| 96 | iconmap coverage | LUNE-ONLY | CHECK_096.txt | 27/27 IDs in manifest, 0 duplicates; spec-driven, no Studio emit. |
| 97 | perf budget table | PASS | CHECK_097.txt | `CHECK PERF_BUDGET PASS 334 500`; 8 over-budget candidates FLAGGED. |
| 98 | `LOOKDEV_LEAK` sweep | PASS | CHECK_098.txt | `CHECK LOOKDEV_LEAK PASS 0 leaks 0 leaks` (both VMs); 1 leak fixed. |
| 99 | Gate 1 evidence sweep | PASS | CHECK_099.txt | `CHECK BUG014 PASS` / `BUG017 PASS` / `BUG018 PASS` (×2); BUG-014/018 → SEEN-IN-STUDIO. |
| 100 | review pack (this item) | PASS | REVIEW_ROUND9.md §24 + this file | Docs written; main session takes shots, designer grades. No emit. |

Legend: every `PASS` above is backed by a `CHECK_*.txt` file with a verbatim Studio emit EXCEPT items
94–96 (`LUNE-ONLY`, spec/file audits) and 100 (documentation). Item 74's earlier BLOCKED reason was
corrected (V-D4 "tropical, no pines" decided) and closed via items 138/102. No item 68–100 remains
BLOCKED. Section N (round 10) follows after item 101 (no-op marker).
