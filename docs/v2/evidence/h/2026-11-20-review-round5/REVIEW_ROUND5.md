# Round-5 candidates: review handoff (2026-11-20, main session)

Work-queue item 42 handoff. It lists the round-5 candidates, their exact one-call toggles, the
datamodel each toggle must run in, and the saved review camera for each. `REVIEW_ROUND5.html` is the
designer review sheet. **Every verdict cell is blank**; no agent grades these visuals.

## Method and controls

- Studio: `Development-Juragan-Desa` (placeId `132087524375529`), Rojo-synced, **Play** mode with
  `Client` and `Server` data models. Nothing was saved or published; Play was left running for the
  verification sweep and no `JuraganDesa.rbxl` was written.
- The running Studio was first found on stale code (25 candidates, no `_r5`). The source in the Edit
  datamodel was current (`LookDev` module contained `spawn_r5`), but its `require` cache was stale.
  Stopping Play and starting it again produced a fresh VM: both Client and Server reported
  `idCount = 31` with `spawn_r5`, `npcs_r5`, `props_r5` and `sky_r5` all present.
- Toggles are the one-call helper with `game` as root and **dot syntax** (colon syntax is a known
  bug and is not used):
  - enable: `require(game.ReplicatedStorage.Shared.LookDevReview).enable("<id>", game)`
  - restore: `require(game.ReplicatedStorage.Shared.LookDevReview).disable()`
- Datamodels follow `LookDevReview.paths` in `src/shared/LookDevReview.luau`: `textures_r4` and
  `sky_r5` are **client** appliers (Terrain colour / skybox changes); all model, dressing and ground
  candidates are **server** appliers because client `InsertService:LoadAsset` is blocked.

## Factual verification performed (no visual grade)

**Enable sweep — every candidate enables and builds its content folder.** Each row was enabled with
the helper, the resulting LookDev folder counted, then disabled. Counts are `GetDescendants()` in the
live Play VM; they prove the applier ran, not that the art looks good.

| Candidate | Datamodel | `ok` | Folder created | Descendants |
|---|---|---|---|---|
| `textures_r4` | Client | true | (Terrain/base-material override; no instance folder) | n/a |
| `sky_r5` | Client | true | (Terrain `Clouds` / `Skybox` override; no instance folder) | n/a |
| `buildings_r4` | Server | true | `LookDevModelsBuildingsR4_buildings_r4` | 123 |
| `vegetation_r5` | Server | true | `LookDevVegetationR5` | 104 |
| `props_r5` | Server | true | `LookDevModelsPropsR5_props_r5` | 46 |
| `npcs_r5` | Server | true | `LookDevModelsNpcsR5_npcs_r5` | 1405 |
| `spawn_r5` | Server | true | `LookDevSpawnDressingR5_spawn_r5` | 1529 |
| `spawn_ground_r5` | Server | true | `LookDevSpawnGroundR5` | 116 |

`LookDev.current()` reported the enabled id for each row, and `disable()` restored the prior state.

**Camera sightline check — each saved camera was queried in the live Play VM.** Two independent
checks were run for every camera: a `Workspace:Raycast` from the camera position toward the
`look_at` point, and a scan of all vegetation-named objects within 12 studs of that sightline
segment. Result: no obstructing geometry on the centre line of any camera. The one exception is the
`props_r5` saved camera, which has two pine objects (`Pine_42_1`, `Pine Tree `) at ~11.3 studs off
the sightline — consistent with the round-4 finding that this camera is partially screened by pines
and tall grass. The `sky_r5` camera has three `FloraGrass` objects ~10.2–10.4 studs off-axis, but it
looks upward (`y 9 → y 16`) so low grass does not block the sky. See the per-row sightline note in
the table below.

**Screenshot pixels could not be retained in this session.** `screen_capture` returned `null` with
image content stripped in this runtime; the same limitation is recorded for round 4 in
`h/2026-11-20-review-round4/REPORT.md`. A `video_capture` probe produced a decodable frame, but a
vision probe of that frame reported only the gameplay HUD over a flat near-black world — no 3D
geometry — and the game's camera script overrides a `Scriptable` camera set from `execute_luau`, so
that frame was not from a saved review camera. No screenshot is attached to this handoff and **no
visual claim is made from it**. Filling the verdicts belongs to the designer or a vision-capable
review pass with retained screenshots.

