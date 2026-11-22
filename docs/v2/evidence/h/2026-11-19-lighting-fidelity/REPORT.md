# Item 23 — Lighting × FidelityTier per hub (2026-11-19)

Status: **SEEN-IN-STUDIO**. Branch `track/c-world-look`, fresh Play Solo client VM,
`Development-Juragan-Desa` (placeId 132087524375529), Rojo `localhost:34872`. Place not
saved, not published, no `profile:Save()`. Studio returned to Edit at the end and all probe
instances were destroyed. Machine-readable matrix: `results.json`.

## What was checked

Forced each of the three tiers (`Rendah`, `Sedang`, `Tinggi`) at each of the six hubs
(`pasar`, `gelap`, `warung`, `ronda`, `polisi`, `pakrt` — `MapSpec.HUB_ORDER`) on the **live**
`FidelityRuntime` singleton, moving the character to each hub centre first. For every one of the
18 combinations recorded: the tier the runtime reports (`get()`), the player's `FidelityTier`
attribute, the applied lighting-related settings, the full Lighting descendant census
(class-name signature + count + `DepthOfFieldEffect` count), and the count of local
Point/Spot/Surface lights and ParticleEmitters within 100 studs of the hub. Then cycled tiers
`Rendah → Tinggi → Rendah → Sedang → Tinggi → Rendah` and cleared the override, checking that
the Lighting census returned to baseline with no effect stuck on.

## Harness note (why a probe LocalScript was used)

The Studio MCP `execute_luau` tool has its own ModuleScript `require` cache: `require(FidelityRuntime)`
from the tool returned an *unstarted* copy (`get() = "Sedang"` default, `setOverride` a no-op),
even though the real client had mounted audio (17 Sounds) and the player's `FidelityTier`
attribute was already `"Tinggi"` from the live singleton. To drive the singleton consumers
actually read, a temporary `LocalScript` was injected into `PlayerScripts` (same cache as
`Main.client`), which reported `isStarted = true` and `get/attr = Tinggi`. The probe and its
`ReplicatedStorage.Item23Probe` result holder were destroyed afterwards; no place file changed.

## Applied settings (correct in all six hubs)

The runtime reported the forced tier and mirrored it to the attribute in all 18 rows, and the
settings advanced exactly as `FidelityTier.SETTINGS` defines:

| tier | localLights | smallPartShadows | cameraDoF | ambientLife |
| --- | --- | --- | --- | --- |
| Rendah | none | off | false | minimal |
| Sedang | key | near | false | half |
| Tinggi | all | on | true | full |

## Lighting instance census and stuck-effect check

The Lighting census was **identical in all 18 combinations** and after every step of the tier
stress cycle:

`Atmosphere, BloomEffect, ColorCorrectionEffect, ColorGradingEffect, Sky, SunRaysEffect`
(count 6, `DepthOfFieldEffect` count **0**).

Hub-local light/effect counts were also identical across the three tiers at each hub:
`1/0/0/0` at pasar, gelap, warung and pakrt; `0/0/0/0` at ronda and polisi (Point/Spot/Surface/
ParticleEmitter). After `Rendah → Tinggi → Rendah → Sedang → Tinggi → Rendah` and clearing the
override, the final census equalled the baseline (6 effects, dof 0). `all_matrix_rows_match_baseline`,
`final_matches_baseline` and overall `pass` are all `true`. **No tier switch created or destroyed any
Lighting effect, so none could be left stuck on.**

Console: no game-code errors (only two Assistant-plugin version-change notices and one transient
`AssistantCommand` error from an earlier malformed probe of this run, not from game code).

## Finding — gap / designer decision (not a code defect)

The four lighting-related tier settings are declared in `FidelityTier.SETTINGS`, returned by
`FidelityRuntime.settings()`, and mirrored to the player attribute — but **no consumer applies
them to Lighting or to local lights/effects**. `src/client/World/Sky.luau` alone owns the Lighting
post effects, and it is driven by season/weather (`Musim`/`Cuaca`), not by tier. In particular
`cameraDoF = true` on `Tinggi` created no `DepthOfFieldEffect` (dof 0 in every row), and
`localLights = "all"` did not change any hub-local light count. The stuck-effect check passes
precisely because no tier switch creates an effect at all. Wiring tier → lighting needs a designer
look decision and is consistent with VISUAL_MASTER_PLAN V0.4 (visual wiring) still `BLOCKED` on
designer approval; recorded under WORK_QUEUE "Decisions for designer". No production lighting code
was changed for this verification-only item.

## Validation

- `lune run tests/run.luau` — **All 1908 tests passed** (unchanged; no new spec —
  `fidelity_tier_spec` already pins all four lighting keys for all three tiers).
- `selene src` — 0 errors / 0 warnings / 0 parse errors.
