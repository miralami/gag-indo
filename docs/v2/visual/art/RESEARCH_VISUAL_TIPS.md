# Visual research and tips backlog (2026-11-14)

Sources: four YouTube tutorials saved in `docs/improvements/realistic tutorials.txt`, plus a web pass over the
official Roblox docs, the Blender manual and licence pages. Status words follow Master Plan §7.
Anything not confirmed from a primary source is marked **UNCONFIRMED**.

**Workflow chosen by the designer: apply all tips first, optimise later.** Section 3 is the
"optimise later" backlog. Section 2 tracks what has been applied.

## 1. What the videos teach, and what we keep

The videos chase photorealism (Sketchfab trees, Polyhaven PBR). Our art direction is hand-painted
with contour lines (D11, `visual/ART.md`), so we take the techniques, not the photoreal assets.

| Technique | Source | Keep? |
|---|---|---|
| Decide mood first, use references | Fives; "ANY game REALISTIC"; "24 hours" | Yes. Designer to supply 2 to 3 reference photos of an Indonesian village and pasar. |
| Clock time ~14 to 17, brighter sun, warm ambient, yellow `ColorShift_Top` | Fives; "ANY game REALISTIC" | Already in `Seasons.luau`. |
| Darker ambient gives stronger shadows ("the secret") | "ANY game REALISTIC" | Apply, small. |
| Atmosphere density, haze and colour matched to the scene | Fives | Already in. |
| Layers: trees, then bushes, then grass, then micro detail | "24 hours" | Apply. |
| 60/30/10 colour rule (green, brown, saturated accent) | "24 hours" | Audit and apply. |
| Break uniformity: vary rotation and scale, mix materials, vary the ground | "24 hours"; "5 building tips" | Apply. |
| Ambient sound is half the atmosphere | Fives | Apply (needs verified audio IDs). |
| Wind on foliage via a tag | "ANY game REALISTIC" | Apply, near the camera only. |
| FOV, camera and footsteps polish | "ANY game REALISTIC" | FOV only for now. |
| Fill shelves, break sightlines, decorate floors | "5 building tips" | Apply. |
| Sketchfab and Polyhaven photoreal assets | "ANY game REALISTIC" | No: style clash, licence and weight. |

## 2. Application tracker (branch `track/c-world-look`)

| Tip | Lane and file | Status |
|---|---|---|
| Trees, roads, hub buildings, decor | `Greybox.luau`, `Decor.luau` | LUNE-ONLY plus structure measured in Studio; no after screenshot |
| Terrain, hills, rumput | `Landscape.luau` | applied 2026-11-14; hills 12 to 18 studs measured in Studio; grass Decoration is a place-file setting that scripts cannot write, tick it in Studio > Terrain (track C) |
| Bushes, rocks, grass, wind tag and sway | `Flora.luau`, `client/World/Wind.luau` | applied; 64 parts, 42 canopies tagged `WindShake`; sway not seen by a human |
| Goods on shelves, sightline breakers, floor details | `Details.luau` | applied; 98 parts; not seen by a human |
| Lighting contrast, FOV | `Seasons.luau`, `client/Feel/CameraFeel.luau` | applied; ambient only 4 to 8 percent darker (subtle); FOV 72 measured |
| Ambient sound and music | `Config/Audio.luau`, `art/ASSET_MANIFEST.md` | applied; music_desa and ambience_cerah playing in Studio; by ear not judged |

Studio caught three errors Lune could not (mock Enum and Terrain accept anything): invalid
`Enum.Material.CorrugatedMetal`, `Terrain.Decoration` written from script, and `Water` passed to
`SetMaterialColor`. Each now has a regression test or note.

## 3. Optimise later (backlog, nothing here is applied)

Measured fact: the designer's Xiaomi 12 Lite (Snapdragon 778G, upper mid-range) runs about 30 fps at
maximum graphics and 60 fps at the lowest (`evidence/h/2026-11-14-perf/DESIGNER_PHONE_REPORT.md`).
Roblox says over half of players are in the Passmark 10k to 20k range, so the real "mid-range"
target is weaker than this phone.

