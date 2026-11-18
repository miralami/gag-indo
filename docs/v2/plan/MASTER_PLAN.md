# Juragan Desa — Master Plan

> Written 2026-11-14. This is the single direction for every agent working on this repo.
> It supersedes `archive/HANDOFF_ROADMAP.md` and `archive/HANDOFF_ART_PASS.md` for ordering and priorities.
> `plan/PLAN.md` stays the feature reference, `visual/ART.md` the art bible, `TECH.md` the code conventions,
> `plan/DECISIONS.md` the designer's decisions. Where this file disagrees with them on *what comes
> first* or *what counts as done*, this file wins.

## Progress tracker — read first, update last

**Last updated:** 2026-11-19 — branch `track/c-world-look` — `lune run tests/run.luau`: 1700 passing. **Gate 1 follow-ups 2026-11-19 (all `SEEN-IN-STUDIO` on synced code, Rojo `localhost:34872`, fresh VERIFY-TEMP mock profile):** real minigame `Cancel.Activated` proof — fired 1×, scrim `true→false`, PlayArea destroyed, 0 commit remotes, profile unchanged (`h/2026-11-19-cancel-proof/`); G3 full §4 beat sheet desktop, all 9 steps `ok=true`, zero game-code errors in `output.log` (`h/2026-11-19-g3-beatsheet/`); G5 three fresh desktop runs, first harvest 20/21/21 s, Super reveal ~110 s, raid gossip ~5:22 — config already meets all targets, no balance change (`h/2026-11-19-g5-timings/`). **Q5 ten-player half attempted and `BLOCKED`** — Studio MCP has no local-server/team-test tool, no scriptable substitute (`h/2026-11-19-q5-multiclient/`). G3/G5 phone halves stay `BLOCKED` on device emulation. Review finding 1 (cutscene) now `SEEN-IN-STUDIO`: raycasts of the exact `cameraFor` eye→target lines against the built world (1706 parts) found all four shots clear, but the police zoom at standOff 18 was blocked by `Tree_12.Canopy_2`; zoom standOff reduced 18→14 (largest clear value; kades clear throughout) and locked by a spec — evidence `h/2026-11-19-review-fixes/` (`REPORT.md`, `raycasts.json`). Review finding 2 (harness `force` restores `raidSafeUntil` after `RaidService.start`, never writes a zero cooldown to real save data) now `SEEN-IN-STUDIO`: fired through the real `Harness_Command` remote with a sentinel cooldown 1796000001, raid started (`incoming`, `InRaid=true`) and the sentinel + whole cooldown table were unchanged after `start` — evidence `h/2026-11-19-gate1-studio/`. That same pass closed **BUG-004**: zero-cash/zero-seed/no-tile player got exactly 1 `padi` seed, cash stayed 0, `n_seed_floor` notified (`SEEN-IN-STUDIO`); Q3 mid-loan recovery also `SEEN-IN-STUDIO` (borrow 375 → owed 412 → repay → active=false). Q2 full-session `output.log` saved (no game-code errors; only BUG-003 + Assistant warnings), now `SEEN-IN-STUDIO` after D-G4 (see sweep note at end of this line). Earlier Studio pass: BUG-011 phone, raid cutscene, Gate 1 harness/Q3 cases, perf switches + fps sampler `SEEN-IN-STUDIO` (`h/2026-11-17-phone-studio/`, `-raid-cutscene/`, `-gate1/`, `-perf-switches/`). Found + fixed BUG-012 (cash-fly `Vector2.Z` crash on sell). Added Studio-only `FpsSampler` (`ClientFps` attribute; no-op in published place). Real fps cost table on the designer phone, save repair, portrait rotation and phone-width readability still need the designer or a throwaway profile. **Synced-code sweep 2026-11-19** (`h/2026-11-19-gate1-sweep/`, Rojo on `localhost:34872`, sync confirmed inside Studio): the earlier join-bootstrap failure did not reproduce (no bug, no fix); force-raid no-save, BUG-004 and mid-loan recovery were re-confirmed; **Q2 and Q3 now `SEEN-IN-STUDIO`** — Q2 via the accepted BUG-003 exclusion (D-G4), Q3 by closing mid-minigame cancel (not reproduced — `Minigame_Cancel:FireClient` closes the scrim; BUG-013 closed, static spec `minigame_cancel_spec.luau`), the exact full-sack boundary/shop restock and the every-button/every-screen sweep (749×388, 0 dead ends). Q3 drove UI with `GuiService.SelectedObject` + keyboard Return; `user_mouse_input` did not activate buttons. The older unsynced pass `h/2026-11-19-gate1-studio/` is superseded on those two observations; its `output.log` remains the Q2 evidence. Place never saved or published; no `profile:Save()`; throwaway profile restored; all `__Verify*` probes removed.

**Long-run 2026-11-19 — WORK_QUEUE item 1 (`LUNE-ONLY`):** added `tests/specs/multiplayer_sim_spec.luau`
(9 cases) — ten interleaved Fakes players on the real Economy/Market/Debt, Raid and Farm services;
per-player cash/item/tile/debt/raid isolation, finite non-negative cash, no duplicated seeds, no
stuck raid or minigame state, no leak. No defect found, so no production fix needed. Suite 1709.
This is the scriptable Lune half of Q5; the live ten-client session stays `BLOCKED` on the designer
(`h/2026-11-19-q5-multiclient/`).

**Long-run 2026-11-19 — WORK_QUEUE item 2 (`LUNE-ONLY`):** full remote-handler security re-pass —
all 48 `OnServerEvent`/`OnServerInvoke` connections reviewed, every C->S remote validated/rate-limited/
guarded with a failure-path spec; closed the sole gap with `tests/specs/state_request_failure_spec.luau`.
No production fix needed. Results/coverage map in `docs/testing/CODE_AUDIT.md`. Suite 1712.

**Rules for this section.** Every agent reads it before touching the repo, so nobody has to rediscover
the state from scratch. Whoever finishes a task ticks it here **in the same commit**, adds its status
word (§7) and an evidence path, and bumps the "Last updated" line. `[x]` = done with evidence,
`[~]` = partly done (say what is missing), `[ ]` = not started. Never tick without evidence. The
gate rows' full detail stays in `docs/testing/GATE1.md`; defects stay in `docs/testing/BUGS.md`.

