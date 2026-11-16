# Docs index

Start with `AGENTS.md`, then the tracker at the top of the build plan.

## Two master plans (separate on purpose)

| Plan | Governs | Tracker |
|---|---|---|
| [v2/plan/MASTER_PLAN.md](v2/plan/MASTER_PLAN.md) | What may be built, in what order, how work is proven (gates, bugs, evidence). Wins on ordering and "done". | Top of the file |
| [v2/visual/VISUAL_MASTER_PLAN.md](v2/visual/VISUAL_MASTER_PLAN.md) | Everything the player sees: light, materials, models, VFX, camera, UI fidelity. Sits under the build plan. | Top of the file |

## Layout

- `v2/plan/`: build side. MASTER_PLAN, PLAN (feature reference), DECISIONS, TECH, BALANCE, ANALYTICS, LOCALIZATION, LAUNCH, TOOLS, DELEGATION_PROMPT.
- `v2/visual/`: visual side. VISUAL_MASTER_PLAN, ART (bible), ART_CHECKPOINT_*, ART_PLAYTEST_PLAN, `art/` (map spec, assets, models), `mockups/`.
- `v2/qa/`: audits (FTUE, perf, security) and playtest plan/cases.
- `v2/evidence/`: proof files behind every `SEEN-IN-STUDIO` claim, by track and date.
- `v2/archive/`: superseded handoff prompts and old checkpoint reports.
- `testing/`: BUGS, GATE1, harness, manual tests, run logs.
- `v1/`: frozen v1 design and tech docs.
- `improvements/`: external audit and its synthesis.
- `SETUP.md`: environment setup.
