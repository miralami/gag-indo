# Playtest Harness — Studio routine

> Refreshed 2026-11-19 (WORK_QUEUE item 28): the `raid` / `raidState` hooks are now documented in
> §1. No harness step was re-run for this refresh; the verification claims below are unchanged.

**Status: sections 2–4 and 9 ran on 2026-11-14** in Studio Play Solo, iPhone 14 device
emulation, Rojo synced, Studio API services on. Those steps are `SEEN-IN-STUDIO` (see the
§10 table); §6 screenshot automation, the 10-player session and the soak are still
`UNVERIFIED`. The gating logic stays `LUNE-ONLY` (`tests/specs/harness_spec.luau`).

What the run proved: the smoke check returned exactly `Harness is off. Enable it from a Studio
admin first.` and `enable` returned `Harness on.`, so the 2026-11-13 prompt blocker is solved
and the harness remote round trip works. The full loop (plant, ready, harvest, sell, buy) ran
twice with the real services, and save → stop → play → `status` came back with cash 48,
`padi` 6 and tilesOwned 6, so persistence works against real Studio DataStores (not a
published place). Evidence: `docs/v2/evidence/h/2026-11-14-phase0/`.

The harness exists because the 2026-11-13 run could not plant, harvest, sell or buy: the
Studio MCP bridge sent `E`, but `ProximityPrompt.Triggered` never fired, so the tile stayed
empty and the seed count never moved. See "The prompt problem" below.

---

## 1. What the harness is

Test-only server hooks in `src/server/Testing/`, started from one line in
`src/server/Main.server.luau`. The driver sends `Harness_Command` and reads `Harness_Result`
(both appended in `src/shared/Remotes.luau`). Nothing in the loop needs key input.

| Action | `value` | Does |
|---|---|---|
| `enable` | — | Opens the gate. Studio admin only. |
| `disable` | — | Closes it again (teardown). |
| `status` | — | Read-back: cash, seeds, tiles, rank, tutorial step, sack, gudang, quests, shop stock, position. |
| `plant` | `{ tile = 1, cropId = "padi" }` | Plants on a specific owned tile, spends one real seed. Omit `tile` for the first empty one. |
| `ready` | — | Makes every growing crop ready now (no waiting out grow timers). |
| `harvest` | `{ tile = 1 }` | Real harvest (rarity, traits, almanak, onboarding, quests), landed in the sack. Omit `tile` for the first ready one. |
| `sell` | `{ channel = "pasar" }` or `"gelap"` | Teleports to the stall, then the real sale. |
| `buy` | `{ cropId = "padi", amount = 2 }` | Real shop purchase (needs shelf stock, rank and cash). |
| `quest` | `{ taskId = "..." }` or omitted | Claims that daily task, or the login reward. |
| `goto` | `{ name = "plot" }` | Stands the character somewhere worth a screenshot: `plot`, `tile`, `pasar`, `gelap`, `pakrt`, `polisi`, `ronda`, `warung`. |
| `save` | — | `profile:Save()` now, so persistence does not depend on leaving cleanly. |
| `raid` | omitted, or `{ viral = true, force = true }` | Starts a raid immediately so the cutscene, camera and choice window can be observed without waiting ~5:30. `viral = true` forces a VIRAL raid; `force = true` clears the cooldown only for this call (restored afterwards, so saves are untouched). Behind an extra Studio+flag+admin gate (`RaidTrigger`). |
| `raidState` | — | Read-back of the current raid state, `InRaid` attribute and `isBusy` — use it to confirm a forced raid fired. |

The two raid hooks live in `server/Testing/RaidTrigger.luau` (pure policy) and `Harness.luau`
(handler). All three gate conditions (Studio + in-memory flag + admin) must be literally true;
the cooldown override never writes into saved data. `raid`/`raidState` need no scripted input.

Read-back is a single `Harness_Result` table; the plain scalars are already mirrored on
player attributes (`Cash`, `Rank`, `TutorialStep`, `TilesOwned`, `Seed_<crop>`, `ShopStock_<crop>`).

### How the gate works

