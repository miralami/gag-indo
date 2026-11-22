# Greybox retired to a test-only fallback — Track H, 2026-11-19

Build: `track/c-world-look` at `a9c164d`, Rojo serving `localhost:34872`. Connected Studio instance
`447c176b-1d7b-4b9c-a794-45912fea4b63`, cloud dev place `Development-Juragan-Desa` (placeId
`132087524375529`, universeId `10776530981`). Machine-readable readings in `results.json`.

**The place was never saved and never published. `profile:Save()` was never called.** Every injected
world existed only inside the running process; Play was stopped and Studio returned to Edit.

## The contract being proven

`Map.isDesignerWorld()` is true when the place has a `VillageWorld` tag **or** a `PlotAnchor` tag.
`Village.build()` calls `Greybox.build()` only when that is false, then `Village.bind()` finds the
six hubs, five prompts and three NPCs from CollectionService tags regardless of who created them.
A designer place therefore gets the same behaviour with no Greybox geometry at all.

## 1. Specs — `tests/specs/greybox_retirement_spec.luau` (6 cases)

The real `Village` and `Map` modules run under Lune with `Greybox` as a call-counting spy:

- `Map.isDesignerWorld()` is false with no tags, true with `VillageWorld`, true with `PlotAnchor`.
- `Village.build()` calls `Greybox.build()` exactly once with no designer world, and never again
  once a designer world is present.
- With a designer world, all six hub positions come from the tagged parts, five prompts bind,
  pakrt/tengkulak/one polisi bind, and `Greybox.build()` is never called.
- A second `build()` (Studio hot reload) does not double-connect a prompt's `Triggered` signal and
  keeps the bound prompt.

Full suite `lune run tests/run.luau`: **1725 passing**. `selene src`: **0 errors, 4 pre-existing
warnings** (item 8 owns clearing those).

## 2. Studio Edit mode — clean code path, no pre-existing world

Edit mode has no world at all (0 `GreyboxWorld`, 0 `VillageWorld`, 0 `PlotAnchor`, no `World`
folder), so it isolates the branch. A `VillageWorld`-tagged Model was injected with six hub anchors
at `MapSpec.hub()` centres (five ProximityPrompts + a `RondaAnchor`), three `NpcSpawn` Models and a
`PlotAnchor`. Then `Village.build()`:

| Reading | Before | After `Village.build()` |
|---|---|---|
| `GreyboxWorld`-tagged | 0 | 0 |
| `workspace.World` folder | absent | absent |
| BaseParts in workspace | 279 | 279 |

All six hub positions matched `MapSpec`; 5 prompts and 3 NPCs bound. **Greybox was not invoked.**

## 3. Studio Play Solo Server VM — the running game with no Greybox

Normal startup built the 1706-part Greybox world (`GreyboxWorld`-tagged, `World` folder with 460
children). That world was destroyed to simulate a designer place, which never contains it:

| Stage | BaseParts | `GreyboxWorld`-tagged |
|---|---|---|
| startup (Greybox) | 1706 | 1 |
| after Greybox destroyed | 287 | 0 |
| after designer world injected + `Village.build()` | 297 | 0 |

The +10 parts are exactly the injected designer world (6 hub parts + 3 NPC parts + 1 plot anchor);
no Greybox geometry was regenerated (`World` folder stayed absent). All six hub positions matched
`MapSpec`, 5 prompts and 3 NPCs bound, and the console output was **identical before and after**
(`[JuraganDesa] server started`, `[ProfileStore]` availability, and the external Assistant plugin
version warning) — **zero new Output errors or warnings**.

## Not in scope — designer / Track C deliverable

This proves the *code path* is Greybox-independent. The actual `JuraganDesa.rbxl` still has no
designer world, so the shipped place currently relies on the Greybox fallback. Building and saving
the real village into the place is the Track C / designer deliverable (`MASTER_PLAN.md` §5, track C),
and this run does not save the place file. The safe reversible default is to keep the fallback
enabled until that designer place ships; disabling it sooner would leave an empty world. Recorded in
WORK_QUEUE "Decisions for designer".
