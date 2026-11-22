# Analytics audit against `ANALYTICS.md` — Track H, 2026-11-19

WORK_QUEUE item 17: every documented event fires from the right trigger, funnel steps are in order
and fire once, and payloads have bounded size. All results here are `LUNE-ONLY`; the platform
dashboard remains **belum diverifikasi di Studio** (`ANALYTICS.md` §7).

## Documented events vs. implementation

Every row of `ANALYTICS.md` §2 was checked against the actual call sites in `src/`.

| Documented event | Owning call site(s) | Status |
|---|---|---|
| `harvest` | `src/server/Farm/FarmService.luau:450` (`{crop, tier, destination}`) | wired |
| `raid_started` | `src/server/Law/RaidService.luau:308` (1 normal / 2 viral) | wired |
| `cheat_used` | `src/server/Law/CheatService.luau:54,94,106` (oplosan/curi_air/gelap) | wired |
| `report_made` | `src/server/Law/EvidenceService.luau:248` | wired |
| `debt_borrowed` | `src/server/Economy/DebtService.luau:145` | wired |
| `debt_overdue` | `src/server/Economy/DebtService.luau:256,268,272` (warning/shame/seize) | wired |
| `debt_cleared` | `src/server/Economy/DebtService.luau:188,295` (ontime/overdue/seized) | wired |
| `debt_seized` | `src/server/Economy/DebtService.luau:284` | wired |
| `purchase` | `src/server/Monetization/Receipts.luau:97` (product key) | wired |
| `login_streak` | `src/server/Progression/QuestService.luau:142` | wired |
| `task_claimed` | `src/server/Progression/QuestService.luau:221` | wired |
| `rank_up` | `src/server/Progression/RankService.luau:55` | wired |
| `badge_awarded` | `src/server/Progression/BadgeService.luau:28` | wired |
| `risk_banjir` / `risk_hama` / `risk_gagal` | `src/server/Farm/FarmService.luau:420,428,436` | wired |
| `first_harvest` (example `once`) | **no call site in `src/`** — only a sample name in `analytics_spec.luau` | documented example, not wired → "Decisions for designer" |

Economy events (§3): `src/server/Economy/EconomyService.luau:104,125,145,146` emit Source on
committed credit and Sink on committed debit, including one event per side of a player transfer.
Funnels (§4): `OnboardingService.luau:85,88` emit onboarding steps; `ShopPurchase` is documented
as "not wired in M4" and has no call site; `FirstSession.luau:113,119,125,144` emit an **extra,
undocumented** `first_session` funnel (steps 5/7/8/9). Both exceptions are recorded in
`WORK_QUEUE.md` → "Decisions for designer" rather than silently changed.

Single-owner rule (§1): a recursive scan of `src/` finds `GetService("AnalyticsService")` only in
`src/server/Analytics/Analytics.luau`. No client or other server module calls the platform API.

## New spec — `tests/specs/analytics_audit_spec.luau` (24 cases, `LUNE-ONLY`)

- **Static audit (22 cases):** the single-owner invariant; one case per documented §2 event
  pointing at its owning file; economy and onboarding emission sites; and three negative locks —
  `first_harvest` and `ShopPurchase` have no call site, while `first_session` is present but
  undocumented. (Source-reading specs are already used here, e.g. `remote_audit_spec`.)
- **Behavioural (2 cases):** the REAL `Analytics` module wired to an in-memory AnalyticsService
  recorder, driving the REAL `OnboardingService` and `EconomyService`:
  1. Onboarding emits step numbers 1..N with config-id names in exact order, a repeated or
     out-of-order action emits nothing, and step `total + 1` ("finished") fires exactly once.
  2. `addCash` emits `Source` and `trySpend` emits `Sink`, both with the balance read **after**
     the mutation; a refused spend emits nothing; currency is `Cash` and the sku/transaction are
     passed through unchanged.

`analytics_spec.luau` already pins the wrapper contract — budget (`120 + 20 * CCU`), `once`,
`economy` validation, the 3-field cap (`CustomField01..03`) and never-fatal `pcall`. The bounded
payload requirement is therefore proven there and not duplicated in this spec; by inspection every
service call site passes at most three fields.

No source bug was found — item 17 was an audit and coverage gap, not a defect. No game source
changed.

## Proof

- `lune run tests/run.luau`: **1845 passing** (was 1821; +24 new cases).
- `selene src`: 0 errors / 0 warnings / 0 parse errors.
- File: new `tests/specs/analytics_audit_spec.luau` (registered in `tests/run.luau`).

## Limits

- The live Roblox Analytics dashboard (Creator Hub → Analytics → **View Events**) could not be
  checked: Studio MCP has no dashboard/analytics-read tool. Per `ANALYTICS.md` §7 this remains
  `belum diverifikasi di Studio`; every claim above is `LUNE-ONLY` against actual service code.
- The static audit proves each event **has** a call site in the right service; the "after the
  mutation" and ordering guarantees are proven behaviourally for onboarding and economy, and are
  locked for the other services by their own specs plus the wrapper's post-mutation-only design.