**Visual direction:** `docs/v2/visual/VISUAL_MASTER_PLAN.md` (written 2026-11-16, D14: aim realistic, land believable) plans light, materials, models, VFX, camera and UI fidelity in phases V0–V4 with its own tracker. It sits under this file; nothing in it is built yet (`UNVERIFIED`).

### Next up (recommended order)

Handoff 2026-11-17: the code-only frontier is mostly done (failure-path specs for every server service, save repair, fidelity tiers, raid cutscene, lazy phone). The bottleneck is now Studio, which was closed all session, so the many `LUNE-ONLY` items below are untested in play.

1. **Studio pass first (main session only, needs Studio open):** BUG-011 done `SEEN-IN-STUDIO` 2026-11-17 (mount, first-tap build, app open, ID/EN, landscape; `docs/v2/evidence/h/2026-11-17-phone-studio/`). Still to do in this order —
   - ~~BUG-011: phone mounts / build / apps / rotation / ID/EN.~~ Done except portrait rotation (`LUNE-ONLY`; viewport cannot be changed via MCP).
   - ~~Raid cutscene: camera hand-back / FOV / BREAKING NEWS / 20 s window.~~ Done `SEEN-IN-STUDIO` 2026-11-17 via a gated `raid` harness hook (`docs/v2/evidence/h/2026-11-17-raid-cutscene/`); phone-width readability of the lower third still needs the designer's device (emulator cannot be set via MCP).
   - `FidelityTier` attribute switches live; admin perf switches toggle and restore; record fps per switch on the designer phone (V0.2 cost table).
   - ~~Save repair warns once on a damaged profile.~~ Left `LUNE-ONLY` (`tests/specs/save_reconcile_spec.luau`): driving the real load path needs a throwaway DataStore profile with corrupted fields, which would touch real save data in the dev place; not safe to force from the harness. The warning text and once-only count are proven in Lune; a real damaged-profile load stays a designer/test-place task.
   - Portrait rotation: left `LUNE-ONLY` (`tests/specs/phone_layout_spec.luau`); the Studio MCP cannot change `Camera.ViewportSize`/device orientation, so only the landscape structure was observable in play.
   - ~~Then the Gate 1 rows in `docs/testing/GATE1.md` (Q3 dead ends).~~ Q3 closed `SEEN-IN-STUDIO` 2026-11-19 on synced code (`h/2026-11-19-gate1-sweep/`): mid-minigame cancel not reproduced, exact full-sack boundary/shop restock and every-button sweep all driven, 0 dead ends. Q2 closed the same day via D-G4. G3 beat sheet and G5 timings now proven at desktop size (`SEEN-IN-STUDIO`, `h/2026-11-19-g3-beatsheet/`, `h/2026-11-19-g5-timings/`); their phone-size halves remain `BLOCKED` on device emulation. Still open (all designer-side): phone-size BUG-008/009 re-check (G4b), fps (G6), ten-player session (Q5, `BLOCKED`, `h/2026-11-19-q5-multiclient/`).
2. **F — raid cutscene framing:** after a review finding, anchors moved off the MapSpec hub centres onto the NPC front spots (Pak RT 68/47, Polisi -68/42) at head height, and a pure `RaidCutscene.cameraFor` places the eye on the -z front side outside all six hub footprints; `RaidOverlay.placeCamera` consumes it. Line of sight `SEEN-IN-STUDIO`: raycasts of the exact `cameraFor` eye→target lines against built geometry cleared all four shots; zoom standOff 18→14 because the police shot at 18 was blocked by `Tree_12.Canopy_2` (10/12/14 clear, 16+ blocked) — `h/2026-11-19-review-fixes/`. Framing composition and the police NPC walk-in remain `BLOCKED` on the designer's look-dev pass + authored NPC animation (visual plan §8; cannot read captures).
3. **G — icon upload (designer/Open Cloud):** `BLOCKED` on designer. All `IconMap.luau` slots are `id=0 / NEEDS-ASSET`, no final icon art exists (only mockup PNGs in `visual/mockups/src/icons/`), and asset IDs must never be invented. Designer uploads (landing in their inventory) then fills IDs in `IconMap.luau` + `ASSET_MANIFEST.md`.
4. **V0.3–V0.5:** `BLOCKED` on designer — reference board needs designer/CC0 photos (V-D5 open), look-dev corner needs the designer's visual judgement, and V-D1..V-D5 answers are not in `DECISIONS.md` yet.
5. **Bugs:** BUG-004 **closed** — D-G3 option A (free-seed floor) implemented and now `SEEN-IN-STUDIO`: zero cash + zero seeds + no tiles → exactly 1 `padi` seed, cash still 0, `n_seed_floor` notified; once-per-session guard held (`h/2026-11-19-gate1-studio/`, re-confirmed in `h/2026-11-19-gate1-sweep/`). BUG-013 **closed — not reproduced**: the 2026-11-19 minigame-Cancel report was an unsynced-source artifact; on synced code the real `Cancel.Activated` closes the scrim with 0 commit remotes and an unchanged profile (`h/2026-11-19-cancel-proof/`), wiring locked by `tests/specs/minigame_cancel_spec.luau`. Join bootstrap was likewise never broken (`Main.server.luau:95/101`) — no bug row.
6. **H — harness force raid no longer writes save data:** `force` used to leave `data.cooldowns.raidSafeUntil = 0` on the live profile. `RaidTrigger.withTemporaryCooldown` restores the exact old cooldown table/value after `RaidService.start` on success and error (specs `LUNE-ONLY`, `raid_trigger_spec`), and is now `SEEN-IN-STUDIO`: with the synced modules driven through the real `Harness_Command` remote and a sentinel cooldown 1796000001, the raid started and the whole cooldown table was unchanged afterwards — `h/2026-11-19-gate1-studio/results.json`, re-confirmed in `h/2026-11-19-gate1-sweep/results.json`. Q3 mid-loan recovery (borrow → repay clears debt) also `SEEN-IN-STUDIO` there; mid-minigame cancel now **not reproduced / closed** (BUG-013) on synced code — `Minigame_Cancel:FireClient` closes the scrim, static guard `tests/specs/minigame_cancel_spec.luau`.

### Phase 0 — repo safe for parallel work

