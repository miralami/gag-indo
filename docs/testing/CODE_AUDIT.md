# Code Audit (pure Lune)

Per-task audit log for the T1-T16 workhorse backlog on `track/c-world-look`. Status: `LUNE-ONLY` unless noted. No invented findings.

## T1 — Single source of truth for world values
- **Findings:** `HEADROOM`/`SPAWN`/`GOLDEN_HOUR`/`SEASON_PRESETS` values were duplicated as literals/comments in `src/server/World/Greybox.luau` (headroom `9.5`, spawn comment `0,0.5,28`) and `src/shared/Config/Seasons.luau` had `musimOrder` literal `{"hujan","kemarau","pancaroba"}`, golden-hour comment `16.0–17.0`, and `clockTime = 17.0` literal; `Landscape.luau`, `Map.luau`, `client/World/Sky.luau`, `server/Season/SeasonService.luau` had no offending literals.
- **Fixes:** Removed literal headroom/spawn mentions from Greybox comments; made `Config/Seasons` source `musimOrder` and golden-hour max clock from `MapSpec` (robust lookup for Env/Roblox contexts); added `tests/specs/world_constants_spec.luau` asserting MapSpec owns values and target modules contain no duplicate literals.
- **Studio checks needed:** Verify season sky/clock behavior and client season loading still work in Studio (Seasons now resolves MapSpec via ServerScriptService lookup at runtime).

## BLOCKED
- `BUG-004` — broke-player recovery choice pending designer decision D-G3 (`docs/testing/BUGS.md`). No code fix applied.
