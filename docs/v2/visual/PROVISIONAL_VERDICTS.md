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

| 2026-11-23 | 2 | `mountains_r10` | **no, redo** | Flat blue Block faces a few studs from the lens; reads as boxes, not distant mountains (item 251) | `h/2026-11-23-sprint2/REVIEW_SPRINT2.html` #01 | |
| 2026-11-23 | 2 | `hill_dressing_r10` | **tunda** (re-shoot) | Coverage 0.0000: no rock or tree cluster in frame from `terrace_wall` (item 250) | `h/2026-11-23-sprint2/REVIEW_SPRINT2.html` #02 | |
| 2026-11-23 | 2 | `kampung_r10` | **yes, rapikan** | Houses and roofs now readable; shrubs are round green balls (item 253) | `h/2026-11-23-sprint2/REVIEW_SPRINT2.html` #03 | |
| 2026-11-23 | 2 | `road_fence_r10` | **tunda** (re-shoot) | Grass blades fill the lens; no fence visible despite coverage 0.8537 (item 250) | `h/2026-11-23-sprint2/REVIEW_SPRINT2.html` #04 | |
| 2026-11-23 | 2 | `lamps_r10` | **tunda** | Night shot works, but one pole and no warm pool on the road (item 246) | `h/2026-11-23-sprint2/REVIEW_SPRINT2.html` #05 | |
| 2026-11-23 | 2 | `signposts_r10` | **yes, rapikan** | Post reads clearly at the road edge; board face is blank, needs a painted label | `h/2026-11-23-sprint2/REVIEW_SPRINT2.html` #06 | |
| 2026-11-23 | 2 | `bamboo_bridge_r10` | **tunda** (re-shoot) | Frame shows the default timber bridge, coverage 0.0321; bamboo deck hidden under it (item 252) | `h/2026-11-23-sprint2/REVIEW_SPRINT2.html` #07 | |
| 2026-11-23 | 2 | `furrows_r10` | **yes** | Unchanged from sprint 1; furrow rows visible on the plot | `h/2026-11-23-sprint2/REVIEW_SPRINT2.html` #08 | |
| 2026-11-23 | 2 | `crop_stages_r10` | **no, rapikan** | Three stages visible but read as thin lollipops half hidden in grass (items 250, 254) | `h/2026-11-23-sprint2/REVIEW_SPRINT2.html` #09 | |
| 2026-11-23 | 2 | `ditch_water_r10` | **tunda** (re-shoot) | Grass only; no water visible despite coverage 0.9464 (item 250) | `h/2026-11-23-sprint2/REVIEW_SPRINT2.html` #10 | |
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

Sprint 2 default-look notes (#11-#15, main session): `spawn` no longer shows melon blobs (item 241,
provisional **yes**). `canonical_overview` horizon is now green hills and far ground instead of a grey
plane (item 242, provisional **yes**). Default Pasar pad, spill and PASAR sign read well (items 208,
209, provisional **yes**). Pos Ronda tower and hut read well (item 211, provisional **yes**). Warung
(item 210) is **tunda**: `hub_warung` shot #14 is the roof at the lens. These are default-look changes
already in the build; the designer can still ask for any of them to be reverted.
