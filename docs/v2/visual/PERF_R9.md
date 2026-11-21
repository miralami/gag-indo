# PERF_R9 — round-9 perf budget table (WORK_QUEUE M6 item 97)

Datetime: 2026-11-21. Method: live Roblox Studio Play, both VMs, no place saved, nothing published.

## Target

Measure and record: instances, parts, `MeshPart` triangle estimate and `ParticleEmitter` count for the
default look and for each LookDev candidate enabled alone on top of it. CHECK `PERF_BUDGET`: the
default look is within the Sedang tier budget in `VISUAL_MASTER_PLAN.md` §6. Flag, never hide, any
candidate over budget. This is a REPORT — no visual verdict, no candidate promoted to default.

## Budget source (`VISUAL_MASTER_PLAN.md` §6, Sedang)

- Draw calls **under about 500** in the spawn view. Operational proxy used everywhere in round 9:
  count of `BasePart`s whose `CFrame.Position` is within 100 studs of `(0,0,0)` (`near100`). Target
  **500**. This is the recorded census method in `evidence/h/2026-11-19-budget-check/REPORT.md`.
- Triangles **under about 500k** in the spawn view. `primTris` below is only a PRIMITIVE estimate
  (Block/Wedge 12, Cylinder 32, Ball/Sphere 320); `MeshPart` triangle count is NOT exposed to Luau,
  so `mesh` (MeshPart count) is reported separately and true triangles are HIGHER than `primTris`.
  No triangle figure is invented.
- Particles: emitters pooled, hard cap per tier; `smoke_r8` is the only candidate staging emitters.

## Method

- Fresh Play session. All 42 server applier modules (`ServerScriptService.Server.World`) required in
  the Server VM; all 23 client applier modules (`StarterPlayer.StarterPlayerScripts.Client`) required
  in the Client VM. 46 server candidates + 33 client candidates = 79 appliers registered.
- Each candidate staged ALONE via `LookDev.enable(id, {studio=true})` in its native VM; a `disableAll()`
  before and after every candidate. Recorded `pre` and `staged` census in the SAME call; reported
  value = fresh-default + (staged − pre). This self-corrects for a small module-load residue observed
  after requiring appliers (spawn_ground geometry; +42 inst/+41 parts/+4 near) and was verified to
  reproduce the earlier single-candidate readings exactly (blocks_r9 5592/2388/354, facades_r8
  4054/1779/383, hubs_real_r9 8094/3466/692, crops 4379/2052/334).
- `near100` uses the harness's exact fallback (`GetBoundingBox()` is Model-only; BaseParts use
  `CFrame.Position`), matching `review_check_r8.luau` VERBATIM `CHECK PERF_BUDGET PASS 334 500`.
- Deltas are deterministic across repeated runs (crops re-measured 3x: identical).

## Default look (no candidate)

| VM | instances | parts | MeshParts | primTris | emitters | near100 |
|---|---|---|---|---|---|---|
| Server | 3921 | 1713 | 299 | 66,248 | 0 | 334 |
| Client | 3931 | 1713 | 299 | 66,248 | 0 | 334 |

Default is the same 334/500 proxy the harness reports, well under ~500 draw calls. `CHECK PERF_BUDGET
PASS 334 500` — **PASS**. No default-look change; all candidates remain off by default.

## Server candidates (46), staged alone on default

