# Sky r4 — three CC0 HDRI options for an A/B/C pick

WORK_QUEUE round 4 item 30. Source proof and hashes: `MANIFEST.md`. Generator:
`src/make_cube_faces.py`. Faces: `faces/{a,b,c}/`. Contact sheet:
`contact_sheet.png` (A/B/C side by side with the source licence text).
Upload IDs: `upload_manifest.json`, consumed by `src/shared/SkyMapR4.luau`.

No agent graded any option visually. No Studio screenshot, no visual verdict,
no `SEEN-IN-STUDIO` claim, no place save and no publish.

## Options

| Toggle (`LookDev.enable` dot syntax) | Source | Kind |
| --- | --- | --- |
| `sky_r4_a` | `spiaggia_di_mondello` (Andreas Mischok) | clear coastal afternoon, closest CC0 to "tropical" |
| `sky_r4_b` | `umhlanga_sunrise` (Greg Zaal) | golden hour over a sandy beach |
| `sky_r4_c` | `overcast_soil_puresky` (Jarod Guest, Sergej Majboroda) | light overcast, pure sky |

All three are **CC0 1.0 Universal** Poly Haven HDRIs; licence text, source URLs
and hashes are in `MANIFEST.md`. None has a city skyline.

## Faces and orientation

Each file is a 1024×1024 RGB PNG. The names are the **real Roblox `Sky` face
properties** (r3's `SkyboxImage*` names were the bug that round 4 fixes).
Orientation is inherited unchanged from the verified r3 generator: front is
`-Z`.

| File | Face normal | Image right | Image up |
| --- | --- | --- | --- |
| `SkyboxFt.png` | `(0,0,-1)` | `+X` | `+Y` |
| `SkyboxBk.png` | `(0,0,+1)` | `-X` | `+Y` |
| `SkyboxRt.png` | `(+1,0,0)` | `+Z` | `+Y` |
| `SkyboxLf.png` | `(-1,0,0)` | `+Z` | `+Y` |
| `SkyboxUp.png` | `(0,+1,0)` | `+X` | `+Z` |
| `SkyboxDn.png` | `(0,-1,0)` | `+X` | `-Z` |

Equirectangular longitude `0 = -Z`, `+π/2 = +X`; latitude `+π/2 = +Y`.
Direction is `normal + sx*right + sy*up` at pixel centres in `[-1,1]` with
`sy=+1` on the top row. Longitude wraps, latitude clamps.

Tone map: decode RGBE as `(byte+0.5)*2^(E-136)` (`E==0 → 0`), bilinear-sample
in `float32`, `x = clamp(rgb, 0, ∞)`, `y = x/(1+x)`, `out = round(255*y^(1/2.2))`.
The generator was run twice and produced byte-identical PNGs
(`faces/faces_manifest.json`).

## Applied properties

IDs live only in `Shared.SkyMapR4.sets[a|b|c].ids`; the applier contains no ID
literal. Only the six real face properties are set. The shared `Atmosphere`
grade keeps r3's haze values, with the round-3 bug fixed: `Decay` is a plain
`{r,g,b}` triple converted to an engine colour at apply time.

| Property | Value |
| --- | --- |
| `SkyboxBk/Dn/Ft/Lf/Rt/Up` | `rbxassetid://<ID from SkyMapR4>` |
| `Atmosphere.Density` | `0.22` |
| `Atmosphere.Color` | `{214, 223, 230}` → `fromRGB` at apply time |
| `Atmosphere.Decay` | `{32, 48, 64}` → `fromRGB` at apply time |
| `Atmosphere.Offset` | `0.55` |
| `Atmosphere.Glare` | `1.2` |
| `Atmosphere.Haze` | `2.4` |

`CelestialBodiesShown` is **never written**: the day cycle still moves the real
sun. The previous Sky child and every touched Atmosphere value are restored on
disable; the created Sky, Atmosphere, ridge folder and wedges are destroyed.

## Ridge silhouette and the offset seam

Shared 12-wedge `Wedge` ring from `SkyMapR3`, radius 27, heights 9–20 studs,
colour token `tinta`, `CastShadow=false`, anchored and non-colliding. The old
centre `(500, *, 500)` was off-map; the round-4 staging-area bug fix landed
while this lane ran and moved staging to `{ x = -14, z = -12 }` (confirmed by
`LookDevCorner.ORIGIN`, `ModelMapR3.STAGING_ORIGIN` and
`SkyMapR3.STAGING_ORIGIN`). `SkyMapR4.ridgeOrigin = { -14, 0, -12 }` follows
that centre and the ring lies inside `MapSpec.PLAZA` (X -48..48, Z -42..42).

`SkyMapR4.ridgeOrigin` is the single documented seam: if staging moves again,
change only that table (and the cameras below); the 12 relative offsets in
`SkyMapR4.ridge` stay unchanged. `ridgeAt()` resolves them to absolute positions.

## Saved review cameras (real terrain, near spawn)

Derived from `MapSpec.SPAWN = {x=0, y=0.5, z=28}` and the re-staged `sky_r3`
camera `{ -14, 9, 42 }` → `{ -14, 16, -12 }` in `sky_r3/README.md` (the old
`REVIEW_ROUND3.md` shot pointed at the retired off-map corner). All coordinates
are absolute and inside the playable map; each camera sits on real plaza ground
near spawn and looks north across the staging centre with the ridge low in
frame. Not yet captured in Studio.

| Shot id | `camera_position` | `look_at_position` |
| --- | --- | --- |
| `sky_r4_a` | `{ -14, 9, 42 }` | `{ -14, 16, -12 }` |
| `sky_r4_b` | `{ -6, 7, 40 }` | `{ -14, 14, -12 }` |
| `sky_r4_c` | `{ -22, 8, 40 }` | `{ -14, 15, -12 }` |

## Review toggles

Appliers are registered off by default; the central registry gains the three
ids in the integrator pass. Use the dot form (the colon form is rejected):

```
require(game.ReplicatedStorage.Shared.LookDev).enable("sky_r4_a")
require(game.ReplicatedStorage.Shared.LookDev).enable("sky_r4_b")
require(game.ReplicatedStorage.Shared.LookDev).enable("sky_r4_c")
require(game.ReplicatedStorage.Shared.LookDev).disable()
```

Only one candidate is active at a time; `enable` restores the previous look
first. Verify one option A face in Studio before relying on B/C.

## Verdicts

| Candidate | Verdict | Review evidence |
| --- | --- | --- |
| `sky_r4_a` |  |  |
| `sky_r4_b` |  |  |
| `sky_r4_c` |  |  |

No visual was graded here; the vision-capable review pass fills these cells
after Studio captures from the saved cameras.
