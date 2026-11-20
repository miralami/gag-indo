# Round-4 candidates: real Studio shots (2026-11-20, main session)

The shots in `shots/` come from a Studio Play session on synced code. They were taken from the saved
review cameras with a scriptable client camera, and every candidate was enabled through `LookDevReview.enable`.
Nothing was saved or published, and Play was stopped afterwards.

`REVIEW_ROUND4_STUDIO.html` is the review sheet and supersedes the description-only `REVIEW_ROUND4.html`.
Verdicts belong to the designer; the suggestions below are only proposals.

## Findings (bugs)

1. **`textures_r4` darkens the ground almost to black** (`02`, `03`). The Laterite/Ground override,
   probably multiplied by Terrain `MaterialColors`, turns paths and plots maroon-black, and buildings
   also get darker.
2. **The `sky_r4_*` ridge silhouette is a set of giant black slabs in the middle of the spawn plaza** (`04`–`07`).
   The ridge parts sit in the village instead of at the horizon.
3. **Terrain `Clouds` (Cover = 1) hide every r4 skybox** (`04`). The sky only shows with clouds disabled,
   so the candidate has to lower the Cover or turn the clouds off.
4. **Cube seams in the sky** (`05`, `06`): there is a visible edge where the top face meets the side faces.
5. **The `props_r4` saved camera sees only pines and tall grass** (`11`). The props are hidden.
   They were moved into the plaza temporarily for `12`.
6. **`props_r4` `karung` is a cement bag** with "CEMENT" printed on it, not a rice sack. The gerobak, sumur, lapak and
   alat tani are small and hard to read.
7. **`npcs_r4` orientation**: two models lie on their side again, and one is a flat yellow untextured figure (`13`).
8. **V-D4 (no pines)**: the baseline map still has many pine trees around spawn (`01`).

## Suggestions

| Candidate | Suggestion |
|---|---|
| `textures_r4` | no, until the darkening is fixed |
| `sky_r4_a` | best of three (clear blue), after the slab, cloud and seam fixes |
| `sky_r4_b` | backup |
| `sky_r4_c` | no (flat overcast) |
| `buildings_r4` | yes for now: textured and the right scale, but Western in style |
| `vegetation_r4` | yes: palm and banana are good, the bamboo is too thin |
| `props_r4` | no, except `jemuran` |
| `npcs_r4` | no |
