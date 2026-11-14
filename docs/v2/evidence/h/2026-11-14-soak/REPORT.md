# Soak report, 2026-11-14 (client loop, 1800 s)

Raw result: `soak.json` in this folder. Studio `Development-Juragan-Desa` (placeId 132087524375529),
Play Solo, memory-only harness. The loop was a recovery-aware variant of HARNESS §11 (read `status`
each cycle, buy any stocked crop, plant up to 6, ready, harvest, sell `pasar`), not the fixed loop.
Status: **SEEN-IN-STUDIO** for the soak half of quality bar 5. The ten-player half is `UNVERIFIED`.

## Result

- Elapsed 1801.3 s, 111 cycles, 395 skipped cycles (nothing buyable or plantable that pass), 0 stale replies.

## Calls and failures

| Action | Calls | Failures | Notes |
|---|---|---|---|
| status | 980 | 0 recorded | |
| enable | 1 | 0 recorded | |
| plant | 424 | 104 | 320 succeeded. All "tile N is not empty"; last "tile 5 is not empty". |
| ready | 111 | 0 | |
| harvest | 424 | 0 | |
| sell | 111 | 0 | |
| buy | 98 | 20 | 78 succeeded. Last: "shop refused cengkeh x4 (stock, rank or cash)". |

## Cash

2141 → 90378 (+88237). Per-action amounts were not recorded, so no desync check was done.

## Client memory (MB)

First 2231.4, mid 2195.3, last 1588.8, min 1421.8, max 2277.0, 507 samples. No sustained climb.

## Server memory

Not in `soak.json`; sampled ad hoc only (about 2248 MB at minute 7, Studio shares one process).

## Plant failures

All 104 are "tile N is not empty". The explanation that perennial crops survive harvest is
**UNCONFIRMED**.

## Not checked

- Full `output.log` not saved: the console tool truncated the head. The tail held only
  `AnalyticsService` info lines. No zero-error claim is made.
- Server memory series.
- Ten-player half: not run.
- Leak verdict beyond "no sustained climb": the 507-sample series was not saved, so no plateau or floor analysis.
- Start tiles and `Seed_padi` baseline; desync check.

## Open question (not a bug)

Cash grew about 42× in 30 minutes. Balance review for track B; no conclusion on intent.
