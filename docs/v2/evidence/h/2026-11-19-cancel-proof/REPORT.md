# H — Cancel proof — 2026-11-19

Track H, Gate 1 / Q3 follow-up to BUG-013. Fresh proof that the **real** minigame Cancel
button closes the overlay, driven on Rojo-synced code in Play Solo. No designer identity is
recorded here; the local Studio player is referred to as "the player".

## Setup

- Branch `track/c-world-look`, HEAD `90b4d9c`, Rojo serving on `localhost:34872`.
- Edit datamodel confirmed matching disk before Play: `Crops` 3786 B, `RaidCutscene` 5140 B,
  standOff-14 comment present.
- To get a genuinely fresh profile with no write to any real save, `src/server/Data/PlayerData.luau`
  was temporarily switched to `store.Mock:StartSessionAsync` (ProfileStore in-memory store). This
  is a VERIFY-TEMP edit only, reverted before commit. Console still reported
  `[ProfileStore]: Roblox API services available - data will be saved`; the mock flag routes the
  session to memory regardless.
- Play Solo stopped and restarted for this pass so all state below is from one clean session.

## Driver note (honest limitation)

The production minigame opens from the tile `ProximityPrompt` via `FarmService.onTilePrompt`,
which sets `pending[player]` and fires `Minigame_Start`. This Studio build exposes no way to fire a
`ProximityPrompt.Triggered` signal (`RBXScriptSignal:Fire()` is engine-locked, `InputActivated()` is
not a member here, and keyboard `E` on a nearby tile did not trigger it). The production
`Minigame_Start` remote was therefore fired from the Server VM — the exact downstream event the
prompt path fires — to open the real `Minigame` UI. The button press itself used the genuine UI.

## Observed (one window, fresh profile)

| Step | Action | Result |
|---|---|---|
| 1 | Harness `enable` + `status` | `Harness on.`; cash 50, `seeds.padi` 5, `tiles` [], `tilesOwned` 6, `tutorialStep` 1, rank `gurem`, sack 0 |
| 2 | Hook `Minigame.Scrim.Card.Cancel.Activated` (client) and `Farm_Complete`/`Farm_Auto`/`Farm_SelectSeed`/`Shop_BuySeed`.`OnServerEvent` (server); fire `Minigame_Start("plant",1,"padi")` | scrim `Visible=true`, `cancelFires=0`, commit-remote count all 0 |
| 3 | `GuiService.SelectedObject = Cancel`, `user_keyboard_input` keyDown/Return/keyUp | `Cancel.Activated` fired **1**×, scrim `true → false`, `PlayArea` destroyed |
| 4 | Harness `status` again | cash 50, `seeds.padi` 5, `tiles` [], `tilesOwned` 6, `tutorialStep` 1, rank `gurem`, sack 0 — **identical to step 1** |
| 5 | Read server commit-remote counters | all 0 — Cancel fired **no** client→server commit |

Mouse click on the button (`user_mouse_input`) did not fire `Activated` in this build; the keyboard
route with `SelectedObject` did. Both were attempted; the successful one is recorded above.

## Source corroboration (read, not re-derived from the run)

- `src/client/UI/Minigame.luau:182` — `cancel.Activated:Connect(close)`
- `src/client/UI/Minigame.luau:97-107` — `close()` runs `current.cleanup()`, drops `current`,
  destroys `playArea`, sets `scrim.Visible = false`. No remote is fired.
- `src/client/UI/Minigame.luau:190` — `Minigame_Cancel.OnClientEvent:Connect(close)` (server→client
  only; no client→server Cancel remote exists in `src/shared/Remotes.luau`).
- Consequence: Cancel cannot commit a plant/harvest (only `Farm_Complete`/`Farm_Auto` can), which is
  why the commit counters stayed at 0 and the profile did not change.

## Verdict

BUG-013 / Q3 "Cancel appeared not to close the overlay" — **not reproduced** on synced code. The
real Cancel button closes the overlay deterministically and commits nothing. Status:
`SEEN-IN-STUDIO` (this file). The static wiring regression remains `LUNE-ONLY` in
`tests/specs/minigame_cancel_spec.luau`. Machine-readable results: `results.json`.
