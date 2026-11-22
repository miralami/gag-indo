# H — Mutation testing of 25 service functions — 2026-11-19

Track H, `WORK_QUEUE.md` item 14. One injected fault per key function across economy, inventory,
raid, debt, receipts and save. Each fault flips a comparison or drops a guard; the full Lune suite
runs with the fault applied and the original bytes are restored in a `finally` block. **Result:
25/25 mutants killed, 0 survivors, 0 manifest errors**, with every fault reverted. Status
`LUNE-ONLY` (no Studio playtest needed — the changes were temporary source mutations, all removed).

## Method

`C:\Users\Sena\AppData\Local\Temp\opencode\mutation-run.ps1` (pass 1) and `mutation-run2.ps1`
(passes 2–3) read each target file with `ReadAllBytes`, apply a **single exact-line replacement**
only when the search string occurs exactly once, run `lune run tests/run.luau`, record the exit code
and the `FAILED, … passed` summary, then restore the original bytes in `finally`. A mutant is
`KILLED` when the suite exits non-zero, `SURVIVED` when it exits zero. `MANIFEST_ERROR` means the
search string was not unique and no fault was applied. Pass 2 added an occurrence index so
ambiguous guards could be targeted; pass 3 re-ran survivors after new specs were added.

## Pass 1 — 15 killed, 7 survived, 3 manifest errors

Killed on the first run: `E01`–`E06`, `I08`, `I11`, `R13`, `D18`, `D20`, `P21`–`P23`, `S24`
(15). Three strings occurred twice in their file and were correctly skipped rather than mutated
blindly: `I10` (`if free <= 0` in both the capacity guard and the loop break), `D17`
(`debt.active and debt.owed > 0` in `borrow` and `onLoaded`), `D19`
(`not debt.active or debt.owed <= 0` in `repay` and `tick`).

Seven mutants survived the existing suite:

| ID | Function | Fault | Why it survived |
| --- | --- | --- | --- |
| `E07` | `EconomyService.transfer` | `moved <= 0` → `< 0` | balance-neutral, but emitted two analytics rows and two syncs for a zero transfer; no spec asserted silence |
| `I09` | `StorageService.used` | drop `not gudang.stacks` | a gudang without `stacks` passed nil to `Produce.count`; no spec covered that shape |
| `I12` | `moveStack` | `count <= 0` → `< 0` | left a zero-count stack in the source sack after the last item moved; counts still matched |
| `R14` | `resolveChoice` | drop the `choosing` state check | both callers (`onChoose`, the timeout timer) already guard the state — behaviourally equivalent from every reachable state |
| `R15` | `resolveChoice` | `cash >= fine` → `>` | no spec tested the exact-cash boundary, where the player was wrongly jailed |
| `R16` | `releaseFromJail` | drop `isState(raid, "jail")` | `jailUntil` is only assigned in `sendToJail` together with the jail state — equivalent by invariant |
| `S25` | `PlayerData.saveAndConfirm` | drop the `IsActive` guard | still returned false, but needlessly subscribed to `OnAfterSave` and called `Save()` on an inactive profile |

## Pass 2 — disambiguated manifest errors: 2 killed, 1 survived

Occurrence-indexed replacement targeted the first occurrence of each ambiguous guard: `I10`
(the capacity guard with the `n_gudang_full` notice) and `D17` (the `borrow` duplicate-loan guard)
were killed (3 and 1 failures respectively). `D19` (the `repay` guard) survived: with
`active=true, owed=0` the mutant pays nothing, clears the loan and awards the cleared badge.

## Pass 3 — eight new killer specs: 8/8 killed

Eight cases were added to the existing specs that already own each module's harness (no new
fixtures duplicated):

- `economy_spec.luau` — a zero transfer emits no analytics rows (`E07`).
- `storage_failure_spec.luau` — `used()` on a gudang without `stacks` returns 0 (`I09`);
  `depositAll` deletes the source stack key when its last item moves (`I12`).
- `debt_failure_spec.luau` — `repay` refuses an active loan with zero owed (`D19`).
- `raid_failure_spec.luau` — cash exactly equal to the fine clears the raid without jailing
  (`R15`); two source-invariant locks assert that `resolveChoice` keeps its own `choosing` guard
  (`R14`) and `releaseFromJail` keeps its `jail` guard (`R16`), since those two mutants are
  behaviourally equivalent through their callers but must not become reachable if a caller changes.
- `data_pass_failure_spec.luau` — `saveAndConfirm` on an inactive profile subscribes to nothing
  and saves nothing (`S25`).

Every re-run failed **exactly one** test, and each failure name matched its intended killer spec —
no cross-killing or vacuous pass. Suite count went 1972 → 1980 (+8). Full detail, including the
fault strings and per-mutant failure lines, is in `results.json`.

## Revert and validation

All 25 faults were restored byte-for-byte by the runner's `finally` block; `git diff` on the six
target files is empty afterwards. `lune run tests/run.luau`: **1980 passed**. `selene src`:
0 errors / 0 warnings / 0 parse errors. No Studio place saved or published; no secrets touched.
