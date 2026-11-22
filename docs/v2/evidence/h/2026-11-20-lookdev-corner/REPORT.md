# LookDev corner — Studio verification and review cameras (round 3 item 2)

**Scope.** Live verification of the off-by-default `corner` LookDev candidate in Roblox Studio,
plus the three saved review-camera positions. The **visual yes/no is deliberately not decided
here** — it belongs to the designer or a vision-capable observer.

## Method

The connected Studio instance (`Development-Juragan-Desa`, Edit mode) was **stale** relative to the
repo: Rojo was not running, so none of the new item-2 modules (nor the earlier `DayCycle` module)
had synced, and the in-Studio `LookDev` registry still had only eight candidates. Starting `rojo
serve` was rejected because the project tree roots at `DataModel` and could clobber unsaved manual
Studio content (the imported `*_v2` prop models in Workspace).

Instead, the **exact committed source** of `src/shared/LookDevCorner.luau` and
`src/client/World/LookDevCorner.luau` was injected as temporary ModuleScripts into the correct
Studio hierarchy (`ReplicatedStorage.Shared.LookDevCorner` and
`StarterPlayer.StarterPlayerScripts.Client.World.LookDevCorner`). The stale in-memory `LookDev`
registry was patched with the `corner` candidate entry so the adapter's `LookDev.register("corner")`
would be accepted, then `LookDev:enable("corner")` was driven through the real gate.

## Live checks (`SEEN-IN-STUDIO`)

| Check | Result |
| --- | --- |
| Injected recipe loads (`WorldConstants` + `Visuals` resolve) | `SIZE=60`, `parts=21`, `goldenHourClock=16.5` |
| `LookDev.isCandidate("corner")` | `true` |
| Adapter registers its applier | `hasApplier("corner")=true` |
| `LookDev.enable("corner")` | `ok=true`, no warning; `current()="corner"` |
| `Workspace.LookDevCorner` created | present, **21 Parts**, **0 Highlight objects** (V-D1) |
| Sample part position | `LookDevCorner_warung_WarungCounter` at `486, 1, 488` (matches recipe) |
| Golden hour applied (V-D2) | `Lighting.ClockTime` 17.2 → **16.5** |
| Restore / cleanup | `disable()=true`; Folder gone, injected modules destroyed, registry entry removed, ClockTime restored to 17.2 |

**Restricted-VM note.** As in the earlier candidate reports, the Studio MCP `execute_luau` sandbox
cannot reliably resolve `Enum.PartType` / `Enum.Material` members, so the adapter's `pcall` lookups
fall back to defaults and the live shot shows block/cylinder-ish primitives, not guaranteed final
shapes/materials. The **recipe data** (positions, sizes, palette colours, part count) and the
toggle/ClockTime behaviour are what was verified live; final shading is for the visual review.

## Saved review cameras

Absolute world coordinates, copied verbatim from `LookDevCorner.cameras`. Paste into the Studio MCP
`screen_capture` tool as `camera_position` / `look_at_position`:

| Shot id | `camera_position` | `look_at_position` | Attempted capture id |
| --- | --- | --- | --- |
| `warung` | `{ 480, 12, 500 }` | `{ 486, 4, 486 }` | `LookDevCorner_warung` |
| `road_bend` | `{ 512, 10, 522 }` | `{ 512, 1, 503 }` | `LookDevCorner_road_bend` |
| `sawah_edge` | `{ 500, 8, 528 }` | `{ 486, 1, 518 }` | `LookDevCorner_sawah_edge` |

The same table is in `docs/v2/visual/art/corner/README.md`.

## What is NOT proven here (`UNVERIFIED`)

`screen_capture` returned `Request timeout` for all three shots — both three-at-once and a single
retry — matching the earlier candidate reports that this session cannot save/view screen captures.
**No screenshot was produced and no visual judgement was made.** The three camera positions are
saved so a vision-capable observer or the designer can capture and score the corner in a later
review pass. The `corner` row in `docs/v2/visual/CANDIDATES.md` stays `pending — review in Studio`.

Place was never saved or published; all injected instances were destroyed and `Lighting.ClockTime`
restored. No asset ID, product ID or UserId was used or invented.