- [x] 0.1 Working tree committed in topical commits.
- [x] 0.2 Studio failures: BUG-001, BUG-002 fixed `SEEN-IN-STUDIO`; BUG-003 is external, excluded by D-G4.
- [x] 0.3 Playtest harness — `docs/testing/HARNESS.md`.
- [x] 0.3b Bug sweep — `docs/testing/BUGS.md`.
- [x] 0.4 Baseline — `docs/v2/evidence/baseline/`.
- [x] 0.5 Tool pipeline — `plan/TOOLS.md`, D-G1 decided; Open Cloud key exists and introspects valid 2026-11-14 (user env var `ROBLOX_API_KEY`, scopes include `asset` read/write). Shells started before it was set see it empty: read it from the User environment or restart.

### Gate 1 at a glance (detail: `docs/testing/GATE1.md`)

- [x] G2/Q1 no open blocker or major bug — all defects BUG-001 through BUG-010 addressed; BUG-003 closed external (`SEEN-IN-STUDIO`).
- [~] G3 harness plays the full beat sheet at phone size — desktop half `SEEN-IN-STUDIO` 2026-11-19 (all 9 §4 steps, `h/2026-11-19-g3-beatsheet/`); phone-size half `BLOCKED` on designer device emulation.
- [ ] G4 nothing visible is a placeholder — icons are letters, NPCs are boxes, most actions are silent.
- [~] G4b text readable at phone size — signs on boards, HUD and phone checked at iPhone 14 (`evidence/h/2026-11-14-audit-fixes/`); app pages updated with 44x44 touch targets.
- [~] G5 first harvest < 45 s, first reveal < 5 min, raid < 7 min — desktop timings `SEEN-IN-STUDIO` 2026-11-19: 3 fresh runs 20/21/21 s, Super ~110 s, raid ~5:22 (`h/2026-11-19-g5-timings/`); config already meets all targets, no change. Tier guarantee `LUNE-ONLY` (`first_session_spec.luau`); phone-size half `BLOCKED` on designer device emulation.
- [~] G6 fps and instance count — instance count saved; Studio-only `ClientFps` sampler works (~60 unfocused, no per-switch delta; `h/2026-11-17-perf-switches/`); designer phone ~30 fps at max, 60 at lowest; real mid-range fps still a designer task.
- [ ] G7 five real people, own phones (designer).
- [x] Q3 no dead ends — `SEEN-IN-STUDIO`: death, reset, rejoin mid-raid, full-sack sell recovery via the gated raid hook (`h/2026-11-17-gate1/`); mid-loan recovery and zero-cash/zero-seed/no-tile recovery (`h/2026-11-19-gate1-studio/`); mid-minigame cancel (not reproduced, BUG-013 closed), exact full-sack boundary/shop restock and every-button/every-screen sweep — 0 dead ends (`h/2026-11-19-gate1-sweep/`).
- [x] Q2 zero errors/warnings — `SEEN-IN-STUDIO`: full-session `output.log` with zero game-code errors (`h/2026-11-19-gate1-studio/output.log`) plus the accepted BUG-003 exclusion (D-G4, `DECISIONS.md:27`).
- [~] Q5 soak — 30-min client soak done (`SEEN-IN-STUDIO` 2026-11-14); ten-player session attempted 2026-11-19 and `BLOCKED` — Studio MCP has no local-server/team-test tool (`h/2026-11-19-q5-multiclient/`); needs a human at the Test tab.
- [ ] Q6 persistence in a published place.
- [ ] Q7 touch on a real mid-range phone.

### Tracks

**A. Game feel**
- [~] Crop growth stages (bibit / tumbuh / siap) exist in `FarmService`; not judged by a human.
- [x] Plant, harvest, sell feedback: particles, tweens, camera nudge, cash-fly — `LUNE-ONLY`, `tests/specs/feel_spec.luau`.
- [x] Rarity reveal: toast tint, Sultan/Langka shake, sting hooks, ActionFeel — `LUNE-ONLY`, `tests/specs/feel_spec.luau`.
- [~] First tier consumers: ActionFeel bursts scale count and lifetime (never below 1 particle), Wind sways only within the tier range with a fade — `LUNE-ONLY`, `src/client/Feel/TierScale.luau`, `tests/specs/tier_consumers_spec.luau`; not seen in Studio.
- [~] V0.2 admin perf switches (Highlights, shadows, bloom, terrain decoration, particles; local, reversible) in the admin panel with the live tier — panel structure + live tier seen in Studio; shadows/decoration toggle and restore `SEEN-IN-STUDIO` (all 5 states restore, `h/2026-11-17-perf-switches/`); `src/client/Feel/PerfSwitches.luau`, `tests/specs/perf_switches_spec.luau`. Studio-only `FpsSampler` publishes `ClientFps` (`tests/specs/fps_sampler_spec.luau`); Studio readings ~60 with no per-switch delta, real cost table still a designer-phone task.
- [~] V0.1 `FidelityTier` tier selection (Rendah/Sedang/Tinggi, fast down, slow up, frozen in hook moments, §6 settings table) — `LUNE-ONLY`, `src/client/Feel/FidelityTier.luau`, `tests/specs/fidelity_tier_spec.luau`; wired live by `src/client/Feel/FidelityRuntime.luau` (Heartbeat feed, `FidelityTier` player attribute, `tests/specs/fidelity_runtime_spec.luau`); no visual reads the tier yet, no settings toggle, rarity reveal and raid overlay freeze the tier via `src/client/Feel/MomentGuard.luau` (`tests/specs/hook_moment_spec.luau`), thresholds unmeasured on a phone, not seen switching in Studio.

**B. First session**
- [x] Four-step tutorial (plant, harvest, sell, buy) — `SEEN-IN-STUDIO` via harness.
- [x] Next Goal card after the tutorial (next rank, then daily tasks) — `SEEN-IN-STUDIO` desktop, `src/shared/NextGoal.luau`.
- [x] Broke-player seed floor (BUG-004, D-G3) — now `SEEN-IN-STUDIO` (2026-11-19, `h/2026-11-19-gate1-studio/`); regression `tests/specs/seedfloor_spec.luau`.
- [x] Tutorial padi ~20 s, first session only — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] Guaranteed Bagus on first harvest, Super/Langka on the second — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] BayarLater loan offer beat (~2:30) — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] Scripted NPC neighbour raid as a spectator (~5:30) — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] Warung rumour / Tengkulak whisper (~7:00) — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] Rank-up ceremony to Petani (~9:00) — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] Explain "Sus" the first time it changes (keep the word; it is satire) — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.
- [x] Analytics funnel step per beat — `LUNE-ONLY`, `tests/specs/first_session_spec.luau`.

