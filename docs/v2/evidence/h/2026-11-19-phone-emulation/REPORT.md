# Track H — phone emulation proof — 2026-11-19

WORK_QUEUE round 2 item 1. Decision: **proven active, no downgrade of the G3/G5 phone
claims**. Status `SEEN-IN-STUDIO` (this file + `results.json`). The point of the item was to
settle whether `StudioDeviceSimulatorService` really changes the render/target, or whether the
round-1 phone-size claims had to be stepped down to `UNVERIFIED`. They do not: a controlled
desktop-vs-phone-vs-low-end-phone comparison shows viewport, aspect and touch capability all
change with the selected device.

## Method

- Branch `track/c-world-look`, placeId 132087524375529, Rojo `localhost:34872`, Studio
  `447c176b-1d7b-4b9c-a794-45912fea4b63`. No source file edited, place not saved, not published.
- `StudioDeviceSimulatorService` methods read live in Edit and PlayClient via `execute_luau`.
  Device was set in the **Edit datamodel before `start_stop_play`** — setting it mid-Play is
  unreliable (round 1 saw a 1x1 viewport). Scaling mode `FitToWindow` throughout.
- Each state was read after `task.wait` with `pcall`-guarded getters:
  `Camera.ViewportSize`, `UserInputService.TouchEnabled`, `GuiService:GetGuiInset()`,
  `StudioDeviceSimulatorService:GetDeviceAsync()` / `GetOrientationAsync()` / `GetResolutionAsync()`.

## Measurements

| # | Device (id) | Native res | Play viewport | Aspect | TouchEnabled | Inset | Orientation |
|---|---|---|---|---|---|---|---|
| 1 | Average Windows (`average_windows`) | 1366x768 | 1365x768 | 1.77 | false | 0,58 | LandscapeRight |
| 2 | iPhone 14 (`iphone_14`) | 844x390 | 749x389 | 1.92 | true | 0,58 | LandscapeRight |
| 3 | iPhone 14 portrait (set during Play) | 844x390 | 388x761 | 0.51 | true | 0,58 | Portrait |
| 4 | Samsung Galaxy A06 (`samsung_galaxy_a06`) | 800x360 | 705x338 | 2.08 | true | 0,58 | LandscapeRight |

`Game.StarterGui.ScreenOrientation` is `Enum.ScreenOrientation.LandscapeSensor`, so this title is
landscape-only by design. That is why a portrait setting applied *before* Play reverts to
`LandscapeRight` on entering Play; portrait can still be forced during Play (row 3), which is
enough to prove the orientation API is live. There is no portrait requirement on Gate 1.

739x389 / 705x338 are the `FitToWindow` render of the device aspect into the Studio pane, not
the device's native pixel count — the same scaling every round-1 phone claim used. The decisive
proof is not the absolute pixel size but that switching devices flips
`TouchEnabled` false -> true and reshapes the viewport; emulation is active.

## Orientation API surface (probed live)

- `GetOrientationAsync()` -> `Enum.ScreenOrientation` EnumItem.
- `SetOrientationAsync(Enum.ScreenOrientation.Portrait)` succeeds on a mobile device only
  (errors with "orientation can only be set on mobile (phone or tablet) devices" on desktop).
- `SetDeviceAsync`, `SetResolutionAsync` exist; `SetDeviceOrientationAsync` and
  `RotateDeviceAsync` do not. Values must be real `Enum.ScreenOrientation` items, not strings.

## Screenshot

`screen_capture` (`PhoneEmulation_A06_Landscape`) was accepted while the Galaxy A06 was active in
Play. This session's model has no image-input support, so the capture could not be visually
analysed here; it is not claimed as visual evidence. The numeric readbacks above are the proof.

## Conclusion

- Phone emulation is real and active in this Studio. No G3/G5 phone claim is downgraded; their
  `SEEN-IN-STUDIO` status and the GATE1 wording stand (`h/2026-11-19-g3-phone/`,
  `h/2026-11-19-g5-phone/`).
- No change to `MASTER_PLAN.md` or `GATE1.md` status columns was required. The item is closed.
- Real-device fps (G6), five-player (G7), touch (Q7) and published-place (Q6) remain designer /
  hardware gates — emulation does not replace them.
