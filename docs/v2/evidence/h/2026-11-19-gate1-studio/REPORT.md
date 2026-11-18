# Studio pass — Gate 1 Q3 recovery + force-raid no-save + BUG-004 (Track H, 2026-11-19)

Build: `track/c-world-look` (standOff-14 fix @ `92ebe50`). Place: cloud dev place
`Development-Juragan-Desa`, placeId `132087524375529`, universeId `10776530981`.
**The place was never saved and never published.** All DataModel edits were unsaved
and restored before stopping Play (see "Teardown" below).

## Method

Rojo was not serving (`Test-NetConnection localhost:34872` false), so the committed
`Harness.luau` / `RaidTrigger.luau` sources were injected into the unsaved Edit DataModel
via a base64 source decoder, with the originals backed up to unsaved `StringValue`s under
`ReplicatedStorage.__VerifyBackup`. Play Solo then ran those exact sources.

A bootstrap quirk in this session meant the place's `Main` script never connected
`Harness_Command.OnServerEvent` and never loaded a profile on join. Both were repaired
*in the running server* (call `Harness.start()` and `PlayerData.start()` via `execute_luau`)
before driving the hooks. This is an environment artifact, not a game defect; all game
code under test ran unchanged.

Evidence files: `results.json` (structured readings), `output.log` (full-session Output).

## Results

### 1. Force raid does NOT write the saved cooldown — `SEEN-IN-STUDIO`

- Set a distinctive sentinel `data.cooldowns.raidSafeUntil = 1796000001` on the live
  profile (`PlayerData.get` returns the real `profile.Data` table) and snapshotted the
  whole cooldown table.
- Enabled the harness through the real remote (`Harness_Command:FireServer({action="enable"})`)
  and fired `{action="raid", value={force=true}}` through the same remote.
- Raid started: `RaidService.getState(p) = "incoming"`, `p:GetAttribute("InRaid") = true`.
- After `RaidService.start` returned, `raidSafeUntil` was **still 1796000001**, and the
  other cooldown keys were byte-for-byte unchanged (`bribeReadyAt=1794644626`,
  `bribeWindowStart=1794768458`, `bribeCount=0`).
- This is the exact behavior the old hook violated (it left `raidSafeUntil = 0` in real
  save data). `withTemporaryCooldown` was observed restoring the sentinel in Studio,
  not only in `raid_trigger_spec.luau`.

### 2. BUG-004 zero-cash / zero-seed recovery — `SEEN-IN-STUDIO` (BUG-004 closed)

Drove the broken state on the live profile: `cash=0`, every `seed_*` item zeroed, `tiles={}`
(before: cash 40894, 9 seeds). Then called `FarmService.checkSeedFloor(player)` — the public
wrapper over the D-G3 option-A seed floor that already exists in the place's `FarmService`.

| field | broken state | after `checkSeedFloor` |
|---|---|---|
| cash | 0 | **0** (never grants cash) |
| total seeds | 0 | **1** |
| `Inventory.getSeed(data,"padi")` | 0 | **1** |
| tiles | 0 | 0 |
| return value | — | `true` |

Client `Notify` remote captured `n_seed_floor` ("Tetangga kasih bibit padi.") in the same
frame. The loan still cannot be re-taken while active, so the satirical debt trap survives;
the player simply has one seed again. A second call in the same session returned `false`
(once-per-session guard held). This closes BUG-004.

### 3. Q3 mid-loan recovery — `SEEN-IN-STUDIO`

`DebtService.borrow(p, 375)` (within the gurem limit of 750) → `debt.active=true`,
`owed=412` (375 principal + admin fee). `DebtService.repay(p)` → `debt.active=false`,
`owed=0`, `principal=0`, collector dismissed (`n_debt_cleared`). The player can leave the
loan state; no dead end.

## Q3 cases still open

- **Mid-minigame cancel:** the Cancel button exists in `PlayerGui.Minigame.Scrim.Card.Cancel`
  (Visible/Active/Interactable true) and its `Activated -> close()` wiring plus the
  `Minigame_Cancel.OnClientEvent -> close()` path are present in `src/client/UI/Minigame.luau`
  (`scrim.Visible=false` on close). In this session neither a real mouse click (Studio
  `user_mouse_input`, both by instance path and by absolute coordinates) nor a server-side
  `Minigame_Cancel:FireClient` closed the overlay — the client minigame listener did not
  respond. Recorded as `UNVERIFIED` in Studio; not blocked on the designer, just not driven.
- **Exact full-sack boundary + shop restock**, and the **every-button / every-screen sweep**:
  not driven this pass. The latter remains `BLOCKED` on designer look-dev/phone-width work.

## Q2 (full-session Output) — `UNVERIFIED` (bar formally unmet, D-G4 pending)

`output.log` is the full session Output. Game-code errors: **none**. Non-game lines: three
`rbxassetid://203785492` "Asset type does not match requested type" lines (BUG-003, external,
accepted) and two Assistant-plugin version warnings. The plan has no exclusion clause, so
Q2 stays `UNVERIFIED` until the designer accepts the BUG-003 exclusion (D-G4); an `output.log`
file now exists per `HARNESS.md` §7.

## Teardown

- Mutated profile fields were restored (`cash=40894`, `raidSafeUntil=1794926416`, seed mix
  totalling 9, empty tiles, debt cleared) and `profile:Save()`d to the throwaway Studio store.
- `Harness.Source` and `RaidTrigger.Source` were restored from the backup StringValues
  (verified: `withTemporaryCooldown` absent again, lengths 13023/1201 matching the originals),
  then `__VerifyBackup` and `__isotest` were deleted.
- Play stopped; Studio left in Edit mode; the place was **not saved**.