**C. World** (art direction: **cartoonish realism**, D11 — chunky shapes, Roblox textured materials; reference: the Warung)
- [x] Hub buildings, trees, decor, flora, shelf goods, hills — `SEEN-IN-STUDIO` desktop.
- [x] Hub names painted on sign boards (BUG-008) — `SEEN-IN-STUDIO` desktop.
- [~] 9.5-stud headroom in all six hubs - `MapSpec.HEADROOM` set to 9.5 and asserted across all six hubs in `tests/specs/greybox_spec.luau` (`LUNE-ONLY`); only the Warung photographed in Studio.
- [x] Spawn composition: the player spawns facing a tree trunk; frame plot, NPC and hub instead (spawn finalised from `src/server/World/MapSpec.luau`, `LUNE-ONLY` in `greybox_spec`) — `LUNE-ONLY`, `tests/specs/greybox_spec.luau`.
- [x] Golden-hour look: clock 16:00-17:00, warm golden senja atmosphere, sunset skybox, and realistic background pine forest leaving sunset corridor clear; golden-hour window and three season preset ids finalised in `src/server/World/MapSpec.luau` (`LUNE-ONLY`, `tests/specs/greybox_spec.luau`) + existing Studio evidence in `docs/v2/evidence/c/2026-11-14-world-look/REPORT.md`.
- [x] Terrain grass decoration: `Terrain.Decoration = true`, road painted Ground material to prevent blade clipping — `SEEN-IN-STUDIO`, `docs/v2/evidence/c/2026-11-14-world-look/REPORT.md`.
- [x] Terrain tops out on the 0.5 gameplay plane instead of burying it — `SEEN-IN-STUDIO` (live raycasts: 0.500 at every grid and key point, idempotent over three runs); screenshots `BLOCKED` (this model cannot save or read viewport captures), `docs/v2/evidence/c/2026-11-15-terrain-fix/REPORT.md`.
  - Note: **a place's terrain can be older than the source that made it.** `Greybox.applyTerrain` always clears the whole 400×16×400 village band (Y −8…8) with Air before filling, so a slab from an earlier generator cannot survive under a rebuild. Smooth Terrain's visible top face is `regionTop + 2` for a 4-stud voxel, not a whole-voxel snap.
- [x] Map spec written (layout, hubs, plots, terrain, scale): `docs/v2/visual/art/MAP_SPEC.md`, art reference `docs/v2/visual/art/map/` — `UNVERIFIED` until built in Studio.
- [x] World at S=2: Rumah Pak RT as scale reference, all hubs, plots (r 192), roads, river, 4 sawah terraces, hills, spawn from `MapSpec.luau` — `SEEN-IN-STUDIO` numerically (grid 0.5 over 1014 points, 0 holes; 10 plots, 6 hubs, spawn); `LUNE-ONLY` specs; screenshots by the designer only. Terrace tops exactly 4.5/8.5/12.5/16.5 live (0 bad of 80 samples).
- [~] Terraced sawah and river: built from `MapSpec.luau`, 4 terraces exact and river water live (`SEEN-IN-STUDIO` numerically, `evidence/c/2026-11-15-terrain-fix/` style probes); three season presets not re-tuned yet, no photo.
- [ ] `Greybox.luau` retired to a test fallback.

**D. UI**
- [x] HUD readable, stats under the top bar (BUG-009) — `SEEN-IN-STUDIO` desktop.
- [x] Phone is the single control panel (Seed Shop and Leaderboard are apps; device look; landscape on short screens) — `SEEN-IN-STUDIO` desktop and iPhone 14.
- [x] Seed bar shows only owned or selected seeds, centred — `SEEN-IN-STUDIO`.
- [~] Cabai banner gold with countdown — `LUNE-ONLY` (event not seen running).
- [x] App pages (Report, Farm, Loan, Quests, Cheat, Decor) at phone size and with real taps — `LUNE-ONLY`, `src/client/UI/Phone.luau`, `src/shared/PhoneLayout.luau`, `tests/specs/phone_layout_spec.luau`.
- [x] Stats panel as icon chips (cash first, sack, Sus, Nama Baik) — `LUNE-ONLY`, `src/client/UI/Hud.luau`.
- [x] D6: Indonesian default plus a language picker (today only `Strings.langFor`); closes BUG-007 — `LUNE-ONLY`, `src/client/UI/Hud.luau`.
- [x] BUG-006 world label under the HUD panel — `LUNE-ONLY`, `src/client/UI/Hud.luau`.
- [x] Phone app pages build on open and are destroyed on leave/close (`src/client/UI/LazyPages.luau`, `tests/specs/lazy_pages_spec.luau`); BUG-011 fixed — `SEEN-IN-STUDIO` 2026-11-17: first tap builds the device frame, home grid and all 8 app tiles (lazy), `App_phone` opens `PagePhone` and hides home, ID→EN switches tile labels, landscape applies on the short viewport; Output clean except external BUG-003 (`docs/v2/evidence/h/2026-11-17-phone-studio/`). Portrait rotation and the other 7 app pages remain `LUNE-ONLY`.
- [ ] Fonts chosen on a phone (§9.3).

**E. Audio**
- [x] Village music, Pasar music, day ambience — `SEEN-IN-STUDIO`, `art/ASSET_MANIFEST.md`.
- [x] UI sounds, tier stings, raid sting, rain and night ambience — `SEEN-IN-STUDIO`, `art/ASSET_MANIFEST.md`.

