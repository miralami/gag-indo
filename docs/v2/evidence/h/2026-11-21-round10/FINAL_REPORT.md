# Round-10 final report (2026-11-22)

**Purpose:** close `WORK_QUEUE` section N (review-prep) and hand the designer a single list of commits, per-item verdicts, blockers and open decisions.

**Scope:** section N items 107–133 (plus items 103–106 that carried into round 10), item 134 (this report), item 135 (refill, pending), and the earlier blocked carryovers 4–16. Gate 1 rows G4/Q5 are recorded as blocked designer actions.

**Status-words rule:** claim status is exactly one of `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`. Per-item PASS/FAIL/BLOCKED/PENDING is a check verdict, not a claim status; every per-item line carries both. This report is not itself evidence; each line cites a file under `docs/v2/evidence/` where one exists (audit/doc-only items cite their source doc or spec path instead).

## Commits

Newest first. All hashes verified present in `git log --oneline -40` on `track/c-world-look`.

| Commit | Items | Subject |
|---|---|---|
| `cd6f3ba` | 132, 133 | Add round-10 shot list and review cameras with full-set CAMERA_CLEAR (items 132, 133) |
| `e399ef5` | 123–131 | Complete UI audits and doc hygiene for section N (items 123-131) |
| `8777aee` | 122, 129, 130 | Add LIGHT_COST audit, rejected register and visual tracker refresh (items 122, 129, 130) |
| `d81da39` | 121 | Add subuh_r8 dawn look with monotonic and safe-range checks (item 121) |
| `9375926` | 120 | Add rain_r8 client rain and mist with emitter/gate/cost checks (item 120) |
| `7d1a98e` | 119 | Add season_r8_* client candidates with safe/restore/distinct checks (item 119) |
| `8792c33` | 118 | Add crops_showcase_r8 crop review plots with staged/camera checks (item 118) |
| `36a1256` | 117 | Add seated_r8 villagers candidate with count/bench checks (item 117) |
| `517bdc2` | 116 | Add layangan_r8 kites candidate with count/cost/string-clear checks (item 116) |
| `4f3f68d` | 115 | Add laundry_r8 hanging laundry candidate with cloth-wall clearance check (item 115) |
| `5c85da5` | 114 | Add kincir_r8 water wheel candidate with timed rotation check (item 114) |
| `3d285fd` | 113 | Add irrigation_r8 irrigation and field life candidate with water-on-terrace check (item 113) |
| `b326b7f` | 112 | Add perahu_r8 boats and river life candidate with river-clear check (item 112) |
| `0fe3a33` | 111 | Add lumbung_r8 lumbung and pekarangan candidate and fix stale Leaf material token (item 111) |
| `6a16bf2` | 110 | Add musala_r8 prayer house candidate and fix stale material token (item 110) |
| `0946818` | 109 | Add pasar_ground_r8 Pasar ground candidate (item 109) |
| `2043089` | 108 | Add lapangan_r8 village field candidate (item 108) |
| `71bf52a` | 107 | Add clean-Play smoke test and fix smoke_r8 emitter type (item 107) |
| `4159303` | 106 (BLOCKED) | Block item 106 avatar-fit audit on shipping geometry (AVATAR_FIT FAIL 2 16) |
| `5f629b2` | 105 | Record full_r9 walkability audit PASS (item 105) |

Earlier section commits (`9112e37` item 104, `5b804de` item 103, `3cbf506` items 100–101, and the round-9 range) are in the same `git log`; they are outside this report's item range.

## Per-item results

Verdict / claim status / one-line result / evidence path.

