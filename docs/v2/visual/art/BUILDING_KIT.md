# Building kit — `buildings_r8` (WORK_QUEUE section O item 146)

Six real free Creator Store buildings, staged by the **OFF-BY-DEFAULT** `buildings_r8` candidate
(`src/server/World/LookDevBuildingsR8.luau`). The designer composes the spawn himself; this is a
placement reference, not a shipping layout. **Visual grading stays the designer's.** No place is
saved or published by this kit.

## Pivot convention

Each baked Model is normalized **at stage time by `LookDevBuildingsR8.stage()`** — the baked assets
themselves are not edited. After final placement the applier sets `model.WorldPivot = CFrame.new(x,
baseY, z)` where `baseY` is the world bbox bottom (`placedBox.Position.Y - placedSize.Y * 0.5`) and
`(x, z)` is the footprint centre. `PrimaryPart` is cleared defensively first: with no PrimaryPart,
`WorldPivot` moves only the pivot, leaving every Part CFrame and the world bbox unchanged (verified
in Studio). Identity CFrame `LookVector` is **-Z**, so the pivot faces -Z; the front door faces the
plaza on the min-Z (facade) side. CHECK `PIVOT_GROUND` grades each pivot against its own bbox bottom
within 0.2 studs.

## Kit table

Bounding sizes are world AABBs, `X × Y × Z` studs (width × height × depth), measured in Studio.
Native = baked asset; staged = after `ScaleTo(scale)`. DoorGauge offset is the local X shift from the
staged footprint centre; `front` = min Z face. Hub matches are a **PROPOSAL awaiting the designer**,
not a decision.

| Slot / ID | Asset ID | Licence / creator | Native bbox (studs) | Staged bbox (studs) | Scale | DoorGauge local X / facade | Suggested hub (PROPOSAL) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `indonesian_house` | `81909711760416` | Creator Store free — Dagelan_Smg | 36.67 × 30.00 × 52.03 | 36.67 × 30.00 × 52.03 | 1.0 | 0 / front | `pasar` — red roof, large |
| `rumah_4` | `140621903274156` | Creator Store free — Dagelan_Smg | 37.61 × 31.53 × 54.80 | 37.61 × 31.53 × 54.80 | 1.0 | 0 / front | `pakrt` — yellow roof |
| `rumah_joglo` | `4820552419` | Creator Store free — Annovaire | 76.87 × 44.00 × 75.35 | 57.66 × 33.00 × 56.51 | 0.75 | 0 / front | `gelap` — vacant / empty lot |
| `pendopo_jawa` | `136417251697510` | Creator Store free — Pramadhita_wira | 30.52 × 48.10 × 51.56 | 30.52 × 48.10 × 51.56 | 1.0 | -3 / front | `polisi` — blue roof, official / ceremonial |
| `warung_penyetan` | `118767493095408` | Creator Store free — Voltcho1354 | 24.00 × 13.02 × 13.82 | 24.00 × 13.02 × 13.82 | 1.0 | 0 / front | `warung` — tin roof, small warung |
| `nipa_hut` | `167594119` | Creator Store free — SanchettaSam | 22.72 × 28.42 × 44.29 | 22.72 × 28.42 × 44.29 | 1.0 | -6 / front | `ronda` — small guard post |

Canonical roof anchors (WORK_QUEUE section O target look): red-roof Pasar, tin-roof Warung,
blue-roof Polisi, yellow-roof Pak RT. The `gelap` and `ronda` rows above have no canonical roof
anchor in the brief; they are size/role matches only. All six facades measured `front` (min Z).

## Placement recipe

1. Stage with `require(game.ReplicatedStorage.Shared.LookDevReview).enable("buildings_r8", game)`
   in the SERVER VM after the Edit-mode bake; `LookDevAssetLoader` clones the baked folders.
2. Read `CHECK PIVOT_GROUND <failing> 0` (target 0) and `CHECK BLDG_VISIBLE 6 6` in
   `tools/studio/review_check_r8.luau`. Both are read-only and stage nothing.
3. For a chosen hub, set the staged Model's `WorldPivot` to the hub's ground-level centre; no
   per-asset CFrame fixup is needed. `PIVOT_GROUND` is the objective check, not a look verdict.

The `hubs_real_r9` candidate (item 147) is where these buildings are tried on the six hub
footprints; it stays a separate, OFF-by-default candidate.
