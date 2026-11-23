# Sprint 2 report — 2026-11-23

SPRINT 2 (`WORK_QUEUE.md` line 15) ran S items **238, 239, 240, 241, 242, 243, 244, 245**, then
Q items **208, 209, 210, 211**, then **S2-STOP**, in that order. Nothing from sprint 3 was started;
no refill item was run; no new item was added. The place was not saved and nothing was published.

Every item check below was run in a real fresh-Play **SERVER DataModel** in Roblox Studio. Each
check was re-run on deliberately injected bad state and observed to FAIL, so no PASS is vacuous.
`lune run tests/run.luau` passed at **3084 tests** and `selene src` reported **0 errors / 0 warnings /
0 parse errors**; stylua was clean on every changed/new Luau file. Each item was committed topically,
pushed to `main`, and ticked in `WORK_QUEUE.md` and the `MASTER_PLAN.md` tracker in the same commit.

All verdict cells in `docs/v2/visual/CANDIDATES.md`, `CANDIDATE_INDEX.md` and
`PROVISIONAL_VERDICTS.md` remain **pending**. No visual approval or rejection was written there or
anywhere else by this run. The review pack is the input to the designer's decision, not the decision.

## Commits

| Item | Commit | Subject |
|---|---|---|
| 238 | `c312d95` | Add HUD hide helper for review captures |
| 239 | `d59b109` | Add SUBJECT_COVERAGE check for review shots |
| 240 | `6f2ef53` | Re-aim weak sprint-1 review cameras |
| 241 | `4954d96`, `919a7f3` | Remove round melon blobs from default look (+ baked hedge shrubs) |
| 242 | `c8d5e5a` | Fill the far horizon and raise shipped haze floor |
| 243 | `a270da4` | Redo mountains_r10 as layered blue-green silhouettes |
| 244 | `737a332` | Redo hill_dressing_r10 with clustered trees, no spheres |
| 245 | `7723a68` | Build bamboo_bridge_r10 deck from bamboo culms |
| 208 | `09dc147` | Add Pasar pad and spilled lapak goods |
| 209 | `a4efdab` | Brighten Pasar stripes and add Strings PASAR board |
| 210 | `0cda8cd` | Dress Warung with seating, stove and lantern |
| 211 | `a7adb3b` | Dress Pos Ronda with kentongan, bench, lamp and rack |

## Status per item (all SEEN-IN-STUDIO)

| Item | Evidence | Main check lines |
|---|---|---|
| 238 | `CHECK_238.txt` | HUD_HIDDEN PASS 0 0; HUD_RESTORE PASS 0 0 (+FAIL cal) |
| 239 | `CHECK_239.txt` | SUBJECT_COVERAGE_FIXTURE PASS 1.0000/0.15, FAIL cal 0.0000; KAMPUNG_R10 0.4694; DITCH_WATER_R10 FAIL 0.0000 |
| 240 | `CHECK_240.txt` | six re-aimed cameras SC240_* PASS (0.6703/0.8537/1.0000/0.5882/0.9464/0.6667), CC240_* PASS 0; lamp_night ClockTime 21 |
| 241 | `CHECK_241.txt` | NO_MELONS PASS 0 0, TREE_COUNT PASS 603/450, PERF_BUDGET PASS 323/500 (+FAIL cal) |
| 242 | `CHECK_242.txt` | HORIZON_FILL PASS 190/173, PERF_BUDGET PASS 323/500 (+FAIL cal 170/192) |
| 243 | `CHECK_243.txt` | SC243_MOUNTAINS PASS 0.8736/0.10, MF/NC/NB PASS 0 0, three FAIL cals |
| 244 | `CHECK_244.txt` | HILL_ROCKS PASS 5/4, HILL_TREES PASS 13/12, WALKABLE PASS 0, NO_MELONS PASS 0 0 (+FAIL cal) |
| 245 | `CHECK_245.txt` | BRIDGE_WALKABLE PASS 0, BRIDGE_RAILS PASS 2, BRIDGE_BAMBOO PASS 1.0000/0.80, q204 regressions PASS, two FAIL cals |
| 208 | `CHECK_208.txt` | PASAR_PAD PASS 1/1, PASAR_PROPS PASS 30/30, LANE_CLEAR PASS 0, three FAIL cals |
| 209 | `CHECK_209.txt` | STRIPE_VALUE PASS 0.9255/0.6, PASAR_SIGN PASS 1/1 (id=Pasar, en=Market), LANE_CLEAR PASS 0, three FAIL cals |
| 210 | `CHECK_210.txt` | WARUNG_SEATS PASS 4/4, LANE_CLEAR PASS 0, NOT_INTERACTIVE PASS 0, three FAIL cals |
| 211 | `CHECK_211.txt` | RONDA_PROPS PASS 15/4 (4 kinds), TOWER_HEIGHT PASS 30.00/28..32, two FAIL cals |