**F. Characters and cutscenes**
- [~] Caricature NPC framework from design cards (Pak RT/Tengkulak/Polisi archetype data and fictionality markers) — `LUNE-ONLY`, `src/shared/Config/NpcArchetypes.luau`, `tests/specs/npc_framework_spec.luau`; visual models/rigs still pending.
- [~] Raid cutscene timeline (establish, triple zoom, police walk-in, letter; 7.0 s; skippable after the first viewing via client attribute `RaidCutsceneSeen`) — `LUNE-ONLY`, `src/client/Feel/CutsceneSequencer.luau`, `src/shared/Config/RaidCutscene.luau`, `tests/specs/cutscene_sequencer_spec.luau`; wired into `src/client/UI/RaidOverlay.luau` (Scriptable camera restored on finish/skip/cancel/death, `CameraFeel.pause/resume`, BREAKING NEWS lower third `raid_lower_third`, decisions in `src/client/Feel/CutsceneState.luau`); server `RaidService.INCOMING_SECONDS` now matches the cutscene so the 20 s choice window is intact. Camera hand-back on finish/skip/death/Raid_End, FOV ease (26→72), BREAKING NEWS bar and the full 20 s choice window now `SEEN-IN-STUDIO` 2026-11-17 via a gated `raid` harness hook (`docs/v2/evidence/h/2026-11-17-raid-cutscene/`). Real `focusAnchors` + `anchorFor` resolver wired into `placeCamera` (`LUNE-ONLY` + data/structure `SEEN-IN-STUDIO`, `h/2026-11-17-cutscene-anchors/`); 2026-11-18 anchors corrected to the NPC front spots (Pak RT 68/47, Polisi -68/42, head height) and a pure `RaidCutscene.cameraFor` places the eye on the -z front outside all six hub footprints; 2026-11-19 zoom standOff 18→14 (police at 18 was occluded by `Tree_12.Canopy_2`); eye→target line of sight for all four shots `SEEN-IN-STUDIO` (`h/2026-11-19-review-fixes/raycasts.json`). Framing quality and the police NPC walk-in still `BLOCKED` on the designer's look-dev pass + authored NPC asset/animation (visual plan §8).
- [~] Raid and debt-collector cutscene state/event hooks (logic only) — `LUNE-ONLY`, `src/server/Npc/CutsceneHooks.luau`, wired in `src/server/Law/RaidService.luau` and `src/server/Economy/DebtCollector.luau`; full sinetron presentation still pending.

**G. Asset pipeline**
- [x] Asset manifest started.
- [x] Open Cloud key — verified by introspection 2026-11-14 (`ROBLOX_API_KEY`, never committed or printed).
- [~] Icon set (crops, tools, tiers, currency, phone apps); 6–8 hero textures. — code-side icon slot map and HUD/Phone/seed-bar wiring done (`LUNE-ONLY`, `src/shared/IconMap.luau`, `tests/specs/iconmap_spec.luau`, slot IDs empty / `NEEDS-ASSET`); upload and filled IDs still pending.

**H. QA and integration**
- [x] Thirty-minute client soak — `evidence/h/2026-11-14-soak/`.
- [x] Quest and Raid failure-path specs; fixed NaN progress completing quests, NaN login streak burning the daily claim, raid start/leave erroring on saves without `cooldowns`/`stats` — `LUNE-ONLY`, `tests/specs/quest_failure_spec.luau`, `tests/specs/raid_failure_spec.luau`.
- [x] Worker, Storage and Cheat failure-path specs; fixed NaN cash letting the buruh harvest and `trySpend` succeed, fractional/infinite gudang capacity, withdraw losing items when the sack table is missing, curi_air erroring without `cooldowns` — `LUNE-ONLY`, `tests/specs/worker_failure_spec.luau`, `tests/specs/storage_failure_spec.luau`, `tests/specs/cheat_failure_spec.luau`.
- [x] Evidence, Plot, Warung and Neighbor failure-path specs; fixed reports/cheat logs erroring without `cooldowns`/`stats`, tile prompt erroring on a save with nil `tilesOwned` or `tiles`, Nama Baik staying NaN and water erroring without `cooldowns` — `LUNE-ONLY`, `tests/specs/evidence_failure_spec.luau`, `tests/specs/plot_failure_spec.luau`, `tests/specs/warung_neighbor_failure_spec.luau`.
- [x] Save repair on load: `src/server/Data/SaveSanitize.luau` runs after Reconcile and migration, resets wrong-typed or NaN/inf template fields (one level into known tables), keeps dynamic keys and negative cash, warns once with the count — `LUNE-ONLY`, `tests/specs/save_reconcile_spec.luau`; not seen on a real damaged profile. Reason: forcing it would need a throwaway DataStore profile with corrupted fields (real save data in the dev place); the once-only warning is proven in Lune, the real load is a designer/test-place task.
- [x] Sus, Almanak, Season, Admin, Cosmetics and Leaderboard failure-path specs; fixed NaN Sus spreading through get/add/reduce, Almanak throwing on a damaged entry or string trait list, admin `grantItem` writing unknown item ids, Cosmetics erroring without `cosmetics`/`equipped`, a failed leaderboard read blanking the last good board — `LUNE-ONLY`, `tests/specs/sus_almanak_failure_spec.luau`, `tests/specs/season_admin_failure_spec.luau`, `tests/specs/cosmetics_leaderboard_failure_spec.luau`.
- [x] Receipts, Onboarding, Tool, Items, Cabai, Badges and Passes failure-path specs; fixed a receipt being acknowledged for an unknown grant type or a missing PurchaseId, ProcessReceipt erroring on a damaged `receipts` table, NaN item counts being spendable, ToolService erroring on a non-table `tools`, CabaiEvent starting twice — `LUNE-ONLY`, `tests/specs/onboarding_receipts_failure_spec.luau`, `tests/specs/tool_items_failure_spec.luau`, `tests/specs/events_badges_passes_failure_spec.luau`.
- [x] Strings integrity (every key has id and en, matching placeholders, every referenced key and `@key` exists) and config cross-reference specs; no defects found — `LUNE-ONLY`, `tests/specs/strings_integrity_spec.luau`, `tests/specs/config_crossref_spec.luau`.
- [~] Full-session `output.log` captured (`h/2026-11-19-gate1-studio/output.log`, zero game-code errors; Q2 still `UNVERIFIED` pending D-G4); fps on the phone emulator, ten-player session and published-place persistence still open.
- [ ] Five real players (designer).

### Parked for Phase 2 (do not start before Gate 1)

- Crop economy has no trade-off: profit per minute per tile rises in a straight line (padi 8 → sawit 96); only the cabai x3 event creates a choice. Needs the balance simulation (§6).
- Outside-audit ideas (gotong royong, koperasi, pasar mingguan, proyek desa): see `docs/improvements/SINTESIS.md` §4.

## 0. The one rule above all others

