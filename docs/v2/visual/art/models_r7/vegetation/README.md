# `vegetation_r7` — review render placeholder

WORK_QUEUE section K item 58. This is the render/screenshot path referenced from
`docs/v2/visual/CANDIDATES.md`. It is intentionally a placeholder: the main session captures the
review shots in a real Studio Play session and saves them into this folder during the item 59
handoff. No agent grades these visuals — that is the designer's decision.

## Candidate

- **ID:** `vegetation_r7` (server-only, OFF by default)
- **Data:** `src/shared/ModelMapVegetationR7.luau` — 88 pure-data slots across 11 species taken from
  `KAMPUNG_VEGETATION.md`, using only real Create Store IDs already present in R4/R6 maps. The real
  Studio check measured 67 in-cone instances / 10 species (`CHECK_58.txt`).
- **Applier:** `src/server/World/LookDevModelsVegetationR7.luau` — clone-first from
  `ServerStorage.LookDevAssets`, loud failure counter under `vegetation_r7`.
- **Composition:** continuous teh-tehan hedge (one instance / 2 studs), 3+ bambu clumps of 5–7
  culms, 6+ pisang, kembang sepatu and puring by houses, talas and keladi on ditches, lidah mertua
  in pots, alang-alang on the sawah verge.
- **Placement rules:** random yaw, ±15% scale jitter, min pair distance 2.0 studs, exclusion zones
  respected, inside the Sedang tier budget.
- **Fixed review camera:** eye `{0, 20, 150}`, look `{0, 8, 96}`; 100-stud radius, 70° cone.
- **Objective checks:** `VEG_COUNT` ≥ 60, `VEG_SPECIES` ≥ 8, `LOAD_FAILURES` = 0 (see
  `docs/v2/evidence/h/2026-11-20-round7/CHECK_*.txt`).

## Shots

Populated by the main session from the real Play session; none recorded at authoring time.
No visual verdict is made here.
