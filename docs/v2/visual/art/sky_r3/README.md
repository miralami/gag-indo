# Sky r3 — CC0 HDRI → six cube faces

WORK_QUEUE round 3 item 24. Source proof, exact checksums and HTTP log:
`MANIFEST.md`. Generator: `src/make_cube_faces.py`. Faces: `faces/*.png`.

No agent graded the sky visually. No Studio screenshot, no visual verdict, no
`SEEN-IN-STUDIO` claim. No upload was performed here; no asset ID was invented.

## Source and attribution

- Asset: **Fish Hoek Beach** (`fish_hoek_beach`), https://polyhaven.com/a/fish_hoek_beach
- Author(s): Greg Zaal (All); Rico Cilliers (Backplates)
- Licence: **CC0 1.0 Universal** — https://creativecommons.org/publicdomain/zero/1.0/
  (verified from the asset page JSON-LD, HTTP 200; the public API has no `license` field)
- Downloaded file: `source/fish_hoek_beach_2k.hdr`, MD5 `2277f75992e8ca4ae3f42f22152c08f3`,
  5,687,874 bytes — Poly Haven 2k HDR variant, overcast beach sunrise, open sky, visible horizon.
  CC0 needs no attribution, but the author and source are recorded here by convention.

## Faces

Each file is a 1024×1024 RGB PNG. Directions are world-space; front is `-Z`
(Roblox part/camera front).

| File | Face normal | Image right | Image up |
| --- | --- | --- | --- |
| `faces/SkyboxImageFront.png` | `(0, 0, -1)` | `+X` | `+Y` |
| `faces/SkyboxImageBack.png` | `(0, 0, +1)` | `-X` | `+Y` |
| `faces/SkyboxImageRight.png` | `(+1, 0, 0)` | `+Z` | `+Y` |
| `faces/SkyboxImageLeft.png` | `(-1, 0, 0)` | `+Z` | `+Y` |
| `faces/SkyboxImageTop.png` | `(0, +1, 0)` | `+X` | `+Z` |
| `faces/SkyboxImageBottom.png` | `(0, -1, 0)` | `+X` | `-Z` |

Mapping: equirectangular longitude `0 = -Z`, `+π/2 = +X`; latitude `+π/2 = +Y`.
Cubemap direction is `normal + sx*right + sy*up`, with `sx,sy` pixel centres in
`[-1,1]` and `sy=+1` at the top row. Longitude wraps; latitude clamps.

## Tone-map formula (exact)

1. Decode Radiance RGBE: `rgb = (byte + 0.5) * 2^(E - 136)`; `E == 0 → rgb = 0`.
2. Bilinear-sample the HDRI with longitude wrap and latitude clamp (`float32`).
3. `x = max(rgb * 1.0, 0)` (exposure `E_exp = 1.0`).
4. `y = x / (1 + x)` (per-channel Reinhard).
5. `out = round_half_to_even(255 * y^(1/2.2))` → `uint8` RGB.

`numpy.rint` supplies the half-to-even rounding. Pillow writes PNG with
`compress_level=9, optimize=False` and no timestamp metadata. Rerunning the
generator produces byte-identical PNGs (verified twice; hashes in `MANIFEST.md`).

## Roblox `Sky` properties (round-3 bug 2 fixed)

The six faces use the **real** Roblox `Sky` properties, not the old invented `SkyboxImage*`
names. The six real asset IDs live in `src/shared/SkyMapR3.ids` and are recorded per face in
`upload_manifest.json`; no ID is invented here. The adapter loops the map and sets each property
to `"rbxassetid://" .. id`.

| Real property | Old face file | ID source |
| --- | --- | --- |
| `SkyboxBk` | `SkyboxImageBack.png` | `SkyMapR3.ids.SkyboxBk` |
| `SkyboxDn` | `SkyboxImageBottom.png` | `SkyMapR3.ids.SkyboxDn` |
| `SkyboxFt` | `SkyboxImageFront.png` | `SkyMapR3.ids.SkyboxFt` |
| `SkyboxLf` | `SkyboxImageLeft.png` | `SkyMapR3.ids.SkyboxLf` |
| `SkyboxRt` | `SkyboxImageRight.png` | `SkyMapR3.ids.SkyboxRt` |
| `SkyboxUp` | `SkyboxImageTop.png` | `SkyMapR3.ids.SkyboxUp` |

Apply only behind LookDev `sky_r3`, off by default; save and restore any
pre-existing `Sky` property values on disable. One-call review form:
`require(game.ReplicatedStorage.Shared.LookDevReview).enable("sky_r3", game)`.

## Proposed `Atmosphere` haze

Starting values only. Nothing here has been viewed in Studio.

| Property | Proposed value |
| --- | --- |
| `Density` | `0.22` |
| `Color` | `Color3.fromRGB(214, 223, 230)` |
| `Decay` | `Color3.fromRGB(120, 150, 160)` — a COLOUR, never a bare number (bug 2) |
| `Offset` | `0.55` |
| `Glare` | `1.2` |
| `Haze` | `2.4` |

The pure recipe stores each colour as a plain `{r,g,b}` array; the applier's `resolve()` makes the
`Color3` at apply time.

## Ridge silhouette

The `sky_r3` applier builds a `Workspace.SkyR3Ridge` folder with twelve dark wedge `Part`s
centred on `(-14, *, -12)` — the same staged origin as the corner and model families on real PLAZA
ground. Radius ~27 studs, each wedge ~6 studs wide, `y` centres 10–14 and heights 8–20 studs.
`Material=Enum.Material.Plastic`, `CastShadow=false`, `Anchored=true`, `CanCollide=false`, colour
from the `tinta` palette token. Radius 27 + half-width 3 keeps the ring inside X -44..16 /
Z -42..18, i.e. inside `MapSpec.PLAZA`. No silhouette ID is fabricated in this package.

## Saved review camera (absolute world coordinates)

Camera for the re-staged corner (old values shifted by X -514, Z -512), not yet captured:

| Shot id | `camera_position` | `look_at_position` |
| --- | --- | --- |
| `sky_horizon` | `{ -14, 9, 42 }` | `{ -14, 16, -12 }` |

It looks north across the corner centre with a slight upward tilt, so the ridge
band sits low and the overcast sky fills the upper frame. Use the existing
`corner` cameras (`docs/v2/visual/art/corner/README.md`) for context shots.

## Verdict

| Candidate | Verdict | Review evidence |
| --- | --- | --- |
| `sky_r3` |  |  |

No agent graded the sky visually; the vision-capable review pass fills the blank
cell after a Studio capture from `sky_horizon`.
