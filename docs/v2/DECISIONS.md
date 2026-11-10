# v2 — Designer Decisions

> Decisions that belong to the designer, kept out of code and out of the plan. Nothing here
> blocks M0/M1 code: each item has a safe default already in place, marked **Default**.

Status values: **open** · **decided** · **changed**

| # | Decision | Default if unanswered | Status |
|---|---|---|---|
| D1 | Approve or redirect the UI direction (PLAN §3.1). Static mockups: `docs/v2/mockups/index.html` | Mockups are proposals; the v1 Theme stays until approval, then the UI rebuild starts | open |
| D2 | "Politics (story)" = story chapters + Kepala Desa system? | Build both, in v2.1, in the order PLAN §4 lists them | open |
| D3 | Launch after v2.0 instead of waiting for all four releases? | Launch after v2.0, as PLAN §1 assumes | open |
| D4 | Name of the hidden informant NPC (currently "Mbah Dukun-style") | Use `Mbah Dukun` as the working name only in comments; never in live strings until decided | open |
| D5 | Name of the pinjol app | Use `Pinjol` as the working label; the phone UI is built in M4 | open |
| D6 | Roblox access in Indonesia (PLAN §8.1) — verify before M3 writes final copy | Keep text ID-first with EN alongside; treat global accessibility as required | open |
| D7 | Maturity questionnaire answers and policy review (PLAN §8.2) | Keep every target a fictional system; do not name real officials or parties | open |
| D8 | Audio source and licence (PLAN §3.1) | Ship with no audio; `Config/Audio.luau` IDs stay `0` until licensed assets exist | open |
| D9 | Real pass/product IDs and prices (M4) | `Config/Products.luau` and `Config/Cosmetics.luau` IDs stay `0`; nothing prompts or errors | open |
| D10 | Admin allowlist: whose Roblox UserIds? | `server/Live/Admins.luau` is empty, so no place has admins until filled | open |

## How to change one

1. Edit this table: set **Status** to `decided` and write the answer in **Default if unanswered**.
2. If it unblocks code, make the code change in the same commit and link the row number in the
   commit message (e.g. `M3: UI kit per D1`).

## Notes

- Decisions already fixed by the designer and folded into the plan are not repeated here.
- Anything that changes player-visible balance belongs in `Config/`, not in this file.
