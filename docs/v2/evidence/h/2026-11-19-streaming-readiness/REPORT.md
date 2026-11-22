# C — StreamingEnabled readiness audit — 2026-11-19

Track C, `WORK_QUEUE.md` item 13. Static audit of whether the client would still work if Roblox
`StreamingEnabled` were turned on, with the safe patterns locked by a new spec. **The setting was
NOT flipped** — that is a designer decision (recorded at the end). No Studio playtest was needed
because nothing was changed at runtime; status is `LUNE-ONLY`.

## Audit method

Grepped and read every `.luau` file under `src/` (71 `WaitForChild` calls, 26 of them under
`src/client`), then classified each call by receiver and timeout, and traced every client path that
reads a world part. Findings are reproducible with `tests/specs/streaming_readiness_spec.luau`.

## Result: the shipping client is already streaming-safe

**No unbounded `WaitForChild` on a streamable world path.** Of the 71 calls:

- 57 are `WaitForChild("Shared")` on `ReplicatedStorage`, which is always replicated. Client and
  server modules use this as a boot strap; streaming cannot affect it.
- `src/shared/Remotes.luau:70,73` — `"Remotes", 30` and `remote, 10`: both bounded.
- `src/client/World/Sky.luau:29` — `Workspace:WaitForChild("Terrain", 10)`: bounded.
- `src/client/Feel/CameraFeel.luau:98` — `character:WaitForChild("Humanoid", 10)`: bounded; a
  character is never streamed out.
- `src/client/UI/Theme.luau:311` — `player:WaitForChild("PlayerGui")`: no timeout needed; PlayerGui
  is always replicated to its owner.

**World-part discovery already uses streaming-safe mechanisms.** CollectionService tags travel with
an instance as it streams in/out, and every consumer either listens to added/removed signals or
re-polls:

| Tag | Emitted by | Client consumer | Reacts to streaming |
| --- | --- | --- | --- |
| `Tile` | `PlotService:92` (comment: "works with streaming") | `UI/Tiles`, `UI/Phone`, `Feel/ActionFeel` | poll / `GetTagged` each tick |
| `WindShake` | `Flora:300` | `World/Wind` | `GetInstanceRemovedSignal` |
| `NpcSpawn` | `Map.luau:34,52` | `World/LookDevNpcs` | `GetInstanceAddedSignal` |
| `LeaderboardBoard` | place file | `UI/Leaderboard` | added + removed signals |
| `MusicZone` | place file | `Audio` | `ZONE_POLL` re-evaluation |

`UI/Phone.luau:558-586` `neighborPlayers()` is the only shipping module that takes a workspace
child snapshot (`workspace:FindFirstChild("World")` + `GetChildren()`). It is nil-guarded at both
levels, validated by attribute type, re-run on every `refreshCheatTab` tick, and its primary data
source is `CollectionService:GetTagged("Tile")`. A streamed-in neighbour plot therefore appears on
a later refresh — no unbounded wait, no unsafe direct index. No `workspace.World.X` dot chains or
unchecked world-part child indexing were found elsewhere in the shipping client.

**Dev-only limitation (not fixed, parked).** `LookDevPlaza`, `LookDevTextures`, `LookDevHubProps`
and `LookDevCrops` each scan the workspace once with `FindFirstChild`/`GetDescendants` and have no
`DescendantAdded` re-scan. With streaming on, a hub part streamed out at enable time could be missed.
All four are LookDev review tools: off by default, never ship, and used in a small Studio review
area. No delivered art or shipping path is affected; this is recorded with the designer proposal
rather than changed mid-run.

## Spec added

`tests/specs/streaming_readiness_spec.luau` (registered in `tests/run.luau`), four cases:

1. no client `WaitForChild` on a streamable path is missing its timeout (with a non-vacuous floor
   of 20 scanned calls),
2. self-check — the classifier flags `workspace:WaitForChild("World")` but accepts the same call
   with a timeout, and accepts `"Shared"` while flagging an unrelated `"Inventory"`,
3. every world-part consumer (Audio, Wind, ActionFeel, Phone, Tiles, Leaderboard, LookDevNpcs)
   discovers through `CollectionService:GetTagged`,
4. shipping (non-LookDev) workspace child snapshots are only a supplement to a tag path.

**Mutation-checked:** a temporary `src/client/StreamingMutationProbe.luau` containing
`workspace:WaitForChild("GhostPart")` made the suite fail `1 FAILED, 1971 passed` (exit 1) with an
error naming the file and the call. The probe was removed; the suite returned to **1972 passing**.
`selene src`: 0 errors / 0 warnings / 0 parse errors. No Studio place saved or published.

## Decision for the designer

Do **not** flip `StreamingEnabled` from an agent. If the designer enables it to reduce initial load
on low-tier devices, first run G6 real-device fps and the full Q5 multi-client pass, then accept or
revert. The four LookDev review tools may need a `DescendantAdded` re-scan if they are to be used
with streaming on (dev-only, off by default, so not blocking). Added to WORK_QUEUE
"Decisions for designer".
