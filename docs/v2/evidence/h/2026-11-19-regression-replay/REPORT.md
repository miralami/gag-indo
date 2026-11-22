# H — Regression replay on synced code — 2026-11-19

Track H, `WORK_QUEUE.md` item 29: replay the Gate 1 evidence after all of items 1–28 landed, to
catch any regression introduced by the later work. Every reading below was taken live in Studio
against the Rojo-synced working tree; no number is copied from an older report without a fresh run.
No designer identity recorded.

## Setup

- Branch `track/c-world-look`, HEAD `350c48f71b436c52ec6d733e5cb84c50da5aff7c` (item 28).
- Studio `Development-Juragan-Desa`, placeId `132087524375529`, Rojo on `localhost:34872`, Edit
  datamodel synced before each Play restart.
- Fresh profile via a VERIFY-TEMP edit in `src/server/Data/PlayerData.luau` switching `store` to the
  in-memory ProfileStore `.Mock` reflection. Reverted before commit; **never committed**.
- Play Solo, desktop viewport. Driver: `Harness_Command` / `Harness_Result` remotes paced 0.35 s
  apart (under the documented 4 commands/s/player limit). Machine data in `results.json`.

## G3 — full nine-step beat sheet — `SEEN-IN-STUDIO`

One coherent pass, all nine steps `ok=true`. Cash 50 → 77 → 57 → 157, padi 5 → 4 → 6, sack
0 → 1 → 0, `tutorialStep` 1 → 5, rank `gurem` throughout, wall 09:58:43 → 09:58:46. This is
identical to the item-28 baseline (`h/2026-11-19-g3-beatsheet/`), so no regression in the
plant/ready/harvest/sell/buy/quest chain.

## Forced-raid regression — `SEEN-IN-STUDIO`

`raid { viral=true, force=true }` → `ok=true`; `raidState` = state `incoming`, `inRaid=true`,
`busy=true`; status after = cash 157, `tutorialStep` 5, `inRaid=true`, wall 09:58:57 → 09:59:00.
This exercises the item-21 raid overlay (non-closable, phase-driven selection, explicit
`NavBridge.rescue()`), item-22 sound lifecycle and item-23 lighting-tier code paths together.
No error or stuck state observed.

## Q2 — full-session Output — `SEEN-IN-STUDIO`

Saved verbatim to `g3-g5-q2-output.log`. Zero game-code errors and zero game-code warnings. The only
non-game lines are two external Assistant-plugin version warnings, AnalyticsService event notices,
and one `execute_luau` camera-type reset notice from the harness itself. The BUG-003 external asset
line did **not** recur in this session. Bar met (D-G4 already accepts the external exclusions).

## G5 — first-session timings — `SEEN-IN-STUDIO`

Three fresh profiles (Play restarted each run; cash 50, `tutorialStep` 1, padi 5), real grow timers,
no `ready` shortcut. Timestamps in `results.json`.

| Run | First harvest | Target | Second harvest / Super reveal | Target |
|---|---|---|---|---|
| 1 | 20 s (10:00:02 → 10:00:22) | < 45 s | — | < 5 min |
| 2 | 20 s (10:00:46 → 10:01:06) | < 45 s | — | < 5 min |
| 3 | 20 s (10:01:49 → 10:02:10) | < 45 s | 48 s (10:02:10 → 10:02:58) | < 5 min |

All readings meet or beat the item-28 baseline (`h/2026-11-19-g5-timings/`). No balance change
proposed.

## Q5 — thirty-minute soak, client half — `SEEN-IN-STUDIO`

Fresh profile, baseline cash 50 / padi 5 / tilesOwned 6, server memory start 2617.5 MB. Injected
`SoakProbe` LocalScript in `PlayerScripts`: 1800 s loop of plant tiles 1–6 padi → `ready` → harvest
1–6 → `sell pasar` → `buy padi 1`, writing `ReplicatedStorage.SoakData` folder attributes flushed
every 5 cycles, plus `G5SessionStart` / `G5GossipAt` markers. Ran to the 1800 s deadline:
**1801.71 s, 234 cycles, `done=true`**, data in `soak.json`, console in `soak-output.log`.

- **No leak** — client memory 235 samples, 2617.57 → 2586.09 MB (min 2578.21, max 2618.38,
  delta −31.5 MB); server memory 2617.5 → 2587.3 MB. No upward trend.
- **No stuck state** — the driver completed all 234 cycles to the deadline; final status cash 945
  (up from 50), rank `gurem` → `petani`, lifetimeEarned 1495, `tutorialStep` 5, tilesOwned 6.
- **No desync symptom** — no stale replies and the final status is coherent. An explicit
  client/server state diff was not scripted this run.
- **Zero game-code errors/warnings** across the full soak Output; only external Assistant warnings,
  a ProfileStore notice and AnalyticsService event notices. BUG-003 did not recur.
- **Raid gossip** marker at 310 s from session start (< 420 s / 7 min target).

The 1339 plant / 1339 harvest / 178 sell / 174 buy failures are **graceful refusals, not defects**:
the probe buys only 1 padi per cycle but attempts 6 plants, so seeds run out ("no padi seed",
"sack is empty"). This is the same class as the 2026-11-14 baseline soak (104 plant + 20 buy
refusals, `h/2026-11-14-soak/soak.json`) and consistent with the BUG-004 documented caveat. The
economy still advanced throughout, so no player-affecting stall.

The ten-player / multi-client half remains `BLOCKED` (no local-server/team-test tool in the Studio
MCP surface); evidence `h/2026-11-19-q5-multiclient/`.

## Verdict

G3, forced-raid regression, Q2, G5 and the Q5 client-half soak all reproduce or beat the item-28
evidence on the current synced code — no gameplay regression found. No bug filed. Remaining Gate 1
gaps are unchanged and all designer/hardware-dependent (phone-size replays, multi-client, published
place, real-device play, final art).
