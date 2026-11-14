# Playtest Harness — Studio routine

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
| Minigame, feel, frame rate | UNVERIFIED | Only a human can judge these; not a harness job. |

Still `UNVERIFIED` after the 2026-11-14 run: §6 screenshot automation, desktop-size capture, a
saved `output.log`, the ten-player session and the thirty-minute soak. Next step: save those,
then run sections 2–4 again with ten players and flip the soak row.
