# Studio pass — Raid cutscene world anchors (Track F, 2026-11-17)

Build: `track/c-world-look` @ f77940d + anchor config/wiring. Place: cloud dev place, never saved.

## What shipped (code, testable logic)

- `src/shared/Config/RaidCutscene.luau`: `focusAnchors` (kades → Rumah Pak RT 68/3.4/68,
  police_chief → Pos Polisi -68/3.4/68, road → plaza cross 0/2/-28, from MapSpec HUBS) and a pure
  `anchorFor(focus)` resolver returning nil for unknown/nil focuses. Anchors are plain {x,y,z} tables
  so the config stays Lune-pure.
- `src/client/UI/RaidOverlay.luau`: `placeCamera` now aims the zoom/walkin shots at the real anchor
  when `anchorFor(shot.focus)` returns one; keep-out/yaw/stand-off are preserved; falls back to the
  existing player-relative framing when no anchor (e.g. `player`, `plot`).
- `tests/specs/cutscene_sequencer_spec.luau`: 2 specs (real anchor values from MapSpec hubs;
  resolver returns known/nil correctly). 1684 tests passing.

## What is proven in Studio

- Config + resolver live: `SEEN-IN-STUDIO` (data). `RaidCutscene.anchorFor("kades")` returned
  `68,3.4,68` in play; the overlay anchor wiring is present in the synced DataModel.
- Cutscene still runs with anchors: `SEEN-IN-STUDIO` (structure). Triggered a raid; mid-cutscene the
  camera was Scriptable, FOV dipped, no new Output error (only external BUG-003 + the MCP tool's
  own camera-reset note).

## Not checked / BLOCKED on designer

- **Visual framing quality** of the anchored shots: BLOCKED on designer — this model cannot read
  viewport captures, and the visual plan (§8) requires before/after screenshots and a designer
  "yes" before a framing change counts as done. Coordinates are starting points from MapSpec, not
  approved compositions.
- **Police NPC walk-in**: not built. Needs an authored police model/animation (L6/V-L6.1–V-L6.2) and
  a walk-in timed to the cutscene; `RaidService.policeGoTo` already walks the two police NPCs to the
  plot, but the sinetron "walk-in" shot with a real NPC model is BLOCKED on the F-track asset/animation
  work and the designer's look-dev pass.
- `JuraganDesa.rbxl` never saved, never published. Play mode stopped at end.