## Review-order table

Enable one row from the correct datamodel, capture from the saved camera, call `.disable()`, then
move on. Cameras are absolute world coordinates from the candidates' source modules / the round-4
handoff. Paste into Studio `screen_capture` as `camera_position` / `look_at_position`.

| # | Candidate | Datamodel / enable | `camera_position` | `look_at_position` | Sightline note | Verdict |
|---|---|---|---|---|---|---|
| 1 | `textures_r4` (darkening fixed) | Client · `enable("textures_r4", game)` | `{ 0, 12, 52 }` | `{ 0, 3, -20 }` | centre line clear |  |
| 2 | `sky_r5` | Client · `enable("sky_r5", game)` | `{ -14, 9, 42 }` | `{ -14, 16, -12 }` | clear; 3 grass stalks ~10 studs off-axis, camera looks up |  |
| 3 | `buildings_r4` (temporary yes) | Server · `enable("buildings_r4", game)` | `{ 0, 22, 84 }` | `{ 0, 7, 20 }` | centre line clear |  |
| 4 | `vegetation_r5` | Server · `enable("vegetation_r5", game)` | `{ 0, 20, 150 }` | `{ 0, 8, 96 }` | centre line clear; camera frames z≈96 (mangga stand-ins at z=108), main pisang/bambu clusters sit at z=34–63 and need a closer wide shot |  |
| 5 | `props_r5` | Server · `enable("props_r5", game)` | `{ 142, 9, 146 }` | `{ 142, 3, 122 }` | **partially screened by pines** (~11.3 studs off-axis) — same caveat as round 4 |  |
| 6 | `npcs_r5` | Server · `enable("npcs_r5", game)` | `{ 0, 7, 28 }` | `{ 0, 2.5, 8 }` | centre line clear; ray hits an R15 rig at ~19.9 studs (subject in frame) |  |
| 7 | `spawn_r5` | Server · `enable("spawn_r5", game)` | `{ 0, 20, 72 }` | `{ 0, 5, 14 }` | centre line clear |  |
| 8 | `spawn_ground_r5` | Server · `enable("spawn_ground_r5", game)` | `{ 0, 20, 72 }` | `{ 0, 5, 14 }` | shares the spawn-wide camera; centre line clear |  |

Camera sources: `textures_r4` and `sky_r5` (round-4 handoff `REVIEW_ROUND4.md`, reused staging);
`buildings_r4` (`ModelMapBuildingsR4.camera`); `vegetation_r5` (round-4 vegetation camera, R5 reuses
the R4 slots); `props_r5` (`ModelMapPropsR4.camera`); `npcs_r5` (`ModelMapNpcsR5.families.npcs_r5.camera`);
`spawn_r5` (`SpawnDressingMapR5.camera`); `spawn_ground_r5` (shared spawn-wide camera). `vegetation_r5`
has no dedicated saved camera in its data; the round-4 camera is the closest documented one and its
framing limit is stated above rather than papered over.

## Designer feedback carried into round 5 (from `h/2026-11-20-review-round4/STUDIO_REVIEW.md`)

- `textures_r4`: "no" until the darkening is fixed → round 5 neutralises Terrain material colours
  while the override is live and restores them exactly on disable.
- `sky_r4_a`: best after the slab, cloud and seam fixes → `sky_r5` lowers `Clouds.Cover` to 0.4,
  builds no ridge slabs and fixes the top-face seam.
- `buildings_r4`: temporary yes; `vegetation_r4`: yes (bamboo too thin, pisang good); `props_r4`:
  no except `jemuran`; `npcs_r4`: no → round 5 keeps jemuran, thickens bamboo, right-sizes props and
  replaces the lying R4 dummy models with upright R15 rigs.

## Status

- All eight candidates remain **off by default**. No verdict is recorded here or in
  `REVIEW_ROUND5.html`; no visual grade is made from code, file contents or the failed capture.
- No place was saved or published, no asset ID / product ID / UserId was created, and
  `ROBLOX_API_KEY` was neither printed nor used here.
- Factual Studio enable/sightline results above are `SEEN-IN-STUDIO`/Lune-verifiable facts; any
  visual claim remains `UNVERIFIED` until a retained-screenshot or designer pass supplies it.
