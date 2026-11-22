# Agent rules for this repository

Read the **Progress tracker** at the top of `docs/v2/plan/MASTER_PLAN.md` first: it says what is done,
what is next and where the evidence is, so you do not have to rediscover the repo. When you finish
a task, tick it there in the same commit. Then read the rest of `docs/v2/plan/MASTER_PLAN.md`. It governs what may be built, in what order, and how work is
proven. These rules sit on top of it and never override it. `docs/README.md` maps every other doc
and marks which are live, dated snapshots or archive.

## Team and authority (read this before anything else)

Three people build this game. Each one works with an AI agent, and every agent helps the same project in
the same direction.

| Person | GitHub | Role | Their agent |
|---|---|---|---|
| Owner and designer | @miralami | Sets direction, makes every design and visual call, the only one who approves merges into `main` | opencode (long runs from `WORK_QUEUE.md`) and Claude Code (review, Studio) |
| Willy | @willsyh | Code and general engineering: gameplay, server/client, data, tests, tooling, CI | Claude Code |
| Ragun | @lyciaryn | Design, 3D, Blender, map, terrain, assets | Claude Code |

**Find out who you work for first.** Run `gh api user --jq .login` (or `git config user.name` if `gh` is
not signed in). If it is `miralami`, you are the owner's agent and the rest of this file applies as
written. Anyone else is a contributor, and these rules override the ones below for you:

- **Direction belongs to @miralami.** `MASTER_PLAN.md`, `WORK_QUEUE.md`, `DECISIONS.md`, the visual
  verdicts in `docs/v2/visual/CANDIDATES.md` / `CANDIDATE_INDEX.md` and this file are owner-only. Read
  them, follow them, never rewrite them. If a task seems to need a change there, write the proposal in
  the PR description and let the owner decide.
- **Long-run mode below is not for you.** It is opencode's mode. Work only on what your human asked for,
  and do not tick `WORK_QUEUE.md` items unless your human says the owner gave that item to them.
- **Never push to `main` or `track/*`.** Work on `willy/<topic>` or `ragun/<topic>`, push that branch
  and open a PR into `main` using the PR template. The owner reviews and merges.
- **Stay in your lane** (see the area table in `CONTRIBUTING.md`). Willy's agent: code, tests, tooling,
  `Strings.luau`. Ragun's agent: models, `assets/`, map and terrain proposals, `docs/v2/visual/art/`.
  Touch another lane only when your human asks, and say so in the PR.
- **Pick from the owner's lists.** Good work: open defects in `docs/testing/BUGS.md`, unticked lines in
  `docs/testing/GATE1.md`, or a queue item the owner assigned by name. No new gameplay feature before
  Gate 1 passes (`MASTER_PLAN.md` §4), same as everyone.
- **Do not edit the live place.** Script changes go through Rojo in the repo; test in a personal copy
  of the place. Only @miralami saves or publishes the main place.
- **Before opening a PR:** `lune run tests/run.luau` passes, `selene src` is clean, stylua on the files
  you changed, player text has `id` and `en` in `Strings.luau`, new asset IDs are in
  `docs/v2/visual/art/ASSET_MANIFEST.md`, no secrets, no `.rbxl`. Visual changes carry Studio
  screenshots; whether a look ships is the owner's call.
- When unsure whether something matches the direction, ask your human to check with @miralami rather
  than guessing.

The owner's agents work directly on `main` (it is the working branch since 2026-11-22). Contributor PRs
merge into `main` too, so pull `main` before starting and rebase before opening a PR.

## Long-run mode (read this after every context compaction)

Long-run mode is for the owner's agents only (see "Team and authority"). If `docs/v2/plan/WORK_QUEUE.md`
has an unchecked item and you are the owner's agent, you are in long-run mode:

- **Do not end your turn.** Do not ask the user questions or write a "what's next?" report while
  any unchecked item is one you can do. The user is away.
- **After a compaction**, re-read `WORK_QUEUE.md`, the tracker, `BUGS.md` and `GATE1.md`. Then
  continue from the first unchecked item. Don't redo ticked items and don't summarize them.
- **Each item:** do the work, run the tests and selene, then tick the item in `WORK_QUEUE.md` and
  the tracker. Commit, push, and start the next item right away.
- **When a choice is the designer's** (balance, look, decisions), pick the safest reversible
  default, add it to the queue's "Decisions for designer" list, and keep going.
- **If an item is blocked**, mark it `BLOCKED — <reason>` and move on. Blocked items never stop
  the run.
- **Stop only** when every item is ticked or `BLOCKED`, including the refill item. Then write one
  final report: what was done (with commits), what is blocked, and the decisions list.

## Orchestration

- Default to orchestrating: the main session plans, dispatches, reconciles, verifies and commits.
  Implementation work goes to subagents (`fixer`, `explorer`, `librarian`, `oracle`, `designer`)
  unless the dispatch costs more than the work or the work needs a tool a subagent does not have.
- Independent lanes go out in parallel in one message; parallel writers must never share a file.
  Every dispatch names its scope, the files it may touch, and who validates the result.
- **Roblox Studio MCP is main-session only.** Subagents have `blender` and `github` and no Studio
  tools (verified 2026-11-14). Anything that starts a play session, runs `execute_luau` or captures a
  screenshot stays in the main session.
- **Visual judgment needs the vision observer.** An observer subagent running Gemini 3.8 can see
  screenshots and make visual calls; this main session cannot. For any visual yes/no (LookDev
  candidates, review shots, whether an asset reads well), delegate the review to that vision-capable
  observer (or the designer) — never call a visual result good from file contents or a text summary
  alone. Integrate assets off by default behind `LookDev`, record the review camera position, and
  let the vision pass decide.
- Claims are not evidence: read the diff or the file a lane produced before believing its summary.

## Rules that bite

- **Always commit and push finished work** (designer, 2026-11-14) without waiting to be asked: topical
  commits, no attribution lines, tracker ticked in the same commit, then push. The owner's agents push
  to `main`; contributors' agents push their own branch and open a PR. Never commit secrets.
- `lune run tests/run.luau` must pass before every commit; the current count is on the tracker's "Last updated" line.
- The Open Cloud key is the user env var `ROBLOX_API_KEY` (never print, log or commit it). Uploads
  land in the designer's inventory; record every resulting ID in `docs/v2/visual/art/ASSET_MANIFEST.md`.
- Status words are exactly `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`. A claim without a
  file under `docs/v2/evidence/` is not `SEEN-IN-STUDIO`.
- Never invent asset IDs, product IDs, prices or UserIds. Never publish, never save
  `JuraganDesa.rbxl` unless the task is track C.
- `docs/testing/BUGS.md` is the defect list; `docs/testing/GATE1.md` is the gate checklist; both are
  read before starting work. Bugs outrank features.
- No gameplay feature starts before Gate 1 passes (`MASTER_PLAN.md` §4).
- Player-facing text lives in `src/shared/Strings.luau` with `id` and `en` variants; `Strings.langFor`
  keys off the client locale, so an en-us Studio client shows English by design.
