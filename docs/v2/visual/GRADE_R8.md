# Colour-grade safe ranges (item 91) — `grade_r8_a/b/c`

Status: **LIVE**. Written 2026-11-21 for WORK_QUEUE section M item 91. The numbers here are the
contract the harness `GRADE_SAFE` check enforces; they are mirrored in `Shared.ModelMapGradeR8`.
No visual verdict is claimed. The designer picks a variant (or none).

## Scope

Three tropical colour grades — `grade_r8_a` warm golden, `grade_r8_b` fresh green,
`grade_r8_c` hazy humid. They are OFF by default and touch **only** these Lighting child effects:

| Effect | Properties tuned |
|---|---|
| `ColorCorrectionEffect` | `Saturation`, `Contrast`, `Brightness`, `TintColor` |
| `BloomEffect` | `Intensity`, `Threshold`, `Size` |
| `SunRaysEffect` | `Intensity`, `Spread` |
| `Atmosphere` | `Density`, `Haze`, `Color`, `Decay`, `Offset`, `Glare` |

Nothing else is written: no Sky, no Terrain Clouds, no `Lighting.ClockTime`, no Part, no asset ID.
**DepthOfFieldEffect count must be 0** at baseline and with any variant enabled; no such effect is
created or configured. `GRADE_NO_DOF` enforces it.

The shipping default (no candidate enabled) is the `sky_r6`/chosen-sky baseline, untouched:
`Atmosphere` Density 0.30, Haze 1.6, Color `{240,236,224}`, Decay `{150,190,220}`, Offset 0.65,
Glare 1.2; `SunRaysEffect` Intensity 0.18, Spread 0.35; `BloomEffect` Intensity 0.12,
Threshold 0.95, Size 18; `ColorCorrectionEffect` Saturation 0.08, Contrast 0.02, Brightness 0,
TintColor `{1,1,1}`. Every candidate saves each property it overwrites and restores it exactly on
disable; a reused instance keeps its identity, and only instances the applier created are destroyed.

## Documented safe ranges (inclusive)

Colour scale: `Atmosphere.Color` / `Atmosphere.Decay` are byte triples (0..255) consumed by
`Color3.fromRGB`; `ColorCorrectionEffect.TintColor` is a normalised triple (0..1) consumed by
`Color3.new`. Channel bounds apply per component.

| Effect | Property | Min | Max | Rationale |
|---|---|---|---|---|
| `ColorCorrectionEffect` | `Saturation` | 0 | 0.20 | Slight lift only (baseline 0.08); above 0.20 the village reads as a poster. |
| `ColorCorrectionEffect` | `Contrast` | -0.02 | 0.08 | Mild separation; never crush shadows. |
| `ColorCorrectionEffect` | `Brightness` | -0.05 | 0.05 | Exposure nudge only, never a re-light. |
| `ColorCorrectionEffect` | `TintColor.R/G/B` | 0.90 | 1.10 | Near-white; a stronger tint fights the chosen skybox. |
| `BloomEffect` | `Intensity` | 0 | 0.25 | Low glow (baseline 0.12); no white-out halo. |
| `BloomEffect` | `Threshold` | 0.85 | 1.0 | Only the brightest highlights bloom. |
| `BloomEffect` | `Size` | 10 | 24 | Baseline 18, soft spread; larger smears fine detail. |
| `SunRaysEffect` | `Intensity` | 0 | 0.30 | Soft rays (baseline 0.18), never a flare. |
| `SunRaysEffect` | `Spread` | 0.15 | 0.50 | Baseline 0.35; wider reads as fog, not rays. |
| `Atmosphere` | `Density` | 0.22 | 0.35 | Recorded tropical humid band (WORK_QUEUE.md §sky best practice: about 0.25-0.35). |
| `Atmosphere` | `Haze` | 1.0 | 2.4 | Humid haze (brief about 1-2), baseline 1.6; above 2.4 detail disappears. |
| `Atmosphere` | `Color.R/G/B` | 0 | 255 | Warm-white byte triple; require `R >= G >= B` so it stays warm. |
| `Atmosphere` | `Decay.R/G/B` | 0 | 255 | Light-blue byte triple; require `B >= G >= R`. |
| `Atmosphere` | `Offset` | 0.5 | 0.8 | Baseline 0.65; keeps the horizon soft without washing the sky. |
| `Atmosphere` | `Glare` | 0.8 | 1.5 | Baseline 1.2; a small headroom for humid glare. |

The qualitative brief is `Atmosphere` about 0.25-0.35 density, humid haze 1-2, warm-white Colour,
light-blue Decay, plus soft `SunRays`, low `Bloom` and a slight saturation lift. These numbers turn
that brief into checkable bounds; the baseline values sit inside every range.

## Variants

| ID | Label | Distinctive values |
|---|---|---|
| `grade_r8_a` | warm golden | Density 0.28, Haze 1.4, warm tint `{1.04,1.00,0.93}`, SunRays 0.24 |
| `grade_r8_b` | fresh green | Density 0.24, Haze 1.05, green tint `{0.95,1.06,0.96}`, Saturation 0.19 |
| `grade_r8_c` | hazy humid | Density 0.34, Haze 2.2, Bloom 0.22/0.86/22, SunRays 0.10/0.48 |

All three values are distinct and all sit inside the ranges above. `GRADE_SAFE` reads the **live**
effect properties after each enable and compares them here; a missing effect or range is a FAIL,
never a skip. `GRADE_RESTORE` compares every touched property and the Lighting descendant count
before enable and after disable. Both are SERVER-VM checks: effects created on the server replicate
to clients, while effects created in the Client VM are not readable by the harness.
