# Juragan Desa — Master Plan

> Written 2026-11-14. This is the single direction for every agent working on this repo.
> It supersedes `HANDOFF_ROADMAP.md` and `HANDOFF_ART_PASS.md` for ordering and priorities.
> `PLAN.md` stays the feature reference, `ART.md` the art bible, `TECH.md` the code conventions,
> `DECISIONS.md` the designer's decisions. Where this file disagrees with them on *what comes
> first* or *what counts as done*, this file wins.

## Progress tracker — read first, update last

**Last updated:** 2026-11-14 · branch `track/c-world-look` · commit `3559d49` · `lune run tests/run.luau`: 596 passing.

**Rules for this section.** Every agent reads it before touching the repo, so nobody has to rediscover
the state from scratch. Whoever finishes a task ticks it here **in the same commit**, adds its status
word (§7) and an evidence path, and bumps the "Last updated" line. `[x]` = done with evidence,
`[~]` = partly done (say what is missing), `[ ]` = not started. Never tick without evidence. The
gate rows' full detail stays in `docs/testing/GATE1.md`; defects stay in `docs/testing/BUGS.md`.

### Next up (recommended order)

1. **A + E — game feel and sound:** plant/harvest/sell feedback; UI sounds and tier stings (all `0` today).
2. **G — first icon set via Open Cloud** (key verified 2026-11-14): crops, currency, phone apps; unblocks G4.
3. **D — phone app pages at phone size** and real taps.
4. **C — spawn composition and golden-hour tuning.**

### Phase 0 — repo safe for parallel work

- [x] 0.1 Working tree committed in topical commits.
- [x] 0.2 Studio failures: BUG-001, BUG-002 fixed `SEEN-IN-STUDIO`; BUG-003 is external, excluded by D-G4.
- [x] 0.3 Playtest harness — `docs/testing/HARNESS.md`.
- [x] 0.3b Bug sweep — `docs/testing/BUGS.md`.
- [x] 0.4 Baseline — `docs/v2/evidence/baseline/`.
- [x] 0.5 Tool pipeline — `TOOLS.md`, D-G1 decided; Open Cloud key exists and introspects valid 2026-11-14 (user env var `ROBLOX_API_KEY`, scopes include `asset` read/write). Shells started before it was set see it empty: read it from the User environment or restart.

### Gate 1 at a glance (detail: `docs/testing/GATE1.md`)

- [~] G2/Q1 no open blocker or major bug — BUG-008 reopened and fixed again (`SEEN-IN-STUDIO` desktop); BUG-004 fixed `LUNE-ONLY`; BUG-006, BUG-007 minor and open.
- [ ] G3 harness plays the full beat sheet at phone size — the beat sheet does not exist yet (track B).
- [ ] G4 nothing visible is a placeholder — icons are letters, NPCs are boxes, most actions are silent.
- [~] G4b text readable at phone size — signs on boards, HUD and phone checked at iPhone 14 (`evidence/h/2026-11-14-audit-fixes/`); the Pasar close-up and app pages are not checked.
- [ ] G5 first harvest < 45 s, first reveal < 5 min, raid < 7 min — blocked by padi `growSeconds` 60.
- [~] G6 fps and instance count — instance count saved; designer phone ~30 fps at max, 60 at lowest; no emulator fps.
- [ ] G7 five real people, own phones (designer).
- [~] Q3 no dead ends — 2 of 8 cases `SEEN-IN-STUDIO`.
- [~] Q5 soak — 30-min client soak done; ten-player session not run.
- [ ] Q6 persistence in a published place.
- [ ] Q7 touch on a real mid-range phone.

### Tracks

**A. Game feel**
- [~] Crop growth stages (bibit / tumbuh / siap) exist in `FarmService`; not judged by a human.
- [ ] Plant, harvest, sell feedback: particles, tweens, camera nudge, cash-fly.
- [~] Rarity reveal: toast tint, Sultan shake and sting hooks exist; sting sounds are `0`.

