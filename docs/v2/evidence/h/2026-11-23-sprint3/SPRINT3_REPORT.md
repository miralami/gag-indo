# Sprint 3 report — 2026-11-23

SPRINT 3 (`WORK_QUEUE.md` line 16) ran S items **250, 251, 252, 253, 254** first, then Q items
**212, 213, 214, 215**, then section S items **246, 247**, then Q items **218, 219, 222, 223, 225**,
then **S3-STOP**, in that order. Nothing from sprint 4 was started; no refill item was run; no new
item was added. The place was not saved and nothing was published.

Every item check below was run in a real fresh-Play **SERVER DataModel** in Roblox Studio. Each check
was re-run on deliberately injected bad state and observed to FAIL, so no PASS is vacuous.
`lune run tests/run.luau` passed at **3123 tests** and `selene src` reported **0 errors / 0 warnings /
0 parse errors**; stylua was clean on every changed/new Luau file. Each item was committed topically,
pushed to `main`, and ticked in `WORK_QUEUE.md` and the `MASTER_PLAN.md` tracker in the same commit.
The final harness commit for item 222 (`f9c7fc3`) was a follow-up that only added the standalone
harness file already exercised in evidence `CHECK_222.txt`.

This run wrote **no visual verdict**. The review pack was built with all verdict cells
`pending`; no approval or rejection was written by this run. The owner's separate commit `495c474`
later recorded the designer's verdicts in `CANDIDATES.md` and `PROVISIONAL_VERDICTS.md`; that
designer decision is not part of this sprint-3 run. The pack is input to the designer, not the decision.

## Commits

| Item | Commit | Subject |
|---|---|---|
| 250 | `52dbc3a` | CAMERA_GRASS harness and camera re-aims (BLOCKED: terrace_wall under hill surface) |
| 251 | `ed20ee7` | Far rock mountains (BLOCKED: coverage above 0.6 ceiling) |
| 252 | `fa439f8` | Default bridge swap on stage (BLOCKED: bamboo deck coverage) |
| 253 | `16a6ca0` | Replace kampung ball shrubs with hedge clusters |
| 254 | `e0993bf` | Crop stages read as plants with leaf fans |
| 212/214/215 | `208606b` | River foam, terrace walls and sawah dressing in default world |
| spec fix | `3d0d266` | Register leak-sweep and strings-parity specs required by the test runner |
| 246/247 | `a711844` | Night lamp pools and golden-hour crop close-up |
| 213 | `4d37657` | Six ducks on water plus fish ripples |
| 218 | `49fd802` | Golden/night camera variants with CAMERA_CLEAR evidence |
| 222 | `211e533` | Strings id/en audit with calibration |
| 219 | `abf733e` | Chunked LOOKDEV_LEAK sweep, 119 ids zero leaks |
| 223/225 | `a3f175d` | Candidate docs parity and section-Q shot list |
| 222 harness | `f9c7fc3` | Standalone strings audit harness file |

## Status per item

