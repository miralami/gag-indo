# H — 30-minute soak with all candidates on — 2026-11-19

Track H, `WORK_QUEUE.md` item 12. A 1800 s client soak with **all eight LookDev candidates applied at
once**, checking for a memory leak, stuck/orphaned connections and growth. Every reading below was
taken live in Studio against the Rojo-synced working tree. No designer identity recorded.

## Setup

- Branch `track/c-world-look`, HEAD `e217bda` (item 11). Studio `Development-Juragan-Desa`, placeId
  `132087524375529`, Rojo `localhost:34872`, Play Solo, desktop viewport.
- Fresh profile via a VERIFY-TEMP edit in `src/server/Data/PlayerData.luau` switching `store` to the
  in-memory ProfileStore `.Mock` reflection. Reverted before commit; **never committed**. Git clean
  after the run.
- Harness enabled from a Studio admin (`Harness_Command:FireServer({ action = "enable" })`) —
  reply `Harness on.`. Commands paced 0.5 s apart (2/s, under the 4/s `RateLimit` bucket).
- **All eight candidates applied additively.** `LookDev` is single-active, so "all on" was assembled
  from the disjoint appliers exactly as in item 11's budget check: six client adapters called
  directly (`icons`, `textures`, `npcs`, `crops`, `hubprops`, `sounds`), `plaza_lighting` via
  `LookDev.enable` on Client, and `police_walkin` via `LookDev.enable` on Server (injected server
  `Script`, because the restricted `execute_luau` VM has a separate require cache). All eight
  reported `ok`; the server `LookDev.current()` was `police_walkin`.
- Driver: injected `SoakProbe` LocalScript in `PlayerScripts` (same require cache as `Main.client`),
  1800 s loop plant tiles 1–6 padi → `ready` → harvest 1–6 → `sell pasar` → `buy padi 1`, writing
  `ReplicatedStorage.SoakData` attributes flushed every 5 cycles and at done. Machine data in
  `soak.json`; full- soak Output in `soak-output.log`.

## Result — `SEEN-IN-STUDIO`

Ran to the deadline: **1801.83 s, 234 cycles, `done=true`**, 15 commands/cycle as designed.

- **No memory leak.** Client memory (235 samples) 2750.97 → 2635.36 MB (net **−115.6 MB**, min
  2623.96, max 2757.61). The single large mid-run drop at sample 54 is a GC compaction (2744.38 →
  2623.96 MB, −120.4 MB), not a reset. After compaction the series drifts only +11.4 MB over 180
  cycles, decelerating to +3.06 MB over the final 40 cycles — a plateau, not unbounded growth.
  Server memory 2760.76 → 2636.04 MB (net **−124.7 MB**). Each series compared to its own start.
- **No growth / no stuck-orphaned connections.** Roblox exposes no raw RBXScriptConnection counter,
  so the documented proxies were used: the harness pending-reply queue stayed at **0** for the whole
  run (no stale or orphaned replies), and the whole-DataModel census moved 6735 → 6898 instances /
  1706 → 1840 parts over 1800 s (~0.09 instances/s), then **+2 instances / +0 parts** over the ~993 s
  after the loop stopped — a plateau. Zero crop parts persisted on tiles at the end; the two
  appliers that register signals (`npcs`, `walkin`) create them once at apply and disconnect once at
  restore, so repeated cycles cannot accumulate them.
- **No stuck state.** All 234 cycles completed; final pending 0; `calls` exactly
  plant 1404 / harvest 1404 / ready 234 / sell 234 / buy 234.
- **No desync symptom.** Baseline cash 50 / padi 5 / tilesOwned 6 / `gurem` / lifetimeEarned 0;
  end cash 754 / padi 0 / tilesOwned 6 / `petani` / lifetimeEarned 1324 / tutorialStep 5. Cash and
  earnings advanced coherently and tilesOwned stayed constant. An explicit client/server state diff
  was not scripted (same limitation as the regression-replay soak).
- **Zero game-code errors** across the full soak Output; only the known ProfileStore notice, the
  rbxassetid asset-type warning, AnalyticsService notices and probe self-destroy warnings. BUG-003
  did not recur.

The 1337 plant / 1337 harvest / 178 sell / 172 buy failures are **graceful refusals, not defects**:
the probe buys 1 padi per cycle but attempts 6 plants, so seed stock runs dry by design and the
harvest/sell refusals follow. This is the same class documented in the regression-replay soak, and
the economy still advanced throughout — no player-affecting stall.

## Cleanup

Play stopped, returned to Edit, all probe instances destroyed (Play Solo discards runtime instances;
verified none remained in the Edit datamodel). VERIFY-TEMP mock edit reverted, place not saved,
nothing published, no `JuraganDesa.rbxl` save, git clean. No asset IDs, product IDs or UserIds
invented. No art was graded or approved.

## Ten-player half

The multi-client half of the quality-bar row remains `BLOCKED` — no local-server/team-test tool is
exposed by the Studio MCP surface (see `h/2026-11-19-q5-multiclient/`). This item proves the
single-client, all-candidates-on soak only.