- Item 105 — full_r9 walkability audit — PASS — SEEN-IN-STUDIO — `PATH_REACH 16 16`, two deterministic runs; 13 candidates staged, anti-vacuity routes=16 parts=35949 markers=10 — `docs/v2/evidence/h/2026-11-21-round10/CHECK_105.txt`
- Item 106 — avatar scale audit with everything on — BLOCKED — BLOCKED — exact FAIL line `BLOCKED — CHECK AVATAR_FIT FAIL 2 16` (verbatim check line `CHECK AVATAR_FIT FAIL 2 16`); 2/16 then 3/16 attempts; blockers are pre-existing shipping geometry, no check weakened — `docs/v2/evidence/h/2026-11-21-round10/CHECK_106.txt`
- Item 107 — Clean-Play smoke test — PASS — SEEN-IN-STUDIO — `SMOKE_CLEAN PASS 0 0` in two 60 s windows (default look, full_r9); real `NumberSequence`→`NumberRange` emitter bug fixed, not allowlisted — `docs/v2/evidence/h/2026-11-21-round10/CHECK_107.txt`
- Item 108 — lapangan_r8 village field — PASS — SEEN-IN-STUDIO — per-kind parts match, 0/5 field-edge corridors blocked, goals 15.94–15.95 studs (ratio 2.2), restore PASS — `docs/v2/evidence/h/2026-11-21-round10/CHECK_108.txt`
- Item 109 — pasar_ground_r8 Pasar ground — PASS — SEEN-IN-STUDIO — `PASAR_PAVING 76>=60`, slab delta 0.0000≤0.15, 6-stud lane clear 0 overlaps, PFS lane PASS — `docs/v2/evidence/h/2026-11-21-round10/CHECK_109.txt`
- Item 110 — musala_r8 prayer house — PASS — SEEN-IN-STUDIO — `MUSALA_PARTS 49>=25`, door clear 0 hits, PFS spawn→approach→door PASS; CANDIDATES verdict `needs designer review: cultural content` — `docs/v2/evidence/h/2026-11-21-round10/CHECK_110.txt`
- Item 111 — lumbung_r8 and pekarangan — PASS — SEEN-IN-STUDIO — `LUMBUNG_PARTS 90>=80`, props-on-grass 0/24 over 3 yards, Ground pads byte-exact LIFO restore, PFS PASS — `docs/v2/evidence/h/2026-11-21-round10/CHECK_111.txt`
- Item 112 — perahu_r8 boats and river life — PASS — SEEN-IN-STUDIO — `PERAHU_PARTS 39>=35`, 0/39 river overlaps in the 56-stud bridge span, `BRIDGE_WALKABLE` read-only — `docs/v2/evidence/h/2026-11-21-round10/CHECK_112.txt`
- Item 113 — irrigation_r8 and field life — PASS — SEEN-IN-STUDIO — `IRRIGATION_PARTS 50>=40`, `IRRIGATION_WATER_ON_TERRACE` worst delta 0.25≤0.3 over 2 sheets, `SAWAH_TOPS` read-only — `docs/v2/evidence/h/2026-11-21-round10/CHECK_113.txt`
- Item 114 — kincir_r8 water wheel — PASS — SEEN-IN-STUDIO — `KINCIR_ROT PASS 6.0000 3..9`, real Heartbeat 6.0225°/1.024 s, 1 loop, disable 0/0/0, bank clear of bridge — `docs/v2/evidence/h/2026-11-21-round10/CHECK_114.txt`
- Item 115 — laundry_r8 hanging laundry — PASS — SEEN-IN-STUDIO — `LAUNDRY_PARTS 44>=40`, `LAUNDRY_CLOTH_CLEAR` 0 wall hits/12 cloths, synthetic overlap flagged; `CLOTH_SWAY` skipped (item 85 owns sway) — `docs/v2/evidence/h/2026-11-21-round10/CHECK_115.txt`
- Item 116 — layangan_r8 kites — PASS — SEEN-IN-STUDIO — `KITE_COUNT` 4 roots/4 Beams/4 anchors, `KITE_STRING_CLEAR` 0 building hits, `KITE_COST 0.14900<0.2 ms` — `docs/v2/evidence/h/2026-11-21-round10/CHECK_116.txt`
- Item 117 — seated_r8 villagers at the warung — PASS — SEEN-IN-STUDIO — `SEATED_COUNT` 4 real R15 rigs/4 Seats, all `Humanoid.Sit=true` after 3 s, `SEATED_ON_BENCH` 0 hits/32 probes — `docs/v2/evidence/h/2026-11-21-round10/CHECK_117.txt`
- Item 118 — crops_showcase_r8 crop review plots — PASS — SEEN-IN-STUDIO — `CROPS_STAGED` 36 Models/3 plots/306 Parts/0 state writes, `CAMERA_CLEAR` 45 cameras/0 blocked, fresh-Client `CROP_GROWTH PASS 12 12` — `docs/v2/evidence/h/2026-11-21-round10/CHECK_118.txt`
- Item 119 — season_r8_hujan/kemarau/panen — PASS — SEEN-IN-STUDIO — `SEASON_SAFE 3 3`, `SEASON_RESTORE 3 3`, `SEASON_DISTINCT 16 2`; Clouds→Client applier and puddle fallback bugs fixed — `docs/v2/evidence/h/2026-11-21-round10/CHECK_119.txt`
- Item 120 — rain_r8 rain and mist — PASS — SEEN-IN-STUDIO — `RAIN_EMITTERS 3 3`, `RAIN_OFF_CERAH 3 3`, `RAIN_COST 0.0042<0.5 ms`; stale weather token and invalid NumberSequence fixed — `docs/v2/evidence/h/2026-11-21-round10/CHECK_120.txt`
- Item 121 — subuh_r8 dawn look — PASS — SEEN-IN-STUDIO — `DAWN_PHASES_MONOTONIC 3 3`, `DAWN_SAFE 4 4`; raw-table Color3 write and float32 band endpoint bugs fixed — `docs/v2/evidence/h/2026-11-21-round10/CHECK_121.txt`
- Item 122 — lamps_shadows_r8 night light cost — PASS — SEEN-IN-STUDIO — `LIGHT_COST PASS 0 0 violations`, 13 IDs staged, totalLights=6 all `Shadows=false`/Range 14/Brightness 0.9; audit-only — `docs/v2/evidence/h/2026-11-21-round10/CHECK_122.txt`
- Item 123 — UI theme audit — PASS — LUNE-ONLY — `THEME_BYPASS` 0 exact-colour theme-token duplicates (0 before, no reduction claimed); 6 non-token radii flagged, no redesign — `docs/v2/visual/UI_THEME_AUDIT.md` (no CHECK file)
- Item 124 — phone-size UI bounds — PASS — SEEN-IN-STUDIO — 3 exact viewports, 116 GuiObjects/screen; 1 plain `AdminPanel.PanelShadow` scale bug fixed at `Admin.luau:204` and re-verified; 31 compact controls left unchanged — `docs/v2/evidence/h/2026-11-21-round10/CHECK_124.txt`
- Item 125 — contrast audit — PASS — LUNE-ONLY — `CONTRAST_AUDIT.md` recomputes ratios; 5 plain FAIL pairs fixed by better-contrast theme tokens, 3 stroke-backed labels remain (13.05:1 against `Theme.ink`) — `docs/v2/visual/CONTRAST_AUDIT.md` (no CHECK file)
- Item 126 — minimum text size — PASS — LUNE-ONLY — `TEXT_MIN_AUDIT.md` + `text_min_spec`; all under-14 px rows protected by locked designer decisions, 0 code changes, 14 px floor not applied — `docs/v2/visual/TEXT_MIN_AUDIT.md` (no CHECK file)
- Item 127 — asset manifest coverage — PASS — LUNE-ONLY — `ASSET_MANIFEST_COVERAGE`: 10 uncovered IDs appended, 24 genuinely-unused marked `unused`, 0 code IDs deleted — `docs/v2/visual/art/ASSET_MANIFEST.md` (no CHECK file)
- Item 128 — candidate catalogue — PASS — LUNE-ONLY — `CANDIDATE_INDEX.md` 95 unique IDs × 6 columns, `CANDIDATE_INDEX` spec 95/95 parity and verbatim verdicts — `docs/v2/visual/CANDIDATE_INDEX.md` (no CHECK file)
- Item 129 — rejected-candidate register — PASS — LUNE-ONLY — `REJECTED.md` exactly 31 `**no**` rows, verbatim reasons, all 20 module paths exist; no code deleted — `docs/v2/visual/REJECTED.md` (no CHECK file)
- Item 130 — visual tracker refresh — PASS — LUNE-ONLY — one dated status line per L1–L10, 10 paths verified; L1/L3/L4/L5/L6/L9 SEEN-IN-STUDIO, L2/L7/L10 UNVERIFIED, L8 BLOCKED (designer framing) — `docs/v2/visual/VISUAL_MASTER_PLAN.md` (no CHECK file)
- Item 131 — evidence index — PASS — LUNE-ONLY — `INDEX.md` 82 dated folders (57 SEEN-IN-STUDIO, 24 LUNE-ONLY, 1 BLOCKED), paths verified, no downgrades found — `docs/v2/evidence/h/INDEX.md` (no CHECK file)
- Item 132 — review shot list — PASS — LUNE-ONLY — `SHOT_LIST.md` 46 rows ordered by datamodel, verbatim enable calls, 42 unique CHECK paths cited, 0 missing; staging queue, not evidence — `docs/v2/evidence/h/2026-11-21-round10/SHOT_LIST.md` (no CHECK file)
- Item 133 — camera additions — PASS — SEEN-IN-STUDIO — 9 new MapSpec-derived cameras appended, existing 45 byte-identical, full-set `CAMERA_CLEAR PASS 0 blocked/54 checked` — `docs/v2/evidence/h/2026-11-21-round10/CHECK_133.txt`
- Item 134 — final report — PASS — LUNE-ONLY — written 2026-11-22; itself not evidence, every claim cites a cited file — `docs/v2/evidence/h/2026-11-21-round10/FINAL_REPORT.md` (this report)
- Item 135 — refill — PENDING — UNVERIFIED — not written at report time; handled in parallel by another agent, no verdict or CHECK file yet — no CHECK file

