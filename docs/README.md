# Docs index

Start with `AGENTS.md`, then the tracker at the top of the build plan, then
[testing/BUGS.md](testing/BUGS.md) and [testing/GATE1.md](testing/GATE1.md). Open anything else only
when the task needs it.

## Two master plans (separate on purpose)

| Plan | Governs | Tracker |
|---|---|---|
| [v2/plan/MASTER_PLAN.md](v2/plan/MASTER_PLAN.md) | What may be built, in what order, how work is proven (gates, bugs, evidence). Wins on ordering and "done". | Top of the file |
| [v2/visual/VISUAL_MASTER_PLAN.md](v2/visual/VISUAL_MASTER_PLAN.md) | Everything the player sees: light, materials, models, VFX, camera, UI fidelity. Sits under the build plan. | Top of the file |

## Which files to trust

- **LIVE**: kept current; trust it and update it.
- **SNAPSHOT**: true when written; re-check before relying on it.
- **ARCHIVE**: history only; never a source of rules or priorities.

### Build side — `v2/plan/`

| File | What it answers | State |
|---|---|---|
| [MASTER_PLAN.md](v2/plan/MASTER_PLAN.md) | Tracker, phases, gates, definition of done | LIVE |
| [DECISIONS.md](v2/plan/DECISIONS.md) | Designer decisions and open questions | LIVE |
| [PLAN.md](v2/plan/PLAN.md) | Feature reference, v2.0 to v2.3 | LIVE |
| [TECH.md](v2/plan/TECH.md) | Code conventions: server authority, state, remotes, tests | LIVE |
| [TOOLS.md](v2/plan/TOOLS.md) | Asset pipeline, upload routes, licences | LIVE |
| [ANALYTICS.md](v2/plan/ANALYTICS.md) | Events, triggers, the questions they answer | LIVE |
| [DELEGATION_PROMPT.md](v2/plan/DELEGATION_PROMPT.md) | Prompt to paste into a second agent | LIVE |
| [WORK_QUEUE.md](v2/plan/WORK_QUEUE.md) | Long-run agent queue, round 3 (visual first); read after every compaction (`AGENTS.md`) | LIVE |
| [WORK_QUEUE_ROUND1.md](v2/plan/WORK_QUEUE_ROUND1.md), [WORK_QUEUE_ROUND2.md](v2/plan/WORK_QUEUE_ROUND2.md) | Rounds 1 and 2, closed 2026-11-19 | ARCHIVE |
| [BALANCE.md](v2/plan/BALANCE.md), [LOCALIZATION.md](v2/plan/LOCALIZATION.md) | Static reports regenerated from current `Config/*.luau` / `Strings.luau` (333 keys, 1930 tests) | SNAPSHOT 2026-11-19 |
| [LAUNCH.md](v2/plan/LAUNCH.md) | Store copy, rating questionnaire, launch checklist | SNAPSHOT 2026-11-12, draft |

### Visual side — `v2/visual/`

