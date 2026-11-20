# vegetation_r4 — provenance, licence and upload manifest (WORK_QUEUE item 31)

One OFF-BY-DEFAULT LookDev family: `vegetation_r4`. This lane owns only the files in this
directory, `src/shared/ModelMapVegetationR4.luau`, `src/server/World/LookDevModelsVegetationR4.luau`
and `tests/specs/model_map_vegetation_r4_spec.luau`. The main session merges the family into the
central `ModelMapR4` / `LookDevModelsR4` registry, `CANDIDATES.md`, `ASSET_MANIFEST.md` and
`tests/run.luau`. **No visual verdict is claimed here.**

## Source policy and hard stops

CC0 or CC BY only. Quaternius assets (site licence QAL), Creator Store, NC/ND, Free Standard and
unknown licences were excluded. Every page below was fetched and its licence field read; the
licence link on every shipped Poly by Google page is `https://creativecommons.org/licenses/by/3.0/`.
The rendered page licence text is exactly `Creative Commons Attribution`. Author is exactly
`Poly by Google`. Attribution strings in `upload_manifest.json` are the exact strings to reproduce.

| Slot | Model (page title) | Source page | Direct GLB | Author | Exact licence text | Attribution | Tris | Class |
|---|---|---|---|---|---|---|---|---|
| `kelapa` | Coconut palm tree | https://poly.pizza/m/bXUTyfiwqBb | https://static.poly.pizza/8f6cf878-c10b-4d28-b38c-45e09d079031.glb | Poly by Google | `Creative Commons Attribution` → CC BY 3.0 | `"Coconut palm tree" by Poly by Google, CC BY 3.0, via Poly Pizza (https://poly.pizza/m/bXUTyfiwqBb)` | 2784 | landmark |
| `pisang` | Banana Tree | https://poly.pizza/m/d0WJSiuOz6o | https://static.poly.pizza/9beeeccc-55e3-46d8-8d9a-0933dc49194f.glb | Poly by Google | `Creative Commons Attribution` → CC BY 3.0 | `"Banana Tree" by Poly by Google, CC BY 3.0, via Poly Pizza (https://poly.pizza/m/d0WJSiuOz6o)` | 2138 | landmark |
| `bambu` | Bamboo | https://poly.pizza/m/eixDUxUDkTK | https://static.poly.pizza/6dfe1137-b696-4d9e-ac40-dbc8f51353f0.glb | Poly by Google | `Creative Commons Attribution` → CC BY 3.0 | `"Bamboo" by Poly by Google, CC BY 3.0, via Poly Pizza (https://poly.pizza/m/eixDUxUDkTK)` | 3864 | landmark |
| `mangga` | Balsa tree | https://poly.pizza/m/ekCgu7iLrz2 | https://static.poly.pizza/4c740e67-5607-4dae-889f-cbd747ca5b1b.glb | Poly by Google | `Creative Commons Attribution` → CC BY 3.0 | `"Balsa tree" by Poly by Google, CC BY 3.0, via Poly Pizza (https://poly.pizza/m/ekCgu7iLrz2)` | 1038 | kit |
| `shrubs` | Shrub | https://poly.pizza/m/aMGUklRjpyo | https://static.poly.pizza/c6494160-b811-4990-8dac-6fda50ad3b95.glb | Poly by Google | `Creative Commons Attribution` → CC BY 3.0 | `"Shrub" by Poly by Google, CC BY 3.0, via Poly Pizza (https://poly.pizza/m/aMGUklRjpyo)` | 816 | kit |

`mangga` is a **broadleaf stand-in**, not a mango tree: no CC0/CC BY downloadable mango tree was
found. It is labelled `mangga` for review only; the true-mango brief is in `HANDOFF.md`.

One extra CC0 candidate was page-verified but not shipped: `Bush` by Isa Lousberg,
https://poly.pizza/m/I5KhMKZKju, page text `Public Domain (CC0)`, 180 tris, one embedded texture.
It was dropped from the staged set to keep the family minimal; no visual judgment was made.

