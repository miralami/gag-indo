# Art candidates — designer yes/no gallery

Round 2, branch `track/c-world-look`. **Every row is a CANDIDATE awaiting a designer yes. None is
approved, none is shipped on by default.** LookDev is a Studio-only, off-by-default opt-in:
`require(game.ReplicatedStorage.Shared.LookDev).enable("<toggle>")` shows a candidate,
`.disable()` restores the shipping look. A published server can never enable it.

The designer's yes/no belongs in the last column. A blank cell means *not yet decided*; it is never
filled by an agent. Asset IDs come from real Open Cloud operations and are recorded in
`docs/v2/visual/art/ASSET_MANIFEST.md` — none are invented.

## Candidate groups

| Candidate | What it is | Toggle | Render / screenshot | Cost (instances / fps) | Designer yes/no |
|---|---|---|---|---|---|
| `plaza_lighting` | Alternative Pasar material + lighting grade (round 1) | `LookDev.enable("plaza_lighting")` | `docs/v2/evidence/h/2026-11-19-lookdev-candidates/` | ~9 material swaps, 0 new instances, no measurable fps cost | pending — review in Studio |
| `police_walkin` | Police NPC walk-in timed to the raid cutscene (round 1) | `LookDev.enable("police_walkin")` | `docs/v2/evidence/h/2026-11-19-lookdev-candidates/` | reuses 1 existing NPC, 0 new instances, no measurable fps cost | pending — review in Studio |
| `icons` | 27 agent-made painted icons for every IconMap slot (round 2 item 4) | `LookDev.enable("icons")` | `docs/v2/visual/art/icons/render/contact_sheet.png` | 0 new instances; swaps `ImageLabel.Image` on existing icon slots only, no measurable fps cost | **yes, improve** (base is fine; fix `tier_biasa`, `debt`, polish the rest) — 2026-11-19 |
| `textures` | 7 agent-made seamless painted textures for the Pasar surface preset (round 2 item 5) | `LookDev.enable("textures")` | `docs/v2/visual/art/textures/render/contact_sheet.png` | ≤10 temporary `SurfaceAppearance` instances on the imported v2 MeshParts while enabled, all destroyed on disable; no measurable fps cost | **no** — use downloaded CC0 PBR textures as MaterialVariants (D18) |
| `npcs` | Procedural caricature detail parts for the box NPCs — Pak RT, Tengkulak, Polisi, debt collector (round 2 item 6) | `LookDev.enable("npcs")` | `docs/v2/visual/art/npcs/render/contact_sheet.png` | 15 temporary primitive Parts on the 3 live NPCs while enabled (6/5/4), all destroyed on disable; no asset IDs, no measurable fps cost | **no** — real 3D models via the D15 ladder |
| `crops` | Low-poly growth-stage models (bibit/tumbuh/siap) for all 12 crops (round 2 item 7) | `LookDev.enable("crops")` | `docs/v2/visual/art/crops/render/contact_sheet.png` | 36 models / 339 temporary Parts in a floating showcase while enabled, all destroyed on disable; no asset IDs, no measurable fps cost | **no** — real 3D models via the D15 ladder |
| `hubprops` | Hero-prop details on the four shop hubs — stall/counter/desk/table, lantern, accent sign (round 2 item 8) | `LookDev.enable("hubprops")` | `docs/v2/visual/art/hubprops/render/contact_sheet.png` | 43 temporary Parts (pasar 11 / warung 11 / polisi 11 / pakrt 10) on hub anchors while enabled, all destroyed on disable; within 8–12/hub budget; no asset IDs, no measurable fps cost | **no** — keep the idea, rebuild mostly as 3D models, case by case |
| `sounds` | Two free Creator Store music beds for the sawah/hutan zones (round 2 item 9) | `LookDev.enable("sounds")` | `docs/v2/evidence/h/2026-11-19-sound-candidates/REPORT.md` | 2 temporary Sounds in the round-1 `JD_music` SoundGroup while enabled (1 active loop + 1 pooled, loaded), all destroyed on disable; no measurable fps cost | pending — listen in Studio |
| `corner` | 60x60 warung / road bend / sawah edge corner at golden hour (round 3 item 2) | `LookDev.enable("corner")` | `docs/v2/visual/art/corner/README.md` | ~21 temporary Parts in a standalone Workspace Folder plus 1 `Lighting.ClockTime` change while enabled, all restored on disable; static geometry, no measurable fps cost | **no** — off the map with no terrain and flat primitives; rebuild inside the real village instead — 2026-11-20 |
| `textures_r3` | Nine real CC0 Poly Haven PBR MaterialVariants — cobble, dirt, sawah mud, furrows, river stones, bamboo, clay roof, corrugated iron, wood (round 3 items 20/21) | `LookDev.enable("textures_r3")` | `docs/v2/visual/art/textures_r3/render/contact_sheet.png` | 9 temporary `MaterialVariant` objects in one ReplicatedStorage Folder; matching MeshParts get a `MaterialVariant` string swap, all restored on disable; saved review camera in the r3 README; no measurable fps cost | pending — CC0 sources are right but only trim changed; retest once round 4 applies them to ground, walls and roofs — 2026-11-20 |
| `day_cycle` | Live 20–40 s phase tweens, Rendah-budget night lamps, five silent sound beds with adzan saved setting (round 3 item 25, code half) | `LookDev.enable("day_cycle")` | `docs/v2/visual/art/daycycle/README.md` | Night PointLights only while enabled and within the Rendah cap (6 lights, 0 shadows); all Lighting values and lights restored on disable; no IDs invented, no measurable fps cost | **yes, tune** — maghrib reads well; 16:00 is flat; night untested — 2026-11-20 |
| `icons_r3` | Revised original icon set — 27 r3 redraws (`tier_biasa` seedling, `debt` padlock + coins, polish elsewhere) with before/after sheets (round 3 item 22) | `LookDev.enable("icons_r3")` | `docs/v2/visual/art/icons/render_r3/contact_after.png` | 0 new instances; swaps `Visuals.icons[*].id` on existing slots and restores captured originals on disable; no measurable fps cost | **yes** — ship the r3 set — 2026-11-20 |
| `buildings_r3` | Village buildings — stilt house, chicken coop, sawmill shed in the 60x60 corner (round 3 item 23) | `LookDev.enable("buildings_r3")` | `docs/v2/visual/art/models_r3/INTEGRATION.md` | 3 loaded `Model` assets (4–6 MeshParts each) in one Workspace Folder, all destroyed on disable; enable from the **Server** datamodel; static, no measurable fps cost | **no** — smaller than the player, untextured grey; real textured models via the D15 ladder — 2026-11-20 |
| `vegetation_r3` | Tropical vegetation — CC0 palm/bamboo plus original banana, mango, shrubs, alt palm (round 3 item 23) | `LookDev.enable("vegetation_r3")` | `docs/v2/visual/art/models_r3/INTEGRATION.md` | 6 loaded `Model` assets in one Workspace Folder, all destroyed on disable; enable from the **Server** datamodel; static, no measurable fps cost | **no** — tiny, mostly grey; real textured models via the D15 ladder — 2026-11-20 |
| `props_r3` | Village props — gerobak cart, well, market stall, bamboo fence, tool set (round 3 item 23) | `LookDev.enable("props_r3")` | `docs/v2/visual/art/models_r3/INTEGRATION.md` | 5 loaded `Model` assets in one Workspace Folder, all destroyed on disable; enable from the **Server** datamodel; static, no measurable fps cost | **no** — grey fragments that don't read; real textured models via the D15 ladder — 2026-11-20 |
| `npcs_r3` | Villagers — two CC0 rigged bodies plus four original distinct silhouettes (round 3 item 23) | `LookDev.enable("npcs_r3")` | `docs/v2/visual/art/models_r3/INTEGRATION.md` | 6 loaded `Model` assets in one Workspace Folder, all destroyed on disable; enable from the **Server** datamodel; static, no measurable fps cost | **no** — grey blocks, CC0 rigs lie flat; real rigged textured models — 2026-11-20 |
| `sky_r3` | Overcast tropical sunrise CC0 HDRI cube sky with ridge silhouette and Atmosphere haze (round 3 item 24) | `LookDev.enable("sky_r3")` | `docs/v2/visual/art/sky_r3/README.md` | 1 temporary `Sky` instance plus ~12 ridge Parts and Atmosphere value swaps, all restored on disable; no measurable fps cost | pending — the skybox never applied (wrong property names); retest after the fix — 2026-11-20 |
| `textures_r4` | 12 CC0 base-material override sets (36 Image IDs), CLIENT datamodel (round 4 item 29) | `LookDev.enable("textures_r4")` | `docs/v2/visual/art/textures_r4/README.md` | 12 temporary `MaterialVariant` objects + base-material overrides, all restored on disable; off by default, not shipped; static assets, no measurable fps cost | **no** — still wrong after the fix: red-desert ground and straw grass; rethink the terrain approach (round 6) — 2026-11-20 |
| `sky_r4_a` | CC0 HDRI cube sky A, 6 faces, CLIENT datamodel (round 4 item 30) | `LookDev.enable("sky_r4_a")` | `docs/v2/visual/art/sky_r4/README.md` | 1 temporary `Sky` + 12 ridge Parts + Atmosphere values, all restored on disable; off by default, not shipped; static assets, no measurable fps cost | **no** — redo: clear direction is right but it doesn't read as an Indonesian sky; find Indonesian sky references (round 5) — 2026-11-20 |
| `sky_r4_b` | CC0 HDRI cube sky B, 6 faces, CLIENT datamodel (round 4 item 30) | `LookDev.enable("sky_r4_b")` | `docs/v2/visual/art/sky_r4/README.md` | 1 temporary `Sky` + 12 ridge Parts + Atmosphere values, all restored on disable; off by default, not shipped; static assets, no measurable fps cost | **no** — redo: keep only as a mild-cloud reference; not too cloudy (round 5) — 2026-11-20 |
| `sky_r4_c` | CC0 HDRI cube sky C, 6 faces, CLIENT datamodel (round 4 item 30) | `LookDev.enable("sky_r4_c")` | `docs/v2/visual/art/sky_r4/README.md` | 1 temporary `Sky` + 12 ridge Parts + Atmosphere values, all restored on disable; off by default, not shipped; static assets, no measurable fps cost | **no** — too overcast for the default; overcast belongs to rain/season events later — 2026-11-20 |
| `buildings_r4` | Real textured CC0 building models, SERVER datamodel (`InsertService:LoadAsset` blocked on client) (round 4 item 31) | `LookDev.enable("buildings_r4")` | `docs/v2/visual/art/models_r4/buildings/HANDOFF.md` | 4 loaded `Model` assets in one Workspace Folder, all destroyed on disable; off by default, not shipped; static assets, no measurable fps cost | **yes, temporary** — OK as placeholders; the designer refines the final models — 2026-11-20 |
| `vegetation_r4` | Real textured CC0/CC BY vegetation models, SERVER datamodel (`InsertService:LoadAsset` blocked on client) (round 4 item 31) | `LookDev.enable("vegetation_r4")` | `docs/v2/visual/art/models_r4/vegetation/HANDOFF.md` | 5 loaded `Model` assets in one Workspace Folder, all destroyed on disable; off by default, not shipped; static assets, no measurable fps cost | **yes, partial** — pisang yes; kelapa kept for another level; bambu/mangga and the overlap with paths need fixing — 2026-11-20 |
| `props_r4` | Real textured CC0/CC BY village props, SERVER datamodel (`InsertService:LoadAsset` blocked on client) (round 4 item 31) | `LookDev.enable("props_r4")` | `docs/v2/visual/art/models_r4/props/HANDOFF.md` | 7 loaded `Model` assets in one Workspace Folder, all destroyed on disable; off by default, not shipped; static assets, no measurable fps cost | **yes, partial** — jemuran yes; karung semen kept but placed in a fitting context; the other tools are too small — 2026-11-20 |
| `npcs_r4` | Real textured CC0/CC BY villager models, SERVER datamodel (`InsertService:LoadAsset` blocked on client) (round 4 item 31) | `LookDev.enable("npcs_r4")` | `docs/v2/visual/art/models_r4/npcs/HANDOFF.md` | 5 loaded `Model` assets in one Workspace Folder, all destroyed on disable; off by default, not shipped; static assets, no measurable fps cost | **no** — not solid; use solid Roblox R15 characters instead — 2026-11-20 |
| `spawn_ground_r5` | Dirt tanah paths instead of the road strips at spawn, SERVER datamodel (round 5 item 36) | `LookDev.enable("spawn_ground_r5")` | `docs/v2/visual/SPAWN_DRESSING.md` | Hides road/kerb Parts and overlapping MudPatches (exact prior state restored), builds feathered tanah path Parts in one Folder; off by default, not shipped; static Parts, no measurable fps cost | **no** — fix: the back road is still asphalt and tall grass covers the flower beds (round 6) — 2026-11-20 |
| `vegetation_r5` | Cleaned spawn vegetation: pisang, dense bamboo, no kelapa or pines, SERVER datamodel (round 5 item 37) | `LookDev.enable("vegetation_r5")` | `docs/v2/visual/art/vegetation_r5/MANIFEST.md` | Reuses round-4 real model IDs through R5 data with path/plot/hub exclusion zones; loaded Models in one Folder, destroyed on disable; off by default, not shipped; static assets, no measurable fps cost | **yes, partial** — right direction but far too sparse; research typical kampung plants and fill (round 6) — 2026-11-20 |
| `sky_r5` | Bright humid Indonesian sky, low cloud cover, no plaza ridge, CLIENT datamodel (round 5 item 38) | `LookDev.enable("sky_r5")` | `docs/v2/visual/art/sky_r5/README.md` | 1 temporary `Sky` + Atmosphere values + lower Terrain Clouds.Cover, all restored on disable; reuse of two real CC0 HDRI sets; off by default, not shipped; static assets, no measurable fps cost | **yes, tune** — much better; round-6 baseline for the Creator Store sky comparison — 2026-11-20 |
| `sky_r6_a` | Realistic Sky — real free Creator Store skybox (Xeksworld08), 6 face IDs, CLIENT datamodel (round 6 item 44) | `LookDev.enable("sky_r6_a")` | `docs/v2/visual/art/sky_r6/README.md` | 1 temporary `Sky` + shared Atmosphere/effect stack + lower Terrain Clouds.Cover, all restored on disable; saved ~20° camera; off by default, not shipped; static assets, no measurable fps cost | **no** — designer picked sky_r6_e — 2026-11-20 |
| `sky_r6_b` | Sky-Realistic — real free Creator Store skybox (Dev_Flowey), 6 face IDs, CLIENT datamodel (round 6 item 44) | `LookDev.enable("sky_r6_b")` | `docs/v2/visual/art/sky_r6/README.md` | 1 temporary `Sky` + shared Atmosphere/effect stack + lower Terrain Clouds.Cover, all restored on disable; saved ~20° camera; off by default, not shipped; static assets, no measurable fps cost | **no** — designer picked sky_r6_e — 2026-11-20 |
| `sky_r6_c` | Realistic Clear Sky — real free Creator Store skybox (HeyItzDaredevil), 6 face IDs, CLIENT datamodel (round 6 item 44) | `LookDev.enable("sky_r6_c")` | `docs/v2/visual/art/sky_r6/README.md` | 1 temporary `Sky` + shared Atmosphere/effect stack + lower Terrain Clouds.Cover, all restored on disable; saved ~20° camera; off by default, not shipped; static assets, no measurable fps cost | **no** — designer picked sky_r6_e — 2026-11-20 |
| `sky_r6_d` | Realistic Clear Skies (SKYBOX) — real free Creator Store skybox (TrainMaker6), 6 face IDs, CLIENT datamodel (round 6 item 44) | `LookDev.enable("sky_r6_d")` | `docs/v2/visual/art/sky_r6/README.md` | 1 temporary `Sky` + shared Atmosphere/effect stack + lower Terrain Clouds.Cover, all restored on disable; saved ~20° camera; off by default, not shipped; static assets, no measurable fps cost | **no** — designer picked sky_r6_e — 2026-11-20 |
| `sky_r6_e` | Blue Sky W Scattered Clouds Daytime Skybox Light — real free Creator Store skybox (Rozosere48), 6 face IDs, CLIENT datamodel (round 6 item 44) | `LookDev.enable("sky_r6_e")` | `docs/v2/visual/art/sky_r6/README.md` | 1 temporary `Sky` + shared Atmosphere/effect stack + lower Terrain Clouds.Cover, all restored on disable; scripts in the loaded model are not copied; saved ~20° camera; off by default, not shipped; static assets, no measurable fps cost | **yes** — chosen sky; promote to the shipping default (round 7 item 55) — 2026-11-20 |
| `sky_r6_f` | Sunless blue sky skybox realistic clouds — real free Creator Store skybox (f0xz08), 6 face IDs, CLIENT datamodel (round 6 item 44) | `LookDev.enable("sky_r6_f")` | `docs/v2/visual/art/sky_r6/README.md` | 1 temporary `Sky` + shared Atmosphere/effect stack + lower Terrain Clouds.Cover, all restored on disable; script in the loaded model is not copied; saved ~20° camera; off by default, not shipped; static assets, no measurable fps cost | **no** — designer picked sky_r6_e — 2026-11-20 |
| `spawn_ground_r6` | Dirt over the full road corridor and grass masked off flower beds and plots, SERVER datamodel (round 6 item 45) | `LookDev.enable("spawn_ground_r6")` | `docs/v2/visual/SPAWN_DRESSING.md` | Hides road/kerb Parts, overlapping MudPatches and masked `FloraGrass` wedges (exact prior state restored); lays tanah Parts over the full corridor including the 30-wide back ring strip; default generators untouched; off by default, not shipped; static Parts, no measurable fps cost | **yes** — chosen ground; promote to default and paint non-Grass voxels under beds and plots (item 55) — 2026-11-20 |
| `terrain_r6_a` | Default Terrain materials with tuned lush/warm/wet colours; CC0 maps on parts/meshes only, CLIENT datamodel (round 6 item 46) | `LookDev.enable("terrain_r6_a")` | `docs/v2/visual/art/terrain_r6/README.md` | No Terrain-wide base-material override: only `SetMaterialColor` for Grass/Ground/Mud; six part/mesh material overrides reuse existing CC0 IDs; exact colours/overrides restored on disable; off by default, not shipped; static, no measurable fps cost | **no** — also turns the wooden building walls almost black — 2026-11-20 |
| `terrain_r6_b` | Alternate brighter olive Terrain palette with the same part/mesh CC0 set, CLIENT datamodel (round 6 item 46) | `LookDev.enable("terrain_r6_b")` | `docs/v2/visual/art/terrain_r6/README.md` | Same mechanics as `a`, different Terrain palette only; no Terrain-wide base-material override; exact colours/overrides restored on disable; off by default, not shipped; static, no measurable fps cost | **no** — also turns the wooden building walls almost black — 2026-11-20 |
| `vegetation_r6` | Dense kampung vegetation clusters — pisang/bambu/mangga, hedge line, pot plants, sawah verge — real models, SERVER datamodel (round 6 item 47) | `LookDev.enable("vegetation_r6")` | `docs/v2/visual/art/models_r6/vegetation/README.md` | Reuses proven R4 IDs plus five real free Creator Store IDs; staged camera-band clusters by default (42 planning slots / ~30.4k est. tris, Rendah cap 50/50k); Sedang 78/~58.2k, Tinggi 102/~78.2k; exclusion zones keep paths/plots/hubs/plaza/lapangan clear; loaded Models in one Folder, destroyed on disable; off by default, not shipped; static assets, no measured fps cost | **no** — still sparse; 5 IDs failed LoadAsset (not authorized); redo after the asset bake (item 58) — 2026-11-20 |
| `npcs_r6` | Role-specific textured R15 villagers — per-role Shirt/Pants, real hat IDs, facing the saved camera, SERVER datamodel (round 6 item 48) | `LookDev.enable("npcs_r6")` | `docs/v2/visual/art/models_r6/npcs/COSTUMES.md` | Five R15 rigs from HumanoidDescription (Async creator, R5 fallback); ten real Image IDs applied to Shirt/Pants siblings (Route B — HumanoidDescription rejects Image IDs); multi-strategy hat attacher; ~180° flip so villagers face the saved camera; exact prior look restored on disable; off by default, not shipped; static rigs, no measurable fps cost | **yes, refine** — facing the camera and textured is OK; hats still 0 (LoadAsset not authorized), batik reads as dots, polisi needs a real uniform (item 56) — 2026-11-20 |
| `props_r6` | Village tools at real size — gerobak, sumur and cangkul rescaled via GetBoundingBox, SERVER datamodel (round 6 item 50) | `LookDev.enable("props_r6")` | `docs/v2/visual/art/models_r6/props/README.md` | Reuses all seven real `props_r4` IDs; `Model:ScaleTo(target/loadedYSize)` measured from actual GetBoundingBox — gerobak ~6 tall/8 long, sumur 4.5, cangkul 4.5; saved camera moved out from behind the pine row; loaded Models in one Folder, destroyed on disable; off by default, not shipped; static assets, no measurable fps cost | **no** - staged inside the pine stand and buried in grass; only the jemuran is visible (item 57) - 2026-11-20 |
| `vegetation_r7` | Dense kampung vegetation - 60+ instances / 8+ species from the baked models, SERVER datamodel (round 7 item 58) | `LookDev.enable("vegetation_r7")` | `docs/v2/visual/art/models_r7/vegetation/README.md` | 88 pure-data slots across 11 species, Sedang budget, clone-first baked models; real Studio check measured 67 in-cone / 10 species (`CHECK_58.txt`); no runtime LoadAsset on the happy path; off by default, not shipped; no measured fps cost; objective checks PASS | **no** - not graded visually; objective Studio checks only |
| `npcs_r7` | Villagers with baked hats, original peci and new batik/polisi templates, SERVER datamodel (round 7 item 56) | `LookDev.enable("npcs_r7")` | `docs/v2/visual/art/models_r7/npcs/COSTUMES_SHEET.png` | R15 rigs, 4-stud spacing, clone-first hats via AddAccessory, original black peci, 585x559 templates; off by default, not shipped; no measurable fps cost; awaiting designer yes | **yes** — catalog outfits picked by the designer (row A, Pak RT batik B2) and now wired; hats sit on the head — 2026-11-21 |
| `props_r7` | Six props restaged in an open yard with a readable row camera, SERVER datamodel (round 7 item 57) | `LookDev.enable("props_r7")` | `docs/v2/visual/art/models_r7/props/README.md` | Open-yard scan with a 15-stud tree margin, 6-stud row spacing, Ground voxel pads, ReviewCameraPos/LookAt attributes; off by default, not shipped; no measured fps cost; awaiting designer yes | **no** - not graded; objective Studio checks only |
| `hubveg_r8` | Per-hub vegetation dressing (round 9, server-only) | `LookDev.enable("hubveg_r8")` | `docs/v2/evidence/h/2026-11-21-round9/` | 96 baked slots (16/hub), clone-first baked assets; no measured fps cost | pending — review in Studio |
| `plots_r8` | plot fences and gates (round 9, server-only) | `LookDev.enable("plots_r8")` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_71.txt` | 10 plots × >=8 procedural fence segments + gate arch, no asset IDs, no measured fps cost | pending — review in Studio |
| `sawah_r8` | terrace dressing (round 9, server-only) | `LookDev.enable("sawah_r8")` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_72.txt` | 4 water sheets + >=40 verge tufts + 1 gubuk, procedural Parts, no asset IDs, no measured fps cost | pending — review in Studio |
| `river_r8` | river banks and bridge dressing (round 9, server-only) | `LookDev.enable("river_r8")` | `docs/v2/evidence/h/2026-11-21-round9/CHECK_73.txt` | bank vegetation + two-side bridge rails + 6 stepping stones, procedural Parts, no asset IDs, no measured fps cost | pending — review in Studio |
| `props_r5` | Right-sized village tools and contextual karung semen stack, SERVER datamodel (round 5 item 39) | `LookDev.enable("props_r5")` | `docs/v2/visual/art/models_r4/props/HANDOFF.md` | Reuses round-4 real model IDs with per-slot scale and a stacked karung group; loaded Models in one Folder, destroyed on disable; off by default, not shipped; static assets, no measurable fps cost | **yes, partial** — jemuran and karung semen yes; the other tools are still too small — 2026-11-20 |
| `npcs_r5` | Solid upright Roblox R15 villagers from HumanoidDescription, SERVER datamodel (round 5 item 40) | `LookDev.enable("npcs_r5")` | `docs/v2/visual/art/models_r5/npcs/MANIFEST.md` | 5 R15 rigs built from body-colour HumanoidDescriptions, plus 3 real free Creator Store hat Models (caping x2, police cap); upright/grounded/idle, folder destroyed on disable; off by default, not shipped; static rigs, no measurable fps cost | **yes, refine** — the solid R15 base is OK; give each role its own textured costume (polisi uniform, Pak RT batik) — 2026-11-20 |
| `spawn_r5` | Spawn dressing pass — temporary buildings, pisang/bambu, contextual props and R15 villagers, SERVER datamodel (round 5 item 41) | `LookDev.enable("spawn_r5")` | `docs/v2/visual/SPAWN_DRESSING_R5.md` | Composes only approved/temporary assets from the R4/R5 source maps: 2 temporary buildings, jemuran, contextual gudang karung stack, rescaled tools, pisang + dense bamboo, 5 R15 villagers. Tier budgets 50/100/150 instances and 50k/100k/150k tris (Sedang default ~23 instances/58k est.). No kelapa, pine or mangga stand-in; north-road corridor kept clear; folder destroyed on disable. Off by default, not shipped; static, no measurable fps cost | **no** — the designer will compose spawn and sculpt the terrain elevation himself — 2026-11-20 |

