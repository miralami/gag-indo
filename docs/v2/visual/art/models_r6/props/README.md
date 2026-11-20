# Props R6 — tools at real size (`props_r6`)

Off-by-default LookDev candidate from WORK_QUEUE section J item 50. Reuses the seven real
`props_r4` Creator Store IDs; no new IDs, no Studio save, no visual graded.

## R5 → R6 scale table

Target heights are final stud sizes after `Model:ScaleTo(effectiveHeight / loadedYSize)`, read
from the actual `GetBoundingBox` size. Player reference: 5 studs.

| Prop | R5 height | R6 scale | R6 target height | Note |
|---|---|---|---|---|
| gerobak | 3.0 | 1 | 6 studs | ~8 studs LONG (planning target, checked in spec) |
| sumur | 2.5 | 0.9 | 4.5 studs | requested 4–5 stud band |
| cangkul (`alat_tani`) | 1.8 | 1.5 | 4.5 studs | R4 `alat_tani` ID, no new key |
| jemuran | 7 | 1 | 7 studs | unchanged, designer liked it |
| lapak | 4.8 | 0.6 | 4.8 studs | unchanged from R5 |
| pagar_bambu | 5 | 1 | 5 studs | unchanged from R5 |
| karung | 2 | 1 | 2 studs | R5 gudang stack reused verbatim |

## Saved camera

R4/R5 `{ position = {142, 9, 146}, target = {142, 3, 122} }` sat behind the pine row.
R6 moves the eye to **`position = {154, 10, 140}`, `target = {142, 3, 122}`** — an X-offset of
+12 that sidesteps the pines while keeping the same look-at on the two staging rows.

## Mechanics

- Server applier `src/server/World/LookDevModelsPropsR6.luau`, data `src/shared/ModelMapPropsR6.luau`.
- Sizes measured with `Model:GetBoundingBox()` before and after scaling; `Model:ScaleTo` uses
  `target / bodyY`. Every engine call is pcall-guarded; prior same-named folder is detached on
  apply and restored exactly on disable.
- Enable from a **Server** command bar / datamodel: `LookDev.enable("props_r6")`. Client
  `LoadAsset` is blocked, so this is server-only.
- `tests/specs/props_r6_spec.luau` mounts a known 2×3×2 stud box (gerobak 2×3×4 for the length
  check), runs the real applier under the fake Env, and compares post-`ScaleTo` `GetBoundingBox`
  sizes with the targets. No visual has been graded; all verdict cells remain blank.
