# `npcs_r6` — role-specific textured villagers (item 48, Route B)

OFF-BY-DEFAULT LookDev candidate. Nothing is applied until it is enabled from the **Server**
datamodel (InsertService:LoadAsset is blocked on the client):

```lua
require(game.ReplicatedStorage.Shared.LookDev).enable("npcs_r6")
-- require(...LookDev).disable() restores the previous look
```

## Role → outfit → Image IDs

Provenance for all ten IDs: `models_r6/npcs/upload_manifest.json` (Open Cloud `Image` uploads,
`ROBLOX_API_KEY`, creator `172146044`). The same IDs are pure data in
`src/shared/ModelMapNpcsR6.luau`; the applier holds no ID literal.

| Role | Outfit | Shirt Image ID | Pants Image ID |
| --- | --- | --- | --- |
| `polisi` | brown police shirt and trousers | 113212316103784 | 98102154190902 |
| `pak_rt` | cream batik shirt, dark trousers | 117485364703264 | 127593796770640 |
| `petani` | pale blue-grey shirt, khaki trousers | 112086829394587 | 130876277340560 |
| `pedagang` | teal kaos + apron, dark slate trousers | 71100897124673 | 139244403929211 |
| `petani_wanita` | pink kebaya-style top, plum trousers | 105653588811968 | 76370296974052 |

`Shirt.ShirtTemplate` / `Pants.PantsTemplate` receive `"rbxassetid://" .. id` on a `Shirt` and
`Pants` created as **siblings of the Humanoid** (parented to the rig Model). These are Image IDs;
`HumanoidDescription.Shirt` / `Pants` are never used because they do not accept Image IDs. Body
colours (skin/torso/limbs) still come from `src/shared/ModelMapNpcsR5.luau` via require; R5 has no
`pak_rt` role, so its `tukang_peci` colours are reused.

## Hat attachment fix

The 2026-11-20 Studio review found **0 accessories** on all five `npcs_r5` rigs: the single
"first BasePart, rescale, parent" path was not enough. `attachHat` now tries, in order:

1. `InsertService:LoadAsset(id)` under `pcall`.
2. Search descendants for an `Accessory`; if found, call `Humanoid:AddAccessory(accessory)`.
3. Otherwise rescale the first `BasePart` to the R5 data-defined size, position it against `Head`,
   and parent it under `Head` (or the rig when no Head exists).
4. Warn clearly if every strategy fails.

A bad hat only skips that hat; it never breaks the toggle. `pak_rt` has no hat by design.

## Facing and saved camera

The 2026-11-20 review saw the villagers' **backs** at R5's `ry = 0` while the saved camera sits at
`z = 28` looking toward `z = 8` (`h/2026-11-20-review-round5/STUDIO_REVIEW.md`). Every R6 slot now
starts from a `math.pi` flip with a small per-role jitter so the group faces the camera and does not
read as one uniform queue. Saved review camera: `{ position = {0, 7, 28}, look = {0, 2.5, 8} }`,
unchanged from R5.

## Designer build

There is **no peci/kopiah hat Model in the repo**. `pak_rt` is batik-only; the R5 caping is a
farmer's conical hat and must not be reused as a peci. No hat ID was invented. A real peci is a
Designer build (`designerBuilds` note in the data module).

No visual was graded, no screenshot or Studio claim is made here; the designer owns the yes/no.
