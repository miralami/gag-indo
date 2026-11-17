# Studio pass — perf switches + fps sampler (2026-11-17)

Build: `track/c-world-look` @ 53cc181 + FpsSampler. Viewport 749x388, Play Solo, Studio unfocused.

## What shipped (code)

- `src/client/Feel/FpsSampler.luau` — pure rolling frame-time→fps helper (bad frames ignored) plus a
  Studio-only `start()` that publishes a `ClientFps` player attribute from RenderStepped every 0.5 s.
  `start()` is a no-op when `RunService:IsStudio()` is false, so nothing runs in a published place.
- Wired into `src/client/Main.client.luau` (one line, Studio-only).
- `tests/specs/fps_sampler_spec.luau` — 6 specs (nil-until-samples, bad frames, rolling window,
  reset, published-place no-op, Studio connect/disconnect). `lune run tests/run.luau`: 1682 passing.

## What is proven in Studio

- `ClientFps` sampler: `SEEN-IN-STUDIO`. Live attribute published `ClientFps=60` within 2.5 s of play.
- Perf switches toggle + restore: `SEEN-IN-STUDIO`. Driving the same `PerfSwitches.get()` module the
  admin buttons call: shadows `Lighting.GlobalShadows` true→false→true, decoration
  `Terrain.Decoration` true→false→true, all five switch states restored to true after the pass.
  Highlights/bloom/particles toggle their instance `Enabled` (covered by `perf_switches_spec.luau`).
- fps per switch: `SEEN-IN-STUDIO` (readings, no usable delta). Sampled ~6 values over ~1.5 s per state:
  baseline 59.9, highlights_off 59.9, shadows_off 59.9, bloom_off 60, decoration_off 60,
  particles_off 60, restored 59.9. Studio-unfocused/empty scene is capped at 60; no switch produced a
  measurable difference here. Output clean (only external BUG-003 line).

## Not checked / decisions

- The real fps-per-switch cost table must be read on the designer's mid-range phone (Xiaomi 12 Lite);
  the emulator/Studio unfocused numbers are not usable. This stays a designer task.
- Admin-panel button clicks were not driven; the module path the buttons call was exercised directly
  (the button → `switches.toggle(name)` wiring is unchanged and in `Admin.luau`).
- `JuraganDesa.rbxl` never saved, never published. Play mode stopped at end.
