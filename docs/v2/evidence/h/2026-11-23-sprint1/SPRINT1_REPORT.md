# Sprint 1 report — 2026-11-23

SPRINT 1 (`WORK_QUEUE.md` line 12) ran items **216, 217, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207** in that order, then **S1-STOP**. Nothing from 208 onward was started; refill item 227 was not run; no new item was added. The place was not saved or published.

Every SHIPPED-state check below was run in a real fresh-Play **SERVER DataModel** in Roblox Studio. Every check was then re-run on deliberately injected bad state and observed to FAIL, so no PASS is vacuous. AFTER Play, `lune run tests/run.luau` passed at **3024 tests** and `selene src` reported **0 errors / 0 warnings / 0 filtered**. Stylua was applied to every changed Luau file. Each item was committed topically, pushed to `main`, and ticked in `WORK_QUEUE.md` and the `MASTER_PLAN.md` progress tracker in the same commit.

All verdicts in `docs/v2/visual/CANDIDATES.md` remain **pending designer review**. No visual approval was written there or anywhere else by this run. The review pack is the input to that decision, not the decision.

## Commits

| Item | Commit | Subject |
|---|---|---|
| 216 + 217 | `c0630ad` | SPRINT1 Q216+Q217: sprint cameras and visual-risk harness |
| 198 | `96fdb5b` | SPRINT1 Q198: distant mountains candidate |
| 199 | `4de5c4c` | SPRINT1 Q199: hill dressing candidate |
| 200 | `db5e860` | SPRINT1 Q200: kampung houses candidate |
| 201 | `a6f1a2d` | SPRINT1 Q201: bamboo road fence candidate |
| 202 | `901a107` | SPRINT1 Q202: night-only street lamps candidate |
| 203 | `a00a477` | SPRINT1 Q203: junction signposts candidate |
| 204 | `f10a2cd` | SPRINT1 Q204: bamboo bridge candidate |
| 205 | `4442b32` | SPRINT1 Q205: plot furrows candidate |
| 206 | `b4564e4` | SPRINT1 Q206: crop stage readability candidate |
| 207 | `07c692f` | SPRINT1 Q207: ditch water candidate |
| S1-STOP | this commit | Review pack, this report, tracker tick |

## Per item status

Status words are exactly `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`.

| Item | Status | Evidence | SHIPPED-state PASS | FAIL calibration |
|---|---|---|---|---|
| 216 | SEEN-IN-STUDIO | `CHECK_216.txt` | `CAMERA_CLEAR 0 0`, `DOCS_ONCE 0 0` (67 cameras checked) | `CAMERA_CLEAR FAIL 1 0` via `CalibrationBlocker`; `DOCS_ONCE` has no injected-bad alternative and is guarded by the per-camera clear ray plus the docs assertion |
| 217 | SEEN-IN-STUDIO | `CHECK_217.txt` | `NO_FLOATERS 0 0`, `NO_CUBE_SHRUBS 0 0`, `SIZE_SANITY 0 0`, `GOOD_SET_NONEMPTY 1`, `AUDIT_PROBE 1 1` | Three `FIXTURE_*_FAILED` lines each report ≥1 offender on a known-bad fixture, plus the calibration note spelling out the matching FAIL counts; no predicate weakened |
| 198 | SEEN-IN-STUDIO | `CHECK_198.txt` | `MOUNTAINS 6/3`, `MOUNTAIN_FAR 0/0`, `NO_COLLISION 0/0`, `PERF_BUDGET 361/500` | Three of four checks FAIL on injected bad state; `MOUNTAINS` non-vacuity covered by the 3-check set and the perf proxy |
| 199 | SEEN-IN-STUDIO | `CHECK_199.txt` | `HILL_ROCKS 5/4`, `HILL_TREES 26/12`, `WALKABLE 0/0` | All three FAIL: `0/4`, `0/12`, `-1/0` |
| 200 | SEEN-IN-STUDIO | `CHECK_200.txt` | `KAMPUNG_HOUSES 12/12`, `LANE_CLEAR 0/0`, `PATH_REACH 0/0`, `PLOT_CLEAR 0/0`, `NOT_INTERACTIVE 0/0`, `PERF_BUDGET 343/500` | All six FAIL on injected bad state; first attempt also FAILED `PLOT_CLEAR 1/0` and was fixed in source, not by weakening the check |
| 201 | SEEN-IN-STUDIO | `CHECK_201.txt` | `ROAD_FENCE 6/6`, `JUNCTION_GAPS 0/0`, `PATH_REACH 0/0` | All three FAIL: `3/6`, `1/0`, `1/0` |
| 202 | SEEN-IN-STUDIO | `CHECK_202.txt` | `LAMPS 12/12`, `LIGHT_COST 0 violations`, `LAMP_NIGHT_ONLY 12/12` | All three FAIL: `9/12`, `12 violations`, `0/12` |
| 203 | SEEN-IN-STUDIO | `CHECK_203.txt` | `SIGNPOSTS 4/4`, `SIGN_TEXT_IN_STRINGS 4/4`, `SIGN_READABLE 4/4` | All three FAIL: `3/4`, `3/4`, `0/4` |
| 204 | SEEN-IN-STUDIO | `CHECK_204.txt` | `BRIDGE_WALKABLE 0/0`, `BRIDGE_MATERIAL 0/0`, `BRIDGE_RAILS 2/2` | All three FAIL: `BRIDGE_WALKABLE 15/0`, `BRIDGE_MATERIAL 14/0`, `BRIDGE_RAILS 1/2` |
| 205 | SEEN-IN-STUDIO | `CHECK_205.txt` | `FURROWS 5/4`, `FURROW_VISIBLE 10/10`, `CROP_PLACEMENT_UNCHANGED 0/0` | All three FAIL: `0/4`, `0/10`, `1/0`; harness-only UDim2 `.Z` crash fixed before the PASS run |
| 206 | SEEN-IN-STUDIO | `CHECK_206.txt` | `CROP_STAGE_HEIGHT 0/0`, `CROP_STAGE_COLOR 0/0`, `CAMERA_SAMPLES 10/10` | Height/color FAIL on injected bad state; `CAMERA_SAMPLES FAIL 0/10` with no clusters. First run `6/10` fixed in source by one cluster per plot |
| 207 | SEEN-IN-STUDIO | `CHECK_207.txt` | `DITCH_WATER 10/10`, `DITCH_COLOR 0/0` | Both FAIL: `9/10`, `1/0` |