Earlier blocked carryovers are named one-by-one in the next section: 4, 5, 6, 7, 8, 9, 9b, 10b, 11, 12, 14, 15, 16 (all external assets/designer/hardware gates). Items 13, 17–19 and 100–104 were closed in earlier sections; 103/104 carry only decision notes, not blockers.

## Blocked items

Exact FAIL / reason lines, verbatim from source.

- **Item 106** — `BLOCKED — CHECK AVATAR_FIT FAIL 2 16`. Source reason (`WORK_QUEUE.md:1016–1025`): "BLOCKED — `CHECK AVATAR_FIT FAIL 2 16` (2026-11-21, fresh Play Server VM, full_r9 staged, 13/13 staged). Two FAIL attempts: (1) any-CanCollide-hit sweep 2/16; (2) >0.1-stud-penetration sweep 3/16. Anti-vacuity staged=13 folders=13 parts=35949 collidable=513 routes=16 samples=2124." Verbatim check lines in `CHECK_106.txt`: `CHECK AVATAR_FIT FAIL 2 16` (attempt 1), `CHECK AVATAR_FIT FAIL 3 16` (attempt 2). Control sweep with nothing staged gives an identical hit set; blockers are shipping geometry, not lookdev candidates.
- **Item 4** — buildings. Reason: "Ingestion needs real Open Cloud IDs, the shared Studio Importer session (D-G2) and a designer/vision verdict; no agent grades these as "good" from a text summary. No model downloaded or ID invented." (`WORK_QUEUE.md:96–100`)
- **Item 5** — vegetation (V-D4). Reason: "Candidates in `SOURCING_BUILDINGS_VEG.md` (Poly Haven CC0 + CC BY Sketchfab; padi three-stage needs step-2 generation). Same visual/session gate as item 4." (`WORK_QUEUE.md:101–103`)
- **Item 6** — props. Reason: "The ten already-imported props were audited under item 3 (`PROP_AUDIT.md`, replace verdict + ladder candidates); the wider set dressing still needs the visual verdict and Studio Importer session. No visual result claimed." (`WORK_QUEUE.md:104–107`)
- **Item 7** — textures (D18). Reason: "Download → MaterialVariant → Open Cloud upload → designer verdict still outstanding; round-2 agent-drawn textures remain rejected." (`WORK_QUEUE.md:108–111`)
- **Item 8** — NPCs/characters. Reason: "Needs real IDs, R15 validation, Studio Importer and the visual verdict. No model inserted." (`WORK_QUEUE.md:112–114`)
- **Item 9** — animations (V-D6). Reason: "(Quaternius QAL-v1.0 licence conflict flagged). Needs the shared Studio session / designer builds." (`WORK_QUEUE.md:115–117`)
- **Item 9b** — icons, improve (D18). Reason: "Blocked 2026-11-20: the 27 base IDs in `IconMap.candidateIds` are real approved Open Cloud assets; a revision needs new uploads through that same route, and this session has no upload path and no image-input/vision review. The before/after contact sheets and yes/no stay with the designer (base verdict in `CANDIDATES.md` is "yes, improve"); no ID invented and no image graded here." (`WORK_QUEUE.md:119–125`)
- **Item 10b** — day-cycle live wiring, remaining half. Reason: "Blocked 2026-11-20: no licensed real sound IDs for the five time-of-day beds exist in `Config/Audio.luau` and none may be invented; `setting_adzan` exists only as a `Strings.luau` label and `DayCycle.ADZAN_SETTING_KEY`, with no settings UI or persistence to wire; the clock/lighting grade needs a designer/vision verdict and Studio is stale (Rojo not running), so the Rendah-tier check cannot be trusted in this session." (`WORK_QUEUE.md:139–149`)
- **Item 11** — sky and fog. Reason: "Blocked 2026-11-20: the skybox needs a licensed real image/HDRI and a real Open Cloud ID (D15/D18), none of which exists in the repo or is obtainable in this session; the ridge and haze grade also need a designer/vision yes/no. No skybox ID invented and no visual claimed." (`WORK_QUEUE.md:150–153`)
- **Item 12** — spawn view. Reason: "There is still no *approved* look to combine, so the spawn camera and five shot tests stay with the designer/vision review, the fps proxy needs designer hardware, and animations (item 9) remain outstanding. The r3 `corner` candidate was rejected by the designer; `REVIEW_ROUND3.md` / `REVIEW_ROUND4.md` are inputs, not approvals." (`WORK_QUEUE.md:156–165`)
- **Item 14** — harvest/reveal/sale VFX (M2–M4). Reason: "Blocked 2026-11-20 (re-checked in item 34): neither section G nor round 4 added VFX or particle-texture assets (r4 covered textures, sky and models only), the V2 gate (VISUAL_MASTER_PLAN §V2) still requires L7.1 particle textures, and this section is explicitly "after the frame is approved", which item 12 is not." (`WORK_QUEUE.md:175–179`)
- **Item 15** — raid moment (M5) lights and police walk-in. Reason: "Blocked 2026-11-20 (re-checked in item 34): that candidate's verdict is still pending in `CANDIDATES.md`, the frame is not approved, and the raid lights (L1.3) plus the V2 clip need real assets and designer hardware. Section G added an off-by-default `day_cycle` lamp layer; round 4 added a police model inside `npcs_r4`, but it is an anchored, unrigged review dummy with a blank verdict and no animation. Still no approved moment package and no V2 clip. No visual claimed." (`WORK_QUEUE.md:180–186`)
- **Item 16** — budget and soak. Reason: "Blocked 2026-11-20 (re-checked in item 34): the registry grew from 17 to 25 off-by-default candidates in round 4 (8 new r4 candidates), but every verdict is still blank, so there are no approved visuals to turn on; the tier/fps measurement also needs the designer's phone emulator and multi-client session. The 2026-11-19 soak evidence in `docs/v2/evidence/h/2026-11-19-regression-replay/` predates the visual candidates and cannot stand for this gate." (`WORK_QUEUE.md:194–200`)
- **Gate 1 G4** — status `BLOCKED — tracks C and G`. Reason, verbatim: "MASTER_PLAN.md §1 still states the world is `World/Greybox.luau` and every icon/texture/sound/product ID is `0`, so the criterion is known to fail today. Track C owns the map (build and save the real village into `JuraganDesa.rbxl`), track G the icons/textures (Open Cloud uploads into `ASSET_MANIFEST.md`), track E "no silent action" — the audio policy/plumbing now exists (`h/2026-11-19-audio-hygiene/`) but is silent-by-design until real IDs land. No placeholder sweep is recorded in `BUGS.md`." (`docs/testing/GATE1.md:37`)
- **Gate 1 Q5** — status `BLOCKED — designer/Studio UI`. Reason, verbatim: "Ten-player half BLOCKED: Studio MCP has no local-server/team-test/multi-client tool and `start_stop_play` is Play-Solo-only (`h/2026-11-19-q5-multiclient/`); needs a designer-run Local Server + several test clients. Lune-side 10-fake-player simulation is `LUNE-ONLY` (`tests/specs/multiplayer_sim_spec.luau`). Explicit desync diff, server memory series and full multi-client `output.log` still not recorded." (`docs/testing/GATE1.md:51`)