| Item | Evidence | Status | Main check lines |
|---|---|---|---|
| 250 | `CHECK_250.txt` | BLOCKED | four of five re-aimed cameras PASS coverage; `CHECK CG250_HILL_DRESSING_R10 FAIL 1 0` (eye y=17.9 under hill surface y=32, eyeClearance=-14.1); two attempts, FAIL calibration PASS |
| 251 | `CHECK_251.txt` | BLOCKED | mountains far/rock-shaped PASS; `CHECK SC251_MAX FAIL 0.8157 0.6` (silhouette over coverage ceiling after two attempts), other gates PASS |
| 252 | `CHECK_252.txt` | BLOCKED | bridge swap/restore/leak/calibrations PASS; `CHECK SUBJECT_COVERAGE_252 FAIL 0.0136 0.3` (bamboo deck projects too few grid cells) |
| 253 | `CHECK_253.txt` | SEEN-IN-STUDIO | `NO_MELONS 0/0`, `SHRUB_MODELS 3/3`, `LOOKDEV_LEAK 0`, both FAIL calibrations PASS |
| 254 | `CHECK_254.txt` | SEEN-IN-STUDIO | `CROP_STAGE_WIDTH PASS 1.35 1.2`, `NO_MELONS 0`, both FAIL calibrations PASS |
| 212 | `CHECK_212.txt` | SEEN-IN-STUDIO | `FOAM_LINE PASS 1.0000 0.60`, `PERF_BUDGET PASS 100 120`, FAIL calibration PASS |
| 214 | `CHECK_214.txt` | SEEN-IN-STUDIO | `TERRACE_WALLS PASS 4/4`, `WALL_ON_TERRAIN PASS 0.0000 0.30`, float-gap direction and FAIL calibration PASS |
| 215 | `CHECK_215.txt` | SEEN-IN-STUDIO | `GUBUK PASS 4/1`, `SCARECROWS PASS 2/2`, `NO_FLOATERS PASS 0/0`, FAIL calibration PASS |
| 246 | `CHECK_246.txt` | SEEN-IN-STUDIO | `LAMP_POOL PASS 12/12`, `LIGHT_COST PASS 0/0`, `LAMP_NIGHT_ONLY PASS 12/12`, FAIL calibration PASS |
| 247 | `CHECK_247.txt` | SEEN-IN-STUDIO | `CROP_STAGE_HEIGHT 0/0`, `CROP_STAGE_COLOR 0/0`, `SUBJECT_COVERAGE_CROP_GOLDEN PASS 0.4706/0.20`, FAIL calibration PASS |
| 213 | `CHECK_213.txt` | SEEN-IN-STUDIO | `DUCKS PASS 6/6`, `DUCKS_ON_WATER PASS 0.5/0.5`, `FISH_RIPPLES PASS 4/1`, `CLIENT_ONLY_ANIM 0/0`, three FAIL calibrations PASS |
| 218 | `CHECK_218.txt` | SEEN-IN-STUDIO | 8 golden/night camera variants; `CAMERA_CLEAR_218 PASS 0 0`, `CAL_CAMERA_CLEAR_218_BLOCK PASS 1 1` |
| 222 | `CHECK_222.txt` | SEEN-IN-STUDIO | `STRINGS_BOTH_VARIANTS PASS 355/355`, `STRINGS_NEW_KEYS PASS 6/6`, `CAL_STRINGS_BOTH_VARIANTS_FAIL PASS 1 1` |
| 219 | `CHECK_219.txt` | SEEN-IN-STUDIO | all 119 ids staged+unstaged, zero signature deltas; `LOOKDEV_LEAK PASS 0 0`, `IDS_SWEPT 119/119`, `CLIENT_SKIP 0/0`, `CAL 1/1` |
| 223 | `CHECK_223.txt` | LUNE-ONLY | candidate docs parity: 24 r10 ids in both docs, `pending` verdict cells, `candidate_index_spec` 3 PASS (119/119 rows) |
| 225 | `CHECK_225.txt` | LUNE-ONLY | section-Q shot list: 19 rows covering sprint-3 candidates/cameras/datamodel/CHECK paths |

Suite grew 3084 → 3123 across the sprint. Three items are BLOCKED (250, 251, 252), each by a
single check line after two failed attempts exactly as the sprint rule requires; every other item
passes its checks with non-vacuous FAIL calibration.

## S3-STOP review pack

Captured in one fresh Play session, `game.Lighting.ClockTime = 13` except `lamps_r10` CT **21** and
`crop_stages_golden` CT **16.5**. `LookDevReview.disableAll()` then `enableAdditive(id, game)` from
the **SERVER** datamodel, one candidate at a time; baseline/default shots have no candidate staged.
HUD hidden with the item-238 helper (`hideHud()` in the Client VM hid 10 ScreenGuis — the Server VM
hid only 1, so the Client call is required for a clean capture). Each shot's `CAMERA_GRASS` was
measured in the same SERVER call via `CameraGrass.evaluate(camera.position, camera.lookAt, readColumn)`;
each candidate shot's `SUBJECT_COVERAGE` was measured via `SubjectCoverage.measure(id, camera)`.
Both lines are printed on every card. Nothing was saved or published.

Every shot under 0.15 coverage or failing `CAMERA_GRASS` was re-aimed and re-shot once before the
sheet was built; where no alternate camera fixed the failure, the card says so:

- Shot 04 `hill_dressing_r10` / `terrace_wall`: re-aim to `hill_ring_in` moved the eye above the hill
  but reduced coverage to 0.0000; kept the original camera, card records `CG250 ... FAIL 1 0`.
- Shot 05 `mountains_r10` / `horizon_north`: re-aim to `hill_ring_in` produced no projected rects;
  kept the original camera, card records `SC251_MAX FAIL 0.8157 0.6`.
- Shot 06 `bamboo_bridge_r10` / `bridge_side`: re-aim to both bank cameras still gave only 0.0494
  coverage; kept the original camera, card records `SUBJECT_COVERAGE_252 FAIL 0.0136 0.3`.
- Shot 11 `terrace_walls_214` / `sawah_below`: grass blades fill the low eye (eyeClearance=2.5,
  5/24 low-grass hits); re-aim to `sawah_above` clears grass but duplicates shot 12 and loses the
  below-view; kept the original camera, card records `CAMERA_GRASS FAIL 1 0`.

