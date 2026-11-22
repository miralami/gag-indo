# hubprops_r8 — vernacular props in all six hubs (WORK_QUEUE section M item 79)

OFF by default, SERVER-side LookDev candidate 57. Grading is pending a real Studio review; **no
Studio result and no visual verdict are claimed here**. No place is saved or published by this item.
Enable from the Studio **Server** command bar only:

```luau
require(game.ReplicatedStorage.Shared.LookDevReview).enable("hubprops_r8", game)
require(game.ReplicatedStorage.Shared.LookDev).disable() -- restores the shipping look
```

## What was added

One `Workspace.LookDevHubPropsR8_hubprops_r8` Folder, one sub-Folder per hub key with `HubKey`, and
one Model per prop named `<HubKey>_<PropKind>` carrying `HubProp=true`, `HubKey`, `PropKind` and
`Source`. Every recipe is local to the hub and placed through `MapSpec.hubPoint(hub, lx, lz)` with
`hub.yaw`: no world position, shipping part or saved place is touched. Props sit on the open local
`+Z` front apron. Slots are laid out across the camera's review cone (7-stud centre spacing, wide
props farther from the eye) so every centre is inside the 35-degree half-angle cone and props do not
mask one another in the 3/4 hub view; the row stays outside the item-78 door gauges. A Ground voxel
pad is painted under every prop so the Terrain sample at `GRASS_Y=4` is not Grass.

| Hub | Count | Vernacular kinds | Baked kinds |
|---|---|---|---|
| `pasar` | 9 | `sayur_crate`, `timbangan` | `bakul` (x2, generated), `karung`, `gerobak`, `lapak`, `jemuran`, `pagar_bambu` |
| `gelap` | 6 | `lampu`, `tong`, `kardus` | `karung`, `gerobak`, `pagar_bambu` |
| `warung` | 9 | `bangku`, `teko`, `toples`, `timbangan` | `lapak`, `jemuran`, `karung`, `pagar_bambu`, `sumur` |
| `ronda` | 7 | `kentongan`, `lampu`, `bangku`, `papan_pengumuman` | `bale_bambu`, `jemuran`, `karung` |
| `polisi` | 8 | `bendera`, `papan_pengumuman`, `meja`, `kursi`, `lampu` | `motor`, `pagar_bambu`, `karung` |
| `pakrt` | 8 | `meja`, `kursi_rotan`, `bendera`, `teko`, `toples`, `papan_pengumuman`, `lampu` | `karung` |

## Ladder decision (D15)

Step (1): the eight baked kinds with a verified asset use one of the **nine** IDs already recorded in
`docs/v2/visual/art/ASSET_MANIFEST.md` (no ID is invented). `LookDevAssetLoader.get` prefers the
Edit-time baked clone over `InsertService:LoadAsset`; scripts are stripped, `GetBoundingBox` is
measured and every part is non-uniformly scaled to its real-world target bbox before anchoring.

Step (2): two Pasar `bakul` props use agent-generated low-poly `BambooBasket` geometry
(generationId `14b48661-4c08-425f-ab3f-c641c1a885fd`), original / CC0-equivalent with **no invented
Creator Store asset ID**. The main session stripped all scripts (0 scripts, 18 parts, native bbox
~4.24x4.24x2.6 studs) and baked it runtime-only under
`ServerStorage.LookDevAssets/generated_bamboo_basket`. The applier clones that folder directly and
scales it via `GetBoundingBox`; it never calls `InsertService:LoadAsset` for it and never records an
ID. The folder is a verified source in `ModelMapHubPropsR8.ALLOWED_GENERATED`, not a numeric asset.

Step (4): the remaining vernacular kinds have no compliant free model in the manifest, so they are
built from explicit anchored Roblox parts. All colours are plain `{r,g,b}` arrays and all materials
are built-in material names resolved at apply time; the shared data module has no game API,
`Instance`, `Color3`, `Enum` or asset URL at load.

Real-world targets (studs, width x height x depth): `karung` 3x3x2, `gerobak` 8x6x5 or 6x3.4x5,
`lapak` 10x6x5, `jemuran` 8x7x2, `pagar`/`bale bambu` 8x5x0.6, `sumur` 5x4x5, `motor` 6x4x2.5,
generated `bakul` 2x2x1.5.
The applier rejects a baked bbox that misses its target by more than 25% and counts it as a load
failure.

## Studio run recipe (main session owns this)

1. Stop Play. Inject at runtime, do not save: `Shared.ModelMapHubPropsR8`, the changed
   `Shared.LookDev` / `Shared.LookDevReview`, `Server.Main.server`,
   `Server.World.LookDevHubPropsR8`, and the new `tools/studio/review_check_r8.luau`. Confirm the
   nine baked asset folders exist under `ServerStorage.LookDevAssets` plus the generated
   `generated_bamboo_basket` folder (0 scripts, 18 parts, runtime-only, never saved).
2. Start a FRESH real Play session in the SERVER datamodel. Stage with
   `require(game.ReplicatedStorage.Shared.LookDevReview).enable("hubprops_r8", game)`.
3. Paste the WHOLE `tools/studio/review_check_r8.luau` into Studio MCP `execute_luau` in the SERVER
   VM. Capture `HUBPROPS_VISIBLE`, `HUBPROPS_ON_GRASS`, `LOAD_FAILURES` and `LOOKDEV_LEAK`.
   Targets: `HUBPROPS_VISIBLE >= 5` (minimum visible tagged props per hub from that hub's
   `hub_<key>` review camera) and `HUBPROPS_ON_GRASS 0`. A missing staging folder, a missing camera
   or a failed read is a FAIL, never a skip. `HUBPROPS_ON_GRASS` is used instead of the existing r7
   `PROPS_ON_GRASS` line so the same harness can report both families without a duplicate CHECK
   name.
4. Stop Play without saving. No publish. A designer yes/no is still pending.

`HUBPROPS_VISIBLE` uses the existing `ReviewCameras.get("hub_" .. key)` cameras and the harness
70-degree cone plus one occlusion ray per subject. The Client VM cannot read `ReviewCameras`
(it requires MapSpec from `ServerScriptService`), so both checks are SERVER-only.