## Decisions for designer

Consolidated; no look, balance or layout decision was made by the agent. Each entry names its source.

1. **Item 106 — corrected avatar-fit gauge and shipping geometry.** "a corrected full-route gauge — ground-based box bottom (not waypoint-centred), segment-oriented rather than world-axis-aligned, with the box size 4 x 7.25 x 4 and the target 16/16 / zero hits UNCHANGED"; and "align AgentHeight with the 7.25-stud avatar and clear or move the shipping walls/signposts/desks in a world task behind Gate 1 — not by weakening this check." Source: `docs/v2/plan/WORK_QUEUE.md` "Decisions for designer", "Round 10 item 106"; `docs/v2/evidence/h/2026-11-21-round10/CHECK_106.txt`.
2. **Item 107 — smoke allowlist scope.** Fifth allowlist entry is the pre-existing `ShippingLookR7: no PlotAnchor parts within 10 s` notice; "adding PlotAnchor parts to the dev world (a world task behind Gate 1) would let this entry be removed". Source: `docs/v2/plan/WORK_QUEUE.md` "Decisions for designer", "Round 10 item 107".
3. **Item 104 — tier-thinning interpretation / facades exemption.** Design call: "allow thinning into the protected structural sets (needs those CHECKs re-scoped), or lower the <=0.55 ceiling"; default tier stays `Tinggi`=100%, facades reported EXEMPT. Source: `docs/v2/plan/WORK_QUEUE.md` "Decisions for designer", "Round 10 item 104".
4. **Item 103 — `full_r9` additive review set, not a new LookDev ID.** "Designer call if wanted later: a first-class combined ID, which needs the IDS-count specs updated and a deliberate cross-VM staging design." Source: `docs/v2/plan/WORK_QUEUE.md` "Decisions for designer", "Round 10 item 103".
5. **UI theme — six non-token corner radii.** "The six radius literals in table (b) are the only design-owned items: `Theme.luau:285` = 3, `Phone.luau:89` = 26, `:104` = 2, `:115` = 18, `:252` = 3, `:1342` = 6. Safest reversible default: leave them as intentional special-case radii. If they should become named `Visuals.radius` tokens, that is a separate designer decision and requires updating this audit and the `THEME_BYPASS` multiset in the same change." Source: `docs/v2/visual/UI_THEME_AUDIT.md`, "Decisions for designer".
6. **Minimum text size — locked body/small vs 14 px floor.** "Raise `Visuals.type.body` from 13 to 14 and `Visuals.type.small` from 11 to 14 in `visuals_spec` if a true 14 px floor is wanted. That is a global type-scale change (18 rows above) and needs a design pass on the 22 px HUD status row, the 30 px Admin grid cell and the two 11 px phone constraints. Not done here." Also: Phone status clock 12 px / glyph mock 11 px are deliberate 22 px-row chrome; the one-line Phone title (`Phone.luau:196`, `MinTextSize=12`, `MaxTextSize=22`) needs a 375 px overflow check before raising. Source: `docs/v2/visual/TEXT_MIN_AUDIT.md`, "Decisions for designer".
7. **Contrast — three stroke-backed labels.** "`kertas` on `kertas` at `Phone.luau:400`, `kertas` on `bambu` at `Hud.luau:365` and `kertas` on `padi` at `Hud.luau:356` remain token FAILs by background, but each call site authors a `Theme.ink` `TextStrokeColor3` with `TextStrokeTransparency = 0` (Phone:407, Hud:418). Against the stroke the ratio is 13.05:1, so the text passes under the item's "or the stroke" clause. Changing the text token would fight the sticker-outline art direction; left unchanged as stroke-backed." Also "Tiles.luau:163,166,169 (world billboard labels) have no token-driven background in UI source; scoring them needs live instances and a vision pass. Not changed, not graded." Source: `docs/v2/visual/CONTRAST_AUDIT.md`, "Decisions for designer".
8. **Phone bounds — 31 compact designer controls.** "31 buttons are under 44x44 at every size ... These are deliberate compact tool/HUD controls (admin panel, perf toggles, leaderboard tabs, language chip), not plain size/anchor bugs. Repo precedent is a ONE-axis 44 px touch contract (`src/shared/PhoneLayout.luau:6-34`, locked by `ui_touch_text_audit_spec`); the item's two-axis 44x44 is stricter. Per the item's "Do not move layout the designer chose", none were resized. Decision recorded for designer." Source: `docs/v2/evidence/h/2026-11-21-round10/CHECK_124.txt`.
9. **Rejected candidates — 31 `**no**` rows to prune or keep.** "Count: **31** candidates with verdict `**no**` in the CANDIDATES.md main table. Nothing here is deleted or changed." "Designer decides what to prune; this register is informational only." Source: `docs/v2/visual/REJECTED.md`.
10. **Layer L8 camera framing.** "2026-11-22 — BLOCKED — `docs/v2/evidence/h/2026-11-17-cutscene-anchors/REPORT.md` — "Visual framing quality of the anchored shots: BLOCKED on designer"". Open sub-items V-L8.1–V-L8.4 (authored shots, impact language, hub framing help, photo mode). Source: `docs/v2/visual/VISUAL_MASTER_PLAN.md` §L8; evidence `docs/v2/evidence/h/2026-11-17-cutscene-anchors/REPORT.md`.
11. **Candidate verdicts still pending / designer review.** Verbatim verdicts needing the designer: `needs designer review: cultural content` (`musala_r8`); `pending — review in Studio` (e.g. `lumbung_r8`, `perahu_r8`, `irrigation_r8`, `kincir_r8`, `laundry_r8`, `layangan_r8`, `seated_r8`, `crops_showcase_r8`, `hubprops_r8`); `pending — listen in Studio` (`sounds`); `pending — CC0 sources are right but only trim changed; retest once round 4 applies them to ground, walls and roofs — 2026-11-20` (`textures_r3`); visual "yes/no is the designer's" for `grade_r8_a/b/c`, `night_r8`, `day_cycle_r8`, and the aural verdict for `sounds_r8`. Source: `docs/v2/visual/CANDIDATES.md`.
12. **Item 118 camera framing default.** "Designer decision: camera framing is a safe MapSpec-derived default; no screenshot claim." Source: `docs/v2/plan/WORK_QUEUE.md` item 118 Done line.