| File | What it answers | State |
|---|---|---|
| [VISUAL_MASTER_PLAN.md](v2/visual/VISUAL_MASTER_PLAN.md) | Look direction and visual tracker; wins over ART on look (D14) | LIVE |
| [ART.md](v2/visual/ART.md) | Palette, UI kit, NPC caricature rules | LIVE |
| [art/ASSET_MANIFEST.md](v2/visual/art/ASSET_MANIFEST.md) | Every asset: slot, source, licence, ID | LIVE |
| [art/MAP_SPEC.md](v2/visual/art/MAP_SPEC.md) | Map coordinates and layout (mirrored in `MapSpec.luau`) | LIVE |
| [art/MAP_LAYOUT_V1.md](v2/visual/art/MAP_LAYOUT_V1.md) | Edit-time layout matched to the illustrated brief `art/map/map_design_brief.webp`: hub models, ring, plots, coordinates, open assumptions | LIVE |
| [art/map/RECONCILIATION.md](v2/visual/art/map/RECONCILIATION.md) | Where MAP_SPEC and the outside map brief differ, and who wins | LIVE |
| [art/ICONS.md](v2/visual/art/ICONS.md), [art/TEXTURES.md](v2/visual/art/TEXTURES.md), [art/npcs.md](v2/visual/art/npcs.md) | Production briefs | LIVE |
| [art/RESEARCH_VISUAL_TIPS.md](v2/visual/art/RESEARCH_VISUAL_TIPS.md) | Visual tips applied and the optimise-later backlog | LIVE |
| [GRADE_R8.md](v2/visual/GRADE_R8.md) | Colour-grade safe ranges and scope for `grade_r8_a/b/c` (item 91) | LIVE |
| [UI_THEME_AUDIT.md](v2/visual/UI_THEME_AUDIT.md) | Palette/font/corner bypass audit of `src/client/UI/**`; CHECK THEME_BYPASS baseline and designer radius decisions | LIVE |
| [improvements/AI_ROBLOX_TIPS.md](improvements/AI_ROBLOX_TIPS.md) | 28 AI-workflow tips mapped to what we already do / should adopt | SNAPSHOT 2026-11-19 |
| `art/map/full-package/` | Outside map brief | Reference; MAP_SPEC wins |
| [mockups/juragan-ui.tokens.md](v2/visual/mockups/juragan-ui.tokens.md), `mockups/index.html` | UI mockups and tokens, not wired in | SNAPSHOT 2026-11-15 |
| [ART_PLAYTEST_PLAN.md](v2/visual/ART_PLAYTEST_PLAN.md) | Art-pass visual checks (W3–W8) | SNAPSHOT, predates the visual plan |

### Testing — `testing/` and `v2/qa/`

`testing/` is the working set; `v2/qa/` holds dated audits and the v2 playtest catalogue.

| File | What it answers | State |
|---|---|---|
| [testing/BUGS.md](testing/BUGS.md) | Defect list | LIVE |
| [testing/GATE1.md](testing/GATE1.md) | Gate 1 working checklist | LIVE |
| [testing/HARNESS.md](testing/HARNESS.md) | Studio playtest routine through the harness | LIVE |
| [testing/CODE_AUDIT.md](testing/CODE_AUDIT.md) | Per-task Lune audit log | LIVE |
| [testing/README.md](testing/README.md) | The three test layers and how to run them | LIVE |
| [v2/qa/PLAYTEST_CASES.md](v2/qa/PLAYTEST_CASES.md) | The one manual case catalogue (v1 cases merged in 2026-11-16), with the every-version set | LIVE; rows marked (v1) need a first check against config |
| [v2/qa/PLAYTEST_PLAN.md](v2/qa/PLAYTEST_PLAN.md) | Scenarios and setup behind the cases | SNAPSHOT, predates the Master Plan |
| [testing/runs/TEMPLATE.md](testing/runs/TEMPLATE.md) | Run sheet to copy per run | LIVE |
| [v2/qa/SECURITY_AUDIT.md](v2/qa/SECURITY_AUDIT.md), [v2/qa/PERF_AUDIT.md](v2/qa/PERF_AUDIT.md), [v2/qa/FTUE_AUDIT.md](v2/qa/FTUE_AUDIT.md) | Static audits without runtime evidence; Master Plan Phase 4 re-runs them | SNAPSHOT 2026-11-12 |
| `testing/runs/` | Signed run sheets | Records |

### Evidence — `v2/evidence/`

`v2/evidence/<track>/<yyyy-mm-dd>-<slug>/` with screenshots, logs and a short `REPORT.md`
(Master Plan §7). No folder here, no `SEEN-IN-STUDIO`.

### Archive

| Folder | What it was |
|---|---|
| [v2/archive/](v2/archive/) | Handoff prompts and checkpoint reports (roadmap and art), superseded by the two master plans |
| [v1/](v1/) | Frozen v1 design and tech docs |
| [improvements/](improvements/) | Outside audit of 2026-11-14, its synthesis and reference photos |

## Where a new doc goes

- A rule or a priority: edit the relevant master plan, do not add a file.
- A decision: a row in `v2/plan/DECISIONS.md`.
- Proof that something ran: `v2/evidence/…/REPORT.md`.
- A dated audit or report: `v2/qa/`, with the date and a status word on top.
- A used-up prompt or checkpoint report: `v2/archive/`.
- Add a row to this page in the same commit.

Other: [SETUP.md](SETUP.md) covers a new machine.
