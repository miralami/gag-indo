# Respawn and rejoin — Track H, 2026-11-19

WORK_QUEUE item 13: audit every `CharacterAdded` / respawn handler for duplicate connections,
check the UI survives a character reset, and run a 10-reset Studio loop.

## Audit: every character-scoped connection in `src/`

| Module | Connection | Bound where | Leak risk on respawn | Verdict |
|---|---|---|---|---|
| `server/Farm/FarmService` | `player.CharacterAdded:Connect(onCharacter)` → wait 0.2s → `teleportToPlot` | inside `onLoaded` (= once per session, on join) | none: `onLoaded` runs once per player; rejoin is a new Player object | one connection; teleport fires once per respawn |
| `server/Monetization/Cosmetics` | `player.CharacterAdded:Connect(...)` → wait 0.3s → `applyVisual` | inside `PlayerData.onLoaded` (= once per session) | none: same reason | one connection; cosmetic reapplied to each new character |
| `client/Feel/CameraFeel` | `CharacterAdded` / `CharacterRemoving` / `Heartbeat` | `start()`, guarded by `started` | none: `start()` is idempotent; `stop()` disconnects all; `bind` uses a generation counter so a late `WaitForChild` cannot bind a stale character | connections stay at 1 each across resets |
| `client/UI/RaidOverlay` | per-cutscene `CharacterRemoving` + `humanoid.Died` in `deathConnections` | on cutscene play | none: `endCutscene` → `disconnectAll()` disconnects and clears the list on every end/skip/cancel/death | bounded per cutscene, cleared |
| `client/Feel/PerfSwitches`, `client/Feel/FidelityRuntime`, `client/Feel/FpsSampler` | `DescendantAdded` / `Heartbeat` / run hooks | start/stop lifecycle | none: all store the connection and `Disconnect()` on teardown (already spec'd in `perf_hotpath_spec`) | verified, no change |

Every `CharacterAdded` connection is created **once per player session** (in a `PlayerData.onLoaded`
handler or an idempotent `start()`), never inside another `CharacterAdded` callback, so repeated
respawns cannot multiply handlers. No production fix was needed.

## New specs — `tests/specs/respawn_rejoin_spec.luau` (5 cases, `LUNE-ONLY`)

- **FarmService**: `CharacterAdded` connects once per session; firing it 10 times keeps exactly one
  fake-signal handler and calls `teleportToPlot` exactly 10 times (once per respawn, no stacking).
- **Cosmetics**: `CharacterAdded` connects once; 10 respawns build exactly 10 hats + 10 welds, one
  per reset — old visuals are removed first, so no per-respawn accumulation.
- **CameraFeel**: `start()` connects its three character-scoped signals once; 10
  `CharacterRemoving`→`CharacterAdded` cycles keep each at one handler; `stop()` clears all three.
- **UI after reset**: `Theme.screenGui` creates every HUD ScreenGui with `ResetOnSpawn = false`, so a
  character reset never destroys or rebuilds the HUD. The deliberate phone-page rebuild path
  (close → destroy → reopen → rebuild) is already covered by the 12 cases in `lazy_pages_spec`.

All run against real module code with mocked dependencies in `Env`; no UserIds or IDs invented.

## Studio 10-reset loop — `SEEN-IN-STUDIO`

`Development-Juragan-Desa` (placeId `132087524375529`), Play Solo, Rojo `localhost:34872`, fresh
mock profile. In the **Server** datamodel, killed the local player's Humanoid (`Health = 0`) and
waited for `Character` to be replaced, ten times in a row; after each reset waited for the plot
teleport. Boot console clean (`[JuraganDesa] server started`, no game-code errors).

- All 10 resets produced a new character; each respawned at the **same** plot position
  `53, 4, -162` (no drift that stacked/missing teleport handlers would cause).
- Final character: fresh `Humanoid` at `Health = 100`.
- **Client** `PlayerGui` after 10 resets: still exactly **11 ScreenGuis** (Chat, BubbleChat, Hud,
  Phone, Minigame, RaidOverlay, AdminPanel, Leaderboard, Freecam, TouchGui, Toasts), **0** with
  `ResetOnSpawn = true` — the UI survived all ten resets with no loss and no duplication.

Note on the literal "connection count": Roblox Studio exposes no public API to count the
connections on an engine `RBXScriptSignal`, and the `execute_luau` bridge runs in a separate Lua VM
from the game's server scripts (its `require` cache is distinct), so the game's live module functions
cannot be monkeypatched to count connections. The Studio loop therefore proves the observable
invariants (one plot teleport's worth of positioning per reset, stable UI instance count, clean
console); the exact one-handler-per-session counts are locked by the fake-signal Lune specs above.

Place was **not saved** and not published; Play Solo was stopped after the loop.

## Proof

- `lune run tests/run.luau`: **1803 passing** (was 1798).
- `selene src`: 0 errors / 0 warnings / 0 parse errors.
- New spec + registry entry in `tests/run.luau`; no game source changes (connections were already correct).
