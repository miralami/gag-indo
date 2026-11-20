# `npcs_r4` — source, licence and decimation manifest (WORK_QUEUE item 31)

Five **real, textured, page-verified** character models. No script-built primitives, no grey
placeholders, no quaternion/QAL source, no Creator Store, no NC/ND, no Free Standard, no unknown
licence. Source pages were fetched and their own `Licence`, `Creator.Username`, `ResourceID` and
`Tris` fields recorded verbatim in `sources.json`. Direct GLBs came from `static.poly.pizza`
using each page's `ResourceID`. All five Open Cloud IDs came back from completed operations and
are in `upload_manifest.json` (`upload_route: ROBLOX_API_KEY`). No ID is invented here.

Triangle budget: about 2,000 per kit piece (`VISUAL_MASTER_PLAN.md` §6 / V-L3.5). Counts are exact
from each GLB's `indices` accessor. `raw/` holds untouched downloads; `export/` holds the shipped
GLBs. The CC BY attribution below is exact and must be reproduced wherever these assets are used.

| Slot | Source title / page | Author | Verified licence field (page text) | Licence URL | Direct GLB | Source → export tris | Colour | Real ID |
|---|---|---|---|---|---|---|---|---|
| `petani_caping` | [Pleasant peasant](https://poly.pizza/m/f-ePrCSeNjW) | Remy Tauziac | `CC-BY 3.0` (page: `Creative Commons Attribution`) | https://creativecommons.org/licenses/by/3.0/ | https://static.poly.pizza/d2ae02d1-3a39-402e-b93e-d5e4e33df126.glb | 1962 → 1962 | 16 authored `baseColorFactor` colours baked into `COLOR_0` vertex colours | 119484467697394 |
| `pedagang` | [Retail Worker](https://poly.pizza/m/kpw4fiF8St) | J-Toastie | `CC-BY 3.0` (page: `Creative Commons Attribution`) | https://creativecommons.org/licenses/by/3.0/ | https://static.poly.pizza/acea3920-3344-4f42-9f07-d4b2dd336645.glb | 4646 → 1884 | embedded base-colour texture | 77509780044045 |
| `petani_wanita` | [Woman](https://poly.pizza/m/usAZvwbH0Y) | Polygonal Mind | `CC0 1.0` (page: `Public Domain (CC0 1.0)`) | https://creativecommons.org/publicdomain/zero/1.0/ | https://static.poly.pizza/7e8b8395-2bbb-4082-8307-19f6680e2778.glb | 3396 → 1804 | embedded base-colour texture | 123174857731098 |
| `tukang_peci` | [Character_Man](https://poly.pizza/m/IE7rk47BHn) | prathm | `CC0 1.0` (page: `Public Domain (CC0 1.0)`) | https://creativecommons.org/publicdomain/zero/1.0/ | https://static.poly.pizza/8da32ddd-f783-49d5-96ff-aad07a598f7e.glb | 896 → 894 | embedded base-colour texture | 115389644627447 |
| `polisi` | [Male Officer](https://poly.pizza/m/ipEgtSYI8u) | J-Toastie | `CC-BY 3.0` (page: `Creative Commons Attribution`) | https://creativecommons.org/licenses/by/3.0/ | https://static.poly.pizza/39435bcc-674e-49db-8ca1-9bf297316d2f.glb | 5128 → 1689 | embedded base-colour texture | 105455683512183 |

## Exact CC BY attribution

- `"Pleasant peasant" by Remy Tauziac — CC-BY 3.0 (https://creativecommons.org/licenses/by/3.0/); source: https://poly.pizza/m/f-ePrCSeNjW`
- `"Retail Worker" by J-Toastie — CC-BY 3.0 (https://creativecommons.org/licenses/by/3.0/); source: https://poly.pizza/m/kpw4fiF8St`
- `"Male Officer" by J-Toastie — CC-BY 3.0 (https://creativecommons.org/licenses/by/3.0/); source: https://poly.pizza/m/ipEgtSYI8u`

The two CC0 rows need no attribution; their author and page are recorded for provenance anyway.

## Processing

1. `src/source_scan.py` fetched the Poly Pizza search/model pages and read the embedded metadata.
   363 URLs were checked; Quaternius rows and every non-CC0/non-CC-BY licence were discarded.
2. `src/download_sources.py` re-read each chosen page, rejected any licence outside the allowlist
   and any Quaternius author, then wrote the untouched GLB to `raw/npcs_r4/` and `sources.json`.
3. `src/decimate_glb.py` used deterministic vertex clustering (adaptive grid, no new geometry) and
   kept UVs, materials, textures, joints and animations. Every export is ≤ 2000 tris. The
   `petani_caping` source was already at 1962 tris, so it was not decimated from the raw file.
4. `src/bake_vertex_colors.py` converted that source's 16 flat PBR base colours into `COLOR_0`
   vertex colours. It is therefore a vertex-coloured real model, not an untextured placeholder.
5. `src/verify_exports.py` confirmed every export has an embedded image or `COLOR_0`, ≤ 2000 tris
   and all buffer views inside the BIN chunk. Up-axis inspection set `rotX = -pi/2` only for the
   Z-up `petani_wanita` source; the other four are already Y-up.
6. `src/upload_models.py` uploaded the five exports as `Model` assets via the r3 Open Cloud route.
   Every returned `assetId`, `operationId` and `moderationState` is in `upload_manifest.json`.

## R15 compatibility / re-rig

None of the five ships with an R15 humanoid rig. They are review dummies placed by
`InsertService:LoadAsset` on the server, anchored, non-colliding and scaled to 5 studs.

| Slot | Source rig | R15 note |
|---|---|---|
| `petani_caping` | static mesh (0 skins, 0 clips) | Re-rig required for R15 animation. |
| `pedagang` | 2 skins, 5 clips | External rig; re-rig/retarget to R15 before gameplay. |
| `petani_wanita` | static mesh (0 skins, 0 clips) | Re-rig required; Z-up source rotated in the applier. |
| `tukang_peci` | 1 skin, 1 clip | External rig; re-rig/retarget to R15 before gameplay. |
| `polisi` | 2 skins, 5 clips | External rig; re-rig/retarget to R15 before gameplay. |

Designer-build briefs for the remaining fidelity gaps are in `HANDOFF.md`. No visual verdict is
claimed: this manifest records provenance and structure only.
