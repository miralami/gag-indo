# `npcs_r5` — solid Roblox R15 villagers (LOOKDEV CANDIDATE, OFF BY DEFAULT)

WORK_QUEUE item 40. Five upright, grounded, motionless review villager rigs built from the
standard Roblox R15 rig and `HumanoidDescription` — **not** imported lying-down body models.
No animation is loaded; the idle pose is the untouched R15 rig. Visual verdict: **blank**
(no agent graded any visual, no Studio screenshot claim).

## Real Creator Store assets used — exactly three

All three are FREE **Model** assets (not Accessory assets), verified on their store pages.
`InsertService:LoadAsset` runs server-side only; the applier takes the first `BasePart`,
scales it to the data-defined `targetSize` and parents it under the character. No script
was found in any of them. No other asset ID is used; no ID was invented or substituted.

| Key | Asset ID | Name | Creator | Licence / kind | Store page | Used by | Data-defined size |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `caping` | `71002247087415` | Chinese Straw Hat Asian Conical Rice Farmer Hats | Zephban5961 | FREE, Model | https://create.roblox.com/store/asset/71002247087415 | petani, petani wanita | source about 2.4 × 0.6 × 2.2 studs; scaled to 2 studs, head offset 0.6 |
| `caping_backup` | `14769019514` | Oriental Bamboo Conical Hat | RZKU | FREE, Model | https://create.roblox.com/store/asset/14769019514 | spare only (not staged) | scaled to 2 studs, head offset 0.6 |
| `polisi_cap` | `126970096704856` | Police Hat Cap Cop Officer Headwear Hats Accessory | Mukamato101 | FREE, Model | https://create.roblox.com/store/asset/126970096704856 | polisi | source about 1 × 1 × 1 stud; scaled to 1.5 studs, head offset 0.5 |

Source description notes: the conical farmer hat is "1 part, 1 mesh, about 2.4 x 0.6 x 2.2
studs. No scripts."; the police cap is "1 part, 1 mesh, about 1 x 1 x 1 studs. No scripts."
These IDs are **never** passed to `HumanoidDescription.HatAccessory` / `ShirtAssetIds`;
that field family expects Accessory assets, not Models.

## Designer builds — no invented ID

Searches for a genuine free **peci/kopiah**, **batik shirt** and **sarong** returned no
reliable match (only irrelevant/spam results). No substitute was invented. These are
**Designer builds**: `pedagang` and `tukang_peci` receive body colours only in this candidate.
Brief for the designer: source or model a simple kopiah, a batik shirt and a sarong with a
clear local silhouette, then add real IDs through the asset ladder in `WORK_QUEUE.md`.

## Roles and body colours

Colours are stored as plain integer `{ r, g, b }` triples in `src/shared/ModelMapNpcsR5.luau`.
Skin maps to head + both arms, shirt to torso, pants to both legs.

| Role | Skin | Shirt | Pants | Hat |
| --- | --- | --- | --- | --- |
| `petani` | 198,148,106 | 86,122,84 | 104,84,62 | `caping` |
| `pedagang` | 190,138,96 | 170,72,56 | 72,82,104 | none — Designer build (batik/sarong) |
| `petani_wanita` | 204,156,116 | 206,128,74 | 110,76,92 | `caping` |
| `tukang_peci` | 186,134,94 | 46,92,118 | 84,78,68 | none — Designer build (peci) |
| `polisi` | 196,146,108 | 30,46,92 (navy) | 26,38,76 (navy) | `polisi_cap` |

## Files and review camera

- Data (pure, no Roblox APIs): `src/shared/ModelMapNpcsR5.luau`.
- SERVER-ONLY applier: `src/server/World/LookDevModelsNpcsR5.luau`. Requires
  `LookDev.register("npcs_r5", { apply, restore })`; main session wires the bootstrap and
  registry row. Off by default; no default game content changes.
- Spec: `tests/specs/npcs_r5_spec.luau` (source checks for the applier, runtime checks for
  the pure data module — no visual assertion).
- Staging row (reused from `ModelMapNpcsR4`): x = -16, -8, 0, 8, 16; y = 0.5; z = 8;
  `ry = 0`, fronts toward +Z. Player-height reference: 5 studs.
- Saved review camera: position `{ 0, 7, 28 }`, lookAt `{ 0, 2.5, 8 }`.

Toggle syntax: `LookDev.enable("npcs_r5")` / `LookDev.disable()` from the Server command
bar (dot syntax). Server datamodel only. On disable the dedicated Workspace folder is
destroyed and a pre-existing same-named folder, if any, is restored exactly.

Status: `LUNE-ONLY` for the code/spec gates. Studio toggle and visual verdict stay with
the main session / designer (`UNVERIFIED` until evidence is saved). Nothing was published
or saved into the place by this work.
