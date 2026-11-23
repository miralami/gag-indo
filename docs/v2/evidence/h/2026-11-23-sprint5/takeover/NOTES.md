# Sprint 5 takeover (main session, Claude lanes), 2026-11-23

Opencode was stopped after its item 249 work. The main session continued with Sonnet code lanes.
Studio work and commits stayed in the main session.

## Root cause found: the place had lost its baked models

Only 6 of the 75 model IDs referenced by `ModelMap*` were baked in `ServerStorage.LookDevAssets`. As a
result:
- All 531 BackgroundForest trees fell back to bare brown trunks (the "dark specks" on every horizon).
- Most props and buildings fell back to primitives.

`tools/studio/bake_all_modelmap.luau` re-baked all 75 in Edit mode. It skips blocklisted IDs, reports
suspicious scripts and ScreenGuis, and strips them. A sweep afterwards found 0 scripts or GUIs in any
baked entry. The bakes live only in the open session: the designer must save the place to keep them.
Shots: `01_overview_before_bake.jpg`, `02_overview_after_bake.jpg`.

## Lanes and main-session look (judged from the pixels)

| Candidate | Shot | Look |
|---|---|---|
| mountains_r10 (terrain ridges at 640/820/1020, blue Atmosphere) | 03, 04 | **Yes for direction.** Layered ridges close the horizon from spawn. Peaks are too round ("gumdrops"), and an empty flat ring lies between the plateau (400) and the first ridge. Refinement sent. |
| signposts_r10 (green steel pole, 5 Strings plates, lamp) | 05 | **Yes.** Matches `signpost_ref.jpg`; every plate is readable. |
| bamboo_bridge_r10 (yellow posts, black rails, white stone pillars, striped curb) | 06 | **Close.** Pillars, posts, deck and curb read. Posts are too tall and the rails too thin to read. Refinement sent. |
| road_fence_r10 (on the shoulders) | 07 | **Better.** It stands on the grass shoulder, but as short gapped pieces. It should be continuous runs. Refinement sent. |
| shade palms (default look) | 04, 07 | Fixed: the palms now stand beside or behind the Pasar, Warung, Pos Ronda, Pos Polisi, Pak RT and Tengkulak instead of inside them. |

## Round 2 (refinements), Studio look

| Candidate | Shot | Look |
|---|---|---|
| mountains_r10 | 08 | **Yes.** Peaks are joined by saddles into a continuous skyline, and foothills fill the gap. Some tops are still round. |
| bamboo_bridge_r10 | 09 | **Yes, close to the reference.** Short yellow posts, white stone pillars and a striped curb. The black rails are thin but present. |
| road_fence_r10 | 10 | **Yes.** Continuous bamboo fence runs on the shoulder, with a gate gap. |
| crop_stages_r10 | 11 | **Partial.** Plants now read as rows of sprout, young and ready plants, but they are dark spiky wedge clusters built from primitives. A Blender plant model is the next step. |
| ditch_water_r10 | none | Not captured: the Studio capture timed out. Unverified. |

Not done in this takeover:
- 248/249 and Q 220/221 are still open.
- `check_q198`, `check_q243` and `check_q251` (mountain parts), and `check_q206`, `check_q207`, `check_q247` and `check_q254` (old crop and ditch values), are stale against the new designs.
- The review HTML sheet was not built; the shots are in this folder.
