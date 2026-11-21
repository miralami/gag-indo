# TEXT_MIN_AUDIT — minimum UI text size at 375 px (WORK_QUEUE item 126)

> Audited 2026-11-22. Static source audit; **no visual verdict**, no Roblox Studio session.
> CHECK id `TEXT_MIN`.

## Method

Walk every `.luau` file under `src/client/UI/**` (reusing the fs walk and line parser from
`tests/specs/ui_touch_text_audit_spec.luau`) and record every literal
`TextSize = <n>`, `MinTextSize = <n>` and `TextSize = Visuals.type.<small|body>` below 14.
A label with `TextScaled = true` renders at the clamp supplied by its
`UITextSizeConstraint.MinTextSize`; a label with `TextScaled = false` renders at its literal
`TextSize`. The reference viewport is 375 px wide (the Phone's portrait device frame).

Locks read before this audit and **not changed**:

- `tests/specs/visuals_spec.luau:41-46` locks `Visuals.type.display = 28`, `heading = 18`,
  `body = 13`, `small = 11`.
- `tests/specs/ui_touch_text_audit_spec.luau:18,145-161,213-217` locks the 11 px floor and the two
  `Phone.luau` constraints `MinTextSize = 11, Parent = label` (`:411`) and
  `MinTextSize = 11, Parent = litLabel` (`:1353`). The one-axis 44 px touch rule is unchanged.

**The 14 px floor could not be universally applied without overriding those locked decisions.**
`visuals_spec` deliberately sets body = 13 and small = 11, and `ui_touch_text_audit_spec` guards two
11 px constraints. No lock was weakened, no threshold was lowered or raised to manufacture PASS.
No plain violation was found that could be fixed without overriding a lock or changing a layout the
designer chose, so **zero code changes** were made in this item.

## Violations at 375 px

`status` is `designer decision` for every row; the reason column names the protecting lock or the
deliberate layout.

| Site | Key | Value | Status | Reason |
|---|---|---:|---|---|
| `src/client/UI/Admin.luau:133` | TextSize | 13 | designer decision | locked `Visuals.type.body = 13` by `visuals_spec.luau:44` |
| `src/client/UI/Admin.luau:162` | TextSize | 13 | designer decision | locked body=13; perf switch label in a 30 px grid cell |
| `src/client/UI/Admin.luau:236` | TextSize | 13 | designer decision | locked body=13 by `visuals_spec.luau:44` |
| `src/client/UI/Admin.luau:343` | TextSize | 13 | designer decision | locked body=13 by `visuals_spec.luau:44` |
| `src/client/UI/Hud.luau:181` | TextSize | 13 | designer decision | locked body=13; 44x30 language toggle |
| `src/client/UI/Hud.luau:363` | TextSize | 13 | designer decision | locked body=13; 116x44 seed-bar label |
| `src/client/UI/Leaderboard.luau:142` | TextSize | 13 | designer decision | locked body=13 by `visuals_spec.luau:44` |
| `src/client/UI/Leaderboard.luau:150` | TextSize | 13 | designer decision | locked body=13 by `visuals_spec.luau:44` |
| `src/client/UI/Phone.luau:143` | TextSize | 12 | designer decision | 22 px status row; 12 px clock is deliberate device chrome, 14 px needs a taller row |
| `src/client/UI/Phone.luau:156` | TextSize | 11 | designer decision | locked `Visuals.type.small = 11` by `visuals_spec.luau:45`; 22 px status glyphs |
| `src/client/UI/Phone.luau:196` | MinTextSize | 12 | designer decision | deliberate one-line title constraint (`MaxTextSize = 22`); 14 px would break the "never wraps" note at `:195` |
| `src/client/UI/Phone.luau:411` | MinTextSize | 11 | designer decision | locked by `ui_touch_text_audit_spec.luau:215` |
| `src/client/UI/Phone.luau:530` | TextSize | 13 | designer decision | locked body=13 by `visuals_spec.luau:44` |
| `src/client/UI/Phone.luau:929` | TextSize | 13 | designer decision | locked body=13 by `visuals_spec.luau:44` |
| `src/client/UI/Phone.luau:1353` | MinTextSize | 11 | designer decision | locked by `ui_touch_text_audit_spec.luau:216` |
| `src/client/UI/RaidOverlay.luau:64` | TextSize | 13 | designer decision | locked body=13 by `visuals_spec.luau:44` |
| `src/client/UI/Theme.luau:292` | TextSize | 11 | designer decision | literal `Visuals.type.small`; locked by `visuals_spec.luau:45` |
| `src/client/UI/Theme.luau:366` | TextSize | 13 | designer decision | literal `Visuals.type.body`; locked by `visuals_spec.luau:44` |

## Fixes applied

None. A 14 px floor on any of the locked body/small rows would silently weaken
`visuals_spec` or `ui_touch_text_audit_spec`; the remaining rows are device-chrome or title layout
that the item explicitly says not to move.

## Counts

- Literal sizes below 14 in audited scope: 18 sites (15 body/small-scale labels, 3 `UITextSizeConstraint`
  minimums).
- Fixed: 0. Left unchanged with a recorded designer-decision reason: 18.
- Locks changed: 0. Thresholds weakened: 0.

## Decisions for designer

- Raise `Visuals.type.body` from 13 to 14 and `Visuals.type.small` from 11 to 14 in `visuals_spec`
  if a true 14 px floor is wanted. That is a global type-scale change (18 rows above) and needs a
  design pass on the 22 px HUD status row, the 30 px Admin grid cell and the two 11 px phone
  constraints. Not done here.
- The Phone status clock (12 px) and glyph mock (11 px) are decorative device chrome in a 22 px row;
  keeping them at 12/11 is a deliberate visual choice.
- The one-line Phone title constraint at `Phone.luau:196` (`MinTextSize = 12`, `MaxTextSize = 22`)
  is content text but a heading, not body text. Raising its floor to 14 requires checking title
  overflow at 375 px in Studio; left for the designer.
