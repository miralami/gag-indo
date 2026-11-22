# Round-4 candidate review — observer descriptions (2026-11-20)

Work-queue item 33 (review handoff) evidence. Eight round-4 LookDev candidates were enabled one at a
time in a live Play session and described by the Studio `screen_capture` vision observer from the
saved absolute cameras in `docs/v2/visual/REVIEW_ROUND4.md`. The scriptable session cannot retain
screenshot pixels (`screen_capture` returned `null` in the Code Mode runtime / image content is
stripped), so this evidence set is **observer descriptions, not screenshots**. The user chose this
review form on 2026-11-20.

`REVIEW_ROUND4.html` is the handoff sheet: per candidate it records the id, the exact dot-syntax
toggle, the datamodel, the camera, the observer's factual report and a **blank** verdict cell.

## Method and controls

- Studio: `Development-Juragan-Desa` (placeId `132087524375529`), Rojo-synced, **Play** mode with
  `Client` and `Server` data models available. Nothing was saved or published; Play mode is stopped
  after this report.
- Fresh Play VMs confirmed the r4 registry is live: Client and Server both reported `idCount=25`,
  `hasSkyR4a=true`, `hasTexturesR4=true`, `hasNpcsR4=true`. (Edit-mode `require` is stale and was
  not used for verification.)
- One-call toggles used the helper, with `game` as root:
  `require(game.ReplicatedStorage.Shared.LookDevReview).enable("<id>", game)` then
  `require(...LookDevReview).disable()` (dot syntax; colon syntax fails).
- `textures_r4`, `sky_r4_a`, `sky_r4_b`, `sky_r4_c` were enabled in the **Client** datamodel;
  `buildings_r4`, `vegetation_r4`, `props_r4`, `npcs_r4` in the **Server** datamodel, because
  client `InsertService:LoadAsset` is blocked.
- After the last capture the helper was disabled and `LookDev.current()` confirmed `nil` on Server.

## What the observer was asked (and not asked) to do

Each observer task: set the named camera, capture one shot, and report **only factual visual
observations** (materials, sky, silhouettes, terrain, props, UI text). It was explicitly told not to
give a yes/no verdict, not to judge quality, not to compare candidates, not to recommend anything,
and not to change game state or save/publish. This is why the sheet contains observations only.

## Capture order, cameras and observations

Order and cameras are verbatim from `REVIEW_ROUND4.md`. Full observation text is in
`REVIEW_ROUND4.html`; a short digest follows.

| # | Candidate | Datamodel | Camera → look_at | Observation digest (factual only) | Verdict |
|---|---|---|---|---|---|
| 1 | `textures_r4` | Client | `{0,12,52}` → `{0,3,-20}` | Brown dirt path and green grass, dark soil edges, wooden plank; blue/grey and red sloped roofs, "Pasar"/"Toko" labels; conifer line and distant hills; overcast grey sky. | blank |
| 2 | `sky_r4_a` | Client | `{-14,9,42}` → `{-14,16,-12}` | Village scene under overcast/cloudy sky; tall black panels; green-roof tower; blue/red roofs; white-haired character. | blank |
| 3 | `sky_r4_b` | Client | `{-6,7,40}` → `{-14,14,-12}` | Uniform overcast grey, no sun or blue; "POS RONDA" and "WARUNG" signs; green and red roofs; round green objects. | blank |
| 4 | `sky_r4_c` | Client | `{-22,8,40}` → `{-14,15,-12}` | Overcast grey-white with no gradient or sun; black panels; tree/building horizon; tilled soil; green melon-like object. | blank |
| 5 | `buildings_r4` | Server | `{0,22,84}` → `{0,7,20}` | Blue building, stilted grey/white building, blue/brown structure, black pillars, small green and tan red-roof buildings, green-roof tower; fences/crates/tables/benches. | blank |
| 6 | `vegetation_r4` | Server | `{0,20,150}` → `{0,8,96}` | Curved-trunk palm, banana plant with yellow fruit, round green trees/bushes, grey bamboo-like stalks, grey rock formation; grass and grass tufts. | blank |
| 7 | `props_r4` | Server | `{142,9,146}` → `{142,3,122}` | Clothesline with hanging garments, grey rectangular block, red triangular marker, red-roof building, conifers, brown rock, "LAHAN KOSONG" text. | blank |
| 8 | `npcs_r4` | Server | `{0,7,28}` → `{0,2.5,8}` | Three humanoid figures (yellow-hatted with pitchfork, orange with green backpack, solid yellow) plus a grey/white blocky object; ~2–3 studs tall. | blank |

## Notes on the run

- A few `screen_capture` observer calls returned `max_tool_calls` on the first attempt; each was
  retried successfully before its observation was recorded. Two bundles (`textures_r4` +
  `sky_r4_c`, and the first Server enable) were therefore issued individually.
- The console showed transient content warnings during model captures, e.g. HTTP 502 on some
  `rbxassetid://…` textures and "Asset content representation is being generated", plus a
  `SurfaceAppearance` texture-unavailable warning for one `props_r4` sack (`karung`). These are
  delivery/loading warnings for uploaded texture IDs, not a change to the recorded property values;
  the observer still described the staged props. No error was edited away and no visual claim is
  made from them.
- `mangga` in `vegetation_r4` is a Balsa-tree stand-in, not a verified mango tree; the `npcs_r4`
  models are anchored review dummies with no R15 rig. Both are noted in `REVIEW_ROUND4.md`.

## Status

- This handoff makes **no screenshot claim** and records **no visual grade**. All verdict cells in
  `REVIEW_ROUND4.html`, `REVIEW_ROUND4.md` and `docs/v2/visual/CANDIDATES.md` are blank.
- All eight candidates remain **off by default**. No place was saved or published, no asset ID,
  product ID or UserId was created here, and `ROBLOX_API_KEY` was neither printed nor used here.
- Filling the yes/no verdicts belongs to the designer or a vision-capable review pass with retained
  screenshots; no agent grades these visuals.
