# Promotion plan — designer-yes r8 scene candidates (WORK_QUEUE item 224)

Doc only. No code, no flag added, no place saved. Scope: the six `yes` ids named in item 224.
Only a designer `**yes` verdict in `docs/v2/visual/CANDIDATES.md` qualifies.
`docs/v2/visual/PROVISIONAL_VERDICTS.md` calls are **not** designer verdicts and may not be promoted.

`PERF_BUDGET` = live Studio count of `BasePart` centres within XZ radius 100 of origin; Sedang
proxy target 500 (`docs/v2/visual/PERF_R9.md` §1–2, §5). Round-9 default measured 334/500;
round-11 checks measure 338/500 after later default-look changes (`CHECK_191.txt`, `CHECK_197.txt`).
No candidate evidence records a measured fps delta; fps is UNVERIFIED everywhere below.

## Candidate table

| candidate | verdict evidence path | perf cost (recorded; no numbers invented) | dependencies (real wiring) | order (rationale) | rollback flag |
|---|---|---|---|---|---|
| `plots_r8` | `docs/v2/visual/CANDIDATES.md` row 60; `docs/v2/visual/CANDIDATE_INDEX.md` row 59; `docs/v2/evidence/h/2026-11-22-review-round10/VOTE_ROUND10.html` (`init.plots_r8 = "yes"`); `docs/v2/evidence/h/2026-11-22-round10/CHECK_181.txt` | `PERF_BUDGET PASS 334/500` (`docs/v2/evidence/h/2026-11-21-round9/CHECK_143.txt`). `PERF_R9.md`: 4,610 instances / 2,391 parts / 299 MeshParts / 74,384 prim tris, near100 334. fps UNVERIFIED. | Applier `src/server/World/LookDevPlotsR8.luau` (`LookDev.register` line 504). Data `src/shared/ModelMapPlotsR8.luau`; `TierThin`, `MapSpec`. Registry: `LookDev.IDS` line 158, `LookDev.candidates.plots_r8` line 796, `LookDevReview.paths.plots_r8` line 76. Boot `pcall(require, script.Parent.World.LookDevPlotsR8)` in `src/server/Main.server.luau` line 128. No baked asset IDs. | **1** — no asset IDs, no load path, perf neutral; gate/sign/clearance already PASS (`CHECK_181.txt`, `CHECK_143.txt`). Promote first to isolate regressions. | None today. Existing rollback = Studio-only `LookDev.disable()` / `disableAll()` (never persisted, refused on published servers). Item 226 proposal: one `DefaultLook.PROMOTED` constant; empty/false restores today's shipping look. No code here. |
| `river_r8` | `CANDIDATES.md` row 62; `CANDIDATE_INDEX.md` row 61; `VOTE_ROUND10.html` (`init.river_r8 = "yes"`); `docs/v2/evidence/h/2026-11-22-round10/CHECK_174.txt`; `docs/v2/evidence/h/2026-11-22-round11/CHECK_192.txt` | `PERF_BUDGET PASS 334/500` (`docs/v2/evidence/h/2026-11-21-round9/CHECK_141.txt`). `PERF_R9.md`: 4,323 instances / 1,999 parts / 349 MeshParts / 69,080 prim tris, near100 334. `CHECK_192.txt` adds baked plants/lilies but records no new `PERF_BUDGET`; post-192 perf UNVERIFIED. fps UNVERIFIED. | Applier `src/server/World/LookDevRiverR8.luau` (`LookDev.register` line 548). Data `src/shared/ModelMapRiverR8.luau`, `ModelMapVegetationR4`, `TierThin`, `MapSpec`; baked models via `LookDevAssetLoader` (IDs in `CHECK_192.txt` §Setup and `ASSET_MANIFEST.md` section Q). Registry: `LookDev.IDS` 160, `LookDev.candidates.river_r8` 816, `LookDevReview.paths.river_r8` 78. Boot require `Main.server.luau` 130. | **2** — perf neutral, `BRIDGE_WALKABLE`/`WATER_CLEAR` PASS; depends on baked plant load but not on other promoted scene geometry. | Same: no `DefaultLook` module exists; item 226 `DefaultLook.PROMOTED` single flag. |
| `sawah_r8` | `CANDIDATES.md` row 61; `CANDIDATE_INDEX.md` row 60; `VOTE_ROUND10.html` (`init.sawah_r8 = "yes"`); `CHECK_178.txt`; `docs/v2/evidence/h/2026-11-22-round11/CHECK_191.txt` | `PERF_BUDGET PASS 338/500` and 7,056 baked padi MeshParts (`CHECK_191.txt`). Historical pre-bake census in `PERF_R9.md`: 39,472 instances / 30,194 parts / 408,020 prim tris, near100 334 (flagged heavy). Post-bake prim tris UNVERIFIED. fps UNVERIFIED. | Applier `src/server/World/LookDevSawahR8.luau` (`LookDev.register` line 570). Data `src/shared/ModelMapSawahR8.luau`, `TierThin`, `MapSpec.paddyWater()`; baked rice via `LookDevAssetLoader` / `ServerStorage.LookDevAssets.13286158859` (`CHECK_191.txt` §Setup). Registry: `LookDev.IDS` 159, `LookDev.candidates.sawah_r8` 806, `LookDevReview.paths.sawah_r8` 77. Boot require `Main.server.luau` 129. | **3** — near100 still under proxy, but largest part/MeshPart load; promote after `plots_r8`/`river_r8` so `SAWAH_TOPS`/`BUND_SHAPE` and perf deltas stay attributable. | Same: no `DefaultLook` module exists; item 226 `DefaultLook.PROMOTED` single flag. |
| `hubveg_r8` | `CANDIDATES.md` row 59; `CANDIDATE_INDEX.md` row 58; `VOTE_ROUND10.html` (`init.hubveg_r8 = "yes"`); `docs/v2/evidence/h/2026-11-21-round9/CHECK_144.txt` | `PERF_BUDGET FAIL 799/500` alone, `848/500` with `facades_r8` — FLAGGED (`CHECK_144.txt`). `PERF_R9.md`: 7,510 instances / 2,629 parts / 595 MeshParts / 73,688 prim tris. fps UNVERIFIED. | Applier `src/server/World/LookDevModelsVegetationHubR8.luau` (`LookDev.register` line 384). Data `src/shared/ModelMapVegetationHubR8.luau` (reuses verified R7 IDs), `LookDevAssetLoader`, `TierThin`, `MapSpec`; plot/path exclusion zones re-evaluated at apply time. Registry: `LookDev.IDS` 157, `LookDev.candidates.hubveg_r8` 787, `LookDevReview.paths.hubveg_r8` 75. Boot require `Main.server.luau` 127. | **4** — over proxy; exclusion zones depend on promoted plot geometry, so stage after `plots_r8`. Factor +facades cost before enabling together (`facades_r8` is `no`, not eligible). | Same: no `DefaultLook` module exists; item 226 `DefaultLook.PROMOTED` single flag. |
| `pasar_awnings_r8` | `CANDIDATES.md` row 76; `CANDIDATE_INDEX.md` row 72; `VOTE_ROUND10.html` (`init.pasar_awnings_r8 = "yes"`); `docs/v2/evidence/h/2026-11-21-round9/CHECK_148.txt`; `docs/v2/evidence/h/2026-11-22-round10/CHECK_179.txt` | `PERF_BUDGET FAIL 558/500` — FLAGGED (`CHECK_148.txt`). `PERF_R9.md`: 4,222 instances / 2,001 parts / 299 MeshParts / 69,944 prim tris. `CHECK_179.txt` fixes pads/stripe value, no new perf line; post-179 perf UNVERIFIED. fps UNVERIFIED. | Applier `src/server/World/LookDevPasarAwningsR8.luau` (`LookDev.register` line 479). Data `src/shared/ModelMapPasarAwningsR8.luau`, `LookDevFailures`, `MapSpec.hub("pasar")`; Ground voxel pad snapshot/LIFO restore. Registry: `LookDev.IDS` 171, `LookDev.candidates.pasar_awnings_r8` 935, `LookDevReview.paths.pasar_awnings_r8` 89. **Gap:** no `pcall(require, ...LookDevPasarAwningsR8)` in `Main.server.luau` (grep: only `LookDevReview`/harness references); item 226 must add the boot require or the applier will not register in a clean Play. | **5** — over proxy and writes Terrain voxels; needs the boot-require gap closed and pad restore reverified (`CHECK_148.txt` detail, `CHECK_179.txt`). | Same: no `DefaultLook` module exists; item 226 `DefaultLook.PROMOTED` single flag. |
| `buildings_r8` | `CANDIDATES.md` row 67; `CANDIDATE_INDEX.md` row 66; `docs/v2/evidence/h/2026-11-21-round9/CHECK_77.txt`; `docs/v2/evidence/h/2026-11-21-round9/CHECK_146.txt`; `docs/v2/visual/art/models_r8/buildings/README.md` | `PERF_BUDGET 1740/500` — OVER (`PERF_R9.md` §Server table and §Over-budget flags; `docs/v2/evidence/h/2026-11-21-round9/CHECK_097.txt`). `PERF_R9.md`: 8,100 instances / 3,472 parts / 350 MeshParts / 98,256 prim tris. fps UNVERIFIED. | Applier `src/server/World/LookDevBuildingsR8.luau` (`LookDev.register` line 768). Data `src/shared/ModelMapBuildingsR8.luau`, `LookDevAssetLoader` (baked clones; no direct `InsertService`), `LookDevFailures`, `MapSpec`; Ground pads + DoorGauge. Registry: `LookDev.IDS` 165, `LookDev.candidates.buildings_r8` 866, `LookDevReview.paths.buildings_r8` 83. Boot require `Main.server.luau` 146. Placement/hub match still a proposal (`docs/v2/visual/art/BUILDING_KIT.md`); `hubs_real_r9` is pending, not promoted. | **6** — highest cost and placement unresolved; the 2026-11-21 yes is for the staged lot, not final hub placement. Re-measure with the other five enabled before shipping; keep last. | Same: no `DefaultLook` module exists; item 226 `DefaultLook.PROMOTED` single flag. |

