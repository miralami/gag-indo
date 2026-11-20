# R3 models — LookDev integration and review handoff (WORK_QUEUE item 23, item 28 fixes)

Twenty real `Model` assets, one row per family staged on **real PLAZA ground** from
`src/server/World/MapSpec.luau` (`PLAZA` spans X -48..48, Z -42..42), centred at
`{ -14, 0, -12 }` with at least 4 studs between neighbouring slots. Source, licence, author and
real ID for every file are in `MANIFEST.md` and `upload_manifest.json`; **all 20 IDs came back from
completed Open Cloud upload operations** (`upload_route: ROBLOX_API_KEY` on all 20 rows). No ID is
invented here. The old `{ 500, 0, 500 }` staging was off-map over the void (round-3 bug 6).

All four candidates are **off by default** and awaiting a designer/vision verdict. This document
integrates and hands off; it does not grade anything visually. No agent has judged these models.

## Activate from the SERVER command bar

`InsertService:LoadAsset(<id>)` works in the **Server** datamodel but fails from the client
(`InsertService cannot be used to load assets from the client`). The appliers therefore live in
`src/server/World/LookDevModelsR3.luau` and are required by `src/server/Main.server.luau`.

A plain `require(...LookDev)` from a fresh command-bar VM has no appliers registered (round-3 bug
7). Use the one-call helper from a **Server** command bar / `execute_luau` VM:

```luau
require(game.ReplicatedStorage.Shared.LookDevReview).enable("buildings_r3", game)
require(game.ReplicatedStorage.Shared.LookDevReview).enable("vegetation_r3", game)
require(game.ReplicatedStorage.Shared.LookDevReview).enable("props_r3", game)
require(game.ReplicatedStorage.Shared.LookDevReview).enable("npcs_r3", game)
require(game.ReplicatedStorage.Shared.LookDevReview).disable()
```

The helper `pcall(require)`s `ServerScriptService.Server.World.LookDevModelsR3` in that VM before
calling `LookDev.enable("id")` with dot syntax; `disable()` restores the shipping look. Only one
candidate is active at a time. Each apply creates a Workspace Folder named
`LookDevModelsR3_<family>`, removes any same-named leftover folder first, and loads each slot into
it as `R3_<slot>`. A failed LoadAsset warns with the slot name; it never throws. Restore destroys
the family folder and puts back a pre-existing same-named folder if one was there.

Each loaded model is oriented (`rotX` + `ry`), normalised to its slot's `targetHeight` with
`Model:ScaleTo(targetHeight / boundingBoxSizeY)` (round-3 bug 4), then **every BasePart descendant
is anchored and set `CanCollide = false`** (round-3 bug 3). `farmer_cc0` and `polisi_cc0` get
`rotX = math.pi / 2` to stand the Z-up CC0 imports upright (round-3 bug 5). Anchoring stops the
model falling through the ground; `CanCollide = false` is deliberate because this staging sits on
the walkable plaza near spawn — a colliding display model would be an invisible player blocker.
No shipping collision is changed.

Prerequisite: `src/shared/LookDev.luau` must list these four ids in `LookDev.IDS` and
`LookDev.candidates`; `LookDev.register` ignores unknown ids. That file is owned by the main
session.

## Toggles → saved cameras

Verbatim from `MANIFEST.md` (absolute world coordinates, paste into Studio `screen_capture` as
`camera_position` / `look_at_position`). Each family's row is staged to face its camera. All rows
stay inside `MapSpec.PLAZA` and away from spawn, roads and hub clearings.

| Candidate toggle | Slots | camera_position | look_at_position | Verdict (blank) |
|---|---|---|---|---|
| `buildings_r3` | 3 | `{ -14, 16, 30 }` | `{ -14, 4, -22 }` |  |
| `vegetation_r3` | 6 | `{ -46, 12, 8 }` | `{ -14, 4, -12 }` |  |
| `props_r3` | 5 | `{ 18, 11, -12 }` | `{ -16, 2, -12 }` |  |
| `npcs_r3` | 6 | `{ -14, 7, 12 }` | `{ -14, 2, -12 }` |  |

Review one family at a time: the four rows share the same staged corner footprint and LookDev
only enables one candidate at once.

## Proof and boundaries

- Pure map + staging: `src/shared/ModelMapR3.luau` (all 20 IDs, `targetHeight`, `rotX`).
- Server adapter: `src/server/World/LookDevModelsR3.luau` (no asset ID literals).
- One-call review helper: `src/shared/LookDevReview.luau` (17 existing candidate paths).
- Lune coverage: `tests/specs/model_map_r3_spec.luau` (legacy shape/IDs) and
  `tests/specs/review_round3_bugfix_spec.luau` (item-28 fixes: MapSpec footprint, spawn/road
  clearance, targetHeight/rotX, anchoring/collision/scale/rotX source, helper ordering). Static
  checks, not a Studio claim.
- Verdict cells stay blank. Capture the four shots in Studio, put evidence under
  `docs/v2/evidence/` and record the yes/no in `docs/v2/visual/CANDIDATES.md`.
- Status words remain `SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`. This handoff is
  `LUNE-ONLY` until a Studio pass records evidence; no place is saved or published here.
