# Item 27 — CI (2026-11-19)

Status: **LUNE-ONLY** (CI config + local command verification; the GitHub-hosted run itself is
`UNVERIFIED` locally until GitHub executes it on push). Branch `track/c-world-look`.

## Findings

A workflow already existed at `.github/workflows/tests.yml`, so item 27 did not need a new file.
It was missing the required `selene src` step and triggered on every push; it now matches the item:

- `push` scoped to `main` and `track/*`; `pull_request` kept for PR checks.
- `CompeyDev/setup-rokit@v0.1.2` installs every tool pinned in `rokit.toml` onto PATH — confirmed
  from the action's README — including `selene` (`kampfkarren/selene@0.27.1`), `lune`
  (`lune-org/lune@0.11.1`), `rojo` and `luau-lsp`. Tools are therefore pinned via rokit as required.
- `Run tests`: `lune run tests/run.luau`.
- `Lint source`: `selene src`.

## Validation (local, with the same pinned tool versions)

- `lune run tests/run.luau` — **All 1930 tests passed**, exit 0.
- `selene src` — **0 errors / 0 warnings / 0 parse errors**, exit 0.
- Workflow YAML parsed with a YAML loader: keys `name/on/jobs`; `on.push.branches ==
  ['main','track/*']`; `jobs.unit.steps` includes both run steps. (`on` surfaces as boolean `True`
  under PyYAML 1.1 — a known YAML 1.1 quirk, not a workflow error; GitHub Actions parses it as the
  event key.)
- The actual GitHub Actions execution cannot be triggered from this machine; status stays
  `UNVERIFIED` until the push runs it on the remote.
