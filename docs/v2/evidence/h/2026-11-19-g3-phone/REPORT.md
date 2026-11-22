# Track H — G3 beat sheet at phone size — 2026-11-19

WORK_QUEUE item 32. Replay the full nine-step §4 harness beat sheet at iPhone 14 phone size and
prove the G3 gate criterion's phone half. **Status: `SEEN-IN-STUDIO`** (this file + `results.json` +
`output.log`). The criterion is now closed.

## Build and method

- Branch `track/c-world-look`, HEAD `76d8d4e`, placeId 132087524375529, Rojo `localhost:34872`.
- Fresh profile via VERIFY-TEMP `ProfileStore.New(...).Mock` in `PlayerData.luau`, reverted before
  commit. No identity/UserId invented; no `profile:Save()`; place not saved or published.
- **Phone viewport 749×389**, GuiService inset `0,58`. `StudioDeviceSimulatorService:SetDeviceAsync(
  "iphone_14")` was applied in the **Edit datamodel before entering Play**; setting the device during
  Play left a 1×1 render viewport. This is the concrete method that overturns the old "no device
  emulation" block reason.
- Harness commands spaced ≥300 ms apart (rate limit 4/s). Reply read as the first new
  `Harness_Result`, not the last, to avoid a stale-reply race.

## Steps (all `ok=true`)

| # | Action | cash | padi | planted | sack | tutorialStep | rank |
|---|---|---|---|---|---|---|---|
| 1 | enable | — | — | — | — | — | — (`Harness on.`) |
| 2 | status | 50 | 5 | 0 | 0 | 1 | gurem |
| 3 | plant tile 1 padi | 50 | 4 | 1 | 0 | 2 | gurem |
| 4 | ready | 50 | 4 | 1 | 0 | 2 | gurem |
| 5 | harvest tile 1 | 50 | 4 | 0 | 1 | 3 | gurem |
| 6 | sell pasar | 77 | 4 | 0 | 0 | 4 | gurem |
| 7 | buy padi ×2 | 57 | 6 | 0 | 0 | 5 | gurem |
| 8 | quest (login reward) | 157 | 6 | 0 | 0 | 5 | gurem |
| 9 | status | 157 | 6 | 0 | 0 | 5 | gurem |

9 commands → 9 replies. Cash 50→77→57→157, padi 5→4→6, tutorialStep 1→5, sack 1 at harvest —
identical to the desktop baseline (`h/2026-11-19-regression-replay/results.json`), so the beat sheet
behaves the same at phone size.

## Output

Zero game-code errors and zero game-code warnings. Only external noise: Assistant-plugin version
warnings, three `rbxassetid://203785492` asset-type lines (BUG-003, accepted exclusion D-G4) and
AnalyticsService notices. BUG-003 did not indicate a game defect.

## Decisions needed

None. This closes the G3 phone half; GATE1.md G3 and the MASTER_PLAN G3 checkbox are marked
`SEEN-IN-STUDIO`. Not checked here (separate rows): G4/G4b placeholder/text pass, G6 frame rate,
Q5 ten-player, Q6 published persistence, Q7 real-device touch.
