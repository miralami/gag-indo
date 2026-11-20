# LookDev corner — round 3 item 2 (staged on real terrain, item 28 fix)

A 60x60-stud corner staged on **real PLAZA ground** from `src/server/World/MapSpec.luau`
(`PLAZA` spans X -48..48, Z -42..42; `SPAWN` is at (0, *, 28)). Origin is
`{ -14, 0, -12 }`, footprint X -44..16 / Z -42..18 — on the mapped ground plate, away from spawn,
the four road arms and the six hub clearings. The old `{ 500, 0, 500 }` origin was off-map over
the void (round-3 review bug 6). Twenty-one temporary primitive Parts form three feature groups:
a **warung** (counter, roof, posts, sign, stool, lantern), a **curved road bend** (five
Cobblestone slabs on an arc plus approach), and a **sawah edge** (tanah strip, pematang ridge,
water strip, three padi clumps). All colours are ART.md section 3 palette tokens; all materials
are built-in Enum.Material names. No asset IDs.

Source of truth: `src/shared/LookDevCorner.luau` (pure recipe, `partsInBounds()` seam).
Applier: `src/client/World/LookDevCorner.luau` — builds `Workspace.LookDevCorner`, destroys it on
disable. Toggle: `require(game.ReplicatedStorage.Shared.LookDev).enable("corner")`; the one-call
review form is `require(game.ReplicatedStorage.Shared.LookDevReview).enable("corner", game)`.

## V-D1 / V-D2 notes

- **V-D1 — no world outlines:** this candidate deliberately creates no Highlight objects and no
  outline descriptors. The corner is shown in its plain built-in-material state first.
- **V-D2 — golden hour:** the adapter saves `game.Lighting.ClockTime`, sets it to
  `LookDevCorner.goldenHourClock` = 16.5 (midpoint of `WorldConstants.GOLDEN_HOUR` 16.0–17.0)
  while enabled, and restores the saved value on disable.

## Review cameras (absolute world coordinates, re-staged)

Copy into Studio `screen_capture` as `camera_position` / `look_at_position`. Each is the old
camera shifted by the same offset (X -514, Z -512) used for every corner part.

| Shot id | camera_position | look_at_position |
|---|---|---|
| `warung` | `{ -34, 12, -12 }` | `{ -28, 4, -26 }` |
| `road_bend` | `{ -2, 10, 10 }` | `{ -2, 1, -9 }` |
| `sawah_edge` | `{ -14, 8, 16 }` | `{ -28, 1, 6 }` |

## Studio review shots — to be captured by parent

No screenshots or visual verdicts are recorded here yet. The parent session captures the three
shots above in Studio and adds the evidence links and designer decision after review.
