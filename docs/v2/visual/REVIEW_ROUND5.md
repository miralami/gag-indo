# Round-5 review handoff (2026-11-20)

This is the round-5 counterpart to `REVIEW_ROUND4.md`: the candidates, their exact one-call toggles,
the datamodel each runs in, and the saved review camera, in review order. Method, the live Studio
enable sweep and the camera sightline checks are in
`docs/v2/evidence/h/2026-11-20-review-round5/REVIEW_ROUND5.md`; the designer sheet is
`REVIEW_ROUND5.html` in that folder. **Every verdict cell is blank; no agent grades these visuals.**

## How to review

- Synced code with the r5 IDs registered (`LookDev.IDS` = 31). Enable one row, capture from the saved
  camera, call `.disable()`, then move on.
- One-call helper, **dot syntax** (colon syntax is a known bug):
  - enable `require(game.ReplicatedStorage.Shared.LookDevReview).enable("<id>", game)`
  - restore `require(game.ReplicatedStorage.Shared.LookDevReview).disable()`
- Run client rows (`textures_r4`, `sky_r5`) in the Client datamodel and server rows in the Server
  datamodel. Paste the camera columns into Studio `screen_capture` as `camera_position` /
  `look_at_position`. Do not invent a camera.
- Record yes/no in `CANDIDATES.md` and evidence under `docs/v2/evidence/`.

## Review-order table

| # | Candidate | Datamodel | Toggle | `camera_position` | `look_at_position` | Verdict |
|---|---|---|---|---|---|---|
| 1 | `textures_r4` (darkening fixed) | Client | `enable("textures_r4", game)` | `{ 0, 12, 52 }` | `{ 0, 3, -20 }` |  |
| 2 | `sky_r5` | Client | `enable("sky_r5", game)` | `{ -14, 9, 42 }` | `{ -14, 16, -12 }` |  |
| 3 | `buildings_r4` (temporary yes) | Server | `enable("buildings_r4", game)` | `{ 0, 22, 84 }` | `{ 0, 7, 20 }` |  |
| 4 | `vegetation_r5` | Server | `enable("vegetation_r5", game)` | `{ 0, 20, 150 }` | `{ 0, 8, 96 }` |  |
| 5 | `props_r5` | Server | `enable("props_r5", game)` | `{ 142, 9, 146 }` | `{ 142, 3, 122 }` |  |
| 6 | `npcs_r5` | Server | `enable("npcs_r5", game)` | `{ 0, 7, 28 }` | `{ 0, 2.5, 8 }` |  |
| 7 | `spawn_r5` | Server | `enable("spawn_r5", game)` | `{ 0, 20, 72 }` | `{ 0, 5, 14 }` |  |
| 8 | `spawn_ground_r5` | Server | `enable("spawn_ground_r5", game)` | `{ 0, 20, 72 }` | `{ 0, 5, 14 }` |  |

Camera sources: round-4 handoff (`textures_r4`, `sky_r5`, `vegetation_r5`), `ModelMapBuildingsR4.camera`,
`ModelMapPropsR4.camera`, `ModelMapNpcsR5.families.npcs_r5.camera`, `SpawnDressingMapR5.camera`.
`vegetation_r5` has no dedicated saved camera; the round-4 one is reused and its framing limit is
noted in the evidence handoff. The `props_r5` camera is partially screened by pines (round-4 caveat).

## Note on screenshots

This handoff makes **no screenshot claim**. Studio `screen_capture` returned no retained pixels in this
session, so pixel-based visual verification was not possible; the designer or a vision-capable pass with
retained screenshots supplies the verdicts. All eight candidates stay off by default.