## `icons` — per-asset renders and IDs

All 27 PNGs are 256x256 transparent, deterministic output of
`docs/v2/visual/art/icons/src/generate_icons.py`. Every ID below was returned by
`POST /assets/v1/assets` and confirmed `Approved` in the completed operation. The contact sheet is
the single render to review first; individual PNGs are listed for a closer look. The generator
script's validity check passed (all files 256x256 RGBA with non-empty alpha). This session had no
image-input support, so no agent visually graded the icons — the render is provided for the
designer's yes/no, not claimed as agent-verified.

| Slot | Render | Asset ID | Designer yes/no |
|---|---|---|---|
| `crop_padi` | `render/crop_padi.png` | 114251482326552 | |
| `crop_singkong` | `render/crop_singkong.png` | 125071570354841 | |
| `crop_jagung` | `render/crop_jagung.png` | 77336087458478 | |
| `crop_bawang` | `render/crop_bawang.png` | 104903641478136 | |
| `crop_cabai` | `render/crop_cabai.png` | 84310027204694 | |
| `crop_tembakau` | `render/crop_tembakau.png` | 80640549300472 | |
| `crop_kopi` | `render/crop_kopi.png` | 87432090737677 | |
| `crop_tebu` | `render/crop_tebu.png` | 126828358791382 | |
| `crop_kakao` | `render/crop_kakao.png` | 105395581171156 | |
| `crop_cengkeh` | `render/crop_cengkeh.png` | 101021953955568 | |
| `crop_durian` | `render/crop_durian.png` | 94589075400460 | |
| `crop_sawit` | `render/crop_sawit.png` | 127561041299274 | |
| `tier_biasa` | `render/tier_biasa.png` | 89039660400929 | |
| `tier_bagus` | `render/tier_bagus.png` | 81110221353868 | |
| `tier_super` | `render/tier_super.png` | 111608597881986 | |
| `tier_langka` | `render/tier_langka.png` | 121577229795943 | |
| `tier_sultan` | `render/tier_sultan.png` | 124401414397944 | |
| `currency_rupiah` | `render/currency_rupiah.png` | 76189327817658 | |
| `cash` | `render/cash.png` | 84649047415515 | |
| `phone` | `render/phone.png` | 135874869613602 | |
| `garden` | `render/garden.png` | 124397872915480 | |
| `debt` | `render/debt.png` | 83485200694555 | |
| `quest` | `render/quest.png` | 86819230917965 | |
| `cheat` | `render/cheat.png` | 135587262954164 | |
| `hat` | `render/hat.png` | 109619793807014 | |
| `shop` | `render/shop.png` | 133120999661934 | |
| `trophy` | `render/trophy.png` | 130034112081024 | |