| id | instances | parts | MeshParts | primTris(est) | emitters | near100 | budget |
|---|---|---|---|---|---|---|---|
| police_walkin | 3921 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| buildings_r3 | 3941 | 1723 | 309 | 66,248 | 0 | 344 | ok |
| vegetation_r3 | 3957 | 1728 | 314 | 66,248 | 0 | 367 | ok |
| props_r3 | 3953 | 1730 | 316 | 66,248 | 0 | 351 | ok |
| npcs_r3 | 4596 | 1755 | 339 | 66,272 | 0 | 376 | ok |
| buildings_r4 | 4041 | 1798 | 384 | 66,248 | 0 | 419 | ok |
| vegetation_r4 | 3937 | 1718 | 304 | 66,248 | 0 | 337 | ok |
| props_r4 | 3946 | 1720 | 306 | 66,248 | 0 | 334 | ok |
| npcs_r4 | 4427 | 1783 | 367 | 66,272 | 0 | 404 | ok |
| spawn_ground_r5 | 4038 | 1829 | 299 | 67,640 | 0 | 340 | ok |
| vegetation_r5 | 4000 | 1739 | 325 | 66,248 | 0 | 348 | ok |
| props_r5 | 3958 | 1723 | 309 | 66,248 | 0 | 338 | ok |
| npcs_r5 | 5332 | 1794 | 374 | 66,320 | 0 | 415 | ok |
| spawn_r5 | 5451 | 1847 | 428 | 66,308 | 0 | 460 | ok |
| spawn_ground_r6 | 4038 | 1829 | 299 | 67,640 | 0 | 340 | ok |
| vegetation_r6 | 4564 | 1863 | 341 | 67,544 | 0 | 348 | ok |
| npcs_r6 | 5342 | 1794 | 374 | 66,320 | 0 | 415 | ok |
| props_r6 | 3958 | 1723 | 309 | 66,248 | 0 | 338 | ok |
| vegetation_r7 | 5161 | 2047 | 417 | 68,840 | 0 | 584 | **OVER** |
| npcs_r7 | 5376 | 1798 | 379 | 66,308 | 0 | 419 | ok |
| props_r7 | 4068 | 1756 | 303 | 66,776 | 0 | 377 | ok |
| hubveg_r8 | 7510 | 2629 | 595 | 73,688 | 0 | 799 | **OVER** |
| plots_r8 | 4610 | 2391 | 299 | 74,384 | 0 | 334 | ok |
| sawah_r8 | 39472 | 30194 | 299 | 408,020 | 0 | 334 | ok* |
| river_r8 | 4323 | 1999 | 349 | 69,080 | 0 | 334 | ok |
| pathedge_r8 | 9251 | 6721 | 299 | 126,344 | 0 | 1146 | **OVER** |
| buildings_r8 | 8100 | 3472 | 350 | 98,256 | 0 | 1740 | **OVER** |
| facades_r8 | 4054 | 1779 | 299 | 67,040 | 0 | 383 | ok |
| hubprops_r8 | 4273 | 1868 | 318 | 69,276 | 0 | 442 | ok |
| forest_pines_legacy | 2808 | 1564 | 150 | 66,248 | 0 | 334 | ok |
| blocks_r9 | 5592 | 2388 | 448 | 72,560 | 0 | 354 | ok |
| hubs_real_r9 | 8094 | 3466 | 350 | 98,184 | 0 | 692 | **OVER** |
| pasar_awnings_r8 | 4222 | 2001 | 299 | 69,944 | 0 | 558 | **OVER** |
| plaza_r9 | 4003 | 1783 | 299 | 67,088 | 0 | 404 | ok |
| ronda_tower_r9 | 3947 | 1737 | 299 | 66,556 | 0 | 334 | ok |
| rocks_r9 | 4050 | 1793 | 299 | 86,920 | 0 | 334 | ok |
| streetfurn_r8 | 4074 | 1829 | 299 | 69,280 | 0 | 369 | ok |
| spanduk_r8 | 3976 | 1742 | 299 | 66,796 | 0 | 359 | ok |
| npcs_r8 | 5384 | 1799 | 380 | 66,308 | 0 | 420 | ok |
| npcs_idle_r8 | 6848 | 1884 | 460 | 66,368 | 0 | 505 | **OVER** |
| ambient_walkers_r8 | 6170 | 1841 | 419 | 66,344 | 0 | 442 | ok |
| night_r8 | 3962 | 1741 | 299 | 66,584 | 0 | 357 | ok |
| grade_r8_a | 3921 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| grade_r8_b | 3921 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| grade_r8_c | 3921 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| sounds_r8 | 3934 | 1719 | 299 | 66,320 | 0 | 335 | ok |

\* `sawah_r8`: near100 stays 334 (all 28,481 added parts sit outside the 100-stud census), but it adds
~342k primitive triangles (total 408,020) and 30,194 parts. Triangle total is under 500k BUT excludes
MeshPart triangles, and part count is very large. Flagged as a heavy candidate for the designer; not
over the draw-call proxy.