**B. First session**
- [x] Four-step tutorial (plant, harvest, sell, buy) — `SEEN-IN-STUDIO` via harness.
- [x] Next Goal card after the tutorial (next rank, then daily tasks) — `SEEN-IN-STUDIO` desktop, `src/shared/NextGoal.luau`.
- [x] Broke-player seed floor (BUG-004, D-G3) — `LUNE-ONLY`.
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
- [~] 9.5-stud headroom in all six hubs — spec in `greybox_spec`; only the Warung photographed.
- [x] Spawn composition: the player spawns facing a tree trunk; frame plot, NPC and hub instead — `LUNE-ONLY`, `tests/specs/greybox_spec.luau`.
- [x] Golden-hour look: clock is already 16:00–16:54, the screen still reads as midday blue (colour and atmosphere) — `LUNE-ONLY`, `tests/specs/seasons_spec.luau`.
- [ ] Terrain grass decoration (place-file setting, tick in Studio).
- [ ] Terraced sawah and river; three season presets re-tuned.
- [ ] `Greybox.luau` retired to a test fallback.

**D. UI**
- [x] HUD readable, stats under the top bar (BUG-009) — `SEEN-IN-STUDIO` desktop.
- [x] Phone is the single control panel (Seed Shop and Leaderboard are apps; device look; landscape on short screens) — `SEEN-IN-STUDIO` desktop and iPhone 14.
- [x] Seed bar shows only owned or selected seeds, centred — `SEEN-IN-STUDIO`.
- [~] Cabai banner gold with countdown — `LUNE-ONLY` (event not seen running).
- [ ] App pages (Report, Farm, Loan, Quests, Cheat, Decor) at phone size and with real taps.
- [ ] Stats panel as icon chips (cash first, sack, Sus, Nama Baik).
- [ ] D6: Indonesian default plus a language picker (today only `Strings.langFor`); closes BUG-007.
- [ ] BUG-006 world label under the HUD panel.
- [ ] Fonts chosen on a phone (§9.3).

**E. Audio**
- [x] Village music, Pasar music, day ambience — `SEEN-IN-STUDIO`, `art/ASSET_MANIFEST.md`.
- [ ] UI sounds, tier stings, raid sting, rain and night ambience (all `0`).

**F. Characters and cutscenes**
- [ ] Caricature NPCs from design cards (Pak RT and others are box heads today).
- [ ] Sinetron raid cutscene; debt collector scene.

**G. Asset pipeline**
- [x] Asset manifest started.
- [x] Open Cloud key — verified by introspection 2026-11-14 (`ROBLOX_API_KEY`, never committed or printed).
- [ ] Icon set (crops, tools, tiers, currency, phone apps); 6–8 hero textures.

**H. QA and integration**
- [x] Thirty-minute client soak — `evidence/h/2026-11-14-soak/`.
- [ ] Full-session `output.log`; fps on the phone emulator; ten-player session; published-place persistence.
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
   it is not finished. Indonesian specifics, per `ART.md` pillar 4 and D7 (fictional names, real stereotypes).
4. **Phone first.** Judge every change on the mobile emulator at phone size before desktop.
5. **Cut rather than fake.** Report a smaller thing that works instead of a bigger thing that might.
   Never invent asset IDs, product IDs, prices, UserIds or Roblox policy.
6. **Server decides everything.** `TECH.md` ground rules and the monetization guardrails in
   `PLAN.md` §3.7 do not change.

## 3. Phase 0 — Make the repo safe for parallel work

One agent, alone, before anyone else starts. Nothing here is optional.

