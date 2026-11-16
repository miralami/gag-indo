# Docs map

Start at the **Progress tracker** in [v2/MASTER_PLAN.md](v2/MASTER_PLAN.md). This page says where
everything else lives and which files are still true.

- **LIVE**: kept current; trust it and update it.
- **SNAPSHOT**: true on the date in the file; re-check before relying on it.
- **ARCHIVE**: history only; never a source of rules or priorities.

## Read order for a new agent

1. [`../AGENTS.md`](../AGENTS.md): repo rules.
2. [v2/MASTER_PLAN.md](v2/MASTER_PLAN.md): tracker, phases, gates, definition of done.
3. [testing/BUGS.md](testing/BUGS.md) and [testing/GATE1.md](testing/GATE1.md): bugs outrank features.
4. Only then the reference doc for the task at hand, from the tables below.

## Plans and reference — `v2/`

| File | What it answers | State |
|---|---|---|
| [MASTER_PLAN.md](v2/MASTER_PLAN.md) | What is done, what is next, order, gates, how work is proven | LIVE |
| [DECISIONS.md](v2/DECISIONS.md) | Designer decisions (D1…, D-G…) and open questions | LIVE |
| [PLAN.md](v2/PLAN.md) | Feature reference: what each system is, v2.0 to v2.3 | LIVE |
| [TECH.md](v2/TECH.md) | Code conventions: server authority, state, remotes, tests | LIVE |
| [ART.md](v2/ART.md) | Art bible: palette, line, rarity, type, lighting | LIVE |
| [TOOLS.md](v2/TOOLS.md) | Asset pipeline, upload routes, licences | LIVE |
| [ANALYTICS.md](v2/ANALYTICS.md) | Events, triggers, the questions they answer | LIVE |
| [LAUNCH.md](v2/LAUNCH.md) | Store copy, rating questionnaire, launch checklist | SNAPSHOT 2026-11-12, draft |
| [DELEGATION_PROMPT.md](v2/DELEGATION_PROMPT.md) | Prompt to paste into a second agent | LIVE |

## Art — `v2/art/`, `v2/mockups/`

| File | What it answers | State |
|---|---|---|
| [art/ASSET_MANIFEST.md](v2/art/ASSET_MANIFEST.md) | Every asset: slot, source, licence, ID | LIVE |
| [art/MAP_SPEC.md](v2/art/MAP_SPEC.md) | Map coordinates and layout (mirrored in `MapSpec.luau`) | LIVE |
| [art/map/RECONCILIATION.md](v2/art/map/RECONCILIATION.md) | Where MAP_SPEC and the outside map brief differ, and who wins | LIVE |
| [art/map/full-package/](v2/art/map/full-package/) | Outside map brief: dressing cards, kit table, plans | Reference; MAP_SPEC wins |
| [art/ICONS.md](v2/art/ICONS.md), [art/TEXTURES.md](v2/art/TEXTURES.md), [art/npcs.md](v2/art/npcs.md) | Production briefs per icon, texture and NPC | LIVE |
| [art/RESEARCH_VISUAL_TIPS.md](v2/art/RESEARCH_VISUAL_TIPS.md) | Visual tips applied and the optimise-later backlog | LIVE |
| `art/models/`, `art/moodboard.html` | Source models and moodboard | Assets |
| [mockups/juragan-ui.tokens.md](v2/mockups/juragan-ui.tokens.md), `mockups/index.html` | UI mockups and tokens (not wired in) | SNAPSHOT 2026-11-15 |

## Testing — `testing/`

| File | What it answers | State |
|---|---|---|
| [BUGS.md](testing/BUGS.md) | Defect list | LIVE |
| [GATE1.md](testing/GATE1.md) | Gate 1 working checklist | LIVE |
| [HARNESS.md](testing/HARNESS.md) | Studio playtest routine through the harness | LIVE |
| [CODE_AUDIT.md](testing/CODE_AUDIT.md) | Per-task Lune audit log (T1–T16) | LIVE |
| [README.md](testing/README.md) | The three test layers and how to run them | LIVE |
| [PLAYTEST_PLAN.md](testing/PLAYTEST_PLAN.md), [PLAYTEST_CASES.md](testing/PLAYTEST_CASES.md) | v2 Studio scenarios and executable cases | SNAPSHOT, written before the Master Plan |
| [ART_PLAYTEST_PLAN.md](testing/ART_PLAYTEST_PLAN.md) | Art-pass visual checks (W3–W8) | SNAPSHOT, written before the Master Plan |
| [MANUAL_TESTS.md](testing/MANUAL_TESTS.md), [runs/TEMPLATE.md](testing/runs/TEMPLATE.md) | v1-era case catalogue and run sheet | SNAPSHOT 2026-11-10 |
| `runs/` | Signed run sheets | Records |

## Audits — `v2/audits/`

Static reports written 2026-11-12 from reading code, without runtime evidence. Master Plan Phase 4
re-runs each one with evidence; until then a "PASS" here is `LUNE-ONLY` at best.

[SECURITY_AUDIT.md](v2/audits/SECURITY_AUDIT.md) ·
[PERF_AUDIT.md](v2/audits/PERF_AUDIT.md) ·
[FTUE_AUDIT.md](v2/audits/FTUE_AUDIT.md) ·
[LOCALIZATION.md](v2/audits/LOCALIZATION.md) ·
[BALANCE.md](v2/audits/BALANCE.md)

## Evidence — `v2/evidence/`

`v2/evidence/<track>/<yyyy-mm-dd>-<slug>/` with screenshots, logs and a `REPORT.md` of at most twenty
lines (Master Plan §7). No folder here, no `SEEN-IN-STUDIO`.

## Archive — `archive/`

| Folder | What it was |
|---|---|
| [archive/v1/](archive/v1/) | v1 GDD and tech guide. v2 `PLAN.md` and `TECH.md` build on them. |
| [archive/handoffs/](archive/handoffs/) | Handoff prompts and checkpoint reports from before 2026-11-14, superseded by the Master Plan. |
| [archive/2026-11-14-outside-audit/](archive/2026-11-14-outside-audit/) | Outside audit, its synthesis (`SINTESIS.md`) and reference photos. Parked ideas are linked from the Master Plan. |

## Where a new doc goes

- A rule or a priority: edit the Master Plan, do not add a file.
- A decision: a row in `DECISIONS.md`.
- Proof that something ran: `v2/evidence/…/REPORT.md`.
- A dated report or audit: `v2/audits/`, with the date and a status word on top.
- A prompt for another agent, once used: `archive/handoffs/`.
- Add a row to this page in the same commit.

Other: [SETUP.md](SETUP.md) covers a new machine.
