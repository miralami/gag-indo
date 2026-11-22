# Round 2 item 5 — hero texture CANDIDATES behind LookDev

Date 2026-11-19. Branch `track/c-world-look`. Status `SEEN-IN-STUDIO`.

## Target

Produce 6–8 hero textures per `docs/v2/visual/art/TEXTURES.md`: tileable, uploaded through Open
Cloud, IDs recorded, and applied in an off-by-default `LookDev` material preset. Every asset is a
CANDIDATE awaiting a designer yes/no — none approved, none shipped on by default.

## What was made

- `docs/v2/visual/art/textures/src/generate_textures.py` deterministically renders seven 512x512
  tileable RGBA PNGs into `docs/v2/visual/art/textures/render/`, plus a labelled
  `contact_sheet.png`. Each motif is drawn on a wrapped 3x3 grid so shapes crossing an edge
  continue on the opposite edge. The generator's validity check passed (7 files, all 512x512 RGBA)
  and a seam check compared opposite-edge pixel jumps against ordinary interior jumps (all 7
  passed). Palette is copied from `Visuals.luau` (ART.md §3); no text, no logos.
- Zip-free flat files were uploaded with Studio MCP `open_cloud_invoke`
  (`POST /assets/v1/assets`, `assetType=Image`) and confirmed with
  `GET /assets/v1/operations/{id}`. Every returned ID was written to
  `docs/v2/visual/art/ASSET_MANIFEST.md` immediately. All are `moderationState=Approved`
  (`texture_sawah` was briefly `Reviewing`, then Approved on re-poll), creator User `172146044`.
  The Studio MCP Assistant-scope token was used — NOT the `ROBLOX_API_KEY` env var; no key was
  printed, logged or committed.

| Slot | Asset ID |
|---|---|
| `texture_bambu` | 86020876968095 |
| `texture_genteng` | 121899778984239 |
| `texture_seng` | 116077927961929 |
| `texture_paving` | 70537329110423 |
| `texture_sawah` | 121312141770783 |
| `texture_kertas` | 102834761172815 |
| `texture_tanah` | 95694392312399 |

## Wiring

- IDs live in `src/shared/TextureMap.luau` `candidateIds`; every shipping `Visuals.textures` slot
  stays 0 (built-in material + palette colour fallback). `LookDev.luau` holds only a pure-data
  `textures` candidate with an `idsSource` pointer, so its "no asset IDs in LookDev or adapters"
  spec guard still holds.
- `src/client/World/LookDevTextures.luau` applies the IDs only while the `textures` candidate is
  enabled, and remembers each part's original Colour/Material/SurfaceAppearance so `disable()`
  restores exactly. Booted behind `pcall(require, …)` in `Main.client.luau`.
- `SurfaceAppearance` can only be parented to `MeshPart`s — confirmed in Studio when parenting to a
  greybox `Pasar` Part threw "SurfaceAppearance can only be parented to MeshParts." The adapter
  therefore targets the imported v2 `prop_*`/`kit_*` MeshParts (plus any MeshParts under `Pasar`);
  greybox Parts are left untouched. This is a LookDev candidate, not a redesign of shipping geometry.

## Studio proof (Play Solo, fresh Client VM, Rojo `localhost:34872`)

The Edit VM kept a stale `require` cache for `LookDev` (3 IDs) even after Rojo synced the 4-ID
source and after touching each ModuleScript's `Source`. A Play session creates a fresh VM that
loads the synced source, so verification ran there. The `execute_luau` Client context is a separate
VM from LocalScripts, so the adapter was required directly from
`LocalPlayer.PlayerScripts.Client.World.LookDevTextures` to register it.

- `LookDev.IDS` = `plaza_lighting,police_walkin,icons,textures`; `hasApplier("textures")` = true.
- `enable("textures")` and `disable()` both returned `true`; `current()` reported `textures`.
- `Visuals.textures` slots: `0,0,0,0,0,0,0` → the seven real IDs → `0,0,0,0,0,0,0` (7 populated).
- `TextureMap.usingCandidates()`: `false` → `true` → `false`.
- `SurfaceAppearance` count across the place: 0 → **10** → 0. Sampled enabled ColorMaps include
  `prop_crate=rbxassetid://86020876968095`, `prop_motor=rbxassetid://116077927961929`,
  `kit_hut=rbxassetid://121899778984239`, `kit_wall=rbxassetid://86020876968095`,
  `prop_barrel=rbxassetid://116077927961929`, `prop_gerobak=rbxassetid://86020876968095`,
  `prop_pasar_stall=rbxassetid://86020876968095`, `kit_fence=rbxassetid://86020876968095`.

No image input was available this session, so no agent visually graded the art. The contact sheet
is provided for the designer's yes/no only; the Studio proof above establishes the wiring and the
toggle, not an aesthetic judgement.

## Validation

`lune run tests/run.luau`: **All 1939 tests passed** (up from 1933; 6 new texture/LookDev specs).
`selene src`: 0 errors / 0 warnings / 0 parse errors. Gallery `docs/v2/visual/CANDIDATES.md`.
Place was not saved and not published.