| # | Task | Done when |
|---|---|---|
| 0.1 | Commit the working tree in topical commits (M4 remainder, audits, art pass, tests). Ask the designer before committing. | `git status` is clean; `lune run tests/run.luau` passes. |
| 0.2 | Fix the known Studio failures: wrong asset type `rbxassetid://203785492`, Clouds not under Terrain, Greybox terrain stacking on rebuild. | A Play Solo run shows zero errors and zero warnings in Output. |
| 0.3 | Build the playtest harness: a documented Studio MCP routine that starts a play session, plants, harvests, sells, buys, and captures screenshots at desktop and phone size. The 2026-11-13 run could not trigger prompts; solve that first (test-only server hooks behind a Studio-only flag are acceptable). | `docs/testing/HARNESS.md` exists and a second agent can follow it to produce screenshots of the full loop. |
| 0.3b | Bug sweep: play every MVP flow in section 0 through the harness, including the dead-end cases in the quality bar, and open `docs/testing/BUGS.md` with everything found. Flag off any non-MVP system that fails. | The bug list exists with severities and owner tracks; flagged-off systems are listed in it. |
| 0.4 | Record the baseline: screenshots and timings of the current first ten minutes on phone size. | Saved under `docs/v2/evidence/baseline/`. This is what "better" is measured against. |
| 0.5 | Set up the tool pipeline (section 5, track G scouting): confirm Blender MCP export to Roblox, decide how assets get uploaded and who presses the button. | `docs/v2/TOOLS.md` lists each tool, its licence terms, and the upload route. |

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

Rules for the beat sheet: the tutorial still never tells the player to cheat (`PLAN.md` §3.1);
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
- Frame rate and instance count are measured on the phone emulator and recorded; the target is 60 fps on mid-range Android (`ART.md` §5).
- Five real people play ten minutes on their own phones without help. The designer runs this. Their confusion points are fixed or logged.

## 5. Tracks (parallel)

Each track is one agent, or one agent at a time, in its own worktree and branch
(`track/<letter>-<slug>`). A track owns its files; nobody else edits them.

| Track | Mission | Owns | Key deliverables |
|---|---|---|---|
| **A. Game feel** | Every core action feels great: plant, grow, harvest, sell, buy, reveal. | `src/client/Minigames/*`, `src/client/UI/Tiles.luau`, `src/client/UI/Minigame.luau`, new `src/client/Feel/*` | Hit feedback, tweens, particles, camera nudges, haptics, cash-fly, visible crop growth stages, rarity reveal sequence per `ART.md` §7 and §9. |
| **B. First session** | Implement the beat sheet. | `src/server/Progression/OnboardingService.luau`, new `src/server/Progression/FirstSession*.luau`, onboarding entries in `Config` | Beat-sheet script, guaranteed first-session outcomes, scripted NPC raid, rank-up ceremony, return hook. Analytics funnel step per beat. |
| **C. World** | Replace the greybox with a real village. | `JuraganDesa.rbxl` (the only track that saves the place file), `src/server/World/*`, `src/client/World/*`, `Config/Seasons.luau` lighting values | Map built to the tag contract in `TECH.md` §3, terraced sawah and river in Terrain, five hubs each with a landmark and accent colour, set dressing, three season lighting presets, `Greybox.luau` retired to a test fallback. |
| **D. UI** | Rebuild every screen on the approved kit. | `src/client/UI/*` except the files owned by A | HUD, shop (spanduk), phone (app grid, BayarLater, chat), surat (raid, fines), struk, quest calendar, per D1 redirects. Image icons everywhere. Phone size first. |
| **E. Audio** | The village is never silent. | `src/client/Audio.luau`, `src/shared/Config/Audio.luau` | Music per area, weather ambience, UI sounds, tier stings, raid sting, collector voice barks. Sources: Roblox licensed catalogue first. Mix levels checked on phone speakers. |
| **F. Characters and cutscenes** | NPCs with personality; the raid as a show. | `src/server/World/NpcFactory.luau`, `src/client/UI/RaidOverlay.luau`, new `src/client/Cutscene/*`, `docs/v2/art/npcs.md` | Caricature NPCs from design cards, idle and talk animations, the sinetron raid cutscene (`PLAN.md` §3.1), the debt collector scene at the plot. |
| **G. Asset pipeline** | Produce and deliver every asset the other tracks ask for. | `docs/v2/art/*`, `docs/v2/TOOLS.md`, `src/shared/Config/Visuals.luau`, `src/client/UI/Icons.luau`, an `assets/` source folder | Icon set (crops, tools, tiers, currency), 6 to 8 hero textures, modular building kit and props via Blender MCP, Toolbox finds restyled to the palette. An asset manifest mapping every slot to an ID, source and licence. |
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
- **Outside tools:** track G may research and propose tools (image, 3D, audio generation) in `TOOLS.md` with their commercial-use terms. Creating accounts, accepting terms, paying, or connecting a new MCP server is the designer's step, not the agent's.
- **Uploads:** agents prepare files; the designer uploads or approves the upload route, then the ID goes into the manifest and config. IDs stay `0` until then and the UI must degrade cleanly.
- **Never:** commercial music, ripped game assets, real people's faces or names (D7), real brand logos.

