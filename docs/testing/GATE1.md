# Gate 1 — the MVP gate, working checklist

One row per criterion, taken only from `docs/v2/MASTER_PLAN.md` §4 ("Gate 1 — the MVP gate, exit
criteria") and §0 ("The quality bar"). Nothing here is invented and no two criteria are merged.
`G#` rows are the §4 gate bullets, `Q#` rows are the §0 quality bar in its own order.

**How to use it.** Work top to bottom. A row may only move off `UNVERIFIED` when the evidence named
in "How it is proven" exists as a file under `docs/v2/evidence/` (Master Plan §7, §8). Status words
are exactly the four in §7: `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`.

**Filled 2026-11-14** from evidence that already exists in the repo:

- `docs/testing/BUGS.md` (rows BUG-001…BUG-007, "Open blockers", "Studio run 2026-11-14")
- `docs/testing/HARNESS.md` §10 and its header
- `docs/v2/evidence/h/2026-11-14-phase0/REPORT.md` and `bug003-blank-place.log`
- `docs/v2/evidence/baseline/REPORT.md` and the three `phone-*.png` shots

Nothing was re-run for this checklist. A status records what the saved evidence says today, not what
the code should do. **No row is `SEEN-IN-STUDIO`** — no single criterion is met end to end by a saved
run; partial proof is named in the evidence column instead.

## Gate 1 exit criteria — MASTER_PLAN §4

| # | Criterion | How it is proven | Status | Evidence or blocker | Owner |
|---|---|---|---|---|---|
| G1 | "The MVP list in section 0 is complete and the whole quality bar in section 0 passes." | Every MVP row in §0 has its own proof, and all eight `Q#` rows above pass. This row closes last. | UNVERIFIED | Composite of the MVP table and `Q1`–`Q8`. No MVP row has an end-to-end saved run yet; see each `Q#` row for what is missing. | H |
| G2 | "`docs/testing/BUGS.md` has no open blocker or major bug." | Read the bug list; every `blocker`/`major` row is closed with evidence. | UNVERIFIED | BUG-003 `major` closed as external (`bug003-blank-place.log`); BUG-005 `major` fixed `SEEN-IN-STUDIO`; **BUG-004 is still open and `BLOCKED` on D-G3 — it now has its own table row, filed 2026-11-14 after this checklist first ran**; BUG-006/007 are `minor` and open. | H |
| G3 | "The harness plays the full beat sheet on phone size with zero Output errors or warnings." | Harness `plant`/`ready`/`harvest`/`sell`/`buy` driven through the §4 beat-sheet times at iPhone 14 size, Output copied to `output.log`. | UNVERIFIED | The loop ran twice at iPhone 14 size (`HARNESS.md` header, `h/2026-11-14-phase0/REPORT.md`), so the harness half is `SEEN-IN-STUDIO`; the **beat sheet itself was never played** (no scripted NPC raid, no rank-up ceremony, no BayarLater offer) and **no `output.log` was saved** (`HARNESS.md` §10 "Output log capture: UNVERIFIED"). Output still carries 3× the BUG-003 line. | H |
| G4 | "Nothing visible in the first ten minutes is a placeholder: no greybox part, no emoji, no missing icon, no silent action." | A phone-size pass over the first ten minutes, each frame checked against that list, shots saved. | BLOCKED — tracks C and G | `MASTER_PLAN.md` §1 states the world is still `World/Greybox.luau` and every icon, texture, sound and product ID is `0`, so the criterion is known to fail today. Track C owns the map, track G owns the icons and textures, track E owns "no silent action". No placeholder sweep is recorded in `BUGS.md`. | C + G |
| G5 | "Time to first harvest is under 45 seconds, first rarity reveal under 5 minutes, raid witnessed under 7 minutes." | Stopwatch or Output timestamps through a fresh first session at phone size, three runs. | UNVERIFIED | Never measured: `baseline/REPORT.md` says "Real-player first-ten-minutes timings: UNVERIFIED (NOT measured)". Config currently blocks it: `padi` `growSeconds` is 60 (`baseline/REPORT.md`, `src/shared/Config/Crops.luau:44-45`), so a 45 s first harvest needs a tutorial-only grow time that does not exist yet. | B + H |
| G6 | "Frame rate and instance count are measured on the phone emulator and recorded; the target is 60 fps on mid-range Android (`ART.md` §5)." | MicroProfiler or `Stats` read on the iPhone 14 emulator at the plot and at the Pasar, plus a descendant count, written into a `REPORT.md`. | UNVERIFIED | No frame-rate or instance-count number is saved anywhere in the repo (`HARNESS.md` §10 "Minigame, feel, frame rate: UNVERIFIED"; `h/2026-11-14-phase0/REPORT.md` "Not checked: … frame rate"). Needs a Studio slot (D-G2) and track H. | H |
| G7 | "Five real people play ten minutes on their own phones without help. The designer runs this. Their confusion points are fixed or logged." | Five separate humans, own phones, no coaching; confusion points logged in `BUGS.md` or fixed. | UNVERIFIED | Never run. Needs the designer plus five humans; no agent can produce this. `baseline/REPORT.md` records only the one Studio session. | designer |

## Quality bar — MASTER_PLAN §0

| # | Criterion | How it is proven | Status | Evidence or blocker | Owner |
|---|---|---|---|---|---|
| Q1 | "No blocker or major bugs known." (blocker = crash, soft lock, lost progress, lost or duplicated money or items, a core action that fails; major = anything a player notices and is annoyed by in a normal session) | Bug list contains no open `blocker`/`major` row. | UNVERIFIED | BUG-003 closed external, BUG-005 fixed (`BUGS.md` table). BUG-004 is open, `major`, `BLOCKED` on D-G3 (`BUGS.md` table row), so it alone keeps this row `UNVERIFIED`. BUG-006 (village label under the HUD) and BUG-007 (HUD language) are `minor`, open. | H |
| Q2 | "Zero errors and zero warnings in the server and client Output through a full session." | Full session, both Outputs, `output.log` saved per `HARNESS.md` §7. | UNVERIFIED | 2026-11-14 Output held "3× the BUG-003 asset line only" (`h/2026-11-14-phase0/REPORT.md`), and that line is proven external by a blank place (`bug003-blank-place.log`). **The plan has no exclusion clause**, so the bar stays formally unmet until the designer accepts the exclusion (D-G4), as that log itself says; no `output.log` file exists. | H |
| Q3 | "Every button does something, every screen can be closed, every state can be left. No dead ends: dying, resetting, rejoining mid-raid, mid-loan, mid-minigame, with a full sack, with zero cash and zero seeds all recover." | Each listed case driven once and recovered, recorded in `HARNESS.md` §10 / `BUGS.md`. | UNVERIFIED | 2 of the 8 listed cases are `SEEN-IN-STUDIO`: death (server-side kill; respawned in 5.5 s at the plot, cash 65 / `padi` 6 / tiles 6 unchanged) and login-reward recovery (65 → 165 → 155). Unproven: an explicit reset, rejoin mid-raid, mid-loan, mid-minigame, full sack, zero cash **and** zero seeds, plus the every-button/every-screen sweep. | H |
| Q4 | "Broke-player check: a player with no cash, no seeds and no crops can always get going again." | A player with zero cash, zero seeds and no planted crop gets a route back to planting, and it is recorded. | BLOCKED — D-G3 (BUG-004) | `BUGS.md` "Open blockers": BUG-004 is `BLOCKED` on decision D-G3. `DECISIONS.md` D-G3 offers the free 1 `padi` seed floor (recommended) or a second loan top-up; neither is implemented. No recovery run exists. | designer, then C |
| Q5 | "Thirty-minute soak with the harness, and a ten-player session, with no leak, no desync and no stuck state." | `HARNESS.md` §11 soak to its 1800 s deadline with the memory series and per-action counts read back, then the §2–§4 loop with ten players. | UNVERIFIED | Soak: **UNVERIFIED — started 2026-11-14, 1800 s, results pending** (`HARNESS.md` §11; no numbers recorded yet). Ten-player: not run — needs ten clients or a Studio team-test session and track H (`HARNESS.md` §10; `h/2026-11-14-phase0/REPORT.md` "Not checked: … 10-player"). | H |
| Q6 | "Persistence verified in a published test place with real DataStores, not only in Studio." | Save, leave, rejoin in a **published** place, compare cash/seeds/tiles. | UNVERIFIED | Only Studio DataStores are proven: save → stop → play → `status` gave cash 48, `padi` 6, tilesOwned 6, and `h/2026-11-14-phase0/REPORT.md` says "real Studio DataStores, not a published place". Publishing is the designer's step (`MASTER_PLAN.md` §8) and needs D-G2 for the place. | H + designer |
| Q7 | "Works on phone: touch only, small screen, mid-range device frame rate." | Played by touch on a real mid-range Android at its own frame rate, shots saved. | UNVERIFIED | iPhone 14 **emulator** render exists (`phone-01.png`, `baseline/phone-plot.png`), which covers small screen only. Touch input and real-device frame rate are untested; the harness bypasses prompts entirely (`HARNESS.md` §5 "Not covered by the harness … prompt visibility and reach"). | H + hardware |
| Q8 | "Every defect gets a regression test where the logic can be tested in Lune, before the fix is merged." | Each fixed defect names its spec; `lune run tests/run.luau` passes. | LUNE-ONLY | BUG-002 → `tests/specs/greybox_spec.luau`; BUG-005 → `tests/specs/analytics_spec.luau`; suite recorded as 495 passing (`BUGS.md` table and "Open blockers"). Not re-run by this checklist, and BUG-001 (Clouds parenting) has no named spec — it may be untestable in Lune. | H |

15 rows. 0 `SEEN-IN-STUDIO` at criterion level, 3 not `UNVERIFIED` (2 `BLOCKED`, 1 `LUNE-ONLY`).

## Left out on purpose

- §4's "Rules for the beat sheet" (no cheating instruction, server-decided guaranteed outcomes, no
  wait over ten seconds) are rules for the beat sheet, not exit criteria, so they have no row. They
  are checked by G3 and G5 when those run.
- §7's Definition of done is per task, not per gate; it is not duplicated here.

## Next three actions

1. **Designer: decide D-G3** (free 1 `padi` seed floor or loan top-up). No Studio needed and it
   unblocks the most: Q4 closes, BUG-004 gets a severity and a table row, and that in turn settles
   Q1 and G2.
2. **Track H, one Studio slot:** run `HARNESS.md` §11 to its deadline, save `output.log`, record fps
   and instance count at iPhone 14 size, then repeat §2–§4 with ten players. One session flips Q2,
   Q5, Q7, G3 and G6.
3. **Track B: tutorial `padi` grow time** — the 45 s first-harvest target cannot pass against
   `growSeconds` 60 — then a timed three-run beat-sheet pass for G5. G7 (five real players) stays
   with the designer and cannot be unblocked by an agent.
