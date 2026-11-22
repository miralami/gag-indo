# Sky r6 — six real Creator Store skies (candidates, OFF by default)

WORK_QUEUE section J item 44. Six independent toggles `sky_r6_a`..`sky_r6_f`, built from data in
`src/shared/SkyMapR6.luau` and applied by `src/client/World/LookDevSkyR6.luau`. `sky_r5` is kept
unchanged as the round-6 baseline comparison.

**No visual was graded.** No screenshot was taken or reviewed for these candidates, no Studio
appearance claim is made, and every verdict cell in `docs/v2/visual/CANDIDATES.md` is **blank**.
The only Studio evidence is the asset load and face-ID read recorded in
`docs/v2/evidence/h/2026-11-20-sky-r6-asset-load/REPORT.md` (`SEEN-IN-STUDIO` for that load only).

## Provenance — real free Creator Store models

Each set is the first `Sky` descendant of one real free Model loaded with
`InsertService:LoadAsset` in a Play-Solo **Server** VM. Legacy
`http://www.roblox.com/asset/?id=N` values were normalised to the integer `N`; the applier adds
`rbxassetid://` at apply time. No ID is invented. Licence: Creator Store free model. Models `e` and
`f` contain scripts; the applier copies only the six Sky faces, never the scripts.

| Candidate | Model ID | Creator Store name | Creator | Store URL |
|---|---:|---|---|---|
| `sky_r6_a` | 4607457995 | Realistic Sky | Xeksworld08 | https://create.roblox.com/store/asset/4607457995 |
| `sky_r6_b` | 10256505900 | Sky-Realistic | Dev_Flowey | https://create.roblox.com/store/asset/10256505900 |
| `sky_r6_c` | 9589448285 | Realistic Clear Sky | HeyItzDaredevil | https://create.roblox.com/store/asset/9589448285 |
| `sky_r6_d` | 11219565245 | Realistic Clear Skies (SKYBOX) | TrainMaker6 | https://create.roblox.com/store/asset/11219565245 |
| `sky_r6_e` | 71778157196658 | Blue Sky W Scattered Clouds Daytime Skybox Light | Rozosere48 | https://create.roblox.com/store/asset/71778157196658 |
| `sky_r6_f` | 79778158338852 | Sunless blue sky skybox realistic clouds | f0xz08 | https://create.roblox.com/store/asset/79778158338852 |

The `sky_r6_e` Store name is "Blue Sky W Scattered Clouds Daytime Skybox Light"; its loaded internal
Sky instance is named `1970s Skybox`. That is the content of the real ID above, not a substitute.

## Exact face IDs read from the loaded Sky instances

| Candidate | SkyboxBk | SkyboxDn | SkyboxFt | SkyboxLf | SkyboxRt | SkyboxUp |
|---|---:|---:|---:|---:|---:|---:|
| `sky_r6_a` | 150335574 | 150335585 | 150335628 | 150335620 | 150335610 | 150335642 |
| `sky_r6_b` | 144933338 | 144931530 | 144933262 | 144933244 | 144933299 | 144931564 |
| `sky_r6_c` | 9544505500 | 9544547905 | 9544504852 | 9544547694 | 9544547542 | 9544547398 |
| `sky_r6_d` | 91458002 | 91457980 | 91458024 | 91458024 | 91458024 | 91458002 |
| `sky_r6_e` | 2835173905 | 2493829793 | 2835177931 | 2835174704 | 2835177433 | 2835175409 |
| `sky_r6_f` | 591058823 | 591059876 | 591058104 | 591057861 | 591057625 | 591059642 |

`sky_r6_d` really repeats the same ID on Ft/Lf/Rt in the loaded model; it is recorded exactly, not
"fixed" by guessing another ID.

## Saved review camera (one for all six)

- Eye: `{ -14, 9, 42 }`
- Look: `{ -14, 28.6, -12 }`

Horizontal distance 54, height delta 19.6, pitch `atan2(19.6, 54)` ≈ 19.9° (about 20° up) so the
sky fills roughly half the frame. Stored in `SkyMapR6.savedCamera`; the spec asserts 18–22°.

## Shared atmosphere stack and effects (identical for all six)

- `Atmosphere`: Density `0.30`, Haze `1.6`, Color `{240,236,224}` (warm white),
  Decay `{150,190,220}` (light blue), Offset `0.65`, Glare `1.2`.
- Terrain `Clouds.Cover = 0.5` (saved and restored exactly on disable).
- Sun stays on: `Sky.CelestialBodiesShown = true` (the property is on `Sky`, not `Lighting`).
- `SunRaysEffect`: Intensity `0.18`, Spread `0.35`, Enabled `true`.
- `BloomEffect`: Intensity `0.12`, Threshold `0.95`, Size `18`, Enabled `true`.
- `ColorCorrectionEffect`: Saturation `0.08`, Contrast `0.02`, TintColor `{1,1,1}` (white, 0–1),
  Brightness `0`, Enabled `true`.

Existing effect instances are reused when present; otherwise they are created. Every touched
property is saved and restored on disable, and only instances created by the candidate are
destroyed. No Part or ridge is built. The top-face seam fix assigns `Sky.SkyboxUp` as its own step.
All engine calls are pcall-guarded: failures warn, never throw.

## Toggle (OFF by default)

Dot syntax only. Enable one candidate at a time; `disable()` restores the shipping look. The short
registry form is `LookDev.enable("sky_r6_a")` (or the corresponding `b`, `c`, `d`, `e`, `f`).

```
require(game.ReplicatedStorage.Shared.LookDev).enable("sky_r6_a")
require(game.ReplicatedStorage.Shared.LookDev).disable()
```

Or, from the Studio command bar, use the one-call review helper (pass `game`):

```
require(game.ReplicatedStorage.Shared.LookDevReview).enable("sky_r6_a", game)
require(game.ReplicatedStorage.Shared.LookDevReview).disable()
```

The review short form is `LookDevReview.enable("sky_r6_a", game)`.

All six short forms (one at a time):

```
LookDev.enable("sky_r6_a")
LookDev.enable("sky_r6_b")
LookDev.enable("sky_r6_c")
LookDev.enable("sky_r6_d")
LookDev.enable("sky_r6_e")
LookDev.enable("sky_r6_f")
```

`LookDev.enable("sky_r5")` is the unchanged baseline. All verdicts remain blank: no candidate here
has been approved or graded.
