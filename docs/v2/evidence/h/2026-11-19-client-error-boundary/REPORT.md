# Client error boundary — WORK_QUEUE round-2 item 18

**Status:** `LUNE-ONLY`
**Date:** 2026-11-19
**Branch:** `track/c-world-look` (HEAD at time of writing: item 17 `8a20610`)
**Spec:** `tests/specs/client_error_boundary_spec.luau` (4 cases), registered in `tests/run.luau`
**Harness helper:** `Env:addScript(path)` added to `tests/lib/Env.luau`

## What was done

`src/client/Main.client.luau` previously called every UI/feel `mount()`/`start()` in a bare
sequence: one throwing module aborted the bootstrap before the rest mounted, leaving the client
with a half-initialised HUD. Each mount/start is now wrapped in a `guarded(name, fn)` boundary:

```lua
local reported = {}
local function guarded(name: string, fn: () -> ())
    local ok, err = pcall(fn)
    if not ok and not reported[name] then
        reported[name] = true
        warn(`[Main.client] {name} failed to start: {tostring(err)}`)
    end
end
```

All 18 bootstrap calls are guarded (State/Audio/Sky/Wind/CameraFeel/FidelityRuntime/FpsSampler/
ActionFeel, then Hud→Evidence→Phone→Minigame→RaidOverlay→Admin→Leaderboard→Tags→Tiles, then
NavBridge). `hudGui` is captured through `guarded("Hud.mount", ...)` and passed to
`Evidence.mount` exactly as before — a failed Hud leaves `hudGui = nil`, which `Evidence.mount`
already tolerates (and which is itself guarded). The LookDev `pcall(require, ...)` lines are
unchanged. Every original call, argument and ordering is byte-for-byte preserved; only the
`pcall` wrapper and one-time `warn` are new.

`reported[name]` makes the "log once" guarantee explicit even if a name is ever guarded twice
in a future edit. Normal (non-throwing) boot is silent — no extra warns, no behaviour change.

## Spec method

`Env:addScript("client/Main.client")` mounts the real bootstrap source as a loadable node (entry
scripts are skipped by `mountDirectory` because they are not ModuleScripts in Studio). The spec
mocks only the leaf modules: `shared/Strings` plus every UI/World/Feel/Audio/State/Tags/NavBridge
module is a stub that records `path.method` calls and optionally `error()`s on a named call.
All seven LookDev modules are mocked to `{}`. Then the spec `pcall(require)`s the real
`Main.client` and inspects the recorded call list and `env.warnings`.

A guard map (e.g. `["client/UI/Hud.mount"] = true`) forces a real throw from that module.

## Cases (4)

1. failing UI module (`Hud.mount`) — bootstrap does not throw, all 18 expected calls still made,
   exactly one `Hud.mount` warning.
2. failing feel module (`CameraFeel.start`) — isolated, one warning, all other mounts run.
3. three simultaneous failures (`Phone.mount`, `ActionFeel.start`, `NavBridge.start`) — each
   warned once, `#warnings == 3`, mount loop completes.
4. clean boot — all 18 calls made, zero warnings.

EXPECTED deliberately treats `client/Chat/Tags` as `mount` (`Tags.mount(lang)`), matching the
real bootstrap; the first draft stubbed `Tags.start` and the spec caught its own mismatch,
which was corrected in the spec (no production change).

## Mutation check

Temporarily replacing `local ok, err = pcall(fn)` with a direct `fn()` call made cases 1–3 FAIL
(the forced throw propagated out of `env:require`), while the clean case still passed. The
mutation was reverted; the final run is green. This proves the boundary — not a spec artefact —
is what keeps the remaining modules mounting.

## Validation

- `lune run tests/run` — **1993 passing** (was 1989; +4 cases), exit code 0, no FAIL lines.
- `selene src` — **0 errors, 0 warnings, 0 parse errors**, exit code 0 (one-liner
  `function() X() end` guards were expanded to multiline to keep the gate at zero warnings).

No place was saved or published. No `JuraganDesa.rbxl` saved. No API key printed, logged or
committed. No balance/config change.
