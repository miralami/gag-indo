# Sprint 3: main-session check (2026-11-23)

Technical check: commits `52dbc3a..e3ae986` on `main`. Local `lune run tests/run.luau` 3123 passed,
`selene src` 0/0/0. CI failed on eight mid-sprint commits (`208606b`..`a3f175d`): the test runner
required `specs/lookdev_leak_sweep_spec` before the spec file was committed. `f9c7fc3` is green; the
owner commit `495c474` failed on CANDIDATE_INDEX parity and `e3ae986` syncs it. Items 250, 251 and 252
are BLOCKED by the worker.

Review rule from the designer (2026-11-23): a subject that cannot be seen is a **no**, not tunda.

| Shot | What the frame shows | Call |
|---|---|---|
| 01 road_fence_r10 | Grass at the lens, fence a faint line | no, not visible |
| 02 ditch_water_r10 | Grass only | no, not visible |
| 03 crop_stages_r10 | Tiny stems in tall grass | no, not visible |
| 04 hill_dressing_r10 | Camera inside the hill: black slope, grass seen from below | no |
| 05 mountains_r10 | Flat blue boxes on the horizon | no, redo |
| 06 bamboo_bridge_r10 | River and banks, no bridge | no, not visible |
| 07 kampung_r10 | Same small box houses as sprint 2 | no |
| 08 default Warung | Roof at the lens | no, not visible |
| 09 river foam (212) | White dashes on the water, read as road markings | no, rapikan |
| 10 ducks (213) | Ducks visible on the river, blocky | yes, rapikan |
| 11 terrace walls (214) | Grass at the lens | no, not visible |
| 12 sawah dressing (215) | Paddy grid reads; flat saturated blue water | yes, rapikan |
| 13 lamps_r10 (246, ClockTime 21) | Same frame as sprint 2, no light pool | no, not visible |
| 14 crop stages golden (247) | Same tiny stems in grass | no, not visible |
| 15 spawn | Unchanged | baseline |
| 16 canonical_overview | Unchanged | baseline |

Main finding: shots #01, #02, #03, #13 and #14 have the same framing as sprint 2,
while the report says the cameras were re-aimed (`CAMERA_GRASS` PASS at 10 to 11 studs) and the
lamps changed. The screenshot is therefore not taken from the measured review camera (most likely the
client camera stays on the character while the check reads the review camera on the server). Sprint
4 starts with item 264: capture from a Scriptable client camera set to the review camera, and print
`CAPTURE_POSE` on every card.
