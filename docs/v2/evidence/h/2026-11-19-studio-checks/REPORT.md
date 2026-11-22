# Studio checks of LUNE-ONLY items — Track H, 2026-11-19

Build: `track/c-world-look` at `a53e92b` (WORK_QUEUE items 1–3 shipped), Rojo serving on
`localhost:34872`. Connected Studio instance `447c176b-1d7b-4b9c-a794-45912fea4b63`,
cloud dev place `Development-Juragan-Desa` (placeId `132087524375529`, universeId `10776530981`).
Machine-readable readings in `results.json`.

**The place was never saved and never published. `profile:Save()` was never called.** Every check
required the real Rojo-synced ModuleScripts inside the Roblox engine through Studio MCP
`execute_luau` — not Lune. Pure/config modules were driven in Edit mode; CabaiEvent and the
headroom raycast were driven in a Play Solo **Server** VM so the real server-created `Remotes`
folder and the built 1706-part `World` existed. Temporary in-memory overrides were restored, a
fabricated Edit-mode `Remotes` folder was destroyed, and Play was stopped (Studio returned to Edit).

All eight sub-checks of WORK_QUEUE item 4 are `SEEN-IN-STUDIO`. No production defect was found, so
no code fix and no new harness hook was needed: every module has a public force/read path reachable
from `execute_luau` (FidelityTier controller `setOverride`, LiveConfig `update`, CutsceneHooks
`emitDebtCollector`, MapSpec data + built geometry). The `RaidTrigger` gated-hook pattern was not
invoked because no check required a remote that the driver could not call directly.

## 1. FidelityTier — force each tier, read applied settings

Forced with `FidelityTier.new({clock=fn})` then `controller.setOverride(tier)` (dot call: the
controller methods capture `self` lexically); read `get()`/`getOverride()`/`settings()`. All three
forced and reported their own settings:

| Tier | particleRate | lifeScale | swayRange | localLights | smallShadows | rain | DoF | ambient |
|---|---|---|---|---|---|---|---|---|
| Rendah | 0.4 | 0.6 | 25 | none | off | sheet | false | minimal |
| Sedang | 0.7 | 1.0 | 50 | key | near | splashes | false | half |
| Tinggi | 1.0 | 1.0 | 80 | all | on | full | true | full |

## 2. TierScale particle and wind consumers

Per-tier settings fed into the real `TierScale` functions: bursts `emitCount(20)` = 8/14/20,
rates `rate(10)` = 4/7/10, particle life `lifetime(0.35,0.65)` = 0.21–0.39 / 0.35–0.65 /
0.35–0.65, sway cull range 25/50/80 studs with weight 1 inside, 0.5 at 80% range, 0 beyond.
`ActionFeel` uses `TierScale.lifetime`/`emitCount` for its cash/sultan bursts; `Wind.step` uses
`TierScale.swayWeight` for foliage within the tier range. `Wind.offsetFor(1.23, 2.5)` returned
−2.767° rotation and −0.083 stud offset, inside the ±3°/±0.25-stud limits.

## 3. Crop stages bibit / tumbuh / siap

`Visuals.cropStages` read from the engine: bibit stem 0.6 / crown 0.7, tumbuh 1.6 / 1.5,
siap 3.4 / 2.4. The `FarmService` selection expression (`ready → siap`;
`elapsed < max(1, GrowSeconds/3) → bibit`; else `tumbuh`) with real `padi.growSeconds = 60`
selected bibit at 0 s, tumbuh at 30 s and 60 s, siap when ready.

## 4. Cabai event — start, banner, countdown (Server VM)

- Timed (`auto`, first delay forced to 0): `CabaiEvent.start()` → active, cabai ×3, other crop ×1,
  `ReplicatedStorage.CabaiEvent` banner `true`, `CabaiEventEndsAt − now = 300 s` (the configured
  `cabaiEventDuration`).
- Forced `on` via `LiveConfig.update`: active, ×3, banner `true`, `EndsAt = 0` — an admin-forced
  event intentionally has no countdown.
- Forced `off`: inactive, ×1, banner `false`, `EndsAt = 0`.

State restored to `auto` in memory after the read; no DataStore write on restore.

## 5. Debt-collector cutscene hooks

Subscribed with `CutsceneHooks.onDebtCollector`, emitted through the real `emitDebtCollector`:
received exactly `{kind=debt_collector, state=summoned, waiting=true}` then
`{state=dismissed, waiting=false}` with the test player. After the unsubscribe function ran, a
third emit reached no listener. `_reset()` left both listener tables empty.

## 6. NPC archetype fields on the live NPCs

`NpcArchetypes.order` = pakrt, tengkulak, polisi. Each entry carries id, displayName, silhouette,
exaggeratedFeature, accessory, outfit and voice (full values in `results.json`); these are the
fields `NpcFactory.build` reads to construct the live NPC models, all present and non-empty.

## 7. 9.5-stud headroom raycast in all six hubs (Server VM, built World)

Required minimum = `MapSpec.GROUND_Y (0.5) + MapSpec.HEADROOM (9.5) = 10.0`. For each hub, the
lowest point of every `Roof`/`RoofRidge`/`Awning`/`Spanduk`/`KunyitTrim`/`MalamTrim` part (tilt
accounted for via CFrame UpVector) and a whitelisted vertical raycast at the hub centre:

| Hub | model | parts | lowest part Y | clears ≥10 | raycast clears |
|---|---|---|---|---|---|
| pasar | Pasar | 5 | 10.0 | yes | yes |
| gelap | TengkulakGelap | 3 | 10.0 | yes | yes |
| warung | Warung | 4 | 10.0 | yes | yes |
| ronda | PosRonda | 6 | 13.0 | yes | yes |
| polisi | PosPolisi | 5 | 10.0 | yes | yes |
| pakrt | RumahPakRT | 8 | 11.26 | yes | yes |

Zero offenders in all six hubs.

## 8. Three season presets

`WorldConstants.SEASON_PRESETS` = hujan, kemarau, pancaroba; golden-hour window 16.0–17.0.
`Seasons.list`/`Seasons.sky` for each: hujan growth 1.1, clock 16.2, brightness 1.8, fogEnd 1400;
kemarau growth 0.9, clock 16.9, brightness 3.0, fogEnd 3000; pancaroba growth 1.0,
clock 17.0 (the golden-hour max), brightness 2.5, fogEnd 3500. All three read correctly in-engine.

## Validation

Full suite `lune run tests/run.luau`: **1719 passing**. `selene src`: **0 errors, 4 pre-existing
warnings** (cleared by WORK_QUEUE item 8, not this item).
