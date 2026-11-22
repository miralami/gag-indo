# Q6 — persistence in a published place (designer run sheet)

**Criterion (Gate 1 Q6):** "Persistence verified in a published test place with real DataStores,
not only in Studio." Save → leave → rejoin as a real player and compare cash / seeds / tiles.
Today only Studio DataStores are proven (`h/2026-11-14-phase0/`). This sheet is the exact path to
close it. It needs the designer (decision **D-G2**) and is therefore `BLOCKED` for an agent to run.
`DESIGNER_GATE1.md` §5 is the one-paragraph version; this file has the full steps and the script.

## A. Before publishing (agent-checkable, already done)

1. Confirm the branch is synced and `lune run tests/run` is green.
2. Keep **Enable Studio Access to API Services** on for the save step.
3. Decide **D-G2**: the designer owns a private test place. Use a *new, private* place — never a
   live/player-facing one. Do not overwrite `JuraganDesa.rbxl` and do not save a local copy.

## B. Publish a private test place

1. Studio, connected via Rojo, File → **Publish to Roblox…**.
2. Create a **new** place under the designer's account. Set its access to **Private** (only the
   designer / invited test accounts can join). Give it a name that marks it as a Gate 1 test place.
3. Publish the current build. Record the place ID in the evidence `REPORT.md` (do not invent one —
   copy it from Roblox after publishing).
4. Confirm Game Settings → Security → **Enable Studio Access to API Services** is still on, and
   that the published place uses DataStore (not a forced-off dev profile).

## C. Save → leave → rejoin in the published place

1. Join the **published** place as a real player (not Play Solo, not a Local Server test client).
   Your account must be allowlisted in `src/server/Live/Admins.luau` (`userIds`): Studio's
   "everyone is an admin" convenience does **not** apply in a published place.
2. Play long enough to own the numbers you will check: plant, harvest and sell at least once.
3. From a client script in the published place, fire the **before** command:

   ```lua
   game:GetService("ReplicatedStorage").Remotes.Admin_Command:FireServer({ action = "q6Capture" })
   ```

   The server prints `Q6_BEFORE_JSON=...` to the console (F9) and keeps that snapshot in memory
   keyed by your UserId. The command is read-only (no save, no mutation), rate limited and
   admin-only; the Studio harness is not involved.
4. Leave the game (Esc → **Leave**). Wait ~10 s so the DataStore write completes.
5. **Rejoin the SAME server** as the same account, then fire:

   ```lua
   game:GetService("ReplicatedStorage").Remotes.Admin_Command:FireServer({ action = "q6Compare" })
   ```

   The server prints the field-by-field verdict (`Q6 persistence: n/n fields match; PASS|FAIL`)
   and `Q6_RESULT_JSON=...`. The reply also arrives on `Admin_Result` as
   `{ ok = ..., message = ..., data = ... }`.
6. Every compared field must be unchanged. A reset, a double, or a missing tile is a **desync** —
   file it in `docs/testing/BUGS.md` with the before/after numbers and stop the Gate 1 claim.
7. In-memory `before` survives a leave/rejoin on a still-running server, but **not** a full server
   restart. Copy the `Q6_BEFORE_JSON` line as a backup before leaving and pass its JSON back if the
   server restarted:

   ```lua
   game:GetService("ReplicatedStorage").Remotes.Admin_Command:FireServer({
     action = "q6Compare",
     value = "<pasted JSON from Q6_BEFORE_JSON>",
   })
   ```

   The table in section E remains a manual fallback if you cannot fire the command.

## D. Studio rehearsal with the gated compare script

The harness is Studio-only, so the script cannot run in the published place. It *can* rehearse the
exact same comparison in Studio, so the designer knows the field list and verdict format before the
real run. Run it with the harness enabled (HARNESS.md §3) and API services on:

```lua
-- SERVER command bar, before leaving:
local P = require(game.ServerScriptService.Server.Testing.Persistence)
P.capture()          -- prints Q6_BEFORE_JSON=<json>; copy that JSON string
```

Stop Play (Shift+F5), Play again, then in the **server** command bar:

```lua
local P = require(game.ServerScriptService.Server.Testing.Persistence)
P.compare("<paste the Q6_BEFORE_JSON string here>")
-- or: P.compare(MC_before_table) if you kept the table in the same session
-- read the stored verdict with: return P.lastResult
```

It prints `Q6 persistence: n/n fields match; PASS|FAIL`, one `LOST/CHANGED <field>` line per
difference, and one `Q6_RESULT_JSON=` line to copy into evidence. Both functions refuse unless the
harness gate is open in Studio, so they can never be used to fake a published-place result.

`tiles.ready` is deliberately **not** compared: a crop that was growing at save time may be ready
after rejoin because time passed. Crop identity, count and hot state are compared. Identity,
character position, the UserId-seeded shop shelf and the onboarding hint id are excluded too. The
field list is `PersistenceCheck.FIELDS` and is locked by `tests/specs/persistence_check_spec.luau`.

## E. Numbers table to fill in (copy into the evidence report)

| Field | Before | After | Match? |
|---|---|---|---|
| cash | | | |
| padi / jagung / … seeds | | | |
| tilesOwned | | | |
| planted crops (t1…tN) | | | |
| gudang / sack | | | |
| rank | | | |
| lifetimeEarned | | | |

## F. Evidence and closing

Save `docs/v2/evidence/h/<yyyy-mm-dd>-published-persistence/REPORT.md` with: the published place ID
(copied, never invented), the filled table, the Studio rehearsal verdict, and `output.log`. Then set
the Q6 row in `docs/testing/GATE1.md` to `SEEN-IN-STUDIO`. Q1/Q5/Q7 and the gate rows still close
separately; **G1 closes last**. Do not save `JuraganDesa.rbxl`.