1. **Find the cause first.** Add Studio/admin-only switches to disable Highlights, shadows and
   bloom one at a time, then compare fps on the phone. Highlight docs: the first visible Highlight
   costs up to 1 ms GPU on mobile and the cost grows with screen coverage; adding or removing one
   triggers a rebuild, so toggle properties instead. The world has 27 Highlights (contour).
2. `BasePart.CastShadow = false` on small and distant parts; `Light.Shadows = false` where possible.
   Shadows are the main low-end cost and the engine drops them as `QualityLevel` falls.
3. Contour only within about 60 studs (`visual/ART.md` §5), and reuse one Highlight per group where possible.
4. Point lights cost more on weak devices; keep the 2 current lights, add none.
5. `MeshPart.RenderFidelity = Performance` for foliage and small meshes once we have meshes.
6. Texture sizes: 256 per about 5x5 studs, 512 per 10x10, 1024 only for 20x20; 1024 costs 4x the
   memory of 512. Default to 512 or below. The docs disagree on the current max (1024 vs 4096):
   **UNCONFIRMED**.
7. Reuse the same mesh or asset ID so the engine can batch draw calls (official example: 8 to 1).
8. StreamingEnabled is on by default for new places; lower `StreamingMinRadius` and
   `StreamingTargetRadius` if memory is the issue. Check the place setting.
9. Profile on the phone: MicroProfiler (red bars are rendering, orange are scripts, physics,
   animation), Developer Console F9, frame dumps with Ctrl+Alt+F6; run 10 to 15 minutes to see
   thermal throttling.
10. **UNCONFIRMED** (no primary source): Future vs ShadowMap cost, bloom and ColorCorrection cost,
    Terrain Decoration cost. Only a phone measurement answers these.
11. Budgets: official docs give no triangle budget. The 20,000 triangles per mesh figure is an
    **upload ceiling**, not a budget. A community guide suggests about 500k triangles and 500 draw
    calls per scene (one author's opinion); a search snippet of the official performance page says
    under 1,000 draw calls and 1,000,000 triangles for low-end. Project budget until measured:
    about 2,000 triangles per modular piece, up to about 8,000 for a hero prop.

## 4. Blender to Roblox pipeline notes

- FBX export: Limit to Selected Objects; Apply Scalings = FBX Unit Scale. glTF avoids the scale
  workaround but adds an extra nested Model per mesh.
- The Blender page says Forward Z, Up Y while the Importer defaults are Front and Top.
  **Do one pilot import before standardising** (one warung, one tree). Apply-transform and pivot
  advice is **UNCONFIRMED**.
- Meshes: watertight, no backfaces, quads preferred, no n-gons, one material, one UV set, UVs in 0 to 1.
- SurfaceAppearance: ColorMap RGB 24-bit, NormalMap OpenGL tangent space, Roughness and
  Metalness 8-bit greyscale.
- Collision fidelity, Unions, naming, trim sheets, inverted hull vs Highlight, vertex colours vs
  textures: **UNCONFIRMED**.

## 5. Licences

| Source | Licence | Verdict |
|---|---|---|
| Poly Haven | CC0 | Free to use, no attribution. |
| Kenney | CC0 | Free to use, no attribution. |
| Quaternius | Own licence v1.0, **not CC0**: commercial use and no attribution, but no resale or raw redistribution | OK inside the game; record in the manifest. |
| Sketchfab | Per-model, Standard licence needs attribution in credited productions | Avoid unless each licence is read. |
| Roblox | You must hold the rights to everything you upload; third-party IP needs permission | Upload only your own work or verified CC0. |

## 6. Sources

- Roblox: `create.roblox.com/docs/art/blender`, `/docs/studio/importer`, `/docs/art/modeling/specifications`,
  `/docs/art/modeling/texture-specifications`, `/docs/effects/highlighting`,
  `/docs/performance-optimization/improve`, `/docs/performance-optimization/microprofiler`,
  `/docs/performance-optimization/test-on-hardware`, `/docs/workspace/streaming/slim`,
  `/docs/tutorials/3D-art/enhancing-outdoor-environments-with-future-lighting`,
  `/docs/production/creator-store`.
- Licences: `polyhaven.com/license`, `kenney.nl/support`, `quaternius.com/license.html`, `sketchfab.com/licenses`.
- Community, lower confidence: DevForum threads on terrain grass, unions and optimisation.