No item is `BLOCKED`. No item is `LUNE-ONLY` or `UNVERIFIED`.

## S1-STOP review pack

Studio was in Play with `game.Lighting.ClockTime = 13`. For each of the ten sprint candidates, the SERVER DataModel VM ran `LookDevReview.disableAll()` then `LookDevReview.enableAdditive(id, game)`; one `screen_capture` was taken from that candidate's paired review camera; then all candidates were disabled again before the next. The two baselines `spawn` and `canonical_overview` were captured with no candidate on. All twelve captures are recorded under `shots/`:

| Shot | Candidate | Review camera |
|---|---|---|
| `01_mountains_r10.jpg` | `mountains_r10` | `horizon_north` |
| `02_hill_dressing_r10.jpg` | `hill_dressing_r10` | `terrace_wall` |
| `03_kampung_r10.jpg` | `kampung_r10` | `kampung_view` |
| `04_road_fence_r10.jpg` | `road_fence_r10` | `path_curve` |
| `05_lamps_r10.jpg` | `lamps_r10` | `lamp_night` |
| `06_signposts_r10.jpg` | `signposts_r10` | `signpost_pasar` |
| `07_bamboo_bridge_r10.jpg` | `bamboo_bridge_r10` | `bridge_side` |
| `08_furrows_r10.jpg` | `furrows_r10` | `plot_aerial_01` |
| `09_crop_stages_r10.jpg` | `crop_stages_r10` | `plot_aerial_03` |
| `10_ditch_water_r10.jpg` | `ditch_water_r10` | `plot_gate_01` |
| `11_spawn.jpg` | none (baseline) | `spawn` |
| `12_canonical_overview.jpg` | none (baseline) | `canonical_overview` |

`REVIEW_SPRINT1.html` follows the round-10 review style: base64 JPEG embedded per card, width capped at 1200 px, Indonesian caption per card with the item's CHECK lines, Ya / Tidak / Tunda radio and a comment box per candidate, and a **Salin hasil** button that copies all votes as text.

Technical QA on the twelve JPGs: all twelve are real 1375×753 non-blank frames with non-trivial colour and edge variance; no black, blank, or flat-skybox capture. **Visual yes/no was deliberately not judged by this run.** The agent that inspected the files has no vision support, so subject plausibility and look quality are left entirely to the designer via the review page.

Note on `lamp_night`: the registry documents it as a name-only ClockTime 21 preset, but S1-STOP explicitly requires ClockTime 13. The pack follows the S1-STOP instruction; the lamps' light-emitting behaviour was proven separately by `CHECK_202`'s SERVER-VM `LAMP_NIGHT_ONLY 12/12`, not by this daytime capture.

## Decisions for designer

No design decision was made by this run. The points below are recorded for the designer's call.

1. **Visual verdicts on all ten candidates.** `CANDIDATES.md` rows stay pending. Use `REVIEW_SPRINT1.html` and the `shots/` captures to decide; nothing here approves a look.
2. **Item 200 fence offset.** The radial offset was reduced `4 -> 2` because the first attempt FAILED `PLOT_CLEAR 1/0` (one yard fence was 19.61 studs inside plot 1). Source fix, check unchanged. If the designer wants the wider fence back, the plot footprint or the house placement has to move instead.
3. **Item 205 surface heights.** `GROUND_Y = 0.5`, `FURROW_Y = 0.55`. The furrow sits 0.05 above soil so it reads without z-fighting. The measurement harness was also guarded against a GUI object's UDim2 `Position` (harness defect only; no shipped check weakened).
4. **Item 206 staging density.** One demo cluster per plot (30 samples / 60 Parts) after `CAMERA_SAMPLES 6/10`. A single shared cluster was occluded from five cameras. Reversible: a denser demo cluster would need extra camera clearance, not a weaker check.
5. **Item 207 ditch orientation and colour.** Strips use yaw `math.atan2(px, pz)`; teal `{r=48,g=124,b=104}` copied from `ModelMapWaterR8.variants.a`. If the designer prefers a different teal or a different strip count, this is a candidate-local change.
6. **`lamp_night` capture lighting.** Review pack uses ClockTime 13 per S1-STOP; a ClockTime 21 variant of shot 05 would need a new explicit instruction, since the item text fixed ClockTime 13 for the whole pack.

## Result

SPRINT 1 complete. All twelve work items PASS in Studio with FAIL calibration, suite and linter green, per-item commits pushed, review pack written. Per the S1-STOP instruction the run stops here.