## Client candidates (33), staged alone on default

| id | instances | parts | MeshParts | primTris(est) | emitters | near100 | budget |
|---|---|---|---|---|---|---|---|
| plaza_lighting | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| icons | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| textures | 3941 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| npcs | 3949 | 1728 | 299 | 66,428 | 0 | 344 | ok |
| crops | 4379 | 2052 | 299 | 93,664 | 0 | 673 | **OVER** |
| hubprops | 3975 | 1756 | 299 | 69,896 | 0 | 375 | ok |
| sounds | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| corner | 3953 | 1734 | 299 | 67,832 | 0 | 355 | ok |
| textures_r3 | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| day_cycle | 3944 | 1719 | 299 | 66,320 | 0 | 340 | ok |
| icons_r3 | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| sky_r3 | 3944 | 1725 | 299 | 66,392 | 0 | 346 | ok |
| textures_r4 | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| sky_r4_a | 3944 | 1725 | 299 | 66,392 | 0 | 346 | ok |
| sky_r4_b | 3944 | 1725 | 299 | 66,392 | 0 | 346 | ok |
| sky_r4_c | 3944 | 1725 | 299 | 66,392 | 0 | 346 | ok |
| sky_r5 | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| sky_r6_a | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| sky_r6_b | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| sky_r6_c | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| sky_r6_d | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| sky_r6_e | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| sky_r6_f | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| terrain_r6_a | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| terrain_r6_b | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| water_r8_a | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| water_r8_b | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| water_r8_c | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| animals_r8 | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| flyers_r8 | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| smoke_r8 | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| wind_r8 | 3931 | 1713 | 299 | 66,248 | 0 | 334 | ok |
| day_cycle_r8 | 3944 | 1719 | 299 | 66,320 | 0 | 340 | ok |

Notes:
- Many client candidates (icons, textures*, sky*, terrain*, water*, animals, flyers, smoke, wind,
  sounds, plaza_lighting) change materials/properties/lighting rather than staging new workspace
  geometry, so their census delta is 0 (or small) — correct, not a measurement failure.
- `crops` stages its 36 showcase Models at `HumanoidRootPart + (-15,+10,+14)`, i.e. near the player
  spawn. In this session that is d=24–58 studs from origin, so +339 parts fall inside the 100-stud
  proxy (near100 673, OVER). In an earlier session the player spawned farther out and the same
  showcase measured +0 near (d>100) — the figure is spawn-position dependent; the conservative
  (OVER) reading is reported here. Flag never hidden.
- `smoke_r8`: live client staging creates 0 emitters here because its applier loads MapSpec from
  `ServerScriptService.Server.World` (server-only, not visible in the Client VM). Item 84's pure-data
  audit already recorded 9 emitters (2 chimney, 1 warung steam, 6 torch flames, max Rate 10 <= 12);
  those sit at the 260–460-stud hubs, outside the spawn census. No emitter figure invented.

## Over-budget flags (8 of 79) — reported, not hidden

| id | VM | near100 | over by |
|---|---|---|---|
| vegetation_r7 | server | 584 | +84 |
| hubveg_r8 | server | 799 | +299 |
| pathedge_r8 | server | 1146 | +646 |
| buildings_r8 | server | 1740 | +1240 |
| hubs_real_r9 | server | 692 | +192 |
| pasar_awnings_r8 | server | 558 | +58 |
| npcs_idle_r8 | server | 505 | +5 |
| crops | client | 673 | +173 |

These reproduce the flagged values already recorded in round-9 evidence
(`CHECK_142.txt` 1146 pathedge, `CHECK_144.txt` 799 hubveg, `CHECK_147.txt` 692 hubs_real,
`CHECK_148.txt` 558 pasar_awnings) and add new flags (buildings_r8, vegetation_r7, npcs_idle_r8,
crops). All are OFF-BY-DEFAULT candidates; the shipping default stays at 334/500 PASS.

## Decision for designer

No promotion decision made here — this is a measurement report. The 8 over-budget candidates and the
heavy `sawah_r8` (408k prim tris, 30k parts, outside spawn census) should be considered before enabling
any of them together or by default. No visual/aesthetic judgment in this document.