## Gates

- `lune run tests/run.luau`: final at HEAD `cd6f3ba` — **All 2872 tests passed**. Per-item counts in `WORK_QUEUE.md` rise 2687 (105/106) → 2693 (107) → 2850 (122); items 123–133 add the remainder.
- `selene src`: 0 errors / 0 warnings / 0 parse errors (0/0/0) at each item commit and at final HEAD.
- `stylua --check`: applied only to files changed by an item. Documented exception from `CHECK_124.txt`: five touched UI files are legacy CRLF and were already non-compliant at HEAD; formatting HEAD vs working tree differed only in the intended one-line edits, zero new violations; full reformat (144 unrelated lines) deliberately not done.
- `git diff --check`: clean for this report.
- HEAD `cd6f3ba`; branch `track/c-world-look`; working tree clean and in sync with `origin/track/c-world-look` (no ahead/behind). No Studio run, no visual verdict, no place save, no commit made for this report.

## Addendum 2026-11-22 — item 135 refill and N7 (post-report)

This report was written at item 134, before the item-135 refill. The lines above are the snapshot at that point (item 135 PENDING, HEAD `cd6f3ba`). The refill and its work closed afterwards, recorded here so the snapshot stays honest:

- Item 134 COMPLETE — this report. Item 135 COMPLETE — re-read `BUGS.md` (0 open defects), `GATE1.md` (all remaining rows designer/hardware), `CANDIDATES.md` (45 pending checks already PASS), `VISUAL_MASTER_PLAN.md`; queued 17 agent-closable objective doc/evidence items and named the checked file for every non-closable layer.
- N7 items 156-172 COMPLETE — 7 sourced engine-fact write-backs into `VISUAL_MASTER_PLAN.md` §11 (items 156-162; 7 answers, 21 `create.roblox.com` URLs, access 2026-11-22; what is not publicly documented is stated as such, never guessed) + 10 stale check-cell refreshes (items 163-172) in `CANDIDATES.md` and `CANDIDATE_INDEX.md`, each still starting `pending` with no visual/aural verdict granted. All cells mirror verbatim; `candidate_gallery_spec` + `candidate_index_spec` green.
- Numbering: N7 was first queued as 136-152, colliding with the pre-existing section-O items 136-155. N7 was renumbered to 156-172 (and `DOC_FACT_136..142` to `DOC_FACT_156..162`); all 171 item numbers in `WORK_QUEUE.md` are now unique, 0 duplicates. The section-O items and their code/spec/evidence references are unchanged.
- Gates after N7: `lune run tests/run.luau` All 2872 tests passed; `selene src` 0/0/0; `stylua --check` no changed Luau; `git diff --check` clean.
- Still open (unchanged, not agent-closable): carryover BLOCKED items 4-16 and 106, Gate 1 G4/Q5, the 45 designer visual/aural verdicts in `CANDIDATES.md`, and L2/L7/L8/L10 + §11 bullet 8 in `VISUAL_MASTER_PLAN.md`. No visual verdict, no place save, no publish from N7.
