# Sourcing study — textures, NPCs, animations (round 3 items 7, 8, 9)

Research deliverable only. Real, page-verified candidates so the ladder work can start when the gates open; **no file was downloaded, no asset uploaded, no model inserted, no ID invented**. Items 7/8/9 stay `BLOCKED` on the designer/vision-observer verdict and the shared Studio Importer session (D-G1/D-G2). D18 settles the source policy: textures must be **CC0 PBR** (agent-drawn ones rejected), NPCs/crops must be **real 3D models**. V-D6 animation route is a mix: Creator Store for generic walk/idle, authored/generated for tool verbs.

## Item 7 — CC0 PBR surface textures (D18)

All Poly Haven rows below are `CC0 License`; Poly Haven's site licence states *"Our assets are all licensed as CC0, which is effectively Public Domain even in jurisdictions that do not support the Public Domain."* No attribution required. ambientCG is equally CC0 1.0. Raw files may be used in-game.

| Surface | Step | Exact code / name | Source | Licence | Author |
| --- | --- | --- | --- | --- | --- |
| Cobblestone path | 1 | `cobblestone_floor_01` | [Poly Haven](https://polyhaven.com/a/cobblestone_floor_01) | CC0 | Rob Tuytel |
| Dirt / soil path | 1 | `stony_dirt_path` (alt ambientCG `Ground037`) | [Poly Haven](https://polyhaven.com/a/stony_dirt_path) | CC0 | eye-candy.xyz |
| Tanah sawah (wet mud) | 1 | `brown_mud_03` (category Wet Mud) | [Poly Haven](https://polyhaven.com/a/brown_mud_03) | CC0 | Rob Tuytel |
| Pematang (field ridge) | 1 | `farm_furrows` | [Poly Haven](https://polyhaven.com/a/farm_furrows) | CC0 | Amal Kumar |
| River bank | 1 | `river_small_rocks` | [Poly Haven](https://polyhaven.com/a/river_small_rocks) | CC0 | Rob Tuytel (photo/process), Rico Cilliers (adjustment) |
| Bambu | 1 | `bamboo_wall` | [Poly Haven](https://polyhaven.com/a/bamboo_wall) | CC0 | Amal Kumar |
| Genteng (clay tile) | 1 | `clay_roof_tiles_02` | [Poly Haven](https://polyhaven.com/a/clay_roof_tiles_02) | CC0 | Amal Kumar |
| Seng (corrugated iron) | 1 | `corrugated_iron` | [Poly Haven](https://polyhaven.com/a/corrugated_iron) | CC0 | Dimitrios Savva (photo), Jenelle van Heerden (process) |
| Wood | 1 | `wood_planks` | [Poly Haven](https://polyhaven.com/a/wood_planks) | CC0 | Amal Kumar |

## Item 8 — NPC / character models (R15 compatible)

| Part | Step | Candidate | Source | Licence | Author / fallback |
| --- | --- | --- | --- | --- | --- |
| Farmer body | 1 | `Farmer` (rigged, 24 clips) | [Poly Pizza 7pn3R6hPvE](https://poly.pizza/m/7pn3R6hPvE) | `Public Domain (CC0)` | Quaternius — caricature base |
| Peci | 1 | `Hat Stylised` | [Poly Pizza lNN3PlrjSa](https://poly.pizza/m/lNN3PlrjSa) | `Public Domain (CC0)` | hat_my_guy — flatten/recolour black; fallback Studio MCP `generate_mesh` |
| Caping | 1 — Creator Store search | `caping`, `conical rice hat`, `topi sawah` | [Creator Store docs](https://create.roblox.com/docs/production/creator-store) | varies — free filter, **strip all Scripts** | No credible CC0 model found (Sketchfab conical hats are CC Attribution). Fallback Blender MCP `generate_3d` cone + weave |
| Polisi seragam | 1 | `SWAT` (alt `Character Soldier`) | [Poly Pizza Btfn3G5Xv4](https://poly.pizza/m/Btfn3G5Xv4) | `Public Domain (CC0)` | Quaternius — rigged uniformed body, recolour to polisi; fallback Creator Store `police uniform R15` |

Rejected hats: Poly by Google `Baseball cap` and J-Toastie `Cap` are CC BY 3.0, not CC0.

## Item 9 — animations (V-D6 mix)

| Clip | Step | Route | Source | Licence | Note |
| --- | --- | --- | --- | --- | --- |
| NPC walk | 1 | Creator Store search `R15 walk cycle`, `NPC walk R15`, `walk animation R15` | [Creator Store docs](https://create.roblox.com/docs/production/creator-store) | varies; strip Scripts | Must pass R15 `AnimationRigData` validation |
| NPC idle | 1 | Creator Store search `R15 idle animation`, `NPC idle R15` | same | same | Same R15 gate |
| Cangkul (hoe) | 2 — author | Studio MCP `generate_animation` / designer beats, one track per export | [TOOLS.md §6](../../plan/TOOLS.md) + [Roblox animation docs](https://create.roblox.com/docs/animation/using) | authored in-project | Fallback Quaternius `Universal Animation Library 2` with licence caveat below |
| Panen (harvest) | 2 — author | same | same | authored in-project | same |

## Notes and caveats

- **Quaternius licence conflict**: pack pages still say *"Free to use in personal, educational and commercial projects. (CC0 License)"* ([Universal Animation Library 2](https://quaternius.com/packs/universalanimationlibrary2.html)), but [quaternius.com/license.html](https://quaternius.com/license.html) now states `Quaternius Asset License (QAL) v1.0`, updated `8/28/2026`: product use allowed, *"You just can't resell or redistribute the assets themselves as assets."* Record **both** strings in `ASSET_MANIFEST.md` if that pack is used; legacy Poly Pizza pages still say `Public Domain (CC0)`.
- **Creator Store** has no plain published licence grant (repo `TOOLS.md` §5 flags this); Roblox docs allow *"Disable Scripts"* on inserted assets — do it for every Store model.
- **R15 gate** references: [export avatar animations from Maya](https://create.roblox.com/docs/art/characters/export-avatar-animations-from-maya), [validation system](https://create.roblox.com/docs/marketplace/validation-system) (`AnimationRigData failed internal R15 validation`).
- Weakest rows: caping (no CC0 candidate — Store/generate required), polisi (SWAT substitute), `farm_furrows` is a recent release. No IDs invented; no downloads performed.
- On ingest: record source + licence + author + **real** Open Cloud ID in `ASSET_MANIFEST.md`; keep per-hub budgets; ship each as its own off-by-default LookDev candidate with a `CANDIDATES.md` row; leave the yes/no to the designer or a vision-capable observer. No agent grades these as "good" from a text summary.
