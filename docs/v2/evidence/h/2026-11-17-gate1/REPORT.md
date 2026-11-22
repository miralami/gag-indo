# Studio pass — Gate 1 harness rows + bug fix (2026-11-17)

Build: `track/c-world-look` @ 8d0a64e + BUG-012 fix. Place: cloud dev place, Edit mode (never saved).

## Bug found and fixed (bugs first)

- **BUG-012** (major): every `sell` printed `Z is not a valid member of Vector2` at
  `src/client/Feel/ActionFeel.luau:22`. `cashFlyTrajectory` probed `.Z` directly; Roblox Vector2
  throws on that read, while the Lune spec used a plain table so it never caught it. Fixed with a
  `pcall` probe; added a strict-2D regression in `tests/specs/feel_spec.luau`. `SEEN-IN-STUDIO`:
  re-ran plant→ready→harvest→sell with clean Output (no `Z` error, only external BUG-003).
  1676 tests passing.

## Gate 1 rows verified in Studio

- **G3 (harness half)**: `SEEN-IN-STUDIO`. Full core loop ran end to end via harness: plant
  (padi 7→6) → ready → harvest (sack 0→1) → sell (cash +25, sack→0) → buy (padi 6→8), plus
  quest/goto/save all `ok=true`. All 10 harness commands reply with correct state. Saved state
  survived a stop/replay (cash 55814 restored).
- **Q2 (clean Output)**: `SEEN-IN-STUDIO` after the BUG-012 fix — full session Output has zero errors
  and zero game warnings; only the 3× external BUG-003 asset line, closed as external via blank place
  (`h/2026-11-14-phase0/bug003-blank-place.log`). Formal gate still awaits the designer's D-G4
  acceptance of that exclusion (no clause in the plan).
- **Q3 (no dead ends)**: several cases now `SEEN-IN-STUDIO`:
  - death: humanoid.Health=0 → respawn ~6 s, cash/padi/tiles unchanged, no stuck minigame;
  - reset: server-side kill → same recovery, minigame Scrim not left visible;
  - rejoin mid-raid: `raid` hook → state `incoming`/InRaid=true, stop+replay → cash fined exactly 5000,
    InRaid cleared, new session `idle`/not busy, no stuck overlay;
  - full sack: sell clears the sack (8→0) and re-enables harvesting; filling to literal base 40 was
    limited by per-buy shop stock restock, so the "sack exactly full" boundary stays manual;
  - 20 s choice window timing also re-confirmed (see raid-cutscene evidence).
  Still not evidenced: mid-loan, mid-minigame cancel, zero-cash+zero-seed auto-recovery (LUNE-ONLY
  seedfloor_spec), every-button sweep (needs manual clicks/screenshots).

## Not Studio-verifiable (unchanged / designer)

G4/G4b (placeholder sweep + phone-size text — no screenshots readable by this model), G5 timed beat
sheet, G6 real fps (no instrumentation; designer phone), G7 five humans, Q4/Q6/Q7 (published place /
real device), ten-player session. Device emulator cannot be set via MCP.

`JuraganDesa.rbxl` never saved, never published. Play mode stopped at end.
