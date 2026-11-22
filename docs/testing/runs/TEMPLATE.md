# Manual Test Run

Copy this file to `docs/testing/runs/<date>-<short commit>.md` and fill it in. Cases are defined in [PLAYTEST_CASES.md](../../v2/qa/PLAYTEST_CASES.md). The rows below are its every-version set (P0); add a row for every other case you ran.

| Field | Value |
|---|---|
| **Version / commit** | `git rev-parse --short HEAD` → |
| **Date** | |
| **Tester** | |
| **Build** | Studio (Rojo live sync) / published place |
| **Devices** | PC / phone emulator (which?) / real phone |
| **Config tweaks** | (any shortened timers in `src/shared/Config`? Put them back afterwards) |
| **Automated suite** | `lune run tests/run` → ___ passed, ___ failed |

**Result key:** `P` pass · `F` fail · `B` blocked (could not run, say why) · `S` skipped on purpose · `-` not run yet

## Results

| ID | Set | Pass (R1..R6) | Result | Notes (required for anything but P) |
|---|---|---|---|---|
| SMK-01 | P0 | | - | |
| FLOW-01 | P0 | | - | |
| FLOW-02 | P0 | | - | |
| FARM-01 | P0 | | - | |
| FARM-07 | P0 | | - | |
| MG-01 | P0 | | - | |
| MG-02 | P0 | | - | |
| SHOP-02 | P0 | | - | |
| MKT-01 | P0 | | - | |
| MKT-13 | P0 | | - | |
| LAW-01 | P0 | | - | |
| LAW-08 | P0 | | - | |
| LAW-09 | P0 | | - | |
| LAW-14 | P0 | | - | |
| LAW-16 | P0 | | - | |
| LAW-17 | P0 | | - | |
| LAW-18 | P0 | | - | |
| PER-01 | P0 | | - | |
| PAY-01 | P0 | | - | |
| PAY-02 | P0 | | - | |
| PAY-03 | P0 | | - | |

## Findings

Anything odd you noticed, in free form. For each real bug, write what you did, what you expected, what happened, and the Output error text if any.

1.

## Sign-off

- [ ] Every **P0** case is `P`.
- [ ] Every `F` has a decision: fixed in commit ______ / accepted because ______.
- [ ] Automated suite is green.

**Verified by:** ______  **Date:** ______
