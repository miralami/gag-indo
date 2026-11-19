# models_r3 — source & regenerate

All assets here are **off-by-default LookDev candidates** for the four
families `buildings_r3`, `vegetation_r3`, `props_r3`, `npcs_r3`. Nothing in this
directory is wired into the shipped world. Main session owns the toggle, IDs,
registry and review docs. **No visual verdict has been made by any agent.**

## Contents

- `MANIFEST.md` — per-asset provenance, licence, triangle count, review slot,
  one review camera per family, and the unreachable-source HTTP log.
- `src/build_models.py` — stdlib-only deterministic generator for every
  `DESIGNER_BUILD` OBJ (no external libraries).
- `generated/<family>/*.obj` + `materials.mtl` — generated originals (16 OBJs).
- `raw/<family>/*.glb` — real CC0 downloads, byte-for-byte as served (4 GLBs).

## Download / provenance steps (how `raw/` was produced)

Python `requests` with a browser-ish `User-Agent`; page licence field checked
before download; no asset ID invented.

1. `GET https://poly.pizza/m/<id>` (UA header) → parse `Licence` from the page
   JSON blob (`CC0 1.0`) and `Creator.Username` (`Quaternius`).
2. Same page → extract `https://static.poly.pizza/<uuid>.glb` (the viewer GLB).
3. `GET` that URL, assert magic bytes `glTF`, write to
   `raw/<family>/<name>.ply.glb`. SHA-256 recorded below.
4. Triangle count parsed from the GLB JSON chunk: sum of
   `accessors[primitive.indices].count // 3` over `mode==4` primitives.

Downloaded IDs (page / direct):
- `DsrrAYmucG` / `21d44b5b-efef-4abd-96ad-fc59e4ad373b` — palm, 3208 tris
- `FUgtfvqgMx` / `7f76e9d4-49f0-4582-8da9-8141d9756058` — bamboo, 400 tris
- `7pn3R6hPvE` / `81f2f0cf-6f53-4b57-92ea-dba0928620f2` — farmer, 5476 tris
- `Btfn3G5Xv4` / `713f6535-f4f3-4367-a4c6-ced126ae0936` — swat, 7752 tris

Full page URLs, authors and licences are in `MANIFEST.md`.

## Regenerate the originals

```
python docs/v2/visual/art/models_r3/src/build_models.py
```

Deterministic: no randomness, closed-form vertices only; re-running produces
byte-identical OBJs. The script also self-verifies every emitted OBJ (triangle
faces, in-range vertex indices, budget, no spaces in filenames) and prints
`VERIFIED 16 OBJ files` on success.

## Verification performed this pass

- All 4 GLBs: HTTP 200, `glTF` magic, JSON chunk parsed, triangle counts above.
- All 16 OBJs: face indices reference valid vertices, every face is a triangle,
  filename space check passes, 76–306 tris each (all ≤ 2000 kit / ≤ 8000
  landmark budget).
- Determinism: two consecutive generator runs → identical SHA-256 for all 16.
- No spaces in any filename under this directory.

## Hand-off (main session)

- Convert GLB/OBJ → Roblox `Model`, strip every Script/LocalScript/ModuleScript
  on import, upload via Open Cloud, record **real** IDs in `ASSET_MANIFEST.md`.
- Add one LookDev candidate per family (`buildings_r3`, `vegetation_r3`,
  `props_r3`, `npcs_r3`), off by default, staged in the 60×60 corner.
- Leave verdict cells blank; capture the four cameras in `MANIFEST.md` and let
  the designer / vision observer grade them.
