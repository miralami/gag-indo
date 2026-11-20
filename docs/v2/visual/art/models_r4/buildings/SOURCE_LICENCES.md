# buildings_r4 — source and licence manifest

Four real, textured GLB downloads for WORK_QUEUE round 4 item 31. Every source page was fetched
and checked on 2026-11-20; `source_verification.json` records HTTP status, page claim, direct URL
and SHA256 of the downloaded bytes. No Quaternius asset, Creator Store asset, NC/ND, Free Standard
or unknown licence was used. No asset ID is invented here; IDs come only from the completed
Open Cloud operations in `upload_manifest.json`.

## Licence verification

Site licence page: <https://grab3d.com/license/>

Exact quote from the page:

> The short version: every model on Grab3D is dedicated to the public domain under
> CC0 1.0 Universal. Use it for anything, commercial or not. No attribution, no account, no fees.

Full legal basis on that page: “CC0 is not a license with conditions but a public domain dedication
by Creative Commons: we waive all copyright and related rights in the models worldwide, to the
extent the law allows.” Author/publisher recorded for every row: **Grab3D**.

Attribution string: not required — CC0 public-domain dedication. No CC BY asset is used, so
there is no mandatory credit line. Optional provenance credit, if the designer wants one:
“Models from Grab3D, CC0 1.0 Universal.”

Origin transparency, from <https://grab3d.com/how-we-make-models/>:

> No model on Grab3D is carved by hand, and we don’t pretend otherwise. Many start as an
> AI-generated draft and are then corrected in Blender. Our kits are built by scripts.

The four chosen pieces are in the site's **Lightweight** tier, described there as procedurally
built kits: “Kits built by scripts in Blender … Python scripts in Blender define shapes,
proportions, palette and materials, and bake wear such as dirt and edge scuffs into PBR textures.”
These are full PBR GLB assets with embedded colour/roughness/normal images, not grey placeholders
and not primitive boxes assembled by this lane. The only geometry edit here was deterministic
mesh simplification plus one door-node Y scale (see `decimation_report.json`).

## Models

| Slot | Model / source page | Direct GLB | Author | Licence | Raw tris | Exported tris | Embedded images |
|---|---|---|---|---|---:|---:|---:|
| `rumah` | [Stilt House](https://grab3d.com/models/buildings/stilt-house/) ([kit](https://grab3d.com/kits/cozy-homes-world/)) | <https://grab3d.com/dl/stilt-house/stilt-house-light.glb> | Grab3D | CC0 1.0 Universal | 20,400 | 7,569 | 2 JPEG (base colour + metallic/roughness) |
| `kandang` | [Chicken Coop](https://grab3d.com/models/buildings/chicken-coop/) ([kit](https://grab3d.com/kits/cozy-houses-village/)) | <https://grab3d.com/dl/chicken-coop/chicken-coop.glb> | Grab3D | CC0 1.0 Universal | 18,576 | 7,616 | 3 JPEG (base colour + metallic/roughness + normal) |
| `gudang` | [Garden Shed](https://grab3d.com/models/buildings/garden-shed/) ([kit](https://grab3d.com/kits/cozy-houses-village/)) | <https://grab3d.com/dl/garden-shed/garden-shed.glb> | Grab3D | CC0 1.0 Universal | 11,860 | 7,560 | 3 JPEG (base colour + metallic/roughness + normal) |
| `warung` | [Market Stall](https://grab3d.com/models/buildings/market-stall/) ([kit](https://grab3d.com/kits/cozy-houses-village/)) | <https://grab3d.com/dl/market-stall/market-stall-light.glb> | Grab3D | CC0 1.0 Universal | 15,744 | 7,460 | 2 JPEG (base colour + metallic/roughness) |

Verbatim page claims (each checked against the fetched page text):

- Stilt House: “Free under CC0 for personal and commercial use, no attribution. Download without
  login as GLB, FBX, BLEND, USDZ or OBJ. Lightweight with 37,418 triangles and 2K textures and light
  version with 20,400 triangles.”
- Chicken Coop: “Free under CC0 for personal and commercial use, no attribution. Download without
  login as GLB, FBX, BLEND, USDZ or OBJ. Lightweight with 18,576 triangles and 2K textures.”
- Garden Shed: “Free under CC0 for personal and commercial use, no attribution. Download without
  login as GLB, FBX, BLEND, USDZ or OBJ. Lightweight with 11,860 triangles and 2K textures.”
- Market Stall: “Free under CC0 for personal and commercial use, no attribution. Download without
  login as GLB, FBX, BLEND, USDZ or OBJ. Lightweight with 28,580 triangles and 2K textures and light
  version with 15,744 triangles.”

## Fit notes / designer decisions

- `rumah` is the closest CC0 stilt-house match found. Source door was 2.088 m of a 7.197 m model:
  at the 22-stud target it would be 6.38 studs, below the 7-stud door requirement. The pipeline
  scales the `stilt-house_door_l` node 1.12× in Y (still below the eave) giving a 2.3386 m door;
  at `targetHeight = 22` that is about **7.25 studs**. Water patch and rowing boat are part of the
  source asset; the designer may choose to hide or replace them in Track C.
- `warung` uses Market Stall as the small-trade kiosk. It is not Indonesia-specific; a local sign
  and awning are a designer-build follow-up, not a gate for this LookDev candidate.
- `gudang` uses Garden Shed as the farm storehouse; `kandang` uses Chicken Coop directly.
- All four are off-by-default behind `buildings_r4`. No visual verdict is claimed here.

## Reproduce

```powershell
python docs/v2/visual/art/models_r4/buildings/scripts/fetch_sources.py
python docs/v2/visual/art/models_r4/buildings/scripts/decimate.py
python docs/v2/visual/art/models_r4/buildings/scripts/inspect_glb.py docs/v2/visual/art/models_r4/buildings/export/buildings_r4/*.glb
python docs/v2/visual/art/models_r4/buildings/scripts/upload_buildings.py
lune run docs/v2/visual/art/models_r4/buildings/scripts/run_spec.luau
```

`decimate.py` pins `@gltf-transform/cli@4.5.1` via `npx --yes`; no credential is used in download,
inspection or decimation. `upload_buildings.py` reads `ROBLOX_API_KEY` from the environment only and
never prints, logs or writes its value.
