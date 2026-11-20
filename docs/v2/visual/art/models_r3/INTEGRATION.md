# R3 models — LookDev integration and review handoff (WORK_QUEUE item 23)

Twenty real `Model` assets, one row per family in the 60×60 corner (absolute origin
`{ 500, 0, 500 }`, footprint X/Z 470–530). Source, licence, author and real ID for every file are
in `MANIFEST.md` and `upload_manifest.json`; **all 20 IDs came back from completed Open Cloud
upload operations** (`upload_route: ROBLOX_API_KEY` on all 20 rows). No ID is invented here.

All four candidates are **off by default** and awaiting a designer/vision verdict. This document
integrates and hands off; it does not grade anything visually. No agent has judged these models.

## Activate from the SERVER command bar

`InsertService:LoadAsset(<id>)` works in the **Server** datamodel but fails from the client
(`InsertService cannot be used to load assets from the client`). The appliers therefore live in
`src/server/World/LookDevModelsR3.luau` and are required by `src/server/Main.server.luau`.

In Studio, switch the command bar to the **Server** datamodel, then run:

```luau
require(game.ReplicatedStorage.Shared.LookDev).enable("buildings_r3")
require(game.ReplicatedStorage.Shared.LookDev).enable("vegetation_r3")
require(game.ReplicatedStorage.Shared.LookDev).enable("props_r3")
require(game.ReplicatedStorage.Shared.LookDev).enable("npcs_r3")
```

Restore with `require(game.ReplicatedStorage.Shared.LookDev).disable()`. Only one candidate is
active at a time; enabling another restores the previous one. Each apply creates a Workspace
Folder named `LookDevModelsR3_<family>`, removes any same-named leftover folder first, and loads
each slot into it as `R3_<slot>`, standing on y=0 using the asset's own bounding box. A failed
LoadAsset warns with the slot name; it never throws. Restore destroys the family folder and puts
back a pre-existing same-named folder if one was there.

Prerequisite: `src/shared/LookDev.luau` must list these four ids in `LookDev.IDS` and
`LookDev.candidates`; `LookDev.register` ignores unknown ids. That file is owned by the main
session.

## Toggles → saved cameras

Verbatim from `MANIFEST.md` (absolute world coordinates, paste into Studio `screen_capture` as
`camera_position` / `look_at_position`). Each family's row is staged to face its camera.

| Candidate toggle | Slots | camera_position | look_at_position | Verdict (blank) |
|---|---|---|---|---|
| `buildings_r3` | 3 | `{ 500, 16, 542 }` | `{ 500, 4, 490 }` |  |
| `vegetation_r3` | 6 | `{ 468, 12, 520 }` | `{ 500, 4, 500 }` |  |
| `props_r3` | 5 | `{ 532, 11, 500 }` | `{ 498, 2, 500 }` |  |
| `npcs_r3` | 6 | `{ 500, 7, 524 }` | `{ 500, 2, 500 }` |  |

All rows stay inside X/Z 470–530 with at least 4 studs between neighbouring slots. Review one
family at a time: the four rows share the same corner footprint and LookDev only enables one
candidate at once.

## Proof and boundaries

- Pure map + staging: `src/shared/ModelMapR3.luau` (all 20 IDs live here).
- Server adapter: `src/server/World/LookDevModelsR3.luau` (no asset ID literals).
- Lune coverage: `tests/specs/model_map_r3_spec.luau` — IDs, family/slot counts, bounds,
  spacing, manifest cross-check and adapter shape. That is a static check, not a Studio claim.
- Verdict cells stay blank. Capture the four shots in Studio, put evidence under
  `docs/v2/evidence/` and record the yes/no in `docs/v2/visual/CANDIDATES.md`.
- Status words remain `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`. This handoff is
  `LUNE-ONLY` until a Studio pass records evidence; no place is saved or published here.
