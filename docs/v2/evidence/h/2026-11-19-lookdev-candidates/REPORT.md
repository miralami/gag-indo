# Look-dev candidates for designer review — Track H, 2026-11-19

Build: `track/c-world-look` at base `3309439`, Rojo serving `localhost:34872`. Studio instance
`447c176b-1d7b-4b9c-a794-45912fea4b63`, cloud dev place `Development-Juragan-Desa` (placeId
`132087524375529`, universeId `10776530981`).

**Play Solo only. The place was never saved or published. `profile:Save()` was never called. Play was
stopped and Studio returned to Edit.**

Both candidates below are recorded **candidate, awaiting designer yes**. Neither is approved or
shipped, and WORK_QUEUE item 9 is deliberately NOT ticked done. Choosing between them (or neither)
is the designer's call.

## The toggle (OFF by default, Studio-only, never persisted)

`src/shared/LookDev.luau` is the single pure source of truth: the two candidate records, their
plans, a built-in-material allowlist, and the gate. `LookDev.current()` is `nil` until the designer
explicitly opts in from the Studio command bar:

```lua
local L = require(game.ReplicatedStorage.Shared.LookDev)
L:enable("plaza_lighting")   -- or "police_walkin"
L:disable()                  -- restores the original look exactly
```

`canEnable()` demands a literal `studio == true` (a published server, a nil flag, or a truthy
non-boolean all refuse). The flag is in-memory only, defaults to `RunService:IsStudio()` when
omitted, and is never written to a DataStore — a published place can never remember it on. Only one
candidate is active at a time; switching restores the previous look first. Both appliers are behind
`pcall(require, ...)` in the respective Main bootstraps, so a missing/failed candidate can never
break the client or server start.

**No asset IDs:** materials are names from a built-in `Enum.Material` allowlist, colours are plain
`{r,g,b}` arrays consumed by `Color3.fromRGB`, and there is no asset ID anywhere in the three files.
A spec asserts this (no `rbxasset`/`assetId` token, no 7+ digit literal) and every configured
material must pass `isBuiltinMaterial()`.

Style for both: **cartoonish-realism**.

## Candidate A — `plaza_lighting` (candidate, awaiting designer yes)

Alternative material + lighting preset for the pasar (plaza) hub.

- Registry/plan: `src/shared/LookDev.luau` (`candidates.plaza_lighting`, `plan()`).
- Applier: `src/client/World/LookDevPlaza.luau`, registered in `src/client/Main.client.luau`.
- Only descendants of the `Pasar` model whose names match a category keyword change material:
  ground→`Sandstone`, wood (counters/tables/shelves)→`WoodPlanks`, roof→`Brick`,
  road/path→`Cobblestone`. All are built-in Roblox textured materials; unknown parts are untouched.
- Alternative grade: brighter, cleaner midday warmth with a gentle teal bounce (clockTime 11.4,
  brightness 2.2, cool fog/ambient, slight saturation/bloom) — deliberately distinct from the
  golden-hour `Config/Seasons` preset so the designer can compare the two.
- Fully reversible: every original material and every touched Lighting/Atmosphere/ColourCorrection
  property is saved and put back on `disable()`. Effects that don't exist in the place are never
  added.

## Candidate B — `police_walkin` (candidate, awaiting designer yes)

Police NPC walk-in prototype using the existing police model and pathing, timed to the raid
cutscene's `walkin` shot.

- Registry/plan: `src/shared/LookDev.luau` (`candidates.police_walkin`, `plan()`).
- Applier: `src/server/World/LookDevWalkin.luau`, registered in `src/server/Main.server.luau`.
- Reuses `Village.police[1]` — the already-wrapped `NpcFactory` police NPC (no new model, no asset
  IDs). On enable it records the home CFrame, teleports the NPC off-frame, then calls the existing
  `walkTo()` to the cutscene `road` anchor at a speed of distance/duration so it arrives as the
  `walkin` shot ends (shot duration 1.8 s from `Config/RaidCutscene`, anchor `0, 2, -28`, speed
  ≈ 20.88 studs/s). `disable()` cancels the walk token, calls `stop()` and teleports home.

## Proof

- `lune run tests/run.luau`: **1769 passing** (was 1754; +15 new `lookdev_candidates_spec` cases).
  `selene src`: **0 errors / 0 warnings / 0 parse errors**.
- `tests/specs/lookdev_candidates_spec.luau` (15 cases, `LUNE-ONLY`) locks: exactly two candidates
  both unapproved/cartoonish-realism; no asset IDs; built-in-material allowlist; the off-by-default
  Studio gate; enable/disable round-trip and single-active rule; applier error containment; both
  plans (plaza grade, walk-in timing to the real 1.8 s shot and road anchor); and the thin-adapter +
  Main `pcall` wiring.
- **Studio client VM (Play Solo):** `LookDev.current()` nil by default; both candidates report
  status `candidate, awaiting designer yes` / style `cartoonish-realism`; `LookDevPlaza` loads and
  registers its applier. Reversible toggle proved live: `enable("plaza_lighting")` → current
  `plaza_lighting`, Lighting.ClockTime 17.2 → 11.4; `disable()` → current nil, clock restored
  (|Δ| < 0.001). 0 probe errors.
- **Studio server VM (Play Solo):** `LookDev.current()` nil by default; both candidates unapproved;
  `LookDevWalkin` loads and registers its applier; plan resolves `duration=1.8`, `anchor=0,-28`,
  `speed=20.88`. 0 probe errors.
- Console showed only the pre-existing Assistant-plugin version warnings — no new game-code errors.
- **Status:** toggle/gate, candidate records, load and reversibility `SEEN-IN-STUDIO` (this report);
  the 15 spec cases `LUNE-ONLY`. Final visual approval is `BLOCKED` on the designer's "yes".