## 6. After Gate 1

Each phase has a gate. No phase starts before the previous gate passes.

### Phase 2 — Depth: hours 1 to 20

`BALANCE.md` only models progress up to Juragan at about one hour. This phase answers "what do I
do after that?" using systems that already exist before adding new ones.

- Rebuild the balance model as a runnable Lune simulation checked against real playtest timings, then tune `Config` against it.
- Long goals: Almanak completion rewards, kebun and perkebunan crops, the sawit permit and hill concession, tool tiers, plot expansion beyond 12 tiles.
- Hidden cheats on the discovery model and the informant NPC (`PLAN.md` §4.4).
- **NPC neighbours who cheat**, pulled forward from v3: a new game has near-empty servers, and the report and raid loop must work with one player online.
- Housing and plot decoration as the visible status goal and main cosmetic surface (`PLAN.md` §5).

**Gate 2:** a tester plays three sessions on three days and can name their next goal each time; the simulation and observed income per minute agree within a stated margin.

### Phase 3 — Social drama

Kepala Desa, Dana Desa, proyek mangkrak, serangan fajar, the election count, the cross-server
viral ticker (`PLAN.md` §4), then trading, stealing, security and hush money (`PLAN.md` §5).
Spec first, per the format in `HANDOFF_ROADMAP.md` phase C. Roblox policy on trading and paid
random items is verified from primary sources before any code.

**Gate 3:** a ten-player test server produces an election, a corruption report and a raid without admin help, and the alt-account and spam scenarios in `SECURITY_AUDIT.md` are re-run against the new remotes.

### Phase 4 — Launch readiness

Real product IDs and prices (D9), receipt tests in a live test place, maturity questionnaire
answered by the designer, icon and thumbnails and a raid clip from real footage, a re-run of
security, performance and localization audits with runtime evidence, then a soft launch to a
small audience before going public.

**Launch gate:** all earlier gates pass, DataStore persistence is verified in a published test place, purchases grant exactly once in a live test, and the designer says go.

Livestock, empang, processing, seasonal events and seed crates (`PLAN.md` §6) come after launch, steered by player data.

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
report with options and a recommendation, add a row to `DECISIONS.md` as `open`, and continue
with unblocked work.

## 8. Hard rules

- Do not revert or overwrite another track's work. **Always commit finished work** (designer, 2026-11-14): topical commits, tests passing, tracker ticked in the same commit; no attribution lines. Never push.
- Do not publish, change experience settings, create products, or spend Robux or money.
- Do not start a system from Phase 2 or later before its gate, even if it looks easy.
- Do not mark anything `SEEN-IN-STUDIO` without the evidence folder.
- Save data changes go through `PlayerData.migrate` with a fixture test.
- Nothing sold blocks a raid, clears a VIRAL case, or is random.

## 9. Open decisions for the designer

1. Upload route for assets: designer uploads by hand, or an Open Cloud key the designer creates for track G.
2. One Studio session shared through track H, or one per agent.
3. Fonts for display and body (`ART.md` §12), chosen on a phone once track D has both on screen.
4. D9 product IDs and prices: needed for Phase 4, not before.
5. Admin UserIds (D10) for the playtest place.