Three conditions, all required, checked on every hook (`src/server/Testing/Gate.luau`):

1. `RunService:IsStudio()` — **false in any published server, so the harness cannot run there.**
2. The in-memory flag, opened only by `enable`.
3. `Admins.isAdmin(player.UserId)` — the same allowlist `AdminService` uses (`Admins.luau`).

The flag is never saved anywhere, so a published place cannot remember it as on. Hooks are
rate limited to 4/s per player with the existing `RateLimit` token bucket. Nothing mints cash
or items: plant spends a real seed, harvest runs the real `doHarvest`, sell/buy are the real
service calls, and saves still go through `PlayerData` (no `migrate` bypass).

---

## 2. Launch checklist

1. Repo root: `rojo serve` (leave it running).
2. Studio, `JuraganDesa.rbxl` open: Plugins → Rojo → **Connect**. Wait for "Synced".
3. Game Settings → Security → **Enable Studio Access to API Services** (only needed for the
   persistence step; without it, `[ProfileStore]: Roblox API services unavailable` is expected
   and saving cannot be verified).
4. Test tab → Device → **iPhone 14** (390x844) for phone size. Desktop screenshots later with
   Device → **Desktop**.
5. Play Solo (F5). Wait for `[JuraganDesa] server started` in Output. No red errors.

## 3. Smoke check — is the bridge alive?

Studio command bar, while playing (runs in the client context):

```lua
local R = game:GetService("ReplicatedStorage").Remotes
R.Harness_Result.OnClientEvent:Connect(print)
R.Harness_Command:FireServer({ action = "status" })
```

- Prints `Harness is off. Enable it from a Studio admin first.` → **bridge alive, harness off**.
  Good: this is the expected first result, and it also proves the gate is closed.
- Prints a state table → the harness is already on.
- Prints nothing → the bridge or the server bootstrap is dead. Check Output for
  `[JuraganDesa] server started`, and that `src/server/Testing/Harness.luau` synced.

Then enable it:

```lua
R.Harness_Command:FireServer({ action = "enable" })
```

Expect `{ ok = true, message = "Harness on." }`.

## 4. The loop, in order

Run each line in the command bar and check the printed `Harness_Result` before the next one.
The `status` numbers are the evidence that the action really happened.

1. `{ action = "status" }` → fresh save: cash 50, `padi` seeds 5, tiles 6, rank `gurem`,
   tutorial `plant`.
2. `{ action = "plant", value = { tile = 1, cropId = "padi" } }` → seeds 4, tile 1 planted.
3. `{ action = "ready" }` → tile 1 `ready = true` (`shifted` = 1).
4. `{ action = "harvest", value = { tile = 1 } }` → sack 1, tutorial moves to `harvest`.
5. `{ action = "sell", value = { channel = "pasar" } }` → cash up, sack 0, tutorial `sell`.
6. `{ action = "buy", value = { cropId = "padi", amount = 2 } }` → seeds up, cash down.
   Only crops in today's shelf (see `shop` in `status`) can be bought.
7. `{ action = "quest" }` → login reward; `{ action = "quest", value = { taskId = "..." } }`
   for a finished task (ids are in `status.quests`).
8. Screenshot state: `{ action = "goto", value = { name = "plot" } }`, then take the phone
   screenshot (section 6), then repeat at desktop size.
9. `{ action = "save" }` → `ok = true` with API services on. Stop the session (Shift+F5),
   press Play again, `status` → cash/seeds/tiles match what you saved. That is the
   persistence check (still Studio DataStore, not a published place).

## 5. The prompt problem, and what this works around

`ProximityPrompt.Triggered` is a client-side input event. On 2026-11-13 the bridge could not
make `E` reach it, so no tile prompt fired and the whole loop was stuck. The harness drives
the same server code without a prompt, through one seam:

```lua
FarmService.commitAttempt(player, { tile = 1, action = "plant", cropId = "padi" }, quality)
```