`render/*` above is relative to `docs/v2/visual/art/icons/`. The `_upload_probe.png` disc
(`106680734829483`) is a pipeline probe recorded in the manifest, not a candidate for review.

## `textures` — per-asset renders and IDs

All 7 PNGs are 512x512 tileable RGBA, deterministic output of
`docs/v2/visual/art/textures/src/generate_textures.py`. Every ID below was returned by
`POST /assets/v1/assets` and confirmed `moderationState=Approved` in the completed
`GET /assets/v1/operations/{id}` (`texture_sawah` was briefly `Reviewing`, then Approved). The
contact sheet is the single render to review first; individual tiles are listed for a closer look.
The generator's validity and seam checks passed (opposite-edge jumps are no larger than ordinary
interior jumps). This session had no image-input support, so no agent visually graded the tiles —
the render is provided for the designer's yes/no, not claimed as agent-verified.

| Slot | Render | Asset ID | Designer yes/no |
|---|---|---|---|
| `texture_bambu` | `render/texture_bambu.png` | 86020876968095 | |
| `texture_genteng` | `render/texture_genteng.png` | 121899778984239 | |
| `texture_seng` | `render/texture_seng.png` | 116077927961929 | |
| `texture_paving` | `render/texture_paving.png` | 70537329110423 | |
| `texture_sawah` | `render/texture_sawah.png` | 121312141770783 | |
| `texture_kertas` | `render/texture_kertas.png` | 102834761172815 | |
| `texture_tanah` | `render/texture_tanah.png` | 95694392312399 | |

