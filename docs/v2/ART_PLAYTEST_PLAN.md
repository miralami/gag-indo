# Art Pass Playtest Plan

Scope: verify the W3–W8 visual pass in Roblox Studio without changing gameplay, save data, or publishing. Use a private local test session; capture evidence and log defects. Keep all asset IDs at `0` unless separately approved.

## Before starting

- [ ] Open the project in Studio; confirm Output has no baseline errors.
- [ ] Use a test account/save. Do not use production DataStores or publish.
- [ ] Record device, viewport resolution, graphics quality, Studio version, and current commit/worktree state.
- [ ] Capture baseline: spawn, one crop plot, village hub, phone/HUD.
- [ ] Note baseline instance count and FPS using the same method/device as the final capture.

## Test cases

| ID | Action | Pass criteria | Evidence |
|---|---|---|---|
| P1 — Spawn/traversal | Start a fresh session; walk between spawn, Pasar, Warung, police post, plots, and river/terraces. | Spawn is safe; routes are traversable; prompts/NPCs are discoverable; no stuck spots, collisions, or major visual gaps. | Wide screenshots; short traversal recording; Output log. |
| P2 — Crop stages | Plant a crop; observe early, middle, and ready stages. Use a crop with short grow time or approved test controls; do not change production balance. | Bibit → tumbuh → siap transitions occur once in order; silhouettes remain distinct and readable at gameplay distance; harvest visuals clear correctly. | Screenshots with timestamps and crop/tier noted. |
| P3 — Rarity | Inspect each tier: Biasa, Bagus, Super, Langka, Sultan. Prefer test fixtures/admin controls that do not alter saved progress. | Correct palette/frame per tier; Biasa has no fanfare; higher-tier effects are visible but not obstructive; no missing/incorrect assets. | One screenshot per tier; note effect/audio outcome. |
| P4 — Reveal motion/audio | Trigger a rare reveal and Sultan reveal; separately test Sultan camera shake. | Frame/glow/reveal feedback is legible; motion is brief; sting plays once; shake is limited to Sultan/raid and does not leave the camera offset. | Short recording; client Output log. |
| P5 — Raid | Trigger a raid through approved test controls; observe warning, overlay, NPC response, end/cleanup. | Readable raid warning and motion; no stuck overlay, camera, NPC, or input state after raid ends. | Recording; before/after screenshots; Output log. |
| P6 — NPCs | Inspect each NPC at close and normal interaction distance; trigger speech with neutral, `!`, and `?` text where available. | Silhouette/accessory and contour read clearly; mouth response is understandable; text is not clipped; no overlapping name/speech labels. | Screenshots at both distances. |
| P7 — Hub art | Inspect Pasar, Balai Desa, Pos Polisi, Warung, sawah, dressing clusters, and contours. | Palette and landmark identity match `ART.md`; hero objects outlined, backdrop not noisy; contour does not dominate at distance; dressing does not block paths/prompts. | Hub screenshots; defect list. |
| P8 — Season/weather | In a private test session, cycle Hujan, Kemarau, Pancaroba and available weather presets using supported admin/config controls. | Each preset applies and transitions cleanly; palette remains readable; rain/storm effects do not obscure play; no persistent Lighting changes after switching. | Screenshot per preset; Output log. |
| P9 — Rebuild lifecycle | In Studio edit/test workflow, build the generated Greybox twice; compare Terrain and tagged world. Repeat with a designer map present only if a safe test copy exists. | Rebuild does not stack terrain, delete designer content, duplicate tags, or leave stale generated objects. | Before/after screenshots; Explorer/Terrain evidence. |
| P10 — Mobile/performance | Repeat P1, P2, P7 at target mobile resolution and mid-range Android quality; compare against baseline. | Text/touch targets readable; no clipped UI; routes/prompts usable; target 60 FPS where device supports it; record any regression and instance delta. | Device/resolution/quality, FPS samples, instance counts, screenshots. |

## Run order and defect handling

1. Run P1 and establish the session baseline.
2. Run P2–P8; isolate visual defects from gameplay defects.
3. Run P9 separately in Edit mode or on a disposable copy; do not risk the designer map.
4. Run P10 after visual fixes, using the same device/settings as baseline.
5. For each failure, record test ID, exact steps, expected/actual result, device/settings, screenshot or recording, and Output errors. Severity: blocker (unsafe/unplayable/data risk), major (core art/readability broken), minor (polish).
6. Re-run the failed case after each fix, then re-run adjacent cases affected by that fix.

## Exit criteria

- Every applicable case marked PASS or FAIL with evidence; BLOCKED requires a reason and owner.
- No blocker or major defect remains open for sprint closure.
- `lune run tests/run` passes after any code changes.
- Update `docs/v2/ART_CHECKPOINT_3.md` with results, device details, evidence locations, and remaining Studio-only items.
- Do not claim visual pass from code review or automated tests alone. Do not fill asset IDs without approved assets/licensing.

## Results log

| ID | Result | Device/settings | Evidence | Defects / follow-up |
|---|---|---|---|---|
| P1–P10 | NOT RUN | — | — | Requires Roblox Studio; no connected Studio instance was available during plan creation. |
