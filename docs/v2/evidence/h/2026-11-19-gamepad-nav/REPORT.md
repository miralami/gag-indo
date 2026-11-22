# Gamepad and keyboard navigation — Track H, 2026-11-19

WORK_QUEUE item 21: every screen closable with B/Escape, selection never stuck in a hidden frame,
default selection on open. Specs where the logic is pure, plus a Studio pass with
`GuiService.SelectedObject`.

**Status:** `SEEN-IN-STUDIO` for the selection behaviour (this file + `results.json`). The
**B/Escape key-press drive is `BLOCKED — Roblox Studio MCP input cannot produce a ContextActionService
Begin event`** (detail below); the binding, cancel policy and registration are still proven by pure +
static specs and are shipped.

## What shipped

- `src/client/UI/Navigation.luau` — pure LIFO/stack policy with **no Roblox globals**. Permanent
  `_byId` registry is kept separate from the active `_stack`; toggling `Visible` moves a screen
  between them, so a screen can be closed and reopened with its default restored.
  `cancel()` closes only the topmost dismissable screen; `rescue(current, isVisible)` keeps a
  still-visible selection, else falls back to the topmost open screen's visible default, else clears.
- `src/client/UI/NavBridge.luau` — the only module that touches Roblox services. Binds
  `Enum.KeyCode.Escape` + `Enum.KeyCode.ButtonB` at `ContextActionPriority.High` via
  `BindActionAtPriority`, gating on `UserInputState.Begin`; Sinks only when a screen actually closes,
  otherwise Passes so Escape can still reach the core menu. Writes/clears `GuiService.SelectedObject`,
  watches its `SelectedObject` changes, and reacts to each registered root's `Visible` signal.
- Registration in `Main.client` (start after all mounts) and in Phone, Hud Shop, Leaderboard, Admin
  (register in `build()`, unregister in `destroy()`), Minigame and RaidOverlay.

### Designer decision (recorded in WORK_QUEUE "Decisions for designer")

RaidOverlay is registered with `closable = false`: it is a forced timed choice with its own Skip
rule (Skip is only available once the cutscene is skippable), so B/Escape must never dismiss it. It
still gets a phase-driven default (Skip while incoming, Fine/Amplop while choosing) with explicit
`NavBridge.rescue()` calls on phase changes so selection never sits on a hidden button.

## Specs (LUNE-ONLY)

- `tests/specs/navigation_spec.luau` — 17 cases: LIFO open/close, re-register, unregister,
  close→reopen regression, cancel skips forced/no-callback screens, nothing-open cancel returns
  false, function (phase-driven) defaults, and all four rescue outcomes (keep / default / lower
  fallback / clear).
- `tests/specs/nav_wiring_spec.luau` — 7 cases pinning the Studio-side hookups that Lune cannot
  run: B+Escape bound at High priority, Begin gate + Sink/Pass, `GuiService.SelectedObject`
  writes + change watch, one registration per dismissable screen, admin unregister, raid
  non-dismissable with dynamic default, bootstrap start after mounts, and pure policy has no
  Roblox globals.

`lune run tests/run.luau` — **All 1883 tests passed** (was 1859; +17 pure + 7 wiring).
`selene src` — 0 errors / 0 warnings / 0 parse errors. One mutation was checked: reverting the
close→reopen registry fix made the new regression spec fail.

## Studio pass (`SEEN-IN-STUDIO`)

Play Solo, **Client** datamodel, default desktop viewport. All game `ScreenGui`s were already mounted
(Rojo had synced `Navigation.luau`/`NavBridge.luau` and the edited screens). Screen roots' `.Visible`
was toggled directly — the real game instances and the real `NavBridge` `Visible` connections run;
only the trigger was forced, because B/Escape cannot be driven (below). `GuiService.SelectedObject`
was read live from the Client VM after each step (50 ms settle).

| Step | Observed | Pass |
|---|---|---|
| Baseline, all screens closed | selection `nil` | ✅ |
| Open Leaderboard.Panel | selection = `Leaderboard.Panel.Close` | ✅ |
| Open Hud.Shop | selection = `Hud.Shop.Close` | ✅ |
| Open Minigame.Scrim | selection = `Scrim.Card.Cancel` | ✅ |
| Open Shop while Board open (newest on top) | selection = `Hud.Shop.Close` | ✅ |
| Close top Shop | selection falls back to `Leaderboard.Panel.Close` | ✅ |
| Close all screens | selection `nil` | ✅ |
| Reopen Board after close | selection restored to `Board.Close` | ✅ |

The reopen case is a real defect found by this pass and fixed before ticking: the first policy
removed a screen from the registry on close, so a reopened screen had no default. The registry/stack
split above fixes it and is locked by a spec.

A `UserInputService.InputBegan` probe confirmed synthetic `A` and `Escape` keys do reach the engine,
but a `ContextActionService:BindActionAtPriority` probe with the same keys received only
`UserInputState.Cancel` events — never `Begin`. The MCP `user_keyboard_input` tool therefore cannot
exercise a CAS `Begin` handler. `VirtualInputManager:SendKeyEvent` is unavailable from the MCP thread
("lacking capability RobloxScript"). No in-place Studio test hook was added to game code.

## Validation / safety

- Place returned to **Edit** mode after the pass; **not saved, not published**.
- `profile:Save()` not called. No asset/product/price/UserId invented.
- `results.json` holds the raw per-step `GuiService.SelectedObject` readings.

## Open (BLOCKED)

- **B/Escape key-press → actual close in Studio**: `BLOCKED — Roblox Studio MCP input cannot
  produce a ContextActionService Begin event (only UIS.InputBegan and CAS Cancel are observable);
  the CAS binding itself is pinned by nav_wiring_spec, and the cancel policy by navigation_spec`.
  Needs a real keyboard/gamepad in a manual Studio session to confirm the final input→Sink link.