`render/*` above is relative to `docs/v2/visual/art/textures/`.

## Wiring / proof

- `src/shared/IconMap.luau` keeps every entry `id = 0` (letter fallback is the default). Uploaded
  IDs live in `IconMap.candidateIds` and are applied only by
  `src/client/UI/LookDevIcons.luau` while the `icons` candidate is enabled; `disable()` restores
  id 0. The LookDev gate and applier are spec-locked in `tests/specs/lookdev_candidates_spec.luau`
  and `tests/specs/iconmap_spec.luau`.
- Enable/disable round-trip and Studio-only refusal are proven by specs; an in-Studio visual check
  of the enabled icons is part of the round-2 Studio sweep (item 27) and will be recorded there.
- `src/shared/TextureMap.luau` holds the 7 uploaded IDs in `candidateIds`; the shipping
  `Visuals.textures` slots all stay 0 (built-in material + palette colour fallback).
  `src/client/World/LookDevTextures.luau` applies them only while the `textures` candidate is
  enabled and restores every slot and MeshPart on disable. `SurfaceAppearance` can only be parented
  to `MeshPart`s (verified in Studio), so the adapter targets the imported v2 `prop_*`/`kit_*`
  MeshParts; the greybox `Pasar` Parts are left as-is. Spec-locked in
  `tests/specs/texturemap_spec.luau` and `tests/specs/lookdev_candidates_spec.luau`.
