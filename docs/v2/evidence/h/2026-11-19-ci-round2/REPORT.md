# Round 2 — CI green (2026-11-19)

WORK_QUEUE round 2 item 2. Status `SEEN-IN-STUDIO` — the GitHub-hosted run was read with `gh`,
not just reproduced locally. Branch `track/c-world-look`, repo `miralami/gag-indo`.

## Runs read

| Run id | Commit | Conclusion |
|---|---|---|
| 44458499132 | `a618f02` | failure — `dead_code_spec` "item 25: Rojo mappings resolve > $path Packages exists on disk" |
| 44472087680 | `47c0802` (refresh) | success — the Packages mapping-spec fix landed |
| 44473085751 | `0fc058d` (round-2 item 1) | success |

`gh run list --repo miralami/gag-indo --branch track/c-world-look` and
`gh run view 44458499132 --log-failed` were used. The historical failure was exactly the
gitignored-generated-dir issue that the refresh commit `47c0802` fixed; it did not recur.

## Change this item

`.github/workflows/tests.yml`: `actions/checkout@v4` → `actions/checkout@v5`. The failed run's log
ended with `##[warning]Node.js 20 is deprecated ... actions/checkout@v4 ... forced to run on
Node.js 24`. `actions/checkout@v5` was confirmed to exist (`gh api repos/actions/checkout/tags`
lists v5/v6/v7; `git/ref/tags/v5` resolves) and its `action.yml` declares `using: node24`. The
nested `actions/cache` inside `CompeyDev/setup-rokit@v0.1.2` is skipped in this workflow because
`cache` defaults to `false`, so checkout was the only Node 20 action that ran. No other workflow
change; rokit pins all tool versions as before.

## Validation

- YAML parsed with PyYAML: `jobs.unit.steps[0].uses == actions/checkout@v5`; keys `name/on/jobs`
  intact.
- Local, with the pinned rokit tools: `lune run tests/run.luau` → All 1929 tests passed (exit 0);
  `selene src` → 0 errors / 0 warnings / 0 parse errors (exit 0).
- After this change is pushed, re-read `gh run list` to confirm the new run is green and the
  Node 20 warning is gone; that result is recorded in the tracker entry for this item.
