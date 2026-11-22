# Evidence index — track h

Status words, exactly: `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`.

Rule: a claim without a file under `docs/v2/evidence/` is not `SEEN-IN-STUDIO`. This `INDEX.md` is a directory, not evidence for any claim; each row points at files in its own folder. Status is derived from that folder's `REPORT.md`, `results.json`, `COVERAGE.md`, `CHECKS_SUMMARY.md`, `STUDIO_REVIEW.md` or `CHECK_*.txt`, never from this file.

Rows: **82** dated folders under `docs/v2/evidence/h/` (2026-11-14 to 2026-11-21).

| Folder | Date | What it proves | Status |
|---|---|---|---|
| `2026-11-14-audit-fixes` | 2026-11-14 | BUG-008 hub signs, Next Goal card, owned-seed bar and materials; desktop screenshots, 581 then 584 tests | SEEN-IN-STUDIO |
| `2026-11-14-perf` | 2026-11-14 | Startup Output and instance counts from Play Solo (`output.log`); frame rate UNVERIFIED | SEEN-IN-STUDIO |
| `2026-11-14-phase0` | 2026-11-14 | Bridge enable, plant→harvest→sell→buy loop, save/reload and BUG-001 on iPhone 14 plus desktop | SEEN-IN-STUDIO |
| `2026-11-14-soak` | 2026-11-14 | 1800 s client soak: 111 cycles, 0 stale replies (`soak.json`); ten-player half UNVERIFIED | SEEN-IN-STUDIO |
| `2026-11-17-cutscene-anchors` | 2026-11-17 | `anchorFor` resolver live and anchored cutscene runs; framing quality BLOCKED on designer | SEEN-IN-STUDIO |
| `2026-11-17-gate1` | 2026-11-17 | BUG-012 `Vector2.Z` sell crash fixed; plant→ready→harvest→sell re-run with clean Output, 1676 tests | SEEN-IN-STUDIO |
| `2026-11-17-perf-switches` | 2026-11-17 | `ClientFps` sampler publishes 60 and perf switches toggle and restore all five states | SEEN-IN-STUDIO |
| `2026-11-17-phone-studio` | 2026-11-17 | BUG-011 phone mount, first-tap build, ID/EN labels and landscape at 749×388 | SEEN-IN-STUDIO |
| `2026-11-17-raid-cutscene` | 2026-11-17 | Gated `raid` hook, camera hand-back on finish/skip/death/Raid_End, 20 s window, BREAKING NEWS bar | SEEN-IN-STUDIO |
| `2026-11-19-admin-authority` | 2026-11-19 | Admin and season commands validate caller and payload; non-admins refused, grants bounded | LUNE-ONLY |
| `2026-11-19-analytics-audit` | 2026-11-19 | Documented analytics events matched to call sites, funnel order, bounded payloads; dashboard UNVERIFIED | LUNE-ONLY |
| `2026-11-19-audio-hygiene` | 2026-11-19 | `AudioPolicy` and grouped Sound census in Play Solo; 4 SoundGroups, 17 Sounds, 0 ungrouped after rapid Cuaca | SEEN-IN-STUDIO |
| `2026-11-19-budget-check` | 2026-11-19 | Live `FidelityRuntime` forced across 18 hub-tier pairs; instance and triangle budget matrix in `results.json` | SEEN-IN-STUDIO |
| `2026-11-19-bug-hunt-reading` | 2026-11-19 | Defect scan of `src/server`, `src/client` and pure `src/shared`; two findings locked by specs | LUNE-ONLY |
| `2026-11-19-cancel-proof` | 2026-11-19 | Real minigame Cancel closes the overlay on Rojo-synced code in Play Solo | SEEN-IN-STUDIO |
| `2026-11-19-candidate-gallery` | 2026-11-19 | `CANDIDATES.md` drift-lock: one row per candidate with render, toggle, cost and yes/no column | LUNE-ONLY |
| `2026-11-19-ci` | 2026-11-19 | CI workflow config and local command verification; GitHub-hosted run UNVERIFIED | LUNE-ONLY |
| `2026-11-19-ci-round2` | 2026-11-19 | Hosted CI runs read with `gh`: red run diagnosed, three green runs recorded | SEEN-IN-STUDIO |
| `2026-11-19-client-error-boundary` | 2026-11-19 | `Main.client` bootstrap survives throwing UI/feel mounts; 4-case spec | LUNE-ONLY |
| `2026-11-19-code-health` | 2026-11-19 | Refactor load and no-regression in Play Solo; helper behaviour spec-locked | SEEN-IN-STUDIO |
| `2026-11-19-crop-candidates` | 2026-11-19 | 36 low-poly crop models behind off-by-default `LookDev`, live 36-model apply/remove round-trip | SEEN-IN-STUDIO |
| `2026-11-19-cross-server-failures` | 2026-11-19 | OrderedDataStore backoff, last-good fallback and write-budget limits; specs only | LUNE-ONLY |
| `2026-11-19-dead-code` | 2026-11-19 | 22 dead Strings keys and 5 dead exports removed; clean Edit→Play→Edit with no game-code errors | SEEN-IN-STUDIO |
| `2026-11-19-docs-refresh` | 2026-11-19 | Docs values reread from current code; documentation only, no game code | LUNE-ONLY |
| `2026-11-19-economy-sim` | 2026-11-19 | Eight simulated hours, 480 cycles, three profiles; balance observation, no balance change | LUNE-ONLY |
| `2026-11-19-g3-beatsheet` | 2026-11-19 | Full nine-step G3 beat sheet at desktop size on Rojo-synced code, Output in `output.log` | SEEN-IN-STUDIO |
| `2026-11-19-g3-phone` | 2026-11-19 | G3 beat sheet at real 749×389 iPhone 14 viewport; all nine steps ok (`results.json`, `output.log`) | SEEN-IN-STUDIO |
| `2026-11-19-g5-phone` | 2026-11-19 | G5 timings at iPhone 14 size: harvest 22/20/21 s, reveal 70 s, raid gossip 315 s | SEEN-IN-STUDIO |
| `2026-11-19-g5-timings` | 2026-11-19 | Three desktop fresh-profile G5 runs, real grow timers, Output wall-time stamps | SEEN-IN-STUDIO |
| `2026-11-19-gamepad-nav` | 2026-11-19 | `GuiService.SelectedObject` navigation across nine states; B/Escape drive BLOCKED — MCP input cannot produce a ContextActionService Begin event | SEEN-IN-STUDIO |
| `2026-11-19-gate1-studio` | 2026-11-19 | Q3 recovery, force-raid no-save and BUG-004 seed floor; join/Cancel observations superseded by `gate1-sweep` | SEEN-IN-STUDIO |
| `2026-11-19-gate1-sweep` | 2026-11-19 | Full Gate 1 sweep on Rojo-synced code: join bootstrap, Cancel, full-sack boundary, every button, Q2 `output.log` | SEEN-IN-STUDIO |
| `2026-11-19-greybox-retirement` | 2026-11-19 | `Map.isDesignerWorld()` tag contract and greybox test-only fallback live, readings in `results.json` | SEEN-IN-STUDIO |
| `2026-11-19-hubprops-candidates` | 2026-11-19 | Warung, pasar, polisi and Pak RT props within per-hub budget behind off-by-default `LookDev` | SEEN-IN-STUDIO |
| `2026-11-19-icons-candidates` | 2026-11-19 | 27 uploaded icon IDs and off-by-default LookDev enable/disable round-trip (`results.json`) | SEEN-IN-STUDIO |
| `2026-11-19-lighting-fidelity` | 2026-11-19 | Six hubs times three fidelity tiers, 18 combinations; no tier creates or destroys Lighting effects | SEEN-IN-STUDIO |
| `2026-11-19-localization` | 2026-11-19 | ID/EN text wiring live in Studio; key integrity and scanner spec-locked | SEEN-IN-STUDIO |
| `2026-11-19-lookdev-candidates` | 2026-11-19 | Two candidates load, gate and reverse live; final visual approval BLOCKED on designer | SEEN-IN-STUDIO |
| `2026-11-19-mutation-testing` | 2026-11-19 | 25/25 mutants killed, 0 survivors, 0 manifest errors; every fault reverted | LUNE-ONLY |
| `2026-11-19-npc-candidates` | 2026-11-19 | 19 caricature NPC detail parts applied to and removed from live tagged NPCs | SEEN-IN-STUDIO |
| `2026-11-19-npc-pathing` | 2026-11-19 | `NpcWalk` live walks to all ten plots plus stuck fallback; walker logic locked by specs | SEEN-IN-STUDIO |
| `2026-11-19-performance` | 2026-11-19 | Instance counts and live hub readings in Play Solo, matrix in `results.json` | SEEN-IN-STUDIO |
| `2026-11-19-phone-emulation` | 2026-11-19 | Controlled desktop-versus-phone-versus-low-end comparison: viewport, aspect and touch all change | SEEN-IN-STUDIO |
| `2026-11-19-player-leave-cleanup` | 2026-11-19 | Six new cleanup specs plus partial live handler smoke; actual leave transition BLOCKED — MCP cannot fire PlayerRemoving | LUNE-ONLY |
| `2026-11-19-purchases` | 2026-11-19 | Receipt idempotency, mid-grant leave, failed save, unknown products and pass check; 5-case spec | LUNE-ONLY |
| `2026-11-19-q5-multiclient` | 2026-11-19 | Ten-player half of Q5 not run: BLOCKED — needs a human at Roblox Studio's Test tab with a Local Server and several clients | BLOCKED |
| `2026-11-19-q5-multiclient-script` | 2026-11-19 | 12-case multi-client comparator script and plan; live ten-player run BLOCKED on a human at Test tab | LUNE-ONLY |
| `2026-11-19-q6-published-place` | 2026-11-19 | Published-place save/rejoin/compare script and plan; live run BLOCKED on designer D-G2 | LUNE-ONLY |
| `2026-11-19-regression-replay` | 2026-11-19 | Post-items-1–28 replay of G3, G5, Q2 and an 1800 s soak on Rojo-synced code | SEEN-IN-STUDIO |
| `2026-11-19-remote-fuzzing` | 2026-11-19 | Deterministic malformed payloads at every connectable C→S remote; 3-case spec | LUNE-ONLY |
| `2026-11-19-respawn-rejoin` | 2026-11-19 | Ten Humanoid-kill resets, fresh character each time and UI survives; live loop | SEEN-IN-STUDIO |
| `2026-11-19-review-fixes` | 2026-11-19 | Cutscene eye-to-target line-of-sight raycasts (`raycasts.json`) and no-save force raid | SEEN-IN-STUDIO |
| `2026-11-19-save-fuzzing` | 2026-11-19 | 1000 damaged saves through migrate and sanitize; found and fixed BUG-018 | LUNE-ONLY |
| `2026-11-19-soak-all-candidates` | 2026-11-19 | 1800 s soak with all eight LookDev candidates on: no leak, no growth, no desync (`soak.json`) | SEEN-IN-STUDIO |
| `2026-11-19-sound-candidates` | 2026-11-19 | Two free Creator Store music IDs loaded in Play VM and torn down by off-by-default `LookDev` | SEEN-IN-STUDIO |
| `2026-11-19-spec-coverage` | 2026-11-19 | No REPORT.md — `COVERAGE.md` maps server/client modules to failure-mode specs; three gaps closed | LUNE-ONLY |
| `2026-11-19-streaming-readiness` | 2026-11-19 | Static audit of 71 `WaitForChild` calls; `StreamingEnabled` not flipped; one new spec | LUNE-ONLY |
| `2026-11-19-strict-types` | 2026-11-19 | `--!strict` on 24 Config and pure client modules; compile-time annotations only | LUNE-ONLY |
| `2026-11-19-studio-checks` | 2026-11-19 | Eight LUNE-ONLY items driven in real Studio through `execute_luau`, readings in `results.json` | SEEN-IN-STUDIO |
| `2026-11-19-suite-health` | 2026-11-19 | Three byte-identical suite runs, no flakiness; harness and timing-contract changes | LUNE-ONLY |
| `2026-11-19-textures-candidates` | 2026-11-19 | Seven uploaded texture IDs, off-by-default material preset, 10 MeshParts reverted on disable | SEEN-IN-STUDIO |
| `2026-11-19-tile-damage` | 2026-11-19 | BUG-019 damaged dynamic tile numerics fixed with three farm-failure cases | LUNE-ONLY |
| `2026-11-19-type-pass-round2` | 2026-11-19 | `luau-lsp analyze` with definitions; 33 real type errors fixed, annotation-only | LUNE-ONLY |
| `2026-11-19-ui-fit` | 2026-11-19 | Every screen and app page probed at 749×388; AdminPanel clipping fixed, 0 violations | SEEN-IN-STUDIO |
| `2026-11-20-final-report` | 2026-11-20 | No REPORT.md — `FINAL_REPORT.md` closes round-5 items 35–43 with commits and 2248 passing tests | LUNE-ONLY |
| `2026-11-20-lookdev-corner` | 2026-11-20 | Live corner candidate verification and three saved review cameras on a stale Studio instance; visual yes/no UNVERIFIED | SEEN-IN-STUDIO |
| `2026-11-20-r6-costume-research` | 2026-11-20 | Studio tool-capability finding for R6 costume routes A and B; no visual verdict | SEEN-IN-STUDIO |
| `2026-11-20-r6-costume-template-layout` | 2026-11-20 | Open Cloud asset-type constraints and classic Shirt/Pants template layout research | LUNE-ONLY |
| `2026-11-20-r6-vegetation-ids` | 2026-11-20 | Real free Creator Store vegetation IDs from Studio MCP `search_asset`; no model placed | SEEN-IN-STUDIO |
| `2026-11-20-review-round3` | 2026-11-20 | Studio Play shots of round-3 candidates from saved cameras, combined in `REVIEW_SHEET.jpg` | SEEN-IN-STUDIO |
| `2026-11-20-review-round4` | 2026-11-20 | Eight round-4 candidates enabled in Play; observer descriptions and studio sheets, not retained pixels | SEEN-IN-STUDIO |
| `2026-11-20-review-round5` | 2026-11-20 | No REPORT.md — `REVIEW_ROUND5.md` toggles and cameras, `STUDIO_REVIEW.md` Play shots, verdicts blank | SEEN-IN-STUDIO |
| `2026-11-20-review-round6` | 2026-11-20 | No REPORT.md — `REVIEW_ROUND6.md` and `STUDIO_REVIEW.md` toggle twelve candidates in Play, two bugs recorded | SEEN-IN-STUDIO |
| `2026-11-20-round7` | 2026-11-20 | No REPORT.md — `CHECK_53.txt` to `CHECK_58.txt` PASS on load failures, sky default, grass, hats, props and vegetation | SEEN-IN-STUDIO |
| `2026-11-20-sky-r6-asset-load` | 2026-11-20 | Six real free sky models loaded and six Sky face IDs read in the Play-Solo Server VM | SEEN-IN-STUDIO |
| `2026-11-20-textures-r4-fix` | 2026-11-20 | Live Play/Client before, during and after `Terrain:GetMaterialColor` measurement of the R4 tint fix | SEEN-IN-STUDIO |
| `2026-11-21-catalog-outfits` | 2026-11-21 | No REPORT.md — `README.md` records designer catalog-outfit verdicts and the Studio Play accessory check | SEEN-IN-STUDIO |
| `2026-11-21-review-round7` | 2026-11-21 | No REPORT.md — `STUDIO_REVIEW.md` findings: sky Cover, raised dirt flower beds, hat placement bugs | SEEN-IN-STUDIO |
| `2026-11-21-review-round9` | 2026-11-21 | No REPORT.md — `STUDIO_REVIEW.md` round-9 candidate findings at ClockTime 13 and Cover 0.55 | SEEN-IN-STUDIO |
| `2026-11-21-round10` | 2026-11-21 | No REPORT.md — `CHECK_103.txt` to `CHECK_122.txt`; item 106 BLOCKED — `CHECK AVATAR_FIT FAIL 2 16` | SEEN-IN-STUDIO |
| `2026-11-21-round8` | 2026-11-21 | No REPORT.md — `REVIEW_ROUND8.md` bake and every check verified in real Studio Play, place not saved | SEEN-IN-STUDIO |
| `2026-11-21-round9` | 2026-11-21 | No REPORT.md — `CHECKS_SUMMARY.md` and `CHECK_*.txt`; items 68–100 PASS except 94–96 LUNE-ONLY | SEEN-IN-STUDIO |

## Claims needing downgrade

none found. `SEEN-IN-STUDIO` claims in `docs/v2/plan/*.md`, `docs/v2/visual/*.md` and `docs/testing/*.md` all have an existing evidence file behind them, directly or in the same entry; lines without an inline path are continuations of entries that name one (for example `docs/v2/plan/MASTER_PLAN.md:335` backs the claim on line 336). The earlier audit reached the same result at `docs/testing/CODE_AUDIT.md:110` and `:147`. No source doc was edited here.
