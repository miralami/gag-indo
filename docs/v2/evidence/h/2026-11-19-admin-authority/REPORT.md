# Admin and season tools — Track H, 2026-11-19

WORK_QUEUE item 16: every admin command validates who calls it and what it receives; non-admins are
refused; no admin path can grant unbounded cash or items. All results are `LUNE-ONLY`.

## Existing coverage (not duplicated)

- `tests/specs/season_admin_failure_spec.luau` — with `Admins` and `LiveConfig` **mocked**, proves
  non-admins are refused for all actions, malformed envelopes are inert, season/anomaly/event values
  are validated, `grantItem` enforces 1..1000 and real item ids, `grantCash` enforces 1..10,000,000,
  rate-limited commands are dropped, and replies go only to the caller.
- `tests/specs/security_spec.luau` — allowlist contains the designer id and not arbitrary ids.
- `tests/specs/harness_spec.luau` / `raid_trigger_spec.luau` — Studio + admin + flag gates.
- `tests/specs/player_leave_cleanup_spec.luau` — `IsAdmin` attribute cleared on leave.

The gap: no spec wired the **real** allowlist, the **real** LiveConfig and the **real** AdminService
together, so the actual gate was never exercised end to end.

## New spec — `tests/specs/admin_authority_spec.luau` (4 cases, `LUNE-ONLY`)

Uses the real `Admins`, `LiveConfig`, `AdminService` and `Inventory`; only persistence, remotes,
player data, rate limit, state touch and economy add-cash are faked. No ids are invented — the
designer UserId is read from the shipped allowlist (`Admins.userIds[1]`).

1. **Published server (`RunService:IsStudio() == false`):** a non-allowlisted player sending all five
   privileged actions (setSeason, setAnomaly, setEvent, grantCash, grantItem) gets only
   access-denied replies; the live config, cash and items are unchanged.
2. **Attribute forgery:** setting `IsAdmin = true` on the attacker grants nothing — the server gates
   on `Admins.isAdmin(player.UserId)`, not the client-visible attribute.
3. **Allowlisted designer:** setSeason/setAnomaly/setEvent actually change the real `LiveConfig`
   config and runtime; `grantCash(500)` calls `addCash` once with `earned = false` and `sku =
   admin_grant`, so admin grants never inflate rank or leaderboard.
4. **Studio convenience:** with `IsStudio() == true` every player is treated as admin, but payload
   bounds still hold (unknown season and a 1e9 cash amount are refused); a valid command still works.

No source bug was found — item 16 was missing proof, not a defect. No game source changed.

## Proof

- `lune run tests/run.luau`: **1821 passing** (was 1817; +4 new cases).
- `selene src`: 0 errors / 0 warnings / 0 parse errors.
- File: new `tests/specs/admin_authority_spec.luau` (registered in `tests/run.luau`).

## Limits

- No live Studio/published-server admin-panel run: Studio MCP cannot toggle `RunService:IsStudio()`
  on a published server or drive a real client to send `Admin_Command`. The real gate and real config
  are proven against actual module code with fake persistence instead.
- Studio's "everyone is an admin" behaviour is intentional (dev convenience) and is documented in
  case 4, not treated as a defect; a published place only trusts the allowlist.
