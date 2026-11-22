# Item 24 — Strict types on pure modules (2026-11-19)

Status: **LUNE-ONLY** (static type-check + Lune specs + selene; no Studio play needed — every change
is a compile-time annotation, erased at runtime). Branch `track/c-world-look`.

## Scope

Added `--!strict` as line 1 to every pure module in the three item-24 families, and only those:

- **all 24 `src/shared/Config/*.luau`** modules (pure data/tables).
- **`src/client/Feel/` pure logic:** `FidelityTier`, `TierScale`, `FpsSampler`, `CutsceneSequencer`,
  `CutsceneState`, `MomentGuard` (injectable, no game services at load).
- **`src/server/Testing/` policy:** `Gate`, `RaidTrigger` (both documented pure / no game APIs).

32 files in total. Deliberately left **non-strict** because they are engine-facing (game services,
Instances, tweens or replicated state at load): `client/Feel/ActionFeel`, `CameraFeel`,
`FidelityRuntime`, `PerfSwitches`, and `server/Testing/Harness`. `client/UI/LazyPages.luau` was
already strict before this item and was left as-is.

## Type errors fixed (annotation-only, no behavior change)

Adding strict surfaced 18 distinct errors in 8 files; each was fixed with a type annotation or a
runtime-erased cast:

- `Config/Audio` — added `SoundDef` type (`looped` optional) and cast `Audio.sounds :: { [string]: SoundDef }`.
- `Config/Products` — added `Product` type (grant-specific fields optional), cast `Products.products`
  and typed `Products.byProductId`.
- `Config/RaidCutscene` — added `Shot` type (`id/kind/duration` required, per-kind parameters optional)
  and cast `RaidCutscene.shots :: { Shot }`. The sequencer only reads `id/kind/duration`, so widening
  the extras does not change playback.
- `Config/Crops` — cast the derived `Crops.families` map to `{ [string]: { string } }`.
- `FidelityTier` — typed the `listeners` callback list; cast the `table.remove(samples, 1)` result
  that feeds `sampleSum` (the list is non-empty at that branch, so the removal never returns nil).
- `FpsSampler` — same `table.remove(...) :: number` cast in the rolling-sum branch.
- `MomentGuard` — annotated the injectable `resolve()` helper as returning `any`.
- `RaidTrigger` — typed `data: any` and the derived `cooldowns` map; left the `start` callback untyped
  (annotating it over-constrained `pcall`).

Note: Luau parses `table.field: T = value` as a *global type declaration*, not an assignment (it drops
the value). All field-level annotations therefore use an RHS `::` cast instead.

## Validation

- `luau-lsp analyze --platform roblox --sourcemap sourcemap.json --defs ".luau/globalTypes.d.luau"
  --ignore "**/Packages/**" src`: **17 distinct errors before, 17 after** — strict introduced **zero**
  new errors. The only apparent diff is the pre-existing `CutsceneSequencer` "idle vs playing" error
  moving from line 139 to 140 because of the added directive. The 17 remaining are all pre-existing
  errors in engine-facing files never touched by this item (Wind, FarmService, Leaderboard,
  Analytics, EconomyService, ToolService, RankService, FirstSession, LookDevWalkin, UI/Leaderboard,
  LookDev). Measured with a freshly regenerated (gitignored) `sourcemap.json` so sibling requires
  resolve; the committed state is unaffected by that local generated file.
- `lune run tests/run.luau` — **All 1908 tests passed** (suite unchanged; no spec added).
- `selene src` — **0 errors / 0 warnings / 0 parse errors**.

All changes are type annotations and `::` casts, which Luau erases at runtime — behavior is unchanged,
confirmed by the full suite. No place saved, no publish, no `profile:Save()`, no Studio play required.
