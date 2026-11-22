# Review round 4 — designer handoff

Purpose: one ordered handoff for the round-4 visual review (WORK_QUEUE items 29–31: twelve CC0
base-material override sets, three CC0 HDRI sky options and four families of real textured CC0/CC BY
models). It lists every new candidate, its exact toggle, its saved review camera and the order to
review. **No agent grades visuals.** Verdict cells in `docs/v2/visual/CANDIDATES.md` stay blank;
only the designer or a vision-capable observer with screenshots fills yes/no.

A missing visual verdict never blocks integration. All eight candidates are integrated off by
default with saved cameras and blank verdicts. This document is a handoff, not a review result:
nothing here is approved, rejected or shipped, no screenshot is claimed, no place is saved or
published, and no asset ID, product ID or UserId is created here. Status words remain
`SEEN-IN-STUDIO`, `LUNE-ONLY`, `UNVERIFIED`, `BLOCKED`.

## Toggles — use dot syntax

From the Studio command bar / `execute_luau`, the one-call review helper:

```luau
require(game.ReplicatedStorage.Shared.LookDevReview).enable("<id>", game)
require(game.ReplicatedStorage.Shared.LookDevReview).disable()
```

A fresh command-bar / `execute_luau` VM has a fresh `Shared.LookDev` with **no appliers registered**,
so a bare `enable("<id>")` can silently do nothing. `LookDevReview.enable` first `pcall(require)`s
the applier module for that id in the same VM — client appliers under
`PlayerScripts.Client`, server appliers under `ServerScriptService.Server` — and only then calls
`LookDev.enable("<id>")`. Pass `game` as the root. This is why one call is enough.

The direct form is also valid when the applier is already registered in that VM:

```luau
require(game.ReplicatedStorage.Shared.LookDev).enable("<id>")
require(game.ReplicatedStorage.Shared.LookDev).disable()
```

Use a **DOT** before `enable` / `disable` (`LookDev.enable`, `LookDev.disable`). Colon syntax
(`LookDev:enable("<id>")`) fails — these are plain table functions, not colon methods.

Only one candidate is active at a time; enabling another restores the previous look. The gate is
Studio-only; a published server can never enable it. All eight candidates are **off by default**:
nothing ships without a designer yes. Real IDs belong only in the shared maps and
`docs/v2/visual/art/ASSET_MANIFEST.md` (Round 4 section); none is invented here.

Model families `buildings_r4`, `vegetation_r4`, `props_r4` and `npcs_r4` MUST be enabled from the
**Server** datamodel: `InsertService:LoadAsset` is blocked on the client. `textures_r4` and
`sky_r4_a` / `sky_r4_b` / `sky_r4_c` use the **Client** datamodel. The one-call helper handles the
applier side for either datamodel from a single command.

## How to review

- Use synced code with the r4 IDs registered in `src/shared/LookDev.luau`; an unregistered id is
  ignored by the gate.
- Enable one row, capture from the saved camera below, call `.disable()`, then move on.
- "Contact sheet" paths are review aids only. The texture and sky sheets are dumps of source maps,
  not Studio screenshots; the four model rows use their per-family handoff as evidence.
- Every camera below is absolute world coordinates read verbatim from the source README/HANDOFF.
  Paste into Studio `screen_capture` as `camera_position` / `look_at_position`. Do not invent one.
- Record yes/no in `docs/v2/visual/CANDIDATES.md` and evidence under `docs/v2/evidence/`.
- No screenshot was captured by this handoff. No visual claim is made.

## Review-order table

| # | Candidate | Datamodel | `camera_position` | `look_at_position` | Contact sheet / evidence | Verdict |
|---|---|---|---|---|---|---|
| 1 | `textures_r4` | Client | `{ 0, 12, 52 }` | `{ 0, 3, -20 }` | `docs/v2/visual/art/textures_r4/render/contact_sheet.png` · `docs/v2/visual/art/textures_r4/README.md` |  |
| 2 | `sky_r4_a` | Client | `{ -14, 9, 42 }` | `{ -14, 16, -12 }` | `docs/v2/visual/art/sky_r4/contact_sheet.png` · `docs/v2/visual/art/sky_r4/README.md` |  |
| 3 | `sky_r4_b` | Client | `{ -6, 7, 40 }` | `{ -14, 14, -12 }` | `docs/v2/visual/art/sky_r4/contact_sheet.png` · `docs/v2/visual/art/sky_r4/README.md` |  |
| 4 | `sky_r4_c` | Client | `{ -22, 8, 40 }` | `{ -14, 15, -12 }` | `docs/v2/visual/art/sky_r4/contact_sheet.png` · `docs/v2/visual/art/sky_r4/README.md` |  |
| 5 | `buildings_r4` | Server | `{ 0, 22, 84 }` | `{ 0, 7, 20 }` | `docs/v2/visual/art/models_r4/buildings/HANDOFF.md` |  |
| 6 | `vegetation_r4` | Server | `{ 0, 20, 150 }` | `{ 0, 8, 96 }` | `docs/v2/visual/art/models_r4/vegetation/HANDOFF.md` |  |
| 7 | `props_r4` | Server | `{ 142, 9, 146 }` | `{ 142, 3, 122 }` | `docs/v2/visual/art/models_r4/props/HANDOFF.md` |  |
| 8 | `npcs_r4` | Server | `{ 0, 7, 28 }` | `{ 0, 2.5, 8 }` | `docs/v2/visual/art/models_r4/npcs/HANDOFF.md` |  |

Camera sources: `textures_r4/README.md` (`spawn_surface_override`), `sky_r4/README.md`
(`sky_r4_a`, `sky_r4_b`, `sky_r4_c`), and the four `models_r4/<family>/HANDOFF.md` files. The model
rows are staged on real `MapSpec` terrain; none uses the retired off-map `(500, 500)` corner.
`mangga` in `vegetation_r4` is a Balsa-tree stand-in, not a verified mango tree. The `npcs_r4`
models are anchored review dummies with no R15 rig.

Every verdict cell above and in `docs/v2/visual/CANDIDATES.md` is blank. All eight candidates are
off by default; **nothing ships without a designer yes**.

## Main session actions

The main session will capture Studio shots from the saved cameras and build the HTML review sheet
for the designer / vision observer. This document makes **no screenshot claim** and records no
visual grade. It does not save or publish the place and does not run Open Cloud uploads.