- Live Play-mode round-trip: all 7 slots `0 → real IDs → 0`, `TextureMap.usingCandidates()`
  `false → true → false`, and 10 MeshParts received real `rbxassetid://…` `ColorMap`s on enable,
  all destroyed on disable. Evidence `docs/v2/evidence/h/2026-11-19-textures-candidates/`.
- `src/shared/NpcModelCandidates.luau` holds the 19 procedural detail recipes (palette + recipe
  data, no asset IDs). `src/client/World/LookDevNpcs.luau` attaches them to the live box NPCs only
  while `npcs` is enabled and destroys them all on disable; the shipping NPCs are untouched. Follows
  the fictional-caricature design cards in `npcs.md` (`Config/NpcArchetypes.luau`); the Polisi badge
  is a plain fictional disc, no real insignia. Spec-locked in
  `tests/specs/npc_model_candidates_spec.luau` and `tests/specs/lookdev_candidates_spec.luau`.
- Built as procedural source-controlled primitives rather than imported meshes: subagent transport
  was down and place saves are forbidden, so this is durable in Rojo and fully reversible. Live
  Play-VM round-trip: 15 detail parts appeared on the 3 tagged NPCs
  (`tengkulak=5|polisi=4|pakrt=6`) and all were removed on disable. The render is a schematic
  parsed from the recipe source, not a Studio screenshot — this session cannot save captures to
  disk. Evidence `docs/v2/evidence/h/2026-11-19-npc-candidates/`. No agent visually graded the art.
