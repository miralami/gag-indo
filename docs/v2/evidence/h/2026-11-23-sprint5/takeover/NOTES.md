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
