# facades_r8 — hub facade details (WORK_QUEUE section M item 78)

OFF by default, SERVER-side LookDev candidate 56. Grading is pending a real Studio review; no visual
verdict is claimed here. No place is saved or published by this item.

## What was added

One procedural staging Folder per existing hub under `Workspace.LookDevFacadesR8_facades_r8`, named
by hub key and carrying `HubKey`. Every hub gets ten anchored, non-collidable Parts plus one
transparent `FacadeDoorGauge` Part. All pieces are built from local recipes in
`Shared.ModelMapFacadesR8` and placed with the live `MapSpec.hub(key)` frame (`hubPoint` + `yaw`);
no world position is hardcoded and no shipping Greybox part is edited. Each decorative Part is
welded to the hub's anchor Part as structural documentation (both ends are anchored).

| Hub | Gauge (w x h x d) | Door position | Notes |
|---|---|---|---|
| `pasar` | 6 x 9 x 2 | local (0, 27) | open stall front on the plaza side; no literal door leaf |
| `gelap` | 6 x 9 x 2 | local (0, 15) | sits in the merah lantern-door frame |
| `warung` | 6 x 9 x 2 | local (0, 23) | open shop front behind the seng awning; no literal door leaf |
| `ronda` | 6 x 9 x 2 | local (0, 17) | cell is open on local +Z; raised for the Floor part |
| `polisi` | 6 x 9 x 2 | local (0, 23) | porch faces the plaza on local +Z; no literal door leaf |
| `pakrt` | 7 x 10.5 x 2 | local (-13, 10.5) | real door gap in Block A's front wall, forward of the wall plane |

All six hub fronts open on local +Z in Greybox. Pak RT and Gelap have authored door/frame geometry;
the other four have no door leaf, so their gauge marks the avatar-fit opening the player actually
walks through. The gauges are explicit in the data so the harness can verify their sizes and test
the opening; they are transparent, anchored, `CanCollide=false` and tagged with `HubKey`, `DoorW`,
`DoorH` and `DoorD`.

## Six detail kinds

Every hub carries all six, for ten Parts total:

- `shuttered_window` — two slatted panels flanking the opening.
- `porch_roof` — two pitched panels above the frontage.
- `ridge_cap` — one bright cap along the roof ridge.
- `lantern_bracket` — two metal arms either side of the front.
- `doorstep` — one low step just outside the gauge footprint.
- `eave` — two dark trim strips under the eave line.

Every decorative Part is tagged `FacadePart=true`, `FacadeKind=<kind>` and `HubKey=<hub>`. No asset
IDs, no `Color3` or `Enum` lookups at module load; colours are `{r,g,b}` arrays and materials are
built-in `Enum.Material` names resolved by the applier.

## Studio run recipe (main session owns this)

1. Stop Play. Inject the changed modules at runtime, do not save: `Shared.ModelMapFacadesR8`,
   `Shared.LookDev`, `Shared.LookDevReview`, `Server.Main.server` and
   `Server.World.LookDevFacadesR8`. Paste the new `tools/studio/review_check_r8.luau` as well.
2. Start a FRESH real Play session (no prior candidate staged), in the SERVER datamodel.
3. Stage with `require(game.ReplicatedStorage.Shared.LookDevReview).enable("facades_r8", game)`.
4. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Capture `FACADE_PARTS` and `DOOR_CLEAR`, plus the guards `LOAD_FAILURES` and
   `LOOKDEV_LEAK`. Targets: `FACADE_PARTS 6 6` (each of six hubs has >=10 tagged Parts and all six
   kinds) and `DOOR_CLEAR 6 6` (each gauge has exact data sizes and zero collidable hub parts and
   zero FacadeParts in its rotation-aware `GetPartsInPart` probe). Missing folder, hub folder, gauge
   or hub Model FAILs at measured 0 — never a skip.
5. Stop Play without saving. No publish. Visual yes/no remains the designer's.
