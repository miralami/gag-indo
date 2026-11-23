# Provisional verdicts (main session, pending designer re-review)

The designer is away for a long run (from 2026-11-23) and asked the main session to review each sprint
itself, keep the review sheets, and log every call here so the designer can re-review later and
overwrite any line. **These are not designer verdicts.** `CANDIDATES.md` / `CANDIDATE_INDEX.md` verdict
cells stay `pending` until the designer confirms. `DefaultLook.PROMOTED` may only use designer
`yes` verdicts, never a line from this file.

How to override: change the "Designer" column (or tell Claude), and the next sprint picks it up.

| Date | Sprint | Candidate | Provisional call | Reason (from the shot) | Sheet | Designer |
|---|---|---|---|---|---|---|
| 2026-11-23 | 1 | `mountains_r10` | **no, redo** | No mountain silhouette in frame; grey void and one grey ellipsoid | `h/2026-11-23-sprint1/REVIEW_SPRINT1.html` #01 | |
| 2026-11-23 | 1 | `hill_dressing_r10` | **no, redo** | Round green/brown blobs read as melons, not rocks or trees | #02 | |
| 2026-11-23 | 1 | `kampung_r10` | **tunda** (re-shoot) | Camera against a red wall; houses not readable | #03 | |
| 2026-11-23 | 1 | `road_fence_r10` | **tunda** (re-shoot) | Fence is a thin line from this camera | #04 | |
| 2026-11-23 | 1 | `lamps_r10` | **tunda** (re-shoot at night) | Daytime shot of a night-only feature | #05 | |
| 2026-11-23 | 1 | `signposts_r10` | **tunda** (re-shoot) | No signpost clearly in frame | #06 | |
| 2026-11-23 | 1 | `bamboo_bridge_r10` | **yes, rapikan** | Bridge and rails read well; planks look like timber, should be bamboo culms | #07 | |
| 2026-11-23 | 1 | `furrows_r10` | **yes** | Furrow rows visible in the plot | #08 | |
| 2026-11-23 | 1 | `crop_stages_r10` | **tunda** (re-shoot closer) | Stages too small to read at this distance | #09 | |
| 2026-11-23 | 1 | `ditch_water_r10` | **tunda** (re-shoot) | Ditch water not visible in frame | #10 | |

Default look notes from sprint 1 baselines (#11 spawn, #12 canonical_overview): the grey horizon void
from above is still there, and round green/brown blobs on the lawns and hills read as melons. Both are
queued in sprint 2.

Data note (2026-11-23, WORK_QUEUE item 244): `hill_dressing_r10` no longer stages spheres. Rocks use
the item-189 baked models when present and Wedge/Cylinder fallbacks when absent; trees are clustered
R4 tropical models with Wedge/Cylinder canopy fallbacks. The provisional "no, redo" verdict above
still stands until a fresh designer review; no verdict cell was changed.

Data note (2026-11-23, WORK_QUEUE item 245): `bamboo_bridge_r10` deck is now 14 Cylinder bamboo
culms with darker Cylinder node rings, not Block timber planks; the two Cylinder rails gain node
rings as well. No asset ID was added and the default look stays untouched. The provisional
"yes, rapikan" verdict above still stands until a fresh designer review; no verdict cell was changed.
Review camera: `bridge_side` (eye 22,10,304 / look 0,3.6,304).