16 JPEGs in `shots/` (embedded ≤1200 px in the HTML):

| Shot | Candidate / baseline | Camera | Item | Clock | SUBJECT_COVERAGE | CAMERA_GRASS |
|---|---|---|---|---|---|---|
| 01 | road_fence_r10 | path_curve | 250 re-aim | 13 | 0.7738 | PASS 10.0 |
| 02 | ditch_water_r10 | ditch_water_close | 250 re-aim | 13 | 0.9583 | PASS 11.0 |
| 03 | crop_stages_r10 | crop_stages_close | 250+254 | 13 | 0.4706 | PASS 11.0 |
| 04 | hill_dressing_r10 | terrace_wall | 250 BLOCKED | 13 | 0.4426 | FAIL -14.1 (BLOCKED) |
| 05 | mountains_r10 | horizon_north | 251 BLOCKED | 13 | 0.8157 FAIL ceiling | PASS 76.5 |
| 06 | bamboo_bridge_r10 | bridge_side | 252 BLOCKED | 13 | 0.0136 FAIL floor | PASS 30.5 |
| 07 | kampung_r10 | kampung_view | 253 | 13 | 0.6703 | PASS 19.5 |
| 08 | default Warung | warung_seated | 210 | 13 | N/A | PASS 19.5 |
| 09 | river foam (Greybox) | bridge_north_bank | 212 | 13 | N/A | PASS 11.5 |
| 10 | animals_r8 (client-only) | bridge_south_bank | 213 | 13 | N/A | PASS 11.5 |
| 11 | terrace walls (Greybox) | sawah_below | 214 | 13 | N/A | FAIL 2.5 (BLOCKED) |
| 12 | sawah dressing (Greybox) | sawah_above | 215 | 13 | N/A | PASS 35.5 |
| 13 | lamps_r10 | lamp_night | 246 | 21 | 0.6667 | PASS 10.0 |
| 14 | crop_stages_golden | crop_stages_golden | 247 | 16.5 | 0.4706 | PASS 11.0 |
| 15 | baseline spawn | spawn | — | 13 | N/A | PASS 20.0 |
| 16 | baseline canonical_overview | canonical_overview | — | 13 | N/A | PASS 100.5 |

`REVIEW_SPRINT3.html`: Indonesian captions, per-item CHECK lines, SUBJECT_COVERAGE line,
CAMERA_GRASS line, Ya/Tidak/Tunda radio, comment box and a "Salin hasil" button — same structure as
`REVIEW_SPRINT2.html`. Coverage and grass are measurements for the designer's eye, not pass/fail
verdicts; failing values are reported verbatim because the measure ran on the exact review camera
used for the shot. Four cards (08, 09, 11, 12) show no-candidate default/Greybox looks; two (15, 16)
are the mandated no-candidate baselines.

## Decisions for designer

- **Item 242 haze floor** `HORIZON_HAZE_FLOOR = 1.6` (gorge fill) is unchanged from sprint 2 and
  remains a reversible, tunable value.
- **Item 244 rock fallback:** baked rocks absent; hill rocks use Wedge/Cylinder primitives and the
  trees use existing R4 models. `ASSET_MANIFEST.md` IDs unchanged.
- **Item 245 straw palette** `{186,168,96}` remains the reversible colour choice.
- **Item 210 NOT_INTERACTIVE** is scoped to the new `WarungDress` parts only; the pre-existing
  `WarungPrompt` was preserved.
- **Item 211 TOWER_HEIGHT** uses the staged `ronda_tower_r9` bbox (28..32), not the greybox nominal 36.
- **Item 253 shrubs:** baked shrubs are absent (`ServerStorage.LookDevAssets` had zero children;
  zero `HedgeShrubBaked`/`FloraShrubBaked`); used Wedge/Cylinder hedge clusters, no Ball, no
  `LoadAsset`, no invented IDs. Logged under `WORK_QUEUE.md` "Decisions for designer".
- **Item 254 crop stages:** leaf fans are Wedge blades + Cylinder produce, not baked assets.
- **Item 219 unauthorized asset:** `rbxassetid://13286158859` is not accessible to this place;
  `hubveg_r8`, `sawah_r8`, `river_r8` retry per clump (slow staging) but unstage with zero signature
  delta. No stub, no invented ID, no target weakened.
- **ClockTime variants:** only shot 13 uses CT 21, only shot 14 uses CT 16.5; all others CT 13.
- This run left verdict cells `pending` in the pack; the owner's separate `495c474` recorded the
  designer's sprint-2 verdicts afterwards. No verdict was written by this run.
