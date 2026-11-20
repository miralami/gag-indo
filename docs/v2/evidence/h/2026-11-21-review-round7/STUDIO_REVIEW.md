# Round-7 Studio review (main session, 2026-11-21)

This review ran in Studio Play on commit 46b4758.

## Session setup

- **Asset bake:** the Edit-mode bake was re-run. It reported `baked=0 skipped=31 failures=0`, because all 31 `ServerStorage.LookDevAssets` folders were already present when Studio reopened. Shots are in `shots/`; the visual sheet is `REVIEW_ROUND7_STUDIO.html`.
- **Staging:** I followed the enable sequence in `REVIEW_ROUND7.md`.
  - `LookDevFailures`: vegetation 0, npcs 0, props 0.
  - Accessories: petani 1, petani_wanita 1, pak_rt 1, polisi 1, pedagang 0.

## Findings (SEEN-IN-STUDIO)

| Area | Finding |
|---|---|
| Default sky | `Lighting.GoldenHourSky.SkyboxFt` is sky E's face, but `Terrain.Clouds.Cover` = 1, so the volumetric overcast hides the skybox completely. Setting Cover to 0.5 on the client (a temporary review change, not committed) shows sky E correctly. **Bug:** the shipping look must set Cover to about 0.5. |
| Flower beds | `GRASS_ON_BEDS` passes, but the Ground voxel fill built six large raised dirt mounds where the beds are. **Bug:** paint the material at grade (replace the material on the existing surface layer) and don't add volume. |
| Hats | **Bug:** the caping on petani and petani_wanita sits at mouth height, not on top of the head. The Pak RT peci reads as a lumpy blob. The polisi cap attaches correctly. |
| Batik | The Pak RT shirt reads as a zebra print: too much contrast, and the waves are too wide. |
| Vegetation | `VEG_COUNT` passes at 67, but most counted instances are small flower shrubs far from the camera. The near and mid ground is still sparse. |
| Props | Props are now visible on a dirt pad between two buildings. The assets themselves are weak: the "cangkul" slot is an axe, the gerobak is a small modern wheelbarrow and the pagar bambu barely shows. |

## Process notes

- The `ServerStorage.LookDevAssets` folders survived a Studio restart. That suggests the place was saved after the bake, which `REVIEW_ROUND7.md` says must not happen. This is UNVERIFIED.
- The "designer PASS on PNGs + 2×2 sheet" note in WORK_QUEUE item 56 was not given by the human designer.