**It has to be a game.** Playable, fun, solid, tested, with no stupid bugs: an actual product a
stranger can pick up and enjoy. A small game that works beats a big one that does not. Every
other section of this plan is in service of this, and when anything conflicts with it, this wins.

### The MVP

The MVP is the smallest version of Juragan Desa that is a complete, fun game on its own. It must
exist and be solid before anything else is added.

| In the MVP | Must be true |
|---|---|
| Core loop: plant, grow, harvest, sell, buy seeds, expand the plot | Works every time, on phone and desktop, alone or with ten players. Feels good. |
| Rarity reveal | Every tier shows correctly; the top tiers are a moment. |
| One real village | Built map, lighting, icons, sound. No placeholder visible. |
| Progression: ranks, tools, gudang, daily tasks | Always a clear next goal for at least the first few hours. |
| The satire core: cheating, Sus, raid, bribe, BayarLater and the debt collector | Each works start to finish and is funny. |
| First session (section 4) | A stranger finishes it without help. |
| Saving | Progress survives leaving, rejoining, crashing and server shutdown. |

**Anything not on this list, and anything on it that is not solid, is switched off** behind a
LiveConfig flag until it is. A feature that half works is hidden, not shipped. Existing systems
that are outside the MVP (seasons effects, market pressure, buruh, almanak, leaderboards,
cosmetics, passes) stay in only if they pass the bar below; otherwise they are flagged off and
come back one at a time.

### The quality bar

A build is a product only when all of these hold. Track H checks them and nobody overrides them.

1. **No blocker or major bugs known.** Blocker: crash, soft lock, lost progress, lost or duplicated money or items, a core action that fails. Major: anything a player notices and is annoyed by in a normal session. Both are fixed before any new work continues.
2. **Zero errors and zero warnings** in the server and client Output through a full session.
3. **Every button does something, every screen can be closed, every state can be left.** No dead ends: dying, resetting, rejoining mid-raid, mid-loan, mid-minigame, with a full sack, with zero cash and zero seeds all recover.
4. **Broke-player check:** a player with no cash, no seeds and no crops can always get going again.
5. **Thirty-minute soak** with the harness, and a ten-player session, with no leak, no desync and no stuck state.
6. **Persistence verified** in a published test place with real DataStores, not only in Studio.
7. **Works on phone:** touch only, small screen, mid-range device frame rate.
8. **Every defect gets a regression test** where the logic can be tested in Lune, before the fix is merged.

**Bugs come first.** A known bug outranks any feature, polish or art task in every track. Track
H keeps one list, `docs/testing/BUGS.md` (id, severity, steps, owner track, status), and it is
the first thing every agent reads at the start of a session.

## 1. Where the game really is

> Written 2026-11-14 at the start of Phase 0; kept as the original diagnosis. The current state is
> the **Progress tracker** at the top of this file.

| Fact | Consequence |
|---|---|
| About 30 systems and 481 passing Lune tests. | The logic is ahead of everything else. More systems will not make the game better right now. |
| No human has ever played it. The one Studio run (2026-11-13) could not plant a crop, take a screenshot, or save data. | Every "VERIFIED" in the audit docs (FTUE, balance, perf, localization) means "reasoned about", not "seen running". Treat them as unverified. |
| The world is still built by `World/Greybox.luau`. Every icon, texture, sound and product ID is `0`. | The player sees grey parts, emoji-era UI and silence. This is the biggest gap between the game and a real game. |
| The satire (raid, pinjol collector, bribes) is the game's best idea and a new player meets none of it in the first session. | The first ten minutes are a generic farming tutorial. |
| Most of M4, the audits and the art pass are uncommitted in one working tree. | Parallel agents cannot start until this is committed. |

## 2. Direction

**North star:** a stranger on a phone laughs within three minutes, sees something they want to
show a friend within ten, and has a reason to come back tomorrow.

**Priority order (designer, 2026-11-14):** 1. Fun. 2. Looks and sound. 3. Depth. 4. Social drama.
All four get built; the order decides who waits when two things compete.

**Launch:** when the gates in section 6 pass, not on a date and not after a fixed list of
releases. This replaces D3.

### Rules every agent follows

1. **Seen running, or not done.** A change is done when it has been observed in a Studio playtest
   and the evidence is saved (section 7). Lune tests are required and are not enough.
2. **Feel before features.** No new gameplay system is started before Gate 1 passes. Until then
   every hour goes into making what exists feel, look and sound great.
3. **The satire is the product.** If a screen, sound or line could belong to any farming game,
   it is not finished. Indonesian specifics, per `visual/ART.md` pillar 4 and D7 (fictional names, real stereotypes).
4. **Phone first.** Judge every change on the mobile emulator at phone size before desktop.
5. **Cut rather than fake.** Report a smaller thing that works instead of a bigger thing that might.
   Never invent asset IDs, product IDs, prices, UserIds or Roblox policy.
6. **Server decides everything.** `TECH.md` ground rules and the monetization guardrails in
   `plan/PLAN.md` §3.7 do not change.

## 3. Phase 0 — Make the repo safe for parallel work

One agent, alone, before anyone else starts. Nothing here is optional.

| # | Task | Done when |
|---|---|---|
| 0.1 | Commit the working tree in topical commits (M4 remainder, audits, art pass, tests). Ask the designer before committing. | `git status` is clean; `lune run tests/run.luau` passes. |
| 0.2 | Fix the known Studio failures: wrong asset type `rbxassetid://203785492`, Clouds not under Terrain, Greybox terrain stacking on rebuild. | A Play Solo run shows zero errors and zero warnings in Output. |
| 0.3 | Build the playtest harness: a documented Studio MCP routine that starts a play session, plants, harvests, sells, buys, and captures screenshots at desktop and phone size. The 2026-11-13 run could not trigger prompts; solve that first (test-only server hooks behind a Studio-only flag are acceptable). | `docs/testing/HARNESS.md` exists and a second agent can follow it to produce screenshots of the full loop. |
| 0.3b | Bug sweep: play every MVP flow in section 0 through the harness, including the dead-end cases in the quality bar, and open `docs/testing/BUGS.md` with everything found. Flag off any non-MVP system that fails. | The bug list exists with severities and owner tracks; flagged-off systems are listed in it. |
| 0.4 | Record the baseline: screenshots and timings of the current first ten minutes on phone size. | Saved under `docs/v2/evidence/baseline/`. This is what "better" is measured against. |
| 0.5 | Set up the tool pipeline (section 5, track G scouting): confirm Blender MCP export to Roblox, decide how assets get uploaded and who presses the button. | `docs/v2/plan/TOOLS.md` lists each tool, its licence terms, and the upload route. |