## Rollback mechanism (honest state)

- No `DefaultLook` module, no `DefaultLook.PROMOTED` constant, and no startup flag exists in `src/`
  (grep for `DefaultLook|PROMOTED` in `src/`: 0 matches).
- Existing shipping defaults are applied directly without a LookDev enable call:
  `src/server/World/ShippingLookR7.luau` (`spawn_ground_r6`, sky `sky_r6_e`) and
  `src/client/World/Water.luau` (`water_r8_a`, item 137).
- Existing review rollback is `LookDev.disable()` / `LookDev.disableAll()`
  (`src/shared/LookDev.luau` lines 2132, 2187): Studio-only, never persisted, refused on a published
  server. It is not a shipping-default switch.
- Item 226 proposal (not implemented here): add one `DefaultLook.PROMOTED` constant listing only the
  six ids above, apply via the existing appliers, and make empty/false equal today's default. Single
  constant toggles the whole set. Checks per item 226: `PROMOTE_ONLY_YES`, `PROMOTE_OFF`,
  `PERF_BUDGET` within Sedang, `WALKABLE`, `GATE_CLEAR`, clean-Play smoke.

## What is blocked

- Sprint-5 look failures — items **257, 258, 260, 261, 262, 263, 268, 270, 271, 272** — are
  `BLOCKED` on look in `docs/v2/plan/MASTER_PLAN.md` progress tracker and evidence under
  `docs/v2/evidence/h/2026-11-23-sprint5/`. Numeric PASS does not override a look failure.
  Do not promote any of them, even if a provisional call in `PROVISIONAL_VERDICTS.md` later says yes.
