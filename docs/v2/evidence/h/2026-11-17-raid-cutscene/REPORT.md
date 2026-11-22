# Studio pass — Raid cutscene test hook + camera hand-back (2026-11-17)

Build: `track/c-world-look`. Place: cloud dev place, Edit mode (never saved). Viewport 749x388.
Harness gate: Studio + in-memory flag + admin; new `raid` action is behind the same `Gate`.

## What shipped (code)

- `src/server/Testing/RaidTrigger.luau` — pure gate (`allowed`) + payload (`viral`) policy.
- `src/server/Testing/Harness.luau` — gated `raid` action (starts a raid now; `force` clears the
  cooldown, `viral` selects a VIRAL raid) and `raidState` read action. Both pass through `enabled(player)`.
- `tests/specs/raid_trigger_spec.luau` — 9 specs: gate refuses published/non-admin/flag-off/truthy
  values, only admits Studio+flag+admin, matches the live gate, never ships enabled; viral payload.
- `lune run tests/run.luau`: 1675 passing (was 1666).

## What is proven in Studio

- Force-raid hook: `SEEN-IN-STUDIO`. `{action="raid"}` → reply `{ok=true,state="incoming",inRaid=true}`,
  player attr `InRaid=true`; the cutscene plays without waiting ~5:30. Gate confirmed: refused while
  another raid was busy, works once idle.
- Camera hand-back on finish: `SEEN-IN-STUDIO`. Per-frame recorder (5134 frames): camera went
  `Scriptable` (364 frames) during the cutscene, FOV dipped to **26** (zoom3) and eased back to **72**;
  camera back to `Custom` at finish, state advanced to `choosing`.
- Camera hand-back on skip: `SEEN-IN-STUDIO`. Skip tap mid-cutscene (camera was Scriptable) → camera
  `Custom`, FOV 72, state `choosing`, `RaidCutsceneSeen` incremented.
- Camera hand-back on death: `SEEN-IN-STUDIO`. Mid-cutscene (Scriptable) → set Humanoid.Health=0 →
  camera `Custom`, FOV 72 immediately and after respawn.
- Camera hand-back on Raid_End: `SEEN-IN-STUDIO`. Choosing → `Raid_Choose("denda")` fires Raid_End →
  camera `Custom`, FOV 72 before and after; raid scrim visible then auto-hides after ~4 s.
- Full 20 s choice window: `SEEN-IN-STUDIO`. At cutscene end the countdown showed **20**, one second
  later **19**; `Law.raidChoiceTimeout=20`. The cutscene does not eat the choice window.
- BREAKING NEWS lower third: `SEEN-IN-STUDIO` (render + structure). Visible 567 frames during the zoom
  shots, text `raid_lower_third` (id/en), 15 px, TextWrapped, 640 px wide inside the device safe area.

## Not checked / decisions

- Phone-width readability of the lower third: only the 749x388 short/landscape viewport is available;
  the device emulator cannot be set via MCP. Text size/wrap/position checked structurally; visual
  confirmation at iPhone 14 width is the designer's step.
- Test-only resize of the Skip/phone buttons during click calibration was in Play mode only; a play
  restart restored clean state. No screenshots saved (this model cannot read viewport captures) —
  console output and per-frame state are the evidence. `JuraganDesa.rbxl` never saved, never published.
- Harness note: a first run hit `attempt to call a nil value` in the raid hook (`ensureTables` was a
  RaidService local). Fixed in the same commit; re-ran clean.
