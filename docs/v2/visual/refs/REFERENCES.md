# Visual references and model picks (main session, 2026-11-23)

The designer asked (2026-11-23, after the sprint-2 review) for **references and 3D models first**, and
for primitive builds only as the last resort. The main session finds the references and model picks;
opencode inserts, restyles and checks them. Store IDs below come from Creator Store searches run in
Studio on 2026-11-23 (free models). Before use: insert into a scratch folder, delete every Script,
LocalScript and ModuleScript inside, anchor all parts, check part count against `PERF_BUDGET`, and
record the ID in `docs/v2/visual/art/ASSET_MANIFEST.md`. If an ID fails to insert, try the next pick.

Thumbnail sheets: `store_picks_lamp_sign_bridge.jpg`, `store_picks_house_fence.jpg`.

| Subject | Designer reference | Pick 1 | Pick 2 | Notes |
|---|---|---|---|---|
| Street lamp (`lamps_r10`) | "lampu street jadul pakai bulb" | `4771586650` Vintage Mercury Vapor Light Street Lamp (wooden pole, old lamp head; has a day/night script, remove it) | `13869743481` Realistic Streetlamp (black pole, hanging bulb; drop the light-cone part) | Warm PointLight at the bulb, night only, as in item 202 |
| Signpost (`signposts_r10`) | `signpost_ref.jpg`: green square steel pole, 5-6 green rectangular arrow plates with white text at different heights and directions, small lamp on top | Build in Blender to match the reference | `71310674426033` FREE Blank Direction Signpost (AD Supply, no scripts), restyled green with flat plates | Plate text from `Strings.luau` (id/en): Pasar, Sawah, Balai Desa, Sungai, Kampung |
| Bridge (`bamboo_bridge_r10`, now a village concrete bridge) | `bridge_ref.jpg`: dark concrete deck slab, yellow square posts, two black pipe rails, white end pillars with river-stone pattern, black-white striped curb, stone abutments | `8029943234` Indonesia Concrete Bridge (Rukmantara), restyled to the reference colours | Build from Blocks/Cylinders to the reference | Hide the default bridge while staged (item 252 swap) |
| Kampung houses (`kampung_r10`) | Village houses at the same scale as the default houses, genteng roofs | `18239791051` Rumah Kampung Simple Indonesia (orange genteng roof) | ~~`128627541097148`~~ **MALICIOUS, never use** (hidden fake Studio "Optimize" dialog that asks for a backdoor to be pasted; see `ASSET_MANIFEST.md` "Blocked assets") | No toy-scale houses, no ball shrubs |
| Road fence (`road_fence_r10`) | Low bamboo fence that reads from road level | `118708423521045` Bamboo Fence (cube3D, stylized, upright culms) | `1158365955` Chicao's Small Bamboo Fence | Tall enough to show above the grass (about 2.5 studs) |
| Home props (later) | Warung, Pos Ronda dressing | `89268533487636` Indonesian House Props Kit (22 props, no scripts, anchored) | | Lantern, bench, kendi, LPG stove |

Designer notes to keep (2026-11-23):

- Mountains: the layered-scenery idea is right; it has to be visible as distant layered ridges.
- Hill dressing: accepted; make the rocks bigger, and do small rocks with terrain texture, not parts.
- Default look (spawn, overview): better; improve later following the map plan.

## Mood references (designer, 2026-11-23)

The image files live in `docs/v2/visual/refs/mood/` **on the designer's machine only** (git-ignored:
they are third-party images and the repo is public). Agents on this machine can open them; anyone
else works from the descriptions below.

| File | What it is | What to take from it |
|---|---|---|
| `view_corridors_concept.jpg` | Stylized concept art, three "Key View Corridors": (1) spawn to Pasar, central life; (2) plots to sawah, nature view; (3) south to village, river and bridge | **The target look overall.** Warm packed-dirt paths, chunky trees with big round leafy canopies, houses with terracotta roofs and wooden porches, flowers and crates along every path, and blue-green layered mountains closing each view. Each corridor is a framed view with a path leading the eye to a landmark. Use these three as hero camera framings. |
| `village_road_photo.jpg` | Real Indonesian village road | Narrow road with houses and verandas on one side and rice paddies on the other, a water ditch between road and paddies, short grass on the bunds, banana and coconut palms, misty hills behind. The ditch and paddy edge are what `ditch_water` and the sawah should look like. |
| `village_night_photo.jpg` | Village lane at night | Warm single bulbs on porches and under eaves, not tall street lights; stony dirt lane; palm silhouettes; starry sky. Reference for `lamps` and the night look. |
| `terraces_mountains_photo.jpg` | Terraced rice fields in a mountain valley | Background: layered ridges fading bluer with distance, a valley gap in the middle, forest on the slopes, terraces with low stone walls stepping down, small houses on the slopes. Reference for `mountains`, `hill_dressing` and `terrace_walls`. |

Main lessons: grass is short (paths, bunds and yards are bare earth or short turf), every view has a
leading path and a landmark, and the horizon is always closed by layered mountains, never an open
flat plane.
