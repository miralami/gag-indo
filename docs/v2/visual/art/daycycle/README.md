# LookDev day cycle — round 3 item 25 (code half)

`day_cycle` is an **off-by-default, Studio-only LookDev candidate** for the D19 / V-D2 time-of-day
grade. Nothing changes in the shipping game until it is explicitly enabled.

## What it does

- `src/shared/World/DayCycleLive.luau` is the pure plan: 20–40 s phase tweens, the five sound-bed
  slot names (`ayam`, `bedug`, `kentongan`, `jangkrik`, `adzan`), the adzan default (ON, LOW volume,
  key `setting_adzan`), six non-shadow lamp lights at most (Rendah ceiling), and a saved review
  camera. It reuses `src/shared/World/DayCycle.luau` (`presetFor`, `phaseInfo`,
  `ADZAN_SETTING_KEY`) without mutating it.
- `src/client/World/LookDevDayCycle.luau` drives the same Lighting / Atmosphere / ColorCorrection /
  Bloom / SunRays / Clouds objects `client/World/Sky.luau` uses, with
  `DayCycleLive.preset(elapsed, Seasons.skyFor(...), FidelityRuntime.get())`. It re-applies after
  a Musim/Cuaca change so the season tween cannot overwrite the grade. On disable it cancels
  tweens, restores every saved property and destroys every Instance it created.
- Night lamps are `PointLight`s created only while the candidate is enabled, capped at the pure
  plan's Rendah budget (max 6 lights, 0 shadow lights), with brightness scaled by the phase's
  `lampLevel` (0 during day). No shipping light or value is edited.
- `src/shared/Settings/AdzanSetting.luau` reads/writes the saved player setting on a
  `profile.Data` table. Missing or damaged values fall back to ON.
- The five beds are registered in `src/shared/Config/Audio.luau` with `id = 0`, the registry's
  silent sentinel. They are **silent until licensed IDs are supplied**; no asset ID was invented.

## Toggle

```luau
require(game.ReplicatedStorage.Shared.LookDev):enable("day_cycle")
require(game.ReplicatedStorage.Shared.LookDev):disable() -- restores the original sky and lamps
```

Studio-only gate, in-memory only, one candidate active at a time. The central registry and client
bootstrap lines are applied by the parent session (see the handoff in the final report); the
adapter is inert until they land.

## Saved review position — absolute coordinates, not a visual verdict

Absolute world coordinates. Spawn is `{ 0, 0.5, 28 }` facing `-Z` (`MapSpec.SPAWN`); this camera
sits behind spawn and looks north across the plaza, matching the absolute-camera convention used
by `docs/v2/visual/art/corner/README.md`.

| Field | Value |
|---|---|
| `camera_position` | `{ 0, 12, 52 }` |
| `look_at_position` | `{ 0, 3, -20 }` |

No screenshot, visual grade or designer approval is recorded here. The review pass owns the
yes/no.
