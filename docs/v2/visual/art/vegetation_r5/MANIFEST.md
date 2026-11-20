# vegetation_r5

Off-by-default LookDev candidate. No visual verdict is recorded here.

- Asset IDs: none new. The three placed model IDs (`pisang`, `bambu`, `mangga`) are read from
  `src/shared/ModelMapVegetationR4.luau`; provenance, licence and triangle counts are in
  `../models_r4/vegetation/upload_manifest.json`.
- **Designer build needed:** a real mango tree. No verified free CC0/CC BY mango model exists in the
  repo, so `mangga` keeps the R4 broadleaf stand-in reference. Brief and references:
  `../models_r4/vegetation/HANDOFF.md`.
- Kelapa is retained only as a disabled "other level" data group. Its R4 ID is reused, never placed
  at spawn (round-5 designer note, V-D4). No pine asset is recorded.
- Placement zones (paths, plots, tagged `Map.TAGS.PlotAnchor` parts, hub footprints and open spaces)
  and all margins live in `src/shared/ModelMapVegetationR5.luau`. The applier skips overlapping slots.
