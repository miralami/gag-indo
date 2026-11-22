# Sky r3 — source + verification manifest

WORK_QUEUE round 3 item 24. One CC0 Poly Haven HDRI, converted offline into six
Roblox `Sky` cube faces. No upload was performed by this agent; no asset ID was invented.

## Source (verified CC0)

| Field | Value |
| --- | --- |
| Asset id | `fish_hoek_beach` |
| Title | Fish Hoek Beach |
| Author(s) | Greg Zaal (All); Rico Cilliers (Backplates) |
| Source URL | https://polyhaven.com/a/fish_hoek_beach |
| Licence | CC0 1.0 Universal — https://creativecommons.org/publicdomain/zero/1.0/ |
| Licence evidence | Asset page JSON-LD `"license":"https://creativecommons.org/publicdomain/zero/1.0/"` and `"copyrightNotice":"CC0 1.0 Universal - public domain dedication"`, HTTP 200. The public API endpoints do not expose a `license` field; licence was read from the asset page metadata, not assumed. |
| Category | `Coast & Water/Beaches/Sandy Beaches` |
| Attributes | `time_of_day=sunrise`, `weather=overcast`, `contrast=low`, `environment=outdoor`, `sky_view=open` |
| Description | "Unclipped, free 16K HDRI capturing Fish Hoek Beach at a soft, overcast sunrise with cool, low-contrast natural light and gentle ocean reflections." |
| Downloaded file | `source/fish_hoek_beach_2k.hdr` |
| Variant | `hdri.2k.hdr` (2048×1024, Radiance RGBE) |
| Download URL | https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/2k/fish_hoek_beach_2k.hdr |
| MD5 | `2277f75992e8ca4ae3f42f22152c08f3` (matches `api.polyhaven.com/files` response) |
| SHA-256 | `e199ce23c87644c4cff49e30a7c47f26abdc81293344368e68e6518772466135` |
| Byte size | 5,687,874 (matches API `size`) |

No DESIGNER_BUILD fallback was needed: a suitable reachable CC0 HDRI was found.

## Real HTTP attempts (Python `requests`, browser-ish User-Agent)

| Tag | URL | Status | Response bytes |
| --- | --- | --- | --- |
| `assets_list` | https://api.polyhaven.com/assets?t=hdris | 200 | 1,077,216 |
| `asset_info` | https://api.polyhaven.com/info/fish_hoek_beach | 200 | 1,101 |
| `asset_files` | https://api.polyhaven.com/files/fish_hoek_beach | 200 | 16,414 |
| `asset_page_licence_metadata` | https://polyhaven.com/a/fish_hoek_beach | 200 | 179,198 |
| `download_2k_hdr` | https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/2k/fish_hoek_beach_2k.hdr | 200 | 5,687,874 |

Failed source attempts: **none**. Every HTTP attempt above returned 200; no status was
inferred or fabricated. Machine-readable copy: `source/download_log.json`.

## Generated faces

Generator: `src/make_cube_faces.py`. Output: `faces/<name>.png`, 1024×1024 RGB PNG.

| Face file | MD5 | SHA-256 | Bytes | Pixel variance |
| --- | --- | --- | --- | --- |
| `faces/SkyboxImageBack.png` | `7a91084829534c7a7f02e176cdd381ca` | `b94210ce74ad62f3b560ac79a0f97f29d74831fa513e459f161b4b87f887daf6` | 584,051 | 1278.827 |
| `faces/SkyboxImageBottom.png` | `ae277967ca736183ee192aa1c1369e3e` | `5de8dffbf6cd9acae871e95ddb4f5bdd8ecc03b363ea5177e453eba73b87f344` | 537,582 | 53.349 |
| `faces/SkyboxImageFront.png` | `9fb38783ba016c5b5be667fad7f645fb` | `1b8097a7b4de3d6e7c9273683d5f10c27362f9b9e503ce460102259c863fad97` | 417,562 | 847.502 |
| `faces/SkyboxImageLeft.png` | `ad91bcb794c46759cbe39c9e6a209f4a` | `c46864a4dc1c3800c3f292bbd504d50febcf19d975d01290b55cd45e4b5260a5` | 515,466 | 984.623 |
| `faces/SkyboxImageRight.png` | `b2fa4f80ef9ec55a636ab0ec9a464620` | `9dc4712393c163d54ead1fdd5d26f3d66efa1bd42f866f43f0f45fd6ba2a5c7a` | 445,815 | 1209.256 |
| `faces/SkyboxImageTop.png` | `7bae3c3d094edc3d4b738d515061fadd` | `ffb56eefd33c079201874eeddf96dc3ecc4eef452006829c523ae6368f2278b5` | 263,851 | 108.007 |

## Verification performed by this agent

- Source MD5 and byte size match the Poly Haven `/files/<id>` API response.
- All six PNGs open with Pillow `verify()`, mode `RGB`, size `1024×1024`.
- All six pixel variances are > 0 (minimum: bottom face, 53.349).
- Generator run twice; all six SHA-256 hashes are byte-identical across runs.
- No upload, no Studio load, no screenshot, no visual grade. Verdict cells stay blank.

| Candidate | Visual verdict |
| --- | --- |
| `sky_r3` |  |
