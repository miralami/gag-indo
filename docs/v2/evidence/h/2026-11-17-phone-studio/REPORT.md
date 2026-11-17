# Studio pass — BUG-011 phone + fidelity/admin state (2026-11-17)

Build: `track/c-world-look` @ working tree. Place: `JuraganDesa.rbxl` (cloud dev place, not saved).
Devices: Studio viewport 749x388 (short → phone uses landscape layout). Harness enabled via bridge.

## What changed / proven

- BUG-011 phone mount: `SEEN-IN-STUDIO`. At mount `PlayerGui.Phone` holds only `PhoneButton`
  (device is lazy, as designed); no `70 + nil` error, Output clean apart from the known external
  BUG-003 asset line. The `homeBarHeight` declaration fix is live in the synced DataModel.
- BUG-011 first tap builds the device: `SEEN-IN-STUDIO`. After activating `PhoneButton`, the tree
  contains Root/Card/Content/PageHome, all 8 app tiles (phone, kebun, pinjol, tugas, cheat, dekor,
  shop, board), Header Back/Close/LangToggle/HomeBar; `Root.Visible=true`, `PhoneButton.Visible=false`.
- BUG-011 app opens: `SEEN-IN-STUDIO`. Tapping `App_phone` built `PagePhone` (Visible=true), hid
  `PageHome`, and set the title to "Report" — proves the LazyPages one-page-at-a-time wiring in play.
- BUG-011 ID/EN: `SEEN-IN-STUDIO`. Tapping `LangToggle` changed every app tile label from Indonesian
  to English ("Report, Farm, Loan, Quests, Cheat, Decor, Seed Shop, Leaderboard") — `Strings.langFor`
  switches at runtime in play.
- BUG-011 landscape: `SEEN-IN-STUDIO` (structure). Short viewport (749x388) applied landscape:
  card aspect constraint 2, home grid 4 columns — matches `PhoneLayout.isLandscape`.
- Fidelity tier live: `SEEN-IN-STUDIO` (state). Player attribute `FidelityTier` is a valid tier
  (observed "Tinggi" and "Sedang" across two runs), published by the live FidelityRuntime.
- Admin perf switches: `SEEN-IN-STUDIO` (structure). AdminPanel hosts the live tier label
  ("Fidelity tier: Sedang") and 5 switches (Highlights/Shadows/Bloom/Terrain decoration/Particles).
  Switch state toggle not driven: the panel content is hidden until opened by an admin; no fps-per-switch
  table measured (no in-code fps instrumentation; needs designer phone). `LUNE-ONLY` for the toggle logic.

## Not checked / decisions

- Portrait rotation: not driven (viewport size cannot be changed via MCP); landscape structure seen,
  portrait layout is `LUNE-ONLY` (`phone_layout_spec`).
- Every app page individually: `App_phone` seen in play; the other 7 use the same `pageDef`/`registry`
  path, covered by `tests/specs/lazy_pages_spec.luau`.
- Raid cutscene camera hand-back / BREAKING NEWS bar / 20 s window: not run — no harness raid trigger;
  logic is `LUNE-ONLY` (`cutscene_sequencer_spec`, `hook_moment_spec`). Needs a real raid (~5:30) or a
  test hook (code change, out of scope).
- Save repair warning: not driven on a real damaged profile (would need a throwaway DataStore profile);
  `LUNE-ONLY` (`save_reconcile_spec`).
- Test-only GUI artifacts created during probing were destroyed; a play restart restored a clean
  session; `JuraganDesa.rbxl` was never saved. `lune run tests/run.luau`: 1666 passing.
