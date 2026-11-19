# models_r3 — LookDev model families (WORK_QUEUE round 3 item 23)

Provenance + review sheet for four off-by-default LookDev families placed in the
60×60 corner (absolute origin `{ 500, 0, 500 }`, footprint X/Z 470–530).

**Verdict column: intentionally blank.** No agent has visually graded any model
here. No screenshot was captured and no "looks good" claim is made. A
designer / vision-capable review pass fills the verdicts from the cameras below.

Source policy: CC0 or CC BY **only**. Every download below is CC0 from the
page's own licence field (`Licence: CC0 1.0` / `Public Domain (CC0)`); no
Sketchfab CC BY asset was ingested because its download needs an authenticated
session this pass does not own. Every generated OBJ is original geometry
(stdlib deterministic generator, no third-party mesh data, no brand/IP marks).

Triangle budget (`VISUAL_MASTER_PLAN.md` §6 / V-L3.5): kit piece ≤ 2000 tris,
landmark ≤ 8000 tris. Counts for GLB downloads are parsed from the glTF JSON
`indices` accessor (exact); counts for OBJs are the generated face count.

---

## `buildings_r3` — 3 designer-built models

No verifiable CC0/CC BY download for rumah panggung / kandang / gudang was
reachable this pass; all three are `AGENT_GENERATED` (script-built, ~100–300 faces; not made by the designer) with the briefs below.

| Filename | Source type | Source URL | Author | Licence | Tris | Intended review slot |
|---|---|---|---|---|---|---|
| `generated/buildings_r3/rumah_panggung.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent (no third-party data) | 198 | `buildings_r3` / slot `rumah` — raised stilt house, gabled seng roof, 5-step teras |
| `generated/buildings_r3/kandang_ayam.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 270 | `buildings_r3` / slot `kandang` — small stilted coop, bamboo slats, ladder |
| `generated/buildings_r3/gudang_sawmill.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 162 | `buildings_r3` / slot `gudang` — open-bay shed, log piles, gabled seng roof |

**Brief (all three):** real Indonesian village proportions, timber posts,
overhanging gabled seng roof, no outline (V-D1), built-in-material friendly.
Upgrade path: replace with decimated CC BY `MODEL RUMAH PANGGUNG TRADISIONAL`
/ `Warung` / `Indonesian Hut Low poly` from `SOURCING_BUILDINGS_VEG.md` once an
authenticated download session exists.

## `vegetation_r3` — 2 CC0 downloads + 4 designer-built models

V-D4: tropical only, no pines. Palm and bamboo are real CC0 Quaternius models
hosted by Poly Pizza; banana, mango and shrubs are original OBJs.

| Filename | Source type | Source URL | Author | Licence | Tris | Intended review slot |
|---|---|---|---|---|---|---|
| `raw/vegetation_r3/palm_quaternius.ply.glb` | CC0_DOWNLOAD | page `https://poly.pizza/m/DsrrAYmucG`; direct `https://static.poly.pizza/21d44b5b-efef-4abd-96ad-fc59e4ad373b.glb` | Quaternius | CC0 1.0 (Public Domain) | 3208 | `vegetation_r3` / slot `kelapa` — hero palm backdrop; 3208 tris = landmark class, decimate if used as a kit piece |
| `raw/vegetation_r3/bamboo_quaternius.ply.glb` | CC0_DOWNLOAD | page `https://poly.pizza/m/FUgtfvqgMx`; direct `https://static.poly.pizza/7f76e9d4-49f0-4582-8da9-8141d9756058.glb` | Quaternius | CC0 1.0 (Public Domain) | 400 | `vegetation_r3` / slot `bambu` — 400-tris bamboo clump, kit class |
| `generated/vegetation_r3/palm_tropical.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 292 | `vegetation_r3` / slot `kelapa-alt` — low-poly drooping-frond palm alternative |
| `generated/vegetation_r3/banana_tropical.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 76 | `vegetation_r3` / slot `pisang` — pseudostem + 8 lanceolate leaves + bunch |
| `generated/vegetation_r3/mango_tropical.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 176 | `vegetation_r3` / slot `mangga` — branching trunk + 3 rounded canopy blobs (not conifer) |
| `generated/vegetation_r3/shrubs_tropical.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 96 | `vegetation_r3` / slot `shrubs` — three clustered low-poly shrubs |

**Brief:** palm fronds droop (coconut silhouette), banana leaves are broad and
radiating, mango canopy is rounded and broadleaf, shrubs are low clumps. No
pines, no conifers, no snow biome flora. Upgrade path: Poly Haven CC0
`pachira_aquatica_01` / `bananas` / `island_tree_0x` (API reachable, glTF
downloads left to the decimation/upload session — photogrammetry counts exceed
the per-piece budget before decimation).

## `props_r3` — 5 designer-built models

No verifiable CC0/CC BY download matched the requested gerobak / sumur / pasar
stall / bamboo fence / tool set this pass; all five are `AGENT_GENERATED` (script-built, ~100–300 faces; not made by the designer).