- `src/shared/CropModelCandidates.luau` holds pure-data low-poly recipes (`partsFor(cropId, stage)`)
  for all 12 crops x 3 growth stages, no asset IDs. `src/client/World/LookDevCrops.luau` builds a
  floating showcase of all 36 models only while `crops` is enabled and destroys it all on disable;
  the shipping `FarmService` crop visuals are untouched. Spec-locked in
  `tests/specs/crop_model_candidates_spec.luau` and `tests/specs/lookdev_candidates_spec.luau`.
- Live Play-VM round-trip: 36 models / 339 parts (303 from `partsFor()` + 36 soil bases) appeared on
  enable and all were removed on disable. The render `docs/v2/visual/art/crops/render/contact_sheet.png`
  is dumped from the **same** `partsFor()` the adapter uses (via
  `docs/v2/visual/art/crops/src/dump_crops.luau`), so it cannot drift — a review aid, not a Studio
  screenshot. Evidence `docs/v2/evidence/h/2026-11-19-crop-candidates/`. No agent visually graded the art.
- `src/shared/HubPropCandidates.luau` holds pure-data hero-prop recipes (`partsFor(hubKey)`) for the
  four shop hubs (pasar/warung/polisi/pakrt) plus a shared lantern and an accent-coloured sign, no
  asset IDs. `src/client/World/LookDevHubProps.luau` finds each hub Model recursively under
  `workspace.World`, parents detail parts to its anchor part (CFrame-relative so they follow hub
  yaw), and destroys them all on disable; the shipping `Greybox` hub props are untouched. Spec-locked
  in `tests/specs/hub_prop_candidates_spec.luau` (incl. the `<= 12`/hub budget) and
  `tests/specs/lookdev_candidates_spec.luau`.