## 4. Phase 1 — The great ten minutes

Goal: the first ten minutes are the best ten minutes of any Indonesian Roblox game. Everything
in this phase serves the beat sheet below. Tracks in section 5 run in parallel.

### First-session beat sheet (target, tune in playtests)

| Time | Beat | What the player feels |
|---|---|---|
| 0:00 | Spawn on your plot at golden hour. Village sounds, music, an NPC calls you over. No menu. | "This looks good." |
| 0:15 | First plant. One tap, satisfying dig, soil flies, sound. | Control. |
| 0:45 | First harvest. The tutorial padi grows in about 20 seconds, not 60. Guaranteed *Bagus*. | First reward. |
| 1:30 | Sell at the Pasar. A thermal *struk* prints, cash flies to the HUD. | Money is fun. |
| 2:30 | Buy seeds from a rotating shelf; plant a full row. The phone buzzes: BayarLater offers a loan. | Temptation, first joke. |
| 4:00 | Second harvest: a guaranteed *Super* or *Langka* reveal with the full sting. | "Whoa." |
| 5:30 | A scripted NPC neighbour gets raided: the full sinetron cutscene, seen as a spectator. | The hook. "That can happen to me?" |
| 7:00 | A rumour at the warung or a whisper from the Tengkulak Gelap. Never an instruction. | Curiosity about cheating. |
| 9:00 | Rank up to Petani with a ceremony. A slow kebun crop is planted and will be ready later; daily tasks appear. | A reason to return. |

Rules for the beat sheet: the tutorial still never tells the player to cheat (`plan/PLAN.md` §3.1);
guaranteed outcomes are first-session only and decided by the server; no wait longer than ten
seconds without something to do or watch.

### Gate 1 — the MVP gate, exit criteria

- The MVP list in section 0 is complete and the whole quality bar in section 0 passes.
- `docs/testing/BUGS.md` has no open blocker or major bug.

- The harness plays the full beat sheet on phone size with zero Output errors or warnings.
- Nothing visible in the first ten minutes is a placeholder: no greybox part, no emoji, no missing icon, no silent action.
- Time to first harvest is under 45 seconds, first rarity reveal under 5 minutes, raid witnessed under 7 minutes.
- All text a player sees, in the world and on the HUD, is readable at phone size: no overlapping labels, no clipped text, nothing hidden under the HUD (BUG-006, BUG-008, BUG-009). Added 2026-11-14 after the designer's phone playtest; it is part of 'no placeholder visible', made explicit.
- Measured on a real phone by the designer (Xiaomi 12 Lite, 2026-11-14, self-reported): about 30 fps at maximum graphics and 60 fps at the lowest. Recorded in `docs/v2/evidence/h/2026-11-14-perf/DESIGNER_PHONE_REPORT.md`; the 60 fps target must hold at the device's default quality.
- Frame rate and instance count are measured on the phone emulator and recorded; the target is 60 fps on mid-range Android (`visual/ART.md` §5).
- Five real people play ten minutes on their own phones without help. The designer runs this. Their confusion points are fixed or logged.

## 5. Tracks (parallel)

Each track is one agent, or one agent at a time, in its own worktree and branch
(`track/<letter>-<slug>`). A track owns its files; nobody else edits them.

| Track | Mission | Owns | Key deliverables |
|---|---|---|---|
| **A. Game feel** | Every core action feels great: plant, grow, harvest, sell, buy, reveal. | `src/client/Minigames/*`, `src/client/UI/Tiles.luau`, `src/client/UI/Minigame.luau`, new `src/client/Feel/*` | Hit feedback, tweens, particles, camera nudges, haptics, cash-fly, visible crop growth stages, rarity reveal sequence per `visual/ART.md` §7 and §9. |
| **B. First session** | Implement the beat sheet. | `src/server/Progression/OnboardingService.luau`, new `src/server/Progression/FirstSession*.luau`, onboarding entries in `Config` | Beat-sheet script, guaranteed first-session outcomes, scripted NPC raid, rank-up ceremony, return hook. Analytics funnel step per beat. |
| **C. World** | Replace the greybox with a real village. | `JuraganDesa.rbxl` (the only track that saves the place file), `src/server/World/*`, `src/client/World/*`, `Config/Seasons.luau` lighting values | Map built to the tag contract in `TECH.md` §3, terraced sawah and river in Terrain, five hubs each with a landmark and accent colour, set dressing, three season lighting presets, `Greybox.luau` retired to a test fallback. |
| **D. UI** | Rebuild every screen on the approved kit. | `src/client/UI/*` except the files owned by A | HUD, shop (spanduk), phone (app grid, BayarLater, chat), surat (raid, fines), struk, quest calendar, per D1 redirects. Image icons everywhere. Phone size first. |
| **E. Audio** | The village is never silent. | `src/client/Audio.luau`, `src/shared/Config/Audio.luau` | Music per area, weather ambience, UI sounds, tier stings, raid sting, collector voice barks. Sources: Roblox licensed catalogue first. Mix levels checked on phone speakers. |
| **F. Characters and cutscenes** | NPCs with personality; the raid as a show. | `src/server/World/NpcFactory.luau`, `src/client/UI/RaidOverlay.luau`, new `src/client/Cutscene/*`, `docs/v2/visual/art/npcs.md` | Caricature NPCs from design cards, idle and talk animations, the sinetron raid cutscene (`plan/PLAN.md` §3.1), the debt collector scene at the plot. |
| **G. Asset pipeline** | Produce and deliver every asset the other tracks ask for. | `docs/v2/visual/art/*`, `docs/v2/plan/TOOLS.md`, `src/shared/Config/Visuals.luau`, `src/client/UI/Icons.luau`, an `assets/` source folder | Icon set (crops, tools, tiers, currency), 6 to 8 hero textures, modular building kit and props via Blender MCP, Toolbox finds restyled to the palette. An asset manifest mapping every slot to an ID, source and licence. |
| **H. QA and integration** | Keep `master` green and prove things work. | `tests/*`, `docs/testing/*`, `docs/v2/evidence/*`, merges into `master` | Runs the harness on every merged track, owns the Studio queue, measures performance, files defects back to the owning track, keeps the evidence index. |

