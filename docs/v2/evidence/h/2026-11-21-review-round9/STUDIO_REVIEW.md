# Round-9 Studio review (main session, 2026-11-21)

Studio Play on commit a683207, ClockTime 13, Clouds.Cover 0.55. Each candidate was enabled alone (the review helper keeps one active). Sheet: `REVIEW_ROUND9_STUDIO.html`, shots in `shots/`. Status: SEEN-IN-STUDIO.

| Candidate | Finding |
|---|---|
| hubveg_r8 | Works: bamboo, flowering shrubs and pot plants at the hubs. Still sparse. |
| facades_r8 | Shutters, awning, eaves read well. BUG: a long yellow diagonal pole floats above the Pak RT roof. |
| buildings_r8 | Best result: real joglo, two-storey house and others. Staged on top of the village, so it needs placement if adopted. |
| sawah_r8 | Passes the counts, but the verge tufts read as long green bars, and padi and gubuk are not visible. |
| river_r8 | Bridge rails and stepping stones fine. Bank plants are thin green posts, not talas or bamboo. |
| pathedge_r8 | Green cubes sit in the middle of the dark road, not at its edge. |
| plots_r8 | Fences barely visible; the saved gate camera sits among pines. |
| water_r8_a/b/c | Three distinct looks: clear green-teal, murky brown, bright cyan. |

## Other findings

- The default pine backdrop dominates many cameras (queue item 102).
- `workspace` holds two stray objects after Play: `GiantyFrog` (a 316-descendant Model at about 52, 4, -162, inside the map) and `BambooBasket` (ProceduralModel at 484, 6.6, 516). They look like leftovers from `generate_procedural_model` runs. Not from the game code.
- Checks pass on counts, but several candidates fail a visual read. Counts alone were not enough, as in rounds 5 to 7.
