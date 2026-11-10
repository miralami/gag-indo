# Manual Test Run

Copy this file to `docs/testing/runs/<date>-<short commit>.md` and fill it in. Cases are defined in [../MANUAL_TESTS.md](../MANUAL_TESTS.md).

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

| ID | Priority | Result | Notes (required for anything but P) |
|---|---|---|---|
| SMK-01 | P0 | - | |
| SMK-02 | P0 | - | |
| SMK-03 | P0 | - | |
| SMK-04 | P1 | - | |
| FARM-01 | P0 | - | |
| FARM-02 | P1 | - | |
| FARM-03 | P0 | - | |
| FARM-04 | P1 | - | |
| FARM-05 | P1 | - | |
| FARM-06 | P0 | - | |
| FARM-07 | P1 | - | |
| FARM-08 | P1 | - | |
| FARM-09 | P2 | - | |
| MKT-01 | P0 | - | |
| MKT-02 | P1 | - | |
| MKT-03 | P0 | - | |
| MKT-04 | P1 | - | |
| MKT-05 | P1 | - | |
| MKT-06 | P1 | - | |
| MKT-07 | P2 | - | |
| LAW-01 | P0 | - | |
| LAW-02 | P1 | - | |
| LAW-03 | P1 | - | |
| LAW-04 | P2 | - | |
| LAW-05 | P1 | - | |
| BRB-01 | P0 | - | |
| BRB-02 | P1 | - | |
| RAID-01 | P0 | - | |
| RAID-02 | P0 | - | |
| RAID-03 | P1 | - | |
| RAID-04 | P1 | - | |
| RAID-05 | P2 | - | |
| RAID-06 | P1 | - | |
| LAP-01 | P0 | - | |
| LAP-02 | P0 | - | |
| LAP-03 | P1 | - | |
| LAP-04 | P1 | - | |
| LAP-05 | P0 | - | |
| LAP-06 | P2 | - | |
| UI-01 | P1 | - | |
| UI-02 | P1 | - | |
| UI-03 | P2 | - | |
| ITM-01 | P1 | - | |
| ITM-02 | P1 | - | |
| COS-01 | P1 | - | |
| NBR-01 | P2 | - | |
| PAY-01 | P0 | - | |
| PAY-02 | P0 | - | |
| PAY-03 | P1 | - | |

## Findings

Anything odd you noticed, in free form. For each real bug, write what you did, what you expected, what happened, and the Output error text if any.

1.

## Sign-off

- [ ] Every **P0** case is `P`.
- [ ] Every `F` has a decision: fixed in commit ______ / accepted because ______.
- [ ] Automated suite is green.

**Verified by:** ______  **Date:** ______
