# Sourcing study — buildings and vegetation (round 3 items 4 and 5)

Research deliverable only. It records real, page-verified candidates so the ladder work can start the moment the gates open; **no model was downloaded, uploaded, inserted, or approved, and no ID is invented**. Items 4 and 5 remain `BLOCKED` on the designer's visual verdict, third-party download/auth and the shared Studio Importer session (D-G2), plus the per-hub triangle budgets (`VISUAL_MASTER_PLAN.md` §6). D15 ladder order: (1) free/CC0 or CC BY with attribution; (2) Studio/Blender MCP generation; (3) designer build; (4) parts/CSG. Everything enters as a LookDev candidate until designer yes.

## Licence caveat (important)

Every Sketchfab candidate below is **CC BY (Creative Commons Attribution)**, not CC0: the page states `Author must be credited. Commercial use is allowed.` D15 step 1 allows this, but the author **and** source URL **must** be recorded in `ASSET_MANIFEST.md` when ingested. Poly Haven and Poly Pizza rows are CC0 (site licence `Our assets are all licensed as CC0`; Poly Pizza Quaternius rows `Public Domain (CC0)`). Sketchfab description text is unreliable — several models claim `CC0` in the description while the platform field reads `CC Attribution` or `Free Standard`. **Trust the platform field only**; the rows below use the verified field. Avoid `Free Standard` / NC / ND rows entirely.

## Item 4 — buildings

| Building | Step | Candidate (exact name) | Source | Licence (verified field) | Author | Fit / fallback |
| --- | --- | --- | --- | --- | --- | --- |
| Rumah panggung | 1 | `MODEL RUMAH PANGGUNG TRADISIONAL` | [Sketchfab 90c6c947…](https://sketchfab.com/3d-models/model-rumah-panggung-tradisional-90c6c94749f3467a9b7e2bc17c40e621) | CC Attribution — credit author, commercial OK | miftahnurrazzaq01 | Exact Indonesian stilt house, ~1M tris — **decimate first**. Fallback step 2: Blender MCP rebuild from timber parts using this as reference. |
| Warung | 1 | `Warung` | [Sketchfab 3c5842cb…](https://sketchfab.com/3d-models/warung-3c5842cb2c1645d097ab51caee53af9d) | CC Attribution | alterego.visual | Exact subject, 49.8k faces PBR; fits the village shop frontage. |
| Pos polisi | 1 | `Traffic police post` | [Sketchfab 05145c15…](https://sketchfab.com/3d-models/traffic-police-post-05145c15fb2142d2bdb50056c1292e87) | CC Attribution | suvorovtim | 8.3k faces roadside booth; not Indonesia-specific. Step 3: add `POLISI` sign + local roof. |
| Rumah Pak RT | 1 | `FREE - Village house` | [Sketchfab aef07700…](https://sketchfab.com/3d-models/free-village-house-aef07700534e48238d7ea16c33bdbf81) | CC Attribution | NameSsis | Generic PBR village house, 287k faces — decimate. Step 3: add teras + papan nama. |
| Pasar stalls | 1 | `Market Stall` | [Sketchfab ff6c0680…](https://sketchfab.com/3d-models/market-stall-ff6c0680a17e40989043a503c86e3f33) | CC Attribution | Kairomitsu | Dirty covered stall, 21.7k faces; repeat with colour variants. Step 2: add kain awning. |
| Gubuk sawah | 1 | `Indonesian Hut Low poly` | [Sketchfab 00d24895…](https://sketchfab.com/3d-models/indonesian-hut-low-poly-00d248958d2d4da99dcf58a59a9e58fd) | CC Attribution | Takamaru | Author text: *"low poly indonesian style hut… inspired when see the ricefield"* — exact brief, weak fidelity; step 2/3 upgrade if the verdict fails. |

## Item 5 — vegetation (V-D4: tropical, not pine)

| Plant | Step | Candidate (exact name) | Source | Licence (verified field) | Author | Fit / fallback |
| --- | --- | --- | --- | --- | --- | --- |
| Kelapa / coconut | 1 | `Coconut Palm` | [Sketchfab c1de3902…](https://sketchfab.com/3d-models/coconut-palm-c1de39028a5e4fa59dadf0a447d4342b) | CC Attribution | Vladimiir6 | Textured palm, 197.9k faces; best V-D4 backdrop. CC0 low-poly alt: [Poly Pizza DsrrAYmucG](https://poly.pizza/m/DsrrAYmucG) (Quaternius). |
| Pisang / banana | 1 | `Banana tree` | [Sketchfab 3b658eca…](https://sketchfab.com/3d-models/banana-tree-3b658ecad29f4d9a9606dbf8fea7c9bb) | CC Attribution | 1Quad | Real pisang form, 48.2k faces / 4K textures. Avoid the `Banana_Tree` row whose field is `Free Standard`. |
| Bambu clump | 1 | `Free Bamboo Set` | [Sketchfab e9f9fa53…](https://sketchfab.com/3d-models/free-bamboo-set-e9f9fa5397814f81bf85ad06acf5bf30) | CC Attribution | JonhGillessen | `Free Bamboo Set PBR`, 37.8k faces. CC0 alt [Poly Pizza FUgtfvqgMx](https://poly.pizza/m/FUgtfvqgMx) is 400 tris — too crude. |
| Shrubs | 1 | `Pachira Aquatica 01` | [Poly Haven](https://polyhaven.com/a/pachira_aquatica_01) | CC0 | Rico Cilliers (modelling), Rob Tuytel (scanning) | Tropical shrub, 77K tris / 8K PBR, alpha leaves; no attribution burden. |
| Padi — 3 stages | 1 (single stage only) | `Rice Plant` | [Sketchfab be6aa4ac…](https://sketchfab.com/3d-models/rice-plant-be6aa4ac9adc4f558cc789a0baed8ae3) | CC Attribution | eskastefani | 3.9k faces; author cites `cybex.pertanian.go.id`. **No bibit/tumbuh/siap set found** — step 2 Blender MCP derive three growth variants, step 3 tune heights. |
| Dense grass | 1 | `Grass Bermuda 01` | [Poly Haven](https://polyhaven.com/a/grass_bermuda_01) | CC0 | Rico Cilliers | 224K tris + alpha maps for Terrain decoration cards; **bake to cards** to cut polycount. |

## Hand-off

- Creator Store search terms for a Studio pass (no IDs): `rumah panggung`, `rumah adat`, `warung`, `pos polisi`, `pasar stall`, `gubuk sawah`, `kelapa`, `pohon pisang`, `bambu`, `padi`, `rumput tropis`, `tropical village`, `stilt house`, `market stall` — strip every Script on insert.
- Weakest rows: padi three-stage set (no ready set — generation mandatory), gubuk sawah (low poly), pos polisi / rumah Pak RT / pasar (generic, need local signage/awning), rumah panggung (~1M faces, decimate).
- On ingest: record source + licence + author + **real** Open Cloud ID in `ASSET_MANIFEST.md`; keep per-hub budgets; ship each as its own off-by-default LookDev candidate with a `CANDIDATES.md` row; leave the yes/no to the designer or a vision-capable observer. No agent grades these as "good" from a text summary.
