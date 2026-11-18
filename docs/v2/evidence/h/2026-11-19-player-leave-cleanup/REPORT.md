# Player leaves mid-state — Track H, 2026-11-19

WORK_QUEUE item 12: for every state a player can be in, confirm the server cleans up on
`PlayerRemoving` — no orphan tasks, NPCs, attributes or locks. Specs first, then a Studio check.

## Inventory: every PlayerRemoving handler in `src/`

| Module | Handler | Prior coverage | This item |
|---|---|---|---|
| `Data/PlayerData` | `release()`: runs `onBeforeRelease` callbacks (raid, Net/State), then `profile:EndSession()` | `data_pass_failure_spec` (leave mid-load never registers), `raid_failure_spec` (fine once, stale choices ignored) | verified, no change |
| `Law/RaidService` | `onBeforeRelease` → `resolveOnLeave`: fine + cooldown + stat once, clears `raids[player]` | `raid_failure_spec` (4 leave cases incl. double-leave, throwing callback) | verified, no change |
| `Net/State` | `onBeforeRelease` → `dirty[player] = nil` | none | **new**: `player_leave_cleanup_spec` |
| `Economy/DebtService` | dismisses the collector NPC via `collectorApi.dismiss(player)` | none | **new** |
| `Farm/FarmService` | clears `selectedSeed` / `pending` / `growing[player]` | `farm_failure_spec` (`R2` pending dropped), `harness_spec` (stale `Farm_Complete` pays nothing) | verified, no change |
| `Farm/PlotService` | `PlotService.release(player)` | `plot_failure_spec` (release + idempotent double-leave) | verified, no change |
| `Law/EvidenceService` | drops `offers[UserId]` and every token with `ownerUserId == UserId` | `evidence_failure_spec` covers a cheater who is *gone from Players* at report time, not this handler | **new** |
| `Live/AdminService` | clears the `IsAdmin` attribute | none | **new** |
| `Net/RateLimit` | `buckets[player] = nil` | `ratelimit_spec` ("forgets a player who leaves") | verified, no change |
| `Progression/FirstSession` | `joinTimes[player] = nil` | `first_session_failure_spec` (player left ignored), but not this timer cleanup | inspected; pure in-memory timer map, no observable orphan |
| `Social/LeaderboardService` | `record(player, true)` final flush | `cosmetics_leaderboard_failure_spec` (departing save already gone is skipped) | **new**: handler fires the flush |
| `Testing/Harness` | `Gate.close()` so one player's flag never leaks | `harness_spec` (`Gate.close` unit), but not the leave wiring | **new** |

Client-side state (`RaidOverlay` `CharacterRemoving` abort, `CameraFeel` character unbind) is
covered by `raid_failure_spec` / `camerafeel_spec`; the item is about server cleanup, so those are
not re-tested here.

## New specs — `tests/specs/player_leave_cleanup_spec.luau` (10 cases, `LUNE-ONLY`)

- **Debt collector NPC**: collector dismissed exactly once with the departing player as argument;
  leaving with no collector bound is safe.
- **IsAdmin attribute**: cleared when an admin leaves; a non-admin leaving is a safe no-op.
- **Leaderboard final flush**: departing player's score written on `PlayerRemoving`; a departing
  player with no save is skipped without error.
- **Harness gate**: an open gate is closed on any player leave (no flag leak between sessions).
- **Evidence offers/tokens**: a departing reporter's tokens are dropped; a later report of a token
  owned by a departed player pays nothing.
- **Net/State release hook**: a `PlayerData.onBeforeRelease` hook is registered and safely clears a
  touched player (no throw).

All run against the real module code with mocked dependencies in `Env`. No product/UserIds invented
— UserIds come from `Fakes.player`.

## Studio check — partial `SEEN-IN-STUDIO`, leave-transition `BLOCKED`

`Development-Juragan-Desa` (placeId `132087524375529`), Play Solo, Rojo `localhost:34872`,
fresh mock profile. Boot console: `[JuraganDesa] server started`, no game-code errors (the one
`AssistantCommand` error was the probe script itself, not game code). In the **Server** datamodel,
executed against the live loaded modules:

- `require("Server/Law/RaidService").resolveOnLeave(player, {})` with no active raid → `ok=true`.
- `require("Server/Testing/Gate")`: `enable()` → `isOpen()=true`, `close()` → `isOpen()=false`.
- `require("Server/Law/EvidenceService").tokenCount(player)` → `ok=true, n=0`.

The **actual leave transition** (put a player into a raid/debt/minigame state and observe the server
at the instant they leave) is `BLOCKED — Roblox Studio MCP cannot fire the engine
`Players.PlayerRemoving` signal from Luau (`Fire is not a valid member of RBXScriptSignal`) and has
no local-server/team-test tool to spawn a second player who can disconnect; Play Solo has one local
player whose departure ends the session.` Same tooling gap as the Q5 multi-client block. The server
side of every handler is nonetheless locked by the Lune specs above, and the real-engine helpers
were exercised successfully.

Place was **not saved** and not published; Play Solo was stopped after the probe.

## Proof

- `lune run tests/run.luau`: **1798 passing** (was 1788).
- `selene src`: 0 errors / 0 warnings / 0 parse errors.
- New spec + registry entry in `tests/run.luau`; no game source changes (cleanup was already correct).
