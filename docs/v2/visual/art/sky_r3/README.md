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

## Proposed Roblox `Sky` properties

`<PENDING_UPLOAD:file>` means the main session uploads that PNG and pastes the
returned `rbxassetid://…` here. Nothing below is an invented ID.

| Property | Proposed value |
| --- | --- |
| `SkyboxImageBack` | `<PENDING_UPLOAD:SkyboxImageBack.png>` |
| `SkyboxImageBottom` | `<PENDING_UPLOAD:SkyboxImageBottom.png>` |
| `SkyboxImageFront` | `<PENDING_UPLOAD:SkyboxImageFront.png>` |
| `SkyboxImageLeft` | `<PENDING_UPLOAD:SkyboxImageLeft.png>` |
| `SkyboxImageRight` | `<PENDING_UPLOAD:SkyboxImageRight.png>` |
| `SkyboxImageTop` | `<PENDING_UPLOAD:SkyboxImageTop.png>` |
| `SkyboxIntensity` | `1.0` |
| `SunAngularSize` | `0.5` |
| `MoonAngularSize` | `0.5` |
| `StarCount` | `0` (overcast sunrise) |
| `SunTextureId` | `""` (avoid a second sun over the baked HDRI glow) |
| `MoonTextureId` | `""` |

Apply only behind LookDev `sky_r3`, off by default; save and restore any
pre-existing `Sky` property values on disable.

## Proposed `Atmosphere` haze

Starting values only. Nothing here has been viewed in Studio.

| Property | Proposed value |
| --- | --- |
| `Density` | `0.22` |
| `Color` | `Color3.fromRGB(214, 223, 230)` |
| `Decay` | `0.65` |
| `Offset` | `0.55` |
| `Glare` | `1.2` |
| `Haze` | `2.4` |

## Ridge silhouette

Proposal, not built here: create a `Folder` named `SkyR3Ridge` **inside**
`Workspace.LookDevCorner` so the existing corner adapter destroys it on
`LookDev:disable()`; if a folder of that name already exists, save and restore it.
Populate it with 24 dark wedge `Part`s (or one `MeshPart` ring) centred on
`(500, *, 500)`, radius ~27 studs, each wedge ~6 studs wide, `y` centres 10–14 and
heights 8–20 studs (varied to make a low ridge). Suggested look:
`Color3.fromRGB(24, 28, 32)`, `Material=Enum.Material.Plastic`, `CastShadow=false`.
Radius 27 + half-width 3 keeps the ring inside the X/Z 470–530 footprint.
No silhouette geometry or ID is fabricated in this package.

## Saved review camera (absolute world coordinates)

Proposed camera for the 60×60 corner footprint (X/Z 470–530), not yet captured:

| Shot id | `camera_position` | `look_at_position` |
| --- | --- | --- |
| `sky_horizon` | `{ 500, 9, 554 }` | `{ 500, 16, 500 }` |

It looks north across the corner centre with a slight upward tilt, so the ridge
band sits low and the overcast sky fills the upper frame. Use the existing
`corner` cameras (`docs/v2/visual/art/corner/README.md`) for context shots.

## Verdict

| Candidate | Verdict | Review evidence |
| --- | --- | --- |
| `sky_r3` |  |  |

No agent graded the sky visually; the vision-capable review pass fills the blank
cell after a Studio capture from `sky_horizon`.
