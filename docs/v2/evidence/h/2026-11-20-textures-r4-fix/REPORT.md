# Item 35 — `textures_r4` darkening: diagnosis and fix evidence (2026-11-20)

Candidate remains **off by default**. No visual verdict is recorded here; the verdict cell stays blank.

## Root cause (measured, not guessed)

`LookDevTexturesR4` installs 12 CC0 `MaterialVariant`s through
`MaterialService:SetBaseMaterialOverride`. A live Play/Client read confirmed the variants carry
only `ColorMap` / `NormalMap` / `RoughnessMap` (no tint property), so a base-material override also
affects Terrain surfaces. Terrain multiplies the colour map by `Terrain:GetMaterialColor(material)`;
the measured stock multipliers were dark earth colours, which crushed the already-dark laterite /
mud / paddy maps towards black.

`Terrain.MaterialColors` is **not** a member of Terrain in this runtime. The working API is
`Terrain:GetMaterialColor(material)` / `Terrain:SetMaterialColor(material, Color3)`, confirmed live
and in `.luau/globalTypes.d.luau`. Water is excluded (`SetMaterialColor` does not support it).

## Fix

`TextureMapR4.terrainTint` holds bright warm-neutral `#RRGGBB` values for the 11 affected built-in
terrain base names. On apply, `LookDevTexturesR4` captures each exact current terrain material
colour and sets the bright tint; on disable it restores the captured colour before restoring the
override strings and destroying the variants. Missing/unsupported Terrain is a silent no-op. No CC0
asset ID, variant name or studsPerTile value was changed.

## Before / during / after — live Play/Client measurement

Read with `Terrain:GetMaterialColor` from the saved spawn review camera area in a **fresh** Play
session after Rojo sync, toggled via `LookDevReview.enable("textures_r4", game)` /
`LookDevReview.disable()` (dot syntax). Hex values are exact reads, not estimates.

| Terrain material | before | during (`textures_r4` on) | after (disabled) |
|---|---|---|---|
| Grass | `#6F8A3F` | `#F7F2E4` | `#6F8A3F` |
| Ground | `#8A6A46` | `#FAF4E8` | `#8A6A46` |
| Mud | `#5B4A38` | `#F6EEE2` | `#5B4A38` |
| Cobblestone | `#847B5A` | `#F6F0E3` | `#847B5A` |
| Brick | `#8A563E` | `#F9F2E6` | `#8A563E` |
| Slate | `#3F7F6B` | `#F7F1E5` | `#3F7F6B` |

`LookDev.current()` read `textures_r4` while on and `nil` after disable. Every colour returned to
its exact pre-candidate value, so the change is fully reversible.

## Still-image note

The existing round-4 shots are `h/2026-11-20-review-round4/shots/01_textures_before.jpg` (baseline),
`02_textures_r4_wide.jpg` and `03_textures_r4_close.jpg` (reported darkening). A new after-fix Studio still was **not** retained in this session: the
direct capture returns an image this session cannot view or write to disk, and the vision observer's
capture returned only UI / no 3D scene. The after-fix still from the saved spawn camera is therefore
assigned to the round-5 review handoff (WORK_QUEUE item 42), where the main session takes the Studio
shots. This file makes no screenshot claim and grades nothing.
