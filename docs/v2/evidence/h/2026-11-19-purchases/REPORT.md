# Purchases / receipt idempotency — Track H, 2026-11-19

WORK_QUEUE item 14: check receipt handling (no product IDs invented) — a duplicate `PurchaseId`, a
player leaving mid-grant, a failed save after grant, unknown products, and a game-pass ownership
check that errors. Each case gets a spec that proves idempotency.

## New spec — `tests/specs/purchase_idempotency_spec.luau` (5 cases, `LUNE-ONLY`)

Unlike the existing receipt specs (which mock `saveAndConfirm`), this spec drives the **real**
`PlayerData` + `Receipts` together against a fake ProfileStore, so the durable save path is
exercised end to end. Product id `111` and pass id `777` are synthetic test integers set only inside
the test environment; the shipped `Products` config keeps every id at `0`. No real Roblox ids,
prices or UserIds are used.

1. **Duplicate `PurchaseId`** — two deliveries grant the item once, record one id, notify once,
   fire one `purchase` analytics event.
2. **Leave mid-grant** — the save confirms in memory but the profile ends before the bounded wait
   closes, so `saveAndConfirm` returns false and Roblox gets `NotProcessedYet`; after the player is
   removed from `Players` and rejoins with a fresh profile, a retry grants exactly once.
3. **Failed save after grant** — first save errors → `NotProcessedYet`, no notify; the retry
   re-confirms a save and returns `PurchaseGranted` with still exactly one grant and one recorded id.
4. **Unknown product** — an unmapped id and the shipped placeholder id `0` are never granted,
   recorded or acknowledged.
5. **Game-pass check that errors** — `UserOwnsGamePassAsync` throwing across three loads grants no
   pass attribute and `Passes.has` stays false; the error never escapes.

## BUG-016 — real money bug found and fixed

The dedup early-return in `src/server/Monetization/Receipts.luau` acknowledged a replayed
`PurchaseId` with `PurchaseGranted` immediately, without re-confirming a save. Reachable failure:
the grant and `table.insert(data.receipts, id)` succeed in memory but `PlayerData.saveAndConfirm`
fails (DataStore down) → `NotProcessedYet`; Roblox retries `ProcessReceipt`, the dedup path then
acknowledges with **no successful save ever**, and if the player leaves/crashes before the next
autosave the paid item is lost with no retry left.

Fix: on a dedup hit, call `PlayerData.saveAndConfirm(profile, id, 15)` again and return
`PurchaseGranted` only when it confirms, otherwise `NotProcessedYet`. No re-grant and no re-notify,
so a normal replay still grants/notifies exactly once and the shipped happy path is unchanged.
Recorded as `BUG-016` in `docs/testing/BUGS.md`.

Mutation check: with the old early-return restored, case 3 fails (`1 FAILED, 1807 passed`) because
the retry no longer re-saves; with the fix, all pass. No Studio step is required — the money path is
proven against real module code with a fake ProfileStore, and no real purchase or id is involved.

## Proof

- `lune run tests/run.luau`: **1808 passing** (was 1803).
- `selene src`: 0 errors / 0 warnings / 0 parse errors.
- Files: new `tests/specs/purchase_idempotency_spec.luau` (registered in `tests/run.luau`),
  `src/server/Monetization/Receipts.luau` (BUG-016 fix), `docs/testing/BUGS.md` (BUG-016 entry).