Suite grew 3024 → 3084 across the twelve items. No item is BLOCKED.

## S2-STOP review pack

Captured in one fresh Play session, `game.Lighting.ClockTime = 13` except `lamps_r10` at **21**.
`LookDevReview.disableAll()` then `enableAdditive(id, game)` from the **SERVER** datamodel, one
candidate at a time. HUD hidden with the item-238 helper (`hideHud()` in the Client VM hid 10
ScreenGuis; `restoreHud()` restored them after the last shot). Each candidate shot's
`SUBJECT_COVERAGE` was measured in the same SERVER call via `SubjectCoverage.measure(id, camera)`
and printed on the card; baseline/default shots have no staged candidate, so their coverage card
reads `N/A (tanpa kandidat)`. Studio was returned to edit mode with all candidates disabled and the
HUD restored; nothing was saved or published.

15 JPEGs in `shots/` (1375×753 native, embedded ≤1200 px in the HTML):

| Shot | Candidate / baseline | Camera | Item | SUBJECT_COVERAGE |
|---|---|---|---|---|
| 01 | mountains_r10 | horizon_north | 243 | 0.8736 |
| 02 | hill_dressing_r10 | terrace_wall | 244 | 0.0000 |
| 03 | kampung_r10 | kampung_view | 240 re-aim | 0.6703 |
| 04 | road_fence_r10 | path_curve | 240 re-aim | 0.8537 |
| 05 | lamps_r10 (ClockTime 21) | lamp_night | 240 | 0.6667 |
| 06 | signposts_r10 | signpost_pasar | 240 re-aim | 1.0000 |
| 07 | bamboo_bridge_r10 | bridge_side | 245 | 0.0321 |
| 08 | furrows_r10 | plot_aerial_01 | r10 unchanged | 0.0115 |
| 09 | crop_stages_r10 | crop_stages_close | 240 closer | 0.5882 |
| 10 | ditch_water_r10 | ditch_water_close | 240 closer | 0.9464 |
| 11 | baseline spawn | spawn | 241 | N/A |
| 12 | baseline canonical_overview | canonical_overview | 242 | N/A |
| 13 | default Pasar | hub_pasar | 208+209 | N/A |
| 14 | default Warung | warung_seated | 210 | N/A |
| 15 | default Pos Ronda | hub_ronda | 211 | N/A |

`REVIEW_SPRINT2.html`: Indonesian captions, per-item CHECK lines, SUBJECT_COVERAGE line, Ya/Tidak/
Tunda radio, comment box and a "Salin hasil" button — same structure as `REVIEW_SPRINT1.html`.
Coverage is a measurement for the designer's eye, not a pass/fail verdict; low values (02, 07, 08)
are reported verbatim because the measure ran on the exact review camera used for the shot.

Shot scope note: the STOP rule names two baselines (spawn, canonical_overview), but items 208-211
changed the **default** look of three hubs. Three extra no-candidate cards (13-15) were added so the
designer can see those defaults; this is a net addition to the pack, not a replacement of any
required shot.

## Decisions for designer

- **Item 242 haze floor** `HORIZON_HAZE_FLOOR = 1.6` (gorge fill) is a reversible, tunable value;
  the designer may raise or lower it.
- **Item 244 rock fallback:** the item-189 baked rock models are absent and `LoadAsset` was
  unauthorized in this place, so hill rocks use Wedge/Cylinder primitives and the trees use the
  existing R4 tree models. `ASSET_MANIFEST.md` IDs are unchanged; swap in baked rocks if/when the
  asset is available in the place.
- **Item 245 straw palette** `{186,168,96}` satisfies "yellow-green to straw"; the greener
  variant is a reversible designer colour choice.
- **Item 210 NOT_INTERACTIVE** is scoped to the new `WarungDress` parts only; the pre-existing
  `WarungPrompt` on the untagged table predates this item and was intentionally preserved.
- **Item 211 TOWER_HEIGHT** is read from the staged `ronda_tower_r9` Model bbox (28..32), not the
  default greybox tower's nominal 36; `review_check_r8.luau` was left untouched.
- **lamp_night ClockTime 21** is a data field on the review camera; only shot 05 uses it.
- All verdict cells stay `pending` for the designer to fill from this pack.