- Live Play-VM round-trip: 43 parts (pasar 11 / warung 11 / polisi 11 / pakrt 10) appeared under
  `LookDevHubPropDetails` on enable and all were removed on disable. The render
  `docs/v2/visual/art/hubprops/render/contact_sheet.png` is dumped from the **same** `partsFor()` the
  adapter uses (via `docs/v2/visual/art/hubprops/src/dump_hubprops.luau`), so it cannot drift — a
  review aid, not a Studio screenshot. Evidence `docs/v2/evidence/h/2026-11-19-hubprops-candidates/`.
  No agent visually graded the art.
- `src/shared/SoundMap.luau` holds the two free Creator Store music-bed IDs in `candidateIds`
  (APMOfficial, "Close Your Eyes - 60 - No Melody" 58.59 s / "Cavernous Wonders 60 A" 60.97 s), each
  verified `IsLoaded = true` in a Play VM and recorded with licence/source in
  `docs/v2/visual/art/ASSET_MANIFEST.md`. The shipping `Config/Audio.sounds` slots stay `id = 0`;
  `src/client/World/LookDevSounds.luau` creates the Sounds into the round-1 `JD_music` SoundGroup
  only while the off-by-default `sounds` candidate is enabled, drives loop state through the
  round-1 `AudioPolicy`, and destroys them on disable. Spec-locked in
  `tests/specs/soundmap_spec.luau` and `tests/specs/lookdev_candidates_spec.luau`.
- Live Play-VM round-trip: 2 Sounds appeared in `JD_music` with real, loaded asset IDs
  (`music_hutan` loaded + playing as the single active loop, `music_sawah` loaded + pooled), and both
  were destroyed on disable. There is no image render for audio; the review artifact is the
  in-Studio enable/disable proof. Evidence `docs/v2/evidence/h/2026-11-19-sound-candidates/`. No agent
  graded the sound aesthetically — audition and yes/no belong to the designer.
