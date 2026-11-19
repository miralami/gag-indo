# UI fit at 749×388 — Track H, 2026-11-19

WORK_QUEUE item 19: probe every screen and app page in Studio and confirm nothing is off-screen or
overlapping the safe-area insets; fix by layout, not by shrinking text below the minimum. **Status:
`SEEN-IN-STUDIO`** (this file + `results.json`). One genuine layout defect was found and fixed
(AdminPanel bottom rows clipped on short landscape screens); no text size was reduced.

## Method

- Play Solo, **Client** datamodel, device simulator `StudioDeviceSimulatorService` with
  `SetDeviceAsync("average_windows")` and `SetResolutionAsync(750, 388)`. The Windows device subtracts
  1 px, giving a **real GUI viewport of exactly 749×388** (`camera.ViewportSize = 749×388`,
  `GuiService:GetGuiInset() = (0, 58)`).
- Safe-area reference measured live with a `ScreenGui` whose `ScreenInsets =
  Enum.ScreenInsets.DeviceSafeInsets` containing a full-scale `Frame`:
  **`safe = { x = 0, y = -58, w = 749, h = 388 }`** (no physical notch on the emulated device, so
  safe == full GUI frame; the 58 px strip above `y = 0` is the top bar inset).
- For every `GuiObject` in every enabled game `ScreenGui` (`Hud`, `Phone`, `Minigame`,
  `RaidOverlay`, `AdminPanel`, `Leaderboard`, `Toasts`), the probe walked the ancestor `.Visible`
  chain (**effectively visible** only), read live `AbsolutePosition` / `AbsoluteSize`, and flagged any
  rect outside `safe ± 2 px`. Descendants of a `ScrollingFrame` were excluded — they are legitimately
  clipped by the scroll canvas. System GUIs (`Chat`, `BubbleChat`, `TouchGui`, `Freecam`) were excluded.
- The phone was cycled through all 8 home tiles one click at a time; event-driven overlays whose real
  trigger needs live gameplay (minigame, raid, admin, panel states) were measured by forcing their
  built scrim/panel `.Visible = true` in the Client VM — the hierarchy and all layout properties are
  the real ones the game constructs; only visibility was forced so the rects could be read.

## Result — every screen fits (0 violations) except AdminPanel

| Screen / app page | effectively-visible elements | off-screen / inset violations |
|---|---:|---:|
| HUD + startup (phone closed) | 50 | 0 |
| Phone home (`PageHome`) | 105 | 0 |
| `App_phone` → `PagePhone` | 84 | 0 |
| `App_kebun` → `PageKebun` | 139 | 0 |
| `App_pinjol` → `PagePinjol` | 74 | 0 |
| `App_tugas` → `PageTugas` | 90 | 0 |
| `App_cheat` → `PageCheat` | 83 | 0 |
| `App_dekor` → `PageDekor` | 82 | 0 |
| `App_shop` → `Hud.Shop` panel | 131 | 0 |
| `App_board` → `Leaderboard.Panel` | 60 | 0 |
| `Toasts.Holder` | visible @ 142,10 (464×120) | 0 |
| `Minigame` card (460×240 @ 144,45) | 8 | 0 |
| `RaidOverlay` card (520×240 @ 114,35) + banner/skip/lower-third/jail | 24 | 0 |
| `AdminPanel` — **before fix** | 50 | **bottom rows clipped (~17–25 px past y = 330)** |
| `AdminPanel` — after fix | 50 | 0 |

Every phone page keeps its card within the safe frame; the HUD `Stats` chips sit at `y ≈ -10` in the
top-bar strip by design (the HUD is inset-aware), not a defect. The minigame and raid cards are
centred and size-constrained; all their controls fall inside `safe`.

## Defect found and fixed — AdminPanel bottom rows clipped

`src/client/UI/Admin.luau` `build()` sizes the panel to a fixed 340×690 and scales it to short screens
with a `UIScale`. The old `refit()` computed the scale from `camera.ViewportSize.Y` (388 here) — the
**full** viewport height — but the panel lives inside `ScreenGui` insets (`CoreUISafeInsets`,
`IgnoreGuiInset = false`), so the usable height is only `388 - 58 = 330`. At 749×388 the scale was
`(388 - 24)/690 = 0.5275`, giving a 364 px-tall panel centred at `y = 165` → `y = -17 … 347`; the
bottom `TextButton` reached `y ≈ 355`, **17–25 px past the 330 viewport bottom**, clipping the last
admin row.

Layout-only fix (no `TextSize` touched): subtract the top GUI inset so the panel fits the usable
height —

```lua
local inset = game:GetService("GuiService"):GetGuiInset()
fit.Scale = math.clamp((h - inset.Y - 24) / 690, 0.4, 1)
```

Studio verification (Client VM, 749×388, fix applied to the live panel): scale `0.4435`, panel
`151×306 @ 299,12`, lowest visible element bottom `324 < 330`, **0 violations**. The change keeps the
existing `UIScale` fit mechanism and the 0.4 floor; it only corrects which height is fitted. Rojo
(`localhost:34872`) is serving the updated source; the live Studio copy was stale because the
Assistant plugin version-change warning dropped the in-place sync, so the corrected scale was applied
in the Client VM to measure the resulting rects before returning to Edit mode.

## Validation

- `lune run tests/run.luau` — passing (count on the tracker).
- `selene src` — 0 errors / 0 warnings.
- No text size was reduced; no asset/product/price/UserId invented; place not saved/published;
  `profile:Save()` not called. Studio returned to Edit mode.

`results.json` holds the raw per-screen safe rect, element counts and rect readings.
