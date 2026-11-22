# vegetation_r4 — handoff (WORK_QUEUE item 31)

## Shipped in this lane

Five real, textured, page-verified CC BY 3.0 GLB models, uploaded as Model assets with real
Open Cloud IDs. No script-built primitives, no grey placeholders, no Quaternius/QAL, no
Creator Store, no NC/ND/Free Standard/unknown licence. Provenance, exact attribution, triangle
counts and operation IDs are in `MANIFEST.md` and `upload_manifest.json`.

| Slot | Source model | Asset ID | Target height |
|---|---|---|---|
| kelapa | Coconut palm tree (Poly by Google, CC BY 3.0) | 95769944522207 | 30 studs (brief 25–35) |
| pisang | Banana Tree (Poly by Google, CC BY 3.0) | 119293239911242 | 12 studs (brief 10–14) |
| bambu | Bamboo (Poly by Google, CC BY 3.0) | 130965811347980 | 21 studs (brief 18–25) |
| mangga | **Balsa tree broadleaf stand-in** (Poly by Google, CC BY 3.0) | 103132734600778 | 22 studs |
| shrubs | Shrub (Poly by Google, CC BY 3.0) | 116666781655827 | 3 studs |

`mangga` is explicitly a stand-in: no compliant downloadable mango tree was found. Do not read
that slot as a verified mango; replace it with the designer build below after review.

## Review setup

- Toggle (Server datamodel, dot syntax): `LookDev.enable("vegetation_r4")`; revert with
  `LookDev.disable()`. Colon syntax fails with "unknown candidate".
- Staging is on **real MapSpec terrain**, not the round-3 `(500,500)` corner: five slots across
  `MapSpec.LAPANGAN` (centre `{ 0, 0, 96 }`, 72×56) at `x = -32,-16,0,16,32`, `z = 96`, 12 studs
  apart.
- Saved review camera: position `{ 0, 20, 150 }`, target `{ 0, 8, 96 }`, footprint
  `MapSpec.LAPANGAN`. Both points sit inside `MapSpec.TERRAIN_HALF` and above `MapSpec.GROUND_Y`.
- The applier is SERVER-ONLY (`InsertService:LoadAsset` is blocked on the client). It anchors
  every BasePart, sets `CanCollide = false`, calls `Model:ScaleTo(targetHeight / bodySizeY)`,
  applies `rotX = 0` and `ry`, drops each model's bounding-box bottom to `y = 0`, and restores the
  previous `Workspace.LookDevModelsVegetationR4_vegetation_r4` folder on disable.
- **No visual verdict is claimed.** The main session takes the Studio shot and a designer or
  vision observer decides yes/no.

## BLOCKED — designer builds

No compliant source exists for a true mango tree or for rice at any growth stage. These carry
**no ID** by design; the applier skips ID-less slots rather than loading a placeholder, and no
primitive model was generated. They are not staged in `slots`/`ids`.

| Slot | Target | Brief | References |
|---|---|---|---|
| `mangga_true` | 22 studs | Real mango (*Mangifera indica*): branching trunk, broad rounded non-conifer canopy, textured leaves with visible leaf detail; tropical, no pines/snow; ≤2000 tris as a kit piece. Replace the staged Balsa tree stand-in after review. | `docs/v2/visual/art/SOURCING_BUILDINGS_VEG.md` item 5 (V-D4 rule); https://poly.pizza/search/mango_tree (no CC0/CC BY tree found) |
| `padi_bibit` | 1 stud | Seedling stage: 3–5 slim upright textured blades in a clump, bright young green, rooted at waterline. Must be a real textured mesh, not a Roblox primitive or untextured wedge. | https://sketchfab.com/3d-models/rice-plant-be6aa4ac9adc4f558cc789a0baed8ae3 (CC BY field but authenticated download, unavailable here); `SOURCING_BUILDINGS_VEG.md` item 5 |
| `padi_tumbuh` | 2 studs | Vegetative/tillering stage: 8–12 longer arching leaves, denser clump, same palette and texture language as `padi_bibit`; share the licensed source mesh if one is obtained. | `SOURCING_BUILDINGS_VEG.md` item 5; `docs/v2/visual/art/MAP_SPEC.md` paddy rows (8-stud row spacing, terraces z −312..−376) |
| `padi_siap` | 3 studs | Fruiting stage: fuller clump with drooping panicles of rice grain, golden-green; same mesh lineage and texture scale as the two earlier stages so the three read as one crop over time. | `SOURCING_BUILDINGS_VEG.md` item 5; `docs/v2/visual/art/models_r4/vegetation/HANDOFF.md` |

If a licensed real rice plant is obtained later, derive the three stages from that mesh (leaf
count, height and panicle geometry) and upload three new Model assets; do not invent IDs and do
not generate primitives. All three remain `BLOCKED` in this lane.

## Verification performed

- `python verify_download.py`: all five shipped GLBs report one embedded texture, one material,
  `textured=true`, and exact triangle counts (2784 / 2138 / 3864 / 1038 / 816), all under the
  8,000-tris landmark ceiling; no decimation needed.
- `python inspect_up.py`: Y-up extents, no root rotation, so `rotX = 0`.
- `python upload_models.py`: five HTTP 200 POSTs, five completed operations with real asset IDs;
  key read from env only, never printed or written.
- `lune run docs/v2/visual/art/models_r4/vegetation/scripts/run_spec.luau`: **10 passed, 0 failed**.
  The spec checks real IDs, target heights, `rotX`, camera/slots inside real MapSpec ground,
  CC BY attribution, absence of banned licences, textured source proof, no-ID gaps, and the
  server-applier guard/anchor/collide/scale/restore strings.
- Whole-suite `lune run tests/run.luau`, `selene`, visual review: **not run in this lane**; main
  session owns the central registry, `tests/run.luau` wiring and the review pass. No commit or
  push was made.