- Only rows whose verdict cell starts `**yes` in `CANDIDATES.md` / `CANDIDATE_INDEX.md` are eligible.
  `pending`, `no`, `tunda`, and provisional-only calls stay behind `LookDev`.

## Evidence paths used

- `docs/v2/visual/CANDIDATES.md`; `docs/v2/visual/CANDIDATE_INDEX.md`;
  `docs/v2/visual/PROVISIONAL_VERDICTS.md`; `docs/v2/visual/PERF_R9.md`;
  `docs/v2/plan/DECISIONS.md`; `docs/v2/plan/WORK_QUEUE.md` items 224/226;
  `docs/v2/plan/MASTER_PLAN.md` progress tracker.
- Verdicts: `docs/v2/evidence/h/2026-11-22-review-round10/VOTE_ROUND10.html`;
  `docs/v2/evidence/h/2026-11-21-review-round9/STUDIO_REVIEW.md`;
  `docs/v2/visual/art/models_r8/buildings/README.md`;
  `docs/v2/visual/art/BUILDING_KIT.md`.
- Perf/checks: `docs/v2/evidence/h/2026-11-21-round9/CHECK_097.txt`,
  `CHECK_141.txt`, `CHECK_143.txt`, `CHECK_144.txt`, `CHECK_146.txt`, `CHECK_148.txt`,
  `CHECK_77.txt`; `docs/v2/evidence/h/2026-11-22-round10/CHECK_174.txt`,
  `CHECK_178.txt`, `CHECK_179.txt`, `CHECK_181.txt`;
  `docs/v2/evidence/h/2026-11-22-round11/CHECK_191.txt`, `CHECK_192.txt`,
  `CHECK_197.txt`; `docs/v2/evidence/h/2026-11-21-round10/SHOT_LIST.md`.
- Wiring: `src/shared/LookDev.luau`, `src/shared/LookDevReview.luau`,
  `src/server/Main.server.luau`, `src/server/World/ShippingLookR7.luau`,
  `src/client/World/Water.luau`, and the six applier/data modules named in the table.
