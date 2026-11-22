# Round 2 item 11 — budget check (2026-11-19)

Status **SEEN-IN-STUDIO**. Branch `track/c-world-look`, place `Development-Juragan-Desa`
(placeId 132087524375529), Rojo `localhost:34872`, Play Solo Client VM. Place not saved, not
published, no `profile:Save()`. Returned to Edit; all probe instances destroyed. Machine-readable
matrix: `results.json`.

## Method

The live `FidelityRuntime` singleton was forced to `Rendah`, `Sedang` and `Tinggi` from a probe
`LocalScript` injected into `PlayerScripts` (the same require cache as `Main.client`);
`setOverride(tier)` was confirmed by `FidelityRuntime.get()` for all 18 hub × tier combinations,
then `setOverride(nil)` restored auto.

`LookDev.enable()` is single-active, so "all candidates on" cannot be toggled literally. It was
measured as **baseline + the sum of the eight per-candidate deltas**: each applier owns a disjoint
container (`LookDevCropShowcase`, `LookDevHubPropDetails`, NPC child parts, material swaps, UI and
Sounds), so the deltas are additive.

For each hub (`MapSpec.HUB_ORDER`) the census counts Workspace descendants within 100 studs of the
hub centre: **instances** (BasePart or Model), **parts** (BasePart) and **estimated triangles** from
the primitive `Shape` (Block/Wedge 12, Cylinder 32, Ball/Sphere 320). Roblox does not expose a
primitive triangle count; the same estimate table is applied to baseline and all-on, and it was
cross-checked against the pure-data recipes. A camera-frustum cross-check was attempted and
discarded because the probe camera census under-reported (zero parts); the 100-stud census is the
reported metric.

## Results (identical at all three tiers)

| Hub | Baseline parts / triangles / instances | All-on parts / triangles / instances |
|---|---|---|
| pasar | 335 / 18,388 / 369 | 690 / 46,980 / 760 |
| gelap | 335 / 14,884 / 384 | 690 / 43,476 / 775 |
| warung | 230 / 13,232 / 278 | 580 / 41,536 / 664 |
| ronda | 347 / 19,780 / 369 | 712 / 49,208 / 770 |
| polisi | 287 / 17,724 / 314 | 641 / 46,036 / 704 |
| pakrt | 266 / 17,364 / 313 | 621 / 45,648 / 704 |

Counts do not vary by tier: none of the eight candidates branches on `FidelityTier`, and tier
changes affect particles and lighting rather than these static parts.

Per-candidate deltas (pasar, representative): `plaza_lighting`, `police_walkin`, `icons`,
`textures`, `sounds` add **0** geometry; `npcs` +5 parts / +60 triangles; `hubprops` +11 / +1,116;
`crops` +339 / +27,416 (Ball 71, Block 42, Cylinder 74, Wedge 152). The live shape histogram
matches the Lune recipe computation exactly: crops 339 parts / 27,416 triangles / 36 models / 72
GUI instances; hubprops 43 parts / 3,648 triangles across four hubs; NPC details 19 parts / 656
triangles in total.

## Verdict

- **Triangles: PASS.** Worst all-on 49,208 triangles — 9.8% of the ~500k Sedang budget
  (`VISUAL_MASTER_PLAN.md` §6).
- **Draw-call proxy: OVER only in the all-on stress case.** 580–712 parts against the ~500
  guideline. Baseline alone is 230–347 parts, comfortably within it. The whole excess is the
  339-part crops showcase, which is a Studio-only review grid floating near the player, not
  shipping art.
- **Rendah: triangle budget passes; draw-call proxy exceeds only because of that Studio-only
  showcase.** Shipping state passes everywhere because every candidate is off by default behind
  the Studio-only gate.

## Decision for the designer (parked, not applied)

Cap the crops showcase by tier: show only the mature `siap` stage on Rendah/Sedang (12 models,
144 parts, 13,088 triangles) and keep all 36 models on Tinggi for full review. That cuts the worst
all-on proxy from 712 to about 517 parts (495 at the pasar/spawn view) while preserving complete
art review on flagship. Implementation is a follow-up touching
`CropModelCandidates.stagesByTier`, `LookDevCrops` and a locking spec; no agent changed delivered
item-7 art during this check.
