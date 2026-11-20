# Sky r4 — source + verification manifest

WORK_QUEUE round 4 item 30. Three CC0 Poly Haven HDRIs, each converted offline
into six 1024×1024 cube faces named after the **real** Roblox `Sky` properties.
All 18 faces were uploaded as Image assets through the `ROBLOX_API_KEY` route;
the IDs in `src/shared/SkyMapR4.luau` come only from completed operations and
are listed with their operation IDs in `upload_manifest.json`. No ID invented.

## Licence — hard stop satisfied

Licence: **CC0 1.0 Universal**, https://creativecommons.org/publicdomain/zero/1.0/
Legal code: https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt

Exact text from the CC0 1.0 legal code (Statement of Purpose, retrieved HTTP 200):

> Certain owners wish to permanently relinquish those rights to a Work for
> the purpose of contributing to a commons of creative, cultural and
> scientific works ("Commons") that the public can reliably and without fear
> of later claims of infringement build upon, modify, incorporate in other
> works, reuse and redistribute as freely as possible in any form whatsoever
> and for any purposes, including without limitation commercial purposes.

Each Poly Haven asset page (HTTP 200) carries the JSON-LD fields
`"license":"https://creativecommons.org/publicdomain/zero/1.0/"` and
`"copyrightNotice":"CC0 1.0 Universal - public domain dedication, no attribution required"`.
CC0 needs no attribution; authors and source URLs are recorded below by convention.
Machine-readable proof: `source/download_log.json`.

## Source A — clear coastal afternoon (closest to "clear tropical afternoon")

| Field | Value |
| --- | --- |
| Asset id | `spiaggia_di_mondello` |
| Title | Spiaggia di Mondello |
| Author | Andreas Mischok (All) |
| Source URL | https://polyhaven.com/a/spiaggia_di_mondello |
| Licence | CC0 1.0 Universal (page and legal code verified) |
| Description | Bright afternoon sun, strong directional light, deep blue sky, high-contrast shadows across sunlit sand and coastal trees. |
| Downloaded | `source/spiaggia_di_mondello_2k.hdr`, 2k HDR, 6,230,981 bytes |
| Download URL | https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/2k/spiaggia_di_mondello_2k.hdr |
| MD5 | `c73bdbbb5558c6c02114764b9260dcad` (matches `/files/<id>` API) |
| SHA-256 | `30421cdd4832ae3f362e9f4d4aac146fb096da5b15cdec65cba8eb44aa860dc3` |

## Source B — golden hour

| Field | Value |
| --- | --- |
| Asset id | `umhlanga_sunrise` |
| Title | Umhlanga Sunrise |
| Author | Greg Zaal (All) |
| Source URL | https://polyhaven.com/a/umhlanga_sunrise |
| Licence | CC0 1.0 Universal (page and legal code verified) |
| Description | Soft low-contrast sunrise over a sandy beach; warm sun near the horizon, cool blue sky fill, gentle waves and scattered clouds. |
| Downloaded | `source/umhlanga_sunrise_2k.hdr`, 2k HDR, 6,186,336 bytes |
| Download URL | https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/2k/umhlanga_sunrise_2k.hdr |
| MD5 | `731aa0d670e3af149d18587d967a4fc2` (matches `/files/<id>` API) |
| SHA-256 | `d0e7e238728c659ba2f1deccf55e9547e7a73b5c36a86d05bddaa9d21fc7aa75` |

## Source C — light overcast

| Field | Value |
| --- | --- |
| Asset id | `overcast_soil_puresky` |
| Title | Overcast Soil (Pure Sky) |
| Authors | Jarod Guest (Sky Edits), Sergej Majboroda (Original) |
| Source URL | https://polyhaven.com/a/overcast_soil_puresky |
| Licence | CC0 1.0 Universal (page and legal code verified) |
| Description | Soft, low-contrast overcast sky with diffused natural morning/afternoon light and a subtle warm horizon glow. Pure sky: no ground, no skyline. |
| Downloaded | `source/overcast_soil_puresky_2k.hdr`, 2k HDR, 4,568,000 bytes |
| Download URL | https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/2k/overcast_soil_puresky_2k.hdr |
| MD5 | `877caf0680d7269037995f6567a67103` (matches `/files/<id>` API) |
| SHA-256 | `5414e1ac0c35e451d28595b2a2cba05e2ca301fdeb755b0a469408443093dafc` |

### Why no perfect "tropical" HDRI

A keyword sweep of the 700+ Poly Haven HDRIs (`tropic`, `palm`, `hawaii`,
`indonesia`, `bali`, `lagoon`) returned **zero** true tropical entries. Per the
task's rule, the closest CC0 options were chosen instead: A is a bright clear
*coastal* afternoon with vegetation, B is a warm golden-hour *beach* sunrise,
C is a pure overcast sky. None contains a city skyline. No non-CC0 source was
considered and no visual grade is claimed.

## HTTP proof

For each asset: `/info/<id>`, `/files/<id>`, `https://polyhaven.com/a/<id>` and
the 2k HDR download all returned **HTTP 200** (12/12 requests). No failed
attempt, no inferred status. Full log: `source/download_log.json`.

## Generation and verification

Generator `src/make_cube_faces.py` is based on
`docs/v2/visual/art/sky_r3/src/make_cube_faces.py`: identical RGBE decoder,
direction grid, bilinear sampler and Reinhard tone-map; only the source table
and output names changed. r3 produced `SkyboxImage*`; Roblox's real properties
are `SkyboxBk`, `SkyboxDn`, `SkyboxFt`, `SkyboxLf`, `SkyboxRt`, `SkyboxUp` —
the r4 files use those names. Face basis vectors (verified against r3):

| Property | Normal | Image right | Image up |
| --- | --- | --- | --- |
| `SkyboxFt` | `(0,0,-1)` | `+X` | `+Y` |
| `SkyboxBk` | `(0,0,+1)` | `-X` | `+Y` |
| `SkyboxRt` | `(+1,0,0)` | `+Z` | `+Y` |
| `SkyboxLf` | `(-1,0,0)` | `+Z` | `+Y` |
| `SkyboxUp` | `(0,+1,0)` | `+X` | `+Z` |
| `SkyboxDn` | `(0,-1,0)` | `+X` | `-Z` |

`src/verify_faces.py` re-ran the generator and asserted all 18 PNGs are
byte-identical; each opens as `RGB` 1024×1024 with non-zero variance (minimum
`4.709`). All MD5/SHA-256/byte counts are in `faces/faces_manifest.json`.

## Uploads

`src/upload_faces.py` posted option A's six faces first, then B, then C, using
the same Open Cloud `POST /assets/v1/assets` route and operation polling as
`sky_r3/src/upload_faces.py`. Each POST returned HTTP 200; each operation
completed with a real `assetId`. The key was read from `ROBLOX_API_KEY` and was
never printed, logged or written to disk. Result: **18/18 Image assets**;
`upload_manifest.json` has 18 rows with `asset_type=Image`,
`upload_route=ROBLOX_API_KEY` and a licence field. No screenshot, no Studio
load, no visual verdict claimed. One A face can be verified in Studio before
the integrator relies on B/C.

| Candidate | Visual verdict |
| --- | --- |
| `sky_r4_a` |  |
| `sky_r4_b` |  |
| `sky_r4_c` |  |