It sets `pending[player]` exactly as the prompt path does and calls the existing local
resolver, so `canPlant`, the empty-tile check, `doPlant` (seed cost, grow time from
`ToolService.growSeconds`, quality formula) and `doHarvest` (rarity, traits, almanak,
onboarding, quests) are the real ones. Harvest goes through the same seam and lands in the
sack, as a player's would. `tests/specs/harness_spec.luau` proves the seam spends one seed,
uses the real grow time and quality, and fires each hook once.

What still differs from a real player: the minigame quality is `GameConfig.autoQuality` (the
same value the server's own `Farm_Auto` path uses), and there is no prompt reach or
interaction cooldown because the harness performs the prompt path's ownership check itself.
No gameplay rule is re-implemented in the harness; a refused attempt is only *explained* by
`plantRefusal` after `FarmService` rejects it. If the prompt path ever changes, change the
seam with it — the harness then follows automatically.

Not covered by the harness, and still needing a human: the minigame itself, prompt visibility
and reach, and anything that is feel.

## 6. Screenshots

Evidence goes to `docs/v2/evidence/<track>/<yyyy-mm-dd>-<slug>/` (Master Plan §7).

- Automated bridge capture is `UNVERIFIED`: the 2026-11-13 run reported no screenshot
  capability. If the connected bridge has one, pass the target path explicitly and confirm the
  file exists.
- Manual fallback (always works): keep the device emulator on, `Win+Shift+S`, drag the region,
  then paste/save into the evidence folder. Name `phone-01-spawn.png`, `phone-02-plant.png`,
  …, then switch Device → Desktop and repeat as `desktop-01-spawn.png`, ….
- Capture at minimum: spawn/HUD, a planted plot, a ready plot, the rarity reveal or harvest
  toast, the Pasar sale, the shop, the phone/quest screen.

## 7. Output log

- Manual (reliable): Output window → click it → `Ctrl+A`, `Ctrl+C` → paste into
  `output.log` in the evidence folder.
- Command-bar attempt (`UNVERIFIED`): `writefile` works only in Studio, and the file lands in
  Studio's content folder, not the repo — copy it out afterwards.

  ```lua
  local LogService = game:GetService("LogService")
  local lines = {}
  for _, entry in LogService:GetLogHistory() do
    table.insert(lines, string.format("[%d] %s", entry.messageType, entry.message))
  end
  writefile("harness-output.log", table.concat(lines, "\n"))
  ```

The run is only clean when this log has zero errors and zero warnings (Master Plan §0 quality
bar). Known pre-existing noise: `rbxassetid://203785492` wrong asset type (3× per play start,
still open as BUG-003). The Clouds-not-under-Terrain warning is gone as of the 2026-11-14 run.

## 8. Evidence layout and REPORT.md

```
docs/v2/evidence/<track>/<yyyy-mm-dd>-<slug>/
  phone-01-spawn.png   phone-02-plant.png   phone-03-harvest.png   ...
  desktop-01-spawn.png ...
  output.log
  REPORT.md
```

`REPORT.md`, at most 20 lines:

```markdown
# <track> — <slug> — <yyyy-mm-dd>

Build: <commit>  Place: JuraganDesa.rbxl (not saved)  Devices: iPhone 14 + Desktop
- Plant on tile 1: SEEN-IN-STUDIO (phone-02-plant.png)
- Harvest: SEEN-IN-STUDIO (sack 1 -> 0 after sale)
- Pasar sale: SEEN-IN-STUDIO (cash 50 -> 58)
- Buy seeds: SEEN-IN-STUDIO (phone-06-shop.png)
- Quest claim: UNVERIFIED (no finished task in the window)
- Save + rejoin: SEEN-IN-STUDIO (cash matched)
- Output: 0 errors, 2 known warnings
- Not checked: minigame feel, mobile frame rate, multiplayer
Decisions needed: none
```

Only steps actually observed get `SEEN-IN-STUDIO`; everything else is `LUNE-ONLY`,
`UNVERIFIED` or `BLOCKED <who>`.

## 9. Teardown

1. `{ action = "disable" }` → `Harness off.` (also happens automatically when the player
   leaves).
2. `Shift+F5` to stop the session. **Do not save `JuraganDesa.rbxl`** — only track C does.
3. Rojo: stop `rojo serve`, disconnect the plugin.
4. Delete throwaway Studio data only if you want a fresh save; otherwise leave it, the Studio
   store is separate (`PlayerData_v1_Studio`).

## 10. What is UNVERIFIED, and the manual fallback

| Step | Status now | Manual fallback |
|---|---|---|
| Enable/disable the gate | SEEN-IN-STUDIO (enable; teardown §9 followed) | Fire `enable` in the command bar; if no reply, the bootstrap did not run. |
| Bridge smoke check | SEEN-IN-STUDIO (gate replied `Harness is off…`, then `Harness on.`) | Human plays the same loop by hand with `E`. |
| Plant / harvest / sell / buy | SEEN-IN-STUDIO (full loop twice; cash 50 → 68 → 48, second session 48 → 75 → 65) | Human taps the tile prompts and the Pasar prompt. |
| Phone-size screenshots | SEEN-IN-STUDIO, manual `Win+Shift+S` only (`phone-01.png`); desktop size not captured | Win+Shift+S with the emulator on; or play on a real phone. |
| Output log capture | UNVERIFIED (Output read in Studio, no `output.log` saved) | Copy from the Output window. |
| Save + rejoin | SEEN-IN-STUDIO (cash 48, `padi` 6, tilesOwned 6 after stop and replay) | Enable API services, play, leave, rejoin, compare cash. |
| Death / reset mid-session | SEEN-IN-STUDIO 2026-11-14 (character killed from the server; respawned in 5.5 s and `CharacterAdded` returned it to the plot at 68, 4.69, 0; cash 65, `padi` 6, tilesOwned 6 unchanged; no minigame node left visible; no error in Output) | Play, take fall damage or `Humanoid.Health = 0` in the command bar, watch where you respawn. |
| Login-reward recovery | SEEN-IN-STUDIO 2026-11-14 (`quest` with no `taskId` claimed the login reward: cash 65 → 165, then `buy` 165 → 155 with `padi` 6 → 7) | Open the phone HUD and claim the daily reward by hand. |
| Thirty-minute soak, client half | SEEN-IN-STUDIO 2026-11-14 (1800 s, 111 cycles, summary in `docs/v2/evidence/h/2026-11-14-soak/soak.json`; no desync check and no server memory series, see §11). Ten-player half stays UNVERIFIED. | Run §11 to its deadline and read `_G.soak` back. |
| Minigame, feel, frame rate | UNVERIFIED | Only a human can judge these; not a harness job. |

Still `UNVERIFIED` after the 2026-11-14 run: §6 screenshot automation, desktop-size capture, a
saved `output.log`, and the ten-player session. The thirty-minute soak (client half) ran on
2026-11-14, see §11. Next step: save `output.log`, then run sections 2–4 again with ten players.

## 11. Soak and stamina run

**Status: soak half `SEEN-IN-STUDIO` 2026-11-14** — 1800 s run, 111 cycles, 0 stale replies. Evidence:
`docs/v2/evidence/h/2026-11-14-soak/soak.json`. The run used a recovery-aware variant of the loop
below (status each cycle, buy any stocked crop), so the loop text is the recipe, not the exact run.
Not recorded: a desync check, a server memory series, and a full `output.log`. Ten-player half:
`UNVERIFIED`.

What it answers: Master Plan §0 quality bar 5, "Thirty-minute soak with the harness … with no leak,
no desync and no stuck state". This section is the soak only. The ten-player half of that row is a
separate run and stays `UNVERIFIED` until someone does it.

### Before it starts

1. Launch checklist §2 done, device emulator on iPhone 14, Play Solo running, no red Output.
2. Enable the gate: `game:GetService("ReplicatedStorage").Remotes.Harness_Command:FireServer({ action = "enable" })` → `Harness on.`
3. `{ action = "status" }` and **write down cash, `Seed_padi` and tilesOwned**. That is the baseline
   the desync check at the end compares against; without it the run proves nothing about economy.
4. Leave the command bar in client context and paste the block below once.

### The loop

Fixed 1800 s, one cycle every 7.5 s: plant tiles 1–6 `padi` → `ready` → harvest tiles 1–6 → sell
`pasar` → buy `padi` 1. Fifteen commands per cycle at 0.5 s apart, which is 2/s, under the 4/s
`RateLimit` bucket. That is roughly 240 cycles (arithmetic from the waits, not a measured count).

```lua
local R = game:GetService("ReplicatedStorage").Remotes
local Stats = game:GetService("Stats")
local SECONDS, GAP, TILES = 1800, 0.5, 6

_G.soak = {
	startClock = os.clock(),
	calls = {}, failures = {}, lastFailure = {},
	memoryMb = { Stats:GetTotalMemoryUsageMb() },
	cycles = 0, pending = {}, done = false,
}

R.Harness_Result.OnClientEvent:Connect(function(result)
	local action = table.remove(_G.soak.pending, 1) or "unknown"
	if result and result.ok == false then
		_G.soak.failures[action] = (_G.soak.failures[action] or 0) + 1
		_G.soak.lastFailure[action] = tostring(result.message)
	end
end)

local function send(action, value)
	_G.soak.calls[action] = (_G.soak.calls[action] or 0) + 1
	table.insert(_G.soak.pending, action)
	R.Harness_Command:FireServer({ action = action, value = value })
	task.wait(GAP)
end

task.spawn(function()
	local deadline = os.clock() + SECONDS
	while os.clock() < deadline do
		for tile = 1, TILES do send("plant", { tile = tile, cropId = "padi" }) end
		send("ready")
		for tile = 1, TILES do send("harvest", { tile = tile }) end
		send("sell", { channel = "pasar" })
		send("buy", { cropId = "padi", amount = 1 })
		_G.soak.cycles += 1
		table.insert(_G.soak.memoryMb, Stats:GetTotalMemoryUsageMb())
	end
	_G.soak.done = true
	_G.soak.endClock = os.clock()
end)
```

`_G.soak` holds: `calls` and `failures` per action, `lastFailure` per action (the message that
explains the refusal), `cycles`, `memoryMb` (one sample at start, then one after every cycle), and
`done`. The loop stops itself at the deadline; nothing needs to be fired to end it.

### Reading it back

One call, client context, `execute_luau`:

```lua
return _G.soak
```

Server memory is a **separate process** — read it in the Server context with the same call,
`return game:GetService("Stats"):GetTotalMemoryUsageMb()`, at the start and at the end. Do not
subtract the client number from the server number; compare each series to its own start value.

### What counts as what

| Signal | Verdict |
|---|---|
| `memoryMb` climbs cycle after cycle, no plateau, and stays high after `done` | **Leak signal.** Save the series and file it against the owning track. |
| `memoryMb` rises and falls with the crop count (sawtooth) | Expected. Crops are created and destroyed every cycle; the question is the floor, not the peak. |
| `done` is `true` but `calls` keeps increasing | **Stuck loop.** Something re-fired after the deadline. |
| Fewer than 15 calls in a cycle, or a cycle that never returns | **Stuck state.** Note the action that stopped replying. |
| End `status` cash or seeds disagree with the counted successful sells and buys | **Desync.** |
| `plant` refused because there is no seed or no cash | **Expected.** One `buy` per cycle funds one plant while six tiles are planted, so the seed stock runs dry by design. `plantRefusal` explains it. The number that matters is plant failures while `Seed_padi` > 0. |
| `harvest` refused on a tile with no crop or an unripe one | **Expected.** A tile whose `plant` was refused has nothing to harvest, and a harvested tile stays empty until the next cycle. |
| `sell` refused with an empty sack | **Expected** on a cycle with no successful harvest. |
| `buy` refused for shelf stock or rank | **Real failure** only if `status.shop` lists `padi` and cash is above the price. Check that first. |
| Any other failure, any `ready` failure, a `sell` failure with sack > 0 | **Real bug.** File it in `BUGS.md` with the `lastFailure` message. |

### Recording it

`docs/v2/evidence/h/<yyyy-mm-dd>-soak/` with `soak.json` (the returned table), `output.log` per §7,
`REPORT.md` per §8: cycle count, per-action call and failure counts, the memory series at start,
mid and end for client and server, and the end `status` against the baseline. Then flip the soak
row in §10 to `SEEN-IN-STUDIO` and leave the ten-player half `UNVERIFIED`.

Do not save `JuraganDesa.rbxl` (§9). Do not run this while another agent holds the Studio session
(D-G2).

### First attempt, 2026-11-14, and why the loop above is not enough

Two loops were run and both stalled inside a minute, so neither is a soak result:

1. The first rotated the plant tile every cycle but `ready` ripens *all* crops, so `harvest` usually
   targeted a tile with no crop: 454 cycles, `harvest` 91 calls / 70 failures, `sell` 91 / 70,
   `buy` 90 / 76. Cash still rose 155 → 458 because the few successful sales were pure profit.
2. The second pinned tile 1 (plant → ready → harvest → sell → buy): 11 cycles, `plant` 10 / 9
   failures (`tile 1 is not empty`, then `no padi seed`), `buy` 10 / 10 (`shop refused padi x1`),
   cash 458 → 499. Once the seeds run out and the shelf will not sell another seed, the ring cannot
   restart itself.

So a real soak needs a recovery step: read `status` each cycle and only advance the ring from a
state it can actually reach — sell before buying, buy seeds before planting, and re-check
`status.shop`/`status.seeds` instead of assuming the previous action worked. What the two attempts
do prove is that several hundred refused commands produce no stack trace and no stuck state:
0 `Stack Begin` in Output, and the only line is BUG-003 ×3. Client memory went 1982.5 → 2082.2 MB
across the first 454-cycle run, but that run also kept every harness reply in `_G.hreplies`, so the
growth is not attributable to the game until a capped run is done. The second run capped replies and
grew 4.4 MB in 27 s — too short to call either way.

Status of the soak criterion: still `UNVERIFIED`.

## 12. Multi-client driver for Q5 (needs a human at the Test tab)

The single-client soak above cannot produce the ten-player half of Q5: this MCP bridge cannot open
a Local Server or add test clients, and Roblox has no scriptable API to create them from inside a
place. A gated **server** script is provided so that, once a human opens the clients, the whole
§2–§4 loop runs on every player at once and produces one results table.

1. Repro root `rojo serve`; Studio connected; **Enable Studio Access to API Services** on.
2. Test tab → **Start** with **Local Server** on. Add test clients (start with 2, then go to 10 for
   the real Q5 run). Every client is a fresh save.
3. In **one** client's command bar, enable the harness (§3) so the gate opens:
   `game:GetService("ReplicatedStorage").Remotes.Harness_Command:FireServer({ action = "enable" })`.
4. In the **server** command bar, run the driver once:

   ```lua
   local MC = require(game.ServerScriptService.Server.Testing.MultiClient)
   MC.run()
   ```

   This runs §4 steps 1–7 (plus `save`, and a final `status`) for every player through the same
   gated handlers a client would call, and prints a readable summary plus one
   `Q5_MULTICLIENT_JSON=` line. Read the raw table back with `return MC.lastResults`.

5. Compare the JSON against the verdicts in §11 "What counts as what". `stuck` lists players with
   no save snapshot or a failed critical step (the action and error are named); `desync` lists
   state fields that differ between players, with each player's value. Identity, position, the
   UserId-seeded `shop` shelf and the onboarding hint id are excluded — check `shop` before calling
   a cash/seeds difference a bug.
6. A driver script cannot see client UI or a client whose network stalls. Watch the clients for the
   "stopped replying" half of Q5 by hand; note it in the report if you see it.

Evidence: `docs/v2/evidence/h/<yyyy-mm-dd>-q5-multiclient-closed/` with `REPORT.md`, the JSON as
`results.json` and `output.log`. The comparator (`server/Testing/MultiClientCheck.luau`) is pure and
covered by `tests/specs/multiclient_spec.luau`; the live ten-player run stays `BLOCKED` until step 2
is done by a human. Do not save `JuraganDesa.rbxl`.