## Texture / vertex-colour verification

`scripts/verify_download.py` parses each GLB's JSON chunk directly (stdlib `struct`/`json`). Every
shipped GLB reports `images=1`, `textures=1`, `materials=1`, `vertex_color=false`, `textured=true`
— real embedded texture maps, no grey placeholders and no script-built primitives. Exact counts
and page metadata are in `sources.json`.

## Decimation result

Budget (`VISUAL_MASTER_PLAN.md` §6 / V-L3.5): about 2,000 triangles per kit piece, up to 8,000 per
landmark. GLB counts are parsed from the glTF `indices` accessors (exact), and match each page's
`Tris` field. All five are already under budget (max 3,864 < 8,000), so **no decimation was
performed** and the raw GLBs were exported and uploaded byte-for-byte. Blender/trimesh are not
installed in this session; no geometry was rewritten.

| Slot | Triangles | Budget class | Limit | Decimation |
|---|---|---|---|---|
| kelapa | 2784 | landmark | 8000 | none needed |
| pisang | 2138 | landmark | 8000 | none needed |
| bambu | 3864 | landmark | 8000 | none needed |
| mangga | 1038 | kit | 2000 | none needed |
| shrubs | 816 | kit | 2000 | none needed |

Up axis: GLB POSITION bounds are tallest on Y for every shipped model (e.g. kelapa extents
`12.75 x 27.08 x 12.16`), with no root rotation — Y-up. `rotX = 0` on every slot; no Z-up import
needed. `inspect_up.py` holds the check.

## Upload result

`scripts/upload_models.py` uses the same Open Cloud route as
`models_r3/src/upload_models.py`: `POST /assets/v1/assets` with `assetType: "Model"`, creator
`172146044`, then poll `/assets/v1/operations/{id}`. `ROBLOX_API_KEY` was read from the environment
only; it was never printed, logged or written to disk. Every POST returned HTTP 200 and every
operation completed with a real `assetId`:

| Slot | Asset ID | Operation ID |
|---|---|---|
| kelapa | 95769944522207 | 163674e4-69a7-40c3-98b4-bb652983f82e |
| pisang | 119293239911242 | bff23685-5367-420f-a4a8-94b25e9ac93e |
| bambu | 130965811347980 | 4ef9389b-0d92-4329-a2b5-2ebe2d2e346a |
| mangga | 103132734600778 | 017a22a3-2b65-47a6-af6e-26ebfc8e96c2 |
| shrubs | 116666781655827 | ce062f39-05a8-47e7-b22d-46df75266048 |

Authoritative per-row data (including moderation state and exact attribution) is in
`upload_manifest.json`. No ID is invented.

## Commands run

From `docs/v2/visual/art/models_r4/vegetation/scripts/`:

- `python probe_pp.py banana_tree coconut_palm palm_tree bamboo mango_tree mango rice shrub banana_leaf plantain rice_plant tropical_tree fruit_tree padi rice_seedling` — enumerated Poly Pizza candidates, filtered by verified licence field and creator; Quaternius excluded.
- `python verify_download.py` — page verification + real GLB downloads + GLB texture/count inspection → `sources.json`, `raw/vegetation_r4/*.glb`.
- `python select_candidates.py` — renamed the two chosen files to slot names, dropped the unused CC0 bush.
- `python inspect_up.py` — POSITION extents / root rotation (up-axis check).
- `python upload_models.py` — five completed Open Cloud uploads → `upload_manifest.json`.
- `lune run docs/v2/visual/art/models_r4/vegetation/scripts/run_spec.luau` — 10 passed, 0 failed.

From the repo root: `lune run tests/run.luau` was **not** run here — the main session owns
`tests/run.luau` wiring and the whole-suite count. No commit or push was made by this lane.
