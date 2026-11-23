# Sprint 2: main-session check (2026-11-23)

Technical check: 14 commits `c312d95..f6a2aa0` on `main`. CI `unit` green on every commit except
`4954d96` (item 241), which `919a7f3` fixed. Local `lune run tests/run.luau` 3084 passed,
`selene src` 0/0/0. Items 238-245, 208-211 and S2-STOP are ticked, none BLOCKED. HUD is hidden in
every shot.

Look at the fifteen shots (main-session read of the contact sheet; the designer's votes decide):

| Shot | What the frame shows | Call |
|---|---|---|
| 01 mountains_r10 | Large flat blue Block faces right at the lens, one grass dome | no, redo (item 251) |
| 02 hill_dressing_r10 | Open grass and the village far away; no rock or tree cluster (coverage 0.0000) | tunda, re-aim (item 250) |
| 03 kampung_r10 | Small houses with brown roofs, readable; round green ball shrubs at the walls | yes, rapikan (item 253) |
| 04 road_fence_r10 | Grass blades fill the lower half; a house far away; no fence | tunda, re-aim (item 250) |
| 05 lamps_r10 (ClockTime 21) | Night sky, one lamp pole, no light pool | tunda (item 246) |
| 06 signposts_r10 | One signpost at the road edge, board blank | yes, rapikan |
| 07 bamboo_bridge_r10 | Default timber plank bridge over the river; bamboo deck not visible | tunda (item 252) |
| 08 furrows_r10 | Player plot from above, furrows visible | yes |
| 09 crop_stages_r10 | Three lollipop-like stems half hidden in grass | no, rapikan (items 250, 254) |
| 10 ditch_water_r10 | Grass only | tunda, re-aim (item 250) |
| 11 spawn | Spawn road and houses, no melon blobs | default look ok |
| 12 canonical_overview | Village ring from above, green hills and far ground at the horizon | default look ok (horizon fixed) |
| 13 default Pasar | Pad, spilled goods, PASAR sign | default look ok |
| 14 default Warung | Warung roof at the lens | tunda, re-aim (item 250) |
| 15 default Pos Ronda | Tower and hut, PASAR sign behind | default look ok |

Main finding: `SUBJECT_COVERAGE` reports high values (0.85 and 0.95) for shots #04 and #10 where the
subject is hidden by terrain grass, because the occlusion raycasts do not hit terrain decoration. It
also let three shots under 0.15 (#02, #07, #08) go into the sheet. Sprint 3 now starts with item 250
(`CAMERA_GRASS` check and re-aims) and the STOP rule re-shoots any candidate under 0.15 before the
sheet is built.
