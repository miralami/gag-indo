# H — G5 first-session timings at phone size — 2026-11-19

WORK_QUEUE item 33. Re-run the three fresh-profile G5 first-session timings at iPhone 14 phone size
and prove the G5 gate criterion's phone half. Combined with the desktop pass
(`h/2026-11-19-g5-timings/`), the G5 criterion is now fully closed. **Status: `SEEN-IN-STUDIO`**
(this file + `results.json` + `output.log`). No designer identity recorded.

## Setup

- Branch `track/c-world-look`, HEAD `db34e01`, placeId 132087524375529, Rojo `localhost:34872`.
- Fresh profile via VERIFY-TEMP `ProfileStore.New(...).Mock` in `PlayerData.luau`, reverted before
  commit. Every run restarted Play, so each began at cash 50, `tutorialStep` 1, `seeds.padi` 5,
  rank `gurem`.
- **Phone viewport 749×389**, GuiService inset `0,58`. `StudioDeviceSimulatorService:SetDeviceAsync(
  "iphone_14")` applied in the **Edit datamodel before entering Play** (setting it during Play leaves
  a 1×1 render viewport). Same method proven in item 32.
- Harness commands paced ≥300 ms (4/s rate limit). Timings stamped to Output:
  `print("[G5P] ... wall=" .. os.date("%H:%M:%S", os.time()))`, read back from Studio Output.

## Driver note

The harness `plant` goes through the real `FarmService.commitAttempt` → `finish` → `doPlant` path, so
the tutorial 20 s padi grow applies (`FirstSession.getGrowSeconds` → `tutorialPadiGrowSeconds = 20`
while the tutorial is unfinished and `stats.harvests == 0`). No harness `ready` shortcut: tile
`ready` comes from the harness `status` snapshot, computed against the real `plantedAt + growSeconds`.
Harvest uses the real `harvest` action into the sack.

## Runs — time to first harvest (target < 45 s)

| Run | t0 | Planted | Tile `ready` | First harvest | Elapsed |
|---|---|---|---|---|---|
| 1 | 11:16:17 | 11:16:18 (1 s) | 11:16:39 (22 s) | 11:16:39 (22 s) | **22 s** |
| 2 | 11:17:14 | 11:17:14 (0 s) | 11:17:34 (20 s) | 11:17:34 (20 s) | **20 s** |
| 3 | 11:18:11 | 11:18:12 (1 s) | 11:18:32 (21 s) | 11:18:32 (21 s) | **21 s** |

All three: first harvest 20–22 s, under 45 s. Matches the desktop baseline (20–21 s). No balance
change: `src/shared/Config/FirstSession.luau` `tutorialPadiGrowSeconds = 20` already meets the target.

## First rarity reveal (target < 5 min)

The first harvest is guaranteed *Bagus* (`guaranteedTiers[1] = "bagus"`), so the first rarity reveal
coincides with the first harvest at 20–22 s — well under 5 min. The second harvest is guaranteed
*Super* (`guaranteedTiers[2] = "super"`): in run 3 a second padi was planted at 11:18:33 and harvested
at 11:19:21 (48 s from plant, 70 s from t0), still under 5 min. The tier guarantee itself is
`LUNE-ONLY` (`first_session_spec.luau`); the Studio run proves the timing window, not the rolled tier
text.

## Raid witnessed (target < 7 min)

Marker: `[G5P] R3 RAID-WITNESS scripted_raid_gossip wall=11:23:26`. Run 3 t0 was 11:18:11, so the
gossip fired ~5:15 (315 s) later, matching `scriptedRaidDelay = 330 s` on the 5 s `FirstSession.tick`
loop. Under the 7 min (420 s) target. The beat fires via `Remotes.Notify` key `scripted_raid_gossip`.

## Output

Zero game-code errors and zero game-code warnings. Only external noise: Assistant-plugin version
warnings, three `rbxassetid://203785492` asset-type lines (BUG-003, accepted exclusion D-G4) and
AnalyticsService notices. BUG-003 did not indicate a game defect.

## Verdict

- First harvest < 45 s: **pass** (3/3 runs, 20–22 s) — `SEEN-IN-STUDIO`.
- First rarity reveal < 5 min: **pass** (first harvest ~20–22 s Bagus; second ~70 s Super) — timing
  `SEEN-IN-STUDIO`, tier guarantee `LUNE-ONLY`.
- Raid witnessed < 7 min: **pass** (~5:15) — `SEEN-IN-STUDIO`.

No balance change proposed. GATE1.md G5 row and the MASTER_PLAN G5 checkbox are now
`SEEN-IN-STUDIO`. Other still-open rows (G4/G4b art & text, G6 frame rate, Q5 ten-player, Q6
published persistence, Q7 real-device touch) are unchanged and remain the designer's.
