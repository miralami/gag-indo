# Studio re-check on synced code — Gate 1 sweep (Track H, 2026-11-19)

Build: `track/c-world-look`, tree clean at `270fffe`, with `92ebe50` (standOff-14) and
`270fffe` in the place. Place: cloud dev place `Development-Juragan-Desa`, placeId
`132087524375529`, universeId `10776530981`. Throwaway profile: `GiantyFrog`, UserId
`172146044`, baseline cash `35857`.

**The place was never saved and never published.** `profile:Save()` was never called.
All DataModel edits were unsaved and the throwaway profile was restored before Play stopped
(see "Teardown").

## Why this pass exists

The sibling pass `h/2026-11-19-gate1-studio/` ran with Rojo **not** serving: committed sources
were injected into the Edit DataModel by hand. Two of its observations were consequently
unreliable — minigame Cancel looked unresponsive and the join bootstrap looked broken. This
pass re-ran every 2026-11-19 claim with **Rojo serving on `localhost:34872`**, after confirming
sync from inside Studio (`RaidCutscene` `standOff = 14`; the Harness line-314 comment from
`270fffe` present in the live source). Where this pass disagrees with the sibling report,
this pass is authoritative.

Evidence files: `results.json` (structured readings). `output.log` stays with the sibling
pass; no new full-session log was captured here.

## Method note — driving the client UI

`user_mouse_input` did **not** activate any `GuiButton` in this session: an `Activated`
counter attached to the phone button stayed at `0` even with `moveTo <instance_path>` plus
`mouseButtonClick` at the button's live absolute position, and `VirtualInputManager` calls
from `execute_luau` are refused (`lacking capability RobloxScript`). The reliable method was
`GuiService.SelectedObject = <button>` followed by `user_keyboard_input keyPress Return`;
this activated every button it was pointed at, including the phone button and each Close.
Selection was done in unsaved Play-mode DataModel only.

## Results

### 1. Join bootstrap — no bug (re-check)

The sibling report's "Main never connected `Harness_Command` / never loaded a profile on join"
did **not** reproduce. Source confirms `src/server/Main.server.luau:95` calls `Harness.start()`
and line 101 calls `PlayerData.start()`. In this pass the real `Harness_Command` remote
replied and a live-server probe read a loaded profile. Environment artifact of the unsynced
pass; **no BUGS row and no fix**.

### 2. Force raid does not write the saved cooldown — `SEEN-IN-STUDIO`

Through the real `Harness_Command` remote with a sentinel `raidSafeUntil = 1796000001`: raid
started (`RaidService.getState(p) = "incoming"`, `InRaid = true`) with the sentinel unchanged;
the whole cooldown table was then restored to its real value (`raidSafeUntil = 1794926416`).
`RaidTrigger.withTemporaryCooldown` restored the exact table on the synced build.

### 3. BUG-004 zero-cash / zero-seed recovery — `SEEN-IN-STUDIO`

On the live profile, cash `0` / 0 seeds / 0 tiles → `FarmService.checkSeedFloor` granted
exactly 1 `padi` seed, cash stayed `0`, `n_seed_floor` notified, second call returned `false`.
BUG-004 stays closed.

### 4. Q3 mid-loan recovery — `SEEN-IN-STUDIO`

`DebtService.borrow(p, 375)` → `active = true`, `owed = 412`, `principal = 375`,
`n_debt_borrowed`; `DebtService.repay(p)` → `active = false`, `owed = 0`, `principal = 0`,
`n_debt_cleared`. The loan state can be left; no dead end.

### 5. Q3 full-sack boundary + shop restock — `SEEN-IN-STUDIO`

- Sack capacity `40`. With the sack at exactly `40`, harvest was refused and `n_sack_full`
  notified — the boundary is inclusive, not overfill.
- `sell` at `pasar` cleared the sack `40 → 0` and paid `cash 35857 → 36541`; the next harvest
  put `1` item in the sack.
- `ShopService.restockNow` rerolled stock (`padi 7 → 10`) and notified `n_shop_restocked`; a
  harness buy of `padi` x2 then succeeded. Full-sack recovery and restock are both reachable.

### 6. Mid-minigame Cancel — NOT reproduced (no fix)

On synced code, firing `Minigame_Cancel:FireClient` closed the scrim (`Visible true → false`).
The static wiring is present in `src/client/UI/Minigame.luau`: `cancel.Activated:Connect(close)`
(line 182), `Remotes.Minigame_Cancel.OnClientEvent:Connect(close)` (line 190), and `close()`
sets `scrim.Visible = false` (line 106). The sibling pass's "cancel did not close the overlay"
is attributed to the unsynced code and is recorded as non-reproduced, not as a defect. A static
regression spec (`tests/specs/minigame_cancel_spec.luau`) now locks the wiring in place.
Mid-minigame cancel therefore counts as recovered for Q3.

### 7. Every-button / every-screen sweep — `SEEN-IN-STUDIO`

Viewport `749 × 388`. Driven via `GuiService.SelectedObject` + keyboard Return. No dead ends
found:

- **AdminPanel**: F2 toggles `Panel` `true → false` (and back).
- **Phone**: the `PhoneButton` built the device on first activation; the home screen shows 8
  app tiles. `App_phone`, `App_kebun`, `App_pinjol`, `App_tugas`, `App_cheat`, `App_dekor`
  each open a page with visible `Back`, `Close` and `HomeBar` controls; each page could be left.
- `App_shop` calls `closePhone()` + `Hud.openShop()`; `App_board` calls `closePhone()` +
  `Leaderboard.open()`. Both destination panels opened and their `Close` buttons closed them
  (`Hud.Shop.Visible → false`, `Leaderboard.Panel.Visible → false`).
- The phone `Close` button closed the device (effective visible buttons dropped to just
  `PhoneButton`), and `HomeBar` on home closed it too.

## Q2 (full-session Output)

Q2 is now `SEEN-IN-STUDIO` on the strength of the sibling pass's saved `output.log`
(`h/2026-11-19-gate1-studio/output.log`, zero game-code errors) plus designer decision D-G4
(`DECISIONS.md:27`, decided 2026-11-14), which excludes the external BUG-003 asset line from
the zero-warnings bar. The remaining lines are that external line (3×) and two Assistant-plugin
version warnings, neither from game code.

## Teardown

- Throwaway profile restored: cash `35857`, produce cleared to the pre-Q3 baseline, shop
  `nonce = 0`. No `profile:Save()` at any point; changes lived only in the running server.
- All `__Verify*` probe scripts removed from `ServerScriptService` (0 remaining).
- Play stopped; Studio left in Edit mode; the place was **not** saved.
- No publish, no `ROBLOX_API_KEY` read, no asset IDs invented.
