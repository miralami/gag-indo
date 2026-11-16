# Studio Playtest Run — 2026-11-13

| Field | Value |
|---|---|
| Build | `JuraganDesa.rbxl`, Roblox Studio local Play Solo |
| Tester | OpenCode automated Studio bridge |
| Devices | Desktop Studio; mobile emulator not run |
| Config tweaks | None |
| DataStore | API services unavailable; profile not saved |
| Automated suite | `lune run tests/run` → 481 passed (separate run) |

## Results

| ID | Result | Evidence / notes |
|---|---|---|
| SMK-01 | P | Play started; `[JuraganDesa] server started`; no red error shown. |
| SMK-02 | P | Fresh Studio profile attrs: Cash 50, Seed_padi 5, TilesOwned 6, Rank `gurem`, TutorialStep `plant`; HUD/Phone/Minigame/RaidOverlay/AdminPanel/Leaderboard mounted. |
| SMK-03 | B | `[ProfileStore]: Roblox API services unavailable - data will not be saved`; persistence cannot be verified. |
| SMK-04 | B | Play Solo only; no second client. |
| SMK-05 / crop interaction | B | Prompt-trigger tool unavailable. `E` input did not activate interaction through the bridge; tile remained empty, seed stayed 5. Not a gameplay failure verdict. |
| SMK-06 / warnings | F | Output warnings: `Cloud instance must exist under Terrain node in workspace to be visible.` Asset load error repeated 3×: `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type`. |
| ART-01 | B | No visual screenshot capture available from current Studio MCP capability; visual composition not judged. |
| ART-02 | B | Terrain rebuild not executed; no source edits per the playtest plan. |
| MP / mobile / soak / security | B | Not run: Local Server, emulator, long-duration test, and controlled client exploit run were unavailable in this pass. |

## Findings

- **Major candidate:** repeated wrong-asset-type load for `rbxassetid://203785492`; find the referencing slot and correct type/ID before visual sign-off. No asset IDs changed.
- **Minor/known:** missing Cloud instance warning; check whether this place expects Clouds under Terrain.
- Fresh Studio state matched configured starting values. Studio profile persistence unavailable.

## Sign-off

- [ ] All P0 cases pass — incomplete; playtest coverage blocked.
- [x] No source edits made during playtest.
- [x] Automated suite green (481 tests, separate CLI run).

This is a partial Studio smoke run, not a sprint verification. Full cases remain in `docs/testing/PLAYTEST_PLAN.md`, `docs/testing/PLAYTEST_CASES.md`, and `docs/testing/MANUAL_TESTS.md`.
