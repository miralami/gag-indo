# `props_r4` — source, licence and attribution

Seven real, textured third-party 3D models for WORK_QUEUE round 4 item 31, props lane. Every GLB in
`export/` was downloaded from a page-verified free source, then colour-verified, decimated where
needed and repacked to GLB by `src/prepare_props.py`. No geometry was authored and no script-built
primitive or grey placeholder is used. The complete machine-readable chain — source URL, title,
author, licence, licence text, MD5 and face counts — is in `prepare_report.json`; the real asset IDs
and completed upload operation IDs are in `upload_manifest.json`.

Licence rule applied: **CC0 or CC BY with exact attribution only**. Quaternius/QAL, Creator Store,
NC, ND, `Free Standard` and unknown licences were excluded. Every CC BY row records the author,
source page and licence URL verbatim below. `ROBLOX_API_KEY` was used only by the uploader; the key
was never printed, logged or written into these files. No ID is invented.

## Per-slot source and exact attribution

| Slot | Source title | Source page | Author | Licence | Exact attribution |
|---|---|---|---|---|---|
| `gerobak` | Street Vendor Cart | https://poly.pizza/m/f_LuAcP2_Yh | Alan Zimmerman | Creative Commons Attribution (CC BY 3.0) — https://creativecommons.org/licenses/by/3.0/ | "Street Vendor Cart" by Alan Zimmerman — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/f_LuAcP2_Yh |
| `sumur` | Well | https://poly.pizza/m/1lK9mD0zDZw | Jarlan Perez | Creative Commons Attribution (CC BY 3.0) — https://creativecommons.org/licenses/by/3.0/ | "Well" by Jarlan Perez — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/1lK9mD0zDZw |
| `lapak` | Small stand with Wheels | https://poly.pizza/m/bwgNq3z2SQs | Peter Simcoe | Creative Commons Attribution (CC BY 3.0) — https://creativecommons.org/licenses/by/3.0/ | "Small stand with Wheels" by Peter Simcoe — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/bwgNq3z2SQs |
| `pagar_bambu` | Bamboo Fence Panel | https://poly.pizza/m/dVwByrifEmj | Jarlan Perez | Creative Commons Attribution (CC BY 3.0) — https://creativecommons.org/licenses/by/3.0/ | "Bamboo Fence Panel" by Jarlan Perez — Poly Pizza, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), source https://poly.pizza/m/dVwByrifEmj |
| `alat_tani` | Wooden Axe | https://polyhaven.com/a/wooden_axe | Ulan Cabanilla | CC0 1.0 — https://polyhaven.com/license | "Wooden Axe" by Ulan Cabanilla — Poly Haven, CC0 1.0 (https://polyhaven.com/license), source https://polyhaven.com/a/wooden_axe |
| `karung` | Cement Bag | https://polyhaven.com/a/cement_bag | PierreB3D | CC0 1.0 — https://polyhaven.com/license | "Cement Bag" by PierreB3D — Poly Haven, CC0 1.0 (https://polyhaven.com/license), source https://polyhaven.com/a/cement_bag |
| `jemuran` | Clothesline (light, 1K PBR) | https://grab3d.com/models/props/clothesline/ | Grab3D | CC0 1.0 Universal — https://creativecommons.org/publicdomain/zero/1.0/legalcode | "Clothesline" by Grab3D — CC0 1.0 Universal, no attribution required (https://creativecommons.org/publicdomain/zero/1.0/legalcode), source https://grab3d.com/models/props/clothesline/, licence text https://grab3d.com/dl/clothesline/LICENSE.txt |

Direct downloads, where the source exposes one:

- `gerobak`: https://static.poly.pizza/116d5231-487f-438c-8fa7-e98d401737ab.glb
- `sumur`: https://static.poly.pizza/516aa94b-f969-4ddd-9dc2-4b414b1b22fc.glb
- `lapak`: https://static.poly.pizza/f148433a-9ffc-4e52-a3b7-1a79c89e8354.glb
- `pagar_bambu`: https://static.poly.pizza/023404b1-6974-49a8-9560-23752ee9fb7c.glb
- `alat_tani`: Poly Haven API asset files under `raw/poly_haven/wooden_axe/`
- `karung`: Poly Haven API asset files under `raw/poly_haven/cement_bag/`
- `jemuran`: https://grab3d.com/dl/clothesline/clothesline-light.glb

## Verbatim licence evidence

- Poly Pizza rows: platform licence field `Creative Commons Attribution (CC BY 3.0)`; legal code
  https://creativecommons.org/licenses/by/3.0/. The four attribution strings above are the exact
  credit lines recorded in `prepare_report.json`.
- Poly Haven rows: site licence page https://polyhaven.com/license states
  "Our assets are all licensed as CC0, which is effectively Public Domain".
- Grab3D row: licence page https://grab3d.com/dl/clothesline/LICENSE.txt states, verbatim:
  "To the extent possible under law, Grab3D has waived all copyright and related or neighboring rights to the 3D models, textures and images in this package. This work is published from: Germany."
- Grab3D generation note, disclosed as requested: the downloaded package manifest carries
  `extras.generator: "Created by grab3d"` and the report records the author as
  `Grab3D (manifest extras.generator: Created by grab3d)`. This is a tool/generator note in the
  source package, not a licence restriction; the recorded licence remains CC0 1.0 Universal.

## Colour and budget verification

`V-L3.5` sets about 2,000 triangles per kit piece (landmarks may reach 8,000). Every export was
checked for real colour data before upload.

| Slot | Source faces | Export faces | Colour proof |
|---|---:|---:|---|
| `gerobak` | 8,098 | 2,027 | `COLOR_0` baked from GLB `baseColorFactor`; 17 distinct sampled colours |
| `sumur` | 3,466 | 1,999 | `COLOR_0` baked from GLB `baseColorFactor`; 6 distinct sampled colours |
| `lapak` | 1,542 | 1,542 | `COLOR_0` baked from GLB `baseColorFactor`; 4 distinct sampled colours |
| `pagar_bambu` | 30,816 | 2,000 | `COLOR_0` baked from GLB `baseColorFactor`; 2 distinct sampled colours |
| `alat_tani` | 3,348 | 1,999 | embedded PBR textures, 3 images / 3 textures |
| `karung` | 844 | 844 | embedded PBR textures, 3 images / 3 textures |
| `jemuran` | 12,396 | 2,000 | embedded PBR textures, 2 images / 2 textures |

The Poly Pizza GLBs carried material base colours but no `COLOR_0` attribute or images; the pipeline
baked those exact `baseColorFactor` values into `COLOR_0`. `pyfqmr` decimation used
`preserve_border = false` because the open-sheet meshes otherwise stayed undecimated. Poly Haven
and Grab3D textures were embedded unchanged.

A Poly Pizza "Washing Line" candidate by J-Toastie was rejected before upload: its GLB colours were
grey-only (`0.051`, `0.4039`) and risked reading as a grey placeholder. It was replaced by the
CC0 Grab3D `Clothesline` above, whose source GLB has a pink towel, blue t-shirt, mint shorts and
yellow socks.

## Designer builds

No designer builds needed. All seven required subjects — gerobak, sumur, lapak, pagar bambu,
alat tani, karung, jemuran — were covered by compliant real models. No mesh was rebuilt in Blender,
generated by script or made from Roblox primitives for this lane.
