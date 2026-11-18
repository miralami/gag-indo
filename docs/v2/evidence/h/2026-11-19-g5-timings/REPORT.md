# H — G5 first-session timings — 2026-11-19

Track H, Gate 1 G5: "Time to first harvest is under 45 seconds, first rarity reveal under 5 minutes,
raid witnessed under 7 minutes." Three desktop runs on a genuinely fresh profile, real grow timers,
Output timestamp markers. No designer identity recorded.

## Setup

- Branch `track/c-world-look`, HEAD `90b4d9c`, Rojo serving on `localhost:34872`, Edit datamodel
  synced before Play.
- Fresh profile via VERIFY-TEMP `store.Mock` in `src/server/Data/PlayerData.luau` (in-memory
  ProfileStore; no write to any real save). Reverted before commit. Every run restarted Play, so
  each began at cash 50, `tutorialStep` 1, `seeds.padi` 5, `tiles` [], rank `gurem`.
- Desktop size, Play Solo. Output stamps written with `print("[G5] ... wall=" ..
  os.date("%H:%M:%S", os.time()))` and read back from Studio Output.

## Driver note

The harness `plant` action goes through the real `FarmService.commitAttempt` → `finish` → `doPlant`
path, so the tutorial 20 s padi grow applies (`FirstSession.getGrowSeconds` returns
`FirstSessionConfig.tutorialPadiGrowSeconds = 20` while the tutorial is unfinished and
`stats.harvests == 0`). No harness `ready` was used for any timing: the tile's `ready` flag comes
from the harness `status` snapshot, which computes `os.time() >= plantedAt + growSeconds` against
the real planted time. Harvest used the real `harvest` action into the sack.

## Runs — time to first harvest (target < 45 s)

| Run | Start wall | Planted | Tile `ready` | First harvest | Elapsed |
|---|---|---|---|---|---|
| 1 | 02:13:55 | 02:13:56 | 02:14:15 | 02:14:15 | **20 s** |
| 2 | — (fresh restart) | — | — | — | **20 s** ready / **21 s** harvest |
| 3 | 02:17:42 | 02:17:42 | 02:18:02 | 02:18:03 | **20 s** ready / **21 s** harvest |

Run 1 Output: `RUN1 PLANTED ok=true wall=02:13:56`, `RUN1 READY elapsedFromStart=20s wall=02:14:15`,
`RUN1 FIRST-HARVEST ok=true elapsedFromStart=20s wall=02:14:15`.
Run 3 Output: `RUN3 PLANTED ok=true wall=02:17:42`, `RUN3 READY elapsedFromStart=20s wall=02:18:02`,
`RUN3 FIRST-HARVEST ok=true elapsedFromStart=21s wall=02:18:03`.

All three runs: first harvest at 20–21 s, under the 45 s target. No balance change needed: the
config already misses nothing — `src/shared/Config/FirstSession.luau:4`
`tutorialPadiGrowSeconds = 20`, and `src/server/Progression/FirstSession.luau:34-39` applies it to
the first padi while the tutorial is unfinished. Nothing was proposed or changed.

## First rarity reveal (target < 5 min)

The first harvest is guaranteed *Bagus* (`FirstSessionConfig.guaranteedTiers[1] = "bagus"`, applied
by `FirstSession.getHarvestTier`), so the first rarity reveal coincides with the first harvest at
~20 s — well under 5 min. The second harvest is guaranteed *Super*
(`guaranteedTiers[2] = "super"`); in run 3 a second padi was planted at 02:18:27 and harvested at
02:20:17 (~110 s from plant), still under 5 min. The tier guarantee itself is covered by
`tests/specs/first_session_spec.luau` (`LUNE-ONLY`); the Studio run proves the timing window, not
the rolled tier text.

## Raid witnessed (target < 7 min)

Output marker: `[G5] RAID-WITNESS scripted_raid_gossip wall=02:23:04`. The session began at
02:17:42 (run 3 `t0`); the gossip fired ~5:22 later, matching `scriptedRaidDelay = 330` s checked on
the 5 s `FirstSession.tick` loop. Under the 7 min target. The beat fires via
`Remotes.Notify` key `scripted_raid_gossip`, hooked on the client for the stamp.

## Verdict

- First harvest < 45 s: **pass** (3/3 runs, 20–21 s) — `SEEN-IN-STUDIO`.
- First rarity reveal < 5 min: **pass** (first harvest ~20 s, guaranteed Bagus tier; second harvest
  ~110 s) — timing `SEEN-IN-STUDIO`, tier guarantee `LUNE-ONLY`.
- Raid witnessed < 7 min: **pass** (~5:22) — `SEEN-IN-STUDIO`.

Config meets every target; no tutorial-path change proposed. Machine-readable readings in
`results.json`. Phone-size pass remains the designer's task (G3/G5 phone half is not run here).
