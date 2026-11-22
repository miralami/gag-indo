# buildings_r8 — LookDev handoff (round 9, item 77)

OFF-BY-DEFAULT LookDev candidate. Enable from the **Server** datamodel:
`require(game.ReplicatedStorage.Shared.LookDevReview).enable("buildings_r8", game)`.
Nothing ships on by default; a published server can never enable it.

## Six staged buildings

| Slot | Asset ID | Creator | Native bbox (X x Y x Z, studs) | Scale | Staged bbox (X x Y x Z, studs) |
|---|---|---|---|---|---|
| indonesian_house | 81909711760416 | Dagelan_Smg | 36.67 x 30.00 x 52.03 | 1.0 | 36.67 x 30.00 x 52.03 |
| rumah_4 | 140621903274156 | Dagelan_Smg | 37.61 x 31.53 x 54.80 | 1.0 | 37.61 x 31.53 x 54.80 |
| rumah_joglo | 4820552419 | Annovaire | 76.87 x 44.00 x 75.35 | 0.75 | 57.66 x 33.00 x 56.51 |
| pendopo_jawa | 136417251697510 | Pramadhita_wira | 30.52 x 48.10 x 51.56 | 1.0 | 30.52 x 48.10 x 51.56 |
| warung_penyetan | 118767493095408 | Voltcho1354 | 24.00 x 13.02 x 13.82 | 1.0 | 24.00 x 13.02 x 13.82 |
| nipa_hut | 167594119 | SanchettaSam | 22.72 x 28.42 x 44.29 | 1.0 | 22.72 x 28.42 x 44.29 |

All six IDs are real free Creator Store models from `search_asset`; none invented. Asset
`10019841237` was rejected (no clear ground-floor opening) and is deliberately absent.
`rumah_joglo` requires `Model:ScaleTo(0.75)`: native width 76.87 is outside the 12..60 band,
staged 57.66 fits. Every staged width is in 12..60.

## Row and site

One row along X with **20 studs of CLEAR GAP between adjacent footprints**, not 20 studs of
centre spacing. Centre pitch varies with the staged widths:
`offset[i] = offset[i-1] + stagedWidth[i-1]/2 + gap + stagedWidth[i]/2` (offset[1]=0). Fixed
20-stud centres made wide buildings physically overlap and mutually occlude in the review cone
(`BLDG_VISIBLE` 4/6); the gap rule gives ~309 studs of row span. The six centres are derived from
`ModelMapBuildingsR8.rowCentres(siteX)` and are centred on the site.

The site is a **340 x 80 stud model-free box** (70 studs tall, probed at Y=25) selected nearest
spawn: candidates are walked outward on a 10-stud grid, tree/keep-out filters apply as before, and
`workspace:GetPartBoundsInBox` rejects any candidate containing an ancestor Model of an existing
World part (Terrain and the staged folder are excluded). This matters because the old (0,-62) yard
sat on the shipping Pasar/Warung hubs. Each slot gets a Ground voxel pad under its footprint. The
staging folder is exactly `LookDevBuildingsR8_buildings_r8`; every staged Part and gauge carries
`LookDevBuildingsR8="buildings_r8"`, every building Model carries `BuildingSlot=<slot>`, and the
folder carries `ReviewCameraPos` / `ReviewLookAt`.

## Door gauge rule

Creator Store "door" nodes are Decals/empty Models, so door height is not measurable from a part
Size. The applier therefore stages ONE real Part per building named `DoorGauge`, with
`Size = Vector3.new(7, 7.25, 2)` (width 7, avatar height 7.25 >= required 7, depth 2),
`CanCollide=false`, `Transparency=1`, `Anchored=true`, parented under the staged building Model.
Its attributes are `LookDevBuildingsR8="buildings_r8"`, `BuildingSlot=<slot>`,
`GaugeKind="DoorClearance"`, `Facade="front"|"back"`.

Placement uses ONE temporary rotation-aware probe Part, reused for all six buildings and destroyed
at the end of `apply()`. It tries FRONT (world min Z) then BACK (world max Z), X offsets
`0,-3,3,-6,6,-9,9,-12,12` from the bbox centre and depth offsets `2,4,6,8,10,12,14` from the
facade edge; `y = minY + 1.5 + 7.25/2`. The 1.5 floor offset avoids ground-slab false positives.
`workspace:GetPartsInPart` counts collidable building parts (`Size.X > 0.5`, `Size.Y > 1.5`) in the
oriented gauge volume; the first zero-overlap position wins. The applier sets the model's Name and
parents it into the staged Workspace folder **before** calling `stage(...)`, so `GetPartsInPart`
sees the real building geometry; a parenting failure counts the slot as a failure and skips staging
rather than probing an unparented model. If none is clear, the gauge falls back to centre-front and
the slot is counted as a failure — never a fake pass. Authored `CanCollide` on building parts is
preserved.

The harness `BLDG_DOOR` check uses the same rotation-aware `GetPartsInPart` measurement instead of
recomputing world AABBs: rotated roof panels (joglo Union 24x26x0.16, pendopo Unions ~19x47x51)
have world AABBs that swallow the gauge even when their actual geometry does not intersect it.
The target remains 6/6 — this is a correctness fix, not a relaxation.

## Review camera

The folder's `ReviewCameraPos` / `ReviewLookAt` attributes are the saved review camera. The rule is
a **signed Z offset** `front = -228`, `up = 60`, `lookY = 16`: the camera is at
`(centreX, 60, centreZ - 228)`, looking at `(centreX, 16, centreZ)`. Negative `front` means the
camera sits on the min-Z (facade) side — the verified clear vantage. The former +Z camera rule put
shipping World buildings (`PosPolisi`, `RumahPakRT`) between camera and row, blocking two of six
sightlines. Frame the row from the saved position; do not move the buildings to suit a shot.

## Status

Look grading is **pending** — fresh-Play Studio verification is required. No screenshot, no visual
verdict, no place save and no publish is claimed here.
