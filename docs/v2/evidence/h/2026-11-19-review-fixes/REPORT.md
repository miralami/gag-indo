# Studio pass — review fixes: front-side cutscene framing + no-save force raid (Track F/H, 2026-11-19)

Build: `track/c-world-look` @ local standOff-14 fix (commit pending). Place: cloud dev place
`Development-Juragan-Desa`, placeId `132087524375529`, universeId `10776530981`. **Place never saved.**

## What this pass proves

Two review findings from the previous round (`83109a5`) are now backed by a real Studio playtest:

1. **Cutscene camera framing — `SEEN-IN-STUDIO` (line of sight).** The anchors were already moved to the
   NPC front spots at head height (Pak RT 68/5.7/47, Polisi -68/5.7/42) with a pure
   `RaidCutscene.cameraFor`. This pass raycast the exact eye→target lines the function produces
   against the real, built world (1706 parts) and found them unobstructed — with one correction:
   the police zoom shot at the previous `standOff = 18` was blocked by a tree. Reducing the zoom
   stand-off to **14** clears it. See `raycasts.json`.
2. **Harness force raid — see status line in MASTER_PLAN** (the no-save cooldown restore is
   `LUNE-ONLY` in `tests/specs/raid_trigger_spec.luau`; confirming the saved cooldown is untouched
   needs the synced `Harness`/`RaidTrigger` running in Studio).

## Raycast method

Studio Play Solo, `execute_luau` in the **Server** DataModel against live built geometry. For each
anchored shot, compute the eye exactly as `RaidCutscene.cameraFor` does —
`eye = anchor + (-standOff*sin(yaw), lift, -standOff*cos(yaw))` with the designer yaws from
`CutsceneState.focusOffset` (kades -18, police +18, road 0) — then
`workspace:Raycast(eye, (target-eye).Unit * magnitude, RaycastParams(Exclude))`.
Designer framing quality remains a look-dev judgement (visual plan §8); this only proves the shot
is not physically occluded.

## Results (standOff = 14 for zoom, walkin dolly unchanged)

| shot | anchor | standOff | line of sight | blocker at old standOff |
|---|---|---|---|---|
| zoom2 (kades) | 68/5.7/47 | 14 | clear | was clear at 18 too |
| zoom3 (police_chief) | -68/5.7/42 | 14 | clear | **18 blocked by `Workspace.World.Tree_12.Canopy_2` @ 3.18** |
| walkin p0 (road) | 0/2/-28 | 40 | clear | n/a |
| walkin p1 (road) | 0/2/-28 | 18 | clear | n/a |

Before/after for the police shot is the key finding: with the front-side anchor but the old
stand-off 18, the eye→head line runs into `Tree_12.Canopy_2` (a tree near -68/28, directly on the
police NPC's -z approach). A stand-off sweep at yaw 18 found 10/12/14 clear and 16/18/20/22
blocked; 14 is the largest clear stand-off and keeps the most framing distance. The kades shot is
clear at every stand-off (10–22). Both zoom shots now use 14, locked by a spec
(`cutscene_sequencer_spec.luau`, "uses a zoom stand-off <= 14 so the police shot clears
Tree_12.Canopy_2").

## Console / known noise

Output tail shows only the expected baseline: `[JuraganDesa] server started`,
`[ProfileStore]: Roblox API services available`, Assistant plugin version warnings, and three
`rbxassetid://203785492` "Asset type does not match requested type" lines (BUG-003, external,
accepted). No new errors introduced by this pass.

## Not covered by this pass

- Framing composition / finishes (designer look-dev, visual plan §8) — `BLOCKED` on designer.
- Harness force-raid saved-cooldown confirmation — pending DataModel sync of the two server scripts.
- Q3 mid-loan / mid-minigame / zero-cash+zero-seed (BUG-004), Q2 full-session Output capture.
