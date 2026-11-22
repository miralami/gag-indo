# Round-6 candidates: review handoff (2026-11-20, main session)

Work-queue item 51 handoff. It lists every round-6 LookDev candidate, its exact one-call toggle,
the datamodel each toggle must run in, and the saved review camera for each. **Every verdict cell
is blank**; no agent grades these visuals. Round-5 verdicts are unchanged and are not restated
here.

## Method and controls

- Toggles are the one-call `LookDevReview` helper with `game` as root and **dot syntax** (colon
  syntax is a known bug and is never used). One line per candidate, then disable before the next:
  - enable: `require(game.ReplicatedStorage.Shared.LookDevReview).enable("<id>", game)`
  - restore: `require(game.ReplicatedStorage.Shared.LookDevReview).disable()`
- The helper prepares the applier in the same VM before toggling, which avoids the stale-`require`
  empty-registry bug. IDs are the exact `Shared.LookDev.IDS` entries; every candidate is
  **off by default**.
- Datamodels follow `LookDevReview.paths` in `src/shared/LookDevReview.luau`: the six `sky_r6_*`
  skyboxes and the two `terrain_r6_*` palettes are **client** appliers (Visual Effects / Terrain
  colour changes); `spawn_ground_r6`, `vegetation_r6`, `npcs_r6` and `props_r6` are **server**
  appliers because client `InsertService:LoadAsset` is blocked.
- Studio shots are the main session's job. Nothing here was saved or published and no
  `JuraganDesa.rbxl` was written.

## Review-order table

Enable one row from the datamodel shown, capture from the saved camera, call `.disable()`, then
move on. Camera coordinates are absolute world positions from each candidate's source module;
paste them into `screen_capture` as `camera_position` / `look_at_position`.

| # | Candidate | Datamodel / enable | `camera_position` | `look_at_position` | Verdict |
|---|---|---|---|---|---|
| 1 | `sky_r6_a` | Client · `enable("sky_r6_a", game)` | `{ -14, 9, 42 }` | `{ -14, 28.6, -12 }` |  |
| 2 | `sky_r6_b` | Client · `enable("sky_r6_b", game)` | `{ -14, 9, 42 }` | `{ -14, 28.6, -12 }` |  |
| 3 | `sky_r6_c` | Client · `enable("sky_r6_c", game)` | `{ -14, 9, 42 }` | `{ -14, 28.6, -12 }` |  |
| 4 | `sky_r6_d` | Client · `enable("sky_r6_d", game)` | `{ -14, 9, 42 }` | `{ -14, 28.6, -12 }` |  |
| 5 | `sky_r6_e` | Client · `enable("sky_r6_e", game)` | `{ -14, 9, 42 }` | `{ -14, 28.6, -12 }` |  |
| 6 | `sky_r6_f` | Client · `enable("sky_r6_f", game)` | `{ -14, 9, 42 }` | `{ -14, 28.6, -12 }` |  |
| 7 | `terrain_r6_a` | Client · `enable("terrain_r6_a", game)` | `{ 0, 20, 72 }` | `{ 0, 5, 14 }` |  |
| 8 | `terrain_r6_b` | Client · `enable("terrain_r6_b", game)` | `{ 0, 20, 72 }` | `{ 0, 5, 14 }` |  |
| 9 | `spawn_ground_r6` | Server · `enable("spawn_ground_r6", game)` | `{ 0, 20, 72 }` | `{ 0, 5, 14 }` |  |
| 10 | `vegetation_r6` | Server · `enable("vegetation_r6", game)` | `{ 0, 20, 150 }` | `{ 0, 8, 96 }` |  |
| 11 | `npcs_r6` | Server · `enable("npcs_r6", game)` | `{ 0, 7, 28 }` | `{ 0, 2.5, 8 }` |  |
| 12 | `props_r6` | Server · `enable("props_r6", game)` | `{ 154, 10, 140 }` | `{ 142, 3, 122 }` |  |

Camera sources: `sky_r6_*` (`src/shared/SkyMapR6.luau`, one shared saved sky camera);
`terrain_r6_*` and `spawn_ground_r6` (shared spawn-wide review camera); `vegetation_r6`
(`src/shared/ModelMapVegetationR6.luau`, the R4 vegetation row camera); `npcs_r6`
(`src/shared/ModelMapNpcsR6.luau`, unchanged from R5); `props_r6` (`src/shared/ModelMapPropsR6.luau`,
moved +12 in X clear of the pine row). The six sky candidates share one camera because they are
the same scene with a different skybox; the two terrain palettes and the ground fix share the
spawn-wide camera so the ground reads under comparable framing.

## Notes for the reviewer

- `sky_r6_a`..`sky_r6_f` are six real free Creator Store skyboxes (face IDs and provenance in
  `h/2026-11-20-sky-r6-asset-load/REPORT.md`). Compare them against the unchanged `sky_r5`
  baseline; `sky_r5` was not modified this round.
- `terrain_r6_a`/`b` tune built-in Terrain colours only (no Terrain-wide texture override); CC0
  maps stay on parts and meshes. `spawn_ground_r6` lays tanah over the full road corridor and masks
  grass off beds and plots. Enable one at a time — they touch overlapping ground geometry.
- `vegetation_r6` stages its densest clusters in the camera band around z≈88–104; the R4 pisang
  and dense-bambu clusters farther back need a closer wide shot if the reviewer wants them.
- `npcs_r6` flips all five villagers ~180° to face the camera (the R5 review saw their backs) and
  applies per-role textured Shirt/Pants; hats use a multi-strategy attacher. `pak_rt` has no peci
  (a designer build) and stays batik-only.
- `props_r6` right-sizes the gerobak (6 tall, ~8 long), sumur (4.5) and cangkul (4.5) with
  `Model:ScaleTo`; its camera was moved out from behind the pines.

## Status

- All twelve candidates remain **off by default**. No verdict is recorded here; no visual grade is
  made from code, file contents or source provenance. Filling the verdicts belongs to the designer
  or a vision-capable review pass with retained screenshots.
- No place was saved or published, no `JuraganDesa.rbxl` was written, and
  `ROBLOX_API_KEY` was neither printed nor used here.
- Any factual enable / sightline results from a Studio pass would be `SEEN-IN-STUDIO`; every visual
  claim stays `UNVERIFIED` until a retained-screenshot or designer pass supplies it.
