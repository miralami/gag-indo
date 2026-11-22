# Round-6 Studio review (main session, 2026-11-20)

Studio Play on Rojo-synced code (commit a1207df). All twelve candidates enabled through
`LookDevReview` with dot syntax, one at a time, and disabled afterwards. The camera was forced by a
client RenderStep binding. The HUD was hidden. ClockTime was pinned to 13:00 for the ground and
model shots. Nothing was saved or published. Shots are in `shots/`; the visual sheet is
`REVIEW_ROUND6_STUDIO.html`. Verdicts belong to the designer and are recorded in `CANDIDATES.md`
once given.

## Factual findings (SEEN-IN-STUDIO)

| Candidate | Finding |
|---|---|
| `sky_r6_a`..`f` | All six enable and swap the Sky faces (for example `sky_r6_a` Ft = 150335628). No cube seams are visible. `sky_r5` shows a seam at the top left. |
| `terrain_r6_a` / `terrain_r6_b` | Terrain colours change as intended. **Bug:** the wooden walls of the pasar, warung and pos ronda also turn almost black while the candidate is on. |
| `spawn_ground_r6` | The back road strip between the pasar and warung is now dirt. Tall grass still covers the flower beds in the foreground. |
| `vegetation_r6` | It enables (121 descendants). Bambu, pisang and round shrubs are visible from the saved camera, but the scene is still sparse. |
| `npcs_r6` | All five villagers face the camera, each with a textured Shirt/Pants Image. **Bug persists:** every villager has 0 Accessory children, so there is no caping, peci or cap. |
| `props_r6` | Bounding boxes: gerobak 6.5×6.0×4.8, sumur 4.5 tall, cangkul 4.5 tall. **Staging bug:** the props stand inside the pine stand at x 130–154, z 116–128, buried in tall grass. Only the jemuran is visible from the saved camera or a higher one. The karung stack is staged separately at (22, 26). |
