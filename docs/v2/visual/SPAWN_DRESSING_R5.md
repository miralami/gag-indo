# Spawn dressing — `spawn_r5` (WORK_QUEUE item 41)

Status: **LUNE-ONLY**. Off by default. Visual verdict: **blank** — this pass composes already
approved / temporary assets, it does not grade them. No Studio shot is claimed here; the main
session takes the review shots and wires the candidate into the registry / review docs.

## 1. What is placed

`src/shared/SpawnDressingMapR5.luau` is pure data. It reads every position and numeric ID at
require time from `ModelMapBuildingsR4`, `ModelMapPropsR5`, `ModelMapVegetationR5` and
`ModelMapNpcsR5`: no ID literal, no invented position, no engine API.

| Source | Entries | Placement rule |
|---|---|---|
| `buildings_r4` (temporary) | gudang (cluster B), warung (cluster C) | both Rendah, both `landmark = true`; rumah/kandang left out |
| `props_r5` | jemuran (B, Rendah, source scale 1), 4 karung sacks on the gudang apron (B, Rendah, source `dx/dz/dy`), gerobak + lapak (Sedang), sumur + pagar_bambu + alat_tani (Tinggi) | x/z/ry/scale copied verbatim; sacks use the source stack offsets as `yOffset` |
| `vegetation_r5` | 3 pisang from cluster A (Rendah) + 1 C/A-edge pisang (Sedang); 2 dense bamboo clumps — A at Sedang, C at Tinggi, 5 stalks each | source slots and footprints copied verbatim; `isTree = true` |
| `npcs_r5` | all five R15 roles: petani + polisi Rendah; pedagang, petani_wanita, tukang_peci Sedang | source row y = 0.5, z = 8 copied verbatim; hats resolved by `accessoryFor(role)` |

Never placed: kelapa, pine, mangga / `mangga_true`. The disabled kelapa data in
`ModelMapVegetationR5.otherLevels` is not iterated. The first-frame north-road corridor
(`x -14..14`, `z -136..42`) is checked in the data module: every `isTree` entry must fail
`inNorthCorridor(x, z)` or it is dropped. All chosen trees sit at `|x| >= 27`.

## 2. Saved review camera

`position = { 0, 20, 72 }`, `lookAt = { 0, 5, 14 }`.
Derived from `+Z of SPAWN, inside MapSpec.TERRAIN_HALF; sees buildings row z=20, NPC row z=8,
plaza apron`. The applier never moves the camera; the review handoff records it.

## 3. Budgets (planning estimates, not measurements)

Rates from `SPAWN_DRESSING.md` §3: `TRI_PER_KIT = 2000`, `TRI_PER_LANDMARK = 8000`; only the two
buildings count as landmarks.

| Tier | Entries | Instance cap | Triangles (estimate) | Triangle cap |
|---|---:|---:|---:|---:|
| Rendah | 12 | 50 | 36,000 | 50,000 |
| Sedang | 23 | 100 | 58,000 | 100,000 |
| Tinggi | 31 | 150 | 74,000 | 150,000 |

`setTier("Rendah"|"Sedang"|"Tinggi")` validates against `D.tiers`; default `Sedang`. The data
module asserts both caps at require time and the spec repeats the checks at runtime.

## 4. Applier behaviour

`src/server/World/LookDevSpawnDressingR5.luau` is SERVER-ONLY (`InsertService:LoadAsset` is blocked
on the client). Toggle with dot syntax: `LookDev.enable("spawn_r5")` / `LookDev.disable()` from a
Server command bar after the main session wires the registry. Models: resolve ID → load → orient →
bbox measure → `ScaleTo(effectiveTarget / sizeY)` → bbox-bottom grounding on `y = 0.5` (plus sack
`yOffset`) → anchor + `CanCollide = false`. Rigs: `HumanoidDescription` six body colours →
`CreateHumanoidModelFromDescription(..., Enum.HumanoidRigType.R15)` → bbox-bottom grounding with a
Y-only rotation → optional Creator Store hat Model scaled and placed on `Head`. Every engine call
is pcall-guarded; a failed hat skips only that hat. `apply()` detaches any same-named folder;
`restore()` destroys the active folder and re-parents the saved one exactly.

## 5. Verification

- `lune run tests/run.luau` — suite unchanged at 2232 (new spec not auto-discovered; main session wires it).
- Focused spec runner — 16/16 passing.
- `selene src` — clean.
- `stylua --check` on the four new files — clean.
- `git diff --check` — clean.

No asset ID, product ID or UserId was invented. No verdict filled.
