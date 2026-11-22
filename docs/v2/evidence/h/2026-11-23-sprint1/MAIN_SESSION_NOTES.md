# Sprint 1: main-session check (2026-11-23)

Technical check: 12 commits `c0630ad..20b4422` on `main`, CI `unit` green on every one, local
`lune run tests/run.luau` 3024 passed, `selene src` 0/0/0. All twelve items and S1-STOP are ticked,
none BLOCKED.

Look at the twelve shots (main-session read of the contact sheet; the designer's votes decide):

| Shot | What the frame shows | Problem with the capture |
|---|---|---|
| 01 mountains_r10 | Grey void, one grey ellipsoid, a grass dome | No mountain silhouette visible; the camera looks into the void or the mountains are too pale/far |
| 02 hill_dressing_r10 | Village in the distance, round green and brown blobs on a slope | Blobs read as melons, not rocks or trees |
| 03 kampung_r10 | A flat red plane right at the lens, grass | Camera is inside or against a house; no house is readable |
| 04 road_fence_r10 | Dark road junction | Fence is a thin line, barely visible |
| 05 lamps_r10 | Road, Pak RT house, one small pole | Daytime shot of a night-only feature; lamps unreadable |
| 06 signposts_r10 | Pasar hub, dirt ground | No signpost clearly in frame |
| 07 bamboo_bridge_r10 | Plank bridge with rails over teal river | Reads well; planks look like timber, not bamboo |
| 08 furrows_r10 | One plot from a distance | Furrows are visible but small |
| 09 crop_stages_r10 | One plot, a few tiny sprouts | Three stages are not readable at this distance |
| 10 ditch_water_r10 | Player and plot sign on grass | Ditch water not visible |
| 11 spawn | Default spawn road | Baseline; fine |
| 12 canonical_overview | Village ring from above | Grey horizon void still there; many round green/brown blobs on the lawns read as melons |

Common issues for the next sprint (designer to confirm):

1. Review cameras for 198, 200, 201, 203, 206 and 207 must frame the subject (the subject fills at
   least a third of the frame); add a check that the candidate's parts cover enough screen area.
2. Hide the HUD (`StarterGui` ScreenGuis) during review captures.
3. Shoot `lamps_r10` at ClockTime 21 as well.
4. The round blobs on the lawns and hills (also in the baseline) need a source check: which
   candidate or default generator places them, and whether they should be real tree/rock models.
5. The horizon void is still grey from above; `mountains_r10` did not fix it.
