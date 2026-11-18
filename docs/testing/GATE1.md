# Gate 1 — the MVP gate, working checklist

One row per criterion, taken only from `docs/v2/plan/MASTER_PLAN.md` §4 ("Gate 1 — the MVP gate, exit
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
| G2 | "`docs/testing/BUGS.md` has no open blocker or major bug." | Read the bug list; every `blocker`/`major` row is closed with evidence. | UNVERIFIED | BUG-003 `major` closed as external (`bug003-blank-place.log`); BUG-005 `major` fixed `SEEN-IN-STUDIO`; **BUG-004 now closed and `SEEN-IN-STUDIO` 2026-11-19 (D-G3 option A, `h/2026-11-19-gate1-studio/`)**. All `blocker`/`major` rows are marked fixed/closed, but BUG-008/009 (major) are only fixed at desktop size / `LUNE-ONLY` and their phone-size re-check is still open, so formal acceptance stays pending. BUG-006/007 are `minor`. | H |
| G3 | "The harness plays the full beat sheet on phone size with zero Output errors or warnings." | Harness `plant`/`ready`/`harvest`/`sell`/`buy` driven through the §4 beat-sheet times at iPhone 14 size, Output copied to `output.log`. | UNVERIFIED | The loop ran twice at iPhone 14 size (`HARNESS.md` header, `h/2026-11-14-phase0/REPORT.md`), so the harness half is `SEEN-IN-STUDIO`; the **beat sheet itself was never played** (no scripted NPC raid, no rank-up ceremony, no BayarLater offer) and only a **startup** `output.log` was saved (`h/2026-11-14-perf/output.log`, first 15 s, BUG-003 line only) (`HARNESS.md` §10 "Output log capture: UNVERIFIED"). Output still carries 3× the BUG-003 line. | H |
| G4 | "Nothing visible in the first ten minutes is a placeholder: no greybox part, no emoji, no missing icon, no silent action." | A phone-size pass over the first ten minutes, each frame checked against that list, shots saved. | BLOCKED — tracks C and G | `MASTER_PLAN.md` §1 states the world is still `World/Greybox.luau` and every icon, texture, sound and product ID is `0`, so the criterion is known to fail today. Track C owns the map, track G owns the icons and textures, track E owns "no silent action". No placeholder sweep is recorded in `BUGS.md`. | C + G |
| G4b | "All text a player sees, in the world and on the HUD, is readable at phone size: no overlapping labels, no clipped text, nothing hidden under the HUD." (added to MASTER_PLAN §4, 2026-11-14) | Phone-size pass at the plot, Pasar and warung, shots saved, every label checked. | UNVERIFIED | BUG-008 and BUG-009 filed; lane fixes in progress. Baseline shots show the defect (`baseline/phone-pasar.png`). | C + D |
| G5 | "Time to first harvest is under 45 seconds, first rarity reveal under 5 minutes, raid witnessed under 7 minutes." | Stopwatch or Output timestamps through a fresh first session at phone size, three runs. | UNVERIFIED | Never measured: `baseline/REPORT.md` says "Real-player first-ten-minutes timings: UNVERIFIED (NOT measured)". Config currently blocks it: `padi` `growSeconds` is 60 (`baseline/REPORT.md`, `src/shared/Config/Crops.luau:44-45`), so a 45 s first harvest needs a tutorial-only grow time that does not exist yet. | B + H |
| G6 | "Frame rate and instance count are measured on the phone emulator and recorded; the target is 60 fps on mid-range Android (`ART.md` §5)." | MicroProfiler or `Stats` read on the iPhone 14 emulator at the plot and at the Pasar, plus a descendant count, written into a `REPORT.md`. | UNVERIFIED | Instance counts now saved (`h/2026-11-14-perf/REPORT.md`: client 7897 descendants, PlayerGui 947), but the only fps reading (15.0, Studio unfocused) is not usable, so fps stays UNVERIFIED. Designer-reported phone play: ~30 fps at max graphics, 60 fps at lowest (`h/2026-11-14-perf/DESIGNER_PHONE_REPORT.md`, no capture, device unnamed). Before this run no number was saved anywhere in the repo (`HARNESS.md` §10 "Minigame, feel, frame rate: UNVERIFIED"; `h/2026-11-14-phase0/REPORT.md` "Not checked: … frame rate"). Needs a Studio slot (D-G2) and track H. | H |
| G7 | "Five real people play ten minutes on their own phones without help. The designer runs this. Their confusion points are fixed or logged." | Five separate humans, own phones, no coaching; confusion points logged in `BUGS.md` or fixed. | UNVERIFIED | Never run. Needs the designer plus five humans; no agent can produce this. `baseline/REPORT.md` records only the one Studio session. | designer |

## Quality bar — MASTER_PLAN §0

| # | Criterion | How it is proven | Status | Evidence or blocker | Owner |
|---|---|---|---|---|---|
| Q1 | "No blocker or major bugs known." (blocker = crash, soft lock, lost progress, lost or duplicated money or items, a core action that fails; major = anything a player notices and is annoyed by in a normal session) | Bug list contains no open `blocker`/`major` row. | UNVERIFIED | BUG-003 closed external, BUG-005 fixed, **BUG-004 now closed and `SEEN-IN-STUDIO` 2026-11-19 (`BUGS.md` table, `h/2026-11-19-gate1-studio/`)** — it no longer keeps this row open. BUG-008/009 (major) are marked fixed but the phone-size re-check is still open, so formal acceptance is pending; BUG-006/007 are `minor`. | H |
| Q2 | "Zero errors and zero warnings in the server and client Output through a full session." | Full session, both Outputs, `output.log` saved per `HARNESS.md` §7. | SEEN-IN-STUDIO | Full-session `output.log` saved (`h/2026-11-19-gate1-studio/output.log`): **zero game-code errors**. The only non-game lines are the external BUG-003 asset line (3×, proven external by a blank place, `bug003-blank-place.log`) and two Assistant-plugin version warnings. Designer decision **D-G4** (`DECISIONS.md:27`, decided 2026-11-14) accepts the BUG-003 exclusion, so the bar is met. Re-confirmed on synced code in `h/2026-11-19-gate1-sweep/`. | H |
| Q3 | "Every button does something, every screen can be closed, every state can be left. No dead ends: dying, resetting, rejoining mid-raid, mid-loan, mid-minigame, with a full sack, with zero cash and zero seeds all recover." | Each listed case driven once and recovered, recorded in `HARNESS.md` §10 / `BUGS.md`. | SEEN-IN-STUDIO | All listed cases driven and recovered. Earlier `SEEN-IN-STUDIO`: death, reset (server kill), rejoin mid-raid (fined 5000, idle/not busy after) and full-sack recovery (sell clears sack 8→0) via the gated `raid` hook (`h/2026-11-17-gate1/`, `h/2026-11-17-raid-cutscene/`); death/login-reward recovery (`h/2026-11-14-phase0/`); mid-loan recovery (borrow 375 → owed 412 → repay → active=false, `n_debt_cleared`) and zero-cash/zero-seed/no-tile recovery (`h/2026-11-19-gate1-studio/`). Closed on synced code in `h/2026-11-19-gate1-sweep/`: **mid-minigame cancel** (not reproduced — `Minigame_Cancel:FireClient` closes the scrim; BUG-013 closed, static guard `tests/specs/minigame_cancel_spec.luau`), **exact full-sack boundary** (sack at exactly 40 refuses harvest with `n_sack_full`; `pasar` sell 40→0, cash 35857→36541), **shop restock** (`n_shop_restocked`, padi 7→10, buy succeeds) and the **every-button/every-screen sweep** (749×388: phone builds with 8 apps, all pages open and close, F2 admin toggle, shop/board redirects open and close — 0 dead ends). No dead ends remain. | H |
| Q4 | "Broke-player check: a player with no cash, no seeds and no crops can always get going again." | A player with zero cash, zero seeds and no planted crop gets a route back to planting, and it is recorded. | SEEN-IN-STUDIO | D-G3 option A (free 1 `padi` seed floor) implemented in `FarmService.checkSeedFloor` (`tests/specs/seedfloor_spec.luau`, `LUNE-ONLY` regression). Verified in Studio 2026-11-19 on the live profile: cash 0 / 0 seeds / 0 tiles → exactly 1 `padi` seed, cash still 0, `n_seed_floor` notified, second call `false` — `docs/v2/evidence/h/2026-11-19-gate1-studio/` (`REPORT.md`, `results.json`). BUG-004 closed. Caveat: `checkSeedFloor` runs on join/post-harvest/post-tile-purchase, so a mid-session spend through another route is not covered until the next join/harvest. | H |
| Q5 | "Thirty-minute soak with the harness, and a ten-player session, with no leak, no desync and no stuck state." | `HARNESS.md` §11 soak to its 1800 s deadline with the memory series and per-action counts read back, then the §2–§4 loop with ten players. | UNVERIFIED | Soak half **SEEN-IN-STUDIO** 2026-11-14: 1800 s, 111 cycles, 0 stale replies, evidence `docs/v2/evidence/h/2026-11-14-soak/soak.json` (`HARNESS.md` §11). Not recorded: desync check, server memory series, full `output.log`. Ten-player half: not run, UNVERIFIED — needs ten clients or a Studio team-test session and track H (`HARNESS.md` §10; `h/2026-11-14-phase0/REPORT.md` "Not checked: … 10-player"). | H |
| Q6 | "Persistence verified in a published test place with real DataStores, not only in Studio." | Save, leave, rejoin in a **published** place, compare cash/seeds/tiles. | UNVERIFIED | Only Studio DataStores are proven: save → stop → play → `status` gave cash 48, `padi` 6, tilesOwned 6, and `h/2026-11-14-phase0/REPORT.md` says "real Studio DataStores, not a published place". Publishing is the designer's step (`MASTER_PLAN.md` §8) and needs D-G2 for the place. | H + designer |
| Q7 | "Works on phone: touch only, small screen, mid-range device frame rate." | Played by touch on a real mid-range Android at its own frame rate, shots saved. | UNVERIFIED | iPhone 14 **emulator** render exists (`phone-01.png`, `baseline/phone-plot.png`), which covers small screen only. Touch input and real-device frame rate are untested; the harness bypasses prompts entirely (`HARNESS.md` §5 "Not covered by the harness … prompt visibility and reach"). | H + hardware |
| Q8 | "Every defect gets a regression test where the logic can be tested in Lune, before the fix is merged." | Each fixed defect names its spec; `lune run tests/run.luau` passes. | LUNE-ONLY | BUG-002 → `tests/specs/greybox_spec.luau`; BUG-005 → `tests/specs/analytics_spec.luau`; BUG-001 → `tests/specs/sky_spec.luau` (fails when Sky parents Clouds under Lighting); BUG-013 (non-reproduced minigame Cancel) → `tests/specs/minigame_cancel_spec.luau` (static wiring guard); suite 1700 passing on 2026-11-19. | H |

16 rows. 3 `SEEN-IN-STUDIO` at criterion level (Q2, Q3, Q4), 2 rows not `UNVERIFIED` for other reasons (G4 `BLOCKED`, Q8 `LUNE-ONLY`), 11 `UNVERIFIED`. Q4 moved on the 2026-11-19 BUG-004 recovery run; Q2 and Q3 moved on the 2026-11-19 synced-code sweep (`h/2026-11-19-gate1-sweep/`) — Q2 via the accepted BUG-003 exclusion (D-G4), Q3 by closing mid-minigame cancel, the exact full-sack boundary/shop restock and the every-button sweep. G1 (the composite row) closes last, once every `Q#` row passes.

## Left out on purpose

- §4's "Rules for the beat sheet" (no cheating instruction, server-decided guaranteed outcomes, no
  wait over ten seconds) are rules for the beat sheet, not exit criteria, so they have no row. They
  are checked by G3 and G5 when those run.
- §7's Definition of done is per task, not per gate; it is not duplicated here.

## Next three actions

1. **Track H, one Studio slot:** Q2 and Q3 are now closed (`h/2026-11-19-gate1-sweep/`, D-G4
   accepted). Still open for the other rows: the phone-size BUG-008/009 re-check (Q1/G2/G4b),
   fps and instance count at iPhone 14 size (G6), and a timed three-run beat sheet (G3/G5). The
   30-minute soak half of Q5 is done (`h/2026-11-14-soak/`); the ten-player session still needs a
   Studio slot with ten clients.
2. **Track B: tutorial `padi` grow time** — the 45 s first-harvest target cannot pass against
   `growSeconds` 60 — then a timed three-run beat-sheet pass for G5. G7 (five real players) stays
   with the designer and cannot be unblocked by an agent.
3. **Designer:** phone-width readability of the raid lower third and the BUG-008/009 phone-size
   re-check, the fps cost table on a real mid-range phone (Q7/G6), five-player playtest (G7),
   icon uploads (track G) and published-place persistence (Q6). None of these can be produced by
   an agent.
