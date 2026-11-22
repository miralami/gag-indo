# vegetation_r6 — dense kampung vegetation (round 6, item 47)

OFF-BY-DEFAULT LookDev candidate. Registered by
`src/server/World/LookDevModelsVegetationR6.luau`, pure placement data in
`src/shared/ModelMapVegetationR6.luau`. Nothing is applied until `LookDev.enable("vegetation_r6")`
is called from the **Server** datamodel (`InsertService:LoadAsset` is blocked on the client).
`LookDev.disable()` destroys the single `LookDevVegetationR6` Folder and reattaches any folder that
was there before. `disable()` never touches the shipping world.

## Plant groups and provenance

| Group | Model key | ID | Where it grows |
| --- | --- | --- | --- |
| pisang clumps | `pisang` | 119293239911242 (R4) | Yard edge, wet ground |
| dense bamboo clumps | `bambu` | 130965811347980 (R4) | Yard edge, fence, drainage; five stalks per clump |
| mango stand-in canopy | `mangga` | 103132734600778 (R4) | Large shade tree in the yard; broadleaf stand-in |
| rough verge / sawah grass | `alang_alang` | 361802126 | Sawah bund and uncultivated margin |
| clipped living fence | `teh_tehan` | 8864962424 | Teh-tehan hedge substitute (Bush/Shrub) |
| hedge flowers | `kembang_sepatu` | 15344074131 | Hibiscus at house front and fence gaps |
| potted snake plant | `lidah_mertua` | 184362803 | Porch/steps pots; not planted in the ground |
| ornamental flower | `bunga` | 9639782964 | FlowerBush at fence gaps |
| low shrubs | `shrubs` | 116666781655827 (R4) | Mixed into the sawah/bund verge |

- The four R4 IDs are required at runtime from
  `src/shared/ModelMapVegetationR4.luau`; their CC BY attribution and upload proof are in
  `docs/v2/visual/art/models_r4/vegetation/upload_manifest.json`. They are not repeated as literals
  in the R6 data or applier.
- The five new IDs are exact rows from
  `docs/v2/evidence/h/2026-11-20-r6-vegetation-ids/REPORT.md` (free Creator Store Models,
  `priceCents=0`). Store URLs:
  - 15344074131 — https://create.roblox.com/store/asset/15344074131
  - 184362803 — https://create.roblox.com/store/asset/184362803
  - 8864962424 — https://create.roblox.com/store/asset/8864962424
  - 361802126 — https://create.roblox.com/store/asset/361802126
  - 9639782964 — https://create.roblox.com/store/asset/9639782964
  - Recorded alternates, never loaded: 115462020907259 and 5445549227 (same report).
- No kelapa and no pine (V-D4). Placement follows
  `docs/v2/visual/KAMPUNG_VEGETATION.md`. The search report graded nothing and loaded no model.

## Clusters, tiers and staged default

`staged = true` means the cluster sits in the saved-camera band and is loaded with the default
Rendah selection. `staged = false` clusters fill the rest of the kampung and the real sawah
terraces; they need `setTier("Sedang"|"Tinggi")` and `setIncludeUnstaged(true)`.

| Cluster | Plants | Tier | Staged |
| --- | --- | --- | --- |
| `pisang_yard_clumps` | 2 x 3 pisang | Rendah | yes |
| `bambu_yard_clumps` | 2 x 5 bambu | Rendah | yes |
| `mangga_canopy` | 2 mangga stand-ins | Rendah | yes |
| `hedge_line` | 6 kembang sepatu + 6 teh-tehan | Rendah | yes |
| `lidah_mertua_pots` | 4 potted snake plants | Rendah | yes |
| `bund_verge` | 2 alang-alang + 2 shrubs | Rendah | yes |
| `fence_gap_flowers` | 4 bunga | Rendah | yes |
| `pisang_kampung` / `bambu_kampung` / `mangga_kampung` | 6 / 10 / 2 | Sedang | no |
| `hedge_fence_kampung` / `lidah_mertua_kampung` | 8 / 2 | Sedang | no |
| `sawah_edge` / `fence_gaps_kampung` | 3 alang-alang + 3 shrubs / 2 bunga | Sedang | no |
| `pisang_outer` / `bambu_outer` | 4 / 10 | Tinggi | no |
| `sawah_edge_outer` / `hedge_outer` | 6 / 4 | Tinggi | no |

Planning estimates only, **not measured triangle counts**: 1200 per tree, 400 per shrub,
300 per pot, 200 per grass clump.

| Selection | Instances | Est. triangles | Budget |
| --- | --- | --- | --- |
| Rendah (staged default) | 42 | 30,400 | 50 / 50,000 |
| Sedang (cumulative) | 78 | 58,200 | 100 / 100,000 |
| Tinggi (cumulative) | 102 | 78,200 | 150 / 150,000 |

Every slot is passed through `ModelMapVegetationR6.slotAllowed` against path, hub, tagged plot,
plaza and lapangan zones before `LoadAsset`. Tagged plot rectangles come from
`Map.TAGS.PlotAnchor` at apply time.

## Saved review camera

`eye = { 0, 20, 150 }`, `look = { 0, 8, 96 }` — the R4 vegetation review shot: row across X on the
lapangan with plant fronts toward +Z. MAIN SESSION takes the Studio shots.
No screenshot was captured or graded by the implementation lane; no visual verdict is claimed and
the CANDIDATES.md verdict cell stays blank pending the designer.

## Designer-build gaps

No clearly-correct free model ID was found for pepaya, talas/keladi, singkong, nangka, rambutan or
`jambu_air` (jambu air). They are recorded in `ModelMapVegetationR6.designerBuilds` with references back to
`docs/v2/visual/KAMPUNG_VEGETATION.md` and are never loaded or given an invented ID. The `mangga`
slot remains the proven R4 broadleaf stand-in until a real mango model is sourced.
