# World Look & Golden Hour Evidence

**Date:** 2026-11-14  
**Branch:** `track/c-world-look`  
**Status:** `SEEN-IN-STUDIO`  

## Changes

1. **Native Terrain Grass (`Terrain.Decoration = true`)**
   - Enabled native voxel grass decoration on `workspace.Terrain`.
   - Road corridors, building footprints, and sawah terrace perimeters painted with `Enum.Material.Ground` to ensure zero grass blades poke through or submerge roads, building plinths, or interactables.

2. **Warm Golden-Hour Senja Lighting & Skybox**
   - Sourced clean Creator Store sunset skybox textures (`156042307`, `155440478`, `156042328`, `156042348`, `156042292`, `156042384`) by Roblox.
   - Tweaked `Atmosphere` and `Lighting` in `src/shared/Config/Seasons.luau` and `src/client/World/Sky.luau` with warm senja golden hues, haze, and glares.

3. **Realistic Pine Forest Perimeter Backdrop**
   - Sourced clean Creator Store free asset `5392132809` ("Realistic Pine Tree" by GabeQZ; meshes `739614116`, `739619496`, `2312874610`).
   - Sourced and populated 86 dense realistic pine trees in `workspace.BackgroundForest` along the outer perimeter (radius ~135–170 studs).
   - Strictly reserved West sunset corridor (azimuth 130° to 230°) free of tall trees, ensuring low golden sun rays and horizon glow directly illuminate the village.
   - Registered in `docs/v2/visual/art/ASSET_MANIFEST.md`.

4. **Testing & Stability**
   - Guarded `game:GetService("ServerStorage")` in `src/server/World/Greybox.luau` via `pcall` and added mock `ServerStorage` in `tests/lib/Env.luau`.
   - All 606 unit tests pass cleanly (`lune run tests/run.luau`).
