# Sky r5 — Indonesian bright/humid sky (candidate, OFF by default)

WORK_QUEUE item 38. One toggle, `sky_r5`, built from data in `src/shared/SkyMapR5.luau`
and applied by `src/client/World/LookDevSkyR5.luau`. No visual was graded here;
no Studio screenshot or verdict is claimed.

## Photo references (bright, humid haze, scattered cumulus, high sun, soft blue horizon)

- https://www.pexels.com/photo/traditional-asian-village-surrounded-by-tropical-woods-5904965/ — Tom Fisk, Pexels License.
- https://www.pexels.com/photo/scenic-view-of-minangkabau-village-sumatra-34241020/ — nur ihsan, Pexels License.
- https://www.pexels.com/photo/aerial-view-of-mount-salak-and-village-in-west-java-37224350/ — Ridwan Afriandy, Pexels License.
- https://commons.wikimedia.org/wiki/File:Cumulus_humilis_clouds_over_Jakarta.jpg — Vitaium, CC BY-SA 4.0. REFERENCE ONLY: do not upload or use it; the round rule prefers CC0/CC BY.

## CC0 HDRI candidates

- https://polyhaven.com/a/rustig_koppie_puresky — Greg Zaal, Jarod Guest, CC0.
- https://polyhaven.com/a/kloppenheim_03_puresky — Greg Zaal, Jarod Guest, CC0.

These two newly researched HDRIs are **not uploaded** (no Roblox asset IDs exist
for them yet). The candidate therefore uses the two already-uploaded CC0 sets
with real IDs from `src/shared/SkyMapR4.luau`: set `a` (Poly Haven
`spiaggia_di_mondello`, clear coastal afternoon, Andreas Mischok) as the primary
bright/humid sky and set `b` (`umhlanga_sunrise`, Greg Zaal) as the alternate.
No ID is invented here.

## Bug fixes folded into this candidate

- Ridge slabs removed: `SkyMapR5.ridgeEnabled = false`; the applier creates no
  ridge parts, so the giant black slabs no longer sit in the spawn plaza. A real
  horizon ridge belongs to a later level, not to this sky candidate.
- Terrain `Clouds.Cover` is lowered to `SkyMapR5.cloudCover = 0.4` (within the
  0.3–0.5 range) while active, then the exact prior value is restored on disable.
- Cube top-face seam fixed by assigning the verified top face through the real
  `Sky.SkyboxUp` property, as in the r4 applier.

Overcast/rain skies belong to a future season event and are NOT built now.

## Toggle (off by default)

```
require(game.ReplicatedStorage.Shared.LookDev).enable("sky_r5")
require(game.ReplicatedStorage.Shared.LookDev).disable()
```

The central LookDev registry gains the id in the integrator pass.
