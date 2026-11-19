# Textures r3 — real CC0 PBR LookDev candidate

WORK_QUEUE round 3 items 20/21. Nine material variants from nine Poly Haven CC0 PBR
sets (diffuse + `nor_gl` normal + roughness, all 1024x1024). All 27 Open Cloud IDs
were returned by completed operations using the `ROBLOX_API_KEY` route (item 20,
POST HTTP 200) and are recorded in `ASSET_MANIFEST.md` and `upload_manifest.json`.
No ID was invented and no agent graded the images visually.

## Toggle

`require(game.ReplicatedStorage.Shared.LookDev):enable("textures_r3")`

`:disable()` destroys the temporary MaterialVariants and restores every MeshPart's
`Material` and `MaterialVariant`. Shipping defaults are unchanged; published
servers can never enable the candidate.

## Review aid

- Contact sheet: `render/contact_sheet.png` (one row per surface, columns diff / nor / rough).
- Source URLs, authors, MD5s and operation IDs: `download_manifest.json`, `upload_manifest.json`.

The sheet is a dump of the downloaded source maps, not a Studio screenshot. The
designer/vision observer decides the verdict; the `CANDIDATES.md` cell stays blank.

## Saved review camera (absolute world coordinates)

The adapter targets the imported prop/kit MeshParts around the Pasar row (Studio
read, 2026-11-20): examples at x ≈ -105..-32, y ≈ 1..5, z ≈ -58. Use this saved
position to compare the variants in context:

| Shot id | `camera_position` | `look_at_position` |
| --- | --- | --- |
| `pasar_material_row` | `{ -70, 12, -30 }` | `{ -70, 3, -58 }` |

This is a review position only. No screenshot, verdict or Studio claim is recorded here.