### Shared files

These are touched by many tracks. Rules instead of owners:

| File | Rule |
|---|---|
| `src/shared/Strings.luau` | Append only, both ID and EN, keys prefixed by track area. Never reorder or rename existing keys. |
| `src/shared/Remotes.luau` | Append only. A changed contract needs a written reason in the PR. |
| `src/server/Main.server.luau`, `src/client/Main.client.luau` | One line per new module; track H resolves conflicts. |
| `src/client/UI/Theme.luau` | Track D only. Others request components from D. |
| `src/server/Data/PlayerData.luau` | Schema changes only through a migration with a test, announced to track H before merging. |
| `JuraganDesa.rbxl` | Track C only. It is binary and cannot be merged. Everyone else leaves it unsaved. |

### Assets and outside tools (track G, with the designer)

- **Order of preference:** Roblox Toolbox and licensed catalogue, restyled → made in Blender via MCP → generated by an outside tool and cleaned up.
- **Every asset has a manifest row:** slot, source, licence, who approved it. No row, no merge.
- **Outside tools:** track G may research and propose tools (image, 3D, audio generation) in `plan/TOOLS.md` with their commercial-use terms. Creating accounts, accepting terms, paying, or connecting a new MCP server is the designer's step, not the agent's.
- **Uploads:** agents prepare files; the designer uploads or approves the upload route, then the ID goes into the manifest and config. IDs stay `0` until then and the UI must degrade cleanly.
- **Never:** commercial music, ripped game assets, real people's faces or names (D7), real brand logos.

## 6. After Gate 1

Each phase has a gate. No phase starts before the previous gate passes.

### Phase 2 — Depth: hours 1 to 20

`plan/BALANCE.md` only models progress up to Juragan at about one hour. This phase answers "what do I
do after that?" using systems that already exist before adding new ones.

- Rebuild the balance model as a runnable Lune simulation checked against real playtest timings, then tune `Config` against it.
- Long goals: Almanak completion rewards, kebun and perkebunan crops, the sawit permit and hill concession, tool tiers, plot expansion beyond 12 tiles.
- Hidden cheats on the discovery model and the informant NPC (`plan/PLAN.md` §4.4).
- **NPC neighbours who cheat**, pulled forward from v3: a new game has near-empty servers, and the report and raid loop must work with one player online.
- Housing and plot decoration as the visible status goal and main cosmetic surface (`plan/PLAN.md` §5).

**Gate 2:** a tester plays three sessions on three days and can name their next goal each time; the simulation and observed income per minute agree within a stated margin.

### Phase 3 — Social drama

Kepala Desa, Dana Desa, proyek mangkrak, serangan fajar, the election count, the cross-server
viral ticker (`plan/PLAN.md` §4), then trading, stealing, security and hush money (`plan/PLAN.md` §5).
Spec first, per the format in `archive/HANDOFF_ROADMAP.md` phase C. Roblox policy on trading and paid
random items is verified from primary sources before any code.

**Gate 3:** a ten-player test server produces an election, a corruption report and a raid without admin help, and the alt-account and spam scenarios in `qa/SECURITY_AUDIT.md` are re-run against the new remotes.

### Phase 4 — Launch readiness

Real product IDs and prices (D9), receipt tests in a live test place, maturity questionnaire
answered by the designer, icon and thumbnails and a raid clip from real footage, a re-run of
security, performance and localization audits with runtime evidence, then a soft launch to a
small audience before going public.

**Launch gate:** all earlier gates pass, DataStore persistence is verified in a published test place, purchases grant exactly once in a live test, and the designer says go.

Livestock, empang, processing, seasonal events and seed crates (`plan/PLAN.md` §6) come after launch, steered by player data.

## 7. How work is proven and reported

**Status words.** Use exactly these in every report:

| Word | Meaning |
|---|---|
| `SEEN-IN-STUDIO` | Observed in a play session; evidence saved. |
| `LUNE-ONLY` | Unit tests pass; not observed running. |
| `UNVERIFIED` | Written, not run. |
| `BLOCKED` | Needs the designer or another track; say which. |

**Evidence.** `docs/v2/evidence/<track>/<yyyy-mm-dd>-<slug>/` holding screenshots at phone and
desktop size, the Output log, and a `REPORT.md` of at most twenty lines: what changed, status
word per item, what was not checked, decisions needed.

**Definition of done for any task:**

1. `lune run tests/run.luau` passes; new logic has a spec; no test removed or weakened.
2. Observed in Studio at phone size with zero new Output errors or warnings.
3. Before and after screenshots saved for anything visible; a short clip description for anything that moves or sounds.
4. Player text is in `Strings.luau` in ID and EN; the EN explains the reference.
5. Only the track's own files and the shared files (by their rules) are touched.
6. Merged by track H, not by the author.

**Studio access.** If only one Studio session is available, track H runs the queue: tracks ask for
a slot, H runs the harness on their branch and returns the evidence. If each agent has its own
Studio, each still uses the harness and never saves the place file unless it is track C.

**Decisions.** When blocked on a designer decision, do not guess and do not stop: log it in the
report with options and a recommendation, add a row to `plan/DECISIONS.md` as `open`, and continue
with unblocked work.

## 8. Hard rules

- Do not revert or overwrite another track's work. **Always commit finished work** (designer, 2026-11-14): topical commits, tests passing, tracker ticked in the same commit; no attribution lines, then push to the working branch (`AGENTS.md`, 2026-11-16).
- Do not publish, change experience settings, create products, or spend Robux or money.
- Do not start a system from Phase 2 or later before its gate, even if it looks easy.
- Do not mark anything `SEEN-IN-STUDIO` without the evidence folder.
- Save data changes go through `PlayerData.migrate` with a fixture test.
- Nothing sold blocks a raid, clears a VIRAL case, or is random.

## 9. Open decisions for the designer

1. Upload route for assets: designer uploads by hand, or an Open Cloud key the designer creates for track G.
2. One Studio session shared through track H, or one per agent.
3. Fonts for display and body (`visual/ART.md` §12), chosen on a phone once track D has both on screen.
4. D9 product IDs and prices: needed for Phase 4, not before.
5. Admin UserIds (D10) for the playtest place.