| Filename | Source type | Source URL | Author | Licence | Tris | Intended review slot |
|---|---|---|---|---|---|---|
| `generated/props_r3/cart_gerobak.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 242 | `props_r3` / slot `cart` — two-wheel gerobak bed, shafts, cloth awning |
| `generated/props_r3/well_sumur.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 306 | `props_r3` / slot `well` — stone ring, water, seng roof, pulley, bucket |
| `generated/props_r3/market_stall.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 162 | `props_r3` / slot `stall` — bamboo posts, counter, shelf, seng awning, goods |
| `generated/props_r3/fencing_bambu.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 120 | `props_r3` / slot `fence` — bamboo posts + two horizontal rails |
| `generated/props_r3/tools_set.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 108 | `props_r3` / slot `tools` — cangkul, sabit, metal pail |

**Brief:** real village-prop proportions, bamboo/timber/seng/cloth palette,
no text or logos, instanced-friendly low counts. Upgrade path: Poly Haven CC0
`CoffeeCart_01` / `wooden_crate_01` (API reachable; native glTF far above budget,
needs Blender decimation in the upload session).

## `npcs_r3` — 2 CC0 downloads + 4 designer-built models

Real Quaternius CC0 bodies (rigged, animated glTF) plus four original stylised
villagers with distinct silhouettes. No brand/IP marks in any model.

| Filename | Source type | Source URL | Author | Licence | Tris | Intended review slot |
|---|---|---|---|---|---|---|
| `raw/npcs_r3/farmer_quaternius.ply.glb` | CC0_DOWNLOAD | page `https://poly.pizza/m/7pn3R6hPvE`; direct `https://static.poly.pizza/81f2f0cf-6f53-4b57-92ea-dba0928620f2.glb` | Quaternius | CC0 1.0 (Public Domain) | 5476 | `npcs_r3` / slot `farmer` — rigged animated farmer body (24 clips in glTF); near 8000 landmark cap |
| `raw/npcs_r3/swat_quaternius.ply.glb` | CC0_DOWNLOAD | page `https://poly.pizza/m/Btfn3G5Xv4`; direct `https://static.poly.pizza/713f6535-f4f3-4367-a4c6-ced126ae0936.glb` | Quaternius | CC0 1.0 (Public Domain) | 7752 | `npcs_r3` / slot `polisi` — rigged animated uniformed body, recolour to polisi desa; at landmark cap |
| `generated/npcs_r3/npc_petani_caping.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 172 | `npcs_r3` / slot `villager_a` — conical caping hat + shoulder hoe |
| `generated/npcs_r3/npc_pedagang.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 152 | `npcs_r3` / slot `villager_b` — headcloth + apron, wider torso |
| `generated/npcs_r3/npc_petani_wanita.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 236 | `npcs_r3` / slot `villager_c` — kerudung + scarf + basket |
| `generated/npcs_r3/npc_tukang_peci.obj` | AGENT_GENERATED | n/a (original) | original (deterministic generator) | original, CC0-equivalent | 192 | `npcs_r3` / slot `villager_d` — peci + tool belt |

**Brief:** four villagers, silhouettes distinct by hat/accessory (caping,
headcloth+apron, kerudung+basket, peci+tool belt), caricature proportions per
D7 / `ART.md` §6 (no uncanny realistic faces). The two CC0 rigged bodies are
alternate high-fidelity candidates for the hero NPC slots; decimate before kit use.

---

## Review cameras (absolute world coordinates)

Copy into Studio `screen_capture` as `camera_position` / `look_at_position`.
One camera per family; models should be staged in the corner footprint
X/Z 470–530 at the matching slot before capture. These are proposed cameras,
not yet captured or judged in Studio.

| Family | camera_position | look_at_position |
|---|---|---|
| `buildings_r3` | `{ 500, 16, 542 }` | `{ 500, 4, 490 }` |
| `vegetation_r3` | `{ 468, 12, 520 }` | `{ 500, 4, 500 }` |
| `props_r3` | `{ 532, 11, 500 }` | `{ 498, 2, 500 }` |
| `npcs_r3` | `{ 500, 7, 524 }` | `{ 500, 2, 500 }` |

## Unreachable / not-ingested sources (HTTP status only, no key printed)

- `https://poly.pizza/api/models/DsrrAYmucG` → **HTTP 404** (wrong API path);
  worked around via the model page HTML + `static.poly.pizza` direct GLB.
- `https://quaternius.com/packs/ultimate-nature-pack.html` → **HTTP 404**.
  Quaternius CC0 content was obtained through the Poly Pizza pages above.
- `https://kenney.nl/assets/nature-kit` → **HTTP 200** (page reachable) but the
  page exposes no direct `.zip` asset URL to an unauthenticated client, so no
  Kenney model was downloaded. No candidate fabricated.
- `https://api.polyhaven.com/assets?t=models` and
  `https://api.polyhaven.com/files/pachira_aquatica_01` → **HTTP 200** (API
  reachable); native glTF files not downloaded here because their unculled
  photogrammetry counts exceed the per-piece budget before Blender decimation,
  which belongs to the upload session.
- Sketchfab CC BY building candidates in `SOURCING_BUILDINGS_VEG.md`: not
  downloaded (authenticated session required); designer-build OBJs supplied
  instead. No licence or ID invented.
