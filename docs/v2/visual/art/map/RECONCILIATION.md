# Map spec vs ChatGPT full brief — decisions (2026-11-15)

`../MAP_SPEC.md` is the authority for coordinates. `full-package/` is the ChatGPT brief, kept as reference
(dressing cards, kit table, gags, social zones, build phases). Where they differ:

| # | Topic | MAP_SPEC | ChatGPT brief | Decision |
|---|---|---|---|---|
| 1 | Tengkulak Gelap | (-40,-60), dead-end alley | (-59,-55), overlaps P9 | MAP_SPEC |
| 2 | Corner hubs | (-32,-32) (34,-34) (-34,34) (34,34) | (±36,±36) | MAP_SPEC (corners r <= 66) |
| 3 | Connector ring | r=72, broken NW | r≈76, clips plot edges | MAP_SPEC |
| 4 | South road | 12 wide to bridge | ends at Lapangan, side links | Brief |
| 5 | Lapangan | 36x28 | 38x28 | Brief |
| 6 | Pos Ronda tower | (-56,-17), 16 tall | (-68,-18), 28-32 tall, clips ring | MAP_SPEC position, brief height |
| 7 | Spawn facing | north | north-northwest | MAP_SPEC |
| 8 | Plot tile size | code: 6 + 1.5 gap | 7 + 1 gap | Code (no gameplay change) |
| 9 | Sawah | 3 terraces, z -156..-180 | 4 terraces 4.5..16.5, flank Balai, 42 gap | Brief, start z -130 |
| 10 | Paddy water | thin Part | thin, not opaque plane | Same |
| 11 | River width | 16 | 20-24 | 20 |
| 12 | River depth | bed -3.5, surface -0.5 | bed -11.5, surface -3.5 | surface -3.5, bed -7.5 (inside clear envelope Y -8) |
| 13 | River centreline | sine | polyline (-200,150) (-120,146) (-40,153) (40,151) (120,143) (200,148) | Brief |
| 14 | Bridge | 8x30 | 8x36 | Brief |
| 15 | Ford | none | (-125,146), Kemarau only | Brief |
| 16 | Hills | start 200, 12-40 | start 210-230, 32-60 | Brief; sunset gap stays MAP_SPEC (west, z 35-100) |
| 17 | Season changes | overlay parts, no runtime terrain edits | voxel fill level | MAP_SPEC |
| 18 | Hub cards, kit, gags, witness bay, social zones, phases | brief | full | Brief |

To verify in code: brief says the 6 starter tiles sit as 2 columns x 3 rows nearest the gate.
Rows 4, 9, 11-16 land after the first blockout pass (they change terrain).
