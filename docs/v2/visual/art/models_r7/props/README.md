# `props_r7` — review render placeholder

WORK_QUEUE section K item 57. This is the render/screenshot path referenced from
`docs/v2/visual/CANDIDATES.md`. It is intentionally a placeholder: the main session captures the
review shots in a real Studio Play session and saves them into this folder during the item 59
handoff. No agent grades these visuals — that is the designer's decision.

## Candidate

- **ID:** `props_r7` (server-only, OFF by default)
- **Data:** `src/shared/ModelMapPropsR7.luau` — six slots in order gerobak, sumur, lapak, pagar_bambu,
  alat_tani, jemuran, 6 studs apart, real sizes carried over from round 6 (gerobak 6 tall, sumur
  4.5, alat_tani 4.5). IDs derive from `ModelMapPropsR6` → `ModelMapPropsR4`.
- **Applier:** `src/server/World/LookDevModelsPropsR7.luau` — clone-first from
  `ServerStorage.LookDevAssets`, loud failure counter under `props_r7`.
- **Placement:** scans `workspace` for tree/pine models and picks the nearest clear 40×40-stud yard
  (15-stud trunk margin) to the spawn area; paints a `Ground` voxel pad under each prop (footprint
  + 2 studs).
- **Camera:** folder attributes `ReviewCameraPos` / `ReviewLookAt` = row centre +28 Z / +7 Y, looking
  at the row centre at y=2. Published by `LookDevModelsPropsR7.camera()`. `front` was 18 on attempt 1,
  which put the two row ends outside the 70° cone (`PROPS_VISIBLE FAIL 4 6`); 28 keeps all six inside
  with ~7° margin while the eye stays clear of the trunks.
- **Objective checks:** `PROPS_VISIBLE` = 6/6, `PROPS_ON_GRASS` = 0 (see
  `docs/v2/evidence/h/2026-11-20-round7/CHECK_*.txt`).

## Shots

Populated by the main session from the real Play session; none recorded at authoring time.
No visual verdict is made here.
