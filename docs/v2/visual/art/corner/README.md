# LookDev corner — round 3 item 2

A standalone 60x60-stud corner at absolute origin `{ 500, 0, 500 }` (footprint X/Z 470–530),
kept off the runtime world. Twenty-one temporary primitive Parts form three feature groups:
a **warung** (counter, roof, posts, sign, stool, lantern), a **curved road bend** (five
Cobblestone slabs on an arc plus approach), and a **sawah edge** (tanah strip, pematang ridge,
water strip, three padi clumps). All colours are ART.md section 3 palette tokens; all materials
are built-in Enum.Material names. No asset IDs.

Source of truth: `src/shared/LookDevCorner.luau` (pure recipe, `partsInBounds()` seam).
Applier: `src/client/World/LookDevCorner.luau` — builds `Workspace.LookDevCorner`, destroys it on
disable. Toggle: `require(game.ReplicatedStorage.Shared.LookDev).enable("corner")`.

## V-D1 / V-D2 notes

- **V-D1 — no world outlines:** this candidate deliberately creates no Highlight objects and no
  outline descriptors. The corner is shown in its plain built-in-material state first.
- **V-D2 — golden hour:** the adapter saves `game.Lighting.ClockTime`, sets it to
  `LookDevCorner.goldenHourClock` = 16.5 (midpoint of `WorldConstants.GOLDEN_HOUR` 16.0–17.0)
  while enabled, and restores the saved value on disable.

## Review cameras (absolute world coordinates)

Copy into Studio `screen_capture` as `camera_position` / `look_at_position`:

| Shot id | camera_position | look_at_position |
|---|---|---|
| `warung` | `{ 480, 12, 500 }` | `{ 486, 4, 486 }` |
| `road_bend` | `{ 512, 10, 522 }` | `{ 512, 1, 503 }` |
| `sawah_edge` | `{ 500, 8, 528 }` | `{ 486, 1, 518 }` |

## Studio review shots — to be captured by parent

No screenshots or visual verdicts are recorded here yet. The parent session captures the three
shots above in Studio and adds the evidence links and designer decision after review.
